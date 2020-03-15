defmodule Retex.Agenda.ExecuteOnce do
  @behaviour Retex.Agenda.Strategy
  def consume_agenda(executed_rules, %{agenda: [rule | rest] = _agenda} = network) do
    {rule_id, network} = execute_rule(rule, network)

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

  def execute_rule(%{id: id, raw_action: raw_action} = _rule, network) do
    new_network =
      Enum.reduce(raw_action, network, fn action, network ->
        do_execute_action(action, network)
      end)

    {id, new_network}
  end

  defp do_execute_action(%Retex.Wme{} = wme, network) do
    Retex.add_wme(network, wme)
  end
end
