defmodule Smileys.Plugs.SetCanPost do
  import Plug.Conn

  alias SmileysData.Query.Room, as: QueryRoom
  alias SmileysData.Query.Room.Allow, as: QueryRoomAllow


  def init(default), do: default 

  def call(%Plug.Conn{params: %{"room" => room_name}} = conn, _default) do
    room = QueryRoom.by_name(room_name)

    if !room do
      assign(conn, :canpost, false)
    else
      user = Guardian.Plug.current_resource(conn)

      canpost = case room.type do
        "public" ->
          true
        "private" ->
          if !user do
            false
          else
            case QueryRoomAllow.user_allowed(user.name, room.name) do
              {:user_not_allowed, _} ->
                false
              {:ok, _} ->
                true
            end
          end
        "restricted" ->
          if !user do
            false
          else
            case  QueryRoomAllow.user_allowed(user.name, room.name) do
              {:user_not_allowed, _} ->
                false
              {:ok, _} ->
                true
            end
          end
        "house" ->
          false
      end

      put_session(conn, :ip_address, conn.remote_ip)

    	assign(conn, :canpost, canpost)
    end
  end

  def call(conn, _) do
    put_session(conn, :ip_address, conn.remote_ip)

    assign(conn, :canpost, false)
  end
end