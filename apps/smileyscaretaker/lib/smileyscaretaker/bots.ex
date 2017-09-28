defmodule Smileyscaretaker.Bots do
	alias Smileyscaretaker.Automation.RegisteredBots
	alias SmileysData.QueryRegisteredBots

	def run_bots() do
		bots = QueryRegisteredBots.bots(20)

		_task_count = Enum.reduce(bots, 0, fn(bot, task_count) -> 
			RegisteredBots.do_task(bot) 
			task_count + 1
		end)
	end
end