defmodule Retex.Discovery do
  @moduledoc """
  Checks which production nodes have been almost activated from the ones
  with the most activated paths pointing to them, sorted by weak activations.
  """

  defstruct weak_activations: []
  alias Retex.Node.PNode

  def weak_activations(%Retex{graph: graph}) do
    %__MODULE__{weak_activations: []}
  end

  defp calculate_weak_activations(%Retex{graph: graph}) do
    # extract all production nodes
    # get their nearest neighbor
    # calculate the active paths between the root node and the closest neighbors
  end

  defp extract_pnodes(%Retex{graph: graph}) do
  end
end
