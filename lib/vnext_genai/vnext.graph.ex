defmodule GenAI.VNext.Graph do
  @vsn 1.0
  @moduledoc """
  A graph data structure for representing AI graphs, threads, conversations, uml, etc. Utility Class
  """

  use GenAI.Graph.NodeBehaviour

  alias GenAI.Graph.Link
  alias GenAI.Graph.NodeProtocol
  alias GenAI.Records, as: R
  alias GenAI.Types, as: T
  # alias VNextGenAI.Session.NodeProtocol.Records, as: Node
  import GenAI.Records.Link
  import GenAI.Records.Node

  require GenAI.Records.Link
  require GenAI.Records.Node
  require GenAI.Types.Graph
  # require VNextGenAI.Session.NodeProtocol.Records

  @derive GenAI.Graph.NodeProtocol
  # @derive VNextGenAI.Session.NodeProtocol
  defnodetype(
    nodes: %{T.Graph.graph_node_id() => T.Graph.graph_node()},
    node_handles: %{T.handle() => T.Graph.graph_node_id()},
    links: %{T.Graph.graph_link_id() => T.Graph.graph_link()},
    link_handles: %{T.handle() => T.Graph.graph_link_id()},
    head: T.Graph.graph_node_id() | nil,
    last_node: T.Graph.graph_node_id() | nil,
    last_link: T.Graph.graph_link_id() | nil
  )

  defnodestruct(
    nodes: %{},
    node_handles: %{},
    links: %{},
    link_handles: %{},
    head: nil,
    last_node: nil,
    last_link: nil,
    settings: nil
  )
  
  
  
  
  def inspect_custom_details(subject, opts) do
    [
      "nodes:", Inspect.Algebra.to_doc(subject.nodes, opts), ", ",
      "links:", Inspect.Algebra.to_doc(subject.links, opts), ", ",
      "head:", Inspect.Algebra.to_doc(subject.head, opts), ", ",
      "last_node:", Inspect.Algebra.to_doc(subject.last_node, opts), ", ",
      "last_link:", Inspect.Algebra.to_doc(subject.last_link, opts), ", ",
      "settings:", Inspect.Algebra.to_doc(subject.settings, opts), ", ",
    ]
  end
  
  
  def process_node(%__MODULE__{} = subject, link, _, session, context, options) do
    with {:ok, head} <- GenAI.VNext.Graph.head(subject) do
      do_process_node(head, link, subject, session, context, options)
    end
  end

  def do_process_node(subject, link, container, session, context, options) do
    case GenAI.Graph.NodeProtocol.process_node(
           subject,
           link,
           container,
           session,
           context,
           options
         ) do
      GenAI.Records.Node.process_next(
        element: element_context(element: target, link: link, container: container),
        session: session
      ) ->
        do_process_node(target, link, container, session, context, options)

      x = process_end() ->
        x

      x = process_error() ->
        x

      x = process_yield() ->
        x
    end
  end

  @spec do_new() :: __MODULE__.t()
  @spec do_new(keyword) :: __MODULE__.t()
  def do_new(options \\ nil)

  def do_new(options) do
    settings =
      Keyword.merge(
        [
          auto_head: false,
          update_last: true,
          update_last_link: false,
          auto_link: false
        ],
        options[:settings] || []
      )

    %__MODULE__{
      id: options[:id] || UUID.uuid4(),
      handle: options[:handle] || nil,
      name: options[:name] || nil,
      description: options[:description] || nil,
      nodes: %{},
      node_handles: %{},
      links: %{},
      link_handles: %{},
      head: nil,
      last_node: nil,
      last_link: nil,
      settings: settings
    }
  end

  @spec setting(__MODULE__.t(), atom, keyword, any) :: any
  def setting(%__MODULE__{settings: settings}, setting, options, default \\ nil) do
    x = options[setting]

    cond do
      is_nil(x) or x == :default ->
        x = settings[setting]

        cond do
          x == nil -> default
          :else -> x
        end

      :else ->
        x
    end
  end

  # =============================================================================
  # Graph Protocol
  # =============================================================================

  # -------------------------
  # node/2
  # -------------------------

  @doc """
  Obtain node by id.

  ## Examples

  ### When Found
      iex> graph = GenAI.VNext.Graph.new()
      ...> node = GenAI.Graph.Node.new(id: UUID.uuid4())
      ...> graph = GenAI.VNext.Graph.add_node(graph, node)
      ...> GenAI.VNext.Graph.node(graph, node.id)
      {:ok, node}

  ### When Not Found
      iex> graph = GenAI.VNext.Graph.new()
      ...> GenAI.VNext.Graph.node(graph, UUID.uuid4())
      {:error, {:node, :not_found}}
  """
  @spec node(graph :: T.Graph.graph(), id :: T.Graph.graph_node_id()) ::
          T.result(T.Graph.graph_node(), T.details())
  def node(graph, graph_node)

  def node(graph, R.Link.connector(node: id)) do
    node(graph, id)
  end

  def node(graph, graph_node) when T.Graph.is_node_id(graph_node) do
    if x = graph.nodes[graph_node] do
      {:ok, x}
    else
      {:error, {:node, :not_found}}
    end
  end

  def node(graph, graph_node) when is_struct(graph_node) do
    with {:ok, id} <- NodeProtocol.id(graph_node) do
      node(graph, id)
    end
  end

  def do_node(graph, graph_node), do: node(graph, graph_node)

  @spec nodes(T.Graph.graph()) :: {:ok, list(T.Graph.graph_node())}
  @spec nodes(T.Graph.graph(), keyword) :: {:ok, list(T.Graph.graph_node())}
  def nodes(graph, options \\ nil)

  def nodes(graph, _) do
    nodes = Map.values(graph.nodes)
    {:ok, nodes}
  end

  # -------------------------
  # node!/2
  # -------------------------
  @spec nodes!(T.Graph.graph()) :: list(T.Graph.graph_node())
  @spec nodes!(T.Graph.graph(), keyword) :: list(T.Graph.graph_node())
  def nodes!(graph, options \\ nil)

  def nodes!(graph, _) do
    Map.values(graph.nodes)
  end

  # -------------------------
  # link/2
  # -------------------------

  @doc """
  Obtain link by id.

  ## Examples

  ### When Found
      iex> graph = GenAI.VNext.Graph.new()
      ...> node1 = GenAI.Graph.Node.new(id: UUID.uuid4())
      ...> node2 = GenAI.Graph.Node.new(id: UUID.uuid4())
      ...> graph = GenAI.VNext.Graph.add_node(graph, node1)
      ...> graph = GenAI.VNext.Graph.add_node(graph, node2)
      ...> link = GenAI.Graph.Link.new(node1.id, node2.id)
      ...> graph = GenAI.VNext.Graph.add_link(graph, link)
      ...> GenAI.VNext.Graph.link(graph, link.id)
      {:ok, link}

  ### When Not Found
      iex> graph = GenAI.VNext.Graph.new()
      ...> GenAI.VNext.Graph.link(graph, UUID.uuid4())
      {:error, {:link, :not_found}}
  """
  @spec link(graph :: T.Graph.graph(), id :: T.Graph.graph_link_id()) ::
          T.result(T.Graph.graph_link(), T.details())
  def link(graph, graph_link)

  def link(graph, graph_link) when T.Graph.is_link_id(graph_link) do
    if x = graph.links[graph_link] do
      {:ok, x}
    else
      {:error, {:link, :not_found}}
    end
  end

  def link(graph, graph_link) when is_struct(graph_link) do
    with {:ok, id} <- Link.id(graph_link) do
      node(graph, id)
    end
  end

  # -------------------------
  # member?/2
  # -------------------------

  @doc """
  Check if a node is a member of the graph.

  ## Examples

      iex> graph = GenAI.VNext.Graph.new()
      ...> node = GenAI.Graph.Node.new(id: UUID.uuid4())
      ...> graph = GenAI.VNext.Graph.add_node(graph, node)
      ...> GenAI.VNext.Graph.member?(graph, node.id)
      true

      iex> graph = GenAI.VNext.Graph.new()
      ...> GenAI.VNext.Graph.member?(graph, UUID.uuid4())
      false
  """
  @spec member?(graph :: T.Graph.graph(), id :: T.Graph.graph_node_id()) :: boolean
  def member?(graph, graph_node)

  def member?(graph, graph_node) when T.Graph.is_node_id(graph_node) do
    (graph.nodes[graph_node] && true) || false
  end

  def member?(graph, graph_node) when is_struct(graph_node) do
    with {:ok, id} <- NodeProtocol.id(graph_node) do
      member?(graph, id)
    end
  end

  # -------------------------
  # by_handle/2
  # -------------------------

  @doc """
  Obtain node by handle.

  ## Examples

  ### When Found
      iex> graph = GenAI.VNext.Graph.new()
      ...> node = GenAI.Graph.Node.new(id: UUID.uuid4(), handle: :foo)
      ...> graph = GenAI.VNext.Graph.add_node(graph, node)
      ...> GenAI.VNext.Graph.by_handle(graph, :foo)
      {:ok, node}

  ### When Not Found
      iex> graph = GenAI.VNext.Graph.new()
      ...> GenAI.VNext.Graph.by_handle(graph, :foo)
      {:error, {:handle, :not_found}}
  """
  @spec by_handle(graph :: T.Graph.graph(), handle :: T.handle()) ::
          T.result(T.Graph.graph_node(), T.details())
  def by_handle(graph, handle)

  def by_handle(graph, handle) do
    if x = graph.node_handles[handle] do
      node(graph, x)
    else
      {:error, {:handle, :not_found}}
    end
  end

  # -------------------------
  # link_by_handle/2
  # -------------------------

  @doc """
  Obtain link by handle.

  ## Examples

  ### When Found
      iex> graph = GenAI.VNext.Graph.new()
      ...> node1 = GenAI.Graph.Node.new(id: UUID.uuid4())
      ...> node2 = GenAI.Graph.Node.new(id: UUID.uuid4())
      ...> graph = GenAI.VNext.Graph.add_node(graph, node1)
      ...> graph = GenAI.VNext.Graph.add_node(graph, node2)
      ...> link = GenAI.Graph.Link.new(node1.id, node2.id, handle: :bar)
      ...> graph = GenAI.VNext.Graph.add_link(graph, link)
      ...> GenAI.VNext.Graph.link_by_handle(graph, :bar)
      {:ok, link}

  ### When Not Found
      iex> graph = GenAI.VNext.Graph.new()
      ...> GenAI.VNext.Graph.link_by_handle(graph, :bar)
      {:error, {:handle, :not_found}}
  """
  @spec link_by_handle(graph :: T.Graph.graph(), handle :: T.handle()) ::
          T.result(T.Graph.graph_link(), T.details())
  def link_by_handle(graph, handle)

  def link_by_handle(graph, handle) do
    if x = graph.link_handles[handle] do
      link(graph, x)
    else
      {:error, {:handle, :not_found}}
    end
  end

  # -------------------------
  # head/1
  # -------------------------
  @spec head(T.Graph.graph()) :: T.result(T.Graph.graph_node(), T.details())
  def head(graph)
  def head(%__MODULE__{head: nil}), do: {:error, {:head, :is_nil}}
  def head(graph = %__MODULE__{head: x}), do: node(graph, x)

  # -------------------------
  # last_node/1
  # -------------------------
  @spec last_node(T.Graph.graph()) :: T.result(T.Graph.graph_node(), T.details())
  def last_node(graph)
  def last_node(%__MODULE__{last_node: nil}), do: {:error, {:last_node, :is_nil}}
  def last_node(graph = %__MODULE__{last_node: x}), do: node(graph, x)

  # -------------------------
  # last_link/1
  # -------------------------
  @spec last_link(T.Graph.graph()) :: T.result(T.Graph.graph_link(), T.details())
  def last_link(graph)
  def last_link(%__MODULE__{last_link: nil}), do: {:error, {:last_link, :is_nil}}
  def last_link(graph = %__MODULE__{last_link: x}), do: link(graph, x)

  @spec attempt_set_handle(T.Graph.graph(), T.Graph.graph_node_id(), T.Graph.graph_node()) ::
          T.Graph.graph()
  defp attempt_set_handle(graph, id, node) do
    with {:ok, handle} <- NodeProtocol.handle(node) do
      if graph.node_handles[handle] do
        raise GenAI.Graph.Exception,
          message: "Node with handle #{handle} already defined in graph",
          details: {:handle_exists, handle}
      end

      put_in(graph, [Access.key(:node_handles), handle], id)
    else
      _ -> graph
    end
  end

  @spec attempt_set_head(T.Graph.graph(), T.Graph.graph_node_id(), T.Graph.graph_node(), keyword) ::
          T.Graph.graph()
  defp attempt_set_head(graph, id, node, options)

  defp attempt_set_head(graph, id, _, options) do
    if setting(graph, :auto_head, options, false) || options[:head] == true do
      update_in(graph, [Access.key(:head)], &(&1 || id))
    else
      graph
    end
  end

  @spec attempt_set_last_node(
          T.Graph.graph(),
          T.Graph.graph_node_id(),
          T.Graph.graph_node(),
          keyword
        ) :: T.Graph.graph()
  defp attempt_set_last_node(graph, id, node, options)

  defp attempt_set_last_node(graph, id, _, options) do
    if setting(graph, :update_last, options, false) do
      put_in(graph, [Access.key(:last_node)], id)
    else
      graph
    end
  end

  @spec auto_link_setting(T.Graph.graph(), keyword) :: any
  defp auto_link_setting(graph, options) do
    case options[:link] do
      true ->
        graph.settings[:auto_link] || true

      false ->
        false

      default when default in [nil, :default] ->
        graph.settings[:auto_link] || false

      {:template, template} ->
        if x = graph.settings[:auto_link_templates][template] do
          x
        else
          raise GenAI.Graph.Exception,
            message: "Auto Link Template #{inspect(template)} Not Found",
            details: {:template_not_found, template}
        end

      x ->
        x
    end
  end

  @spec attempt_auto_link(
          T.Graph.graph(),
          T.Graph.graph_node_id(),
          T.Graph.graph_node_id(),
          T.Graph.graph_node(),
          keyword
        ) :: T.Graph.graph()
  defp attempt_auto_link(graph, from_node, node_id, node, options)

  defp attempt_auto_link(graph, from_node, node_id, _, options) do
    auto_link = auto_link_setting(graph, options)

    cond do
      auto_link == false ->
        graph

      auto_link == true ->
        link = Link.new(from_node, node_id)
        GenAI.VNext.Graph.add_link(graph, link, options)

      is_struct(auto_link, Link) ->
        link = auto_link

        with {:ok, link} <- Link.putnew_source(link, from_node),
             {:ok, link} <- Link.putnew_target(link, node_id),
             {:ok, link} <- Link.with_id(link) do
          GenAI.VNext.Graph.add_link(graph, link, options)
        else
          {:error, details} ->
            raise GenAI.Graph.Exception,
              message: "Auto Link Failed",
              details: details
        end

      not is_struct(auto_link) and (is_map(auto_link) or is_list(auto_link)) ->
        auto_link_options = auto_link
        link = Link.new(from_node, node_id, auto_link_options)
        GenAI.VNext.Graph.add_link(graph, link, options)
    end
  end

  @spec attempt_set_node(T.Graph.graph(), T.Graph.graph_node_id(), T.Graph.graph_node(), keyword) ::
          T.Graph.graph()
  def attempt_set_node(graph, node_id, graph_node, options)

  def attempt_set_node(graph, node_id, graph_node, _) do
    if member?(graph, node_id) do
      raise GenAI.Graph.Exception,
        message: "Node with #{node_id} already defined in graph",
        details: {:node_exists, node_id}
    end

    put_in(graph, [Access.key(:nodes), node_id], graph_node)
  end

  # -------------------------
  # attach_node/3
  # -------------------------

  @doc """
  Attach a node to the graph linked to last inserted item.

  ## Examples

      iex> graph = GenAI.VNext.Graph.new()
      ...> node = GenAI.Graph.Node.new(id: UUID.uuid4())
      ...> graph = GenAI.VNext.Graph.attach_node(graph, node)
      ...> GenAI.VNext.Graph.member?(graph, node.id)
      true
  """
  @spec attach_node(graph :: T.Graph.graph(), node :: T.Graph.graph_node(), options :: map) ::
          T.result(T.Graph.graph(), T.details())
  def attach_node(graph, graph_node, options \\ nil)

  def attach_node(graph, graph_node, options) do
    options =
      Keyword.merge(
        [auto_head: true, update_last: true, update_last_link: true, link: true],
        options || []
      )

    add_node(graph, graph_node, options)
  end

  # -------------------------
  # add_node/3
  # -------------------------

  @doc """
  Add a node to the graph.

  ## Examples

      iex> graph = GenAI.VNext.Graph.new()
      ...> node = GenAI.Graph.Node.new(id: UUID.uuid4())
      ...> graph = GenAI.VNext.Graph.add_node(graph, node)
      ...> GenAI.VNext.Graph.member?(graph, node.id)
      true
  """
  @spec add_node(graph :: T.Graph.graph(), node :: T.Graph.graph_node(), options :: map) ::
          T.result(T.Graph.graph(), T.details())
  def add_node(graph, graph_node, options \\ nil)

  def add_node(graph, graph_node, options) do
    with {:ok, node_id} <- NodeProtocol.id(graph_node) do
      graph
      |> attempt_set_node(node_id, graph_node, options)
      |> attempt_set_handle(node_id, graph_node)
      |> attempt_set_head(node_id, graph_node, options)
      |> attempt_set_last_node(node_id, graph_node, options)
      |> attempt_auto_link(graph.last_node, node_id, graph_node, options)
    else
      x -> x
    end
  end

  @spec local_reference?(T.Graph.graph_link(), T.Graph.graph_link()) :: boolean
  defp local_reference?(source, target) do
    if R.Link.connector(source, :external) && R.Link.connector(target, :external) do
      false
    else
      true
    end
  end

  # -------------------------
  # add_node/3
  # -------------------------

  @doc """
  Add a link to the graph.

  ## Examples

      iex> graph = GenAI.VNext.Graph.new()
      ...> node1 = GenAI.Graph.Node.new(id: UUID.uuid4())
      ...> node2 = GenAI.Graph.Node.new(id: UUID.uuid4())
      ...> graph = GenAI.VNext.Graph.add_node(graph, node1)
      ...> graph = GenAI.VNext.Graph.add_node(graph, node2)
      ...> link = GenAI.Graph.Link.new(node1.id, node2.id)
      ...> graph = GenAI.VNext.Graph.add_link(graph, link)
      ...> GenAI.VNext.Graph.link(graph, link.id)
      {:ok, link}
  """
  @spec add_link(graph :: T.Graph.graph(), link :: T.Graph.graph_link(), options :: map) ::
          T.result(T.Graph.graph(), T.details())
  def add_link(graph, graph_link, options \\ nil)

  def add_link(graph, graph_link, options) do
    with {:ok, link_id} <- Link.id(graph_link),
         {:ok, source} <- Link.source_connector(graph_link),
         {:ok, target} <- Link.target_connector(graph_link),
         true <- local_reference?(source, target) || {:error, {:link, :local_reference_required}} do
      graph
      |> attempt_set_link(link_id, graph_link, options)
      |> attempt_set_last_link(link_id, graph_link, options)
      |> attempt_register_link(source, graph_link, options)
      |> attempt_register_link(target, graph_link, options)
    else
      {:error, details} ->
        raise GenAI.Graph.Exception,
          message: "Link Failure - #{inspect(details)}",
          details: details
    end
  end

  @spec attempt_set_link(T.Graph.graph(), T.Graph.graph_link_id(), T.Graph.graph_link(), keyword) ::
          T.Graph.graph()
  defp attempt_set_link(graph, link_id, graph_link, options)

  defp attempt_set_link(graph, link_id, graph_link, _) do
    if Map.has_key?(graph.links, link_id) do
      raise GenAI.Graph.Exception,
        message: "Link with #{link_id} already defined in graph",
        details: {:link_exists, link_id}
    end

    with {:ok, handle} <- Link.handle(graph_link) do
      graph
      |> put_in([Access.key(:link_handles), handle], link_id)
      |> put_in([Access.key(:links), link_id], graph_link)
    else
      _ ->
        put_in(graph, [Access.key(:links), link_id], graph_link)
    end
  end

  @spec attempt_set_last_link(
          T.Graph.graph(),
          T.Graph.graph_link_id(),
          T.Graph.graph_link(),
          keyword
        ) :: T.Graph.graph()
  defp attempt_set_last_link(graph, link_id, graph_link, options)

  defp attempt_set_last_link(graph, link_id, _, options) do
    if setting(graph, :update_last_link, options, false) do
      put_in(graph, [Access.key(:last_link)], link_id)
    else
      graph
    end
  end

  @spec attempt_register_link(
          T.Graph.graph(),
          T.Graph.graph_link(),
          T.Graph.graph_link(),
          keyword
        ) :: T.Graph.graph()
  defp attempt_register_link(graph, connector, link, options) do
    connector_node_id = R.Link.connector(connector, :node)

    cond do
      R.Link.connector(connector, :external) ->
        graph

      member?(graph, connector_node_id) ->
        n = graph.nodes[connector_node_id]
        {:ok, n} = NodeProtocol.register_link(n, graph, link, options)
        put_in(graph, [Access.key(:nodes), connector_node_id], n)

      :else ->
        raise GenAI.Graph.Exception,
          message: "Node Not Found",
          details: {:source_not_found, connector}
    end
  end
