defmodule Smileys.Post.ActivityBucket do
  @moduledoc """
  A bucket representing all of a posts activity. Currently only contains a comment count
  """

  use Agent

  alias Smileys.Post.Activity

  @doc """
  Start with a new empty activity bucket
  """
  def start_link(_opts) do
    Agent.start_link(fn -> %Activity{comments: 0} end)
  end

  @doc """
  Get the activity map of a post
  """
  def get_activity(post_bucket) do
    Agent.get(post_bucket, fn state -> state end)
  end

  @doc """
  Put new activity on a post in a users bucket, filed under the posts hash string. Get and update are used in order to increment
  counts since this is used on a per event basis.  Checks size of activity map.
  Returns new state of activity map
  """
  def increment_comment_count(post_bucket, new_comments_amt \\ 1)
  def increment_comment_count(post_bucket, new_comments_amt) do
    Agent.get_and_update(post_bucket, fn %Activity{comments: comments} = activity ->
    	new_activity = Map.put(activity, :comments, comments + new_comments_amt)
    	{new_activity, new_activity}
    end)
  end
end