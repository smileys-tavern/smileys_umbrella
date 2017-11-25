defmodule SmileyscaretakerWeb.Emails.UserActivityCompose do
  use Bamboo.Phoenix, view: SmileyscaretakerWeb.EmailView

  alias SmileysData.QuerySubscription

  alias SmileysData.State.Activity
  alias SmileysData.State.Room.Activity, as: RoomActivity
  alias SmileysData.State.User.Activity, as: UserActivity

  def daily(user) do
    activity = Activity.retrieve(%UserActivity{user_name: user.name})

    activity_list = Enum.map(activity, fn {_, activity} -> activity end)

    subscriptions = QuerySubscription.user_subscriptions(user)

    subscriptions_decorated = List.foldl(subscriptions, [], fn(subscription, acc) -> 
      room_activity = Activity.retrieve_item(%RoomActivity{room: subscription.roomname})

      [Map.merge(subscription, room_activity)|acc]
    end)

    base_email(user)
      |> subject("Smileys Pub Daily")
      |> render(:activity_daily, %{:user => user, :useractivity => activity_list, :subscriptions => subscriptions_decorated})
  end

  def weekly(user) do
    activity = Activity.retrieve(%UserActivity{user_name: user.name})

    activity_list = Enum.map(activity, fn {_, activity} -> activity end)

    subscriptions = QuerySubscription.user_subscriptions(user)

    subscriptions_decorated = List.foldl(subscriptions, [], fn(subscription, acc) -> 
      room_activity = Activity.retrieve_item(%RoomActivity{room: subscription.roomname})

      [Map.merge(subscription, room_activity)|acc]
    end)

    base_email(user)
      |> subject("Smileys Pub Weekly")
      |> render(:activity_weekly, %{:user => user, :useractivity => activity_list, :subscriptions => subscriptions_decorated})
  end

  defp base_email(user) do
    new_email()
      |> from("Smileys Pub<no-reply@smileys.pub>")
      |> to(user.email)
      |> put_layout({SmileyscaretakerWeb.LayoutView, :email})
  end
end
