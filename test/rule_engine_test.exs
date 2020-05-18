defmodule Retex.RuleEngineTest do
  use ExUnit.Case
  alias Retex.{Rule, RuleEngine, Wme}
  import ExUnit.CaptureLog

  test "can be started" do
    assert Retex.RuleEngine.new("test")
  end

  test "rules can be added, and their conclusion can be a function call" do
    engine = RuleEngine.new("test")

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

    assert engine = RuleEngine.apply_rule(engine, rule)

    refute Enum.empty?(engine.rules_fired)
    assert function_rule = Enum.find(engine.rule_engine.agenda, fn pnode -> pnode.id == 2 end)

    assert capture_log(fn ->
             RuleEngine.apply_rule(engine, function_rule)
           end) =~ inspect(%{"$name" => "bob"})
  end

  test "rules can be added" do
    engine = RuleEngine.new("test")

    rules = [
      Rule.new(
        id: 1,
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

    assert engine = RuleEngine.apply_rule(engine, rule)
  end
end
