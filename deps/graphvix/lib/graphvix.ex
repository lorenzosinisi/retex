defmodule Graphvix do
  @moduledoc """
  `Graphvix` provides an Elixir interface to [Graphviz](http://www.graphviz.org/)
  notation.

  With `Graphvix` you can iteratively construct directed graphs, save them to
  disk in `.dot` format, and print them.

  ### Create a new graph

      iex> graph = Graph.new(edge: [style: "dotted"])

  ### Add vertices

      iex> {graph, v1} = Graph.add_vertex(graph, "first vertex", color: "blue")
      iex> {graph, v2} = Graph.add_vertex(graph, "second vertex", color: "red")
      iex> {graph, v3} = Graph.add_vertex(graph, "hello", shape: "square")

  ### Add vertices with nested record structure

      iex> record = Graphvix.Record.new(row(["a", {"port_b", "b"}, col(["c", "d", "e"])]))
      iex> {graph, v4} = Graph.add_record(graph, record)

  ### Add vertices with HTML-style tables

      iex> html_record = Graphvix.HTMLRecord.new([tr([td("a", port: "port_a", colspan: 2)]), tr([td("b"), td(["c", br(), "d"])])])
      iex> {graph, v5} = Graph.add_record(graph, html_record)

  ### Group vertices into subgraphs and clusters

      iex> {graph, cluster1} = Graph.add_cluster(graph, [v1, v3, v5], style: "filled")

  ### Connect vertices and their ports with edges

      iex> {graph, e1} = Graph.add_edge(graph, v1, v2)
      iex> {graph, e2} = Graph.add_edge(graph, v1, {v4, "port_b"})
      iex> {graph, e3} = Graph.add_edge(graph, {v5, "port_a"}, v3, color: "red")


  ### Write the graph to a `.dot` file on your local filesystem

      iex> Graph.write(graph, "my_graph") #=> Creates `my_graph.dot`

  See the `Graphvix.Graph` documentation for more detailed usage examples.
  """
end
