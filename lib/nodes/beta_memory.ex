defmodule Retex.Node.BetaMemory do
  @moduledoc """
  A BetaMemory works like a two input node in Rete. It is simply a join node
  between two tests that have passed successfully. The activation of a BetaMemory
  happens if the two parents (left and right) have been activated and the bindings
  are matching for both of them.
  """
  defstruct type: :BetaMemory, left: nil, right: nil, id: nil, bindings: %{}

  require Logger

  def new(left, right, labels \\ []) do
    item = %__MODULE__{left: left, right: right}
    {%{item | id: Retex.hash(item)}, labels}
  end

  defimpl Retex.Protocol.Activation do
    def activate(
          %Retex.Node.BetaMemory{bindings: previous_bindings} = neighbor,
          %Retex{graph: graph, activations: activations} = rete,
          wme,
          bindings
        ) do
      with [_ | _] <- Map.get(activations, neighbor.left.id),
           [_ | _] <- Map.get(activations, neighbor.right.id),
           left_vars <- Retex.get_current_bindings(neighbor.left, bindings),
           right_vars <- Retex.get_current_bindings(neighbor.right, bindings),
           true <- variables_match(left_vars, right_vars) do
        current_bindings = Retex.get_current_bindings(neighbor, bindings)
        already_active? = Map.get(activations, neighbor.id)
        inherited_vars = Map.merge(left_vars, right_vars)
        new_bindings = Retex.update_bindings(current_bindings, bindings, neighbor, inherited_vars)

        if already_active? do
          rete |> Retex.stop_traversal(new_bindings)
        else
          rete
          |> Retex.create_activation(neighbor, wme)
          |> Retex.continue_traversal(new_bindings, neighbor, wme)
        end
      else
        _ ->
          Retex.stop_traversal(rete, bindings)
      end
    end

    defp variables_match(left, right) do
      Enum.reduce_while(left, true, fn {key, value}, true ->
        if Map.get(right, key, value) == value, do: {:cont, true}, else: {:halt, false}
      end) &&
        Enum.reduce_while(right, true, fn {key, value}, true ->
          if Map.get(left, key, value) == value, do: {:cont, true}, else: {:halt, false}
        end)
    end
  end
end
