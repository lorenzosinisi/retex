defmodule Retex.Rule do
  import Retex.Facts
  defstruct [:given, :then]

  def new(given: given, then: then) do
    %__MODULE__{
      given: parse(given) |> interpret(),
      then: parse(then) |> interpret()
    }
  end

  def parse(str) do
    {:ok, ast} = Sanskrit.parse(str)
    ast
  end

  def interpret(ast) when is_list(ast) do
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
