defmodule Graphvix.RecordSubset do
  @moduledoc """
  [Internal] Models a row or a column as part of a `Graphvix.Record` vertex.

  The functionality provided by this module is internal. See the documentation
  for `Graphvix.Record`.
  """

  defstruct [
    cells: [],
    is_column: false
  ]

  alias __MODULE__

  @type t :: %__MODULE__{cells: [RecordSubset.cell()], is_column: boolean()}
  @type cell_with_port :: {String.t(), String.t()}
  @type cell :: String.t() | RecordSubset.cell_with_port() | RecordSubset.t()

  @doc false
  def new(cells, is_column \\ false) do
    %__MODULE__{cells: cells, is_column: is_column}
  end

  @doc false
  def to_label(subset, top_level \\ false)
  def to_label(%{cells: cells, is_column: false}, _top_level = true) do
    Enum.map(cells, &_to_label/1) |> Enum.join(" | ")
  end
  def to_label(%{cells: cells}, _top_level) do
    "{ " <> (Enum.map(cells, &_to_label/1) |> Enum.join(" | ")) <> " }"
  end

  defp _to_label(string) when is_bitstring(string), do: string
  defp _to_label({port, string}) do
    "<#{port}> #{string}"
  end
  defp _to_label(subset = %__MODULE__{}), do: __MODULE__.to_label(subset)
end
