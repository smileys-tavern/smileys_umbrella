defmodule SmileysWeb.RoomPostController do
  use SmileysWeb, :controller

  alias SmileysData.{Post, PostMeta}

  plug Smileys.Plugs.SetCanPost
  plug Smileys.Plugs.SetUser


  def new(conn, _params) do
    if !conn.assigns.canpost do
      conn |> put_flash(:info, "A restricted room friend.  You need be granted passage.") |> put_status(401) |> render(SmileysWeb.ErrorView, "401.html")
    end

  	current_user = conn.assigns.user

  	changeset = Post.changeset(%Post{})

  	current_user = case current_user do
  		nil ->
        %{name: "amysteriousstranger", reputation: 1, id: 5}
      _ ->
        current_user
  	end

    render conn, "create.html", user: current_user, changeset: changeset, action: "new"
  end

  # needs some refactoring. Very big method at the moment
  def create(conn, %{"post" => post_params, "room" => room_name, "meta" => meta_params} = params) do
    if !conn.assigns.canpost do
      conn 
        |> put_flash(:info, "A restricted room friend.  You must be granted passage.") 
        |> put_status(401) 
        |> render(SmileysWeb.ErrorView, "401.html")
    end

  	current_user = case conn.assigns.user do
      nil ->
        %{:id => 5, :reputation => 1, :name => "amysteriousstranger"}
      user ->
        user 
    end

    room = SmileysData.QueryRoom.room(room_name)

  	# Add data that is created for each post automatically
  	post_params_1 = Map.put_new(post_params, "posterid", current_user.id)
  	  |> Map.put_new("voteprivate", current_user.reputation)
      |> Map.put_new("votepublic", 0)
      |> Map.put_new("hash", SmileysData.QueryPost.create_hash(current_user.id, room_name))
      |> Map.put_new("superparentid", room.id)
      |> Map.put_new("parentid", room.id)
      |> Map.put_new("parenttype", "room")
      |> Map.put_new("age", room.age)

    changeset = Post.changeset(%Post{}, post_params_1)

    meta_params_1 = Map.put_new(meta_params, "userid", current_user.id)

    image_param = cond do
      Map.has_key?(meta_params, "image") ->
        meta_params["image"]
      true ->
        nil
    end

    meta_params_2 = cond do
      Map.has_key?(meta_params, "image") ->
        Map.delete(meta_params_1, "image")
      true ->
        meta_params_1
    end

    changeset_meta = PostMeta.changeset(%PostMeta{}, meta_params_2)

    # Recaptcha wall
    if Application.get_env(:smileys, :captcha) == :on do
      case Recaptcha.verify(params["g-recaptcha-response"]) do
        {:error, _errors} ->
          conn
            |> put_flash(:error, "Captcha verification failed")
            |> render("create.html", user: current_user, changeset: changeset, changeset_meta: changeset_meta, action: "new")
      end
    end

    # must be logged in if uploading material (needs refactor. super clumsy to be here)
    if meta_params["image"] && current_user.id == Application.get_env(:smileys, :mysteryuser) do
      conn
        |> put_flash(:info, "Please log in to upload images. Or just link an external image.")
        |> render("create.html", user: current_user, changeset: changeset, changeset_meta: changeset_meta, action: "new")
    end



    # special body check for USER input stuff
    body_check = cond do
      SmileysData.QueryPost.validate_post_body(post_params_1["body"]) ->
        true
      String.length(post_params_1["body"]) == 0 ->
        true
      true ->
        false
    end

    # special image check
    valid_image = cond do
      image_param ->
        Smileys.Logic.PostMeta.is_valid_upload(image_param)
      true ->
        true
    end

    cond do 
      changeset.valid? && changeset_meta.valid? && valid_image && body_check ->
      
        tag_data = Smileys.Logic.PostMeta.process_tags(meta_params, meta_params["tags"])

        image_upload = case image_param do
          nil ->
            nil
          image_param_valid ->
            Smileys.Logic.PostMeta.upload_image(image_param_valid, tag_data[:tags])
        end

        post_params_2 = %{post_params_1 | "body" => Smileys.Logic.PostMeta.modify_post_by_meta_tags(post_params_1["body"], tag_data)}

        case SmileysData.QueryPost.create_new_post(current_user, post_params_2, meta_params, image_upload) do
          {:ok, _} ->
            conn
              |> put_flash(:info, "Posted successfully.")
              |> redirect(to: "/r/" <> room.name)
          {:post_freqency_violation, _} ->
              conn
                |> put_flash(:error, "You have posted too recently. We have a short limit on posting frequency which will lessen after using the site more.")
                |> render("create.html", changeset: changeset, changeset_meta: changeset_meta, action: "new", user: current_user)
          {:error, changeset} ->
              render(conn, "create.html", changeset: changeset, action: "new")
        end
      true ->
        error_msg = cond do
          !valid_image ->
            "Valid image formats include .jpg .jpeg .gif .png .JPG at the moment"
          !changeset_meta.valid? ->
            {first_error_text, first_error_meta} = changeset_meta.errors[:tags]
          
            case List.keyfind(first_error_meta, :count, 0) do
              {:count, count} ->
                "Currently " <> Integer.to_string(count) <> " characters worth of tags are allowable"
              _ ->
                first_error_text
            end
          !body_check ->
            "Your post is only allowed basic characters and punctuation currently"
          true ->
            "There was an issue with your post data or meta data"
        end

        conn
          |> put_flash(:error, error_msg)
          |> render("create.html", changeset: changeset, changeset_meta: changeset_meta, action: "new", user: current_user)
    end
  end
end