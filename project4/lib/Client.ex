  # Sets up the worker/ Client

  defmodule Client do
  use GenServer

   def generateMultipleTweets(username, delay, n) do
      for _ <- 1..n do
        spawn(fn -> generateTweets(username, delay) end)
        end
   end

   def createMultipleRetweets(username, n) do
        for _ <- 1..n do
        spawn(fn -> createRetweets(username) end)
        end
   end

  def generateTweets(username, delay) do

    # get the tweet content.
    content = Simulator.getTweetContent(username)
    GenServer.cast(String.to_atom(username),{:tweet, content})
    
    Process.sleep(delay)

    generateTweets(username, delay)
  end

  def createRetweets(username) do

    Process.sleep(5000)

    index = GenServer.call(String.to_atom(username), {:getRetweetIndex})
    if index != nil do
      GenServer.cast(String.to_atom(username),{:retweet, username, index})
    end
    createRetweets(username)

  end

  def start_link(username, serverIP) do
      GenServer.start_link(__MODULE__, [username, serverIP, MapSet.new,[],[],[],[]],name: String.to_atom(username))
  end

  def init(username, serverIP, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets) do
      {:ok, {username, serverIP, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets}}
  end


  def handle_cast({:kill_self}, state) do
      {:stop, :normal, state}
  end

  def handle_cast({:receiveTweet, index, tweeter, content}, state) do
     [username, serverIP, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets] = state
     seenTweets = MapSet.put(seenTweets, index)
      if is_tuple(content) do
        {org_tweeter, text} = content
        Simulator.log(" #{username} sees #{tweeter} RETWEETED post of #{org_tweeter} : #{text}")
      else
        Simulator.log(" #{username} sees #{tweeter} posted a NEW tweet : #{content}")
      end
      {:noreply, [username, serverIP, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets]}
  end

  def handle_cast({:register_user, username}, state) do
     [username, serverIP, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets] = state
     GenServer.cast({:main_server, String.to_atom("mainserver@"<>serverIP)},{:registerMe, username, Node.self()})
    {:noreply, [username, serverIP, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets]}
  end

  def handle_cast({:retweet, selfId, tweetIndex}, state) do
     [username, serverIP, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets] = state
     GenServer.cast({:main_server, String.to_atom("mainserver@"<>serverIP)},{:reTweet, selfId, tweetIndex}) 
     {:noreply, [username, serverIP, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets]}
  end

  def handle_call({:getRetweetIndex}, _from, state) do
     [username, serverIP, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets] = state
     tweetList = MapSet.to_list(seenTweets)
     rand_Index = Enum.random(1..Enum.count(tweetList))
     selectedTweet = Enum.at(tweetList, rand_Index - 1)

     {:reply, selectedTweet, [username, serverIP, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets]}
  end

  def handle_cast({:subscribe_to,selfId, username}, state) do
     [username, serverIP, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets] = state
      GenServer.cast({:main_server, String.to_atom("mainserver@"<>serverIP)},{:subscribeTo, selfId, username}) 
     {:noreply, [username, serverIP, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets]}
  end

  def register_user(username, serverIP) do
    
    # Node.connect(String.to_atom("mainserver@"<>serverIP))
    GenServer.cast({:main_server, String.to_atom("mainserver@"<>serverIP)},{:registerMe, username, Node.self()})
  end


  
  def subscribe_to(selfId, username, serverIP) do
    GenServer.cast({:main_server, String.to_atom("mainserver@"<>serverIP)},{:subscribeTo, selfId, username}) 
  end



  


#change
  # def handle_cast({:search_by_hashtags, hashtag}, state) do
  #    [username, serverIP, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets] = state
  #     hashtag_list = GenServer.call({:main_server, String.to_atom("mainserver@"<>serverIP)},{:tweetsWithHashtag, hashtag}, 10000)
  #    {:noreply, [username, serverIP, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets]}
  # end

  def handle_cast({:search_by_hashtags, hashtag}, state) do
     [username, serverIP, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets] = state
      GenServer.cast({:main_server, String.to_atom("mainserver@"<>serverIP)},{:tweetsWithHashtag, hashtag,username})
     {:noreply, [username, serverIP, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets]}
  end

  def handle_cast({:receiveHashtagResults,hashtag_list},state) do
     [username, serverIP, seenTweets,_,mentions_list,relevantTweets,mentionedTweets] = state
     {:noreply, [username, serverIP, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets]}
  end

  def handle_cast({:getMyMentions}, state) do
     [username, serverIP, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets] = state
     GenServer.cast({:main_server, String.to_atom("mainserver@"<>serverIP)},{:myMentions, username})      
     {:noreply, [username, serverIP, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets]}
  end

  def handle_cast({:receiveMyMentions,mentions_list},state) do
     [username, serverIP, seenTweets,hashtag_list,_,relevantTweets,mentionedTweets] = state
     {:noreply, [username, serverIP, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets]}
  end

  # def handle_cast({:queryYourTweets}, state) do
  #    [username, serverIP, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets] = state
  #    {relevantTweets, mentionedTweets}=GenServer.call({:main_server, String.to_atom("mainserver@"<>serverIP)},{:queryTweets, username}, 10000)
  #    {:noreply, [username, serverIP, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets]} #not keeping mentioned tweets
  # end

  def handle_cast({:queryYourTweets}, state) do
     [username, serverIP, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets] = state
     GenServer.cast({:main_server, String.to_atom("mainserver@"<>serverIP)},{:queryTweets, username})
     {:noreply, [username, serverIP, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets]} #not keeping mentioned tweets
  end

  def handle_cast({:receiveQueryResults,relevantTweets},state) do
     [username, serverIP, seenTweets,hashtag_list,mentions_list,_,mentionedTweets] = state
     {:noreply, [username, serverIP, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets]}
  end

  def handle_cast({:tweet, tweet_content}, state) do
     [username, serverIP, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets] = state

      content=tweet_content
      split_words=String.split(content," ")
      hashtags=findHashTags(split_words,[])
      mentions=findMentions(split_words,[])
      tweetBody={content, hashtags, mentions}

      GenServer.cast({:main_server, String.to_atom("mainserver@"<>serverIP)},{:tweet,username, tweetBody})

      {:noreply, [username, serverIP, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets]}
  end
  
  def findHashTags([head|tail],hashList) do
    if(String.first(head)=="#") do
      [_, elem] = String.split(head, "#") 
      findHashTags(tail,List.insert_at(hashList, 0, head))
    else 
      findHashTags(tail,hashList)
    end

  end

  def findHashTags([],hashList) do
    hashList
  end

  def findMentions([head|tail],mentionList) do
    if(String.first(head)=="@") do
      [_, elem] = String.split(head, "@") 
      findMentions(tail,List.insert_at(mentionList, 0, elem))
      
    else 
      findMentions(tail,mentionList)
    end

  end

  def findMentions([],mentionList) do
    mentionList
  end


  def unsubscribe(selfId, username) do
    GenServer.cast(:main_server,{:unsubscribeTo, selfId, username})
  end

  def findIP(iter) do
    list = Enum.at(:inet.getif() |> Tuple.to_list, 1)
    if (elem(Enum.at(list, iter), 0) == {127, 0, 0, 1}) do
      findIP(iter+1)
    else
      elem(Enum.at(list, iter), 0) |> Tuple.to_list |> Enum.join(".")
    end
  end

  end