end

defimpl GenAI.Graph.MermaidProtocol, for: GenAI.VNext.Graph do
  @spec mermaid_id(any) :: any
  def mermaid_id(subject) do
    GenAI.Graph.MermaidProtocol.Helpers.mermaid_id(subject.id)
  end

  @spec encode(any) :: {:ok, String.t()} | {:error, any}
  def encode(graph_element), do: encode(graph_element, [])

  @spec encode(any, any) :: {:ok, String.t()} | {:error, any}
  def encode(graph_element, options), do: encode(graph_element, options, %{})

  @spec encode(any, any, any) :: {:ok, String.t()} | {:error, any}
  def encode(graph_element, options, state) do
    case GenAI.Graph.MermaidProtocol.Helpers.diagram_type(options) do
      :state_diagram_v2 -> state_diagram_v2(graph_element, options, state)
      x -> {:error, {:unsupported_diagram, x}}
    end
  end

  @spec state_diagram_v2(any, keyword, map) :: {:ok, String.t()} | {:error, any}
  def state_diagram_v2(graph_element, options, state) do
    identifier = mermaid_id(graph_element)

    headline = """
    stateDiagram-v2
    """

    if graph_element.nodes == %{} do
      body =
        GenAI.Graph.MermaidProtocol.Helpers.indent("""
        [*] --> #{identifier}
        state "Empty Graph" as #{identifier}
        """)

      graph = headline <> body
      {:ok, graph}
    else
      entry_point =
        if head = graph_element.head do
          """
          [*] --> #{GenAI.Graph.MermaidProtocol.Helpers.mermaid_id(head)}
          """
        else
          ""
        end

      # We need expanded nodes with link details
      state = update_in(state, [:container], &[graph_element | &1 || []])

      contents =
        graph_element.nodes
        |> Enum.map(fn {_, n} ->
          GenAI.Graph.MermaidProtocol.encode(n, options, state)
        end)
        |> Enum.map_join("\n", fn {:ok, x} -> x end)

      body = GenAI.Graph.MermaidProtocol.Helpers.indent(entry_point <> contents)

      graph = headline <> body
      {:ok, graph}
    end
  end
end
