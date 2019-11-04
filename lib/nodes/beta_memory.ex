defmodule Retex.Node.BetaMemory do
  @moduledoc """
  A BetaMemory works like a two input node in Rete. It is simply a join node
  between two tests that have passed successfully. The activation of a BetaMemory
  happens if the two parents (left and right) have been activated and the bindings
  are matching for both of them.
  """
  defstruct type: :BetaMemory, left: nil, right: nil, id: nil, bindings: %{}

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
      require Logger
      left? = Map.get(activations, neighbor.left.id)
      right? = Map.get(activations, neighbor.right.id)

      if left? && right? do
        Logger.warn("is activated")
        new_rete = rete |> Retex.create_activation(neighbor, wme)
        {:next, {new_rete, bindings}}
      else
        Logger.warn("is not activated")
        {:next, {rete, bindings}}
      end
    end
  end
end
