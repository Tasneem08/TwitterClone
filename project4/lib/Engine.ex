defmodule Engine do
use GenServer

  def setupEngine() do
    # node start
    IO.inspect findIP(0)
    Node.start(String.to_atom("mainserver@"<>findIP(0)))
    cookie_name = String.to_atom("twitter")
    Node.set_cookie(cookie_name)
    start_link()
  end

  def start_link() do
      :ets.new(:hashtagMap, [:set, :public, :named_table])
      :ets.new(:mentionsMap, [:set, :public, :named_table])
      :ets.new(:followersTable, [:set, :public, :named_table])
      :ets.new(:followsTable, [:set, :public, :named_table])
      :ets.new(:tweetsDB, [:set, :public, :named_table])
      :ets.new(:userToIPMap, [:set, :public, :named_table])
      GenServer.start_link(__MODULE__, :ok, name: :main_server)
  end

  def init(:ok) do
      {:ok, 0} #Tweet ID
  end

  def handle_cast({:registerMe, username, userIP}, state) do
      nextID = state
      register_status = :ets.insert_new(:userToIPMap, {username, userIP})
      #userToIPMap = Map.put(userToIPMap, username, userIP)
      # followersTable = 
      if register_status == false do
        # Simulator.log("#{username} is an existing user.")
        # spawn(fn -> GenServer.cast({String.to_atom(username), String.to_atom(username<>"@"<>userIP)},{:queryYourTweets}) end)
        spawn(fn -> GenServer.cast({String.to_atom(username), userIP},{:queryYourTweets}) end)
        # Map.put(userToIPMap, username, userIP)
        # followersTable
        end
      {:noreply, nextID}
  end

