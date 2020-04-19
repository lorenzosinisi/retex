defmodule Retex.Node.BetaMemory do
  @moduledoc """
  A BetaMemory works like a two input node in Rete. It is simply a join node
  between two tests that have passed successfully. The activation of a BetaMemory
  happens if the two parents (left and right) have been activated and the bindings
  are matching for both of them.
  """
  defstruct type: :BetaMemory, left: nil, right: nil, id: nil, bindings: %{}
  @type t :: %Retex.Node.BetaMemory{}

  def new(left, right, labels \\ []) do
    item = %__MODULE__{left: left, right: right}
    {%{item | id: Retex.hash(item)}, labels}
  end

  defimpl Retex.Protocol.Activation do
    def activate(neighbor, rete, wme, bindings, _tokens) do
      with true <- __MODULE__.active?(neighbor.left, rete),
           true <- __MODULE__.active?(neighbor.right, rete),
           left_tokens <- Map.get(rete.tokens, neighbor.left.id),
           right_tokens <- Map.get(rete.tokens, neighbor.right.id),
           new_tokens <- matching_tokens(right_tokens, left_tokens),
           true <- Enum.any?(new_tokens) do
        rete
        |> Retex.create_activation(neighbor, wme)
        |> Retex.add_token(neighbor, wme, bindings, new_tokens)
        |> Retex.continue_traversal(bindings, neighbor, wme)
      else
        _ ->
          Retex.stop_traversal(rete, %{})
      end
    end

    defp matching_tokens(left, right) do
      for i <- left, j <- right do
        left_bindings = if is_tuple(i), do: elem(i, 2), else: i.bindings
        right_bindings = if is_tuple(j), do: elem(j, 2), else: j.bindings

        if variables_match(left_bindings, right_bindings),
          do: [{j, i, Map.merge(left_bindings, right_bindings)}],
          else: []
      end
      |> List.flatten()
    end

    defp variables_match(left, right) do
      Enum.reduce_while(left, true, fn {key, value}, true ->
        if Map.get(right, key, value) == value, do: {:cont, true}, else: {:halt, false}
      end) &&
        Enum.reduce_while(right, true, fn {key, value}, true ->
          if Map.get(left, key, value) == value, do: {:cont, true}, else: {:halt, false}
        end)
    end

    @spec active?(%{id: any}, Retex.t()) :: boolean()
    def active?(%{id: id}, %Retex{activations: activations}) do
      not Enum.empty?(Map.get(activations, id, []))
    end
  end
end
