defmodule Smileys.Room.ActivityBucket do
  @moduledoc """
  A bucket representing all of a posts activity. Currently only contains a comment count
  """

  use Agent

  alias Smileys.Room.Activity

  @doc """
  Start with a new empty activity bucket
  """
  def start_link(_opts) do
    Agent.start_link(fn -> %Activity{} end)
  end

  @doc """
  Get the activity map of a post
  """
  def get_activity(room_bucket) do
    Agent.get(room_bucket, fn state -> state end)
  end

  @doc """
  Put new activity on a post in a users bucket, filed under the posts hash string. Get and update are used in order to increment
  counts since this is used on a per event basis.  Checks size of activity map.
  Returns new state of activity map
  """
  def increment_room_bucket_activity!(room_bucket, %Activity{subs: new_subs, new_posts: new_new_posts, hot_posts: new_hot_posts, new_rooms: new_new_rooms}) do
    Agent.get_and_update(room_bucket, fn %Activity{subs: subs, new_posts: new_posts, hot_posts: hot_posts, new_rooms: new_room} ->
    	new_activity = %Activity{subs: subs + new_subs, new_posts: new_posts + new_new_posts, hot_posts: hot_posts + new_hot_posts, new_rooms: new_room + new_new_rooms}
    	{new_activity, new_activity}
    end)
  end
end