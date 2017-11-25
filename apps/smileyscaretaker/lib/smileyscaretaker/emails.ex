defmodule Smileyscaretaker.Emails do
	alias SmileysData.QueryUser
	alias SmileyscaretakerWeb.Emails.UserActivityCompose
	alias Smileyscaretaker.Mailer


	def send_to_daily_subscribers() do
	  users = QueryUser.users_by_email_subscription_type("daily")

	  for (user <- users) do
	  	UserActivityCompose.daily(user) |> Mailer.deliver_later
	  end
	end

	def send_to_weekly_subscribers() do
	  users = QueryUser.users_by_email_subscription_type("weekly")

	  for (user <- users) do
	  	UserActivityCompose.weekly(user) |> Mailer.deliver_later
	  end
	end
end