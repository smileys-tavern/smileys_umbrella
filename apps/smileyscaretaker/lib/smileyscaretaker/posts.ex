defmodule Smileysprocesses.Posts do
  @moduledoc """
  Processes related to post maintainence. Initial simple post decay methods used. Very rough.. TODO: refactor post decay
  to be more versatile (based on post/room params fast and slow decays, run on an easier to follow curve instead of relying on
  amount crons run etc)
  """

  @doc """
  Decay new posts a small amount

  ## Examples

      iex> Smileysprocesses.Posts.decay_posts_small()
      {:ok, 12}

  """
  def decay_posts_small do
    SmileysData.QueryPost.decay_posts("0.05", "INTERVAL '2 hours'", "INTERVAL '1 hour'")
  end

  @doc """
  Decay new posts a small amount

  ## Examples

      iex> Smileysprocesses.Posts.decay_posts_medium()
      {:ok, 4}

  """
  def decay_posts_medium do
    SmileysData.QueryPost.decay_posts("0.1", "INTERVAL '4 hours'", "INTERVAL '2 hour'")
  end

  @doc """
  Decay new posts a small amount

  ## Examples

      iex> Smileysprocesses.Posts.decay_posts_large()
      {:ok, 239}

  """
  def decay_posts_large do
    SmileysData.QueryPost.decay_posts("0.2", "INTERVAL '8 hours'", "INTERVAL '4 hour'")
  end
end
