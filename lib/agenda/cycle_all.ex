defmodule Retex.Agenda.CycleAll do
  @behaviour Retex.Agenda.Strategy
  @default_rule_executor Retex.RuleExecutor.Default
  def consume_agenda(executed_rules, %{agenda: [rule | rest] = _agenda} = network, opts \\ []) do
    executor = Keyword.get(opts, :rules_executor, @default_rule_executor)
    {rule_id, network} = executor.execute(rule, network)
    executed_rules = [rule_id] ++ executed_rules

    next_rules =
      network.agenda
      |> Enum.reject(fn pnode ->
        Enum.member?(executed_rules, pnode.id)
      end)

    network =
      if Enum.empty?(next_rules) do
        network
      else
        consume_agenda(executed_rules, %{network | agenda: next_rules ++ rest})
      end

    {executed_rules, network}
  end
end
