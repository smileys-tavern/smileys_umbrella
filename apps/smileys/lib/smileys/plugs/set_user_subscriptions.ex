defmodule Smileys.Plugs.SetUserSubscriptions do
  import Plug.Conn

  alias SmileysData.State.Room.ActivityRegistry, as: RoomActivityRegistry

  def init(default), do: default 

  def call(conn, _default) do
    user = Guardian.Plug.current_resource(conn)

    subscriptions = SmileysData.QuerySubscription.user_subscriptions(user)

    subscriptions_decorated = List.foldl(subscriptions, [], fn(subscription, acc) -> 
      room_activity = RoomActivityRegistry.retrieve_room_bucket!({:global, :room_activity_reg}, subscription.roomname)

      [Map.merge(subscription, room_activity)|acc]
    end)

   	assign(conn, :subscriptions, subscriptions_decorated)
  end
end