# def handle_cast({:printMapping}, state) do
#     [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap, userToIPMap] = state
#     # IO.inspect "PRINTING MAPPING"
#     # IO.inspect followersTable
#     {:noreply, [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap, userToIPMap]}
# end

  def handle_cast({:subscribeTo, selfId, username}, state) do
      nextID = state

      mapSet =
      if :ets.lookup(:followersTable, username) == [] do
          MapSet.new
      else
          [{_, set}] = :ets.lookup(:followersTable, username)
          set
      end

      mapSet = MapSet.put(mapSet, selfId)

      spawn(fn->:ets.insert(:followersTable, {username, mapSet}) end)

      mapSet2 = 
      if :ets.lookup(:followsTable, selfId) == [] do
        MapSet.new
      else
       [{_, set}] = :ets.lookup(:followsTable, selfId)
       set
      end 

      mapSet2 = MapSet.put(mapSet2, username)
      # followsTable = Map.put(followsTable, selfId, mapSet2)
      spawn(fn->:ets.insert(:followsTable, {selfId, mapSet2})end)
      {:noreply, nextID}
  end

  # def handle_cast({:unsubscribeTo, selfId, username}, state) do
  #     [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap, userToIPMap] = state
  #     mapSet = Map.get(followersTable, username)
  #     mapSet = MapSet.delete(mapSet, selfId);
  #     followersTable = Map.put(followersTable, username, mapSet)

  #     mapSet = Map.get(followsTable, selfId)
  #     mapSet = MapSet.delete(mapSet, username);
  #     followsTable = Map.put(followsTable, selfId, mapSet)
  #     {:noreply, [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap, userToIPMap]}
  # end

  def handle_cast({:tweet, username, tweetBody}, state) do
      nextID = state
      {content, hashtags, mentions} = tweetBody
      # insert into tweetsDB get size - index / key. insert value mei tuple.
      Simulator.log("TweetID: #{nextID} => #{username} posted a new tweet : #{content}")
      # TweetID #{nextID} => 
      # index = Kernel.map_size(tweetsDB)
      spawn(fn->:ets.insert(:tweetsDB, {nextID, username, content})end)
      # tweetsDB = Map.put(tweetsDB, index, {username, content})
      spawn(fn -> updateMentionsMap(mentions, nextID) end)
      spawn(fn -> updateHashTagMap(hashtags, nextID) end)
      
      #broadcast 
      spawn(fn->sendToFollowers(MapSet.to_list(elem(List.first(:ets.lookup(:followersTable, username)), 1)), nextID, username, content) end)
      spawn(fn->sendToFollowers(mentions, nextID, username, content) end)

      {:noreply, nextID+1}
  end

    def handle_cast({:reTweet, username, tweetIndex}, state) do
      nextID = state
      #{content, hashtags, mentions} = tweetBody
      # insert into tweetsDB get size - index / key. insert value mei tuple.
      
      [{_, original_tweeter, content}] = :ets.lookup(:tweetsDB, tweetIndex)
      Simulator.log("TweetID: #{nextID} => #{username} posted a retweet of tweetID #{tweetIndex}")
      {org_tweeter, contentfinal} = 
      if is_tuple(content) do 
            {org_tweet, org_content} = content
            {org_tweet, org_content}
      else
            {original_tweeter, content}
      end
      
      # index = Kernel.map_size(tweetsDB)
      # tweetsDB = Map.put(tweetsDB, nextID, {username, {original_tweeter, content}})
      :ets.insert_new(:tweetsDB, {nextID, username, {org_tweeter, contentfinal}})

      #mentionsMap = updateMentionsMap(mentionsMap, mentions, index)
      #hashtagMap = updateHashTagMap(hashtagMap, hashtags, index)
    #   IO.inspect tweetsDB
      #broadcast 
      spawn(fn -> sendToFollowers(MapSet.to_list(elem(List.first(:ets.lookup(:followersTable, username)), 1)), nextID, username, {original_tweeter, content})end)
      
      {:noreply, nextID+1}
  end

  def handle_cast({:myMentions, username}, state) do
      mentions =
      if :ets.lookup(:mentionsMap, username) == [] do
        MapSet.new
      else
        [{_, set}] = :ets.lookup(:mentionsMap, username)
        set
      end
      mentionedTweets = getMentions(MapSet.to_list(mentions), [])
      spawn(fn -> GenServer.cast({String.to_atom(username), elem(List.first(:ets.lookup(:userToIPMap, username)), 1)},{:receiveMyMentions, mentionedTweets}) end)
      {:noreply, state}
  end

  def handle_cast({:tweetsWithHashtag, hashtag, username}, state) do
      tweets = 
      if :ets.lookup(:hashtagMap, hashtag) == [] do
        MapSet.new
      else
        [{_, set}] = :ets.lookup(:hashtagMap, hashtag)
        set
      end

      hashtagTweets = getHashtags(MapSet.to_list(tweets), [])
      spawn(fn -> GenServer.cast({String.to_atom(username), elem(List.first(:ets.lookup(:userToIPMap, username)), 1)},{:receiveHashtagResults, hashtagTweets}) end)
      {:noreply, state}
  end

  def handle_cast({:queryTweets, username}, state) do
      mapSet = 
      if :ets.lookup(:followsTable,username) == [] do
        MapSet.new
      else
        [{_, set}] = :ets.lookup(:followsTable,username)
        set
      end 
      relevantTweets = fetchRelevantTweets(mapSet)

      mentions = 
      if :ets.lookup(:mentionsMap,username) == [] do
        MapSet.new
      else 
        [{_, set}] = :ets.lookup(:mentionsMap,username)
        set
      end

      mentionedTweets = getMentions(MapSet.to_list(mentions), [])
      spawn(fn -> GenServer.cast({String.to_atom(username), elem(List.first(:ets.lookup(:userToIPMap, username)), 1)},{:receiveQueryResults, relevantTweets, mentionedTweets}) end)
      {:noreply, state}
  end
  
  # def fetchRelevantTweets([firstTweet |tweetsDB], mapSet, relevantTweets) do
  #       {_, {tweeter,content}} = firstTweet
  #       relevantTweets = 
  #       if MapSet.member?(mapSet, tweeter) do
  #           List.insert_at(relevantTweets, 0, firstTweet)
  #       else
  #           relevantTweets
  #       end
  #       fetchRelevantTweets(tweetsDB, mapSet, relevantTweets)
  # end

  # def fetchRelevantTweets([], _, relevantTweets) do
  #       relevantTweets
  # end
  
  def fetchRelevantTweets(mapSet) do
      result = 
      for f_user <- MapSet.to_list(mapSet) do
        list_of_tweets = List.flatten(:ets.match(:tweetsDB, {:_, f_user, :"$1"}))
        Enum.map(list_of_tweets, fn tweet -> {f_user, tweet} end)
    end
    List.flatten(result)
  end

  def sendToFollowers([first | followers], index, username, content) do
      spawn(fn->GenServer.cast({String.to_atom(first), elem(List.first(:ets.lookup(:userToIPMap, first)), 1)},{:receiveTweet, index, username, content})end) 
      # spawn(fn->GenServer.cast(String.to_atom(first),{:receiveTweet, index, username, content})end) 

      sendToFollowers(followers, index, username, content)
  end
  
  def sendToFollowers([], _, _, _) do
  end

  def getHashtags([index | rest], hashtagTweets) do
      [{index, username, content}] = :ets.lookup(:tweetsDB, index)
      hashtagTweets = List.insert_at(hashtagTweets, 0, {index, {username, content}})
      getHashtags(rest, hashtagTweets)
  end

  def getHashtags([], hashtagTweets) do
      hashtagTweets
  end

  def getMentions([index | rest], mentionedTweets) do
      [{index, username, content}] = :ets.lookup(:tweetsDB, index)
      mentionedTweets = List.insert_at(mentionedTweets, 0, {index, {username, content}})
      getMentions(rest, mentionedTweets)
  end

  def getMentions(_, [], mentionedTweets) do
    mentionedTweets
  end

  def updateMentionsMap([mention | mentions], index) do
      elems = 
      if :ets.lookup(:mentionsMap, mention) == [] do
          element = MapSet.new
          MapSet.put(element, index)
      else
          [{_,element}] = :ets.lookup(:mentionsMap, mention)
        MapSet.put(element, index)
      end

      :ets.insert(:mentionsMap, {mention, elems})
      updateMentionsMap(mentions, index)
  end

  def updateMentionsMap([], _) do
  end

  def updateHashTagMap([hashtag | hashtags], index) do
      elems = 
      if :ets.lookup(:hashtagMap, hashtag) == [] do
          element = MapSet.new
          MapSet.put(element, index)
      else
          [{_,element}] = :ets.lookup(:hashtagMap, hashtag)
          MapSet.put(element, index)
      end

      :ets.insert(:hashtagMap, {hashtag, elems})
      updateHashTagMap(hashtags, index)
  end

  def updateHashTagMap([], _) do
  end

  # Returns the IP address of the machine the code is being run on.
  def findIP(iter) do
    list = Enum.at(:inet.getif() |> Tuple.to_list, 1)
    if (elem(Enum.at(list, iter), 0) == {127, 0, 0, 1}) do
      findIP(iter+1)
    else
      elem(Enum.at(list, iter), 0) |> Tuple.to_list |> Enum.join(".")
    end
  end

end
