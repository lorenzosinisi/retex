defmodule Benchmark do
  alias Retex.Agenda

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

  defp create_rule(lhs: given, rhs: action, id: id) do
    %{
      given: given,
      id: id,
      then: action
    }
  end

  def generate_rule_chain(depth) do
    for level <- 1..depth do
      given = [
        has_attribute("Thing_#{level}", "attribute_#{level}", :==, level),
        has_attribute("Thing_#{level}", "attribute_#{level}", :!=, false)
      ]

      then =
        if level + 1 >= depth do
          []
        else
          [Retex.Wme.new("Thing_#{level + 1}", "attribute_#{level + 1}", level + 1)]
        end

      create_rule(lhs: given, rhs: then, id: depth)
    end
  end

  def run(depth \\ 2000) do
    depth =
      case parse(System.argv()) do
        {[depth: depth], _, _} -> depth
        _ -> depth
      end

    rules = generate_rule_chain(depth)
    require Logger

    Logger.info("Adding #{depth} rules...")

    result =
      Timer.tc(fn ->
        Enum.reduce(rules, Retex.new(), fn rule, network ->
          Retex.add_production(network, rule)
        end)
      end)

    duration = result[:humanized_duration]
    network = result[:reply]
    Logger.info("Adding #{depth} rules took #{duration}")

    wme = Retex.Wme.new("Thing_1", "attribute_1", 1)

    result = Timer.tc(fn -> Retex.add_wme(network, wme) end)

    duration = result[:humanized_duration]
    network = result[:reply]

    {executed_rules, network} = Agenda.ExecuteOnce.consume_agenda([], network)

    Logger.info("Adding working memories took #{duration}")
  end

  defp parse(args) do
    OptionParser.parse(args, strict: [depth: :integer])
  end
end

Benchmark.run()
