defprotocol Retex.Protocol.AlphaNetwork do
  @doc "This protocol knows how append a new partial production into an existing network based on the type of fact"
  def append(fact, accumulator)
end
