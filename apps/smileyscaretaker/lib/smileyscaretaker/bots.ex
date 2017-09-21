defmodule Smileyscaretaker.Bots do
	alias Smileyscaretaker.Automation.RegisteredBots
	alias Smileyscaretaker.Feeds
	alias SmileysData.{QueryRegisteredBots, RegisteredBot}

	def run_bots() do
		bots = QueryRegisteredBots.bots(20)

		_task_count = Enum.reduce(bots, 0, fn(bot, task_count) -> 
			RegisteredBots.do_task(bot) 
			task_count + 1
		end)
	end

	def handle_scraper(%RegisteredBot{} = bot, bot_meta) do
		mapped_feeds = Enum.reduce(bot_meta, [], fn(meta, feeds) ->
			# hit scraper url
			case HTTPoison.get(meta.meta) do
		    	{:ok, %{body: body}} ->
		    	    {:ok, feed, _} = FeederEx.parse(body)

		    	    # Each feed can return multiple entries, all of which are mapped here
		    	    Feeds.map_feed(feed) ++ feeds
		    	_ ->
		    		feeds
		    end
		end)

      	bot_result = handle_mapped_feeds(mapped_feeds, bot, [])

      	IO.inspect "Finished Processing Feeds"
      	IO.inspect bot_result
	end

	def handle_mapped_feeds([], _, acc) do
		acc
	end

	def handle_mapped_feeds([feed|tail], %RegisteredBot{} = bot, acc) do
		result = Feeds.create_post_from_feed(feed, bot)

		handle_mapped_feeds(tail, bot, [result|acc])
	end
end