defmodule Retex do
  @moduledoc false
  alias Retex.{Node, Protocol, Fact, Token}

  defstruct graph: Graph.new(),
            wmes: %{},
            agenda: [],
            activations: %{},
            wme_activations: %{},
            tokens: %{},
            bindings: %{},
            pending_activation: []

  def root_vertex(), do: Retex.Root.new()

  def new() do
    %{graph: graph} = %Retex{}
    graph = Graph.add_vertex(graph, Retex.Root.new())
    %Retex{graph: graph}
  end

  def add_wme(%Retex{} = network, %Retex.Wme{} = wme) do
    network = %{network | wmes: Map.put(network.wmes, wme.id, wme)}
    {network, bindings} = propagate_activations(network, root_vertex(), wme, network.bindings)
    %{network | bindings: Map.merge(network.bindings, bindings)}
  end

  def get_current_bindings(neighbor, bindings) do
    Map.get(bindings, %{})
  end

  def previous_match(current_bindings, key, value) do
    Map.get(current_bindings, key, value)
  end

  def compile_given(_acc, []), do: []

  def compile_given(acc, conditions) do
    {_, new_conditions} =
      Enum.reduce(conditions, {acc, []}, fn condition, {acc, conds} ->
        case condition do
          %Fact.Isa{type: type, variable: variable} = condition ->
            acc = Map.put_new(acc, variable, type)
            {acc, [condition | conds]}

          %Fact.HasAttribute{owner: "$" <> _variable_name = var} = condition ->
            type = Map.get(acc, var) || raise("#{var} is not defined")
            {acc, [%{condition | owner: type} | conds]}

          condition ->
            {acc, [condition | conds]}
        end
      end)

    new_conditions
  end

  def update_bindings(current_bindings, bindings, %_{} = neighbor, %{} = map) do
    new_bindings = current_bindings |> Map.merge(map)
    Map.put(bindings, new_bindings)
  end

  def update_bindings(current_bindings, bindings, %{} = neighbor, key, value) do
    new_bindings = current_bindings || %{} |> Map.put_new(key, value)
    Map.merge(bindings, new_bindings)
  end

  defp propagate_activation(neighbor, rete, wme, bindings, tokens \\ []) do
    Protocol.Activation.activate(neighbor, rete, wme, bindings, tokens)
  end

  def add_production(%{graph: graph} = network, %{given: given, then: action}) do
    given = compile_given(%{}, given)

    {graph, alphas} =
      given |> Enum.reverse() |> Enum.reduce({graph, []}, &build_alpha_network(&1, &2))

    {beta_memory, graph} = build_beta_network(graph, alphas)
    graph = add_p_node(graph, beta_memory, action)
    %{network | graph: graph}
  end

  def build_beta_network(graph, disjoint_beta_network) do
    create_beta_nodes(graph, disjoint_beta_network)
  end

  def create_beta_nodes(graph, [first | [second | list]]) do
    {beta_memory, _} = Node.BetaMemory.new(first, second)

    graph
    |> Graph.add_vertex(beta_memory)
    |> Graph.add_edge(first, beta_memory)
    |> Graph.add_edge(second, beta_memory)
    |> create_beta_nodes([beta_memory] ++ list)
  end

  def create_beta_nodes(graph, [beta_memory]) do
    {beta_memory, graph}
  end

  def add_p_node(graph, beta_memory, action) do
    {pnode, _} = Node.PNode.new(action)
    graph |> Graph.add_vertex(pnode) |> Graph.add_edge(beta_memory, pnode)
  end

  def build_alpha_network(%Fact.Isa{} = condition, {graph, test_nodes}) do
    %{variable: _, type: type} = condition
    {type_node, _} = Node.Type.new(type)

    new_graph =
      graph
      |> Graph.add_vertex(type_node)
      |> Graph.add_edge(root_vertex(), type_node)

    {new_graph, [type_node | test_nodes]}
  end

  def build_alpha_network(%Fact.HasAttribute{} = condition, {graph, test_nodes}) do
    %{attribute: attribute, owner: class, predicate: predicate, value: value} = condition
    condition_id = hash(condition)
    {type_node, _} = Node.Type.new(class)
    {select_node, _} = Node.Select.new(class, attribute)
    {test_node, _} = Node.Test.new([predicate, value], condition_id)

    new_graph =
      graph
      |> Graph.add_vertex(type_node)
      |> Graph.add_edge(root_vertex(), type_node)
      |> Graph.add_vertex(select_node)
      |> Graph.add_edge(type_node, select_node)
      |> Graph.add_vertex(test_node)
      |> Graph.add_edge(select_node, test_node)

    {new_graph, [test_node | test_nodes]}
  end

  def print(%{graph: graph} = network) do
    with {:ok, graph} <- Graph.to_dot(graph) do
      IO.write("\n")
      IO.write("\n")
      IO.puts(graph)
      IO.write("\n")
      IO.write("\n")
    end

    network
  end

  def hash(:uuid4), do: UUIDTools.uuid4()

  def hash(data) do
    :crypto.hash(:sha256, inspect(data))
    |> Base.encode16()
    |> String.downcase()
  end

  def replace_bindings(%_{action: actions} = pnode, bindings) when is_map(bindings) do
    new_actions =
      Enum.map(actions, fn action ->
        List.to_tuple(
          for element <- Tuple.to_list(action) do
            if is_binary(element), do: Map.get(bindings, element, element), else: element
          end
        )
      end)

    %{pnode | action: new_actions}
  end

  def replace_bindings(%_{action: actions} = pnode, {_, _, bindings}) when is_map(bindings) do
    new_actions =
      Enum.map(actions, fn action ->
        List.to_tuple(
          for element <- Tuple.to_list(action) do
            if is_binary(element), do: Map.get(bindings, element, element), else: element
          end
        )
      end)

    %{pnode | action: new_actions}
  end

  def add_token(%Retex{tokens: rete_tokens} = rete, current_node, wme, bindings, [_ | _] = tokens) do
    node_tokens = Map.get(rete_tokens, current_node.id, [])

    all_tokens = node_tokens ++ tokens

    new_tokens = Map.put(rete_tokens, current_node.id, Enum.uniq(all_tokens))
    %{rete | tokens: new_tokens}
  end

  def add_token(%Retex{tokens: rete_tokens} = rete, current_node, wme, bindings, tokens) do
    node_tokens = Map.get(rete_tokens, current_node.id, [])
    token = Token.new()

    token = %{
      token
      | wmem: wme,
        node: current_node.id,
        bindings: bindings
    }

    all_tokens = [token] ++ node_tokens ++ tokens

    new_tokens = Map.put(rete_tokens, current_node.id, Enum.uniq(all_tokens))
    %{rete | tokens: new_tokens}
  end

  def create_activation(
        %__MODULE__{tokens: tokens, activations: activations, wme_activations: wme_activations} =
          rete,
        current_node,
        wme
      ) do
    node_activations = Map.get(activations, current_node.id, [])
    new_activations = [wme.id | node_activations]
    new_rete = %{rete | activations: Map.put(activations, current_node.id, new_activations)}
    previous_wme_activations = Map.get(wme_activations, wme.id, [])

    new_wme_activations =
      Map.put(wme_activations, wme.id, [current_node.id | previous_wme_activations])

    %{new_rete | wme_activations: new_wme_activations}
  end

  def propagate_activations(
        %Retex{tokens: tokens} = rete,
        %{} = current_node,
        %Retex.Wme{} = wme,
        bindings,
        new_tokens
      ) do
    %{graph: graph} = rete
    children = Graph.out_neighbors(graph, current_node)

    Enum.reduce(children, {rete, bindings}, fn vertex, {network, bindings} ->
      propagate_activation(vertex, network, wme, bindings, new_tokens)
    end)
  end

  def propagate_activations(
        %Retex{tokens: tokens} = rete,
        %{} = current_node,
        %Retex.Wme{} = wme,
        bindings
      ) do
    %{graph: graph} = rete
    children = Graph.out_neighbors(graph, current_node)

    Enum.reduce(children, {rete, bindings}, fn vertex, {network, bindings} ->
      propagate_activation(vertex, network, wme, bindings)
    end)
  end

  def continue_traversal(
        %Retex{} = new_rete,
        %{} = new_bindings,
        %_{} = current_node,
        %Retex.Wme{} = wme,
        tokens
      ) do
    {new_rete, new_bindings}
    propagate_activations(new_rete, current_node, wme, new_bindings, tokens)
  end

  def continue_traversal(
        %Retex{} = new_rete,
        %{} = new_bindings,
        %_{} = current_node,
        %Retex.Wme{} = wme
      ) do
    {new_rete, new_bindings}
    propagate_activations(new_rete, current_node, wme, new_bindings)
  end

  def stop_traversal(%Retex{} = rete, %{} = bindings) do
    {rete, bindings}
  end
end
