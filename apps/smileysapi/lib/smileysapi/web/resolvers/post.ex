defmodule Smileysapi.Resolver.Post do

  alias SmileysData.Query.Post.Summary, as: QueryPostSummary
  alias SmileysData.Query.Post, as: QueryPost
  alias SmileysData.Query.Room, as: QueryRoom

  def get(%{room: room_name} = params, _info) do
  	room = QueryRoom.by_name(room_name)

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


    {posts, _kerosene} = case room do
      nil ->
        []
      _ ->
        QueryPostSummary.get(limit, order_by, room.id, %{page: offset, room: room_name}, false) 
    end

    {:ok, posts}
  end

  def get_from_all(_params, _info) do
	  posts = QueryPostSummary.get(30, :vote, :nil, %{}, false)

    {:ok, posts}
  end

  def one(%{hash: hash}, _info) do
  	case QueryPost.by_hash(hash) do
  		nil  -> {:error, "Post by hash #{hash} not found"}
    	post -> {:ok, post}
  	end
  end
end