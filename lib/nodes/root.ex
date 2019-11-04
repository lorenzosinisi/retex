defmodule Retex.Root do
  @moduledoc """
  The root node is the root vertex of the network.
  From the root node start all the edges that connect with each TypeNode,
  the discrimination network starts from here.
  """
  defstruct class: :Root, id: :root

  def new(), do: %__MODULE__{}

  defimpl Retex.Protocol.Activation do
    def activate(
          %Retex.Root{} = neighbor,
          %Retex{graph: _graph} = rete,
          %Retex.Wme{attribute: _attribute} = _wme,
          bindings
        ) do
      {:next, {rete, bindings}}
    end
  end
end
