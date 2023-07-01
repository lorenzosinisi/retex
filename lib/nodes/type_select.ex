defmodule Retex.Node.Select do
  @moduledoc """
  The select nodes are checking for attributes, if they exists and are linked to the
  right owner from above, they will be activated and pass the tokens down in the test
  nodes (that will check for their value instead).
  """
  defstruct class: nil, id: nil, parent: nil
  @type t() :: %Retex.Node.Select{}

  def new(parent, class) do
    item = %__MODULE__{class: class, parent: parent}
    %{item | id: Retex.hash(item)}
  end

  defimpl Retex.Protocol.Activation do
    def activate(
          %Retex.Node.Select{class: "$" <> _variable = var} = neighbor,
          %Retex{} = rete,
          %Retex.Wme{attribute: attribute} = wme,
          bindings,
          tokens
        ) do
      rete
      |> Retex.create_activation(neighbor, wme)
      |> Retex.add_token(neighbor, wme, Map.merge(bindings, %{var => attribute}), tokens)
      |> Retex.continue_traversal(Map.merge(bindings, %{var => attribute}), neighbor, wme)
    end

    def activate(
          %Retex.Node.Select{class: attribute} = neighbor,
          %Retex{} = rete,
          %Retex.Wme{attribute: attribute} = wme,
          bindings,
          tokens
        ) do
      rete
      |> Retex.create_activation(neighbor, wme)
      |> Retex.add_token(neighbor, wme, bindings, tokens)
      |> Retex.continue_traversal(bindings, neighbor, wme)
    end

    def activate(
          %Retex.Node.Select{class: _class} = _neighbor,
          %Retex{} = rete,
          %Retex.Wme{attribute: _attribute},
          bindings,
          _tokens
        ) do
      Retex.stop_traversal(rete, bindings)
    end

    @spec active?(%{id: any}, Retex.t()) :: boolean()
    def active?(%{id: id}, %Retex{activations: activations}) do
      Enum.any?(Map.get(activations, id, []))
    end
  end
end
