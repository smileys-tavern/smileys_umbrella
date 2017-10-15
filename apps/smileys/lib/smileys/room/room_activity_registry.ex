defmodule Smileys.Room.ActivityRegistry do
  @moduledoc """
  Keeps a registry of room activity buckets.  This is the interface used to create and retrieve buckets and will handle
  cleanup on bucket crashes if necessary.
  """
  use GenServer

  alias Smileys.Room.{Activity, ActivityBucket}

  @room_activity_hours_to_live 6

  ## Client API

  @doc """
  Starts the activity registry.
  """
  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, [name: name])
  end

  @doc """
  Looks up a rooms bucket pid by the room name stored in `server`.

  Returns `{:ok, pid}` if the bucket exists, `:error` otherwise.
  """  
  def lookup_room_bucket(server, room_name) do
    GenServer.call(server, {:lookup, room_name})
  end

  @doc """
  Look up and retrieve a room bucket, if bucket does not exist, one is created as it is assumed a room is entitled to new activity
  if called.
  """
  def retrieve_room_bucket!(server, room_name) do
  	case lookup_room_bucket(server, room_name) do
  		{:ok, bucket_pid} ->
  			ActivityBucket.get_activity(bucket_pid)
  		:error ->
  			%Activity{}
  	end
  end

  @doc """
  Update a room bucket.  If none exists a bucket will be created since new activity indicates an active post
  """
  def increment_room_bucket_activity!(server, room_name, %Activity{} = activity) do
  	case lookup_room_bucket(server, room_name) do
  		{:ok, bucket_pid} ->
  			ActivityBucket.increment_room_bucket_activity!(bucket_pid, activity)
  		_ ->
  			case create_room_bucket(server, room_name) do
  				:ok ->
  					{:ok, bucket_pid} = lookup_room_bucket(server, room_name)

            set_activity_elimination_timer(room_name, activity)

  					ActivityBucket.increment_room_bucket_activity!(bucket_pid, activity)
  			end
  	end
  end

  defp set_activity_elimination_timer(room_name, %Activity{subs: subs, new_posts: new_posts, hot_posts: hot_posts, new_rooms: new_rooms}) do
    activity_reversed = %Activity{subs: subs * -1, new_posts: new_posts * -1, hot_posts: hot_posts * -1, new_rooms: new_rooms * -1}
    Process.send_after(self(), {:expire_activities, room_name, activity_reversed}, @room_activity_hours_to_live * 60 * 60 * 1000)
  end

  @doc """
  Ensures there is a room bucket associated with the given `room_name` in `server`.
  """
  def create_room_bucket(server, room_name) do
    GenServer.call(server, {:create, room_name})
  end

  ## Server Callbacks
  def init(:ok) do
  	room_names = %{}
  	refs  = %{}
	
	  {:ok, {room_names, refs}}
  end

  def handle_call({:lookup, room_name}, _from, {room_names, _} = state) do
    {:reply, Map.fetch(room_names, room_name), state}
  end

  def handle_call({:create, room_name}, _from, {room_names, refs} = state) do
  	if Map.has_key?(room_names, room_name) do
  	  {:reply, :duplicate, state}
  	else
  	  {:ok, pid} = ActivityBucket.start_link([])
  	  
  	  ref        = Process.monitor(pid)
  	  refs       = Map.put(refs, ref, room_name)
  	  room_names = Map.put(room_names, room_name, pid)

  	  {:reply, :ok, {room_names, refs}}
  	end
  end

  def handle_call({:expire_activities, room_name, activity}, state) do
    _ = increment_room_bucket_activity!(self(), room_name, activity)

    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, {room_names, refs}) do
  	{room_name, refs} = Map.pop(refs, ref)
	  room_names        = Map.delete(room_names, room_name)

	  {:noreply, {room_names, refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end