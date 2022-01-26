# Retex

![Elixir CI](https://github.com/lorenzosinisi/retex/workflows/Elixir%20CI/badge.svg)

# The Rete Algorithm

"The Rete Match Algorithm is an efficient method for comparing a large collection of patterns to a large
collection of objects. Itfinds all the objects that match eachpattern. The algorithm was developedfor use in
production system interpreters, and it has been used for systems containing from a few hundred to more
than a thousand patterns and objects. This article presents the algorithm in detail. It explains the basic
concepts of the algorithm, it describes pattern and object representations that are appropriate for the
algorithm, and it describes the operations performed by the pattern matcher." - C. Forgy

**Boilerplate/PoC of a version of the Rete Algorithm implementated in Elixir**

Rete is a complex stateful algorithm, this is an attempt of reproducing it with some slight modifications, using a functional immutable language such as Elixir/Erlang. [Read more about Rete](http://www.csl.sri.com/users/mwfong/Technical/RETE%20Match%20Algorithm%20-%20Forgy%20OCR.pdf)

## Requirements

- Erlang/OTP 22
- Elixir 1.12.1 (compiled with Erlang/OTP 22)

## Concepts

- Retex compiles the rules using a directed acyclic graph data structure
- The activation of nodes is done using a [State Monad and Forward Chaining](https://www.researchgate.net/publication/303626297_Forward_Chaining_with_State_Monad).
- A list of bindinds is stored at each active node in order to generate complete matches from partial ones

## Installation

```elixir
def deps do
  [
    {:retex, git: "https://github.com/lorenzosinisi/retex"}
  ]
end
```

## Installation using the wrapper NeuralBridge

If you want you can have a predefined generic DSL and the wrapper NeuralBridge so that you don't have to build the rest of the Expert System from zero

```elixir
def deps do
  [
    {:neural_bridge, git: "https://github.com/lorenzosinisi/neural_bridge"}
  ]
end
```

## Examples and usage with NeuralBridge (a wrapper around Retex)

### Generic inferred knowledge

```elixir
    alias NeuralBridge.{Engine, Rule}
    engine = Engine.new("test")

    rules = [
      Rule.new(
        id: 1,
        given: """
        Person's name is equal "bob"
        """,
        then: """
        Person's age is 23
        """
      ),
      Rule.new(
        id: 2,
        given: """
        Person's name is equal $name
        Person's age is equal 23
        """,
        then: fn production ->
          require Logger
          bindings = Map.get(production, :bindings)
          Logger.info(inspect(bindings))
        end
      )
    ]

    engine = Engine.add_rules(engine, rules)
    engine = Engine.add_facts(engine, "Person's name is \"bob\"")
    rule = List.first(engine.rule_engine.agenda)
    engine = Engine.apply_rule(engine, rule)

    Enum.each(engine.rule_engine.agenda, fn pnode ->
        Engine.apply_rule(engine, pnode)
        end)
    end # will log %{"$name" => "bob"}

```

### Medical diagnosis

```elixir
    alias NeuralBridge.{Engine, Rule}
    engine = Engine.new("doctor_AI")

    engine =
      Engine.add_rules(engine, [
        Rule.new(
          id: 1,
          given: """
          Patient's fever is greater 38.5
          Patient's name is equal $name
          Patient's generic_weakness is equal "Yes"
          """,
          then: """
          Patient's diagnosis is "flu"
          """
        ),
        Rule.new(
          id: 2,
          given: """
          Patient's fever is lesser 38.5
          Patient's name is equal $name
          Patient's generic_weakness is equal "No"
          """,
          then: """
          Patient's diagnosis is "all good"
          """
        )
      ])

    engine =
      Engine.add_facts(engine, """
      Patient's fever is 39
      Patient's name is "Aylon"
      Patient's generic_weakness is "Yes"
      """)

    ## contains Patient's diagnnosis
    [
      %_{
        action: [
          %Retex.Wme{
            identifier: "Patient",
            attribute: "diagnosis",
            value: "flu"
          }
        ],
        bindings: %{"$name" => "Aylon"}
      }
    ] = engine.rule_engine.agenda

```

## Test

- Run `mix test`

## Benchmark adding 20k rules and triggering one

- Run `elixir benchmark/rule_chain.exs`

## Warnings

- Use at your own risk
- This is just a template for complexer implementations of the described algorithms

## For more on Rete algorithm

- [Rete](https://cis.temple.edu/~giorgio/cis587/readings/rete.html)
