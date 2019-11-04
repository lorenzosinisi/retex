defmodule Graphvix.Graph do
  @moduledoc """
  Models a directed graph that can be written to disk and displayed using
  [Graphviz](http://www.graphviz.org/) notation.

  Graphs are created by

  * adding vertices of various formats to a graph
    * `add_vertex/3`
    * `add_record/2`
    * `add_html_record/2`
  * connecting them with edges
    * `add_edge/4`
  * grouping them into subgraphs and clusters,
    * `add_subgraph/3`
    * `add_cluster/3`
  * providing styling to all these elements
    * `set_graph_property/3`
    * `set_global_properties/3`

  They can then be

  * written to disk in `.dot` format
    * `write/2`
  * compiled and displayed in any number of image formats (`Graphvix` defaults to `.png`)
    * `compile/3`
    * `show/2`

  """
  import Graphvix.DotHelpers

  alias Graphvix.{Record, HTMLRecord}

  defstruct [
    digraph: nil,
    global_properties: [node: [], edge: []],
    graph_properties: [],
    subgraphs: []
  ]

  @type digraph :: {:digraph, reference(), reference(), reference(), boolean()}
  @type t :: %__MODULE__{
    digraph: digraph(),
    global_properties: keyword(),
    graph_properties: keyword(),
    subgraphs: list()
  }

  @doc """
  Creates a new `Graph` struct.

  A `Graph` struct consists of an Erlang `digraph` record, a list of subgraphs,
  and two keyword lists of properties.

  ## Examples

      iex> graph = Graph.new()
      iex> Graph.to_dot(graph)
      ~S(digraph G {

      })

      iex> graph = Graph.new(graph: [size: "4x4"], node: [shape: "record"])
      iex> Graph.to_dot(graph)
      ~S(digraph G {

          size="4x4"

          node [shape="record"]

      })

  """
  def new(attributes \\ []) do
    digraph = :digraph.new()
    [_, _, ntab] = _digraph_tables(digraph)
    true = :ets.insert(ntab, {:"$sid", 0})
    %__MODULE__{
      digraph: digraph,
      global_properties: [
        node: Keyword.get(attributes, :node, []),
        edge: Keyword.get(attributes, :edge, [])
      ],
      graph_properties: Keyword.get(attributes, :graph, [])
    }
  end

  @doc """

  Destructures the references to the ETS tables for vertices, edges, and
  neighbours from the `Graph` struct.

  ## Examples

      iex> graph = Graph.new()
      iex> Graph.digraph_tables(graph)
      [
        #Reference<0.4011094290.3698196484.157076>,
        #Reference<0.4011094290.3698196484.157077>,
        #Reference<0.4011094290.3698196484.157078>
      ]

  """
  def digraph_tables(%__MODULE__{digraph: graph}), do: _digraph_tables(graph)
  defp _digraph_tables({:digraph, vtab, etab, ntab, _}) do
    [vtab, etab, ntab]
  end

  @doc """
  Adds a vertex to `graph`.

  The vertex's label text is the argument `label`, and additional attributes
  can be passed in as `attributes`. It returns a tuple of the updated graph
  and the `:digraph`-assigned ID for the new vertex.

  ## Examples

      iex> graph = Graph.new()
      iex> {_graph, vid} = Graph.add_vertex(graph, "hello", color: "blue")
      iex> vid
      [:"$v" | 0]

  """
  def add_vertex(graph, label, attributes \\ []) do
    next_id = get_and_increment_vertex_id(graph)
    attributes = Keyword.put(attributes, :label, label)
    vertex_id = [:"$v" | next_id]
    vid = :digraph.add_vertex(graph.digraph, vertex_id, attributes)
    {graph, vid}
  end

  @doc """
  Add an edge between two vertices in a graph.

  It takes 3 required arguments and one optional. The first argument is the graph,
  the second two arguments are the tail and head of the edge respectively, and the
  fourth, optional, argument is a list of layout attributes to apply to the edge.

  The arguments for the ends of the edge can each be either the id of a vertex, or
  a tuple of a vertex id and a port name to attach the edge to. This second
  option is only valid with `Record` or `HTMLRecord` vertices.

  ## Examples

      iex> graph = Graph.new()
      iex> {graph, v1id} = Graph.add_vertex(graph, "start")
      iex> {graph, v2id} = Graph.add_vertex(graph, "end")
      iex> {_graph, eid} = Graph.add_edge(graph, v1id, v2id, color: "green")
      iex> eid
      [:"$e" | 0]

  """
  def add_edge(graph, out_from, in_to, attributes \\ [])
  def add_edge(graph, {id = [:"$v" | _], port}, in_to, attributes) do
    add_edge(graph, id, in_to, Keyword.put(attributes, :outport, port))
  end
  def add_edge(graph, out_from, {id = [:"$v" | _], port}, attributes) do
    add_edge(graph, out_from, id, Keyword.put(attributes, :inport, port))
  end
  def add_edge(graph, out_from, in_to, attributes) do
    eid = :digraph.add_edge(graph.digraph, out_from, in_to, attributes)
    {graph, eid}
  end

  @doc """
  Group a set of vertices into a subgraph within a graph.

  In addition to the graph and the vertex ids, you can pass attributes for
  `node` and `edge` to apply common styling to the vertices included
  in the subgraph, as well as the edges between two vertices both in the subgraph.

  ## Examples

      iex> graph = Graph.new()
      iex> {graph, v1id} = Graph.add_vertex(graph, "start")
      iex> {graph, v2id} = Graph.add_vertex(graph, "end")
      iex> {_graph, sid} = Graph.add_subgraph(
      ...>   graph, [v1id, v2id],
      ...>   node: [shape: "triangle"],
      ...>   edge: [style: "dotted"]
      ...> )
      iex> sid
      "subgraph0"

  """
  def add_subgraph(graph, vertex_ids, properties \\ []) do
    _add_subgraph(graph, vertex_ids, properties, false)
  end


  @doc """
  Group a set of vertices into a cluster in a graph.

  In addition to the graph and the vertex ids, you can pass attributes
  for `node` and `edge` to apply common styling to the vertices included
  in the cluster, as well as the edges between two vertices both in the cluster.

  The difference between a cluster and a subgraph is that a cluster can also
  accept attributes to style the cluster, such as a border, background color,
  and custom label. These attributes can be passed as top-level attributes in
  the final keyword list argument to the function.

  ## Example

      iex> graph = Graph.new()
      iex> {graph, v1id} = Graph.add_vertex(graph, "start")
      iex> {graph, v2id} = Graph.add_vertex(graph, "end")
      iex> {_graph, cid} = Graph.add_cluster(
      ...>   graph, [v1id, v2id],
      ...>   color: "blue", label: "cluster0",
      ...>   node: [shape: "triangle"],
      ...>   edge: [style: "dotted"]
      ...> )
      iex> cid
      "cluster0"

  In `.dot` notation a cluster is specified, as opposed to a subgraph, by
  giving the cluster an ID that begins with `"cluster"` as seen in the example
  above. Contrast with `Graphvix.Graph.add_subgraph/3`.

  """
  def add_cluster(graph, vertex_ids, properties \\ []) do
    _add_subgraph(graph, vertex_ids, properties, true)
  end

  @doc """
  Add a vertex built from a `Graphvix.Record` to the graph.

      iex> graph = Graph.new()
      iex> record = Record.new(["a", "b", "c"])
      iex> {_graph, rid} = Graph.add_record(graph, record)
      iex> rid
      [:"$v" | 0]

      See `Graphvix.Record` for details on `Graphvix.Record.new/2`
      and the complete module API.
  """
  def add_record(graph, record) do
    label = Record.to_label(record)
    attributes = Keyword.put(record.properties, :shape, "record")
    add_vertex(graph, label, attributes)
  end

  @doc """
  Add a vertex built from a `Graphvix.HTMLRecord` to the graph.

      iex> graph = Graph.new()
      iex> record = HTMLRecord.new([
      ...>   HTMLRecord.tr([
      ...>     HTMLRecord.td("start"),
      ...>     HTMLRecord.td("middle"),
      ...>     HTMLRecord.td("end"),
      ...>   ])
      ...> ])
      iex> {_graph, rid} = Graph.add_html_record(graph, record)
      iex> rid
      [:"$v" | 0]

      See `Graphvix.HTMLRecord` for details on `Graphvix.HTMLRecord.new/2`
      and the complete module API.
  """
  def add_html_record(graph, record) do
    label = HTMLRecord.to_label(record)
    attributes = [shape: "plaintext"]
    add_vertex(graph, label, attributes)
  end

  @doc """
  Converts a graph to its representation using `.dot` syntax.

  ## Example

      iex> graph = Graph.new(node: [shape: "triangle"], edge: [color: "green"], graph: [size: "4x4"])
      iex> {graph, vid} = Graph.add_vertex(graph, "a")
      iex> {graph, vid2} = Graph.add_vertex(graph, "b")
      iex> {graph, vid3} = Graph.add_vertex(graph, "c")
      iex> {graph, eid} = Graph.add_edge(graph, vid, vid2)
      iex> {graph, eid2} = Graph.add_edge(graph, vid, vid3)
      iex> {graph, clusterid} = Graph.add_cluster(graph, [vid, vid2])
      iex> Graph.to_dot(graph)
      ~S(digraph G {

        size="4x4"

        node [shape="triange"]
        edge [color="green"]

        subgraph cluster0 {
          v0 [label="a"]
          v1 [label="b"]

          v0 -> v1
        }

        v2 [label="c"]

        v1 -> v2

      })

  For more expressive examples, see the `.ex` and `.dot` files in the `examples/` directory of
  Graphvix's source code.
  """
  def to_dot(graph) do
    [
      "digraph G {",
      graph_properties_to_dot(graph),
      global_properties_to_dot(graph),
      subgraphs_to_dot(graph),
      vertices_to_dot(graph),
      edges_to_dot(graph),
      "}"
    ] |> Enum.reject(&is_nil/1)
    |> Enum.join("\n\n")

  end

  @doc """
  Writes a `Graph` to a named file in `.dot` format

  ```
  iex> Graph.write(graph, "my_graph")
  ```

  will write a file named `"my_graph.dot"` to your current working directory.

  `filename` works as expected in Elixir. Filenames beginning with `/` define
  an absolute path on your file system. Filenames otherwise define a path relative
  to your current working directory.
  """
  def write(graph, filename) do
    File.write(filename <> ".dot", to_dot(graph))
  end

  @doc """
  Writes the graph to a `.dot` file and compiles it to the specified output
  format (defaults to `.png`).

  The following code creates the files `"graph_one.dot"` and `"graph_one.png"`
  in your current working directory.

  ```
  iex> Graph.compile(graph, "graph_one")
  ```

  This code creates the files `"graph_one.dot"` and `"graph_one.pdf"`.

  ```
  iex> Graph.compile(graph, "graph_one", :pdf)
  ```

  `filename` works as expected in Elixir. Filenames beginning with `/` define
  an absolute path on your file system. Filenames otherwise define a path relative
  to your current working directory.
  """
  def compile(graph, filename, format \\ :png) do
    :ok = write(graph, filename)
    {_, 0} = System.cmd("dot", [
      "-T", "#{format}", filename <> ".dot",
      "-o", filename <> ".#{format}"
    ])
    :ok
  end

  @doc """
  Write a graph to file, compile it, and open the resulting image in your
  system's default image viewer.

  The following code will write the contents of `graph` to `"graph_one.dot"`,
  compile the file to `"graph_one.png"` and open it.

  ```
  iex> Graph.show(graph, "graph_one")
  ```

  `filename` works as expected in Elixir. Filenames beginning with `/` define
  an absolute path on your file system. Filenames otherwise define a path relative
  to your current working directory.
  """
  def show(graph, filename) do
    :ok = write(graph, filename <> ".dot")
    :ok = compile(graph, filename)
    {_, 0} = System.cmd("open", [filename <> ".png"])
    :ok
  end

  @doc """
  Adds a top-level graph property.

  These attributes affect the overall layout of the graph at a high level.
  Use `set_global_properties/3` to modify the global styling for vertices
  and edges.

  ## Example

      iex> graph = Graph.new()
      iex> graph.graph_properties
      []
      iex> graph = Graph.set_graph_property(graph, :rank_direction, "RL")
      iex> graph.graph_properties
      [
        rank_direction: "RL"
      ]

  """
  def set_graph_property(graph, key, value) do
    new_properties = Keyword.put(graph.graph_properties, key, value)
    %{ graph | graph_properties: new_properties }
  end

  @doc """
  Sets a property for a vertex or edge that will apply to all vertices or edges
  in the graph.

  *NB* `:digraph` uses `vertex` to define the discrete points in
  a graph that are connected via edges, while Graphviz and DOT use the word
  `node`. `Graphvix` attempts to use "vertex" when the context is constructing
  the data for the graph, and "node" in the context of formatting and printing
  the graph.

  ## Example

  ```
  iex> graph = Graph.new()
  iex> {graph, vid} = Graph.add_vertex(graph, "label")
  iex> graph = Graph.set_global_property(graph, :node, shape: "triangle")
  ```

  When the graph is drawn, the vertex whose id is `vid`, and any other vertices
  added to the graph, will have a triangle shape.

  Global properties are overwritten by properties added by a subgraph or cluster:

  ```
  {graph, subgraph_id} = Graph.add_subgraph(graph, [vid], shape: "hexagon")
  ```

  Now when the graph is drawn the vertex `vid` will have a hexagon shape.

  Properties written directly to a vertex or edge have the highest priority
  of all. The vertex created below will have a circle shape despite the global
  property set on `graph`.

  ```
  {graph, vid2} = Graph.add_vertex(graph, "this is a circle!")
  ```

  """
  def set_global_properties(graph, attr_for, attrs \\ []) do
    Enum.reduce(attrs, graph, fn {k, v}, g ->
      _set_global_property(g, attr_for, [{k, v}])
    end)
  end

  ## PRIVATE

  defp _set_global_property(graph, attr_for, [{key, value}]) do
    properties = Keyword.get(graph.global_properties, attr_for)
    new_props = Keyword.put(properties, key, value)
    new_properties = Keyword.put(graph.global_properties, attr_for, new_props)
    %{ graph | global_properties: new_properties }
  end

  defp subgraphs_to_dot(graph) do
    case graph.subgraphs do
      [] -> nil
      subgraphs ->
        subgraphs
        |> Enum.map(&Graphvix.Subgraph.to_dot(&1, graph))
        |> Enum.join("\n\n")
    end
  end

  defp vertices_to_dot(graph) do
    [vtab, _, _] = digraph_tables(graph)
    elements_to_dot(vtab, fn {vid = [_ | id], attributes} ->
      case in_a_subgraph?(vid, graph) do
        true -> nil
        false ->
          [
            "v#{id}",
            attributes_to_dot(attributes)
          ] |> compact() |> Enum.join(" ") |> indent()
      end
    end)
  end

  defp edge_side_with_port(v_id, nil), do: "v#{v_id}"
  defp edge_side_with_port(v_id, port), do: "v#{v_id}:#{port}"

  defp edges_to_dot(graph) do
    [_, etab, _] = digraph_tables(graph)
    elements_to_dot(etab, fn edge = {_, [:"$v" | v1], [:"$v" | v2], attributes} ->
      case edge in edges_contained_in_subgraphs(graph) do
        true -> nil
        false ->
          v_out = edge_side_with_port(v1, Keyword.get(attributes, :outport))
          v_in = edge_side_with_port(v2, Keyword.get(attributes, :inport))
          attributes = attributes |> Keyword.delete(:outport) |> Keyword.delete(:inport)
          ["#{v_out} -> #{v_in}",
           attributes_to_dot(attributes)
          ] |> compact() |> Enum.join(" ") |> indent()
      end
    end)
  end

  defp get_and_increment_vertex_id(graph) do
    [_, _, ntab] = digraph_tables(graph)
    [{:"$vid", next_id}] = :ets.lookup(ntab, :"$vid")
    true = :ets.delete(ntab, :"$vid")
    true = :ets.insert(ntab, {:"$vid", next_id + 1})
    next_id
  end

  defp get_and_increment_subgraph_id(graph) do
    [_, _, ntab] = digraph_tables(graph)
    [{:"$sid", next_id}] = :ets.lookup(ntab, :"$sid")
    true = :ets.delete(ntab, :"$sid")
    true = :ets.insert(ntab, {:"$sid", next_id + 1})
    next_id
  end

  defp in_a_subgraph?(vertex_id, graph) do
    vertex_id in vertex_ids_in_subgraphs(graph)
  end

  defp vertex_ids_in_subgraphs(%__MODULE__{subgraphs: subgraphs}) do
    Enum.reduce(subgraphs, [], fn c, acc ->
      acc ++ c.vertex_ids
    end)
  end

  defp edges_contained_in_subgraphs(graph = %__MODULE__{subgraphs: subgraphs}) do
    [_, etab, _] = digraph_tables(graph)
    edges = :ets.tab2list(etab)
    Enum.filter(edges, fn {_, vid1, vid2, _} ->
      Enum.any?(subgraphs, fn subgraph ->
        Graphvix.Subgraph.both_vertices_in_subgraph?(subgraph.vertex_ids, vid1, vid2)
      end)
    end)
  end

  defp graph_properties_to_dot(%{graph_properties: []}), do: nil
  defp graph_properties_to_dot(%{graph_properties: properties}) do
    Enum.map(properties, fn {k, v} ->
      attribute_to_dot(k, v)
    end)
    |> Enum.join("\n") |> indent
  end

  defp _add_subgraph(graph, vertex_ids, properties, is_cluster) do
    next_id = get_and_increment_subgraph_id(graph)
    subgraph = Graphvix.Subgraph.new(next_id, vertex_ids, is_cluster, properties)
    new_graph = %{ graph | subgraphs: graph.subgraphs ++ [subgraph]}
    {new_graph, subgraph.id}
  end
end
