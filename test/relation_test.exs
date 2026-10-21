defmodule Retex.RelationTest do
  use ExUnit.Case
  import Retex.Facts

  test "relation condition matches a WME triple" do
    rule = %{
      given: [relation(:Customer, :bought, :Flight)],
      then: [{:Customer, :owns, :Flight}]
    }

    network =
      Retex.new()
      |> Retex.add_production(rule)
      |> Retex.add_wme(Retex.Wme.new(:Customer, :bought, :Flight))

    assert [[{:Customer, :owns, :Flight}]] =
             Enum.map(network.agenda, & &1.action)
  end

  test "relation condition rejects triples with any mismatched part" do
    rule = %{
      given: [relation(:Customer, :bought, :Flight)],
      then: [{:Customer, :owns, :Flight}]
    }

    network =
      Retex.new()
      |> Retex.add_production(rule)
      |> Retex.add_wme(Retex.Wme.new(:Supplier, :bought, :Flight))
      |> Retex.add_wme(Retex.Wme.new(:Customer, :sold, :Flight))
      |> Retex.add_wme(Retex.Wme.new(:Customer, :bought, :Train))

    assert network.agenda == []
  end

  test "relation condition binds variables in all three parts" do
    rule = %{
      given: [relation("$buyer", "$verb", "$item")],
      then: [{"$buyer", "$verb", "$item"}]
    }

    network =
      Retex.new()
      |> Retex.add_production(rule)
      |> Retex.add_wme(Retex.Wme.new(:Customer, :bought, :Flight))

    assert [[{:Customer, :bought, :Flight}]] =
             Enum.map(network.agenda, & &1.action)
  end

  test "joined relation conditions require shared variable values to agree" do
    rule = %{
      given: [
        relation("$buyer", :bought, "$item"),
        relation("$buyer", :owns, "$item")
      ],
      then: [{"$buyer", :owns, "$item"}]
    }

    mismatching_network =
      Retex.new()
      |> Retex.add_production(rule)
      |> Retex.add_wme(Retex.Wme.new(:Customer, :bought, :Flight))
      |> Retex.add_wme(Retex.Wme.new(:Supplier, :owns, :Flight))

    assert mismatching_network.agenda == []

    matching_network =
      mismatching_network
      |> Retex.add_wme(Retex.Wme.new(:Customer, :owns, :Flight))

    assert [[{:Customer, :owns, :Flight}]] =
             Enum.map(matching_network.agenda, & &1.action)
  end
end
