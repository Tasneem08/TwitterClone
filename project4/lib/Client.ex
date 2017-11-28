  # Sets up the worker/ Client

  defmodule Client do
  use GenServer

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

  def start_link(username) do
      #clientname = String.to_atom(username)
      #Create node .. node start
      clientname = String.to_atom(username<>"@"<>findIP(0))
      Node.start(clientname)
      Node.set_cookie(String.to_atom("twitter"))

      GenServer.start_link(__MODULE__, [username, MapSet.new,[],[],[],[]],name: clientname)
  end

  def init(username, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets) do
      {:ok, {username, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets}}
  end


  def handle_cast({:kill_self}, state) do
      {:stop, :normal, state}
  end

  def handle_cast({:receiveTweet, index, tweeter, content}, state) do
     [username, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets] = state
     seenTweets = MapSet.put(seenTweets, index)
      if is_tuple(content) do
        {org_tweeter, text} = content
        Simulator.log(" #{username} sees #{tweeter} retweeted #{org_tweeter} ka post : #{text}")
      else
        Simulator.log(" #{username} sees #{tweeter} posted a new tweet : #{content}")
      end
      {:noreply, [username, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets]}
  end

  def handle_cast({:register_user, username}, state) do
     [username, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets] = state
     GenServer.cast(:main_server,{:registerMe, username})
    {:noreply, [username, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets]}
  end

  def register_user(username, server) do
    #node.connect with server .. server
    Node.connect(String.to_atom("mainserver@"<>server))
    GenServer.cast(:main_server,{:registerMe, username})
  end

  def handle_cast({:retweet, selfId, tweetIndex}, state) do
     [username, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets] = state
     GenServer.cast(:main_server,{:reTweet, selfId, tweetIndex}) 
     {:noreply, [username, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets]}
  end
  

  def handle_call({:getRetweetIndex}, _from, state) do
     [username, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets] = state
     tweetList = MapSet.to_list(seenTweets)
     rand_Index = Enum.random(1..Enum.count(tweetList))
     selectedTweet = Enum.at(tweetList, rand_Index - 1)

     {:reply, selectedTweet, [username, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets]}
  end

  def retweet(selfId, tweetIndex) do
    GenServer.cast(:main_server,{:reTweet, selfId, tweetIndex}) 
  end

  def handle_cast({:subscribe_to,selfId, username}, state) do
     [username, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets] = state
      GenServer.cast(:main_server,{:subscribeTo, selfId, username}) 
     {:noreply, [username, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets]}
  end

  def subscribe_to(selfId, username) do
    GenServer.cast(:main_server,{:subscribeTo, selfId, username}) 
  end

#change
  def handle_cast({:search_by_hashtags, hashtag}, state) do
     [username, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets] = state
      IO.inspect hashtag_list = GenServer.call(:main_server,{:tweetsWithHashtag, hashtag})
     {:noreply, [username, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets]}
  end

  def handle_cast({:getMyMentions}, state) do
     [username, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets] = state
     IO.inspect mentions_list=GenServer.call(:main_server,{:myMentions, username})    
     {:noreply, [username, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets]}
  end

  def handle_cast({:queryYourTweets}, state) do
     [username, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets] = state
     IO.inspect {relevantTweets, mentionedTweets}=GenServer.call(:main_server,{:queryTweets, username})
     {:noreply, [username, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets]} #not keeping mentioned tweets
  end

  def handle_cast({:tweet, tweet_content}, state) do
     [username, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets] = state

      content=tweet_content
      split_words=String.split(content," ")
      hashtags=findHashTags(split_words,[])
      mentions=findMentions(split_words,[])
      tweetBody={content, hashtags, mentions}

      GenServer.cast(:main_server,{:tweet,username, tweetBody})

      {:noreply, [username, seenTweets,hashtag_list,mentions_list,relevantTweets,mentionedTweets]}
  end
  
  def findHashTags([head|tail],hashList) do
    if(String.first(head)=="#") do
      # [_, elem] = String.split(head, "#") 
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