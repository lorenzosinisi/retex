defmodule Retex.WhyTest do
  use ExUnit.Case
  alias Retex.Facts
  import Facts
  alias Retex.{Why, Node}

  defp create_rule(lhs: given, rhs: action) do
    %{
      given: given,
      then: action
    }
  end

  test "two paths are activated in order to reach a conclusion" do
    given = [
      has_attribute(:Account, :status, :==, "$a"),
      has_attribute(:Family, :size, :==, "$a")
    ]

    action = [
      {:Flight, :account_status, "$a"}
    ]

    rule = create_rule(lhs: given, rhs: action)

    network = Retex.add_production(Retex.new(), rule)
    {pnode, _} = Node.PNode.new([{:Flight, :account_status, "$a"}])

    assert "It exists an entity of type Account, with status == $a; " <>
             "It exists an entity of type Family, with size == $a" =
             inspect(Why.explain(network, pnode))
  end
end
