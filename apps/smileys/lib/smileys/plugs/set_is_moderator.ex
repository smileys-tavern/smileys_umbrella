defmodule Smileys.Plugs.SetIsModerator do
  import Plug.Conn

  alias SmileysData.Query.Room, as: QueryRoom
  alias SmileysData.Query.User.Moderator, as: QueryUserModerator

  def init(default), do: default 

  def call(%Plug.Conn{params: %{"roomname" => roomname}} = conn, _default) do
    assign_ismod(conn, roomname)
  end

  def call(%Plug.Conn{params: %{"room" => room}} = conn, _default) do
    case room do
      %{} ->
        assign(conn, :ismod, false)
      roomname ->
        assign_ismod(conn, roomname)
    end
  end

  def call(conn, _) do
    assign(conn, :ismod, false)
  end

  defp assign_ismod(conn, roomname) do
    user = Guardian.Plug.current_resource(conn)

    room = QueryRoom.by_name(roomname)

    isMod = cond do
      !user || !room ->
        false
      true ->
        QueryUserModerator.moderating_room(user, room.id)
    end

    conn
      |> assign(:room, room)
      |> assign(:ismod, isMod)
  end
end