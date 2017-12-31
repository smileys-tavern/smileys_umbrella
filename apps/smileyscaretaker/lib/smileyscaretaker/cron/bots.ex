defmodule Smileyscaretaker.Cron.Bots do
	alias Smileyscaretaker.Automation.RegisteredBots
	alias Smileyscaretaker.Feeds.Post
	alias SmileysData.Query.User.Bot, as: QueryBot
	alias SmileysData.RegisteredBot

  def run_bots() do
    bots = QueryBot.all(50)

    Enum.reduce(bots, 0, fn(bot, task_count) ->
      bot_meta = QueryBot.meta(bot)

      case bot.type do
        "scraper" ->
          for (meta <- bot_meta) do
            scrape_for_bot(bot, meta)
          end

          task_count + 1
      end 
    end)
  end

  defp scrape_for_bot(bot, meta) do
    case HTTPoison.get(meta.meta) do
      {:ok, %{body: body}} ->
        feed = case FeederEx.parse(body) do
          {:ok, feed, _} ->
            feed
          feeder_response ->
            IO.inspect "Feed Parse Failed"
            IO.inspect feeder_response
            nil
        end

        if feed do
          # Each feed can return multiple entries, all of which are mapped here
          mapped_feeds = Post.map_feed(feed)

          _feeds_processed = handle_mapped_feeds(mapped_feeds, bot, 0)
        end
      _ ->
        IO.inspect("No match on scraper request")
    end
  end

  # TODO: convert to use enum no special function needed any longer
  defp handle_mapped_feeds([], _, acc) do
    acc
  end

  defp handle_mapped_feeds([feed|tail], %RegisteredBot{} = bot, acc) do
  	RegisteredBots.do_task(bot, feed)

    handle_mapped_feeds(tail, bot, acc + 1)
  end
end