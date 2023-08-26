defmodule Retex.Node.NegativeType do
  @moduledoc """
  The NegativeNodeType if part of the alpha network, the discrimination part of the network
  that check if a specific class DOES NOT exist. If this is the case, it propagates the activations
  down to the select node types. They will select an attribute and check for its test to pass.
  """
  defstruct class: nil, id: nil
  @type t :: %Retex.Node.Type{}

  def new(class) do
    item = %__MODULE__{class: class}
    %{item | id: Retex.hash(item)}
  end

  defimpl Retex.Protocol.Activation do
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
      |> Retex.deactivate_descendants(neighbor)
      |> Retex.stop_traversal(%{})
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
    def active?(%{id: id}, %Retex{id: network_id, activations: _activations}) do
      activations = Retex.get(network_id, :activations)
      Enum.empty?(Map.get(activations, id, []))
    end
  end
end
