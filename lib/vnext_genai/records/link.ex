defmodule GenAI.Records.Link do
  @moduledoc """
  Records related to graph links.
  """

  alias GenAI.Types.Graph, as: G
  require Record

  @typedoc """
  A graph handle are used to reference a graph element by name
  Global scopes must be unique and can not be overridden locally.
  Standard scope must be unique but can be overridden by local scoped handles.

  # When looking up handles we check for a global first, then a local, and if not local is in scope we check standard entries.
  """
  @type graph_handle ::
          record(:graph_handle, scope: :standard | :local | :global, name: G.node_handle())
  Record.defrecord(:graph_handle, scope: :standard, name: nil)

  @typedoc """
  Record container a graph node, the link leading to the node and immeidate
  parent of the graph node.
  """
  @type element_context :: record(:element_context, element: term, link: term, container: term)
  Record.defrecord(:element_context, element: nil, link: nil, container: nil)

  @typedoc """
  Element lookup entries point from the Graph Root to nested elements.
  """
  @type element_lookup ::
          record(:element_lookup,
            element: term,
            path: list(),
            type: module,
            implementation: module
          )
  Record.defrecord(:element_lookup, element: nil, path: [], type: nil, implementation: nil)

  @typedoc """
  Anchor Links point to a handle from the root node and from it's scope a nested local handle.
  Unlike the standard lookup logic only local handles are considered and we take
  the closest (first) local handle below the anchor.
  local_handle may itself be an array / path of local nodes below the anchor handle
  """
  @type anchor_link ::
          record(:anchor_link,
            anchor_handle: G.node_handle(),
            local_handle: G.node_handle() | list(G.node_handle())
          )
  Record.defrecord(:anchor_link, anchor_handle: nil, local_handle: nil)

  @typedoc """
  Record representing a link connector (target, and socket).
  ## Note
  Socket is used for elements with special input output links like grid search to indicate appropriate link to use per state.
  """
  @type connector ::
          record(:connector,
            node: G.graph_node_id() | {anchor :: term, handle :: term},
            socket: term,
            external: atom
          )
  Record.defrecord(:connector, node: nil, socket: nil, external: false)
end
