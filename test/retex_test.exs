defmodule RetexTest do
  use ExUnit.Case
  alias Retex.Fact
  doctest Retex

  defp isa(variable, type) do
    isa(variable: variable, type: type)
  end

  defp isa(fields) do
    Fact.Isa.new(fields)
  end

  defp has_attribute(owner, attribute, predicate, value) do
    has_attribute(owner: owner, attribute: attribute, predicate: predicate, value: value)
  end

  defp has_attribute(fields) do
    Fact.HasAttribute.new(fields)
  end

  defp create_rule(lhs: given, rhs: action) do
    %{
      given: given,
      then: action
    }
  end

  test "add duplicated production, does not duplicate data" do
    given = [
      has_attribute(:Account, :status, :==, "silver"),
      has_attribute(:Account, :status, :!=, "outdated"),
      has_attribute(:Flight, :partner, :!=, true)
    ]

    action = [
      {:concession, 50}
    ]

    rule = create_rule(lhs: given, rhs: action)
    network = Retex.new()
    network = Retex.add_production(network, rule)
    Retex.add_production(network, rule)
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

    test "apply inference with rules in which we use isa statements" do
      given = [
        isa("$thing", :Account),
        has_attribute("$thing", :status, :==, "$a"),
        has_attribute("$thing", :premium, :==, true)
      ]

      action = [
        {"$thing", :account_status, "$a"}
      ]

      rule = create_rule(lhs: given, rhs: action)

      given_2 = [
        isa("$thing_a", :AccountB),
        has_attribute("$thing_a", :status, :==, "$a_a"),
        has_attribute("$thing_a", :premium, :==, true)
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

      assert network.agenda == [
               {"$thing", :account_status, :silver},
               {"$thing", :account_status, :silver}
             ]
    end

    test "apply inference with rules in which all elements are variables" do
      wme = Retex.Wme.new(:Account, :status, :silver)
      wme_2 = Retex.Wme.new(:Account, :premium, true)
      wme_3 = Retex.Wme.new(:Family, :size, 10)

      given = [
        isa("$thing", :Account),
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

      assert network.agenda == [
               {"$thing", :account_status, :silver},
               {"$thing", :account_status, :silver}
             ]
    end

    test "apply inference with the use of variables as types" do
      wme = Retex.Wme.new(:Account, :status, :silver)
      wme_2 = Retex.Wme.new(:Account, :premium, false)
      wme_3 = Retex.Wme.new(:Family, :size, 10)

      given = [
        isa("$thing", :Account),
        has_attribute("$thing", :status, :==, "$a"),
        has_attribute("$thing", :premium, :==, false),
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

      assert network.agenda == [{"$thing", :account_status, :silver}]
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

      assert network.agenda == []
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

      assert network.agenda == [
               {:Flight, :account_status, :silver}
             ]
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

      assert network.agenda == [
               {:Flight, :account_status, :silver}
             ]

      assert network.tokens !== nil
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

      assert network.agenda == [{:Flight, :account_status, :silver}]
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

      assert network.agenda == [{:Flight, :account_status, "silver"}]
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
