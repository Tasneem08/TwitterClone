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
    if  Map.has_key?(statusTable, username) do
       IO.puts "#{username} is an existing user."
    else
       IO.puts "#{username} is an NEW user... Updating the tables now.."
       statusTable = Map.put(statusTable, username, MapSet.new)
    end
    {:noreply, [statusTable, tweetsDB, hashtagMap, mentionsMap]}
  end

  def handle_cast({:initiateProtocol, map}, state) do
      # Process.sleep(50)
      [_, numNodes, algorithm, count, starttime] = state
      if map_size(map) <= 0.5*numNodes do
       diff =  DateTime.diff(DateTime.utc_now, starttime, :millisecond)
       IO.puts "Most nodes have died. Shutting down the protocol.. Convergence took #{diff} milliseconds."
       Process.exit(self(), :shutdown)
      end
      # IO.inspect "Infecting with #{map_size(map)} alive Nodes..."
      { pid, firstNode} = Enum.at(map, Enum.random(0..(map_size(map)-1)))
      #  selectedNeighborNode = String.to_atom("workernode"<>Integer.to_string(firstNode)<>"@"<>GossipNode.findIP())
      selectedNeighborServer =  String.to_atom("workerserver"<>Integer.to_string(firstNode))
      # a = DateTime.utc_now
      if Process.whereis(selectedNeighborServer) != nil do
      if algorithm == "push-sum" do
      GenServer.cast(selectedNeighborServer, {:infectPushSum, 0, 0})
      else
      GenServer.cast(selectedNeighborServer, {:infect})
      end
      end
      {:noreply, state}
  end

    def handle_cast({:findNextAgain}, state) do
       GenServer.cast(:main_server, {:initiateProtocol})
       {:noreply, state}
  end

      def handle_cast({:initiateProtocol, map, 0}, state) do
       [_, _, _, _, starttime] = state
       diff =  DateTime.diff(DateTime.utc_now, starttime, :millisecond)
       IO.puts "Most nodes have died. Shutting down the protocol.. Convergence took #{diff} milliseconds."
       Process.exit(self(), :shutdown)
  end

  def handle_call({:killMain}, _from, state) do
    
    IO.puts "Most nodes have died. Shutting down the protocol..."
    {:stop, :normal, state}
  end
end

# defmodule Gossip.Supervisor do
#     use Supervisor

#     def start_link(numNodes,topology,algorithm) do

#     if topology == "2D" or topology == "imp2D" do
#        #Readjust the number of nodes.
#        sqrt = :math.sqrt(numNodes)|> Float.ceil|> round
#        numNodes = sqrt*sqrt
#     end
#     children = Enum.map(Enum.to_list(1..numNodes), fn(nodeId) ->
#       worker(GossipNode, [nodeId, topology, numNodes, algorithm], [id: nodeId, restart: :permanent])
#     end)

#     Supervisor.start_link(children,strategy: :one_for_one, name: :super)
#     IO.puts "Done creating agents. Infecting a random node..."

#     childList = Supervisor.which_children(:super)
#     {firstNode, pid, _, _} = IO.inspect Enum.at(childList, Enum.random(0..(numNodes-1)))
#     selectedNeighborNode = String.to_atom("workernode"<>Integer.to_string(firstNode)<>"@"<>GossipNode.findIP())
#     selectedNeighborServer = String.to_atom("workerserver"<>Integer.to_string(firstNode))

#     # if algorithm == "pushsum" do
#     #   GenServer.cast({selectedNeighborServer, selectedNeighborNode}, {:infect, nodeId, 1})
#     # else
#     GenServer.call(selectedNeighborServer, {:infect})
#     :timer.sleep(:infinity)
#     # end
#   end
# end