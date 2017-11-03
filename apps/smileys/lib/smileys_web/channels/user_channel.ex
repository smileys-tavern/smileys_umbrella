defmodule SmileysWeb.UserChannel do
  use Phoenix.Channel
  import Guardian.Phoenix.Socket

  require Logger

  alias SmileysData.State.Activity
  alias SmileysData.State.Room.Activity, as: RoomActivity
  alias SmileysData.State.User.Activity, as: UserActivity
  alias SmileysData.State.User.Notification, as: UserNotification

  intercept ["activity"]


  def join("user:" <> _user_name, %{"guardian_token" => token}, socket) do
    case sign_in(socket, token) do
      {:ok, authed_socket, _guardian_params} ->
        {:ok, %{result: "Joined"}, authed_socket}
      {:error, _reason} ->
        Logger.error "Auth error, expected token to auth user"
    end
  end

  def join("user:" <> _mystery_token, _message, socket) do
    {:ok, socket}
  end

  def handle_in("subscribe", %{"roomname" => room_name}, socket) do 
    room = SmileysData.QueryRoom.room(room_name)

    user = current_resource(socket)

    if SmileysData.QuerySubscription.can_user_subscribe_to_room(user, room) do
      case SmileysData.QuerySubscription.create_user_subscription(user, room) do
        {:ok, subscription} ->
          room_activity = Activity.update_item(%RoomActivity{room: room_name, subs: 1})

          SmileysWeb.Endpoint.broadcast("room:" <> room_name, "activity", room_activity)

          {:reply, {:ok, %{room: subscription.roomname}}, socket}
        _ ->
          {:reply, {:ok, %{room: nil}}, socket}
      end
    end
  end

  def handle_in("unsubscribe", %{"roomname" => room_name}, socket) do 
    user = current_resource(socket)

    case SmileysData.QuerySubscription.delete_user_subscription(user, room_name) do
      {:ok, roomname} ->
        room_activity = Activity.update_item(%RoomActivity{room: room_name, subs: -1})

        SmileysWeb.Endpoint.broadcast("room:" <> room_name, "activity", room_activity)

        {:reply, {:ok, %{room: roomname}}, socket}
      _ ->
        {:noreply, socket}
    end
  end

  def handle_in("load_thread", %{"hash" => hash, "mode" => mode}, socket) do
    post = SmileysData.QueryPost.post_by_hash(hash)

    op = SmileysData.QueryPost.post_by_hash(post.ophash)

    room = SmileysData.QueryRoom.room_by_id(post.superparentid)

    thread = SmileysData.QueryPost.get_thread(mode, post.id)


    thread_html = build_thread_html(thread, room, op)

    {:reply, {:ok, %{thread: thread_html}}, socket}
  end

  def handle_in("search_for", %{"term" => term, "offset" => offset, "user_token" => user_token}, socket) do

    user = current_resource(socket)

    {search_results, amount} = case SmileysSearch.QueryPost.posts_all(term, offset) do
      {:ok, results, amount_results} ->
        {results, amount_results}
      {:error, _} ->
        {[], 0}
    end

    posts = SmileysData.QueryPost.post_summary_by_ids(search_results)

    channel_id = case user do
      nil ->
        user_token
      user ->
        user.name
    end

    SmileysWeb.Endpoint.broadcast("user:" <> channel_id, "search_result", %{results: posts, amt: amount})

    {:noreply, socket}
  end

  def handle_in("search_suggest", %{"term" => _term, "user_token" => _user_token}, socket) do
    #suggest_results = case SmileysSearch.QueryPost.suggest(term) do
    #  {:ok, results} ->
    #    user = current_resource(socket)
    #    SmileysWeb.Endpoint.broadcast("user:" <> user.id, "suggest_result", %{results: results})
    #  {:error, _} ->
    #    []
    #end

    {:noreply, socket}
  end

  def handle_out("activity", %UserActivity{hash: post_hash} = activity_payload, socket) do
    activity_html = Phoenix.View.render_to_string(SmileysWeb.SharedView, "user_activity.html", %{activity: activity_payload})
    
    push socket, "activity", %{html: activity_html, hash: post_hash}
    
    {:noreply, socket}    
  end

  def handle_out("activity", %UserNotification{hash: post_hash} = activity_payload, socket) do
    activity_html = Phoenix.View.render_to_string(SmileysWeb.SharedView, "user_notification.html", %{notification: activity_payload})
    
    push socket, "activity", %{html: activity_html, hash: post_hash}
    
    {:noreply, socket}    
  end

  defp build_thread_html(thread, room, op) do
    build_thread_html_a(thread, room, op, "")
  end

  defp build_thread_html_a([], _, _, acc) do
    acc
  end

  defp build_thread_html_a([thread_post|tail], room, op, acc) do
    acc_appended = acc <> Phoenix.View.render_to_string(
      SmileysWeb.SharedView, 
      "comment.html", 
      %{:comment => thread_post, :room => room, :op => op}
    )

    build_thread_html_a(tail, room, op, acc_appended)
  end
end