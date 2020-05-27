defmodule Retex.Wme do
  @moduledoc """
    A working memory element, it represent the world in the form of identifier, attribute and values
    timestamp is set at time of insertion into retex
  """
  @type wme_identifier() :: String.t() | atom()
  @type attribute() :: String.t() | atom()
  @type id() :: String.t() | number()
  @type value() :: any()

  @type t :: %__MODULE__{
          identifier: wme_identifier(),
          attribute: attribute(),
          id: id(),
          timestamp: number(),
          value: value()
        }

  defstruct identifier: nil, attribute: nil, value: nil, id: nil, timestamp: nil
  alias Retex.Fact.HasAttribute

  def new(id, attr, val) do
    item = %__MODULE__{identifier: id, attribute: attr, value: val}
    Map.put(item, :id, Retex.hash(item))
  end

  def to_has_attribute(%Retex.Wme{} = wme) do
    %__MODULE__{identifier: id, attribute: attr, value: val} = wme
    HasAttribute.new(owner: id, attribute: attr, predicate: :==, value: val)
  end
end
