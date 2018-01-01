defmodule Smileys.Plugs.SetCanSubscribe do
  import Plug.Conn

  alias SmileysData.Query.Room, as: QueryRoom
  alias SmileysData.Query.Room.Allow, as: QueryRoomAllow
  alias SmileysData.Query.User.Subscription, as: QueryUserSubscription


  def init(default), do: default 

  def call(%Plug.Conn{params: %{"room" => roomname}} = conn, _default) do
    room = QueryRoom.by_name(roomname)

    user = Guardian.Plug.current_resource(conn)

   	assign(conn, :cansubscribe, can_user_subscribe(user, room))
  end

  def call(conn, _) do
    assign(conn, :cansubscribe, false)
  end

  defp can_user_subscribe(user, room) do
    if !user || !room do
      false
    else
      # if already subscribed
      isSubscribed = case QueryUserSubscription.room_by_id(user.id, room.name) do
        {:no_subscription, _} ->
          false
        {:ok, _} ->
          true
      end

      if isSubscribed do
        false
      else
        case room.type do
          "public" ->
            true
          "private" ->
            case QueryRoomAllow.user_allowed(user.name, room.name) do
              nil ->
                false
              _ ->
                true
            end
          "restricted" ->
            true
          "house" ->
            false
        end
      end
    end
  end
end