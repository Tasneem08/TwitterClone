  # Sets up the worker/ Client

  defmodule Client do

  def register_user(ipAddr) do
    local_node_name = String.to_atom("mmathkar"<>(:erlang.monotonic_time() |> :erlang.phash2(256) |> Integer.to_string(16))<>"@"<>findIP())
    # Node.start(local_node_name)
    # Node.set_cookie(String.to_atom("monster"))
    # if Node.connect(String.to_atom("muginu@"<>ipAddr)) == true do
      # {{max_val, min_val}, k} = get_work(ipAddr)
      # clientMainMethod(String.duplicate("0", k), min_val, max_val, ipAddr)
    #   GenServer.cast()
      
    end
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