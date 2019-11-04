defmodule Graphvix.Record do
  @moduledoc """
  Models a graph vertex that has a shape of `record`.

  A record's label can be a single string, a single row or column, or a nested
  alternation of rows and columns.

  Once a record is created by `Graphvix.Record.new/2` it can be added to a graph using
  `Graphvix.Graph.add_record/2`.

  See `new/2` for more complete usage examples.

  ## Example

      iex> import Record, only: [column: 1]
      iex> graph = Graph.new()
      iex> record = Record.new(["a", "B", column(["c", "D"])], color: "blue")
      iex> {graph, _rid} = Graph.add_record(graph, record)
      iex> Graph.to_dot(graph)
      ~s(digraph G {\\n\\n  v0 [label="a | B | { c | D }",shape="record",color="blue"]\\n\\n})

  """

  defstruct [
    body: nil,
    properties: []
  ]

  alias __MODULE__
  alias Graphvix.RecordSubset

  @type body :: String.t | [any()] | RecordSubset.t()
  @type t :: %__MODULE__{body: Record.t(), properties: keyword()}

  @doc """
  Returns a new `Graphvix.Record` struct that can be added to a graph as a vertex.

  ## Examples

  A record's can be a simple text label

      iex> record = Record.new("just a plain text record")
      iex> Record.to_label(record)
      "just a plain text record"

  or it can be a single row or column of strings

      iex> import Record, only: [row: 1]
      iex> record = Record.new(row(["a", "b", "c"]))
      iex> Record.to_label(record)
      "a | b | c"

      iex> import Record, only: [column: 1]
      iex> record = Record.new(column(["a", "b", "c"]))
      iex> Record.to_label(record)
      "{ a | b | c }"

  or it can be a series of nested rows and columns

      iex> import Record, only: [row: 1, column: 1]
      iex> record = Record.new(
      ...>   row([
      ...>     "a",
      ...>     column([
      ...>       "b", "c", "d"
      ...>     ]),
      ...>     column([
      ...>       "e",
      ...>       "f",
      ...>       row([
      ...>         "g", "h", "i"
      ...>       ])
      ...>     ])
      ...>   ])
      ...> )
      iex> Record.to_label(record)
      "a | { b | c | d } | { e | f | { g | h | i } }"

  passing a plain list defaults to a row

      iex> record = Record.new(["a", "b", "c"])
      iex> Record.to_label(record)
      "a | b | c"

  Each cell can contain a plain string, or a string with a port attached,
  allowing edges to be drawn directly to and from that cell, rather than the
  vertex. Ports are created by passing a tuple of the form `{port_name, label}`

      iex> record = Record.new(["a", {"port_b", "b"}])
      iex> Record.to_label(record)
      "a | <port_b> b"

  A second, optional argument can be passed specifying other formatting and
  styling properties for the vertex.

      iex> record = Record.new(["a", {"port_b", "b"}, "c"], color: "blue")
      iex> graph = Graph.new()
      iex> {graph, _record_id} = Graph.add_record(graph, record)
      iex> Graph.to_dot(graph)
      ~s(digraph G {\\n\\n  v0 [label="a | <port_b> b | c",shape="record",color="blue"]\\n\\n})


  """
  def new(body, properties \\ [])
  def new(string, properties) when is_bitstring(string) do
    %__MODULE__{body: string, properties: properties}
  end
  def new(list, properties) when is_list(list) do
    %__MODULE__{body: Graphvix.RecordSubset.new(list), properties: properties}
  end
  def new(row_or_column = %Graphvix.RecordSubset{}, properties) do
    %__MODULE__{body: row_or_column, properties: properties}
  end

  @doc """
  A helper method that takes a list of cells and returns them as a row inside a
  `Graphvix.Record` struct.

  The list can consist of a mix of string labels or tuples of cell labels +
  port names.

  This function provides little functionality on its own. See the documentation
  for `Graphvix.Record.new/2` for usage examples in context.
  """
  def row(cells) do
    %RecordSubset{cells: cells, is_column: false}
  end

  @doc """
  A helper method that takes a list of cells and returns them as a column inside a
  `Graphvix.Record` struct.

  The list can consist of a mix of string labels or tuples of cell labels +
  port names.

  This function provides little functionality on its own. See the documentation
  for `Graphvix.Record.new/2` for usage examples in context.
  """
  def column(cells) do
    %RecordSubset{cells: cells, is_column: true}
  end

  @doc false
  def to_label(record)
  def to_label(%{body: string}) when is_bitstring(string) do
    string
  end
  def to_label(%{body: subset = %RecordSubset{}}) do
    RecordSubset.to_label(subset, true)
  end
end
