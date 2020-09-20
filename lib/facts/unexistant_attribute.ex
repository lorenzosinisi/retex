defmodule Retex.Fact.UnexistantAttribute do
  @moduledoc "Attribute values that a Wme should NOT have in order for this condition to be true"

  defstruct owner: nil, attribute: nil

  @type owner :: String.t() | atom()
  @type attribute :: String.t() | atom()
  @type fields :: [owner: owner(), attribute: attribute()]

  @type t :: %Retex.Fact.UnexistantAttribute{
          owner: owner(),
          attribute: attribute()
        }
  @spec new(fields()) :: t()
  def new(fields) do
    struct(__MODULE__, fields)
  end

  defimpl Retex.Protocol.AlphaNetwork do
    alias Retex.{Fact, Node}

    def append(%Fact.UnexistantAttribute{} = condition, {graph, nodes}) do
      %{attribute: attribute, owner: class} = condition
      type_node = Node.Type.new(class)
      negative_select_node = Node.SelectNot.new(class, attribute)

      new_graph =
        graph
        |> Graph.add_vertex(type_node)
        |> Graph.add_edge(Retex.root_vertex(), type_node)
        |> Graph.add_vertex(negative_select_node)
        |> Graph.add_edge(type_node, negative_select_node)

      {new_graph, [negative_select_node | nodes]}
    end
  end

  defimpl Inspect do
    def inspect(vertex, _opts) do
      "UnexistantAttribute(#{vertex.owner}, #{vertex.attribute})"
    end
  end
end
