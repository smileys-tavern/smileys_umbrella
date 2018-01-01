defmodule SmileysWeb.PageController do
  use SmileysWeb, :controller

  plug Smileys.Plugs.SetNewRooms, 5
  plug Smileys.Plugs.SetCanPost
  plug Smileys.Plugs.SetUser
  plug Smileys.Plugs.SetCanSubscribe
  plug Smileys.Plugs.SetUserSubscriptions
  plug Smileys.Plugs.SetUserActivity
  plug Smileys.Plugs.SetIsModerator

  alias SmileysData.State.Activity
  alias SmileysData.State.Post.Activity, as: PostActivity

  alias SmileysData.Query.Post, as: QueryPost
  alias SmileysData.Query.Post.Summary, as: QueryPostSummary
  alias SmileysData.Query.Post.Meta, as: QueryPostMeta
  alias SmileysData.Query.Post.Thread, as: QueryPostThread
  alias SmileysData.Query.Room, as: QueryRoom
  alias SmileysData.Query.Room.Allow, as: QueryRoomAllow
  alias SmileysData.Query.User, as: QueryUser
  alias SmileysData.Query.User.Moderator, as: QueryUserModerator


  def index(conn, _params) do
    {posts, _} = QueryPostSummary.get(10)

    reputable_rooms = QueryRoom.list(:reputation, 5)

    render conn, "index.html", new_posts: decorate_post_comment_count(posts), reputable_rooms: reputable_rooms
  end

  def profile(conn, %{"username" => user_name} = _params) do
    case QueryUser.by_name(user_name) do
      %{name: _} = user ->
        posts = QueryPost.by_user_latest(user, 50, false)

        render conn, "profile.html", posts: posts, profileuser: user
      _ ->
        conn
          |> put_status(:not_found)
          |> render(SmileysWeb.ErrorView, "404.html")
    end
  end

  def settings(conn, %{"username" => user_name} = _params) do
    current_user = conn.assigns.user

    cond do
      current_user.name == user_name ->
        render conn, "settings.html"
      true ->
        conn
          |> put_status(401)
          |> render(SmileysWeb.ErrorView, "401.html")
    end
  end

  def house(conn, %{"room" => room_name} = _params) do
  	room = QueryRoom.by_name(room_name)

  	if !room do
  	  conn
	    |> put_status(:not_found)
	   	|> render(SmileysWeb.ErrorView, "404.html")
  	end

  	{posts, _} = case room_name do
  		"all" -> 
  		  QueryPostSummary.get(30)
  		"walloffame" ->
  		  QueryPostSummary.get(30, :alltime)
  		_ ->
  		  conn
  		  	|> put_status(:not_found)
  		  	|> render(Smileys.ErrorView, "404.html")
  	end

  	render conn, "house.html", room: room, posts: decorate_post_comment_count(posts), roomtype: "house"
  end

  def room(conn, %{"room" => room_name} = params) do
  	room = QueryRoom.by_name(room_name)

    current_user = conn.assigns.user

  	if !room do
  	  conn
	    |> put_status(:not_found)
	   	|> render(SmileysWeb.ErrorView, "404.html")
  	end

    {:ok, is_mod} = allowed_in_room(conn, current_user, room)

  	{posts, kerosene} = cond do
  		(params["mode"] && params["mode"] == "new") ->
	  		QueryPostSummary.by_room(25, :new, room.id, params)
  		true ->
		  	QueryPostSummary.by_room(25, :vote, room.id, params)
	  end

  	render conn, "room.html", room: room, posts: decorate_post_comment_count(posts), ismod: is_mod, roomtype: "room", kerosene: kerosene
  end

  def comments(conn, %{"room" => _room, "hash" => hash, "focushash" => focushash} = _params) do
    current_user = conn.assigns.user

  	post = QueryPost.by_hash(focushash)

  	op = QueryPost.by_hash(hash)

    roomData = QueryRoom.by_id(post.superparentid)

    parentpost = case post.parenttype do
      "room" ->
        nil
      _ ->
        QueryPost.by_id(post.parentid)
    end

    _ = allowed_in_room(conn, current_user, roomData)

  	original_poster = QueryUser.by_id(post.posterid)

  	comments = QueryPostThread.by_post_id(post.id, "focus")

  	render conn, "post.html", post: post, op: op, title: roomData.name, roomtype: "room", room: roomData, comments: comments, opname: original_poster.name, parent: parentpost, opmeta: nil
  end

  def comments(conn, %{"room" => _room, "hash" => hash} = params) do
    current_user = conn.assigns.user

  	post = QueryPost.by_hash(hash)

    if !post do
      conn 
        |> put_status(404) 
        |> render(SmileysWeb.ErrorView, "404.html")
    end

  	op = post

  	op_meta = QueryPostMeta.by_post_id(op.id)

  	original_poster = QueryUser.by_id(post.posterid)

  	roomData = QueryRoom.by_id(post.superparentid)

    _ = allowed_in_room(conn, current_user, roomData)

  	{comments, mode} = cond do
  		params["mode"] && params["mode"] == "new" ->
  			{QueryPostThread.by_post_id(post.id, "new"), "new"}
  	  true ->
  			{QueryPostThread.by_post_id(post.id, "hot"), "hot"}
  	end

  	render conn, "post.html", post: post, op: op, title: roomData.name, mode: mode, roomtype: "room", room: roomData, comments: comments, opname: original_poster.name, opmeta: op_meta
  end

  def about(conn, _params) do
    render conn, "about.html"
  end

  def tos(conn, _params) do
    render conn, "tos.html"
  end

  defp decorate_post_comment_count(posts) do
    posts_decorated = Enum.map(posts, fn(post) ->
      %PostActivity{comments: comments} = Activity.retrieve_item(%PostActivity{hash: post.hash})

      Map.put(post, :comment_count, comments)
    end)

    posts_decorated
  end

  defp allowed_in_room(conn, current_user, room) do
    is_mod = cond do 
      Map.has_key?(conn.assigns, :user) && current_user ->
        QueryUserModerator.moderating_room(current_user, room.id)
      true ->
        false
    end

    # See if user has permission to view room
    if room.type == "private" do
      if !current_user do
        conn |> put_status(401) |> render(SmileysWeb.ErrorView, "401.html")
      else
        user_in_allow_list = case QueryRoomAllow.user_allowed(current_user.name, room.name) do
          {:user_not_allowed, _} ->
            false
          _ ->
            true
        end

        if !is_mod && !user_in_allow_list do
          conn 
            |> put_status(401) 
            |> render(SmileysWeb.ErrorView, "401.html")
        end
      end
    end

    {:ok, is_mod}
  end
end

