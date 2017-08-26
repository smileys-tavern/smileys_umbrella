defmodule Smileys.Plugs.SetNewRooms do
  import Plug.Conn


  def init(limit), do: limit

  def call(conn, limit) do
  	assign(conn, :new_rooms, SmileysData.QueryRoom.list_by(:inserted_at, limit))
  end
end