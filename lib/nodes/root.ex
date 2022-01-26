defmodule Retex.Root do
  @moduledoc """
  The root node is the root vertex of the network.
  From the root node start all the edges that connect with each TypeNode,
  the discrimination network starts from here.
  """
  defstruct class: :Root, id: :root

  @type t :: %Retex.Root{}

  def new, do: %__MODULE__{}

  defimpl Retex.Protocol.Activation do
    def activate(
          %Retex.Root{} = neighbor,
          %Retex{graph: _graph} = rete,
          %Retex.Wme{attribute: _attribute} = wme,
          bindings,
          _tokens
        ) do
      Retex.continue_traversal(rete, bindings, neighbor, wme)
    end

    def active?(_node, _rete), do: true
  end

  defimpl Inspect do
    def inspect(_node, _opts) do
      "Root()"
    end
  end
end
