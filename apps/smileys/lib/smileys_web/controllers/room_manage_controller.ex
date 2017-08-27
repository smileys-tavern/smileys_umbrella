defmodule SmileysWeb.RoomManageController do
  use SmileysWeb, :controller

  alias SmileysData.{UserRoomAllow, ModeratorListing}

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
        SmileysData.QueryUserRoomAllow.user_allow_list_room(conn.assigns.room.name, params)
    end

    render conn, "manage.html", changeset: changeset, action: "new", userroomallow: userRoomAllow, kerosene: kerosene
  end

  def managesubs(conn, params) do
  	if !conn.assigns.ismod do
      conn
        |> put_status(401)
        |> render(SmileysWeb.ErrorView, "401.html")
    end

  	{subs, kerosene} = SmileysData.QueryUserRoomAllow.user_allow_list_room(conn.assigns.room.name, params)

  	render conn, "managesubs.html", action: "new", subs: subs, kerosene: kerosene
  end

  def manage_mods(conn, params) do
    if conn.assigns.ismod != "admin" do
      conn
        |> put_status(401)
        |> render(SmileysWeb.ErrorView, "401.html")
    end

    changeset = ModeratorListing.changeset(%ModeratorListing{})

    {mods, kerosene} = SmileysData.QueryUser.moderators_for_room(conn.assigns.room.id, params)

    render conn, "managemods.html", changeset: changeset, action: "mods/new", roommods: mods, kerosene: kerosene
  end

  def removeuser(conn, %{"username" => username} = _params) do
    if !conn.assigns.ismod do
      conn
        |> put_status(401)
        |> render(SmileysWeb.ErrorView, "401.html")
    end

    {:ok, userRoomAllow} = SmileysData.QueryUserRoomAllow.user_allowed_in_room(username, conn.assigns.room.name)

    userRoomAllowRepo = SmileysData.QueryUserRoomAllow.user_room_allow_by_id(userRoomAllow.id)

    SmileysData.QueryUserRoomAllow.user_room_allow_delete(userRoomAllowRepo)

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

    case SmileysData.QueryUserRoomAllow.user_room_allow_create(changeset) do
      {:ok, userroomallow} ->
        conn
          |> put_flash(:info, "User " <> userroomallow.username <> " allowed in room")
          |> redirect(to: "/room/" <> userroomallow.roomname <> "/manage")
      {:error, changeset} ->
        {userRoomAllow, kerosene} = cond do
          conn.assigns.room.type == "public" ->
            {nil, nil}
          true ->
            SmileysData.QueryUserRoomAllow.user_allow_list_room(conn.assigns.room.name, params)
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

    newMod = SmileysData.QueryUser.user_by_name(params["moderator_listing"]["username"])

    if !newMod do
      conn
        |> put_flash(:info, "User " <> params["moderator_listing"]["username"] <> " does not exist")
        |> redirect(to: "/room/" <> conn.assigns.room.name <> "/manage/mods")      
    end

    room = SmileysData.QueryRoom.room(conn.assigns.room.name)
    subscription = case SmileysData.QuerySubscription.user_subscription_to_room(newMod.id, room.name) do
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

    case SmileysData.QueryUser.user_moderator_add(changeset) do
      {:ok, _modListing} ->
        conn
          |> put_flash(:info, "User " <> newMod.name <> " became a " <> room.name <> " moderator")
          |> redirect(to: "/room/" <> room.name <> "/manage/mods")
      {:error, changeset} ->
        {mods, kerosene} =  SmileysData.QueryUser.moderators_for_room(conn.assigns.room.id, params)

        render conn, "managemods.html", changeset: changeset, action: "mods/new", roommods: mods, kerosene: kerosene
    end
  end

  def removemod(conn, %{"username" => username} = _params) do
    if conn.assigns.ismod != "admin" do
      conn
        |> put_status(401)
        |> render(SmileysWeb.ErrorView, "401.html")
    end

    user = SmileysData.QueryUser.user_by_name(username)
    room = SmileysData.QueryRoom.room(conn.assigns.room.name)

    modListing = SmileysData.QueryUser.user_room_moderator_listing(user.id, room.id)

    modListingRepo = SmileysData.QueryUser.moderator_listing_by_id(modListing.id)

    SmileysData.QueryUser.moderator_listing_delete(modListingRepo)

    conn
      |> put_flash(:info, "User " <> username <> " removed from the premise.")
      |> redirect(to: "/room/" <> conn.assigns.room.name <> "/manage/mods")
  end
end