defmodule Retex.Fact.Isa do
  @moduledoc "A type of thing that needs to exists in order for a Wme to activate part of a condition"
  defstruct type: nil, variable: nil

  @type type :: String.t() | atom()
  @type variable :: String.t()
  @type fields :: [type: type(), variable: variable()]
  @type t :: %__MODULE__{type: type(), variable: variable()}

  @spec new(fields()) :: t()
  def new(fields) do
    struct(__MODULE__, fields)
  end

  defimpl Retex.Protocol.AlphaNetwork do
    alias Retex.Fact.Isa

    def append(%Isa{} = condition, {graph, test_nodes}) do
      %{variable: _, type: type} = condition
      {type_node, _} = Retex.Node.Type.new(type)

      new_graph =
        graph
        |> Graph.add_vertex(type_node)
        |> Graph.add_edge(Retex.root_vertex(), type_node)

      {new_graph, [type_node | test_nodes]}
    end
  end

  defimpl Inspect do
    def inspect(vertex, _opts) do
      "Isa($#{vertex.variable}, #{vertex.type})"
    end
  end
end
