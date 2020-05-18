defmodule Retex.Rule do
  import Retex.Facts
  defstruct [:id, :given, :then]

  def new(id: id, given: given, then: then) when is_binary(given) and is_binary(then) do
    with {:ok, given} <- to_production(given),
         {:ok, then} <- to_production(then) do
      %__MODULE__{id: id, given: given, then: then}
    end
  end

  def new(id: id, given: given, then: then) when is_binary(given) and is_function(then) do
    with {:ok, given} <- to_production(given) do
      %__MODULE__{id: id, given: given, then: then}
    end
  end

  defp to_production(conditions) when is_binary(conditions) do
    with {:ok, ast} <- parse(conditions) do
      {:ok, interpret(ast)}
    end
  end

  defp parse(str) do
    Sanskrit.parse(str)
  end

  defp interpret(ast) when is_list(ast) do
    for node <- ast, do: do_interpret(node)
  end

  defp do_interpret({:filter, type, kind, value}) do
    filter(type, kind, value)
  end

  defp do_interpret({:unexistant_attribute, type, attr}) do
    unexistant_attribute(type, attr)
  end

  defp do_interpret({:negation, variable, type}) do
    is_not(variable, type)
  end

  defp do_interpret({:wme, type, attr, value}) do
    Retex.Wme.new(type, attr, value)
  end

  defp do_interpret({:isa, var, type}) do
    isa(var, type)
  end

  defp do_interpret({:has_attribute, type, attr, kind, value}) do
    has_attribute(type, attr, kind, value)
  end
end
