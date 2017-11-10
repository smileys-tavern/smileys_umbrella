defmodule Smileys.Plugs.SetUserActivity do
  import Plug.Conn

  alias SmileysData.State.Activity
  alias SmileysData.State.User.Activity, as: UserActivity
  alias SmileysData.State.User.Activity, as: UserNotification

  def init(default), do: default 

  def call(conn, _default) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        assign(conn, :useractivity, [])
      user ->
        activity = Activity.retrieve(%UserActivity{user_name: user.name})

        assign(conn, :useractivity, Enum.map(activity, fn {_, activity} -> activity end))
    end
  end
end