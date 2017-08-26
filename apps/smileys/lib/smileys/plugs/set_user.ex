defmodule Smileys.Plugs.SetUser do
  import Plug.Conn


  def init(_), do: %{}

  def call(conn, _default) do
  	conn
  	|> assign(:user, Guardian.Plug.current_resource(conn))
  end
end