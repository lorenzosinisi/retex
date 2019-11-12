defprotocol Retex.Protocol.Activation do
  @doc "This protocol knows how to activate a node and pass the information to children"
  def activate(node, rete, wme, bindings, tokens)
end
