defmodule Tapestry do
  def start() do
    [numNodes, numRequest] = System.argv()
    numNodes = String.to_integer(numNodes)
    numRequest = String.to_integer(numRequest)

    :ets.new(:processTable,[:set,:public,:named_table])
    #ets table to store list of process and its hashID {key,value}->{hashID,pid}

    Enum.each(1..numNodes,fn(x)->
      hashID = :crypto.hash(:sha,Integer.to_string(x))|>Base.encode16 |>String.slice(0..7)
      list = generateList(x)
      #list = insertNeighbour(x,list)
      Server.start_link([hashID,list])
    end)

    Server.isnertNode()
  end
  def generateList(x) do
  #8 levels(row) and 16 (hex) cols
    codeString=:crypto.hash(:sha,Integer.to_string(x))|>Base.encode16 |>String.slice(0..7) # BDF23E
    stringArray = String.codepoints(codeString) # B D F 2 3 E
  list = Enum.reduce(0..7,[],fn(rowNo,temp)  ->
          tempList =List.duplicate(0,16)
          {t,_}=Integer.parse(Enum.at(stringArray,rowNo),16)
          tempList = List.replace_at(tempList,t,codeString)
          #IO.inspect(tempList)
          temp = temp++[tempList]
  end)
 # IO.inspect(list)
 end


end
Tapestry.start

