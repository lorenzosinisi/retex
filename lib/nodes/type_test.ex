defmodule Retex.Node.Test do
  @moduledoc """
  Test node.

  If we reached that node, means that we are checking that a value is matching
  a specific condition. If this is the case, we activate this node and pass the token down
  to the beta network.
  """
  defstruct type: :NodeTest, class: nil, id: nil, bindings: %{}

  def new(class, id, labels \\ []), do: {%__MODULE__{class: class, id: id}, labels}

  defimpl Retex.Protocol.Activation do
    def activate(
          %Retex.Node.Test{class: [_operator, "$" <> _variable = var]} = neighbor,
          %Retex{activations: _activations} = rete,
          %{value: value} = wme,
          bindings
        ) do
      key = var
      current_bindings = Retex.get_current_bindings(neighbor, bindings)
      previous_match = Retex.previous_match(current_bindings, key, value)

      if previous_match === value do
        new_bindings = Retex.update_bindings(current_bindings, bindings, neighbor, key, value)

        new_rete =
          rete
          |> Retex.create_activation(neighbor, wme)

        {:next, {new_rete, new_bindings}}
      else
        {:skip, {rete, bindings}}
      end
    end

    def activate(
          %Retex.Node.Test{class: [operator, value]} = neighbor,
          %Retex{activations: _activations} = rete,
          wme,
          bindings
        ) do
      if apply(Kernel, operator, [value, wme.value]) do
        new_rete =
          rete
          |> Retex.create_activation(neighbor, wme)

        {:next, {new_rete, bindings}}
      else
        {:skip, {rete, bindings}}
      end
    end
  end
end
