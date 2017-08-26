defmodule Smileysapi.Resolver.Graph do

  alias SmileysData.Protocols.GraphOp

  def insert(%{v: v}, _info) do
  	result = case SmileysData.QueryGraph.insert_vertex(GraphOp.to_vertex(v)) do
      {:ok, id} ->
        %{id: id}
      _ ->
        %{error: "error"}
    end

    {:ok, result}
  end

  def insert(%{e: e}, _info) do
    result = case SmileysData.QueryGraph.insert_edge(GraphOp.to_edge(e)) do
      {:ok, id} ->
        %{id: id}
      _ ->
        %{error: "error"}
    end

    {:ok, result}
  end

  def select(%{v: v}, _info) do
    result = case SmileysData.QueryGraph.get_vertices(GraphOp.to_vertex(v)) do
      {:ok, result} ->
        # TODO: enum these up and return properly
        %{v: result}
      {:error, error} ->
        %{error: error}
    end

    {:ok, result}
  end

  def select(%{e: e}, _info) do
    result = case SmileysData.QueryGraph.get_vertices(GraphOp.to_edge(e)) do
      {:ok, id} ->
        %{id: id}
      _ ->
        %{error: "error"}
    end

    {:ok, result}
  end
end