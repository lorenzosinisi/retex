defmodule Retex.Agenda.Strategy do
  @moduledoc false
  @type rules_executed :: List.t()
  @type network :: Retex.t()

  @callback consume_agenda(rules_executed, network) :: {:ok, {rules_executed, network}}
end
