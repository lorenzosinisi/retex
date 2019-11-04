defmodule Retex.Fact.HasAttribute do
  @moduledoc "Attribute values that a Wme should have in order for this condition to be true"
  defstruct owner: nil, attribute: nil, predicate: nil, value: nil

  def new(fields) do
    struct(__MODULE__, fields)
  end
end
