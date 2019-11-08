defmodule Retex.Node.Type do
  @moduledoc """
  The NodeType if part of the alpha network, the discrimination part of the network
  that check if a specific class exists. If this is the case, it propagates the activations
  down to the select node types. They will select an attribute and check for its existance.
  """
  defstruct type: :NodeType, class: nil, id: nil, bindings: %{}

  def new(class, labels \\ []) do
    item = %__MODULE__{class: class}
    {%{item | id: Retex.hash(item)}, labels}
  end

  defimpl Retex.Protocol.Activation do
    def activate(
          %Retex.Node.Type{class: "$" <> _variable = var} = neighbor,
          %Retex{graph: _graph} = rete,
          %Retex.Wme{identifier: identifier} = wme,
          bindings,
          tokens
        ) do
      key = var
      value = identifier
      current_bindings = Retex.get_current_bindings(neighbor, bindings)
      new_bindings = Retex.update_bindings(current_bindings, bindings, neighbor, key, value)

      rete
      |> Retex.create_activation(neighbor, wme)
      |> Retex.add_token(neighbor, wme, new_bindings, tokens)
      |> Retex.continue_traversal(new_bindings, neighbor, wme)
    end

    def activate(
          %Retex.Node.Type{class: identifier} = neighbor,
          %Retex{graph: graph} = rete,
          %Retex.Wme{identifier: identifier} = wme,
          bindings,
          tokens
        ) do
      rete
      |> Retex.create_activation(neighbor, wme)
      |> Retex.add_token(neighbor, wme, bindings, tokens)
      |> Retex.continue_traversal(bindings, neighbor, wme)
    end

    def activate(
          %Retex.Node.Type{class: _class},
          %Retex{graph: _graph} = rete,
          %Retex.Wme{identifier: _identifier} = _wme,
          bindings,
          tokens
        ) do
      Retex.stop_traversal(rete, bindings)
    end
  end
end
