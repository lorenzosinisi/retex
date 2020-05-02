# Retex

![Elixir CI](https://github.com/lorenzosinisi/retex/workflows/Elixir%20CI/badge.svg)

**Boilerplate/PoC of the Rete Algorithm implementated in Elixir**

Rete is a complex stateful algorithm, this is an attempt of reproducing it with a functional immutable language
such as Elixir/Erlang. This is a boilerplate that will let you implement your own version of Rete starting from a baseline.

Feel free to contact me via email if you have any question. One example of usage of Retex can be found in [NeuralBridge](https://github.com/lorenzosinisi/neural_bridge)

## Concepts

- Retex compiles the rules using `libgraph` (A graph data structure library for Elixir projects)
- The activation of nodes is done using a `Map.reduce` over each node and activating them
using the `Activation` protocol. Each type of node implements its own protocol for the activation
- When a node is activated, a map is updated adding its ID to the list of activated nodes in the Retex state
- A list of bindinds is passed along each iteration of the reduction on the graph and updated/checked depending on each implementation of the Activation protocol that the current node has


## TODO

- Each production node should be visited only once
- Add tests for variables of the same name in different rules (it should work, right now it isnt)
- Improve performances and extend the facts to handle more complex cases such as relationships between WMEs

# Benchmark/Example

clone the project and run `mix run benchmark/example.exs --no-mix-exs`

The example adds 100_000 conditions and only one triggers a new inference with 6 working memory elements

You will see something like the following:

```
13:36:55.036 [info]  Adding 100000 rules took 42 seconds, 508.98 milliseconds

13:36:55.432 [info]  Network info %{num_edges: 400000, num_vertices: 299996, size_in_bytes: 278404360, type: :directed}
[agenda: [[{"$thing", :account_status, :silver}]]]

13:36:55.439 [info]  Adding 6 working memories took 7.034 milliseconds and matched 1 rule
```

The code: 

```
  ...
  defp rule(n, type \\ :Thing) do
    given = [
      has_attribute(:Thing, :status, :==, "$a_#{n}"),
      has_attribute(:Thing, :premium, :==, true)
    ]

    action = [
      {"$thing_#{n}", :account_status, "$a_#{n}"}
    ]

    rule = create_rule(lhs: given, rhs: action)
  end

  def run() do
    wme = Retex.Wme.new(:Account, :status, :silver)
    wme_2 = Retex.Wme.new(:Account, :premium, true)
    wme_3 = Retex.Wme.new(:Family, :size, 10)

    wme_4 = Retex.Wme.new(:Account, :status, :silver)
    wme_5 = Retex.Wme.new(:AccountC, :status, :silver)
    wme_5 = Retex.Wme.new(:AccountD, :status, :silver)
    number_of_rules = 100_000

    require Logger

    Logger.info("Adding #{number_of_rules} rules...")
   
    # rules that will not match
    result =
      Timer.tc(fn ->
        Enum.reduce(1..number_of_rules, Retex.new(), fn n, network ->
          Retex.add_production(network, rule(n))
        end)
      end)

    duration = result[:humanized_duration]
    rules_100_000 = result[:reply]
    Logger.info("Adding #{number_of_rules} rules took #{duration}")
   
    # A rule that will match 
    given_matching = [
      has_attribute(:Account, :status, :==, "$account"),
      has_attribute(:Account, :premium, :==, true)
    ]

    action_2 = [
      {"$thing", :account_status, "$account"}
    ]

    rule = create_rule(lhs: given_matching, rhs: action_2)
    network = Retex.add_production(rules_100_000, rule)

    Logger.info("Network info #{Graph.info(rules_100_000.graph) |> inspect()}")

    # feed knowledge to the engine
    result =
      Timer.tc(fn ->
        network
        |> Retex.add_wme(wme)
        |> Retex.add_wme(wme_2)
        |> Retex.add_wme(wme_3)
        |> Retex.add_wme(wme_4)
        |> Retex.add_wme(wme_5)
      end)
     ...
```

## Warnings

- So far it works very little and only in some cases, needs more testing and a better way to handle variable bindings
- This is just a WIP and a PoC, do not use it in production but feel free to contribute with ideas and PRs
- Use it as boilerplate and starting point to continue your own personal implementation (more facts, DSL, etc)

## For more on Rete algorithm
- https://cis.temple.edu/~giorgio/cis587/readings/rete.html
