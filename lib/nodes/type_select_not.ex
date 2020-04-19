defmodule Retex.Node.SelectNot do
  @moduledoc """
  The select nodes are checking for attributes, if they do NOT exists and are linked to the
  right owner from above, they will be activated and pass the tokens down
  """
  defstruct type: :NodeSelectNot, class: nil, id: nil, bindings: %{}, parent: nil
  @type t() :: %Retex.Node.SelectNot{}

  def new(parent, class, labels \\ []) do
    item = %__MODULE__{class: class, parent: parent}
    {%{item | id: Retex.hash(item)}, labels}
  end

  defimpl Retex.Protocol.Activation do
    def activate(
          %Retex.Node.SelectNot{class: attribute} = neighbor,
          %Retex{} = rete,
          %Retex.Wme{attribute: attribute} = wme,
          bindings,
          tokens
        ) do
      rete
      |> Retex.create_activation(neighbor, wme)
      |> Retex.add_token(neighbor, wme, bindings, tokens)
      |> Retex.deactivate_descendants(neighbor)
      |> Retex.stop_traversal(%{})
    end

    def activate(
          %Retex.Node.SelectNot{class: _class} = _neighbor,
          %Retex{} = rete,
          %Retex.Wme{attribute: _attribute},
          bindings,
          _tokens
        ) do
      Retex.stop_traversal(rete, bindings)
    end

    @spec active?(%{id: any}, Retex.t()) :: boolean()
    def active?(%{id: id}, %Retex{activations: activations}) do
      Enum.empty?(Map.get(activations, id, []))
    end
  end
end
