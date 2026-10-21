defmodule Retex.Fact.Relation do
  @moduledoc "A relation triple that a WME must match for this condition to be true"
  defstruct name: nil, from: nil, to: nil, via: nil

  def new(fields) do
    via = to_string(fields[:from]) |> String.downcase() |> Kernel.<>("_id")
    rel = struct(__MODULE__, fields)
    Map.put(rel, :via, via)
  end

  defimpl Retex.Protocol.AlphaNetwork do
    alias Retex.Fact.HasAttribute

    def append(%Retex.Fact.Relation{from: from, name: name, to: to}, accumulator) do
      condition =
        HasAttribute.new(owner: from, attribute: name, predicate: :==, value: to)

      Retex.Protocol.AlphaNetwork.append(condition, accumulator)
    end
  end
end
