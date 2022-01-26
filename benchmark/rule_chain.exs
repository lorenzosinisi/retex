Mix.install([
  {:retex, path: "./"},
  {:duration, "~> 0.1.0"},
  {:timex, "~> 3.7.6"}
])

defmodule Benchmark do
  alias Retex.Agenda

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

  def run(depth \\ 20000) do
    depth =
      case parse(System.argv()) do
        {[depth: depth], _, _} -> depth
        _ -> depth
      end

    rules = generate_rule_chain(depth)
    require Logger

    Logger.info("Adding #{depth} rules...")

    {time, rete_engine} =
      :timer.tc(fn ->
        Enum.reduce(rules, Retex.new(), fn rule, network ->
          Retex.add_production(network, rule)
        end)
      end)

    Graph.info(rete_engine.graph) |> inspect() |> Logger.info()
    Logger.info("Adding #{depth} rules took #{humanized_duration(time)}")

    wme = Retex.Wme.new("Thing_1", "attribute_1", 1)

    {time, rete_engine} = :timer.tc(fn -> Retex.add_wme(rete_engine, wme) end)

    Agenda.ExecuteOnce.consume_agenda([], rete_engine)

    Logger.info("Adding the working memory took #{humanized_duration(time)}")
  end

  defp parse(args) do
    OptionParser.parse(args, strict: [depth: :integer])
  end

  defp humanized_duration(time) do
    duration_in_seconds = time / 1_000_000

    duration_in_seconds
    |> Timex.Duration.from_seconds()
    |> Timex.Format.Duration.Formatter.format(:humanized)
  end
end

Benchmark.run()
