defmodule Smileys.Vote.Action do
	@moduledoc """
	Handle logic in smileys related to voting
	"""

	alias SmileysData.State.User.{ActivityRegistry, Activity}
	alias Smileys.Logic.PostHelpers
	alias SmileysData.{Post, User, QueryVote}

	@doc """
	Vote a post positively
	"""
	def upvote(%Post{} = post, %User{} = user, %User{} = post_user, room_name) do
		{url, _, comments, votes} = ActivityRegistry.update_user_bucket!(
          {:global, :user_activity_reg},
          %Activity{user_name: post_user.name, hash: post.hash, url: PostHelpers.create_link(post, room_name), votes: 1}
        )

		SmileysWeb.Endpoint.broadcast("user:" <> post_user.name, "activity", %Activity{user_name: post_user.name, hash: post.hash, url: url, comments: comments, votes: votes})

		QueryVote.upvote(post, user)
	end

	@doc """
	Vote a post negatively
	"""
	def downvote(%Post{} = post, %User{} = user, %User{} = post_user, room_name) do
		{url, _, comments, votes} = ActivityRegistry.update_user_bucket!(
          {:global, :user_activity_reg},
          %Activity{user_name: post_user.name, hash: post.hash, url: PostHelpers.create_link(post, room_name), votes: -1}
        )

        SmileysWeb.Endpoint.broadcast("user:" <> post_user.name, "activity", %Activity{user_name: post_user.name, hash: post.hash, url: url, comments: comments, votes: votes})

		QueryVote.downvote(post, user)
	end
end