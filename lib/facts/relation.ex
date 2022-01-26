defmodule Retex.Fact.Relation do
  @moduledoc "Attribute values that a Wme should have in order for this condition to be true"
  defstruct name: nil, from: nil, to: nil, via: nil

  def new(fields) do
    via = to_string(fields[:from]) |> String.downcase() |> Kernel.<>("_id")
    rel = struct(__MODULE__, fields)
    Map.put(rel, :via, via)
  end

  defimpl Inspect do
    def inspect(vertex, _opts) do
      "Relation(#{vertex.from}, #{vertex.via}, #{vertex.to})"
    end
  end
end
