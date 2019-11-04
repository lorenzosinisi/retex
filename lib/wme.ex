defmodule Retex.Wme do
  @moduledoc "A working memory element, it represent the world in the form of identifier, attribute and values"
  defstruct identifier: nil, attribute: nil, value: nil, id: nil

  def new(id, attr, val) do
    item = %__MODULE__{identifier: id, attribute: attr, value: val}
    Map.put(item, :id, Retex.hash(item))
  end
end
