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

end
