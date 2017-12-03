defmodule Simulator do

def main(args) do
    try do
        [ipAddr, num] = args
        total = String.to_integer(num)

        setupStaticData(total, ipAddr)
        # Start the clients
         start_Client(ipAddr)
        Process.sleep(5000)
        # Start the simulation
        simulate(ipAddr)
        Process.sleep(15000)
        spawn(fn-> getMyMentions() end)
        Process.sleep(5000)
        spawn(fn-> searchByHashtag() end)
        Process.sleep(5000)
        spawn(fn-> killClients(ipAddr) end)
       
    rescue
        MatchError -> Engine.setupEngine()
    end
        :timer.sleep(:infinity)
  end

def log(str) do
    IO.puts str
end
# def main(args) do
#     total = List.first(args) |> String.to_integer()
#     # Start the engine
#     Engine.start_link()
    
#     setupStaticData(total)
#     # Start the clients
#     start_Client()
    
#     # Start the simulation
#     simulate()
#     Process.sleep(15000)
#     spawn(fn-> getMyMentions() end)
#     Process.sleep(5000)
#     spawn(fn-> searchByHashtag() end)
#     Process.sleep(5000)
#     spawn(fn-> killClients() end)
#     :timer.sleep(:infinity)
# end

def setupStaticData(total, serverIP) do
      clientname = String.to_atom("client"<>"@"<>findIP(0))
      Node.start(clientname)
      Node.set_cookie(String.to_atom("twitter"))
    :ets.new(:staticFields, [:named_table])
    :ets.insert(:staticFields, {"totalNodes", total})
    :ets.insert(:staticFields, {"sampleTweets", ["Please come to my party. ","Don't you dare come to my party. ","Why won't you invite me to your party? ","But I wanna come to your party. ","Okay I won't come to your party. "]})
    :ets.insert(:staticFields, {"hashTags", ["#adoptdontshop ","#UFisGreat ","#Fall2017 ","#DinnerParty ","#cutenesscatified "]})
    Node.connect(String.to_atom("mainserver@"<>serverIP))
end
 
# def start_Client() do
#     [{_, numClients}] = :ets.lookup(:staticFields, "totalNodes")
#      for client <- 1..numClients do
#             spawn(fn -> Client.start_link("user" <> Integer.to_string(client)) end)
#             spawn(fn -> Client.register_user("user" <> Integer.to_string(client)) end)
#      end
# end

def start_Client(ipAddr) do
    [{_, numClients}] = :ets.lookup(:staticFields, "totalNodes")
     for client <- 1..numClients do
            Client.start_link("user" <> Integer.to_string(client), ipAddr)
            Client.register_user("user" <> Integer.to_string(client), ipAddr)
     end
end

def getMyMentions() do
    [{_, numClients}] = :ets.lookup(:staticFields, "totalNodes")
    IO.inspect "GETTING MY MENTIONS"

    # select 5 random to kill and store these ids in a list
    clientIds = for i<- 1..5 do
        client = Enum.random(1..numClients)
    end

    for j <- clientIds do
        spawn(fn -> GenServer.cast(String.to_atom("user"<>Integer.to_string(j)),{:getMyMentions}) end)
    end
end

def searchByHashtag() do
    [{_, hashTags}] = :ets.lookup(:staticFields, "hashTags")
    IO.inspect "SEARCHING BY HASHTAG"
    
    # select 5 random to kill and store these ids in a list
    for i<- 1..5 do
        hashTag = Enum.random(hashTags)
        IO.inspect hashTag
        spawn(fn -> GenServer.cast(String.to_atom("user"<>Integer.to_string(i)),{:search_by_hashtags, String.trim(hashTag)}) end)
    end

end

def killClients(ipAddr) do
    [{_, numClients}] = :ets.lookup(:staticFields, "totalNodes")
    
    # select 5 random to kill and store these ids in a list
    clientIds = for i<- 1..5 do
        client = Enum.random(1..numClients)
    end
     IO.inspect clientIds

    for j <- clientIds do
        spawn(fn -> GenServer.cast(String.to_atom("user"<>Integer.to_string(j)),{:kill_self}) end)
    end

    # sleep for some time
    Process.sleep(10000)
    # start the genserver again and get their state back from server - query the tweets etc

    IO.inspect "STARTING AGAIN!!!!!"
    for j <- clientIds do
        spawn(fn -> Client.start_link("user" <> Integer.to_string(j), ipAddr) end)
        spawn(fn -> Client.register_user("user" <> Integer.to_string(j), ipAddr) end)
    end

end

def simulate(ipAddr) do 
        [{_, numClients}] = :ets.lookup(:staticFields, "totalNodes")
        assignfollowers(numClients, ipAddr) # add zipf logic
        Process.sleep(5000)
        delay = calculateFrequency(numClients) # add zipf logic
        numThreads = 
            if 100000/numClients > 1 do
                round(100000/numClients)
            else
                1
            end
    listofFequency = 
      for client <- 1..numClients do
            spawn(fn -> Client.generateMultipleTweets("user" <> Integer.to_string(client), delay * client, numThreads) end)
            spawn(fn -> Client.createMultipleRetweets("user" <> Integer.to_string(client), numThreads) end)
            {"user" <> Integer.to_string(client) , (numThreads*1000) / (delay * client)}
      end

      IO.inspect listofFequency
end

def getSum([first|tail], sum) do
    sum = sum + first
    getSum(tail,sum)
end

def getSum([], sum) do
    sum
end

def assignfollowers(numClients, ipAddr) do
    # calculate cons somehow 
    
    harmonicList = for j <- 1..numClients do
                     round(1/j)
                   end
    c=(100/getSum(harmonicList,0))

    
    for tweeter <- 1..numClients, i <- 1..round(Float.floor(c/tweeter)) do

            follower = ("user" <> Integer.to_string(Enum.random(1..numClients)))
            mainUser = ("user" <> Integer.to_string(tweeter))
            spawn(fn -> Client.subscribe_to(follower, mainUser, ipAddr) end)
        
    end

    listofFollowersCount = 
    for tweeter <- 1..numClients do
    {"user" <> Integer.to_string(tweeter) , round(Float.floor(c/tweeter))}
    end
    IO.inspect listofFollowersCount
end

def calculateFrequency(numClients) do
    3000
end

def getTweetContent(username) do
    [{_, sampleTweets}] = :ets.lookup(:staticFields, "sampleTweets")
    rand_Index = Enum.random(1..Enum.count(sampleTweets))
    selectedTweet = Enum.at(sampleTweets, rand_Index - 1)
    
    [{_, hashTags}] = :ets.lookup(:staticFields, "hashTags")
    numTags = Enum.random(0..5)

    hashTagList = 
    if numTags > 0 do
        for i <- Enum.to_list(1..numTags) do
             Enum.at(hashTags, i - 1)
        end
    else
        []
    end
    [{_, numClients}] = :ets.lookup(:staticFields, "totalNodes")
    numMentions = Enum.random(0..5)

    mentionsList = 
    if numMentions > 0 do
        for i <- Enum.to_list(1..numMentions) do
             "@user" <> Integer.to_string(Enum.random(1..numClients)) <> " "
        end
    else
        []
    end
    selectedTweet <> condense(hashTagList, "") <> condense(mentionsList, "")

    end

    def condense([first|tail], string) do
        string = string <> first
        condense(tail, string)
    end

    def condense([], string) do
        string
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