defmodule RetexTest do
  use ExUnit.Case
  alias Retex.Facts
  import Facts
  doctest Retex

  defp create_rule(lhs: given, rhs: action) do
    %{
      given: given,
      then: action
    }
  end

  test "add a production with existing attributes" do
    given = [
      has_attribute(:Account, :status, :==, "silver"),
      has_attribute(:Account, :status, :!=, "outdated"),
      has_attribute(:Flight, :partner, :!=, true)
    ]

    action = [
      {:concession, 50}
    ]

    rule = create_rule(lhs: given, rhs: action)

    given_b = [
      has_attribute(:Account, :status, :==, "silver"),
      has_attribute(:Account, :status, :!=, "outdated"),
      has_attribute(:Family, :size, :>=, 12),
      has_attribute(:Flight, :partner, :!=, true)
    ]

    action_b = [
      {:concession, 110}
    ]

    rule_b = create_rule(lhs: given_b, rhs: action_b)

    network =
      Retex.new()
      |> Retex.add_production(rule)
      |> Retex.add_production(rule_b)

    assert 22 == Graph.edges(network.graph) |> Enum.count()
    assert 18 == Graph.vertices(network.graph) |> Enum.count()
  end

  test "can convert the graph to a flowchart (mermaid)" do
    given = [
      has_attribute(:Account, :status, :==, "silver"),
      has_attribute(:Account, :status, :!=, "outdated"),
      has_attribute(:Flight, :partner, :!=, true)
    ]

    action = fn something -> something end

    rule = create_rule(lhs: given, rhs: action)

    given_b = [
      has_attribute(:Account, :status, :==, "silver"),
      has_attribute(:Account, :status, :!=, "outdated"),
      has_attribute(:Family, :size, :>=, 12),
      has_attribute(:Flight, :partner, :!=, true)
    ]

    action_b = fn something -> something end

    rule_b = create_rule(lhs: given_b, rhs: action_b)

    assert {:ok, _chart} =
             Retex.new()
             |> Retex.add_production(rule)
             |> Retex.add_production(rule_b)
             |> Map.get(:graph)
             |> Serializer.serialize()
  end

  test "add a production where the then clause is a function" do
    given = [
      has_attribute(:Account, :status, :==, "silver"),
      has_attribute(:Account, :status, :!=, "outdated"),
      has_attribute(:Flight, :partner, :!=, true)
    ]

    action = fn something -> something end

    rule = create_rule(lhs: given, rhs: action)

    given_b = [
      has_attribute(:Account, :status, :==, "silver"),
      has_attribute(:Account, :status, :!=, "outdated"),
      has_attribute(:Family, :size, :>=, 12),
      has_attribute(:Flight, :partner, :!=, true)
    ]

    action_b = fn something -> something end

    rule_b = create_rule(lhs: given_b, rhs: action_b)

    network =
      Retex.new()
      |> Retex.add_production(rule)
      |> Retex.add_production(rule_b)

    assert 22 == Graph.edges(network.graph) |> Enum.count()
    assert 18 == Graph.vertices(network.graph) |> Enum.count()
  end

  test "add a production" do
    given = [
      has_attribute(:Account, :status, :==, "silver"),
      has_attribute(:Account, :status, :!=, "outdated"),
      has_attribute(:Flight, :partner, :!=, true)
    ]

    action = [
      {:concession, 50}
    ]

    rule = create_rule(lhs: given, rhs: action)

    network =
      Retex.new()
      |> Retex.add_production(rule)

    assert 12 == Graph.edges(network.graph) |> Enum.count()
    assert 11 == Graph.vertices(network.graph) |> Enum.count()
  end

  describe "add_wme/2" do
    test "apply inference with rules in which we use isa statements that doesnt match" do
      wme = Retex.Wme.new(:Account, :status, :silver)
      wme_2 = Retex.Wme.new(:Account, :premium, true)
      wme_3 = Retex.Wme.new(:Family, :size, 10)

      given = [
        isa("$thing", :AccountB),
        has_attribute("$thing", :status, :==, "$a"),
        has_attribute("$thing", :premium, :==, true)
      ]

      action = [
        {"$thing", :account_status, "$a"}
      ]

      rule = create_rule(lhs: given, rhs: action)

      network =
        Retex.new()
        |> Retex.add_production(rule)
        |> Retex.add_wme(wme)
        |> Retex.add_wme(wme_2)
        |> Retex.add_wme(wme_3)

      assert network.agenda == []
    end

    test "an activation of a negative node will deactivate its descendants" do
      given = [
        isa("$thing", :Thing),
        is_not("$entity", :Flight)
      ]

      action = [
        Retex.Wme.new(:Account, :id, 1)
      ]

      rule = create_rule(lhs: given, rhs: action)

      wme = Retex.Wme.new(:Thing, :status, :silver)
      wme_1 = Retex.Wme.new(:Flight, :status, :silver)

      network =
        Retex.new()
        |> Retex.add_production(rule)
        |> Retex.add_wme(wme)
        |> Retex.add_wme(wme_1)

      agenda = network.agenda |> Enum.map(&Map.get(&1, :action))

      assert [] == agenda
    end

    test "apply inference with a negated attribute, when the negative node is active" do
      given = [
        isa("$thing", :Thing),
        not_existing_attribute(:Thing, :status)
      ]

      action = [
        Retex.Wme.new(:Thing, :status, 1)
      ]

      rule = create_rule(lhs: given, rhs: action)

      wme = Retex.Wme.new(:Thing, :status, :gold)

      network =
        Retex.new()
        |> Retex.add_production(rule)
        |> Retex.add_wme(wme)

      agenda = network.agenda |> Enum.map(&Map.get(&1, :action))

      assert [] == agenda

      wme_1 = Retex.Wme.new(:Thing, :id, 1)
      network = Retex.add_wme(network, wme_1)
      agenda = network.agenda |> Enum.map(&Map.get(&1, :action))

      assert [] == agenda
    end

    test "apply inference with a negated attribute, when the negative node is not active" do
      given = [
        isa("$thing", :Thing),
        not_existing_attribute(:Thing, :status)
      ]

      action = [
        Retex.Wme.new(:Thing, :status, 1)
      ]

      rule = create_rule(lhs: given, rhs: action)

      wme = Retex.Wme.new(:Thing, :id, 1)

      network =
        Retex.new()
        |> Retex.add_production(rule)
        |> Retex.add_wme(wme)

      agenda = network.agenda |> Enum.map(&Map.get(&1, :action))

      assert [[%Retex.Wme{attribute: :status, identifier: :Thing, value: 1}]] = agenda

      wme_1 = Retex.Wme.new(:Thing, :status, :silver)
      network = Retex.add_wme(network, wme_1)
      agenda = network.agenda |> Enum.map(&Map.get(&1, :action))

      assert [] == agenda
    end

    test "apply inference with a negated condition, when the negative node is active" do
      given = [
        isa("$thing", :Thing),
        is_not("$entity", :Flight)
      ]

      action = [
        Retex.Wme.new(:Account, :id, 1)
      ]

      rule = create_rule(lhs: given, rhs: action)

      wme = Retex.Wme.new(:Flight, :status, :silver)
      wme_1 = Retex.Wme.new(:Thing, :status, :silver)

      network =
        Retex.new()
        |> Retex.add_production(rule)
        |> Retex.add_wme(wme)
        |> Retex.add_wme(wme_1)

      agenda = network.agenda |> Enum.map(&Map.get(&1, :action))

      assert [] == agenda
    end

    test "apply inference with a negated condition" do
      given = [
        isa("$thing", :Thing),
        is_not("$entity", :Flight)
      ]

      action = [
        Retex.Wme.new(:Account, :id, 1)
      ]

      rule = create_rule(lhs: given, rhs: action)

      wme = Retex.Wme.new(:Thing, :status, :silver)

      network =
        Retex.new()
        |> Retex.add_production(rule)
        |> Retex.add_wme(wme)

      agenda = network.agenda |> Enum.map(&Map.get(&1, :action))

      assert [
               [
                 %Retex.Wme{
                   attribute: :id,
                   timestamp: nil,
                   identifier: :Account,
                   value: 1
                 }
               ]
             ] = agenda
    end

    test "apply inference and replace variables in a WME" do
      given = [
        has_attribute(:Account, :status, :==, "$a"),
        has_attribute(:Account, :premium, :==, true)
      ]

      action = [
        Retex.Wme.new("$thing", :account_status, "$a")
      ]

      rule = create_rule(lhs: given, rhs: action)

      given_2 = [
        has_attribute(:AccountB, :status, :==, "$a_a"),
        has_attribute(:AccountB, :premium, :==, true)
      ]

      action_2 = [
        {"$thing_a", :account_status, "$a_a"}
      ]

      rule_2 = create_rule(lhs: given_2, rhs: action_2)

      given_3 = [
        has_attribute(:Account, :status, :==, "$a"),
        has_attribute(:Account, :premium, :==, true),
        has_attribute(:AccountB, :status, :==, "$a_a"),
        has_attribute(:AccountB, :premium, :==, true)
      ]

      action_3 = [
        {"$thing_3", :account_status, "$a_3"}
      ]

      rule_3 = create_rule(lhs: given_3, rhs: action_3)

      wme = Retex.Wme.new(:Account, :status, :silver)
      wme_2 = Retex.Wme.new(:Account, :premium, true)
      wme_3 = Retex.Wme.new(:Family, :size, 10)

      network =
        Retex.new()
        |> Retex.add_production(rule)
        |> Retex.add_production(rule_2)
        |> Retex.add_production(rule_3)
        |> Retex.add_wme(wme)
        |> Retex.add_wme(wme_2)
        |> Retex.add_wme(wme_3)

      agenda = network.agenda |> Enum.map(&Map.get(&1, :action))

      assert [
               [
                 %Retex.Wme{
                   attribute: :account_status,
                   timestamp: nil,
                   identifier: "$thing",
                   value: :silver
                 }
               ]
             ] = agenda

      wme_4 = Retex.Wme.new(:AccountB, :premium, true)
      wme_5 = Retex.Wme.new(:AccountB, :status, true)

      network =
        network
        |> Retex.add_wme(wme_4)
        |> Retex.add_wme(wme_5)

      agenda = network.agenda |> Enum.map(&Map.get(&1, :action)) |> Enum.count()

      assert 3 == agenda
    end

    test "return only the bindings of the fully activated rule" do
      given = [
        has_attribute(:Account, :status, :==, "$a"),
        has_attribute(:Account, :premium, :==, "$b"),
        has_attribute(:Account, :age, :==, "$a"),
        has_attribute(:Account, :age, :>, 21)
      ]

      action = [
        {:Account, :activated_1, "$a"}
      ]

      rule = create_rule(lhs: given, rhs: action)

      given_2 = [
        has_attribute(:Account, :status, :==, "$a"),
        filter("$a", :!==, :blue),
        has_attribute(:Account, :premium, :==, "$b"),
        has_attribute(:Account, :age, :>, 11)
      ]

      action_2 = [
        {:Account, :activated_2, "$a"}
      ]

      rule_2 = create_rule(lhs: given_2, rhs: action_2)

      wme = Retex.Wme.new(:Account, :status, :silver)
      wme_2 = Retex.Wme.new(:Account, :premium, true)
      wme_5 = Retex.Wme.new(:Account, :status, :blue)
      wme_3 = Retex.Wme.new(:Account, :age, 10)
      wme_4 = Retex.Wme.new(:Account, :status, :silver)

      network =
        Retex.new()
        |> Retex.add_production(rule)
        |> Retex.add_production(rule_2)
        |> Retex.add_wme(wme)
        |> Retex.add_wme(wme_2)
        |> Retex.add_wme(wme_3)
        |> Retex.add_wme(wme_4)
        |> Retex.add_wme(wme_5)

      agenda = network.agenda |> Enum.map(&Map.get(&1, :action))

      assert agenda == []

      triggering = Retex.Wme.new(:Account, :age, 20)

      network = Retex.add_wme(network, triggering)

      agenda = network.agenda |> Enum.map(&Map.take(&1, [:bindings]))

      assert agenda == [%{bindings: %{"$a" => :silver, "$b" => true}}]
    end

    test "apply inference with rules in which we use isa statements" do
      given = [
        has_attribute(:Account, :status, :==, "$a"),
        has_attribute(:Account, :premium, :==, true)
      ]

      action = [
        {"$thing", :account_status, "$a"}
      ]

      rule = create_rule(lhs: given, rhs: action)

      given_2 = [
        has_attribute(:AccountB, :status, :==, "$a_a"),
        has_attribute(:AccountB, :premium, :==, true)
      ]

      action_2 = [
        {"$thing_a", :account_status, "$a_a"}
      ]

      rule_2 = create_rule(lhs: given_2, rhs: action_2)

      wme = Retex.Wme.new(:Account, :status, :silver)
      wme_2 = Retex.Wme.new(:Account, :premium, true)
      wme_3 = Retex.Wme.new(:Family, :size, 10)

      network =
        Retex.new()
        |> Retex.add_production(rule)
        |> Retex.add_production(rule_2)
        |> Retex.add_wme(wme)
        |> Retex.add_wme(wme_2)
        |> Retex.add_wme(wme_3)

      agenda = network.agenda |> Enum.map(&Map.get(&1, :action))

      assert agenda == [[{"$thing", :account_status, :silver}]]
    end

    test "the bindings are returned upon node activation" do
      wme = Retex.Wme.new(:Account, :status, :silver)
      wme_2 = Retex.Wme.new(:Account, :premium, true)
      wme_3 = Retex.Wme.new(:Family, :size, 10)

      given = [
        has_attribute(:Account, :status, :==, "$a"),
        has_attribute(:Account, :premium, :==, true)
      ]

      action = [
        {"$thing", :account_status, "$a"}
      ]

      rule = create_rule(lhs: given, rhs: action)

      network =
        Retex.new()
        |> Retex.add_production(rule)
        |> Retex.add_wme(wme)
        |> Retex.add_wme(wme_2)
        |> Retex.add_wme(wme_3)

      agenda = network.agenda
      [pnode] = agenda
      assert pnode.bindings == %{"$a" => :silver}
    end

    test "apply inference with rules in which all elements are variables" do
      wme = Retex.Wme.new(:Account, :status, :silver)
      wme_2 = Retex.Wme.new(:Account, :premium, true)
      wme_3 = Retex.Wme.new(:Family, :size, 10)

      given = [
        has_attribute(:Account, :status, :==, "$a"),
        has_attribute(:Account, :premium, :==, true)
      ]

      action = [
        {"$thing", :account_status, "$a"}
      ]

      rule = create_rule(lhs: given, rhs: action)

      network =
        Retex.new()
        |> Retex.add_production(rule)
        |> Retex.add_wme(wme)
        |> Retex.add_wme(wme_2)
        |> Retex.add_wme(wme_3)

      agenda = network.agenda |> Enum.map(&Map.get(&1, :action))

      [pnodes] = agenda

      assert pnodes == [{"$thing", :account_status, :silver}]
    end

    test "apply inference with the use of variables as types" do
      wme = Retex.Wme.new(:Account, :status, :silver)
      wme_2 = Retex.Wme.new(:Account, :premium, false)
      wme_3 = Retex.Wme.new(:Family, :size, 10)

      given = [
        has_attribute(:Account, :status, :==, "$a"),
        has_attribute(:Account, :premium, :==, false),
        has_attribute(:Family, :size, :==, "$c")
      ]

      action = [
        {"$thing", :account_status, "$a"}
      ]

      rule = create_rule(lhs: given, rhs: action)

      network =
        Retex.new()
        |> Retex.add_production(rule)
        |> Retex.add_wme(wme)
        |> Retex.add_wme(wme_2)
        |> Retex.add_wme(wme_3)

      agenda = network.agenda |> Enum.map(&Map.get(&1, :action))
      assert agenda == [[{"$thing", :account_status, :silver}]]
    end

    test "apply inference with the use of variables and they DONT match" do
      wme = Retex.Wme.new(:Account, :status, :silver)
      wme_2 = Retex.Wme.new(:Family, :size, 10)

      given = [
        has_attribute(:Account, :status, :==, "$a"),
        has_attribute(:Family, :size, :==, "$a")
      ]

      action = [
        {:Flight, :account_status, "$a"}
      ]

      rule = create_rule(lhs: given, rhs: action)

      network =
        Retex.new()
        |> Retex.add_production(rule)
        |> Retex.add_wme(wme)
        |> Retex.add_wme(wme_2)

      agenda = network.agenda

      assert agenda == []
    end

    test "apply inference with the use of variables and they match" do
      wme = Retex.Wme.new(:Account, :status, :silver)
      wme_2 = Retex.Wme.new(:Family, :size, :silver)

      given = [
        has_attribute(:Account, :status, :==, "$a"),
        has_attribute(:Family, :size, :==, "$a")
      ]

      action = [
        {:Flight, :account_status, "$a"}
      ]

      rule = create_rule(lhs: given, rhs: action)

      network =
        Retex.new()
        |> Retex.add_production(rule)
        |> Retex.add_wme(wme)
        |> Retex.add_wme(wme_2)

      agenda = network.agenda |> Enum.map(&Map.get(&1, :action))

      assert ^agenda = [[{:Flight, :account_status, :silver}]]
    end

    test "tokens are created" do
      wme = Retex.Wme.new(:Account, :status, :silver)
      wme_2 = Retex.Wme.new(:Family, :size, :silver)

      given = [
        has_attribute(:Account, :status, :==, "$a"),
        has_attribute(:Family, :size, :==, "$a")
      ]

      action = [
        {:Flight, :account_status, "$a"}
      ]

      rule = create_rule(lhs: given, rhs: action)

      network =
        Retex.new()
        |> Retex.add_production(rule)
        |> Retex.add_wme(wme)
        |> Retex.add_wme(wme_2)

      agenda = network.agenda |> Enum.map(&Map.get(&1, :action))

      assert agenda == [
               [{:Flight, :account_status, :silver}]
             ]

      assert network.tokens !== nil
    end

    test "apply inference with the use of variables with two rules sharing var names and attribute names" do
      wme = Retex.Wme.new(:Account, :status, :silver)
      wme_2 = Retex.Wme.new(:Family, :size, 10)
      wme_4 = Retex.Wme.new(:Account, :status, 10)

      given = [
        has_attribute(:Account, :status, :==, "$a"),
        has_attribute(:Family, :size, :==, 10)
      ]

      action = [
        {:Flight, :account_status, "$a"}
      ]

      rule = create_rule(lhs: given, rhs: action)

      given_2 = [
        has_attribute(:Account, :status, :==, "$a"),
        has_attribute(:Family, :size, :==, "$a")
      ]

      action_2 = [
        {:Flight, :account_status_a, "$a"}
      ]

      rule_2 = create_rule(lhs: given_2, rhs: action_2)

      network =
        Retex.new()
        |> Retex.add_production(rule)
        |> Retex.add_production(rule_2)
        |> Retex.add_wme(wme)
        |> Retex.add_wme(wme_2)

      agenda = network.agenda |> Enum.map(&Map.get(&1, :action))

      assert agenda == [[{:Flight, :account_status, :silver}]]

      network =
        network
        |> Retex.add_wme(wme_4)

      agenda = network.agenda |> Enum.map(&Map.get(&1, :action)) |> Enum.sort()

      assert agenda == [
               [{:Flight, :account_status, 10}],
               [{:Flight, :account_status, :silver}],
               [{:Flight, :account_status_a, 10}]
             ]
    end

    test "apply inference with the use of variables with two rules sharing var names" do
      wme = Retex.Wme.new(:Account, :status, :silver)
      wme_2 = Retex.Wme.new(:Family, :size, 10)
      wme_3 = Retex.Wme.new(:Family, :size_a, 10)
      wme_4 = Retex.Wme.new(:Account, :status_a, 10)

      given = [
        has_attribute(:Account, :status, :==, "$a"),
        has_attribute(:Family, :size, :==, 10),
        has_attribute(:Account, :status, :!=, 10)
      ]

      action = [
        {:Flight, :account_status, "$a"}
      ]

      rule = create_rule(lhs: given, rhs: action)

      given_2 = [
        has_attribute(:Account, :status_a, :==, "$a"),
        has_attribute(:Family, :size_a, :==, "$a")
      ]

      action_2 = [
        {:Flight, :account_status_a, "$a"}
      ]

      rule_2 = create_rule(lhs: given_2, rhs: action_2)

      network =
        Retex.new()
        |> Retex.add_production(rule)
        |> Retex.add_production(rule_2)
        |> Retex.add_wme(wme)
        |> Retex.add_wme(wme_2)

      agenda = network.agenda |> Enum.map(&Map.get(&1, :action))

      assert agenda == [[{:Flight, :account_status, :silver}]]

      network =
        network
        |> Retex.add_wme(wme_3)
        |> Retex.add_wme(wme_4)

      agenda = network.agenda |> Enum.map(&Map.get(&1, :action))

      assert agenda == [
               [{:Flight, :account_status_a, 10}],
               [{:Flight, :account_status, :silver}]
             ]
    end

    test "apply inference with the use of variables" do
      wme = Retex.Wme.new(:Account, :status, :silver)
      wme_2 = Retex.Wme.new(:Family, :size, 10)

      given = [
        has_attribute(:Account, :status, :==, "$a"),
        has_attribute(:Family, :size, :==, 10)
      ]

      action = [
        {:Flight, :account_status, "$a"}
      ]

      rule = create_rule(lhs: given, rhs: action)

      network =
        Retex.new()
        |> Retex.add_production(rule)
        |> Retex.add_wme(wme)
        |> Retex.add_wme(wme_2)

      agenda = network.agenda |> Enum.map(&Map.get(&1, :action))
      assert agenda == [[{:Flight, :account_status, :silver}]]
    end

    test "add a new wme, trigger production" do
      wme = Retex.Wme.new(:Account, :status, :silver)

      given = [
        has_attribute(:Account, :status, :==, :silver)
      ]

      action = [
        {:Flight, :account_status, "silver"}
      ]

      rule = create_rule(lhs: given, rhs: action)

      network =
        Retex.new()
        |> Retex.add_production(rule)
        |> Retex.add_wme(wme)

      agenda = network.agenda |> Enum.map(&Map.get(&1, :action))

      assert agenda == [[{:Flight, :account_status, "silver"}]]
    end

    test "add a new wme" do
      wme = Retex.Wme.new(:Account, :status, "silver")

      network =
        Retex.new()
        |> Retex.add_wme(wme)

      assert network.wmes |> Enum.count() == 1
    end
  end
end
