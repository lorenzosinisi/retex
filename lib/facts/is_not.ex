defmodule Retex.Fact.IsNot do
  @moduledoc "A type of thing that needs to not exists in order for a Wme to activate part of a condition"
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
    alias Retex.Fact.IsNot
    alias Retex.Node.NegativeType

    def append(%IsNot{} = condition, {graph, test_nodes}) do
      %{variable: _, type: type} = condition
      type_node = NegativeType.new(type)

      new_graph =
        graph
        |> Graph.add_vertex(type_node)
        |> Graph.add_edge(Retex.root_vertex(), type_node)

      {new_graph, [type_node | test_nodes]}
    end
  end

  defimpl Inspect do
    def inspect(vertex, _opts) do
      "IsNot(#{vertex.variable}, #{vertex.type}, "
    end
  end
end
