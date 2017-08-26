defmodule Smileysapi.Schema.Types do
  use Absinthe.Schema.Notation

  alias SmileysData.{User, PostMeta}

  @desc """
  A post on Smileys
  """
  object :post do
  	field :title, :string
  	field :poster, :user do
	    resolve fn post, _, _ ->
	      batch({Smileysapi.Schema.Helpers, :by_id, User}, post.posterid, fn batch_results ->
	        {:ok, Map.get(batch_results, post.posterid)}
	      end)
	    end
	end
  	field :body, :string
  	field :age, :integer
  	field :hash, :string
  	field :votepublic, :integer
  	field :ophash, :string
  	field :meta, :post_meta do
	    resolve fn post, _, _ ->
	      batch({Smileysapi.Schema.Helpers, :by_postid, PostMeta}, post.id, fn batch_results ->
	        {:ok, Map.get(batch_results, post.id)}
	      end)
	    end
	end
  end

  @desc """
  A post on Smileys with only a few required fields
  """
  object :post_summary do
  	field :title, :string
  	field :poster, :user do
	    resolve fn post, _, _ ->
	      batch({Smileysapi.Schema.Helpers, :by_id, User}, post.posterid, fn batch_results ->
	        {:ok, Map.get(batch_results, post.posterid)}
	      end)
	    end
	  end
  	field :age, :integer
  	field :hash, :string
    field :tags, :string
    field :link, :string
    field :parenttype, :string
    field :thumb, :string
  	field :votepublic, :integer
  	field :ophash, :string
  	field :meta, :post_meta do
	    resolve fn post, _, _ ->
	      batch({Smileysapi.Schema.Helpers, :by_postid, PostMeta}, post.id, fn batch_results ->
	        {:ok, Map.get(batch_results, post.id)}
	      end)
	    end
	  end
  end

  @desc """
  A posts attached data such as tags and links
  """
  object :post_meta do
    field :link, :string
    field :image, :string
    field :thumb, :string
    field :tags, :string
  end

  @desc """
  A Smileys user
  """
  object :user do
  	field :name, :string
    field :drinks, :integer
    field :inserted_at, :string
  end

  @desc """
  A Smileys room
  """
  object :room do
    field :name, :string
    field :creator, :user
    field :title, :string
    field :description, :string
    field :type, :string
    field :age, :integer
  end

  @desc """
  A post search that searches user, post and room data for postings
  """
  object :search_post_results do
  	field :s, :string
  	field :matches, list_of(:post)
  	field :amount_results, :integer
  	field :amount_matches, :integer
  end

  
  @desc """
  A user search that focuses on post data to find the user
  """
  object :search_user_results do
    field :s, :string
  	field :matches, list_of(:user)
  	field :amount_results, :integer
  	field :amount_matches, :integer
  end

  @desc """
  A search object representing what can be searched for
  """
  object :search_for do
  	field :s, :string
  	field :matches, list_of(:post_summary)
  	field :amount_results, :integer
  	field :limit, :integer
  	field :offset, :integer
  end

  @desc """
  Valid filter fields for smileys search queries
  """
  input_object :sphinx_filter do
  	field :age, list_of(:integer)
  	field :age_range, :range
  	field :votepublic, list_of(:integer)
  	field :votepublic_range, :range
  end

  @desc """
  Valid fields for smileys sphinx queries
  """
  input_object :sphinx_field do
  	field :body, :integer
  	field :title, :integer
  end

  @desc """
  An object representing a range of integers min/max
  """
  object :range do
  	field :min, :integer
  	field :max, :integer
  end

  # Graph
  @desc """
  The result of a graph operation
  """
  object :graph_result do
    field :id, :string
    field :ids, list_of(:string)
    field :error, :string
  end

  @desc """
  The result of a graph operation return a vertex or list of vertices
  """
  object :graph_result_select do
    field :v, list_of(:vertex_output)
    field :e, list_of(:edge_output)
    field :error, :string
  end

  @desc """
  A graph vertex which can be connected to other vertices via edges
  """
  input_object :vertex do
    field :id, :string
    field :class, :string
    field :meta, list_of(:graph_meta)
  end

  object :vertex_output do
    field :id, :string
    field :class, :string
    field :meta, list_of(:graph_meta_output)
  end

  @desc """
  A graph edge that can connect vertices
  """
  input_object :edge do
    field :id, :string
    field :class, :string
    field :meta, list_of(:graph_meta)
    field :v1, :vertex
    field :v2, :vertex
  end

  object :edge_output do
    field :id, :string
    field :class, :string
    field :meta, list_of(:graph_meta_output)
    field :v1, :vertex_output
    field :v2, :vertex_output
  end

  @desc """
  A meta value that can be attacked to an edge or vertex. Multiple meta are usually allowed per 
  graph entity
  """
  input_object :graph_meta do
    field :name, :string
    field :value, :string
  end

  object :graph_meta_output do
    field :name, :string
    field :value, :string
  end

  # End Graph

  scalar :time, description: "ISOz time" do
    description "ISOz time",
    parse &Timex.parse(&1, "{ISOz}")
    serialize &Timex.format!(&1, "{ISOz}")
  end
end
