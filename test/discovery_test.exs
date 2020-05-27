defmodule Retex.DiscoveryTest do
  use ExUnit.Case
  alias Retex.Facts
  import Facts
  alias Retex.Why

  defp create_rule(lhs: given, rhs: action) do
    %{
      given: given,
      then: action
    }
  end

  test "two paths are activated in order to reach a conclusion" do
    given = [
      has_attribute(:Account, :status, :==, "$a"),
      has_attribute(:Family, :size, :==, "$a")
    ]

    wme = Retex.Wme.new(:Account, :status, :ok)
    wme_2 = Retex.Wme.new(:Family, :size, :ok)

    action = [
      {:Flight, :account_status, "$a"}
    ]

    rule = create_rule(lhs: given, rhs: action)

    network =
      Retex.add_production(Retex.new(), rule) |> Retex.add_wme(wme) |> Retex.add_wme(wme_2)

    action = network.agenda |> List.first()

    assert 2 == Enum.count(Why.explain(network, action) |> Map.get(:paths))
  end
end
