  # Sets up the worker/ Client

  defmodule Client do
  use GenServer

  def register_user() do
    username = String.to_atom("mmathkar"<>(:erlang.monotonic_time() |> :erlang.phash2(256) |> Integer.to_string(16))<>"@"<>findIP())
    GenServer.cast(username,{:registerMe, username})    
    
  end

  def subscribe_to(username) do
    GenServer.cast(username,{:registerMe, username}) 
  end

  def search_by_hashtags(hashtag) do
    GenServer.cast()
  end





   # Returns the IP address of the machine the code is being run on.
  def findIP do
    {ops_sys, extra } = :os.type
    ip = 
    case ops_sys do
      :unix -> 
            if extra == :linux do
              {:ok, [addr: ip]} = :inet.ifget('ens3', [:addr])
              to_string(:inet.ntoa(ip))
            else
              {:ok, [addr: ip]} = :inet.ifget('en0', [:addr])
              to_string(:inet.ntoa(ip))
            end
      :win32 -> {:ok, [ip, _]} = :inet.getiflist
               to_string(ip)
    end
  (ip)
  end

  end