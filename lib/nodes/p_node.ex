defmodule Retex.Node.PNode do
  @moduledoc """
  Production node. This is like a production node in Rete algorithm. It is activated if all
  the conditions in a rule are matching and contains the action that can be executed as consequence.
  """
  defstruct type: :PNode, action: nil, id: nil

  def new(action, labels \\ []) do
    item = %__MODULE__{action: action}
    {%{item | id: Retex.hash(item)}, labels}
  end

  defimpl Retex.Protocol.Activation do
    def activate(neighbor, %Retex{graph: graph, activations: activations} = rete, _wme, bindings) do
      with true <- Graph.in_neighbors(graph, neighbor) |> Enum.all?(&Map.get(activations, &1.id)) do
        pnode = Retex.replace_bindings(neighbor, bindings)
        new_rete = %{rete | agenda: [pnode.action | rete.agenda]}
        Retex.stop_traversal(new_rete, bindings)
      else
        _ -> Retex.stop_traversal(rete, bindings)
      end
    end
  end
end
