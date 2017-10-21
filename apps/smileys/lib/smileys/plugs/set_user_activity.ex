defmodule Smileys.Plugs.SetUserActivity do
  import Plug.Conn

  alias SmileysData.State.User.{Activity, ActivityRegistry}

  def init(default), do: default 

  def call(conn, _default) do
    case Guardian.Plug.current_resource(conn) do
      nil ->
        assign(conn, :useractivity, [])
      user ->
        activity = ActivityRegistry.retrieve_user_bucket!({:via, :syn, :user_activity_reg}, user.name)
        
        assign(conn, :useractivity, Enum.map(activity, fn {hash, {url, _, comments, votes}} -> 
          %Activity{hash: hash, url: url, comments: comments, votes: votes}
        end))
    end
  end
end