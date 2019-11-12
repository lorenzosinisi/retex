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
          _bindings,
          _tokens
        ) do
      # A production node has only one parent
      [parent] = parents = Graph.in_neighbors(graph, neighbor)
      tokens = Map.get(tokens, parent.id)

      with true <- Enum.all?(parents, &Map.get(activations, &1.id)) do
        actions =
          for token <- tokens do
            if is_tuple(token) do
              Retex.replace_bindings(neighbor, token)
            else
              Retex.replace_bindings(neighbor, token.bindings)
            end
          end
          |> List.flatten()
          |> Enum.uniq()
          |> Enum.map(fn node -> node.action end)

        new_rete = %{
          rete
          | agenda: ([actions] ++ rete.agenda) |> List.flatten() |> Enum.uniq()
        }

        Retex.stop_traversal(new_rete, %{})
      else
        _ -> Retex.stop_traversal(rete, %{})
      end
    end
  end
end
