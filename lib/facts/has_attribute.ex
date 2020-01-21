defmodule Retex.Fact.HasAttribute do
  @moduledoc "Attribute values that a Wme should have in order for this condition to be true"

  defstruct owner: nil, attribute: nil, predicate: nil, value: nil

  @type owner :: String.t() | atom()
  @type attribute :: String.t() | atom()
  @type predicate :: :== | :=== | :!== | :!= | :> | :< | :<= | :>=
  @type value :: any()
  @type fields :: [owner: owner(), attribute: attribute(), predicate: predicate(), value: value()]

  @type t :: %__MODULE__{
          owner: owner(),
          attribute: attribute(),
          predicate: predicate(),
          value: value()
        }
  @spec new(fields()) :: t()
  def new(fields) do
    struct(__MODULE__, fields)
  end
end
