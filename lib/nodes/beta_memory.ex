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
      left? = Map.get(activations, neighbor.left.id)
      right? = left? && Map.get(activations, neighbor.right.id)
      left_vars = left? && Retex.get_current_bindings(neighbor.left, bindings)
      right_vars = right? && Retex.get_current_bindings(neighbor.right, bindings)
      current_bindings = right? && Retex.get_current_bindings(neighbor, bindings)
      already_active? = left? && right? && Map.get(activations, neighbor.id)

      matching =
        left? && right? &&
          Enum.reduce_while(left_vars, true, fn {key, value}, true ->
            if Map.get(right_vars, key, value) == value, do: {:cont, true}, else: {:halt, false}
          end) &&
          Enum.reduce_while(right_vars, true, fn {key, value}, true ->
            if Map.get(left_vars, key, value) == value, do: {:cont, true}, else: {:halt, false}
          end)

      cond do
        matching && !already_active? ->
          inherited_vars = Map.merge(left_vars, right_vars)

          new_bindings =
            Retex.update_bindings(current_bindings, bindings, neighbor, inherited_vars)

          rete
          |> Retex.create_activation(neighbor, wme)
          |> Retex.continue_traversal(new_bindings, neighbor, wme)

        matching && already_active? ->
          inherited_vars = Map.merge(left_vars, right_vars)

          new_bindings =
            Retex.update_bindings(current_bindings, bindings, neighbor, inherited_vars)

          rete |> Retex.stop_traversal(new_bindings)

        true ->
          Retex.stop_traversal(rete, bindings)
      end
    end
  end
end
