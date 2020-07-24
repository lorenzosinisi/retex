# Retex

![Elixir CI](https://github.com/lorenzosinisi/retex/workflows/Elixir%20CI/badge.svg)

**Boilerplate/PoC of a version of the Rete Algorithm implementated in Elixir**

Rete is a complex stateful algorithm, this is an attempt of reproducing it with some slight modifications, using a functional immutable language such as Elixir/Erlang. [Read more about Rete](http://www.csl.sri.com/users/mwfong/Technical/RETE%20Match%20Algorithm%20-%20Forgy%20OCR.pdf)


## Concepts

- Retex compiles the rules using a directed acyclic graph data structure
- The activation of nodes is done using a [State Monad and Forward Chaining](https://www.researchgate.net/publication/303626297_Forward_Chaining_with_State_Monad).
- A list of bindinds is stored at each active node in order to generate complete matched from partial ones


## TODO

[ ] Optimize the amount of memory used by production nodes

[ ] Add tests for variables of the same name in different rules (it should work, right now it isnt)

[ ] Improve performances and extend the facts to handle more complex cases such as relationships between WMEs

# Example

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

- Use at your own risk
- This is just a template for complexer implementations of the described algorithms

## For more on Rete algorithm
- [Rete](https://cis.temple.edu/~giorgio/cis587/readings/rete.html)
