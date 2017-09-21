defmodule Smileyscaretaker.Automation.RegisteredBots do
  @moduledoc """
  """
  use GenServer

  alias Smileyscaretaker.{Feeds}
  alias SmileysData.{RegisteredBot, QueryRegisteredBots}

  ### GenServer

  @spec start_link(Keyword.t) :: GenServer.on_start
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  GenServer.init/1 callback
  """
  def init(_opts) do
    HTTPoison.start

    {:ok, %{}}
  end

  @doc """
  GenServer.handle_cast/3 callback
  """
  def handle_cast({:scraper, bot, meta}, completed_tasks_state) do

  	# hit scraper url
	case HTTPoison.get(meta.meta) do
    	{:ok, %{body: body}} ->
    	    {:ok, feed, _} = FeederEx.parse(body)

    	    # Each feed can return multiple entries, all of which are mapped here
    	    mapped_feeds = Feeds.map_feed(feed)

    	    result = handle_mapped_feeds(mapped_feeds, bot, [])

    	    IO.inspect result
    	_ ->
    		IO.inspect("No match on scraper request")
    end

    {:noreply, completed_tasks_state}
  end

  ### Client API / Helper functions

  @doc """
  Do a task based on a bots profile
  """
  def do_task(%RegisteredBot{} = bot) do 
  	bot_meta = QueryRegisteredBots.meta_by_bot(bot)

  	case bot.type do
  		"scraper" ->
  			for (meta <- bot_meta) do
  				GenServer.cast(__MODULE__, {:scraper, bot, meta})
			end
  	end
  end

  defp handle_mapped_feeds([], _, acc) do
	acc
  end

  defp handle_mapped_feeds([feed|tail], %RegisteredBot{} = bot, acc) do
    result = Feeds.create_post_from_feed(feed, bot)

	handle_mapped_feeds(tail, bot, [result|acc])
  end
end