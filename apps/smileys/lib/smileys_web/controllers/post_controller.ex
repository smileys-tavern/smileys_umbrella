defmodule SmileysWeb.PostController do
  use SmileysWeb, :controller

  plug Smileys.Plugs.SetUser
  plug Smileys.Plugs.SetIsModerator

  alias SmileysData.{QueryPost, QueryUser}
  alias Smileys.Logic.PostHelpers
  alias SmileysData.State.User.Activity, as: UserActivity
  alias SmileysData.State.User.ActivityRegistry, as: UserActivityRegistry
  alias SmileysData.State.Post.Activity, as: PostActivity
  alias SmileysData.State.Post.ActivityRegistry, as: PostActivityRegistry


  def comment(conn, %{"hash" => hash, "depth" => depth, "ophash" => ophash, "body" => body} = _params) do
    user = case conn.assigns.user do
      nil ->
        %{:name => "amysteriousstranger", :id => 5, :reputation => 1}
      logged_in_user ->
        logged_in_user
    end
    
    # TODO: try to cast depth as an int coming in instead of here
    {comment_hash, comment_html} = case QueryPost.create_comment(hash, ophash, body, String.to_integer(depth), user) do
      {:ok, comment_result} ->
        reply_to = comment_result.reply_to
        op_user = QueryUser.user_by_id(reply_to.posterid)

        {url, _, comments, votes} = UserActivityRegistry.update_user_bucket!(
          {:via, :syn, :user_activity_reg},
          %UserActivity{user_name: op_user.name, hash: reply_to.hash, url: PostHelpers.create_link(reply_to, comment_result.room.name), comments: 1}
        )

        SmileysWeb.Endpoint.broadcast("user:" <> op_user.name, "activity", %UserActivity{user_name: op_user.name, hash: reply_to.hash, url: url, comments: comments, votes: votes})

        %PostActivity{comments: comment_count} = PostActivityRegistry.increment_post_bucket_comments!(
          {:via, :syn, :post_activity_reg},
          comment_result.op.hash,
          %PostActivity{comments: 1}
        )

        SmileysWeb.Endpoint.broadcast("room:" <> comment_result.room.name, "post-activity", %{comments: comment_count, hash: comment_result.op.hash})

        {comment_result.comment.hash,
         Phoenix.View.render_to_string(SmileysWeb.SharedView, "comment.html", %{
          :user    => user, 
          :comment => comment_result.comment, 
          :room    => comment_result.room, 
          :op      => comment_result.op})
        }
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