defmodule Benchmark do
  defp isa(variable, type) do
    isa(variable: variable, type: type)
  end

  defp isa(fields) do
    Retex.Fact.Isa.new(fields)
  end

  defp has_attribute(owner, attribute, predicate, value) do
    has_attribute(owner: owner, attribute: attribute, predicate: predicate, value: value)
  end

  defp has_attribute(fields) do
    Retex.Fact.HasAttribute.new(fields)
  end

  defp create_rule(lhs: given, rhs: action) do
    %{
      given: given,
      then: action
    }
  end

  defp rule(n, type \\ :Thing) do
    given = [
      isa(type, "$Account_#{n}"),
      has_attribute(type, :status, :==, "$a_#{n}"),
      has_attribute(type, :premium, :==, true)
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

    rules_100_000 =
      Enum.reduce(1..10_000, Retex.new(), fn n, network ->
        IO.inspect("Adding rule nr #{n}")
        Retex.add_production(network, rule(n))
      end)

    network = Retex.add_production(rules_100_000, rule(1, :Account))
    IO.inspect("Add wmes")

    network =
      network
      |> Retex.add_wme(wme)
      |> Retex.add_wme(wme_2)
      |> Retex.add_wme(wme_3)

    IO.inspect("Done adding wme")
    agenda = network.agenda

    agenda = %{
      "a9b34041bb1983d6c1ed33fc383ecd85b00b886c1b3be49ef01a9683237aa001" => [
        {:Account, :account_status, :silver}
      ]
    }
  end
end

Benchmark.run()
