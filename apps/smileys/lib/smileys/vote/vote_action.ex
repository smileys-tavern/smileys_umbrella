defmodule Smileys.Vote.Action do
	@moduledoc """
	Handle logic in smileys related to voting
	"""

	alias SmileysData.Query.Vote, as: QueryVote

	alias SmileysData.State.User.Activity, as: UserActivity
	alias SmileysData.State.Activity
	alias Smileys.Logic.PostHelpers
	alias SmileysData.{Post, User}

	@doc """
	Vote a post positively
	"""
	def upvote(%Post{} = post, %User{} = user, %User{} = post_user, room_name) do
		result = QueryVote.up(post, user)

		case result do
			{:ok, _} ->
				%UserActivity{url: url, comments: comments, votes: votes} = Activity.update_item(
		          %UserActivity{user_name: post_user.name, hash: post.hash, url: PostHelpers.create_link(post, room_name), votes: 1}
		        )

				SmileysWeb.Endpoint.broadcast("user:" <> post_user.name, "activity", %UserActivity{user_name: post_user.name, hash: post.hash, url: url, comments: comments, votes: votes})

				result
			_ ->
				result
		end
	end

	@doc """
	Vote a post negatively
	"""
	def downvote(%Post{} = post, %User{} = user, %User{} = post_user, room_name) do
		result = QueryVote.down(post, user)

		case result do
			{:ok, _} ->
				%UserActivity{url: url, comments: comments, votes: votes} = Activity.update_item(
		          %UserActivity{user_name: post_user.name, hash: post.hash, url: PostHelpers.create_link(post, room_name), votes: -1}
		        )

		        SmileysWeb.Endpoint.broadcast("user:" <> post_user.name, "activity", %UserActivity{user_name: post_user.name, hash: post.hash, url: url, comments: comments, votes: votes})

		        result
		    _ ->
		    	result
		end
	end
end