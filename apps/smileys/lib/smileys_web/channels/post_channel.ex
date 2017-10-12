defmodule SmileysWeb.PostChannel do
  use Phoenix.Channel
  import Guardian.Phoenix.Socket

  require Logger


  def join("post:" <> _post_hash, %{"guardian_token" => token}, socket) do
    case sign_in(socket, token) do
      {:ok, authed_socket, _guardian_params} ->
        {:ok, %{result: "Joined"}, authed_socket}
      {:error, _reason} ->
        Logger.error "Auth error, expected token to auth user"
    end
  end
  
  # Readonly still allowed if no token
  def join("post:" <> _post_hash, _message, socket) do
    {:ok, socket}
  end

  def handle_in("edit", %{"posthash" => hash, "body" => body}, socket) do
    user = current_resource(socket)

    if !user do
      {:noreply, socket}
    else
      case SmileysData.QueryPost.edit_comment(hash, body, user) do
        nil ->
          SmileysWeb.Endpoint.broadcast("user:" <> user.name, "warning", %{msg: "issue editing post"})
          {:noreply, socket}
        comment ->
          {:reply, {:ok, %{comment: comment.body, hash: comment.hash}}, socket}
      end
    end
  end

  def handle_in("voteup", %{"posthash" => hash}, socket) do 
    user = current_resource(socket)

    post = SmileysData.QueryPost.post_by_hash(hash)

    result = case user do
      nil ->
        {:no_user, 0}
      _ ->
        room      = SmileysData.QueryRoom.room_by_id(post.superparentid)
        post_user = SmileysData.QueryUser.user_by_id(post.posterid)
        Smileys.Vote.Action.upvote(post, user, post_user, room.name)
    end
    
    _amt = case result do
      {:ok, amount} ->
        # broadcast on post channel
        broadcast! socket, "vote", %{posthash: hash, score: (post.votepublic + amount), result: amount, type: "up"}

        # broadcast on periferal channels
        SmileysWeb.Endpoint.broadcast("user:" <> user.name, "vote", %{direction: "up", hash: hash})
        SmileysWeb.Endpoint.broadcast("room:all", "vote", %{direction: "up", hash: hash})
        amount
      {:no_vote, amount} ->
        SmileysWeb.Endpoint.broadcast("user:" <> user.name, "warning", %{msg: "Votes are final and one per post"})
        amount
      {:vote_time_over, amount} ->
        SmileysWeb.Endpoint.broadcast("user:" <> user.name, "warning", %{msg: "Voting closed; voting lasts for 3 days"})
        amount
      _ ->
        0     
    end

    {:noreply, socket}
  end

  def handle_in("votedown", %{"posthash" => hash}, socket) do 
    user = current_resource(socket)

    post = SmileysData.QueryPost.post_by_hash(hash)

    result = case user do
      nil ->
        {:no_user, 0}
      _ ->
        room      = SmileysData.QueryRoom.room_by_id(post.superparentid)
        post_user = SmileysData.QueryUser.user_by_id(post.posterid)
        Smileys.Vote.Action.upvote(post, user, post_user, room.name)
    end

    _amt = case result do
      {:ok, amount} ->
        broadcast! socket, "vote", %{posthash: hash, score: (post.votepublic + amount), result: amount, type: "down"}

        SmileysWeb.Endpoint.broadcast("user:" <> user.name, "vote", %{direction: "down", hash: hash})
        SmileysWeb.Endpoint.broadcast("room:all", "vote", %{direction: "down", hash: hash})
        amount
      {:no_vote, amount} ->
        SmileysWeb.Endpoint.broadcast("user:" <> user.name, "warning", %{msg: "Votes are final and one per post"})
        amount
      {:vote_time_over, amount} ->
          SmileysWeb.Endpoint.broadcast("user:" <> user.name, "warning", %{msg: "Voting closed; voting lasts for 3 days"})
          amount
        _ ->
          0
    end

    {:noreply, socket}
  end
end