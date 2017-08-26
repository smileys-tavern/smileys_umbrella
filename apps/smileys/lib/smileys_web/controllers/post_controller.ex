defmodule SmileysWeb.PostController do
  use SmileysWeb, :controller

  plug Smileys.Plugs.SetUser
  plug Smileys.Plugs.SetIsModerator


  def comment(conn, %{"hash" => hash, "depth" => depth, "ophash" => ophash, "body" => body} = _params) do
    user = case conn.assigns.user do
      nil ->
        %{:name => "amysteriousstranger", :id => 5, :reputation => 1}
      logged_in_user ->
        logged_in_user
    end
    
    # TODO: try to cast depth as an int coming in instead of here
    {comment_hash, comment_html} = case SmileysData.QueryPost.create_comment(hash, ophash, body, String.to_integer(depth), user) do
      {:ok, comment_result} ->
        SmileysWeb.Endpoint.broadcast("post:" <> ophash, "activity", %{msg: "Comment!", hash: hash, ophash: ophash})

        {comment_result.comment.hash,
         Phoenix.View.render_to_string(SmileysWeb.SharedView, "comment.html", %{:user => user, :comment => comment_result.comment, :room => comment_result.room, :op => comment_result.op})}
      {:body_invalid, _} ->
        SmileysWeb.Endpoint.broadcast("user:" <> user.name, "warning", %{msg: "Comment contains invalid characters."})
        {"", ""}
      {:post_frequency_violation, _} ->
        SmileysWeb.Endpoint.broadcast("user:" <> user.name, "warning", %{msg: "You have posted too recently. We have a short limit on posting frequency which will lessen after using the site more."})
        {"", ""}
      {:error, _changeset} ->
        SmileysWeb.Endpoint.broadcast("user:" <> user.name, "warning", %{msg: "There was an error commenting. Check length of comment."})
        {"", ""}
    end

    json conn, %{comment: comment_html, hash: comment_hash, ochash: hash}
  end

  def mod_delete_comment(conn, %{"hash" => hash, "depth" => depth, "ophash" => ophash, "body" => body} = _params) do
    user = conn.assigns.user

    case SmileysData.QueryPost.delete_post_by_moderator(user, hash, String.to_integer(depth), ophash, body) do
      {:ok, %{:new => new, :edited => edited}} ->
        comment_html = Phoenix.View.render_to_string SmileysWeb.SharedView, "comment.html", %{:user => user, :comment => new.comment, :room => new.room, :op => new.op}

        json conn, %{comment: comment_html, edited: edited.body, hash: new.comment.hash, ochash: hash}
      _ ->
        json conn, %{error: "Moderate comment attempt failed"}
    end
  end
end