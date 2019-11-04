# Graphvix

[![Build Status](https://travis-ci.org/mikowitz/graphvix.svg?branch=master)](https://travis-ci.org/mikowitz/graphvix)

Graphviz in Elixir

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

1. Add `graphvix` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:graphvix, "~> 1.0.0"}]
end
```

# Usage

See [the wiki](https://github.com/mikowitz/graphvix/wiki/Examples) for examples.

## API Overview

* Create a new graph

    `Graphvix.Graph.new/0`

* Add a vertex to a graph

    `Graphvix.Graph.add_vertex/2`
    `Graphvix.Graph.add_vertex/3`

* Add an edge between two vertices

    `Graphvix.Graph.add_edge/3`
    `Graphvix.Graph.add_edge/4`

* Create a vertex with type `record`

    `Graphvix.Record.new/1`
    `Graphvix.Record.new/2`

* Add a record vertex to a graph

    `Graphvix.Graph.add_record/2`

* Create a vertex using HTML table markup

    `Graphvix.HTMLRecord.new/1`
    `Graphvix.HTMLRecord.new/2`

* Add an HTML table vertex to a graph

    `Graphvix.Graph.add_html_record/2`

* Save a graph to disk in `.dot` format

    `Graphvix.Graph.write/2`

* Save and compile a graph (defaults to `.png`)

    `Graphvix.Graph.compile/2`
    `Graphvix.Graph.compile/3`

* Save, compile and open a graph (defaults to `.png` and your OS's default image viewer)

    `Graphvix.Graph.graph/2`
    `Graphvix.Graph.graph/3`

## Basic Usage

1. Alias the necessary module for ease of use

    ```elixir
    alias Graphvix.Graph
    ```

1. Create a new graph.

    ```elixir
    graph = Graph.new()
    ```

1. Add a simple vertex with a label

    ```elixir
    {graph, vertex_id} = Graph.add_vertex(graph, "vertex label")
    ```

1. Add a vertex with a label and attributes

    ```elixir
    {graph, vertex2_id} = Graph.add_vertex(
      graph,
      "my other vertex",
      color: "blue", shape: "diamond"
    )
    ```

1. Add an edge between two existing vertices

    ```elixir
    {graph, edge_id} = Graph.add_edge(
      graph,
      vertex_id, vertex2_id,
      label: "Edge", color: "green"
    )
    ```

1. Add a cluster containing one or more nodes

    ```elixir
    {graph, cluster_id} = Graph.add_cluster(graph, [vertex_id, vertex2_id])
    ```

## Records

1. Alias the necessary module for ease of use

    ```elixir
    alias Graphvix.Record
    ```

1. Create a simple record that contains only a row of cells

    ```elixir
    record = Record.new(Record.row(["a", "b", "c"]))
    ```

    * A record with a top-level row can also be created by just passing a list

      ```elixir
      record = Record.new(["a", "b", "c"])
      ```
1. Create a record with a single column of cells

    ```elixir
    record = Record.new(Record.column(["a", "b", "c"]))
    ```

1. Create a record with nested rows and columns

    ```elixir
    import Graphvix.Record, only: [column: 1, row: 1]

    record = Record.new(row([
      "a",
      column([
        "b",
        row(["c", "d", "e"]),
        "f"
      ]),
      "g"
    ])
    ```

### Ports

1. Ports can be attached to record cells by passing a tuple of `{port_name, label}`

    ```elixir
    import Graphvix.Record, only: [column: 1, row: 1]

    record = Record.new(row([
      {"port_a", "a"},
      column([
        "b",
        row(["c", {"port_d", "d"}, "e"]),
        "f"
      ]),
      "g"
    ])
    ```

1. Edges can be drawn from specific ports on a record

    ```elixir
    {graph, record_id} = Graph.add_record(graph, record)

    {graph, _edge_id} = Graph.add_edge({record_id, "port_a"}, vertex_id)

    ```

## HTML Table Records

1. Alias the necessary modules for ease of use

    ```elixir
    alias Graphvix.HTMLRecord
    ```

1. Create a simple table

    ```elixir
    record = HTMLRecord.new([
      tr([
        td("a"),
        td("b"),
        td("c")
      ]),
      tr([
        td("d", port: "port_d"),
        td("e"),
        td("f")
      ])
    ])
    ```

1. Or a more complex table

    ```elixir
    record = HTMLRecord.new([
      tr([
        td("a", rowspan: 3),
        td("b", colspan: 2),
        td("f", rowspan: 3)
      ]),
      tr([
        td("c"),
        td("d")
      ])
      tr([
        td("e", colspan: 2)
      ])
    ])
    ```

Cells can also use the `font/2` and `br/0` helper methods to add font styling and forced line breaks. See
the documentation for `Graphvix.HTMLRecord` for examples.

## Output

1. Convert the graph to DOT format

    ```elixir
    Graph.to_dot(graph)
    """
    digraph G {
      cluster c0 {
        v0 [label="vertex label"]
        v1 [label="my other vertex",color="blue",shape="diamond"]

        v0 -> v1 [label="Edge",color="green"]
      }
    }
    """
    ```
1. Save the graph to a .dot file, with an optional filename

    ```elixir
    Graph.write(graph, "first_graph") #=> creates "first_graph.dot"
    ```

1. Compile the graph to a .png or .pdf using the `dot` command

    ```elixir
    ## creates first_graph.dot and first_graph.png
    Graph.compile(graph, "first_graph")

    ## creates first_graph.dot and first_graph.pdf
    Graph.compile(graph, "first_graph", :pdf)
    ```

1. Compile the graph using the `dot` command and open the resulting file

    ```elixir
    ## creates first_graph.dot and first_graph.pdf; opens first_graph.png
    Graph.graph(graph, "first_graph")

    ## creates first_graph.dot and first_graph.pdf; opens first_graph.pdf
    Graph.graph(graph, "first_graph", :pdf)
    ```

