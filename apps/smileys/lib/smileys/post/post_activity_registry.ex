defmodule Smileys.Post.ActivityRegistry do
  @moduledoc """
  Keeps a registry of post activity buckets.  This is the interface used to create and retrieve buckets and will handle
  cleanup on bucket crashes if necessary.  These entries are expected to be pruned regularly for older activity no longer
  tracked (so this only keeps latest comment counts since x time ago)
  """
  use GenServer

  alias Smileys.Post.{Activity, ActivityBucket}

  @post_hours_to_live 72

  ## Client API

  @doc """
  Starts the activity registry.
  """
  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, [name: name])
  end

  @doc """
  Looks up a posts bucket pid by the post hash stored in `server`.

  Returns `{:ok, pid}` if the bucket exists, `:error` otherwise. This identifier can be used to update or
  retrieve items for a posts bucket
  """  
  def lookup_post_bucket(server, post_hash) do
    GenServer.call(server, {:lookup, post_hash})
  end

  @doc """
  Look up and retrieve a post bucket, if bucket does not exist returns empty activity set, and so assumes no new activity exists
  """
  def retrieve_post_bucket!(server, post_hash) do
  	case lookup_post_bucket(server, post_hash) do
  		{:ok, bucket_pid} ->
  			ActivityBucket.get_activity(bucket_pid)
  		:error ->
  			%Activity{}
  	end
  end

  @doc """
  Update a post bucket.  If none exists a bucket will be created since new activity indicates an active post
  """
  def increment_post_bucket_comments!(server, post_hash, %Activity{comments: new_comment_amt}) do
  	case lookup_post_bucket(server, post_hash) do
  		{:ok, bucket_pid} ->
  			ActivityBucket.increment_comment_count(bucket_pid, new_comment_amt)
  		_ ->
  			case create_post_bucket(server, post_hash) do
  				:ok ->
  					{:ok, bucket_pid} = lookup_post_bucket(server, post_hash)

  					ActivityBucket.increment_comment_count(bucket_pid, new_comment_amt)
  			end
  	end
  end

  @doc """
  Ensures there is a post bucket associated with the given `post_hash` in `server`.
  """
  def create_post_bucket(server, post_hash) do
    GenServer.call(server, {:create, post_hash})
  end

  @doc """
  Prunes the registered post buckets for any entries older than the max allowed hours
  """
  def prune_old_entries(server) do
  	GenServer.call(server, {:prune, @post_hours_to_live})
  end


  ## Server Callbacks
  def init(:ok) do
	post_hashes = %{}
	refs  = %{}
	
	{:ok, {post_hashes, refs}}
  end

  def handle_call({:lookup, post_hash}, _from, {post_hashes, _} = state) do
    {:reply, Map.fetch(post_hashes, post_hash), state}
  end

  def handle_call({:create, post_hash}, _from, {post_hashes, refs} = state) do
	if Map.has_key?(post_hashes, post_hash) do
	  {:reply, :duplicate, state}
	else
	  {:ok, pid} = ActivityBucket.start_link([])
	  
	  ref         = Process.monitor(pid)
	  refs        = Map.put(refs, ref, post_hash)
	  post_hashes = Map.put(post_hashes, post_hash, pid)

	  # Kill the bucket after it's high activity time is expected to be over
	  Process.send_after(self(), {:prune, pid, ref}, @post_hours_to_live * 60 * 60 * 1000)

	  {:reply, :ok, {post_hashes, refs}}
	end
  end

  def handle_info({:prune, bucket_pid, ref}, {post_hashes, refs}) do
  	# Demonitor since we will handle a clean exit and lose the keys from state
  	Process.demonitor(ref)
  	Process.exit(bucket_pid, :kill)

  	{post_hash, refs} = Map.pop(refs, ref)
	post_hashes       = Map.delete(post_hashes, post_hash)

  	{:noreply, {post_hashes, refs}}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, {post_hashes, refs}) do
  	{post_hash, refs} = Map.pop(refs, ref)
	post_hashes       = Map.delete(post_hashes, post_hash)

	{:noreply, {post_hashes, refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end