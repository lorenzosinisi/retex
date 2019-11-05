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

        rete
        |> Retex.create_activation(neighbor, wme)
        |> Retex.continue_traversal(new_bindings, neighbor, wme)
      else
        rete |> Retex.stop_traversal(bindings)
      end
    end

    def activate(
          %Retex.Node.Test{class: [operator, value]} = neighbor,
          %Retex{activations: _activations} = rete,
          wme,
          bindings
        ) do
      if apply(Kernel, operator, [value, wme.value]) do
        rete
        |> Retex.create_activation(neighbor, wme)
        |> Retex.continue_traversal(bindings, neighbor, wme)
      else
        rete |> Retex.stop_traversal(bindings)
      end
    end
  end
end
