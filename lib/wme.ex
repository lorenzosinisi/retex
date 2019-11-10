defmodule Retex.Wme do
  @moduledoc """
    A working memory element, it represent the world in the form of identifier, attribute and values
    timestamp is set at time of insertion into retex
  """

  defstruct identifier: nil, attribute: nil, value: nil, id: nil, timesptamp: nil

  def new(id, attr, val) do
    item = %__MODULE__{identifier: id, attribute: attr, value: val}
    Map.put(item, :id, Retex.hash(item))
  end
end
