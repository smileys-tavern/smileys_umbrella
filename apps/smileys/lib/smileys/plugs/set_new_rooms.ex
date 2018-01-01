defmodule Smileys.Plugs.SetNewRooms do
  import Plug.Conn

  alias SmileysData.Query.Room, as: QueryRoom


  def init(limit), do: limit

  def call(conn, limit) do
  	assign(conn, :new_rooms, QueryRoom.list(:inserted_at, limit))
  end
end