defmodule Retex.Why do
  @moduledoc """
  Why a rule was activated?

  Use this module passing the conclusion of a rule and it will tell you why it was activated
  """

  defstruct conclusion: nil, paths: []
  alias Retex.Node.PNode

  def explain(%Retex{graph: graph}, %PNode{} = conclusion) do
    conclusion = PNode.new(conclusion.raw_action)
    paths = Graph.get_paths(graph, Retex.root_vertex(), conclusion)
    %__MODULE__{paths: paths, conclusion: conclusion}
  end
end
