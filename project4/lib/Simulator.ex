defmodule Simulator do

def main(args) do
    total = List.first(args) |> String.to_integer()
    # spawn(fn -> Engine.start_link() end)
    Engine.start_link()

    start_Client(total)
    simulate(total)
    :timer.sleep(:infinity)
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
      end
    end

    def start_Client(numClients) do
     for client <- 1..numClients do
            Client.start_link("user" <> Integer.to_string(client))
     end
    end

end