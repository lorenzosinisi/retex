defmodule Retex.RuleExecutor.Default do
  @behaviour Retex.RuleExecutorBehaviour

  def execute(rule, network), do: execute_rule(rule, network)

  defp execute_rule(%{id: id, raw_action: raw_action} = _rule, network) do
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
