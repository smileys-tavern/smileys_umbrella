defmodule Smileyscaretaker.Cron.ContentSorter do

	alias SmileysData.ContentSorting.EigenSorter, as: Sorter

	def decay_posts_new() do
		Sorter.decay_posts_new()
	end

	def decay_posts_medium() do
		Sorter.decay_posts_medium()
	end

	def decay_posts_long() do
		Sorter.decay_posts_long()
	end

	def decay_posts_termination() do
		Sorter.decay_posts_termination()
	end
end