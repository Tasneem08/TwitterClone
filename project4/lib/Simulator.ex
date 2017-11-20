defmodule Simulator do

    def simulate(numClients) do 
        for client <- 1..numClients do
            #spawn(fn -> Client.register_user("user" <> Integer.to_string(client)) end)
            Client.register_user("user" <> Integer.to_string(client))
        end

        for client <- 1..numClients do
            #spawn(fn -> Client.register_user("user" <> Integer.to_string(client)) end)
            Client.simulateClient("user" <> Integer.to_string(client), numClients)
        end

        # Client.subscribe_to("user1", "user2")
        # Client.subscribe_to("user1", "user3")
        # Client.subscribe_to("user1", "user4")
        # Client.subscribe_to("user5", "user1")

        # Client.tweet("user2", "this is a test tweet.")

    end
end