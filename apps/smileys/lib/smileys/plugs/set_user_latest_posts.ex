defmodule Smileys.Plugs.SetUserLatestPosts do
  import Plug.Conn

  alias SmileysData.Query.Post, as: QueryPost

  def init(default), do: default 

  def call(conn, _default) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        assign(conn, :userlatestposts, [])
      user ->
        assign(conn, :userlatestposts, QueryPost.by_user_latest(user, 3))
    end
  end
end