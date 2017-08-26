defmodule Smileysapi.Schema do
  use Absinthe.Schema

  import_types Smileysapi.Schema.Types

  alias Smileysapi.{Resolver}

  query do
  	@desc "Get a list of posts from a room where the name of the room is required"
    field :posts, list_of(:post) do
      arg :room, non_null(:string)
      arg :mode, :string
      arg :limit, :integer
      arg :offset, :integer
      resolve &Resolver.Post.get/2
    end

    @desc "Get a single post by it's identifying hash string"
  	field :post, type: :post do
  		arg :hash, non_null(:string)
  		resolve &Resolver.Post.one/2
  	end

  	@desc "Get a user by their name"
  	field :user, type: :user do
  		arg :name, non_null(:string)
  		resolve &Resolver.User.one/2
  	end

  	@desc "Search for a post by any search string"
  	field :search_posts, type: :search_for do
  		arg :s, non_null(:string)
  		arg :limit, :integer
  		arg :offset, :integer
  		arg :filter_include, list_of(:sphinx_filter)
  		arg :filter_exclude, list_of(:sphinx_filter)
  		arg :field_weights, list_of(:sphinx_field)
  		resolve &Resolver.Search.get_posts/2
  	end

    @desc "Add a graph vertex to smileys graph on behalf of the current user"
    field :graph_insert, type: :graph_result do
      arg :v, :vertex
      arg :e, :edge
      resolve &Resolver.Graph.insert/2
    end

    @desc "Select a graph vertex or set of vertices"
    field :graph_select, type: :graph_result_select do
      arg :v, :vertex
      arg :e, :edge
      resolve &Resolver.Graph.select/2
    end
  end
end