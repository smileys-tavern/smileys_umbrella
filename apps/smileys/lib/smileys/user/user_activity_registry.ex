defmodule Smileys.User.ActivityRegistry do
  @moduledoc """
  Keeps a registry of user activity buckets.  This is the interface used to create and retrieve buckets and will handle
  cleanup on bucket crashes if necessary.
  """
  use GenServer

  alias Smileys.User.{Activity, ActivityBucket}

  ## Client API

  @doc """
  Starts the activity registry.
  """
  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, [name: name])
  end

  @doc """
  Looks up an individual users bucket pid by username stored in `server`.

  Returns `{:ok, pid}` if the bucket exists, `:error` otherwise. This identifier can be used to update or
  retrieve items from a users bucket
  """  
  def lookup_user_bucket(server, user_name) do
    GenServer.call(server, {:lookup, user_name})
  end

  @doc """
  Look up and retrieve a user bucket whether it is yet created or not. Can call for an individual bucket post or an entire
  activity map for a user
  """
  def retrieve_user_bucket!(server, %Activity{user_name: user_name, hash: post_hash}) do
  	case lookup_user_bucket(server, user_name) do
  		{:ok, bucket_pid} ->
  			ActivityBucket.get_post_activity(bucket_pid, post_hash)
  		_ ->
  			case create_user_bucket(server, user_name) do
  				:ok ->
  					{:ok, bucket_pid} = lookup_user_bucket(server, user_name)

  					ActivityBucket.get_post_activity(bucket_pid, post_hash)
  			end
  		
  	end
  end

  def retrieve_user_bucket!(server, user_name) do
  	case lookup_user_bucket(server, user_name) do
  		{:ok, bucket_pid} ->
  			ActivityBucket.get_activity(bucket_pid)
  		_ ->
  			case create_user_bucket(server, user_name) do
  				:ok ->
  					{:ok, bucket_pid} = lookup_user_bucket(server, user_name)

  					ActivityBucket.get_activity(bucket_pid)
  			end
  		
  	end
  end

  def update_user_bucket!(server, %Activity{user_name: user_name, hash: post_hash, url: url, comments: amt_new_comment, votes: amt_new_vote}) do
  	activity = case lookup_user_bucket(server, user_name) do
  		{:ok, bucket_pid} ->
  			ActivityBucket.add_new_post_activity(bucket_pid, post_hash, url, amt_new_comment, amt_new_vote)
  		_ ->
  			case create_user_bucket(server, user_name) do
  				:ok ->
  					{:ok, bucket_pid} = lookup_user_bucket(server, user_name)

  					ActivityBucket.add_new_post_activity(bucket_pid, post_hash, url, amt_new_comment, amt_new_vote)
  			end
  	end

  	{url, _, comments, votes} = activity[post_hash]

  	SmileysWeb.Endpoint.broadcast("user:" <> user_name, "activity", %Activity{user_name: user_name, hash: post_hash, url: url, comments: comments, votes: votes})
  end

  @doc """
  Ensures there is a bucket associated with the given `user_name` in `server`.
  """
  def create_user_bucket(server, user_name) do
    GenServer.call(server, {:create, user_name})
  end

  ## Server Callbacks
  def init(:ok) do
	user_names = %{}
	refs  = %{}
	
	{:ok, {user_names, refs}}
  end

  def handle_call({:lookup, user_name}, _from, {user_names, _} = state) do
    {:reply, Map.fetch(user_names, user_name), state}
  end

  def handle_call({:create, user_name}, _from, {user_names, refs} = state) do
	if Map.has_key?(user_names, user_name) do
	  {:reply, :duplicate, state}
	else
	  {:ok, pid} = ActivityBucket.start_link([])
	  
	  ref        = Process.monitor(pid)
	  refs       = Map.put(refs, ref, user_name)
	  user_names = Map.put(user_names, user_name, pid)

	  {:reply, :ok, {user_names, refs}}
	end
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, {user_names, refs}) do
  	{user_name, refs} = Map.pop(refs, ref)
	user_names        = Map.delete(user_names, user_name)

	{:noreply, {user_names, refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end