defmodule Retex.Node.Select do
  @moduledoc """
  The select nodes are checking for attributes, if they exists and are linked to the
  right owner from above, they will be activated and pass the tokens down in the test
  nodes (that will check for their value instead).
  """
  defstruct type: :NodeSelect, class: nil, id: nil, bindings: %{}, parent: nil

  def new(parent, class, labels \\ []) do
    item = %__MODULE__{class: class, parent: parent}
    {%{item | id: Retex.hash(item)}, labels}
  end

  defimpl Retex.Protocol.Activation do
    def activate(
          %Retex.Node.Select{class: "$" <> variable = var, id: id} = neighbor,
          %Retex{graph: graph} = rete,
          %Retex.Wme{attribute: attribute} = wme,
          bindings,
          tokens
        ) do
      key = var
      value = attribute
      current_bindings = Retex.get_current_bindings(neighbor, bindings)
      new_bindings = Retex.update_bindings(current_bindings, bindings, neighbor, key, value)

      rete
      |> Retex.create_activation(neighbor, wme)
      |> Retex.add_token(neighbor, wme, new_bindings, tokens)
      |> Retex.continue_traversal(new_bindings, neighbor, wme)
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
  end
end
