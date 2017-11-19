defmodule Engine do
use GenServer
# entry point to the code. Read command line arguments and invoke the right things here.
  # Entry point to the code. 
  def main() do
      hashtagMap = %{}
      mentionsMap = %{}
      followersTable = %{}
      followsTable = %{}
      tweetsDB = {}

      # Start gen server
      start_link(followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap)

     :timer.sleep(:infinity)
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
      mapSet = Map.get(followersTable, username) 
      mapSet = MapSet.put(mapSet, selfId)
      followersTable = Map.put(followersTable, username, mapSet)

      mapSet = Map.get(followsTable, selfId) 
      mapSet = MapSet.put(mapSet, username)
      followsTable = Map.put(followsTable, selfId, mapSet)

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

      index = Kernel.map_size(tweetsDB)
      tweetsDB = Map.put(tweetsDB, index, {username, content})
      mentionsMap = updateMentionsMap(mentionsMap, mentions, index)
      hashtagMap = updateHashTagMap(hashtagMap, hashtags, index)
      
      #broadcast 
      sendToFollowers(MapSet.to_list(Map.get(followersTable, username)), content)

      {:noreply, [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap]}
  end

  def handle_call({:myMentions, username}, state) do
      [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap] = state
      mentions = Map.get(mentionsMap, username)
      mentionedTweets = getMentions(tweetsDB, MapSet.to_list(mentions), [])
      {:reply, mentionedTweets, [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap]}
  end

  def handle_call({:tweetsWithHashtag, hashtag}, state) do
      [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap] = state
      tweets = Map.get(hashtagMap, hashtag)
      hashtagTweets = getHashtags(tweetsDB, MapSet.to_list(tweets), [])
      {:reply, hashtagTweets, [followersTable, followsTable, tweetsDB, hashtagMap, mentionsMap]}
  end

  def sendToFollowers([first | followers], content) do
      GenServer.cast(String.to_atom(first),{:receiveTweet, content}) 
      sendToFollowers(followers, content)
  end
  
  def sendToFollowers([], _) do
  end

  def getHashtags(tweetsDB, [index | rest], hashtagTweets) do
      hashtagTweets = Enum.concat(Map.get(tweetsDB, index), hashtagTweets)
      getHashtags(tweetsDB, rest, hashtagTweets)
  end

  def getHashtags(_, [], hashtagTweets) do
      hashtagTweets
  end

  def getMentions(tweetsDB, [index | rest], mentionedTweets) do
      mentionedTweets = Enum.concat(Map.get(tweetsDB, index), mentionedTweets)
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
