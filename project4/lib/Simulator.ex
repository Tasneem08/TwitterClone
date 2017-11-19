defmodule Simulator do

    def simulate(numClients) do 
        for client <- 1..numClients do
            spawn(fn -> Client.register_user("user" <> Integer.to_string(client)) end)
        end
    end
end