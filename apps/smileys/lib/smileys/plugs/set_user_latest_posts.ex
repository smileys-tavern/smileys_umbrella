defmodule Smileys.Plugs.SetUserLatestPosts do
  import Plug.Conn

  def init(default), do: default 

  def call(conn, _default) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        assign(conn, :userlatestposts, [])
      user ->
        assign(conn, :userlatestposts, SmileysData.QueryPost.latest_by_user(user, 3))
    end
  end
end