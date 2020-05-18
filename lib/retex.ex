defmodule Retex do
  @moduledoc false

  @type t() :: %Retex{}
  alias Retex.{Node, Protocol, Fact, Token}

  alias Node.{
    Type,
    Test,
    Select,
    PNode,
    BetaMemory
  }

  @type action :: %{given: list(Retex.Wme.t()), then: list(Retex.Wme.t())}
  @type network_node :: Type.t() | Test.t() | Select.t() | PNode.t() | BetaMemory.t()

  defstruct graph: Graph.new(),
            wmes: %{},
            agenda: [],
            activations: %{},
            wme_activations: %{},
            tokens: %{},
            bindings: %{},
            pending_activation: []

  @spec root_vertex :: Retex.Root.t()
  def root_vertex(), do: Retex.Root.new()

  @spec new :: Retex.t()
  def new() do
    %{graph: graph} = %Retex{}
    graph = Graph.add_vertex(graph, Retex.Root.new())
    %Retex{graph: graph}
  end

  @spec add_wme(Retex.t(), Retex.Wme.t()) :: Retex.t()
  def add_wme(%Retex{} = network, %Retex.Wme{} = wme) do
    wme = Map.put(wme, :timestamp, :os.system_time(:seconds))
    network = %{network | wmes: Map.put(network.wmes, wme.id, wme)}
    {network, bindings} = propagate_activations(network, root_vertex(), wme, network.bindings)
    %{network | bindings: Map.merge(network.bindings, bindings)}
  end

  defp propagate_activation(neighbor, rete, wme, bindings, tokens \\ []) do
    Protocol.Activation.activate(neighbor, rete, wme, bindings, tokens)
  end

  @spec add_production(Retex.t(), %{given: list(Retex.Wme.t()), then: action()}) :: t()
  def add_production(%{graph: graph} = network, %{given: given, then: action} = rule) do
    {filters, given} = split_conditions_from_filters(given)

    {graph, alphas} =
      given |> Enum.reverse() |> Enum.reduce({graph, []}, &build_alpha_network(&1, &2))

    {beta_memory, graph} = build_beta_network(graph, alphas)
    graph = add_p_node(Map.get(rule, :id), graph, beta_memory, action, filters)
    %{network | graph: graph}
  end

  defp split_conditions_from_filters(given) do
    Enum.split_with(given, &is_filter?/1)
  end

  defp is_filter?(%Fact.Filter{}), do: true
  defp is_filter?(_), do: false

  @spec build_beta_network(Graph.t(), list(network_node())) :: {list(network_node()), Graph.t()}
  def build_beta_network(graph, disjoint_beta_network) do
    create_beta_nodes(graph, disjoint_beta_network)
  end

  @spec create_beta_nodes(Graph.t(), list(network_node())) :: {list(network_node()), Graph.t()}
  def create_beta_nodes(graph, [first | [second | list]]) do
    {beta_memory, _} = Node.BetaMemory.new(first, second)

    graph
    |> Graph.add_vertex(beta_memory)
    |> Graph.add_edge(first, beta_memory)
    |> Graph.add_edge(second, beta_memory)
    |> create_beta_nodes([beta_memory | list])
  end

  def create_beta_nodes(graph, [beta_memory]) do
    {beta_memory, graph}
  end

  @spec add_p_node(any, Graph.t(), BetaMemory.t(), action(), list(Fact.Filter.t())) :: Graph.t()
  def add_p_node(id, graph, beta_memory, action, filters) do
    {pnode, _} = Node.PNode.new(action, filters)
    prod = if id, do: Map.put(pnode, :id, id), else: pnode
    graph |> Graph.add_vertex(prod) |> Graph.add_edge(beta_memory, prod)
  end

  @spec build_alpha_network(
          Fact.Isa.t() | Fact.HasAttribute.t(),
          {Graph.t(), list(network_node())}
        ) :: {Graph.t(), list(network_node())}
  def build_alpha_network(%Fact.Isa{} = condition, {graph, test_nodes}) do
    %{variable: _, type: type} = condition
    {type_node, _} = Node.Type.new(type)

    new_graph =
      graph
      |> Graph.add_vertex(type_node)
      |> Graph.add_edge(root_vertex(), type_node)

    {new_graph, [type_node | test_nodes]}
  end

  def build_alpha_network(%Fact.IsNot{} = condition, {graph, test_nodes}) do
    %{variable: _, type: type} = condition
    {type_node, _} = Node.NegativeType.new(type)

    new_graph =
      graph
      |> Graph.add_vertex(type_node)
      |> Graph.add_edge(root_vertex(), type_node)

    {new_graph, [type_node | test_nodes]}
  end

  def build_alpha_network(%Fact.UnexistantAttribute{} = condition, {graph, last_nodes}) do
    %{attribute: attribute, owner: class} = condition
    {type_node, _} = Node.Type.new(class)
    {select_node, _} = Node.SelectNot.new(class, attribute)

    new_graph =
      graph
      |> Graph.add_vertex(type_node)
      |> Graph.add_edge(root_vertex(), type_node)
      |> Graph.add_vertex(select_node)
      |> Graph.add_edge(type_node, select_node)

    {new_graph, [select_node | last_nodes]}
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

  @spec print(%{graph: Graph.t()}) :: Retex.t()
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

  @spec hash(any) :: String.t()
  def hash(:uuid4), do: UUIDTools.uuid4()

  def hash(data) do
    :crypto.hash(:sha256, inspect(data))
    |> Base.encode16()
    |> String.downcase()
  end

  @spec replace_bindings(PNode.t(), map) :: PNode.t()
  def replace_bindings(%_{action: actions} = pnode, bindings) when is_map(bindings) do
    new_actions =
      Enum.map(actions, fn action ->
        case action do
          action when is_tuple(action) ->
            List.to_tuple(
              for element <- Tuple.to_list(action) do
                if is_binary(element), do: Map.get(bindings, element, element), else: element
              end
            )

          %Retex.Wme{} = action ->
            populated =
              for {key, val} <- Map.from_struct(action), into: %{} do
                val = Map.get(bindings, val, val)
                {key, val}
              end

            struct(Retex.Wme, populated)

          anything ->
            anything
        end
      end)

    %{pnode | action: new_actions, bindings: bindings}
  end

  def replace_bindings(%_{action: actions} = pnode, bindings) when is_map(bindings) do
    new_actions =
      Enum.map(actions, fn action ->
        case action do
          action when is_tuple(action) ->
            List.to_tuple(
              for element <- Tuple.to_list(action) do
                if is_binary(element), do: Map.get(bindings, element, element), else: element
              end
            )

          %Retex.Wme{} = action ->
            populated =
              for {key, val} <- Map.from_struct(action), into: %{} do
                val = Map.get(bindings, val, val)
                {key, val}
              end

            struct(Retex.Wme, populated)

          anything ->
            anything
        end
      end)

    %{pnode | action: new_actions, bindings: bindings}
  end

  def replace_bindings(%_{action: actions} = pnode, {_, _, bindings})
      when is_map(bindings) and is_list(actions) do
    new_actions =
      Enum.map(actions, fn action ->
        case action do
          action when is_tuple(action) ->
            List.to_tuple(
              for element <- Tuple.to_list(action) do
                if is_binary(element), do: Map.get(bindings, element, element), else: element
              end
            )

          %Retex.Wme{} = action ->
            populated =
              for {key, val} <- Map.from_struct(action), into: %{} do
                val = Map.get(bindings, val, val)
                {key, val}
              end

            struct(Retex.Wme, populated)

          anything ->
            anything
        end
      end)

    %{pnode | action: new_actions, bindings: bindings}
  end

  def replace_bindings(%_{action: action_fun} = pnode, {_, _, bindings})
      when is_function(action_fun) do
    %{pnode | action: action_fun, bindings: bindings}
  end

  @spec add_token(Retex.t(), network_node(), Retex.Wme.t(), map, list(Retex.Token.t())) ::
          Retex.t()
  def add_token(
        %Retex{tokens: rete_tokens} = rete,
        current_node,
        _wme,
        _bindings,
        [_ | _] = tokens
      ) do
    node_tokens = Map.get(rete_tokens, current_node.id, [])

    all_tokens = Enum.uniq(node_tokens ++ tokens)

    new_tokens = Map.put(rete_tokens, current_node.id, all_tokens)
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

    all_tokens = [token | node_tokens] ++ tokens

    new_tokens = Map.put(rete_tokens, current_node.id, Enum.uniq(all_tokens))
    %{rete | tokens: new_tokens}
  end

  @spec create_activation(Retex.t(), network_node(), Retex.Wme.t()) :: Retex.t()
  def create_activation(
        %__MODULE__{activations: activations, wme_activations: wme_activations} = rete,
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

  @spec propagate_activations(
          Retex.t(),
          network_node(),
          Retex.Wme.t(),
          map,
          list(Retex.Token.t())
        ) :: {Retex.t(), map}
  def propagate_activations(
        %Retex{} = rete,
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

  @spec propagate_activations(Retex.t(), network_node(), Retex.Wme.t(), map) :: {Retex.t(), map}
  def propagate_activations(
        %Retex{} = rete,
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

  @spec deactivate_descendants(Retex.t(), network_node()) :: Retex.t()
  def deactivate_descendants(%Retex{activations: activations} = rete, %{} = current_node) do
    %{graph: graph} = rete
    children = Graph.out_neighbors(graph, current_node)

    Enum.reduce(children, rete, fn %type{} = vertex, network ->
      if type == Retex.Node.PNode do
        %{
          network
          | agenda: Enum.reject(network.agenda, fn pnode -> pnode.id == vertex.id end)
        }
      else
        new_network = %{network | activations: Map.put(activations, vertex.id, [])}
        deactivate_descendants(new_network, vertex)
      end
    end)
  end

  @spec continue_traversal(Retex.t(), map, network_node(), Retex.Wme.t(), list(Retex.Token.t())) ::
          {Retex.t(), map}
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

  @spec continue_traversal(Retex.t(), map, network_node(), Retex.Wme.t()) :: {Retex.t(), map}
  def continue_traversal(
        %Retex{} = new_rete,
        %{} = new_bindings,
        %_{} = current_node,
        %Retex.Wme{} = wme
      ) do
    {new_rete, new_bindings}
    propagate_activations(new_rete, current_node, wme, new_bindings)
  end

  @spec stop_traversal(Retex.t(), map) :: {Retex.t(), map}
  def stop_traversal(%Retex{} = rete, %{} = bindings) do
    {rete, bindings}
  end
end
