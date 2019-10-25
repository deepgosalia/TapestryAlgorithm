defmodule Tapestry do
  def start() do
    [numNodes, _numRequest] = System.argv()
    numNodes = String.to_integer(numNodes)-1   # we are creating first 99 nodes and then other 1 node
    #_numRequest = String.to_integer(numRequest)

    :ets.new(:processTable,[:set,:public,:named_table])
    :ets.new(:network,[:set,:public,:named_table])
    #ets table to store list of process and its hashID {key,value}->{hashID,pid}

    temp=Enum.reduce(1..numNodes,[],fn(x,hashList)->
      hashID = :crypto.hash(:sha,Integer.to_string(x))|>Base.encode16 |>String.slice(0..7)
      hashList++[hashID]
    end)

    Enum.each(1..numNodes, fn(x)->
      hashID = :crypto.hash(:sha,Integer.to_string(x))|>Base.encode16 |>String.slice(0..7)
      #spawn fn-> genList(temp,numNodes,x) end

      genList(temp,numNodes,x)
    end)
    to_find=:crypto.hash(:sha,Integer.to_string(numNodes+1))|>Base.encode16 |>String.slice(0..7)
    new_root=findRoot(temp,to_find,[],0,0)

    list = generateList(100)
    #IO.inspect(list)
    Server.start_link([to_find,list])
    level = Server.findMaxPrefixMatch(new_root, to_find)
    Server.insertnode(new_root,to_find,0)

    Server.ackMulticast(new_root,to_find,level)

    Enum.each(temp,fn (e) ->
      Server.test_node(e)
    end)
    #IO.puts(new_root)
    loop()
  end

  def loop() do
    loop()
  end
  def generateList(x) do
  #8 levels(row) and 16 (hex) cols
    codeString=:crypto.hash(:sha,Integer.to_string(x))|>Base.encode16 |>String.slice(0..7) # BDF23E
    stringArray = String.codepoints(codeString) # B D F 2 3 E
  _list = Enum.reduce(0..7,[],fn(rowNo,temp)  ->
          tempList =List.duplicate(nil,16)
          {t,_}=Integer.parse(Enum.at(stringArray,rowNo),16)
          tempList = List.replace_at(tempList,t,codeString)
          _temp = temp++[tempList]
  end)
 end


 def genList(t,numNodes,i) do   #356A192B
  codeString=:crypto.hash(:sha,Integer.to_string(i))|>Base.encode16 |>String.slice(0..7) # BDF23E
  hashID=Enum.filter(t,fn x-> x != codeString end)

  list = Enum.reduce(0..7,[],fn row,temp ->
    difList=Enum.filter(hashID,fn x-> String.slice(codeString,0,row)==String.slice(x,0,row) and String.slice(codeString,0,row+1)!=String.slice(x,0,row+1) end)
    final=Enum.reduce(0..15,[],fn col,some ->
          coList=Enum.filter(difList,fn dif-> String.slice(dif,row,1) == Integer.to_string(col, 16) end)
          if length(coList)<=1 do
            put_list=List.first(coList)
            some++[put_list]
          else
            put_list=findRoot(coList,codeString,[],0,0)
            some++[put_list]
          end
    end)

    stringArray = String.codepoints(codeString) # B D F 2 3 E
    {t,_}=Integer.parse(Enum.at(stringArray,row),16)
    final = List.replace_at(final,t,codeString)

    temp= temp ++ [final]
  end)
  Server.start_link([codeString,list])
end


 def findRoot(network_list,new_node,neigh_list,pos,added_weight) do  #new node = "86C8BF23"
 char_node = String.at(new_node,pos)
 {t,_} = Integer.parse(char_node, 16)
  char_node=Integer.to_string(rem(t+added_weight,16),16)
  updated_neigh=Enum.reduce(network_list,[],fn(element,temp)->
    char_root = String.at(element,pos)
    if(char_node==char_root) do
       _temp=temp++[element]
    else
      _temp = temp++[]
      end
  end)
  if updated_neigh==[] do
    findRoot(network_list,new_node,neigh_list,pos,added_weight+1)
  else
    if length(updated_neigh)==1 do
     Enum.at(updated_neigh,0)
    else
      if(pos<String.length(new_node)-1) do
        findRoot(updated_neigh,new_node,neigh_list,pos+1,0)
      end
  end
  end
 end

end
Tapestry.start

