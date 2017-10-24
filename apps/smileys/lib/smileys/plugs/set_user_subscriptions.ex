defmodule Smileys.Plugs.SetUserSubscriptions do
  import Plug.Conn

  alias SmileysData.State.Activity
  alias SmileysData.State.Room.Activity, as: RoomActivity

  def init(default), do: default 

  def call(conn, _default) do
    user = Guardian.Plug.current_resource(conn)

    subscriptions = SmileysData.QuerySubscription.user_subscriptions(user)

    subscriptions_decorated = List.foldl(subscriptions, [], fn(subscription, acc) -> 
      room_activity = Activity.retrieve_item(%RoomActivity{room: subscription.roomname})

      [Map.merge(subscription, room_activity)|acc]
    end)

   	assign(conn, :subscriptions, subscriptions_decorated)
  end
end