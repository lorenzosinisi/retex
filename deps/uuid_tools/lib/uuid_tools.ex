defmodule UUIDTools do
  @moduledoc """
  Documentation for UUIDTools.
  """
  defdelegate uuid1(), to: UUIDTools.UUID
  defdelegate uuid1(format), to: UUIDTools.UUID
  defdelegate uuid3(namespace, name), to: UUIDTools.UUID
  defdelegate uuid3(namespace, name, format), to: UUIDTools.UUID
  defdelegate uuid4(), to: UUIDTools.UUID
  defdelegate uuid4(format), to: UUIDTools.UUID
  defdelegate uuid5(namespace, binary), to: UUIDTools.UUID
  defdelegate uuid5(namespace, binary, format), to: UUIDTools.UUID
  defdelegate binary_to_string!(a, b), to: UUIDTools.UUID
  defdelegate string_to_binary!(a), to: UUIDTools.UUID
end
