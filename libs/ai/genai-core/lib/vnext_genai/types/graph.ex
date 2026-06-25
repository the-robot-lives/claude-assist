defmodule GenAI.Types.Graph do
  @moduledoc """
  GenAI.VNext.Graph Type Declarations.
  """

  @typedoc """
  A GenAI.VNext.Graph Object
  """
  @type graph :: term

  @typedoc """
  A GenAI.VNext.Graph Object Identifier
  """
  @type graph_id :: term

  @typedoc """
  A GenAI.VNext.Graph Link Object
  """
  @type graph_link :: term

  @typedoc """
  A GenAI.VNext.Graph Link Object Identifier
  """
  @type graph_link_id :: term

  @typedoc """
  A GenAI.VNext.Graph Node Object
  """
  @type graph_node :: term

  @typedoc """
  A GenAI.VNext.Graph Node Object Identifier
  """
  @type graph_node_id :: term

  @typedoc """
  GenAI.VNext.Graph Link Type (e.g. comment, path, etc.)
  """
  @type link_type :: term

  @typedoc """
  GenAI.VNext.Graph Link Label (e.g. "Log Output")
  """
  @type link_label :: term

  @typedoc """
  A GenAI.VNext.Graph Node Handle - logical reference name for a node.
  """
  @type node_handle :: term

  @typedoc """
  A GenAI.VNext.Graph Node Identifier.
  """
  @type node_id :: term

  # --------------------------------
  # Type Guards
  # --------------------------------

  @doc """
  Guard to check if a value is a valid Graph ID.
  """
  defguard is_graph_id(id)
           when is_atom(id) or is_integer(id) or is_tuple(id) or is_bitstring(id) or is_binary(id)

  @doc """
  Guard to check if a value is a valid Node ID.
  """
  defguard is_node_id(id)
           when is_atom(id) or is_integer(id) or is_tuple(id) or is_bitstring(id) or is_binary(id)

  @doc """
  Guard to check if a value is a valid Link ID.
  """
  defguard is_link_id(id)
           when is_atom(id) or is_integer(id) or is_tuple(id) or is_bitstring(id) or is_binary(id)
end
