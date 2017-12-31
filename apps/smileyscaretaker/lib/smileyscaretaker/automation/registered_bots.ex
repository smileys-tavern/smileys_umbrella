defmodule Smileyscaretaker.Automation.RegisteredBots do
  @moduledoc """
  Runs a bot as a registered process
  TODO: also run a feed as a process so one feed doesnt crash others
  """
  use GenServer

  alias Smileyscaretaker.Feeds.Post

  ### GenServer

  @spec start_link(Keyword.t) :: GenServer.on_start
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  GenServer.init/1 callback
  """
  def init(_opts) do
    {:ok, %{}}
  end

  ### Client

  @doc """
  Do a task based on a bots profile
  """
  def do_task(bot, feed) do 
    GenServer.cast(__MODULE__, {:scraper, bot, feed})
  end

  ### Server

  @doc """
  GenServer.handle_cast/3 callback
  """
  def handle_cast({:scraper, bot, feed}, completed_tasks_state) do
  	_result = Post.create_post_from_feed(feed, bot)

    {:noreply, completed_tasks_state}
  end
end