defmodule GenAI.Types do
  @moduledoc """
  VNextGenAI Types
  """

  @typedoc """
  Element Handle
  """
  @type handle :: term

  @typedoc """
  Element Name.
  """
  @type name :: term

  @typedoc """
  Element Description.
  """
  @type description :: term

  @typedoc """
  Element Finger Print.
  """
  @type finger_print :: term

  @typedoc """
  Node Handle - used to reference a node by a logical name.
  """
  @type node_handle :: term

  @typedoc """
  Node Identifier - unique identifier for a node.
  """
  @type node_id :: term

  @typedoc """
  Link Map - map of links grouped by outlet/socket.
  """
  @type link_map :: map()

  @typedoc """
  Error details
  """
  @type details :: tuple | atom | bitstring()

  @typedoc """
  Success Response
  """
  @type ok(r) :: {:ok, r}
  @typedoc """
  Error Response
  """
  @type error(e) :: {:error, e}

  @typedoc """
  Call outcome tuple.
  """
  @type result(r, e) :: ok(r) | error(e)
end
