defmodule Smileysapi.Resolver.Post do

  def get(%{room: room_name} = params, _info) do
  	room = SmileysData.QueryRoom.room(room_name)

    # TODO refactor to matching function clauses
  	limit = case params do
  		%{limit: limit_param} ->
  			limit_param
  		_ ->
  			10
  	end

  	offset = case params do
  		%{offset: offset_param} ->
  			offset_param
  		_ ->
  			0
  	end

  	order_by = case params do
  		%{mode: mode_param} ->
  			case mode_param do
  				"new" ->
  					:new
  				"hot" ->
  					:vote
  				_ ->
  					:vote
  			end
  		_ ->
  			:vote
  	end

    posts = SmileysData.QueryPost.summary(limit, order_by, room.id, %{page: offset, room: room_name}, false) 

    {:ok, posts}
  end

  def get_from_all(_params, _info) do
	  posts = SmileysData.QueryPost.summary(30, :vote, :nil, %{}, false)

    {:ok, posts}
  end

  def one(%{hash: hash}, _info) do
  	case SmileysData.QueryPost.post_by_hash(hash) do
  		nil  -> {:error, "Post by hash #{hash} not found"}
    	post -> {:ok, post}
  	end
  end
end