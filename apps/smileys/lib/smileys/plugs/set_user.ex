defmodule Smileys.Plugs.SetUser do
  import Plug.Conn

  alias SmileysData.Query.User.Helper, as: QueryUserHelper

  def init(_), do: %{}

  def call(conn, _default) do
  	case Guardian.Plug.current_resource(conn) do
  		nil ->
  			conn 
  				|> assign(:user, nil)
  				|> assign(:mystery_token, QueryUserHelper.create_hash(conn.remote_ip))
  		user ->
  			conn
  				|> assign(:user, user)
  	end
  end
end