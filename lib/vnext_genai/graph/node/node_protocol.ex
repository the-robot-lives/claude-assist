defprotocol GenAI.Graph.NodeProtocol do
  @moduledoc """
  Protocol for managing Graph Nodes.
  """
  alias GenAI.Types.Graph, as: G
  alias GenAI.Types, as: T

  # ----------------------------------------------------------------
  # node/2
  # ----------------------------------------------------------------
  @doc """
  Obtain a node nested under current node,
  """
  def node(graph_node, id)

  # ----------------------------------------------------------------
  # nodes/2
  # ----------------------------------------------------------------
  @doc """
  Obtain direct children node of current node.
  """
  def nodes(graph_node, options \\ nil)

  # ----------------------------------------------------------------
  # build_node_lookup/2
  # ----------------------------------------------------------------
  @doc """
  build Graph Root node lookup allowing nodes to link across descendents/siblings to far away elements.
  """
  def build_node_lookup(graph_node, options \\ nil)

  # ----------------------------------------------------------------
  # build_handle_lookup/2
  # ----------------------------------------------------------------
  @doc """
  build handle lookup table for graph root, including local handles that can override standard handles based on scope.
  """
  def build_handle_lookup(graph_node, options \\ nil)

  # ----------------------------------------------------------------
  # node_type/1
  # ----------------------------------------------------------------
  @doc """
  Obtain the node type for a graph node.

  ## Example
      iex> node = %GenAI.Graph.Node{id: UUID.uuid4()}
      ...> GenAI.Graph.NodeProtocol.node_type(node)
      {:ok, GenAI.Graph.Node}
  """
  @spec node_type(graph_node :: G.graph_node()) :: T.result(G.graph_node_id(), T.details())
  def node_type(graph_node)

  # ----------------------------------------------------------------
  # id/1
  # ----------------------------------------------------------------
  @doc """
  Obtain the id of a graph node.

  ## Examples

  ### When Set
      iex> node = %GenAI.Graph.Node{id: UUID.uuid4()}
      ...> GenAI.Graph.NodeProtocol.id(node)
      {:ok, node.id}

  ### When Not Set
      iex> node = %GenAI.Graph.Node{id: nil}
      ...> GenAI.Graph.NodeProtocol.id(node)
      {:error, {:id, :is_nil}}
  """
  @spec id(graph_node :: G.graph_node()) :: T.result(G.graph_node_id(), T.details())
  def id(graph_node)

  # ----------------------------------------------------------------
  # handle/1
  # ----------------------------------------------------------------
  @doc """
  Obtain the handle of a graph node.

  ## Examples

  ### When Set
      iex> node = %GenAI.Graph.Node{handle: :foo}
      ...> GenAI.Graph.NodeProtocol.handle(node)
      {:ok, :foo}

  ### When Not Set
      iex> node = %GenAI.Graph.Node{handle: nil}
      ...> GenAI.Graph.NodeProtocol.handle(node)
      {:error, {:handle, :is_nil}}
  """
  @spec handle(graph_node :: G.graph_node()) :: T.result(T.handle(), T.details())
  def handle(graph_node)

  # ----------------------------------------------------------------
  # handle_record/1
  # ----------------------------------------------------------------
  @doc """
  Return full handle record not just the handle name.
  """
  def handle_record(graph_node)

  # ----------------------------------------------------------------
  # handle/2
  # ----------------------------------------------------------------
  @doc """
  Obtain the handle of a graph node, or return a default value if the handle is nil.

  ## Examples

  ### When Set
      iex> node = %GenAI.Graph.Node{handle: :foo}
      ...> GenAI.Graph.NodeProtocol.handle(node, :default)
      {:ok, :foo}

  ### When Not Set
      iex> node = %GenAI.Graph.Node{handle: nil}
      ...> GenAI.Graph.NodeProtocol.handle(node, :default)
      {:ok, :default}
  """
  @spec handle(graph_node :: G.graph_node(), default :: T.handle()) ::
          T.result(T.handle(), T.details())
  def handle(graph_node, default)

  # ----------------------------------------------------------------
  # name/1
  # ----------------------------------------------------------------
  @doc """
  Obtain the name of a graph node.

  ## Examples

  ### When Set
      iex> node = %GenAI.Graph.Node{name: "A"}
      ...> GenAI.Graph.NodeProtocol.name(node)
      {:ok, "A"}

  ### When Not Set
      iex> node = %GenAI.Graph.Node{name: nil}
      ...> GenAI.Graph.NodeProtocol.name(node)
      {:error, {:name, :is_nil}}
  """
  @spec name(graph_node :: G.graph_node()) :: T.result(T.name(), T.details())
  def name(graph_node)

  # ----------------------------------------------------------------
  # name/2
  # ----------------------------------------------------------------
  @doc """
  Obtain the name of a graph node, or return a default value if the name is nil.

  ## Examples

  ### When Set
      iex> node = %GenAI.Graph.Node{name: "A"}
      ...> GenAI.Graph.NodeProtocol.name(node, "default")
      {:ok, "A"}

  ### When Not Set
      iex> node = %GenAI.Graph.Node{name: nil}
      ...> GenAI.Graph.NodeProtocol.name(node, "default")
      {:ok, "default"}
  """
  @spec name(graph_node :: G.graph_node(), default :: T.name()) :: T.result(T.name(), T.details())
  def name(graph_node, default)

  # ----------------------------------------------------------------
  # description/1
  # ----------------------------------------------------------------
  @doc """
  Obtain the description of a graph node.

  ## Examples

  ### When Set
      iex> node = %GenAI.Graph.Node{description: "B"}
      ...> GenAI.Graph.NodeProtocol.description(node)
      {:ok, "B"}

  ### When Not Set
      iex> node = %GenAI.Graph.Node{description: nil}
      ...> GenAI.Graph.NodeProtocol.description(node)
      {:error, {:description, :is_nil}}
  """
  @spec description(graph_node :: G.graph_node()) :: T.result(T.description(), T.details())
  def description(graph_node)

  # ----------------------------------------------------------------
  # description/2
  # ----------------------------------------------------------------
  @doc """
  Obtain the description of a graph node, or return a default value if the description is nil.

  ## Examples

  ### When Set
      iex> node = %GenAI.Graph.Node{description: "B"}
      ...> GenAI.Graph.NodeProtocol.description(node, "default")
      {:ok, "B"}

  ### When Not Set
      iex> node = %GenAI.Graph.Node{description: nil}
      ...> GenAI.Graph.NodeProtocol.description(node, "default")
      {:ok, "default"}
  """
  @spec description(graph_node :: G.graph_node(), default :: T.description()) ::
          T.result(T.description(), T.details())
  def description(graph_node, default)

  # ----------------------------------------------------------------
  # with_id/1
  # ----------------------------------------------------------------
  @doc """
  Ensure the graph node has an id, generating one if necessary.

  ## Examples

  ### When Already Set
      iex> node = %GenAI.Graph.Node{id: UUID.uuid4()}
      ...> {:ok, node2} = GenAI.Graph.NodeProtocol.with_id(node)
      ...> %{was_nil: is_nil(node.id), is_nil: is_nil(node2.id), id_change: node.id != node2.id}
      %{was_nil: false, is_nil: false, id_change: false}

  ### When Not Set
      iex> node = %GenAI.Graph.Node{id: nil}
      ...> {:ok, node2} = GenAI.Graph.NodeProtocol.with_id(node)
      ...> %{was_nil: is_nil(node.id), is_nil: is_nil(node2.id), id_change: node.id != node2.id}
      %{was_nil: true, is_nil: false, id_change: true}
  """
  @spec with_id(graph_node :: G.graph_node()) :: T.result(G.graph_node(), T.details())
  def with_id(graph_node)

  # ----------------------------------------------------------------
  # register_link/4
  # ----------------------------------------------------------------
  @doc """
  Register a link with the graph node.

  ## Examples

      iex> n1 = UUID.uuid5(:oid, "node-1")
      ...> n2 = UUID.uuid5(:oid, "node-2")
      ...> n = %GenAI.Graph.Node{id: n1}
      ...> link = GenAI.Graph.Link.new(n1, n2)
      ...> link_id = link.id
      ...> {:ok, updated} = GenAI.Graph.NodeProtocol.register_link(n, %{}, link, nil)
      ...> updated
      %GenAI.Graph.Node{outbound_links: %{default: [^link_id]}} = updated
  """
  @spec register_link(
          graph_node :: G.graph_node(),
          graph :: G.graph(),
          link :: G.graph_link(),
          options :: map
        ) :: T.result(G.graph_node(), T.details())
  def register_link(graph_node, graph, link, options)

  # ----------------------------------------------------------------
  # outbound_links/3
  # ----------------------------------------------------------------
  @doc """
  Obtain outbound links of a graph node.
  """
  @spec outbound_links(graph_node :: G.graph_node(), graph :: G.graph(), options :: map) ::
          {:ok, list(G.graph_link_id())} | {:error, term}
  def outbound_links(graph_node, graph, options)

  # ----------------------------------------------------------------
  # inbound_links/3
  # ----------------------------------------------------------------
  @doc """
  Obtain inbound links of a graph node.
  """
  @spec inbound_links(graph_node :: G.graph_node(), graph :: G.graph(), options :: map) ::
          {:ok, list(G.graph_link_id())} | {:error, term}
  def inbound_links(graph_node, graph, options)

  # ----------------------------------------------------------------
  # process_node
  # ----------------------------------------------------------------
  @doc """
  Process graph to execute tasks or run inference.
  """
  def process_node(graph_node, graph_link, graph_container, session, context, options)
