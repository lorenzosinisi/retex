defmodule Retex.Node.Test do
  @moduledoc """
  Test node.

  If we reached that node, means that we are checking that a value is matching
  a specific condition. If this is the case, we activate this node and pass the token down
  to the beta network.
  """
  defstruct class: nil, id: nil
  @type t :: %Retex.Node.Test{}

  def new(class, id), do: %__MODULE__{class: class, id: id}

  defimpl Retex.Protocol.Activation do
    def activate(
          %Retex.Node.Test{class: [_operator, "$" <> _variable = var]} = neighbor,
          %Retex{activations: _activations} = rete,
          %{value: value} = wme,
          bindings,
          tokens
        ) do
      rete
      |> Retex.create_activation(neighbor, wme)
      |> Retex.add_token(neighbor, wme, Map.merge(bindings, %{var => value}), tokens)
      |> Retex.continue_traversal(Map.merge(bindings, %{var => value}), neighbor, wme)
    end

    def activate(
          %Retex.Node.Test{class: [:in, value]} = neighbor,
          %Retex{activations: _activations} = rete,
          wme,
          bindings,
          tokens
        ) do
      if apply(Enum, :member?, [value, wme.value]) do
        rete
        |> Retex.create_activation(neighbor, wme)
        |> Retex.add_token(neighbor, wme, bindings, tokens)
        |> Retex.continue_traversal(bindings, neighbor, wme)
      else
        Retex.stop_traversal(rete, %{})
      end
    end

    def activate(
          %Retex.Node.Test{class: [operator, value]} = neighbor,
          %Retex{activations: _activations} = rete,
          wme,
          bindings,
          tokens
        ) do
      if apply(Kernel, operator, [wme.value, value]) do
        rete
        |> Retex.create_activation(neighbor, wme)
        |> Retex.add_token(neighbor, wme, bindings, tokens)
        |> Retex.continue_traversal(bindings, neighbor, wme)
      else
        Retex.stop_traversal(rete, %{})
      end
    end

    @spec active?(%{id: any}, Retex.t()) :: boolean()
    def active?(%{id: id}, %Retex{activations: activations}) do
      Enum.any?(Map.get(activations, id, []))
    end
  end

  defimpl Inspect do
    def inspect(%{id: id, class: [operator, value]}, _opts) do
      "#{operator} #{value} (#{id})"
    end
  end
end
