defmodule Retex.Node.PNode do
  @moduledoc """
  Production node. This is like a production node in Rete algorithm. It is activated if all
  the conditions in a rule are matching and contains the action that can be executed as consequence.
  """
  defstruct action: nil, id: nil, raw_action: nil, bindings: %{}, filters: []

  def new(action, filters \\ []) do
    item = %__MODULE__{action: action, raw_action: action, filters: filters}
    %{item | id: Retex.hash(item)}
  end

  defimpl Retex.Protocol.Activation do
    def activate(
          neighbor = %{filters: filters},
          %Retex{tokens: tokens, graph: graph, activations: activations} = rete,
          _wme,
          _bindings,
          _tokens
        ) do
      # A production node has only one parent, right?
      [parent | _] =
        parents =
        Graph.in_neighbors(graph, neighbor)
        |> Enum.filter(fn node ->
          Map.get(activations, node.id)
        end)

      tokens = Map.get(tokens, parent.id)

      if Enum.all?(parents, &Map.get(activations, &1.id)) do
        productions =
          for token <- tokens do
            if is_tuple(token) do
              Retex.replace_bindings(neighbor, token)
            else
              Retex.replace_bindings(neighbor, token.bindings)
            end
          end
          |> List.flatten()
          |> Enum.uniq()
          |> apply_filters(filters)

        new_rete = %{
          rete
          | agenda: ([productions] ++ rete.agenda) |> List.flatten() |> Enum.uniq()
        }

        Retex.stop_traversal(new_rete, %{})
      else
        Retex.stop_traversal(rete, %{})
      end
    end

    def active?(_, _) do
      raise "Not implemented"
    end

    def apply_filters(nodes, filters) do
      Enum.filter(nodes, fn node ->
        Enum.reduce_while(filters, true, fn filter, _ ->
          if test_pass?(node, filter), do: {:cont, true}, else: {:halt, false}
        end)
      end)
    end

    def test_pass?(%Retex.Node.PNode{bindings: bindings}, %Retex.Fact.Filter{
          predicate: predicate,
          value: value,
          variable: variable
        }) do
      case Map.get(bindings, variable, :_undefined) do
        :_undefined -> true
        current_value -> apply(Kernel, predicate, [current_value, value])
      end
    end
  end

  defimpl Inspect do
    def inspect(node, _opts) do
      "PNode(#{inspect(node.action)})"
    end
  end
end
