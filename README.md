# Retex

![Elixir CI](https://github.com/lorenzosinisi/retex/workflows/Elixir%20CI/badge.svg)

# The Rete Algorithm


"The Rete Match Algorithm is an efficient method for comparing a large collection of patterns to a large collection of objects. It finds all the objects that match each pattern. The algorithm was developed for use in production system interpreters, and it has been used for systems containing from a few hundred to more than a thousand patterns and objects" - C. Forgy

**Boilerplate/PoC of a version of the Rete Algorithm implementated in Elixir**

Rete is a complex stateful algorithm, this is an attempt of reproducing it with some slight modifications, using a functional immutable language such as Elixir/Erlang. [Read more about Rete](http://www.csl.sri.com/users/mwfong/Technical/RETE%20Match%20Algorithm%20-%20Forgy%20OCR.pdf)

## Requirements

- Erlang/OTP 24
- Elixir 1.14.2 (compiled with Erlang/OTP 22)


## How does it work?

The algorithm utilizes symbols to create an internal representation of the world. Each element in the real world is converted into a triple known as a "Working Memory Element" (WME), represented as {Entity, attribute, attribute_value}.

The world is represented through facts (WMEs) and Rules. A Rule consists of two essential parts: the "given" (right side) and the "then" (left side).

To perform inference, the rule generates a directed graph starting from a common and generic Root node, which branches out to form leaf nodes. The branches from the Root node correspond to the initial part of the WME, representing the working memory elements or "Entity". For instance, if we want to represent a customer's account status as "silver", we would encode it as "{Customer, account_status, silver}". Alternatively, with the use of a struct, we can achieve the same representation as Retex.Wme.new("Customer", "account status", "silver").

Now, let's explore how this would appear when compiling the rete algorithm with Retex:

```mermaid
 flowchart
    2332826675[==silver]
    3108351631[Root]
    3860425667[Customer]
    3895425755[account_status]
    3108351631 --> 3860425667
    3860425667 --> 3895425755
    3895425755 --> 2332826675
 ```
 **example nr. 1**

Now, let's examine the graph, which consists of four nodes in the following order:

1. The Root node
   1. This node serves as the root for all type nodes, such as Account, Customer, God, Table, and so on.
2. The Customer node
   1. Also known as a Type node, it stores each known "type" of entity recognized by the algorithm.
3. The account_status node
   1. Referred to as a Select node, it represents the attribute name of the entity being described.
4. the ==silver node
   1. Known as a Test node, it includes the == symbol, indicating that the value of Customer.account_status is checked against "silver" as a literal string (tests can use all Elixir comparison symbols). 


By expanding this network, we can continue mapping various aspects of the real world using any desired triple. Let's consider the entity representing a Flight, specifically its number of miles. We can represent this as {Flight, miles, 100} to signify a flight with a mileage of 100. Now, let's incorporate this into our network and observe the resulting graph:

Let's add this to our network and check what kind of graph we will get:

```mermaid
flowchart
    2102090852[==100]
    2332826675[==silver]
    3108351631[Root]
    3801762854[miles]
    3860425667[Customer]
    3895425755[account_status]
    4112061991[Flight]
    3108351631 --> 3860425667
    3108351631 --> 4112061991
    3801762854 --> 2102090852
    3860425667 --> 3895425755
    3895425755 --> 2332826675
    4112061991 --> 3801762854
```

**example nr. 2**

Now we begin to observe the modeling of more complex scenarios. Let's consider the addition of our first inference to the network, which involves introducing our first rule.

The rule we want to encode states that when the Customer's account_status is "silver" and the Flight's miles are exactly "100," we should apply a discount to the Customer entity.

Let's examine how our network will appear after incorporating this rule:

```mermaid
flowchart
    2102090852["==100"]
    2332826675["==silver"]
    2833714732["[{:Discount, :code, 50}]"]
    3108351631["Root"]
    3726656564["Join"]
    3801762854["miles"]
    3860425667["Customer"]
    3895425755["account_status"]
    4112061991["Flight"]
    2102090852 --> 3726656564
    2332826675 --> 3726656564
    3108351631 --> 3860425667
    3108351631 --> 4112061991
    3726656564 --> 2833714732
    3801762854 --> 2102090852
    3860425667 --> 3895425755
    3895425755 --> 2332826675
    4112061991 --> 3801762854
```


Now we have constructed our network, which possesses a symbolic representation of the world and describes the relationships between multiple entities and their values to trigger a rule. Notably, the last node in the graph is represented as {:Discount, :code, 50}.

Let's examine how we can interpret this graph step by step:

1. At the first level, we encounter the Root node, which serves as a placeholder.
2. At the second level, we find the Flight and Customer nodes branching out from the Root node. It's important to note that they are at the same level.
3. Both the Flight and Customer nodes branch out only once since they each have only one attribute.
4. Each attribute node (==100 and ==silver) branches out once again to indicate that if we encounter the attribute Customer.account_status, we should verify that its value is indeed "silver."
5. The last two nodes (==100 and ==silver) both connect to a new anonymous node called the Join node.
6. The Join node branches out only once, leading to the right-hand side of the rule (also known as the production node).

This structure of the graph allows us to represent and process complex relationships and conditions within our network.



## What are join nodes?

Join nodes are also what is called "beta memory" in the original C. Forgy paper. To make it simple we can assert that they group together a set of conditions that need to be true in order for a rule to fire. In our last example, the rule is:

```
# pseudocode
given: Flight.miles == 100 and Customer.account_status == "silver"
then: Discount.code == 50
```

In the graph representation, the Join node corresponds to the "and" in the "given" part of the rule. Its purpose is to evaluate and combine the conditions associated with its two parent nodes. Notably, a Join node can only have and will always have exactly two parents (incoming edges), which is a crucial characteristic of its design.

By utilizing Join nodes, the network is able to effectively represent complex conditions and evaluate them in order to trigger the corresponding rules.


## What are production nodes?

Production nodes, as named in the Forgy paper, refer to the right-hand side of a rule (also known as the "given" part). These nodes are exclusively connected to one incoming Join node in the network.

To clarify, the purpose of a production node is to represent the actions or outcomes specified by the rule. It captures the consequences that should occur when the conditions specified in the Join node's associated "given" part are met. This relationship ensures that the rule's right-hand side is only triggered when the conditions of the Join node are satisfied.

## How do we use all of that after we built the network?

Once we have a graph like the following and we know how to read it let's imagine we want to use to make inference and so to understand if we can give out
such discount code to our customer.

```mermaid
flowchart
    2102090852["==100"]
    2332826675["==silver"]
    2833714732["[{:Discount, :code, 50}]"]
    3108351631["Root"]
    3726656564["Join"]
    3801762854["miles"]
    3860425667["Customer"]
    3895425755["account_status"]
    4112061991["Flight"]
    2102090852 --> 3726656564
    2332826675 --> 3726656564
    3108351631 --> 3860425667
    3108351631 --> 4112061991
    3726656564 --> 2833714732
    3801762854 --> 2102090852
    3860425667 --> 3895425755
    3895425755 --> 2332826675
    4112061991 --> 3801762854
```

This process is called adding WMEs (working memory elements) to the network. As you might have already guessed there is very little difference between a WME and a part of a rule.

`Retex` exposes the function `Retex.add_wme(t(), Retex.Wme.t())` which takes the network itself and a WME struct and tries to activate as many nodes as possible traversing the graph from the Root until each reachable branch executing a series of "tests" at each node. Let's see step by step how it would work.

Let's rewrite that same graph adding some names to the edges so we can reference them in the description:

```mermaid
flowchart
    2102090852["==100"]
    2332826675["==silver"]
    2833714732["[{:Discount, :code, 50}]"]
    3108351631["Root"]
    3726656564["Join"]
    3801762854["miles"]
    3860425667["Customer"]
    3895425755["account_status"]
    4112061991["Flight"]
    2102090852 --a--> 3726656564
    2332826675 --b--> 3726656564
    3108351631 --c--> 3860425667
    3108351631 --d--> 4112061991
    3726656564 --e--> 2833714732
    3801762854 --f--> 2102090852
    3860425667 --g--> 3895425755
    3895425755 --h--> 2332826675
    4112061991 --i--> 3801762854
```

Let's see what happens when adding the following working memory element to the Retex algorithm `Retex.Wme.new(:Flight, :miles, 100`

1. Retex will receive the WME and start testing the network from the Root node which passes down anything as it doesn't test for anything
2. The `Root` branches out in `n` nodes (Flight and Customer)
   1. the branch `d` will find a type node with value "Flight" and this is the first part of the WME so the test is passing
      1. the next branch from `d` is `i` which connects Flight to `miles` and so we test that the second part of the triple is exactly `miles`: the test is passing again
         1. the next branch from `i` is `f` which finds a test node `== 100` which is the case of our new WME and so the test is passing
            1. next is `a` which connects to the `Join` node which needs to be tested: a test for a Join node asserts that all incoming connections are active (their test passed) and given that the branch `b` is not yet tested the traversal for now ends here and the Join remains only 50% activated
   2. the second branch to test is `c` which connects to `Customer` and this is not matching `Flight` so we can't go any further

After adding the WME `Retex.Wme.new(:Flight, :miles, 100)` the only active branches and nodes are d, i, f and a

Our rule can't be activated because the parent node `Join` is not fully active yet and so it can't propagate the current WME to the production node (which is sad but fair)


Let's see what happens when adding the following working memory element to the Retex algorithm `Retex.Wme.new(:Customer, :account_status, "silver")`

1. Retex will receive the WME and start testing the network from the Root node which passes down anything as it doesn't test for anything
2. The `Root` branches out in `n` nodes (Flight and Customer)
   1. the branch `c` will find a type node with value "Customer" and this is the first part of the WME so the test is passing
      1. the next branch from `c` is `g` which connects Customer to `account_status` and so we test that the second part of the triple is exactly `account_status`: the test is passing again
         1. the next branch from `h` finds a test node `== "silver"` which is the case of our new WME and so the test is passing
            1. next is `b` which connects to the `Join` node which needs to be tested: a test for a Join node asserts that all incoming connections are active (their test passed) and given that the branch `a` is also already active (we stored that in a map) we can continue the traversal
               1. Now we find a production node which tells us that the Discount code can be applied
   2. the second branch to test is `d` which doesn't match so we can stop the traversal

After adding the WME `Retex.Wme.new(:Customer, :account_status, "silver")` all nodes are active and so the production node ends up in the agenda (just an elixir list to keep track of all production nodes which are activated)

We have now done inference and found an applicable rule. All we need to do now is to add the new WME to the network to check if any other node can be activated in the same way.

Now imagine adding more and more complex rules and following the same strategy to find activable production nodes. The conditions will all be joined by a `Join` (and) node
and will point to a production.

## Concepts

- Retex compiles the rules using a directed acyclic graph data structure
- The activation of nodes is done using a [State Monad and Forward Chaining](https://www.researchgate.net/publication/303626297_Forward_Chaining_with_State_Monad).
- A list of bindings is stored at each active node in order to generate complete matches from partial ones

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

## Resources and documentation

- [Rete](https://cis.temple.edu/~giorgio/cis587/readings/rete.html)
- [Retex at ElixirConf EU](https://www.youtube.com/watch?v=pvi5hURNzbk&ab_channel=CodeSync)

References:

```
Rete: A Fast Algorithm for the Many Pattern/Many Object Pattern Match Problem* by
Charles L. Forgy
Department of Computer Science, Carnegie-Mellon University,
Pittsburgh, PA 15213, U.S.A.
```
