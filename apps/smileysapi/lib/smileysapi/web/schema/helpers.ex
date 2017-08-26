defmodule Smileysapi.Schema.Helpers do
  
  alias SmileysData.{Repo}

  def by_id(model, ids) do
    import Ecto.Query
    model
	  |> where([m], m.id in ^ids)
	  |> Repo.all
	  |> Map.new(&{&1.id, &1})
  end

  def by_postid(model, ids) do
  	import Ecto.Query
  	model
  	  |> where([m], m.postid in ^ids)
  	  |> Repo.all
  	  |> Map.new(&{&1.postid, &1})
  end
end