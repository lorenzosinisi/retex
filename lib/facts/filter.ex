defmodule Retex.Fact.Filter do
  @moduledoc "Apply a filter to a variable on the PNode, so that the activation of a PNode happens when this condition is also satisfied"
  defstruct variable: nil, predicate: nil, value: nil

  @type variable :: String.t()
  @type predicate :: :== | :=== | :!== | :!= | :> | :< | :<= | :>= | :in
  @type value :: any()
  @type t :: %__MODULE__{variable: variable(), predicate: predicate(), value: value()}
  @type fields :: [variable: variable(), predicate: predicate(), value: value()]

  @spec new(fields()) :: t()
  def new(fields) do
    struct(__MODULE__, fields)
  end

  defimpl Inspect do
    def inspect(vertex, _opts) do
      "Filter($#{vertex.variable}, #{vertex.predicate}, #{vertex.value})"
    end
  end
end
