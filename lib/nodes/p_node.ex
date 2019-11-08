defmodule Retex.Node.PNode do
  @moduledoc """
  Production node. This is like a production node in Rete algorithm. It is activated if all
  the conditions in a rule are matching and contains the action that can be executed as consequence.
  """
  defstruct type: :PNode, action: nil, id: nil

  def new(action, labels \\ []) do
    item = %__MODULE__{action: action}
    {%{item | id: Retex.hash(item)}, labels}
  end

  defimpl Retex.Protocol.Activation do
    def activate(
          neighbor,
          %Retex{tokens: tokens, graph: graph, activations: activations} = rete,
          _wme,
          bindings,
          _tokens
        ) do
      parents = Graph.in_neighbors(graph, neighbor)
      parent = List.first(parents)
      tokens = Map.get(tokens, parent.id)

      with true <- Enum.all?(parents, &Map.get(activations, &1.id)) do
        actions =
          for token <- tokens do
            if is_tuple(token) do
              Retex.replace_bindings(neighbor, token) |> Map.get(:action)
            else
              Retex.replace_bindings(neighbor, token.bindings) |> Map.get(:action)
            end
          end
          |> List.flatten()
          |> Enum.uniq()

        new_rete = %{
          rete
          | agenda: [actions | rete.agenda] |> List.flatten()
        }

        Retex.stop_traversal(new_rete, bindings)
      else
        _ -> Retex.stop_traversal(rete, bindings)
      end
    end
  end
end
