defmodule Graphvix.Record.Port do
  @moduledoc """
  [Internal] Models a `Graphvix.Record` cell with a port name attached.

  See `Graphvix.Record.new/2` for a more complete documentation of using
  ports with cells.
  """

  defstruct [
    body: nil,
    port_name: nil
  ]

  @doc false
  def new(body, port_name) do
    %__MODULE__{body: body, port_name: port_name}
  end

  @doc false
  def to_label(port) do
    "<#{port.port_name}> #{port.body}"
  end
end


