defmodule Engine do
use GenServer

  def setupEngine() do
    # node start
    IO.inspect findIP(0)
    Node.start(String.to_atom("mainserver@"<>findIP(0)))
    cookie_name = String.to_atom("twitter")
    Node.set_cookie(cookie_name)
    start_link()
    :timer.sleep(:infinity)
  end

  def start_link() do
      hashtagMap = %{}
      mentionsMap = %{}
      followersTable = %{}
      followsTable = %{}
      tweetsDB = %{}
      userToIPMap = %{}
      GenServer.start_link(__MODULE__, [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap, userToIPMap], name: :main_server)
  end

  def init(followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap, userToIPMap) do
      {:ok, {followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap, userToIPMap}}
  end

  def handle_cast({:registerMe, username, userIP}, state) do
      [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap, userToIPMap] = state
      userToIPMap = Map.put(userToIPMap, username, userIP)
      followersTable = 
      if Map.has_key?(followersTable, username) do
        # Simulator.log("#{username} is an existing user.")
        # spawn(fn -> GenServer.cast({String.to_atom(username), String.to_atom(username<>"@"<>userIP)},{:queryYourTweets}) end)
        spawn(fn -> GenServer.cast({String.to_atom(username), userIP},{:queryYourTweets}) end)
        # Map.put(userToIPMap, username, userIP)
        followersTable
      else
        # Simulator.log("#{username} is an NEW user... Updating the tables now..")

        Map.put(followersTable, username, MapSet.new)
      end
      {:noreply, [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap, userToIPMap]}
  end

def handle_cast({:printMapping}, state) do
    [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap, userToIPMap] = state
    # IO.inspect "PRINTING MAPPING"
    # IO.inspect followersTable
    {:noreply, [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap, userToIPMap]}
