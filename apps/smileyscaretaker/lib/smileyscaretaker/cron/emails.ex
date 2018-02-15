defmodule Smileyscaretaker.Cron.Emails do
	alias SmileysData.Query.User.Subscription, as: QueryUserSubscription
	alias SmileyscaretakerWeb.Emails.UserActivityCompose
	alias Smileyscaretaker.Mailer
	alias SimpleStatEx, as: SSX


	def send_to_daily_subscribers() do
	  users = QueryUserSubscription.by_email_subscription_type("daily")

	  SSX.stat("sc_ran_email_daily", :weekly) |> SSX.save()

	  for (user <- users) do
	  	UserActivityCompose.daily(user) |> Mailer.deliver_later
	  end
	end

	def send_to_weekly_subscribers() do
	  users = QueryUserSubscription.by_email_subscription_type("weekly")

	  SSX.stat("sc_ran_email_weekly", :weekly) |> SSX.save()

	  for (user <- users) do
	  	UserActivityCompose.weekly(user) |> Mailer.deliver_later
	  end
	end
end