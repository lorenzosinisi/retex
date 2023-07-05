defmodule Serializer do
  @moduledoc """
  This serializer converts a `Graph` to a [Mermaid Flowchart](https://mermaid.js.org/syntax/flowchart.html).
  """

  use Graph.Serializer
  import Graph.Serializer

  @impl Graph.Serializer
  def serialize(%Graph{} = g) do
    result = """
    flowchart
    #{serialize_vertices(g)}
    #{serialize_edges(g)}
    """

    {:ok, result}
  end

  def vertex_labels(%Graph{vertex_labels: vl}, id, v) do
    case Map.get(vl, id) do
      [] -> encode(v)
      label -> encode(label)
    end
  end

  defp serialize_vertices(g) do
    Enum.map_join(g.vertices, "\n", fn {id, value} ->
      indent(1) <> "#{id}" <> "[" <> vertex_labels(g, id, value) <> "]"
    end)
  end

  defp serialize_edges(g) do
    arrow =
      case g.type do
        :directed -> "->"
        :undirected -> "-"
      end

    g.vertices
    |> Enum.reduce([], fn {id, _}, acc ->
      g.out_edges
      |> Map.get_lazy(id, &MapSet.new/0)
      |> Enum.flat_map(fn out_edge_id ->
        g.edges
        |> Map.fetch!({id, out_edge_id})
        |> Enum.map(fn
          {nil, weight} -> {id, out_edge_id, weight}
          {label, weight} -> {id, out_edge_id, weight, encode(label)}
        end)
      end)
      |> case do
        [] -> acc
        edges -> acc ++ edges
      end
    end)
    |> Enum.map_join("\n", &serialize_edge(&1, arrow))
  end

  defp encode(%{class: name}) when is_list(name) do
    Enum.join(name)
  end

  defp encode(%{class: name}) do
    to_string(name)
  end

  defp encode(%Retex.Node.BetaMemory{}) do
    "Join"
  end

  defp encode(%Retex.Node.PNode{id: id}) do
    "Rule##{id}"
  end

  defp serialize_edge({id, out_edge_id, weight, label}, arrow) do
    indent(1) <> "#{id} " <> weight_arrow(arrow, weight) <> " |#{label}| " <> "#{out_edge_id}"
  end

  defp serialize_edge({id, out_edge_id, weight}, arrow) do
    indent(1) <> "#{id} " <> weight_arrow(arrow, weight) <> " #{out_edge_id}"
  end

  defp weight_arrow(arrow, weight) do
    String.duplicate("-", weight) <> arrow
  end
end
