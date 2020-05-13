defmodule Retex.RuleEngineTest do
  use ExUnit.Case
  alias Retex.{Rule, RuleEngine, Wme}

  test "can be started" do
    assert Retex.RuleEngine.new("test")
  end

  test "rules can be added" do
    engine = RuleEngine.new("test")

    rules = [
      Rule.new(
        given: """
        Person's name is equal "bob"
        """,
        then: """
        Person's age is 23
        """
      )
    ]

    engine = RuleEngine.add_rules(engine, rules)
    assert Enum.empty?(engine.rule_engine.agenda)

    engine = RuleEngine.add_facts(engine, Wme.new("Person", "name", "bob"))

    rule = List.first(engine.rule_engine.agenda)

    assert Enum.empty?(engine.rules_fired)

    assert %Retex.Node.PNode{
             action: [
               %Retex.Wme{
                 attribute: "age",
                 id: _,
                 identifier: "Person",
                 timestamp: nil,
                 value: 23
               }
             ]
           } = rule

    engine = RuleEngine.apply_rule(engine, rule)

    refute Enum.empty?(engine.rules_fired)
  end
end
