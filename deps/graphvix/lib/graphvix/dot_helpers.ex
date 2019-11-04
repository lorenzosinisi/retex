defmodule Graphvix.DotHelpers do
  @moduledoc """
  This module contains a set of helper methods for converting Elixir graph data
  into its DOT representation.
  """


  @doc """
  Convert top-level node and edge properties for a graph or subgraph into
  correct DOT notation.

  ## Example

      iex> graph = Graph.new(edge: [color: "green", style: "dotted"], node: [color: "blue"])
      iex> DotHelpers.global_properties_to_dot(graph)
      ~S(  node [color="blue"]
        edge [color="green",style="dotted"])

  """
  def global_properties_to_dot(graph) do
    [:node, :edge]
      |> Enum.map(&_global_properties_to_dot(graph, &1))
      |> compact()
      |> case do
        [] -> nil
        global_props -> Enum.join(global_props, "\n")
      end
  end

  @doc """
  Converts a list of attributes into a properly formatted list of DOT attributes.

  ## Examples

      iex> DotHelpers.attributes_to_dot(color: "blue", shape: "circle")
      ~S([color="blue",shape="circle"])

  """
  def attributes_to_dot([]), do: nil
  def attributes_to_dot(attributes) do
    [
      "[",
      Enum.map(attributes, fn {key, value} ->
        attribute_to_dot(key, value)
      end) |> Enum.join(","),
      "]"
    ] |> Enum.join("")
  end

  @doc """
  Convert a single atribute to DOT format for inclusion in a list of attributes.

  ## Examples

      iex> DotHelpers.attribute_to_dot(:color, "blue")
      ~S(color="blue")

  There is one special case this function handles, which is the label for a record
  using HTML to build a table. In this case the generated HTML label must be
  surrounded by a set of angle brackets `< ... >` instead of double quotes.

      iex> DotHelpers.attribute_to_dot(:label, "<table></table>")
      "label=<<table></table>>"

  """
  def attribute_to_dot(:label, value = "<table" <> _) do
    ~s(label=<#{value}>)
  end
  def attribute_to_dot(key, value) do
    ~s(#{key}="#{value}")
  end

  @doc """
  Indent a single line or block of text.

  An optional second argument can be provided to tell the function how deep
  to indent (defaults to one level).

  ## Examples

      iex> DotHelpers.indent("hello")
      "  hello"

      iex> DotHelpers.indent("hello", 3)
      "      hello"

      iex> DotHelpers.indent("line one\\n  line two\\nline three")
      "  line one\\n    line two\\n  line three"

  """
  def indent(string, depth \\ 1)
  def indent(string, depth) when is_bitstring(string) do
    string
    |> String.split("\n")
    |> indent(depth)
    |> Enum.join("\n")
  end
  def indent(list, depth) when is_list(list) do
    Enum.map(list, fn s -> String.duplicate("  ", depth) <> s end)
  end

  @doc """
  Maps a collection of vertices or nodes to their correct DOT format.


  The first argument is a reference to an ETS table or the list of results
  from an ETS table. The second argument is the function used to format
  each element in the collection.
  """
  def elements_to_dot(table, formatting_func) when is_reference(table) or is_integer(table) do
    :ets.tab2list(table) |> elements_to_dot(formatting_func)
  end
  def elements_to_dot(list, formatting_func) when is_list(list) do
    list
    |> sort_elements_by_id()
    |> Enum.map(&formatting_func.(&1))
    |> compact()
    |> return_joined_list_or_nil()
  end

  @doc """
  Returns nil if an empty list is passed in. Returns the elements of the list
  joined by the optional second parameter (defaults to `\n` otherwise.

  ## Examples

      iex> DotHelpers.return_joined_list_or_nil([])
      nil

      iex> DotHelpers.return_joined_list_or_nil([], "-")
      nil

      iex> DotHelpers.return_joined_list_or_nil(["a", "b", "c"])
      "a\\nb\\nc"

      iex> DotHelpers.return_joined_list_or_nil(["a", "b", "c"], "-")
      "a-b-c"

  """
  def return_joined_list_or_nil(list, joiner \\ "\n")
  def return_joined_list_or_nil([], _joiner), do: nil
  def return_joined_list_or_nil(list, joiner) do
    Enum.join(list, joiner)
  end

  @doc """
  Takes a list of elements returned from the vertex or edge table and sorts
  them by their ID.

  This ensures that vertices and edges are written into the `.dot` file in the
  same order they were added to the ETS tables. This is important as the order
  of vertices and edges in a `.dot` file can ultimately affect the final
  layout of the graph.
  """
  def sort_elements_by_id(elements) do
    Enum.sort_by(elements, fn element ->
      [[_ | id] | _] = Tuple.to_list(element)
      id
    end)
  end

  @doc """
  Removes all `nil` elements from an list.

  ## Examples

      iex> DotHelpers.compact([])
      []

      iex> DotHelpers.compact(["a", nil, "b", nil, 1])
      ["a", "b", 1]

  """
  def compact(enum), do: Enum.reject(enum, &is_nil/1)

  ## Private

  defp _global_properties_to_dot(%{global_properties: global_props}, key) do
    with props <- Keyword.get(global_props, key) do
      case length(props) do
        0 -> nil
        _ -> indent("#{key} #{attributes_to_dot(props)}")
      end
    end
  end
end
