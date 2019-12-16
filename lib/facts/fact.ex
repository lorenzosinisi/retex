defmodule Retex.Facts do
  @moduledoc false
  alias Retex.Fact

  def relation(from, name, to) do
    Fact.Relation.new(name: name, from: from, to: to)
  end

  def isa(variable, type) do
    isa(variable: variable, type: type)
  end

  def isa(fields) do
    Fact.Isa.new(fields)
  end

  def has_attribute(owner, attribute, predicate, value) do
    has_attribute(owner: owner, attribute: attribute, predicate: predicate, value: value)
  end

  def has_attribute(fields) do
    Fact.HasAttribute.new(fields)
  end
end
