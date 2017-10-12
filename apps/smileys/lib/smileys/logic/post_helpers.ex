defmodule Smileys.Logic.PostHelpers do
	alias SmileysData.Post

	def create_link(%Post{hash: hash, title: title, parenttype: parenttype} = post, room_name) do
		cond do
			parenttype == "room" ->
				"/r/" <> room_name <> "/comments/" <> hash <> "/" <> title
			true ->
				"/r/" <> room_name <> "/comments/" <> post.ophash <> "/focus/" <> post.hash
		end
	end
end