defmodule Retex do
  @moduledoc """
  The algorithm utilizes symbols to create an internal representation of the world.
  Each element in the real world is converted into a triple known as a "Working Memory Element" (`Retex.Wme.t()`),
  represented as {Entity, attribute, attribute_value}.

  The world is represented through facts (WMEs) and Rules.
  A Rule consists of two essential parts: the "given" (right side) and the "then" (left side).

  To perform inference, the rule generates a directed graph starting from a common and generic Root node,
  which branches out to form leaf nodes. The branches from the Root node correspond to the initial part
  of the WME, representing the working memory elements or "Entity". For instance, if we want to
  represent a customer's account status as "silver", we would encode it as "{Customer, account_status, silver}".
  Alternatively, with the use of a struct, we can achieve the same representation as `Retex.Wme.new("Customer", "account status", "silver")`



  ## The struct
  This module also defines a Struct with the following fields:

  1. `graph: Graph.new()`: This field is initialized with the value returned by the `Graph.new()` function. It is a reference to a directed graph data structure (using `libgraph`)
  that represents a network of interconnected nodes and vertices.

  2. `wmes: %{}`: This field is initialized as an empty map. It is expected to store "working memory elements" (WMEs), which are pieces of information or facts used in the system.

  3. `agenda: []`: This field is initialized as an empty list. It is intended to store a collection of tasks or items that need to be processed or executed. The agenda typically represents a prioritized queue of pending actions.

  4. `activations: %{}`: This field is initialized as an empty map. It is used to store information related to the activations of nodes in the network.

  5. `wme_activations: %{}`: This field is initialized as an empty map. It is similar to the `activations` field but specifically focuses on the activations of working memory elements (WMEs) and can serve as reverse lookup of which facts have activated which no.

  6. `tokens: MapSet.new()`: This field is initialized with the value returned by the `MapSet.new()` function. Will be deprecated soon because it has no use but was a porting from the original paper.

  7. `bindings: %{}`: This field is initialized as an empty map. It is used to store variable bindings or associations between variables and their corresponding values. This can be useful for tracking and manipulating data within the system.

  8. `pending_activation: []`: This field is initialized as an empty list. It is likely used to keep track of activations that are pending or awaiting further processing. The exact meaning and usage of these pending activations would depend on the system's design.
  """

  @type t() :: %Retex{}
  alias Retex.{Fact, Node, Protocol, Protocol.AlphaNetwork, Token}

  alias Node.{
    BetaMemory,
    PNode,
    Select,
    Test,
    Type
  }

  @type action :: %{given: list(Retex.Wme.t()), then: list(Retex.Wme.t())}
  @type network_node :: Type.t() | Test.t() | Select.t() | PNode.t() | BetaMemory.t()

  # the Retex network is made of the following elements:
  defstruct graph: Graph.new(),
            wmes: %{},
            id: nil,
            concurrent: false,
            agenda: [],
            activations: %{},
            wme_activations: %{},
            tokens: MapSet.new(),
            bindings: %{},
            pending_activation: []

  @doc """
  Generate a new Retext.Root.t() struct that represents the first node of the network.
  An anonymous node that functions just as connector for the type nodes (`Retex.Node.Type.t()`)
  """
  @spec root_vertex :: Retex.Root.t()
  def root_vertex, do: Retex.Root.new()

  @doc @moduledoc
  @spec new(String.t()) :: Retex.t()
  def new(id \\ UUIDTools.uuid4(), opts \\ []) do
    :ets.new(String.to_atom(id), [:set, :protected, :named_table])
    %{graph: graph} = %Retex{id: id, concurrent: true}
    graph = Graph.add_vertex(graph, Retex.Root.new())
    %Retex{graph: graph, id: id, concurrent: true}
  end

  def get(id, key, default \\ %{}) do
    IO.inspect({:get, key})

    case :ets.lookup(String.to_atom(id), key) do
      [value] ->
        value

      [] ->
        default
    end
  end

  def put(id, key, value) when is_binary(id) do
    IO.inspect({key, value})

    value =
      case :ets.lookup(String.to_atom(id), key) do
        [{^key, activations}] when is_map(value) ->
          IO.inspect(DeepMerge.deep_merge(activations, value), label: key)

        [] ->
          value
      end

    :ets.insert(String.to_atom(id), {key, value})
  end

  @doc """
  Takes the network itself and a WME struct and tries to activate as many nodes as possible traversing the graph
  from the Root until each reachable branch executing a series of "tests" (pattern matching) at each node level.

  Each node is tested implementing the activation protocol, so to know if how the test for the node against the WME
  works check their protocol implementation.
  """
  @spec add_wme(Retex.t(), Retex.Wme.t()) :: Retex.t()
  def add_wme(%Retex{} = network, %Retex.Wme{} = wme) do
    # just a timestamp might be useful for the future
    wme = Map.put(wme, :timestamp, :os.system_time(:seconds))
    # store the new fact in memory with their ID
    network = %{network | wmes: Map.put(network.wmes, wme.id, wme)}
    # traverse the network for the Root node branching out and testing each node for possible
    # activations
    {network, bindings} = propagate_activations(network, root_vertex(), wme, network.bindings)

    # if there is some activation for variables store such mapping (variable name => value) in memory
    %{network | bindings: Map.merge(network.bindings, bindings)}
  end

  @doc """
  A production is what is called a Rule in the original Rete paper from C. Forgy

  A production is a map of given and then and each of those fields contains a list of
  `Retex.Fact.t()` which can be tested against a `Retex.Wme.t()`
  """
  @spec add_production(Retex.t(), %{given: list(Retex.Wme.t()), then: action()}) :: t()
  def add_production(%{graph: graph} = network, %{given: given, then: action}) do
    # Filters are extra tests that ca be added to the given part of the rule
    # it is an extra feature present only in Retex and a personal choice
    {filters, given} = Enum.split_with(given, &is_filter?/1)
    # Take each fact in the given part of the rule and find or create the corresponding node
    # this part of what you see in the graph at https://github.com/lorenzosinisi/retex#how-does-it-work
    {graph, alphas} = build_alpha_network(graph, given)
    # this second part is just the representation of each "and" in a rule.
    {beta_memory, graph} = build_beta_network(graph, alphas)

    # finally add the "then" part of the rule on the last leaf of that subgraph (generated by the Rule)
    graph = add_p_node(graph, beta_memory, action, filters)

    %{network | graph: graph}
  end

  defp is_filter?(%Fact.Filter{}), do: true
  defp is_filter?(_), do: false

  @doc """
  Take each fact of the "given" part of the rule and construct the alpha part of the network destructuring the facts
  into "Root" -> "Entity" -> "Attribute" -> "Value" (if a node with the same value already exists it will be a noop)
  """
  @spec build_alpha_network(Graph.t(), list()) :: {Graph.t(), list()}
  def build_alpha_network(graph, given) do
    Enum.reduce(given, {graph, []}, &AlphaNetwork.append(&1, &2))
  end

  @doc """
  After building the alpha network we will have a list of nodes which are the bottom of the new subnetwork,
  not connect those two by two. Take the firs two, join them with a new node, that that one node
  connect it with the next orphan node, keep doing it until all the facts of a rule are connected together and
  we have one last "Join" node.

  And example of a graph with only one "and/join" node:

  ```mermaid
  flowchart
    2102090852["==100"]
    2332826675["==silver"]
    2833714732["[{:Discount, :code, 50}]"]
    3108351631["Root"]
    3726656564["Join"]
    3801762854["miles"]
    3860425667["Customer"]
    3895425755["account_status"]
    4112061991["Flight"]
    2102090852 --> 3726656564
    2332826675 --> 3726656564
    3108351631 --> 3860425667
    3108351631 --> 4112061991
    3726656564 --> 2833714732
    3801762854 --> 2102090852
    3860425667 --> 3895425755
    3895425755 --> 2332826675
    4112061991 --> 3801762854
  ```
  """
  @spec build_beta_network(Graph.t(), list(network_node())) :: {list(network_node()), Graph.t()}
  def build_beta_network(graph, [first, second | list]) do
    id = Retex.hash(Enum.sort([first, second]))
    beta_memory = Node.BetaMemory.new(id)

    graph
    |> Graph.add_vertex(beta_memory)
    |> Graph.add_edge(first, beta_memory)
    |> Graph.add_edge(second, beta_memory)
    |> build_beta_network([beta_memory | list])
  end

  def build_beta_network(graph, [beta_memory]) do
    {beta_memory, graph}
  end

  @doc """
  The P node is the production node, just another name of a rule
  """
  @spec add_p_node(Graph.t(), BetaMemory.t(), action(), list(Fact.Filter.t())) :: Graph.t()
  def add_p_node(graph, beta_memory, action, filters) do
    pnode = Node.PNode.new(action, filters)
    graph |> Graph.add_vertex(pnode) |> Graph.add_edge(beta_memory, pnode)
  end

  @max_phash 4_294_967_296
  @spec hash(any) :: String.t()
  def hash(:uuid4), do: UUIDTools.uuid4()

  def hash(data) do
    :erlang.phash2(data, @max_phash)
  end

  @spec replace_bindings(PNode.t(), map) :: PNode.t()
  def replace_bindings(%_{action: action_fun} = pnode, bindings)
      when is_function(action_fun) do
    %{pnode | action: action_fun, bindings: bindings}
  end

  def replace_bindings(%_{action: actions} = pnode, bindings)
      when is_list(actions) and is_map(bindings) do
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

  def replace_bindings(tuple, bindings) when is_map(bindings) and is_tuple(tuple) do
    List.to_tuple(
      for element <- Tuple.to_list(tuple) do
        if is_binary(element), do: Map.get(bindings, element, element), else: element
      end
    )
  end

  def replace_bindings(anything, _bindings) do
    anything
  end

  @spec add_token(Retex.t(), network_node(), Retex.Wme.t(), map, list(Retex.Token.t())) ::
          Retex.t()

  def add_token(
        %Retex{tokens: _rete_tokens, concurrent: true} = rete,
        current_node,
        _wme,
        _bindings,
        [_ | _] = tokens
      ) do
    rete_tokens = get(rete.id, :tokens)

    node_tokens =
      rete_tokens
      |> Map.get(current_node.id, [])
      |> MapSet.new()

    all_tokens =
      node_tokens
      |> MapSet.new()
      |> MapSet.union(MapSet.new(tokens))

    new_tokens = Map.put(rete_tokens, current_node.id, all_tokens)

    put(rete.id, :tokens, new_tokens)

    %{rete | tokens: new_tokens}
  end

  def add_token(
        %Retex{tokens: rete_tokens} = rete,
        current_node,
        _wme,
        _bindings,
        [_ | _] = tokens
      ) do
    node_tokens =
      rete_tokens
      |> Map.get(current_node.id, [])
      |> MapSet.new()

    all_tokens =
      node_tokens
      |> MapSet.new()
      |> MapSet.union(MapSet.new(tokens))

    new_tokens = Map.put(rete_tokens, current_node.id, all_tokens)

    put(rete.id, :tokens, new_tokens)

    %{rete | tokens: new_tokens}
  end

  def add_token(%Retex{tokens: rete_tokens} = rete, current_node, wme, bindings, tokens) do
    node_tokens =
      rete_tokens
      |> Map.get(current_node.id, [])
      |> MapSet.new()

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

    new_tokens = Map.put(rete_tokens, current_node.id, all_tokens)

    put(rete.id, :tokens, new_tokens)

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

    put(rete.id, :wme_activations, new_wme_activations)
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

  defp propagate_activation(neighbor, rete, wme, bindings, tokens \\ []) do
    Protocol.Activation.activate(neighbor, rete, wme, bindings, tokens)
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
        put(rete.id, :activations, Map.put(activations, vertex.id, []))
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
