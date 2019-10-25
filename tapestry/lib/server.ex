defmodule Server do
  use GenServer
  def start_link(state) do
    {:ok,pid} = GenServer.start_link(__MODULE__,state) # [hashID,]
    hashID = Enum.at(state,0)
    #IO.inspect(pid)
   # IO.inspect(Enum.at(state, 1))
    :ets.insert(:processTable,{hashID,pid})
  end

  def init(state) do
    Process.flag(:trap_exit,true)
    {:ok,state}
  end



  #00000000000000000000000000000000000000000000000000000000000000000
  #below are the get and set functions--------------------------------
  def get_state(pid) do
    state=GenServer.call(pid,:get_state)
    state
  end

  def handle_call(:get_state,_from,state) do
    {:reply,state,state}
  end

  def getProcessId(hashID) do
    #IO.puts(hashID)
    [{_,pid}] = :ets.lookup(:processTable,hashID)
    pid
  end

  def getListAt(pid,level) do
    state = get_state(pid)
    levelList = Enum.at(Enum.at(state,1),level)
    levelList
  end

  def handle_cast({:updateList,list},state) do
    [id,_list] = state
    {:noreply,[id,list]}
  end
  #---------------------------------------------------------

# to generate filled table------------------------

def generatetable() do

end


#------------------------------------

  #to insert a single node with a given root-------------------
  #findRoot(root,insert_node)

  def insertnode(root,insert_node,ackFlag) do
    #IO.puts("here")
    #IO.inspect("#{root} : #{insert_node}")
   root_id = getProcessId(root)
   level = findMaxPrefixMatch(root, insert_node)
    root_list = getListAt(root_id,level)
    stringArray = String.codepoints(insert_node)
    char_val = Enum.at(stringArray,level)
   #IO.inspect(Integer.parse(char_val,16))
   {char_pos,_} = Integer.parse(char_val,16)
   field = Enum.at(root_list,char_pos)

   if(ackFlag==0) do
    updateNewNodeTable(insert_node,root,level)
   end

   if(field==nil) do
     #add it there
     updateRootTable(insert_node,level,char_pos,root_id)
   else
    node=findNodeWithMinDist(root,insert_node)
    #update value in its table
   end

   #ackmulticast
   #get updated root value
  #  last = String.length(root)
  # #  if nextLevel!=-1 do
  # #    level = nextLevel
  # #  end

  #     Enum.each(level..last-1, fn(x)  ->
  #       temp_list = getListAt(root_id,x)
  #       Enum.each(temp_list, fn (ackElement) ->
  #           if ackElement != root and ackElement != nil do
  #             insertnode(ackElement,insert_node)
  #           end
  #         end)
  #     end)

   #for each using enum.each send multicast to that node
   #there get id for that node and insertnode() without modifying the new node(so add flag)
   # go till last level
  end

# Search---------------------------

def search(root, node,hops) do

  level = findMaxPrefixMatch(root, node) #row
  stringArray = String.codepoints(node)
  char_val = Enum.at(stringArray,level)
  {char_pos,_} = Integer.parse(char_val,16) #col

  root_id = getProcessId(root)
  root_list = getListAt(root_id,level)
  field = Enum.at(root_list,char_pos)

  if field == node do
    IO.puts(hops)
  else
    IO.puts(field)
    search(field,node,hops+1)
  end

end




   #Ack Multicast----------------------------------------------

   def ackMulticast(root,insert_node,level) do
    last = String.length(root)
    root_id = getProcessId(root)
    # if addedLevel == 0 do
    #   level = findMaxPrefixMatch(root, insert_node)
    # end
    if level<last do
    Enum.each(level..last-1, fn(x)  ->
      temp_list = getListAt(root_id,x)
      Enum.each(temp_list, fn (ackElement) ->
          if ackElement != insert_node and (ackElement != root and ackElement != nil) do
            #IO.inspect("#{ackElement} : #{insert_node}")
            insertnode(ackElement,insert_node,1)
            ackMulticast(ackElement,insert_node,level+1)
          end
        end)
    end)
  end

   end

   #----------------------------------------------------


  def test_node(hashID) do
    pid = getProcessId(hashID)
    state=get_state(pid)
    IO.inspect(Enum.at(state,1))
  end



  #here below we copy from root to node level------------------


def updateNewNodeTable(new_node,root_node_id,uptoLevel) do
  pid = getProcessId(new_node)
  root_id = getProcessId(root_node_id)
  state = get_state(root_id)
  root_list = Enum.at(state,1)
  state=get_state(pid)
  node_list = Enum.at(state,1)

  Enum.each(0..uptoLevel,fn(x)->
    temp_list = Enum.at(root_list,x)
    new_list=List.replace_at(node_list,x,temp_list)
    GenServer.cast(pid,{:updateList,new_list})
  end)


  #GenServer.cast(pid,{:update_node_table,new_node,root_node_id,uptoLevel})
end

  #---------------------------------------------------
   # to update single value at a position

   def updateRootTable(node_value,level,col,pid) do
    GenServer.cast(pid,{:update_node,node_value,level,col,pid})
  end

  def handle_cast({:update_node,node_value,level,col,pid},state) do
    node_list = Enum.at(state,1)
    new_list=List.replace_at(Enum.at(node_list,level),col,node_value)
    new_temp =List.replace_at(node_list,level,new_list)
    {:noreply,[Enum.at(state,0),new_temp]}
  end

  #----------------------------------------------------

  # def handle_cast({:update_node_table,_new_node,root_node_id,level},state) do
  #  # IO.inspect(root_id)
  #   root_id = getProcessId(root_node_id)
  #   root_list = Enum.at(get_state(root_id),1)
  #   Enum.each(0..level,fn(x)->
  #     temp_list = Enum.at(root_list,x)
  #     GenServer.cast(self(),{:updateAtLevel,temp_list,x})
  #   end)
  #   {:noreply,state}
  # end

  # def handle_cast({:updateAtLevel,list_insert,x},_state) do
  #   state=get_state(self())
  #   node_list = Enum.at(state,1)
  #   new_list=List.replace_at(node_list,x,list_insert)
  #   {:noreply,[Enum.at(state,0),new_list]}
  # end

#---------------------------------------

#to find which one has minimum distance
  def findNodeWithMinDist(new_field,curr_field) do
    a = Integer.parse(new_field,16)
    b = Integer.parse(curr_field,16)
    if a<b do
      new_field
    else
      curr_field
    end
  end

#to find to what extend are two nodes share common prefix
  def findMaxPrefixMatch(a,b) do
    a=Enum.reduce_while(0..7,0,fn i,acc->
      x = String.slice(a,i,1)
      y = String.slice(b,i,1)
        if x==y, do: {:cont, acc + 1},else: {:halt, acc}
       end)
    a
  end

end
