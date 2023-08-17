defmodule Retex.Token do
  @moduledoc """
  The root node of the network is the input to the black box.
  This node receives the tokens that are sent to the black box and passes copies
  of the tokens to all its successors. The successors of the top node, the nodes to
  perform the intra-element tests, have one input and one or more outputs. Each
  node tests one feature and sends the tokens that pass the test to its successors.
  The two-input nodes compare tokens from different paths and join them into
  bigger tokens if they satisfy the inter-element constraints of the LHS. Because
  of the tests performed by the other nodes, a terminal node will receive only
  tokens that instantiate the LHS. The terminal node sends out of the black box
  the information that the conflict set must be changed. - RETE Match Algorithm - Forgy OCR
  """
  defstruct wmem: nil, node: nil, bindings: %{}

  @type t() :: %Retex.Token{}

  def new do
    %__MODULE__{}
  end
end
