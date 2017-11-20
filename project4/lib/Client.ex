  # Sets up the worker/ Client

  defmodule Client do
  use GenServer

  def simulateClient(username, numClients) do
    # register_user
    # subscribe to random users
    # send n tweets to main_server
    pid = register_user(username)
    for _ <- 1..3 do
    subscribe_to(username, "user" <> Integer.to_string(Enum.random(1..30)))
    end

    for i <- 1..2 do
      tweet(username, "test string by " <> username <> "attempt - " <> Integer.to_string(i))
    end
  end

  def start_link(username) do
      GenServer.start_link(Client, name: String.to_atom(username))
  end

  def init() do
      {:ok}
  end

  def handle_cast({:receiveTweet, index, tweeter, content}, state) do
  IO.inspect "in handle cast" 
      if is_tuple(content) do
        {org_tweeter, text} = content
        IO.inspect "#{tweeter} retweeted #{org_tweeter} ka post : #{text}"
      else
        IO.inspect "#{tweeter} posted a new tweet : #{content}"
      end
      {:noreply, state}
  end

  def register_user(username) do
    {_, pid} = start_link(username)
    #username = String.to_atom("mmathkar"<>(:erlang.monotonic_time() |> :erlang.phash2(256) |> Integer.to_string(16))<>"@"<>findIP())
    GenServer.cast(:main_server,{:registerMe, username})    
    pid
  end

  def retweet(selfId, tweetIndex) do
    GenServer.cast(:main_server,{:reTweet, selfId, tweetIndex}) 
  end

  def subscribe_to(selfId, username) do
    GenServer.cast(:main_server,{:subscribeTo, selfId, username}) 
  end

  def search_by_hashtags(hashtag) do
    hashtag_list = GenServer.call(:main_server,{:tweetsWithHashtag, hashtag})
    hashtag_list
  end

  def getMyMentions(username) do
    mentions_list=GenServer.call(:main_server,{:myMentions, username})
    mentions_list
  end

  def queryTweets(username) do
    tweets_list=GenServer.call(:main_server,{:queryTweets, username})
    tweets_list
  end

  def tweet(username, tweet_content) do

#    {content, hashtags, mentions} = tweetBody

   content=tweet_content
   split_words=String.split(content," ")
   hashtags=findHashTags(split_words,[])
   mentions=findMentions(split_words,[])
   tweetBody={content, hashtags, mentions}

    GenServer.cast(:main_server,{:tweet,username, tweetBody})
  end

  def findHashTags([head|tail],hashList) do
    if(String.first(head)=="#") do
      findHashTags(tail,Enum.concat(head,hashList))

    else 
      findHashTags(tail,hashList)
    end

  end

  def findHashTags([],hashList) do
    hashList
  end

  def findMentions([head|tail],mentionList) do
    if(String.first(head)=="@") do
      findMentions(tail,Enum.concat(head,mentionList))

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

  

   # Returns the IP address of the machine the code is being run on.
  # def findIP do
  #   {ops_sys, extra } = :os.type
  #   ip = 
  #   case ops_sys do
  #     :unix -> 
  #           if extra == :linux do
  #             {:ok, [addr: ip]} = :inet.ifget('ens3', [:addr])
  #             to_string(:inet.ntoa(ip))
  #           else
  #             {:ok, [addr: ip]} = :inet.ifget('en0', [:addr])
  #             to_string(:inet.ntoa(ip))
  #           end
  #     :win32 -> {:ok, [ip, _]} = :inet.getiflist
  #              to_string(ip)
  #   end
  # (ip)
  # end

  end