end

defimpl GenAI.Graph.NodeProtocol, for: Any do
  def node(_, _), do: {:error, :unsupported}
  def nodes(_), do: {:error, :unsupported}
  def nodes(_, _), do: {:error, :unsupported}
  def build_node_lookup(_), do: {:error, :unsupported}
  def build_node_lookup(_, _), do: {:error, :unsupported}
  def build_handle_lookup(_), do: {:error, :unsupported}
  def build_handle_lookup(_, _), do: {:error, :unsupported}

  def node_type(_), do: {:error, :unsupported}
  def id(_), do: {:error, :unsupported}
  def handle_record(_), do: {:error, :unsupported}
  def handle(_), do: {:error, :unsupported}
  def handle(_, _), do: {:error, :unsupported}
  def name(_), do: {:error, :unsupported}
  def name(_, _), do: {:error, :unsupported}
  def description(_), do: {:error, :unsupported}
  def description(_, _), do: {:error, :unsupported}
  def with_id(_), do: {:error, :unsupported}
  def register_link(_, _, _, _), do: {:error, :unsupported}
  def outbound_links(_, _, _), do: {:error, :unsupported}
  def inbound_links(_, _, _), do: {:error, :unsupported}
  def process_node(_, _, _, _, _, _), do: {:error, :unsupported}

  defmacro __deriving__(module, struct, options)

  defmacro __deriving__(module, _, options) do
    quote do
      defimpl GenAI.Graph.NodeProtocol, for: unquote(module) do
        @provider unquote(options[:provider]) || GenAI.Graph.NodeProtocol.DefaultProvider

        @defimpl GenAI.Graph.NodeProtocol
        defdelegate node(subject, id), to: @provider
        @defimpl GenAI.Graph.NodeProtocol
        defdelegate nodes(subject, id), to: @provider

        defdelegate build_node_lookup(graph_node, options \\ nil), to: @provider
        defdelegate build_handle_lookup(graph_node, options \\ nil), to: @provider

        @defimpl GenAI.Graph.NodeProtocol
        defdelegate node_type(subject), to: @provider

        @defimpl GenAI.Graph.NodeProtocol
        defdelegate id(subject), to: @provider

        @defimpl GenAI.Graph.NodeProtocol
        defdelegate handle_record(subject), to: @provider

        @defimpl GenAI.Graph.NodeProtocol
        defdelegate handle(subject), to: @provider

        @defimpl GenAI.Graph.NodeProtocol
        defdelegate handle(subject, default), to: @provider

        @defimpl GenAI.Graph.NodeProtocol
        defdelegate name(subject), to: @provider

        @defimpl GenAI.Graph.NodeProtocol
        defdelegate name(subject, default), to: @provider

        @defimpl GenAI.Graph.NodeProtocol
        defdelegate description(subject), to: @provider

        @defimpl GenAI.Graph.NodeProtocol
        defdelegate description(subject, default), to: @provider

        @defimpl GenAI.Graph.NodeProtocol
        defdelegate with_id(subject), to: @provider

        @defimpl GenAI.Graph.NodeProtocol
        defdelegate register_link(subject, graph, link, options), to: @provider

        @defimpl GenAI.Graph.NodeProtocol
        defdelegate outbound_links(subject, graph, options), to: @provider

        @defimpl GenAI.Graph.NodeProtocol
        defdelegate inbound_links(subject, graph, options), to: @provider

        @defimpl GenAI.Graph.NodeProtocol
        defdelegate process_node(subject, link, container, session, context, options),
          to: @provider
      end
    end
  end
end
