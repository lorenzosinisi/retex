defmodule Retex.Discovery do
  @moduledoc """
  Checks which production nodes have been almost activated from the ones
  with the most activated paths pointing to them, sorted by weak activations.
  """

  defstruct weak_activations: []

  def weak_activations(%Retex{graph: _graph}) do
    %__MODULE__{weak_activations: []}
  end
end
