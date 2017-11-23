defmodule Simulator do

def main(args) do
    total = List.first(args) |> String.to_integer()
    # Start the engine
    Engine.start_link()
    
    setupStaticData(total)
    # Start the clients
    start_Client()
# assignfollowers(total)
    # Start the simulation
     simulate()

    :timer.sleep(:infinity)
end

def setupStaticData(total) do
    :ets.new(:staticFields, [:named_table])
    :ets.insert(:staticFields, {"totalNodes", total})
    :ets.insert(:staticFields, {"sampleTweets", ["Please come to my party. ","Don't you dare come to my party. ","Why won't you invite me to your party? ","But I wanna come to your party. ","Okay I won't come to your party. "]})
    :ets.insert(:staticFields, {"hashTags", ["#adoptdontshop ","#UFisGreat ","#Fall2017 ","#DinnerParty ","#cutenesscatified "]})

end
 
def start_Client() do
    [{_, numClients}] = :ets.lookup(:staticFields, "totalNodes")
     for client <- 1..numClients do
            Client.start_link("user" <> Integer.to_string(client))
            Client.register_user("user" <> Integer.to_string(client))
     end
end

def simulate() do 
        [{_, numClients}] = :ets.lookup(:staticFields, "totalNodes")
        assignfollowers(numClients) # add zipf logic
        delay = calculateFrequency(numClients) # add zipf logic

      for client <- 1..numClients do
            spawn(fn -> Client.generateTweets("user" <> Integer.to_string(client), delay * client) end)
      end
end

def assignfollowers(numClients) do
    # calculate cons somehow 
    c = 5
    for tweeter <- 1..numClients, i <- 1..round(Float.floor(c/tweeter)) do
            # IO.inspect "#{tweeter} #{i}"
            follower = ("user" <> Integer.to_string(Enum.random(1..numClients)))
            mainUser = ("user" <> Integer.to_string(tweeter))
             spawn(fn -> Client.subscribe_to(follower, mainUser) end)
    end
    GenServer.cast(:main_server,{:printMapping})
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
end