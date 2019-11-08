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
    number_of_rules = 1000

    require Logger

    Logger.info("Adding #{number_of_rules} rules...")

    result =
      Timer.tc(fn ->
        Enum.reduce(1..number_of_rules, Retex.new(), fn n, network ->
          Retex.add_production(network, rule(n))
        end)
      end)

    duration = result[:humanized_duration]
    rules_100_000 = result[:reply]
    Logger.info("Adding #{number_of_rules} rules took #{duration}")

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

    result =
      Timer.tc(fn ->
        network
        |> Retex.add_wme(wme)
        |> Retex.add_wme(wme_2)
        |> Retex.add_wme(wme_3)
        |> Retex.add_wme(wme_4)
        |> Retex.add_wme(wme_5)
      end)

    duration = result[:humanized_duration]
    network = result[:reply]

    Logger.info(
      "Adding 6 working memories took #{duration} and matched #{Enum.count(network.agenda)} rules"
    )

    IO.inspect(agenda: network.agenda)
  end
end

Benchmark.run()
