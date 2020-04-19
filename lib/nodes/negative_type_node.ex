defmodule Retex.Node.NegativeType do
  @moduledoc """
  The NegativeNodeType if part of the alpha network, the discrimination part of the network
  that check if a specific class DOES NOT exist. If this is the case, it propagates the activations
  down to the select node types. They will select an attribute and check for its test to pass.
  """
  defstruct type: :NegativeNodeType, class: nil, id: nil, bindings: %{}
  @type t :: %Retex.Node.Type{}

  def new(class, labels \\ []) do
    item = %__MODULE__{class: class}
    {%{item | id: Retex.hash(item)}, labels}
  end

  defimpl Retex.Protocol.Activation do
    def activate(
          %Retex.Node.NegativeType{class: class} = neighbor,
          %Retex{graph: _graph} = rete,
          %Retex.Wme{identifier: "$" <> _identifier = var} = wme,
          bindings,
          tokens
        ) do
      new_bindings = Map.merge(bindings, %{var => class})

      rete
      |> Retex.create_activation(neighbor, wme)
      |> Retex.add_token(neighbor, wme, new_bindings, tokens)
      |> Retex.continue_traversal(new_bindings, neighbor, wme)
    end

    def activate(
          %Retex.Node.NegativeType{class: "$" <> _variable = var} = neighbor,
          %Retex{graph: _graph} = rete,
          %Retex.Wme{identifier: identifier} = wme,
          bindings,
          tokens
        ) do
      rete
      |> Retex.create_activation(neighbor, wme)
      |> Retex.add_token(neighbor, wme, Map.merge(bindings, %{var => identifier}), tokens)
      |> Retex.continue_traversal(Map.merge(bindings, %{var => identifier}), neighbor, wme)
    end

    def activate(
          %Retex.Node.NegativeType{class: identifier} = neighbor,
          %Retex{} = rete,
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
          %Retex.Node.NegativeType{class: _class},
          %Retex{graph: _graph} = rete,
          %Retex.Wme{identifier: _identifier} = _wme,
          _bindings,
          _tokens
        ) do
      Retex.stop_traversal(rete, %{})
    end

    @spec active?(%{id: any}, Retex.t()) :: boolean()
    def active?(%{id: id}, %Retex{activations: activations}) do
      Enum.empty?(Map.get(activations, id, []))
    end
  end
end
