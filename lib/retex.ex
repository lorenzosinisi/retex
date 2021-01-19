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
            tokens: MapSet.new(),
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
    {filters, given} = Enum.split_with(given, &is_filter?/1)
    {graph, alphas} = build_alpha_network(graph, given)
    {beta_memory, graph} = build_beta_network(graph, alphas)
    graph = add_p_node(Map.get(rule, :id), graph, beta_memory, action, filters)

    %{network | graph: graph}
  end

  defp is_filter?(%Fact.Filter{}), do: true
  defp is_filter?(_), do: false

  @spec build_alpha_network(Graph.t(), list()) :: {Graph.t(), list()}
  def build_alpha_network(graph, given) do
    Enum.reduce(given, {graph, []}, &Retex.Protocol.AlphaNetwork.append(&1, &2))
  end

  @spec build_beta_network(Graph.t(), list(network_node())) :: {list(network_node()), Graph.t()}
  def build_beta_network(graph, disjoint_beta_network) do
    create_beta_nodes(graph, disjoint_beta_network)
  end

  @spec create_beta_nodes(Graph.t(), list(network_node())) :: {list(network_node()), Graph.t()}
  def create_beta_nodes(graph, [first | [second | list]]) do
    beta_memory = Node.BetaMemory.new()

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
    pnode = Node.PNode.new(action, filters)
    prod = if id, do: Map.put(pnode, :id, id), else: pnode
    graph |> Graph.add_vertex(prod) |> Graph.add_edge(beta_memory, prod)
  end

  @spec hash(any) :: String.t()
  def hash(:uuid4), do: UUIDTools.uuid4()

  def hash(data) do
    :sha256
    |> :crypto.hash(inspect(data))
    |> Base.encode16(case: :lower)
  end

  @spec replace_bindings(PNode.t(), map) :: PNode.t()
  def replace_bindings(%_{action: action_fun} = pnode, bindings)
      when is_function(action_fun) do
    %{pnode | action: action_fun, bindings: bindings}
  end

  def replace_bindings(%_{action: actions} = pnode, bindings) when is_map(bindings) do
    new_actions = Enum.map(actions, fn action -> replace_bindings(action, bindings) end)
    %{pnode | action: new_actions, bindings: bindings}
  end

  def replace_bindings(%Retex.Wme{} = action, bindings) when is_map(bindings) do
    populated =
      for {key, val} <- Map.from_struct(action), into: %{} do
        val = Map.get(bindings, val, val)
        {key, val}
      end

    struct(Retex.Wme, populated)
  end

  def replace_bindings(%_{action: actions} = pnode, bindings) when is_map(bindings) do
    new_actions = Enum.map(actions, fn action -> replace_bindings(action, bindings) end)

    %{pnode | action: new_actions, bindings: bindings}
  end

  def replace_bindings(tuple, bindings) when is_map(bindings) and is_tuple(tuple) do
    List.to_tuple(
      for element <- Tuple.to_list(tuple) do
        if is_binary(element), do: Map.get(bindings, element, element), else: element
      end
    )
  end

  def replace_bindings(%_{action: actions} = pnode, {_, _, bindings})
      when is_map(bindings) and is_list(actions) do
    new_actions = Enum.map(actions, fn action -> replace_bindings(action, bindings) end)
    %{pnode | action: new_actions, bindings: bindings}
  end

  def replace_bindings(anything, _bindings) do
    anything
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
    node_tokens = Map.get(rete_tokens, current_node.id, []) |> MapSet.new()
    all_tokens = MapSet.new(node_tokens) |> MapSet.union(MapSet.new(tokens))
    new_tokens = Map.put(rete_tokens, current_node.id, all_tokens)

    %{rete | tokens: new_tokens}
  end

  def add_token(%Retex{tokens: rete_tokens} = rete, current_node, wme, bindings, tokens) do
    node_tokens = Map.get(rete_tokens, current_node.id, []) |> MapSet.new()
    token = Token.new()

    token = %{
      token
      | wmem: wme,
        node: current_node.id,
        bindings: bindings
    }

    all_tokens =
      [token]
      |> MapSet.new()
      |> MapSet.union(node_tokens)
      |> MapSet.union(MapSet.new(tokens))

    new_tokens = Map.put(rete_tokens, current_node.id, MapSet.new(all_tokens))
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
        %Retex{graph: graph} = rete,
        %{} = current_node,
        %Retex.Wme{} = wme,
        bindings,
        new_tokens
      ) do
    graph
    |> Graph.out_neighbors(current_node)
    |> Enum.reduce({rete, bindings}, fn vertex, {network, bindings} ->
      propagate_activation(vertex, network, wme, bindings, new_tokens)
    end)
  end

  @spec propagate_activations(Retex.t(), network_node(), Retex.Wme.t(), map) :: {Retex.t(), map}
  def propagate_activations(
        %Retex{graph: graph} = rete,
        %{} = current_node,
        %Retex.Wme{} = wme,
        bindings
      ) do
    graph
    |> Graph.out_neighbors(current_node)
    |> Enum.reduce({rete, bindings}, fn vertex, {network, bindings} ->
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
    propagate_activations(new_rete, current_node, wme, new_bindings, tokens)
  end

  @spec continue_traversal(Retex.t(), map, network_node(), Retex.Wme.t()) :: {Retex.t(), map}
  def continue_traversal(
        %Retex{} = new_rete,
        %{} = new_bindings,
        %_{} = current_node,
        %Retex.Wme{} = wme
      ) do
    propagate_activations(new_rete, current_node, wme, new_bindings)
  end

  @spec stop_traversal(Retex.t(), map) :: {Retex.t(), map}
  def stop_traversal(%Retex{} = rete, %{} = bindings) do
    {rete, bindings}
  end
end
