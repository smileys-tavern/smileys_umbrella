defmodule SmileysWeb.RoomEditController do
  use SmileysWeb, :controller

  alias SmileysData.{Room, UserRoomAllow}



  plug Smileys.Plugs.SetUser
  plug Smileys.Plugs.SetIsModerator


  def new(conn, _params) do
  	changeset = Room.changeset(%Room{})

  	if !conn.assigns.user do
  		conn
	    	|> put_status(:not_found)
	   		|> render(SmileysWeb.ErrorView, "login.html")
  	end

    render conn, "create.html", changeset: changeset, action: "new"
  end

  def create(conn, %{"room" => room_params} = params) do
  	# Add data that is created for each room automatically
  	room_params_additions = Map.put_new(room_params, "creatorid", conn.assigns.user.id)
      |> Map.put_new("reputation", conn.assigns.user.reputation)

    room_params_final = %{room_params_additions | "title" => HtmlSanitizeEx.basic_html(room_params_additions["title"])}

    changeset = Room.changeset(%Room{}, room_params_final)

    captcha_response = if Application.get_env(:smileys, :captcha) == :off do
      true
    else
      case Recaptcha.verify(params["g-recaptcha-response"]) do
        {:ok, _response} ->
          true
        _ ->
          false
      end
    end

    cond do
      captcha_response ->
        case SmileysData.QueryRoom.room_create(changeset) do
          {:ok, room} ->
            current_user_w_moderation = case SmileysData.QueryUser.create_user_moderator_privalege(conn.assigns.user, room, "admin") do
              {:ok, user_w_moderation} ->
                user_w_moderation
              _ ->
                conn.assigns.user
            end

            user_room_params = %{username: conn.assigns.user.name, roomname: room.name}

            room_allow_changeset = UserRoomAllow.changeset(%UserRoomAllow{}, user_room_params)

            _ = SmileysData.QueryUserRoomAllow.user_room_allow_create(room_allow_changeset)

            conn
              |> put_flash(:info, "Room created successfully.")
              |> Guardian.Plug.sign_in(current_user_w_moderation, :token, perms: SmileysData.QueryUser.user_permission_level(current_user_w_moderation))
              |> redirect(to: "/r/" <> room.name)
          {:error, changeset} ->
            conn
            |> render("create.html", changeset: changeset, action: "new")
        end
      true ->
        conn
          |> put_flash(:error, "Captcha verification failed")
          |> render("create.html", changeset: changeset, action: "new")
    end
  end

  def edit(conn, %{"roomname" => room_name}) do
    if !conn.assigns.ismod do
      conn
        |> put_status(401)
        |> render(SmileysWeb.ErrorView, "401.html")
    end

    room = SmileysData.QueryRoom.room(room_name)

    changeset = Room.changeset(room)
    
    render(conn, "edit.html", room: room, changeset: changeset, action: "edit")
  end

  def update(conn, %{"roomname" => room_name, "room" => room_params}) do
    if !conn.assigns.ismod do
      conn
        |> put_status(401)
        |> render(SmileysWeb.ErrorView, "401.html")
    end

    room = SmileysData.QueryRoom.room(room_name)

    changeset = Room.changeset(room, room_params)

    case SmileysData.QueryRoom.room_update(changeset) do
      {:ok, _room} ->
        conn
        |> put_flash(:info, "Room updated successfully.")
        |> redirect(to: "/r/" <> room_name)
      {:error, changeset} ->
        render(conn, "edit.html", room: room, changeset: changeset, action: "edit")
    end
  end
end