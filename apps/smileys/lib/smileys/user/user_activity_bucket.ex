defmodule Smileys.User.ActivityBucket do
  @moduledoc """
  A bucket representing all of a users most recent post activity (comment and vote counts). The bucket is a map keyed by
  post hashes and each contains a tuple of the form {post_url, last_update_time, comments_total, votes_total}
  """

  use Agent

  @max_activity_count 30
  @prune_amount       10

  @doc """
  Start with a new empty activity bucket
  """
  def start_link(_opts) do
    Agent.start_link(fn -> %{} end)
  end

  @doc """
  Get the comment and vote activity of one of a users posts
  """
  def get_post_activity(user_bucket, post_hash) do
    Agent.get(user_bucket, &Map.get(&1, post_hash))
  end

  @doc """
  Return a users post activity
  """
  def get_activity(user_bucket) do
  	Agent.get(user_bucket, fn state -> state end)
  end

  @doc """
  Deletes a single posts activity entry
  NOTE this may be less awkward if it returns the entire new state instead of the popped element
  """
  def delete_activity(user_bucket, post_hash) do
  	Agent.get_and_update(user_bucket, &Map.pop(&1, post_hash))
  end

  @doc """
  Return the user bucket to an empty state
  """
  def reset_activity_bucket(user_bucket) do
  	Agent.update(user_bucket, fn -> %{} end)
  end

  @doc """
  Put new activity on a post in a users bucket, filed under the posts hash string. Get and update are used in order to increment
  counts since this is used on a per event basis.  Checks size of activity map.
  Returns new state of activity map
  """
  def add_new_post_activity(user_bucket, post_hash, url, comment_value \\ 1, vote_value \\ 0)
  def add_new_post_activity(user_bucket, post_hash, url, comment_value, vote_value) do
    user_activity = Agent.get_and_update(user_bucket, fn state -> 
    	new_state = Map.update(state, post_hash, {url, Time.utc_now(), comment_value, vote_value}, fn {_, _, p_comment, p_vote} ->
	   		{url, Time.utc_now(), p_comment + comment_value, p_vote + vote_value}
    	end)
    	{new_state, new_state}
    end)

    # Maintainance operation
    _ = map_size_check(user_bucket, user_activity)

    user_activity
  end

  defp map_size_check(user_bucket, activity) do
  	cond do 
  		Enum.count(activity) > @max_activity_count ->
	  		activity_sorted = Enum.sort(activity, fn {_, {_, time1, _, _}}, {_, {_, time2, _, _}} -> 
	  			time1 >= time2
	  		end)

	  		# Gather last x sorted keys
	  		_ = filter_activity_map(user_bucket, activity_sorted)


	  	true ->
	  		:noop
  	end
  end

  defp filter_activity_map(user_bucket, activity) do
  	filter_activity_map(user_bucket, activity, @prune_amount, 0)
  end

  defp filter_activity_map(_, _, 0, amount_pruned) do
  	amount_pruned
  end

  defp filter_activity_map(_, [], _, amount_pruned) do
  	amount_pruned
  end

  defp filter_activity_map(user_bucket, [{hash, _}|activity], prune, amount_pruned) do
  	_ = delete_activity(user_bucket, hash)

  	filter_activity_map(user_bucket, activity, prune - 1, amount_pruned + 1)
  end
end