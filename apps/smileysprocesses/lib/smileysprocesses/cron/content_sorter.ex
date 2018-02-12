defmodule SmileysProcesses.Cron.ContentSorter do

	alias SmileysData.ContentSorting.EigenSorter, as: Sorter
	alias SimpleStatEx, as: SSX

	def decay_posts_new() do
		SSX.stat("sc_ran_decay_posts_new", :daily) |> SSX.save()

		{_, amt} = Sorter.decay_posts_new()

		SSX.stat("sc_posts_new_decayed", :hourly, amt) |> SSX.save()
	end

	def decay_posts_medium() do
		SSX.stat("sc_ran_decay_posts_medium", :daily) |> SSX.save()

		{_, amt} = Sorter.decay_posts_medium()

		SSX.stat("sc_posts_medium_decayed", :hourly, amt) |> SSX.save()
	end

	def decay_posts_long() do
		SSX.stat("sc_ran_decay_posts_long", :daily) |> SSX.save()

		{_, amt} = Sorter.decay_posts_long()

		SSX.stat("sc_posts_long_decayed", :hourly, amt) |> SSX.save()
	end

	def decay_posts_termination() do
		SSX.stat("sc_ran_decay_posts_term", :daily) |> SSX.save()

		{_, amt} = Sorter.decay_posts_termination()

		SSX.stat("sc_posts_termination_decayed", :hourly, amt) |> SSX.save()
	end
end