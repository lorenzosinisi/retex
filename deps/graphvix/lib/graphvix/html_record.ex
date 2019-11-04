defmodule Graphvix.HTMLRecord do
  @moduledoc """
  Models a graph vertex that uses HTML to generate a table-shaped record.

  # Table structure

  The Graphviz API allows the basic table-related HTML elements:

  * `<table>`
  * `<tr>`
  * `<th>`

  and the `Graphvix` API provides the parallel functions:

  * `new/2`
  * `tr/1`
  * `td/2`

  ## Example

      iex> import Graphvix.HTMLRecord, only: [tr: 1, td: 1, td: 2]
      iex> record = HTMLRecord.new([
      iex>   tr([
      ...>     td("a"),
      ...>     td("b")
      ...>   ]),
      ...>   tr([
      ...>     td("c"),
      ...>     td("d")
      ...>   ]),
      ...> ])
      iex> HTMLRecord.to_label(record)
      ~S(<table>
        <tr>
          <td>a</td>
          <td>b</td>
        </tr>
        <tr>
          <td>c</td>
          <td>d</td>
        </tr>
      </table>)

  # Ports

  As with `Graphvix.Record` vertices, port names can be attached to cells. With
  `HTMLRecord` vertices, this is done by passing a `:port` key as one of the
  attributes in the second argument keyword list for `td/2`.

      iex> import Graphvix.HTMLRecord, only: [tr: 1, td: 1, td: 2]
      iex> record = HTMLRecord.new([
      iex>   tr([td("a"), td("b")]),
      ...>   tr([td("c", port: "port_c"), td("d")]),
      ...> ])
      iex> HTMLRecord.to_label(record)
      ~S(<table>
        <tr>
          <td>a</td>
          <td>b</td>
        </tr>
        <tr>
          <td port="port_c">c</td>
          <td>d</td>
        </tr>
      </table>)

  In addition to `:port`, values for existing HTML keys

  * `border`
  * `cellpadding`
  * `cellspacing`

  can be added to cells, and

  * `border`
  * `cellborder`
  * `cellpadding`
  * `cellspacing`

  can be added to the table at the top-level to style the table and cells.

  # Text formatting

  Aside from structuring the table, two elements are available for formatting
  the content of the cells

  * `<font>`
  * `<br/>`

  with corresponding `Graphvix.HTMLRecord` functions

  * `font/2`
  * `br/0`

  In addition to contents as its first argument, `font/2` can take a keyword list
  of properties as its optional second argument.

      iex> import Graphvix.HTMLRecord, only: [tr: 1, td: 1, td: 2, br: 0, font: 2]
      iex> record = HTMLRecord.new([
      iex>   tr([td("a"), td(["b", br(), font("B", color: "red", point_size: 100)])]),
      ...>   tr([td("c"), td("d")]),
      ...> ])
      iex> HTMLRecord.to_label(record)
      ~S(<table>
        <tr>
          <td>a</td>
          <td>b<br/><font color="red" point-size="100">B</font></td>
        </tr>
        <tr>
          <td>c</td>
          <td>d</td>
        </tr>
      </table>)


  While maintaining proper nesting (each element contains both opening and closing
  tags within its enclosing element), these elements may be nested as desired,
  including nesting entire tables inside of cells.

  """

  defstruct [
    rows: [],
    attributes: []
  ]

  @type t :: %__MODULE__{
    rows: [__MODULE__.tr],
    attributes: keyword()
  }
  @type tr :: %{cells: __MODULE__.cells}

  @type br :: %{tag: :br}
  @type font :: %{tag: :font, cell: __MODULE__.one_or_more_cells, attributes: keyword()}
  @type td :: %{label: __MODULE__.one_or_more_cells, attributes: keyword()}

  @type cell :: String.t |
    __MODULE__.br |
    __MODULE__.font |
    __MODULE__.td |
    __MODULE__.t

  @type cells :: [__MODULE__.cell]

  @type one_or_more_cells :: __MODULE__.cell | [__MODULE__.cell]

  alias Graphvix.HTMLRecord
  import Graphvix.DotHelpers, only: [indent: 1]

  @doc """
  Returns a new `HTMLRecord` which can be turned into an HTML table vertex.

  It takes two arguments. The first is a list of table rows all returned from
  the `tr/1` function.

  The second is an optional keyword list of attributes to apply to the table as
  a whole. Valid keys for this list are:

  * `align`
  * `bgcolor`
  * `border`
  * `cellborder`
  * `cellpadding`
  * `cellspacing`
  * `color`
  * `columns`
  * `fixedsize`
  * `gradientangle`
  * `height`
  * `href`
  * `id`
  * `port`
  * `rows`
  * `sides`
  * `style`
  * `target`
  * `title`
  * `tooltip`
  * `valign`
  * `width`

  ## Example

      iex> import HTMLRecord, only: [tr: 1, td: 1]
      iex> HTMLRecord.new([
      ...>   tr([
      ...>     td("a"),
      ...>     td("b")
      ...>   ]),
      ...>   tr([
      ...>     td("c"),
      ...>     td("d")
      ...>   ])
      ...> ], border: 1, cellspacing: 0, cellborder: 1)
      %HTMLRecord{
        rows: [
          %{cells: [
            %{label: "a", attributes: []},
            %{label: "b", attributes: []},
          ]},
          %{cells: [
            %{label: "c", attributes: []},
            %{label: "d", attributes: []},
          ]}
        ],
        attributes: [
          border: 1,
          cellspacing: 0,
          cellborder: 1
        ]
      }

  """
  def new(rows, attributes \\ []) when is_list(rows) do
    %__MODULE__{rows: rows, attributes: attributes}
  end

  @doc """
  A helper method to generate a row of a table.

  It takes a single argument, which is a list of cells returned by the `td/2`
  helper function.
  """
  def tr(cells) when is_list(cells) do
    %{cells: cells}
  end

  @doc """
  A helper method to generate a single cell of a table.

  The first argument is the contents of the cell. It can be a plain string or
  a list of other elements.

  The second argument is an optional keyword list of attributes to apply to the
  cell. Valid keys include:

  * `align`
  * `balign`
  * `bgcolor`
  * `border`
  * `cellpadding`
  * `cellspacing`
  * `color`
  * `colspan`
  * `fixedsize`
  * `gradientangle`
  * `height`
  * `href`
  * `id`
  * `port`
  * `rowspan`
  * `sides`
  * `style`
  * `target`
  * `title`
  * `tooltip`
  * `valign`
  * `width`

  See the module documentation for `Graphvix.HTMLRecord` for usage examples in context.
  """
  def td(label, attributes \\ []) do
    %{label: label, attributes: attributes}
  end

  @doc """
  Creates a `<br/>` element as part of a cell in an `HTMLRecord`

  A helper method that creates a `<br/>` HTML element as part of a table cell.

  See the module documentation for `Graphvix.HTMLRecord` for usage examples in context.
  """
  def br, do: %{tag: :br}

  @doc """
  Creates a `<font/>` element as part of a cell in an `HTMLRecord`

  A helper method that creates a `<br/>` HTML element as part of a table cell.

  The first argument to `font/2` is the contents of the cell, which can itself
  be a plain string or a list of nested element functions.

  The second, optional argument is a keyword list of attributes to determine
  the formatting of the contents of the `<tag>`. Valid keys for this list are

  * `color`
  * `face`
  * `point_size`

  ## Example

      iex> HTMLRecord.font("a", color: "blue", face: "Arial", point_size: 10)
      %{tag: :font, cell: "a", attributes: [color: "blue", face: "Arial", point_size: 10]}

  """
  def font(cell, attributes \\ []) do
    %{tag: :font, cell: cell, attributes: attributes}
  end

  @doc """
  Converts an `HTMLRecord` struct into a valid HTML-like string.

  The resulting string can be passed to `Graphvix.Graph.add_vertex/3` as a label
  for a vertex.

  ## Example

      iex> import HTMLRecord, only: [tr: 1, td: 1]
      iex> record = HTMLRecord.new([
      ...>   tr([
      ...>     td("a"),
      ...>     td("b")
      ...>   ]),
      ...>   tr([
      ...>     td("c"),
      ...>     td("d")
      ...>   ])
      ...> ], border: 1, cellspacing: 0, cellborder: 1)
      iex> HTMLRecord.to_label(record)
      ~S(<table border="1" cellspacing="0" cellborder="1">
        <tr>
          <td>a</td>
          <td>b</td>
        </tr>
        <tr>
          <td>c</td>
          <td>d</td>
        </tr>
      </table>)

  """
  def to_label(%__MODULE__{rows: rows, attributes: attributes}) do
    [
      "<table#{attributes_for_label(attributes)}>",
      Enum.map(rows, &tr_to_label/1),
      "</table>"
    ] |> List.flatten |> Enum.join("\n")
  end

  ## Private

  defp tr_to_label(%{cells: cells}) do
    [
      "<tr>",
      Enum.map(cells, &td_to_label/1),
      "</tr>"
    ] |> List.flatten |> Enum.join("\n") |> indent
  end

  defp td_to_label(%{label: label, attributes: attributes}) do
    [
      "<td#{attributes_for_label(attributes)}>",
      label_to_string(label),
      "</td>"
    ] |> Enum.join("") |> indent()
  end

  defp attributes_for_label(attributes) do
    case attributes do
      [] -> ""
      attrs ->
        " " <> (Enum.map(attrs, fn {k, v} ->
          ~s(#{hyphenize(k)}="#{v}")
        end) |> Enum.join(" "))
    end
  end

  defp hyphenize(name) do
    name |> to_string |> String.replace("_", "-")
  end

  defp label_to_string(list) when is_list(list) do
    Enum.map(list, &label_to_string/1) |> Enum.join("")
  end
  defp label_to_string(%{tag: :br}), do: "<br/>"
  defp label_to_string(%{tag: :font, cell: cell, attributes: attributes}) do
    [
      "<font#{attributes_for_label(attributes)}>",
      label_to_string(cell),
      "</font>"
    ] |> Enum.join("")
  end
  defp label_to_string(table = %HTMLRecord{}) do
    HTMLRecord.to_label(table)
  end
  defp label_to_string(string) when is_bitstring(string), do: string
end
