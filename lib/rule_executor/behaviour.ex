defmodule Retex.RuleExecutorBehaviour do
  @type rule_id :: String.t()
  @type rule :: %{id: String.t(), raw_action: any()}
  @type network :: Retex.t()
  @callback execute(rule, network) :: {rule_id(), network}
end
