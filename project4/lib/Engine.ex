defmodule Engine do
use GenServer
# entry point to the code. Read command line arguments and invoke the right things here.
  # Entry point to the code. 
  def main(args) do
      total = List.first(args) |> String.to_integer()
      hashtagMap = %{}
      mentionsMap = %{}
      followersTable = %{}
      followsTable = %{}
      tweetsDB = %{}
      
      start_Client(total)
      # Start gen server
      start_link(followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap)
      simulate(total)
      
     :timer.sleep(:infinity)
  end

def start_Client(numClients) do
     for client <- 1..numClients do
            #spawn(fn -> Client.register_user("user" <> Integer.to_string(client)) end)
            Client.start_link("user" <> Integer.to_string(client))
            #Client.register_user("user" <> Integer.to_string(client))
     end
end
    def simulate(numClients) do 
        for client <- 1..numClients do
            #spawn(fn -> Client.register_user("user" <> Integer.to_string(client)) end)
            #Client.start_link("user" <> Integer.to_string(client))
            Client.register_user("user" <> Integer.to_string(client))
        end


  

        Client.subscribe_to("user2", "user1")
        Client.subscribe_to("user4", "user1")
        Client.subscribe_to("user3", "user1")
        Client.subscribe_to("user1", "user5")

      for client <- 1..numClients do
            spawn(fn -> Client.simulateClient("user" <> Integer.to_string(client), numClients) end)
            #Client.simulateClient("user" <> Integer.to_string(client), numClients)
    end
        # Client.tweet("user2", "this is a test tweet.")

    end

  def start_link(followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap) do
      GenServer.start_link(Engine, [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap], name: :main_server)
  end

  def init(followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap) do
      {:ok, {followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap}}
  end

  def handle_cast({:registerMe, username}, state) do
      [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap] = state
      followersTable = 
      if Map.has_key?(followersTable, username) do
        IO.puts "#{username} is an existing user."
        followersTable
      else
        IO.puts "#{username} is an NEW user... Updating the tables now.."
        Map.put(followersTable, username, MapSet.new)
      end
      {:noreply, [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap]}
  end

  def handle_cast({:subscribeTo, selfId, username}, state) do
      [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap] = state
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
      {:noreply, [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap]}
  end

  def handle_cast({:unsubscribeTo, selfId, username}, state) do
      [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap] = state
      mapSet = Map.get(followersTable, username)
      mapSet = MapSet.delete(mapSet, selfId);
      followersTable = Map.put(followersTable, username, mapSet)

      mapSet = Map.get(followsTable, selfId)
      mapSet = MapSet.delete(mapSet, username);
      followsTable = Map.put(followsTable, selfId, mapSet)
      {:noreply, [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap]}
  end

  def handle_cast({:tweet, username, tweetBody}, state) do
      [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap] = state
      {content, hashtags, mentions} = tweetBody
      # insert into tweetsDB get size - index / key. insert value mei tuple.
    #   IO.puts "AT SERVER #{username} posted a new tweet : #{content}"
      index = Kernel.map_size(tweetsDB)
      tweetsDB = Map.put(tweetsDB, index, {username, content})
      mentionsMap = updateMentionsMap(mentionsMap, mentions, index)
      hashtagMap = updateHashTagMap(hashtagMap, hashtags, index)
      
      #broadcast 
      sendToFollowers(MapSet.to_list(Map.get(followersTable, username)), index, username, content)

      {:noreply, [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap]}
  end

    def handle_cast({:reTweet, username, tweetIndex}, state) do
      [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap] = state
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
      
      #broadcast 
      sendToFollowers(MapSet.to_list(Map.get(followersTable, username)), index, username, {original_tweeter, content})

      {:noreply, [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap]}
  end

  def handle_call({:myMentions, username}, _from, state) do
      [_, _, tweetsDB, _, mentionsMap] = state
      mentions = Map.get(mentionsMap, username)
      mentionedTweets = getMentions(tweetsDB, MapSet.to_list(mentions), [])
      {:reply, mentionedTweets, state}
  end

  def handle_call({:tweetsWithHashtag, hashtag}, _from, state) do
      [_, _, tweetsDB, hashtagMap, _] = state
      tweets = Map.get(hashtagMap, hashtag)
      hashtagTweets = getHashtags(tweetsDB, MapSet.to_list(tweets), [])
      {:reply, hashtagTweets, state}
  end

  def handle_call({:queryTweets, username}, _from, state) do
      [_, followsTable, tweetsDB, _, mentionsMap] = state
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
            # Enum.concat({tweeter, content}, relevantTweets)
        else
            relevantTweets
        end
        fetchRelevantTweets(tweetsDB, mapSet, relevantTweets)
  end

  def fetchRelevantTweets([], _, relevantTweets) do
        relevantTweets
  end

  def sendToFollowers([first | followers], index, username, content) do
      GenServer.cast(String.to_atom(first),{:receiveTweet, index, username, content}) 
      sendToFollowers(followers, index, username, content)
  end
  
  def sendToFollowers([], _, _, _) do
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

end