end

  def handle_cast({:subscribeTo, selfId, username}, state) do
      [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap, userToIPMap] = state
      mapSet = 
      if Map.get(followersTable, username) == nil do
        MapSet.new
      else
       Map.get(followersTable, username)
      end 

      mapSet = MapSet.put(mapSet, selfId)
      followersTable = Map.put(followersTable, username, mapSet)

      mapSet2 = 
      if Map.get(followsTable, selfId) == nil do
        MapSet.new
      else
       Map.get(followsTable, selfId)
      end 
      mapSet2 = MapSet.put(mapSet2, username)
      followsTable = Map.put(followsTable, selfId, mapSet2)
      {:noreply, [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap, userToIPMap]}
  end

  def handle_cast({:unsubscribeTo, selfId, username}, state) do
      [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap, userToIPMap] = state
      mapSet = Map.get(followersTable, username)
      mapSet = MapSet.delete(mapSet, selfId);
      followersTable = Map.put(followersTable, username, mapSet)

      mapSet = Map.get(followsTable, selfId)
      mapSet = MapSet.delete(mapSet, username);
      followsTable = Map.put(followsTable, selfId, mapSet)
      {:noreply, [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap, userToIPMap]}
  end

  def handle_cast({:tweet, username, tweetBody}, state) do
      [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap, userToIPMap] = state
      {content, hashtags, mentions} = tweetBody
      # insert into tweetsDB get size - index / key. insert value mei tuple.
      Simulator.log("AT SERVER #{username} posted a new tweet : #{content}")
      index = Kernel.map_size(tweetsDB)
      tweetsDB = Map.put(tweetsDB, index, {username, content})
      mentionsMap = updateMentionsMap(mentionsMap, mentions, index)
      hashtagMap = updateHashTagMap(hashtagMap, hashtags, index)
      
      #broadcast 
      spawn(fn->sendToFollowers(MapSet.to_list(Map.get(followersTable, username)), userToIPMap, index, username, content)end)
      spawn(fn->sendToFollowers(mentions, userToIPMap, index, username, content)end)

      {:noreply, [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap, userToIPMap]}
  end

    def handle_cast({:reTweet, username, tweetIndex}, state) do
      [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap, userToIPMap] = state
      #{content, hashtags, mentions} = tweetBody
      # insert into tweetsDB get size - index / key. insert value mei tuple.
      {original_tweeter, content} = Map.get(tweetsDB, tweetIndex)
      {original_tweeter, content} = 
      if is_tuple(content) do 
            {original_tweeter, content} = content
      else
            {original_tweeter, content}
      end
      
      index = Kernel.map_size(tweetsDB)
      tweetsDB = Map.put(tweetsDB, index, {username, {original_tweeter, content}})
      #mentionsMap = updateMentionsMap(mentionsMap, mentions, index)
      #hashtagMap = updateHashTagMap(hashtagMap, hashtags, index)
    #   IO.inspect tweetsDB
      #broadcast 
      spawn(fn -> sendToFollowers(MapSet.to_list(Map.get(followersTable, username)), userToIPMap, index, username, {original_tweeter, content})end)
      
      {:noreply, [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap, userToIPMap]}
  end

  def handle_call({:myMentions, username}, _from, state) do
      [_, _, tweetsDB, _, mentionsMap, userToIPMap] = state
      mentions = 
      if Map.get(mentionsMap, username) == nil do
        MapSet.new
      else 
        Map.get(mentionsMap, username)
      end
      mentionedTweets = getMentions(tweetsDB, MapSet.to_list(mentions), [])
      {:reply, mentionedTweets, state}
  end

  def handle_call({:tweetsWithHashtag, hashtag}, _from, state) do
      [_, _, tweetsDB, hashtagMap, _, userToIPMap] = state
      tweets = 
      if Map.get(hashtagMap, hashtag) == nil do
        MapSet.new
      else 
        Map.get(hashtagMap, hashtag)
      end
      hashtagTweets = getHashtags(tweetsDB, MapSet.to_list(tweets), [])
      {:reply, hashtagTweets, state}
  end

  def handle_call({:queryTweets, username}, _from, state) do
      [_, followsTable, tweetsDB, _, mentionsMap, userToIPMap] = state
      mapSet = 
      if Map.get(followsTable, username) == nil do
        MapSet.new
      else
       Map.get(followsTable, username)
      end 
      relevantTweets = fetchRelevantTweets(Map.to_list(tweetsDB), mapSet, [])
      mentions = 
      if Map.get(mentionsMap, username) == nil do
        MapSet.new
      else 
        Map.get(mentionsMap, username)
      end
      mentionedTweets = getMentions(tweetsDB, MapSet.to_list(mentions), [])

      {:reply, {relevantTweets, mentionedTweets}, state}
  end
  
  def fetchRelevantTweets([firstTweet |tweetsDB], mapSet, relevantTweets) do
        {_, {tweeter,content}} = firstTweet
        relevantTweets = 
        if MapSet.member?(mapSet, tweeter) do
            List.insert_at(relevantTweets, 0, firstTweet)
        else
            relevantTweets
        end
        fetchRelevantTweets(tweetsDB, mapSet, relevantTweets)
  end

  def fetchRelevantTweets([], _, relevantTweets) do
        relevantTweets
  end

  def sendToFollowers([first | followers], userToIPMap, index, username, content) do
      spawn(fn->GenServer.cast({String.to_atom(first), Map.get(userToIPMap,first)},{:receiveTweet, index, username, content})end) 
      # spawn(fn->GenServer.cast(String.to_atom(first),{:receiveTweet, index, username, content})end) 

      sendToFollowers(followers, userToIPMap, index, username, content)
  end
  
  def sendToFollowers([], _, _, _, _) do
  end

  def getHashtags(tweetsDB, [index | rest], hashtagTweets) do
      hashtagTweets = List.insert_at(hashtagTweets, 0, {index, Map.get(tweetsDB, index)})
      getHashtags(tweetsDB, rest, hashtagTweets)
  end

  def getHashtags(_, [], hashtagTweets) do
      hashtagTweets
  end

  def getMentions(tweetsDB, [index | rest], mentionedTweets) do
      mentionedTweets = List.insert_at(mentionedTweets, 0, {index, Map.get(tweetsDB, index)})
      getMentions(tweetsDB, rest, mentionedTweets)
  end

  def getMentions(_, [], mentionedTweets) do
    mentionedTweets
  end

  def updateMentionsMap(mentionsMap, [mention | mentions], index) do
      elems = 
      if Map.has_key?(mentionsMap, mention) do
        element = Map.get(mentionsMap, mention)
        MapSet.put(element, index)
      else
        element = MapSet.new
        MapSet.put(element, index)
      end
      mentionsMap = Map.put(mentionsMap, mention, elems)
      updateMentionsMap(mentionsMap, mentions, index)
  end

  def updateMentionsMap(mentionsMap, [], _) do
      mentionsMap
  end

  def updateHashTagMap(hashtagMap, [hashtag | hashtags], index) do
      elems = 
      if Map.has_key?(hashtagMap, hashtag) do
        element = Map.get(hashtagMap, hashtag)
        MapSet.put(element, index)
      else
        element = MapSet.new
        MapSet.put(element, index)
      end
      hashtagMap = Map.put(hashtagMap, hashtag, elems)
      updateHashTagMap(hashtagMap, hashtags, index)
  end

  def updateHashTagMap(hashtagMap, [], _) do
      hashtagMap
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
