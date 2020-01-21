defmodule Retex.Fact.Isa do
  @moduledoc "A type of thing that needs to exists in order for a Wme to activate part of a condition"
  defstruct type: nil, variable: nil

  @type type :: String.t() | atom()
  @type variable :: String.t()
  @type fields :: [type: type(), variable: variable()]
  @type t :: %__MODULE__{type: type(), variable: variable()}

  @spec new(fields()) :: t()
  def new(fields) do
    struct(__MODULE__, fields)
  end
end
