defmodule Engine do
use GenServer
# entry point to the code. Read command line arguments and invoke the right things here.
  # Entry point to the code. 
  def main() do
      hashtagMap=%{}
      mentionsMap=%{}
      statusTable = %{}
      tweetsDB = {}

      # Start gen server
      start_link(statusTable, tweetsDB, hashtagMap, mentionsMap)

     :timer.sleep(:infinity)
  end
  
  def start_link(statusTable, tweetsDB, hashtagMap, mentionsMap) do
      GenServer.start_link(Engine, [statusTable, tweetsDB, hashtagMap, mentionsMap], name: :main_server)
  end

  def init(statusTable, tweetsDB, hashtagMap, mentionsMap) do
      {:ok, {statusTable, tweetsDB, hashtagMap, mentionsMap}}
  end

  def handle_cast({:registerMe, username}, state) do
      [statusTable, tweetsDB, hashtagMap, mentionsMap] = state
      if Map.has_key?(statusTable, username) do
        IO.puts "#{username} is an existing user."
      else
        IO.puts "#{username} is an NEW user... Updating the tables now.."
        statusTable = Map.put(statusTable, username, MapSet.new)
      end
      {:noreply, [statusTable, tweetsDB, hashtagMap, mentionsMap]}
  end

  def handle_cast({:subscribeTo, selfId, username}, state) do
      [statusTable, tweetsDB, hashtagMap, mentionsMap] = state
      mapSet = Map.get(statusTable, :selfId)
      mapSet = MapSet.put(mapSet, username);
      statusTable = Map.put(statusTable, selfId, mapSet)
      {:noreply, [statusTable, tweetsDB, hashtagMap, mentionsMap]}
  end

  def handle_cast({:unsubscribeTo, selfId, username}, state) do
      [statusTable, tweetsDB, hashtagMap, mentionsMap] = state
      mapSet = Map.get(statusTable, :selfId)
      mapSet = MapSet.delete(mapSet, username);
      statusTable = Map.put(statusTable, selfId, mapSet)
      {:noreply, [statusTable, tweetsDB, hashtagMap, mentionsMap]}
  end

  def handle_cast({:tweet, username, tweetBody}, state) do
      [statusTable, tweetsDB, hashtagMap, mentionsMap] = state
      {content, hashtags, mentions} = tweetBody
      
      
      {:noreply, [statusTable, tweetsDB, hashtagMap, mentionsMap]}
  end

  def handle_call({:myMentions, username}, state) do
      [statusTable, tweetsDB, hashtagMap, mentionsMap] = state
      mentions = Map.get(mentionsMap, username)
      mentionedTweets = getMentions(tweetsDB, MapSet.to_list(mentions), [])
      {:reply, [statusTable, tweetsDB, hashtagMap, mentionsMap]}
  end

  def getMentions(tweetsDB, [index | rest], mentionedTweets) do
      
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
