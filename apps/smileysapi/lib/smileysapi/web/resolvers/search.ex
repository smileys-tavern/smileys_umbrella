defmodule Smileysapi.Resolver.Search do

  alias SmileysData.Query.Post.Summary, as: QueryPostSummary
  

  def get_posts(params, _info) do
    {search_results, amount} = case SmileysSearch.QueryPost.posts_by_map(params) do
      {:ok, results, amount_results} ->
        {results, amount_results}
      {:error, _} ->
        {[], 0}
    end

    posts = QueryPostSummary.by_ids(search_results)

    {:ok, %{s: params.s, matches: posts, amount_results: amount}}
  end

end