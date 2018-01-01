defmodule SmileysWeb.PostController do
  use SmileysWeb, :controller

  plug Smileys.Plugs.SetUser
  plug Smileys.Plugs.SetIsModerator

  alias Smileys.Logic.{PostHelpers, UserHelpers, PostScraper}

  alias SmileysData.Query.Post.Comment, as: QueryPostComment
  alias SmileysData.Query.Post.Anonymous, as: QueryPostAnonymous
  alias SmileysData.Query.Post.Moderator, as: QueryPostModerator
  alias SmileysData.Query.User, as: QueryUser

  alias SmileysData.State.Activity
  alias SmileysData.State.User.Activity, as: UserActivity
  alias SmileysData.State.User.Notification, as: UserNotification
  alias SmileysData.State.Post.Activity, as: PostActivity


  def comment(conn, %{"hash" => hash, "depth" => depth, "ophash" => ophash, "body" => body} = _params) do
    user = case conn.assigns.user do
      nil ->
        %{:name => "amysteriousstranger", :id => 5, :reputation => 1, :user_token => conn.assigns.mystery_token}
      logged_in_user ->
        logged_in_user
    end

    {actions, body_action_enhanced} = PostScraper.scan_for_actions(HtmlSanitizeEx.strip_tags(body))
    
    # TODO: try to cast depth as an int coming in instead of here
    {comment_hash, comment_html} = case QueryPostComment.create(hash, ophash, body_action_enhanced, String.to_integer(depth), user) do
      {:ok, comment_result} ->
        reply_to = comment_result.reply_to
        op_user = QueryUser.by_id(reply_to.posterid)

        %UserActivity{url: url, comments: comments, votes: votes} = Activity.update_item(
          %UserActivity{user_name: op_user.name, hash: reply_to.hash, url: PostHelpers.create_link(reply_to, comment_result.room.name), comments: 1}
        )

        SmileysWeb.Endpoint.broadcast("user:" <> op_user.name, "activity", %UserActivity{user_name: op_user.name, hash: reply_to.hash, url: url, comments: comments, votes: votes})

        %PostActivity{comments: comment_count} = Activity.update_item(%PostActivity{hash: comment_result.op.hash, comments: 1})

        SmileysWeb.Endpoint.broadcast("room:" <> comment_result.room.name, "post-activity", %{comments: comment_count, hash: comment_result.op.hash})

        for (action <- actions) do
          case action do
            {:shout, shout_to_name} ->
              user_notification = Activity.update_item(
                %UserNotification{user_name: shout_to_name, hash: reply_to.hash, url: PostHelpers.create_link(comment_result.comment, comment_result.room.name), pinged_by: user.name}
              )

              SmileysWeb.Endpoint.broadcast("user:" <> shout_to_name, "activity", user_notification)
            _ ->
              {} # NoOp
          end
        end

        if user.name == "amysteriousstranger" do
          QueryPostAnonymous.add(comment_result.comment.id, user.user_token)
        end

        {comment_result.comment.hash,
         Phoenix.View.render_to_string(SmileysWeb.SharedView, "comment.html", %{
          :user    => user, 
          :comment => comment_result.comment, 
          :room    => comment_result.room, 
          :op      => comment_result.op})
        }
      {:body_invalid, _} ->
        UserHelpers.broadcast_warning(user, "Post contains invalid characters.")
        {"", ""}
      {:post_frequency_violation, limit} ->
        limit_format = case limit do
          true ->
            "Unknown Limit"
          limit_string ->
            Integer.to_string(div(limit_string, 60)) <> " Minutes"
        end
        UserHelpers.broadcast_warning(user, "There is a short limit on posting frequency which will be removed after using the site more (" <> limit_format <> ")")
        {"", ""}
      {:error, _changeset} ->
        UserHelpers.broadcast_warning(user, "There was an error commenting. Check length of comment.")
        {"", ""}
    end

    json conn, %{comment: comment_html, hash: comment_hash, ochash: hash}
  end

  def mod_delete_comment(conn, %{"hash" => hash, "depth" => depth, "ophash" => ophash, "body" => body} = _params) do
    user = conn.assigns.user

    case QueryPostModerator.delete(user, hash, String.to_integer(depth), ophash, body) do
      {:ok, %{:new => new, :edited => edited}} ->
        comment_html = Phoenix.View.render_to_string SmileysWeb.SharedView, "comment.html", %{:user => user, :comment => new.comment, :room => new.room, :op => new.op}

        json conn, %{comment: comment_html, edited: edited.body, hash: new.comment.hash, ochash: hash}
      _ ->
        json conn, %{error: "Moderate comment attempt failed"}
    end
  end
end