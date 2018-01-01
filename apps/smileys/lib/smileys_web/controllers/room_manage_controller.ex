defmodule SmileysWeb.RoomManageController do
  use SmileysWeb, :controller

  alias SmileysData.{UserRoomAllow, ModeratorListing}

  alias SmileysData.Query.Room, as: QueryRoom
  alias SmileysData.Query.Room.Allow, as: QueryRoomAllow
  alias SmileysData.Query.User, as: QueryUser
  alias SmileysData.Query.User.Moderator, as: QueryUserModerator
  alias SmileysData.Query.User.Subscription, as: QueryUserSubscription

  plug Smileys.Plugs.SetUser
  plug Smileys.Plugs.SetIsModerator


  def manage(conn, params) do
    if !conn.assigns.ismod do
      conn
        |> put_status(401)
        |> render(SmileysWeb.ErrorView, "401.html")
    end

    changeset = UserRoomAllow.changeset(%UserRoomAllow{})

    {userRoomAllow, kerosene} = cond do
      conn.assigns.room.type == "public" ->
        {nil, nil}
      true ->
        QueryRoomAllow.user_list(conn.assigns.room.name, params)
    end

    render conn, "manage.html", changeset: changeset, action: "new", userroomallow: userRoomAllow, kerosene: kerosene
  end

  def managesubs(conn, params) do
  	if !conn.assigns.ismod do
      conn
        |> put_status(401)
        |> render(SmileysWeb.ErrorView, "401.html")
    end

  	{subs, kerosene} = QueryRoomAllow.user_list(conn.assigns.room.name, params)

  	render conn, "managesubs.html", action: "new", subs: subs, kerosene: kerosene
  end

  def manage_mods(conn, params) do
    if conn.assigns.ismod != "admin" do
      conn
        |> put_status(401)
        |> render(SmileysWeb.ErrorView, "401.html")
    end

    changeset = ModeratorListing.changeset(%ModeratorListing{})

    {mods, kerosene} = QueryUserModerator.moderators_for_room(conn.assigns.room.id, params)

    render conn, "managemods.html", changeset: changeset, action: "mods/new", roommods: mods, kerosene: kerosene
  end

  def removeuser(conn, %{"username" => username} = _params) do
    if !conn.assigns.ismod do
      conn
        |> put_status(401)
        |> render(SmileysWeb.ErrorView, "401.html")
    end

    {:ok, userRoomAllow} = QueryRoomAllow.user_allowed(username, conn.assigns.room.name)

    userRoomAllowRepo = QueryRoomAllow.by_id(userRoomAllow.id)

    QueryRoomAllow.delete(userRoomAllowRepo)

    conn
      |> put_flash(:info, "User " <> username <> " removed from the premise.")
      |> redirect(to: "/room/" <> conn.assigns.room.name <> "/manage")
  end

  def allowuser(conn, params) do
    if !conn.assigns.ismod do
      conn
        |> put_status(401)
        |> render(SmileysWeb.ErrorView, "401.html")
    end

    userRoomParams = %{username: params["user_room_allow"]["username"], roomname: conn.assigns.room.name}

    changeset = UserRoomAllow.changeset(%UserRoomAllow{}, userRoomParams)

    case QueryRoomAllow.create(changeset) do
      {:ok, userroomallow} ->
        conn
          |> put_flash(:info, "User " <> userroomallow.username <> " allowed in room")
          |> redirect(to: "/room/" <> userroomallow.roomname <> "/manage")
      {:error, changeset} ->
        {userRoomAllow, kerosene} = cond do
          conn.assigns.room.type == "public" ->
            {nil, nil}
          true ->
            QueryRoomAllow.user_list(conn.assigns.room.name, params)
        end

        render conn, "manage.html", changeset: changeset, action: "new", userroomallow: userRoomAllow, kerosene: kerosene
    end
  end

def addmod(conn, params) do
    if conn.assigns.ismod != "admin" do
      conn
        |> put_status(401)
        |> render(SmileysWeb.ErrorView, "401.html")
    end

    newMod = QueryUser.by_name(params["moderator_listing"]["username"])

    if !newMod do
      conn
        |> put_flash(:info, "User " <> params["moderator_listing"]["username"] <> " does not exist")
        |> redirect(to: "/room/" <> conn.assigns.room.name <> "/manage/mods")      
    end

    room = QueryRoom.by_name(conn.assigns.room.name)

    subscription = case QueryUserSubscription.room_by_id(newMod.id, room.name) do
      {:ok, sub} ->
        sub
      _ ->
        nil
    end

    if !subscription do
      conn
        |> put_flash(:info, "User must subscribe to room before becoming a moderator")
        |> redirect(to: "/room/" <> conn.assigns.room.name <> "/manage/mods")
    end

    modParams = %{userid: newMod.id, roomid: room.id, type: "mod"}

    changeset = ModeratorListing.changeset(%ModeratorListing{}, modParams)

    case QueryUserModerator.add(changeset) do
      {:ok, _modListing} ->
        conn
          |> put_flash(:info, "User " <> newMod.name <> " became a " <> room.name <> " moderator")
          |> redirect(to: "/room/" <> room.name <> "/manage/mods")
      {:error, changeset} ->
        {mods, kerosene} =  QueryUserModerator.moderators_for_room(conn.assigns.room.id, params)

        render conn, "managemods.html", changeset: changeset, action: "mods/new", roommods: mods, kerosene: kerosene
    end
  end

  def removemod(conn, %{"username" => username} = _params) do
    if conn.assigns.ismod != "admin" do
      conn
        |> put_status(401)
        |> render(SmileysWeb.ErrorView, "401.html")
    end

    user = QueryUser.by_name(username)
    room = QueryRoom.by_name(conn.assigns.room.name)

    modListing = QueryUserModerator.by_room_id(user.id, room.id)

    modListingRepo = QueryUserModerator.by_id(modListing.id)

    QueryUserModerator.delete(modListingRepo)

    conn
      |> put_flash(:info, "User " <> username <> " removed from the premise.")
      |> redirect(to: "/room/" <> conn.assigns.room.name <> "/manage/mods")
  end
end