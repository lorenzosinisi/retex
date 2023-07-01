defmodule Retex.Fact.HasAttribute do
  @moduledoc "Attribute values that a Wme should have in order for this condition to be true"

  defstruct owner: nil, attribute: nil, predicate: nil, value: nil

  @type owner :: String.t() | atom()
  @type attribute :: String.t() | atom()
  @type predicate :: :== | :=== | :!== | :!= | :> | :< | :<= | :>= | :in
  @type value :: any()
  @type fields :: [owner: owner(), attribute: attribute(), predicate: predicate(), value: value()]

  @type t :: %Retex.Fact.HasAttribute{
          owner: owner(),
          attribute: attribute(),
          predicate: predicate(),
          value: value()
        }
  @spec new(fields()) :: t()
  def new(fields) do
    struct(__MODULE__, fields)
  end

  defimpl Retex.Protocol.AlphaNetwork do
    alias Retex.{Fact.HasAttribute, Node}

    def append(%HasAttribute{} = condition, {graph, test_nodes}) do
      %{attribute: attribute, owner: class, predicate: predicate, value: value} = condition
      condition_id = Retex.hash(condition)
      type_node = Node.Type.new(class)
      select_node = Node.Select.new(class, attribute)
      test_node = Node.Test.new([predicate, value], condition_id)

      new_graph =
        graph
        |> Graph.add_vertex(type_node)
        |> Graph.add_edge(Retex.root_vertex(), type_node)
        |> Graph.add_vertex(select_node)
        |> Graph.add_edge(type_node, select_node)
        |> Graph.add_vertex(test_node)
        |> Graph.add_edge(select_node, test_node)

      {new_graph, [test_node | test_nodes]}
    end
  end
end
