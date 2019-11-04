defmodule Retex.Fact.Isa do
  @moduledoc "A type of thing that needs to exists in order for a Wme to activate part of a condition"
  defstruct type: nil, variable: nil

  def new(fields) do
    struct(__MODULE__, fields)
  end
end
