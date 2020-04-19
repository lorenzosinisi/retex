defmodule Retex.Fact.UnexistantAttribute do
  @moduledoc "Attribute values that a Wme should NOT have in order for this condition to be true"

  defstruct owner: nil, attribute: nil

  @type owner :: String.t() | atom()
  @type attribute :: String.t() | atom()
  @type fields :: [owner: owner(), attribute: attribute()]

  @type t :: %Retex.Fact.UnexistantAttribute{
          owner: owner(),
          attribute: attribute()
        }
  @spec new(fields()) :: t()
  def new(fields) do
    struct(__MODULE__, fields)
  end
end
