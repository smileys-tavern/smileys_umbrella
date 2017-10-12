defmodule Smileys.Vote.Action do
	@moduledoc """
	Handle logic in smileys related to voting
	"""

	alias Smileys.User.{ActivityRegistry, Activity}
	alias Smileys.Logic.PostHelpers
	alias SmileysData.{Post, User, QueryVote}

	@doc """
	Vote a post positively
	"""
	def upvote(%Post{} = post, %User{} = user, %User{} = post_user, room_name) do
		_ = ActivityRegistry.update_user_bucket!(
          :user_activity_reg,
          %Activity{user_name: post_user.name, hash: post.hash, url: PostHelpers.create_link(post, room_name), votes: 1}
        )

		QueryVote.upvote(post, user)
	end

	@doc """
	Vote a post negatively
	"""
	def downvote(%Post{} = post, %User{} = user, %User{} = post_user, room_name) do
		_ = ActivityRegistry.update_user_bucket!(
          :user_activity_reg,
          %Activity{user_name: post_user.name, hash: post.hash, url: PostHelpers.create_link(post, room_name), votes: -1}
        )

		QueryVote.downvote(post, user)
	end
end