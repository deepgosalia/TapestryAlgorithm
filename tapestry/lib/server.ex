defmodule Server do
  use GenServer
  def start_link(state) do
    {:ok,pid} = GenServer.start_link(__MODULE__,state) # [hashID,]
    hashID = Enum.at(state,0)
    :ets.insert(:processTable,{hashID,pid})
  end

  def init(state) do
    Process.flag(:trap_exit,true)
    {:ok,state}
  end

  def get_state(pid) do
    state=GenServer.call(pid,:get_state)
    state
  end

  def handle_call(:get_state,_from,state) do
    {:reply,state,state}
  end

  def getProcessId(hashID) do
    [{_,pid}] = :ets.lookup(:processTable,hashID)
    pid
  end

  def getListAt(pid,level) do
    state = get_state(pid)
    levelList = Enum.at(Enum.at(state,1),level)
    levelList
  end



  def insertnode(root,insert_node) do
   root_id = getProcessId(root)
   level = findMaxPrefixMatch(root, insert_node)
   root_list = getListAt(root_id,level)
   stringArray = String.codepoints(insert_node)
   char_val = Enum.at(stringArray,level)
   char_pos = Integer.parse(char_val,16)
   field = Enum.at(root_list,char_pos)

   updateNewNodeTable(insert_node,root_id,level)

   if(field==0) do
     #add it there
     updateRootTable(insert_node,level,char_pos,root_id)
   else
    node=findNodeWithMinDist(root,insert_node)
    #update value in its table
   end
  end

  def updateNewNodeTable(new_node,root_node_id,uptoLevel) do
    pid = getProcessId(new_node)
    GenServer.cast(pid,{:update_node_table,new_node,root_node_id,uptoLevel})
  end


  def handle_cast({:updateAtLevel,list_insert,x},_state) do
    state=get_state(self())
    node_list = Enum.at(state,1)
    new_list=List.replace_at(node_list,x,list_insert)
    {:noreply,[Enum.at(state,0),new_list]}
  end

  def handle_cast({:update_node_table,_new_node,root_node_id,level},state) do
    root_list = Enum.at(get_state(root_node_id),1)
    Enum.each(0..level,fn(x)->
      temp_list = Enum.at(root_list,x)
      GenServer.cast(self(),{:updateAtLevel,temp_list,x})
    end)
    {:noreply,state}
  end

  def updateRootTable(node_value,level,col,pid) do
    GenServer.cast(pid,{:update_node,node_value,level,col})
  end

  def handle_cast({:update_node,node_value,level,col},state) do
    node_list = Enum.at(get_state(self()),1)
    List.replace_at(Enum.at(node_list,level),
  end

  def findNodeWithMinDist(new_field,curr_field) do
    a = Integer.parse(new_field,16)
    b = Integer.parse(curr_field,16)
    if a<b do
      new_field
    else
      curr_field
    end
  end


  def findMaxPrefixMatch(a,b) do
    a=Enum.reduce_while(0..7,0,fn i,acc->
      x = String.slice(a,i,1)
      y = String.slice(b,i,1)
        if x==y, do: {:cont, acc + 1},else: {:halt, acc}
       end)
    a
  end

end
