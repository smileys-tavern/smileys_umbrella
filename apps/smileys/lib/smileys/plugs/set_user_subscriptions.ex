defmodule Smileys.Plugs.SetUserSubscriptions do
  import Plug.Conn

  def init(default), do: default 

  def call(conn, _default) do
    user = Guardian.Plug.current_resource(conn)

   	assign(conn, :subscriptions, SmileysData.QuerySubscription.user_subscriptions(user))
  end
end