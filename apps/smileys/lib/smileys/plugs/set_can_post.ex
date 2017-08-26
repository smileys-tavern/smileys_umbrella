defmodule Smileys.Plugs.SetCanPost do
  import Plug.Conn


  def init(default), do: default 

  def call(%Plug.Conn{params: %{"room" => roomname}} = conn, _default) do
    room = SmileysData.QueryRoom.room(roomname)

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
            case SmileysData.QueryUserRoomAllow.user_allowed_in_room(user.name, room.name) do
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
            case  SmileysData.QueryUserRoomAllow.user_allowed_in_room(user.name, room.name) do
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