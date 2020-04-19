defmodule Retex.Facts do
  @moduledoc false
  @type t :: Fact.Relation.t() | Fact.Isa.t() | Fact.HasAttribute.t()
  alias Retex.Fact

  def relation(from, name, to) do
    Fact.Relation.new(name: name, from: from, to: to)
  end

  def isa(variable, type) do
    isa(variable: variable, type: type)
  end

  def is_not(variable, type) do
    is_not(variable: variable, type: type)
  end

  def filter(variable, predicate, value) do
    Fact.Filter.new(variable: variable, predicate: predicate, value: value)
  end

  def isa(fields) do
    Fact.Isa.new(fields)
  end

  def is_not(fields) do
    Fact.IsNot.new(fields)
  end

  def has_attribute(owner, attribute, predicate, value) do
    has_attribute(owner: owner, attribute: attribute, predicate: predicate, value: value)
  end

  def has_attribute(fields) do
    Fact.HasAttribute.new(fields)
  end

  def unexistant_attribute(owner, attribute) do
    unexistant_attribute(owner: owner, attribute: attribute)
  end

  def unexistant_attribute(fields) do
    Fact.UnexistantAttribute.new(fields)
  end
end
