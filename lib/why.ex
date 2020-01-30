defmodule Retex.Why do
  @moduledoc """
  Why a rule was activated?

  Use this module passing the conclusion of a rule and it will tell you why it was activated
  """

  defstruct conclusion: nil, paths: []
  alias Retex.Node.PNode

  def explain(%Retex{graph: graph}, %PNode{} = conclusion) do
    {conclusion, _} = PNode.new(conclusion.raw_action)
    paths = Graph.get_paths(graph, Retex.root_vertex(), conclusion)
    %__MODULE__{paths: paths, conclusion: conclusion}
  end

  defimpl Inspect do
    def inspect(%{paths: paths}, _) do
      Enum.reduce(paths, [], fn path, acc ->
        [
          Enum.reduce(path, "", fn node, local_explanation ->
            local_explanation <> node_to_string(node)
          end)
          | acc
        ]
      end)
      |> Enum.join("; ")
    end

    defp node_to_string(%Retex.Node.Type{class: class}) do
      "It exists an entity of type #{class}, "
    end

    defp node_to_string(%Retex.Node.Select{class: class}) do
      "with #{class}"
    end

    defp node_to_string(%Retex.Node.Test{class: [operator, class]}) do
      " #{operator} #{class}"
    end

    defp node_to_string(%{}) do
      ""
    end
  end
end
