defprotocol Retex.Protocol.Activation do
  @doc "This protocol knows how to activate a node and pass the information to children"
  def activate(node, rete, wme, bindings, tokens)

  @doc "Implements the strategy to know if a node is activated or not"
  def active?(rete, node)
end
