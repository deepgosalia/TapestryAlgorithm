defmodule Server do
  use GenServer
  def start_link(state) do
    {:ok,pid} = GenServer.start_link(__MODULE__,state) # [hashID,]
    hashID = Enum.at(state,0)
    IO.inspect(Enum.at(state,1))
    :ets.insert(:processTable,{hashID,pid})
  end
  def init(state) do
    Process.flag(:trap_exit,true)
    {:ok,state}
  end
end
