defmodule GenAI.Graph.NodeProtocol.DefaultProvider do
  @moduledoc """
  Default provider for GenAI.Graph.NodeProtocol.
  Uses function_exported? to invoke the passed module's implementation if any for calls.
  """

  alias GenAI.Graph.Link
  alias GenAI.Types.Graph, as: G
  alias GenAI.Records, as: R
  alias GenAI.Types, as: T
  alias GenAI.Records.Link, as: L
  require GenAI.Records.Link
  require GenAI.Records.Node

  # -------------------------
  # new/2
  # -------------------------
  @spec new(module, any) :: struct
  def new(module, options) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_new, 1) do
      module.do_new(options)
    else
      do_new(module, options)
    end
  end

  @spec do_new(module, any) :: any
  def do_new(module, nil) do
    options = [
      id: UUID.uuid4(),
      inbound_links: %{},
      outbound_links: %{}
    ]

    module.__struct__(options)
  end

  def do_new(module, options) do
    core = [
      id: options[:id] || UUID.uuid4(),
      inbound_links: options[:inbound_links] || %{},
      outbound_links: options[:outbound_links] || %{}
    ]

    keys =
      module.__info__(:struct)
      |> Enum.map(& &1.field)
      |> MapSet.new()

    options =
      Keyword.merge(Enum.to_list(options), core)
      |> Enum.filter(fn {key, _} -> Enum.member?(keys, key) end)

    module.__struct__(options)
  end

  # -------------------------
  # node/2
  # -------------------------
  @spec node(G.graph_node(), term) :: T.result(G.graph_node_id(), T.details())
  def node(graph_node = %{__struct__: module}, id) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_node, 2) do
      module.do_node(graph_node, id)
    else
      {:error, {:element, :not_found}}
    end
  end

  # -------------------------
  # node/2
  # -------------------------
  @spec nodes(G.graph_node(), term) :: T.result(G.graph_node_id(), T.details())
  def nodes(graph_node = %{__struct__: module}, options \\ nil) do
    if Code.ensure_loaded?(module) and function_exported?(module, :nodes, 2) do
      module.nodes(graph_node, options)
    else
      {:ok, []}
    end
  end

  def build_node_lookup(graph_node, options \\ nil) do
    with {:ok, id} <- GenAI.Graph.NodeProtocol.id(graph_node),
         {:ok, type} <- GenAI.Graph.NodeProtocol.node_type(graph_node),
         {:ok, nodes} <- GenAI.Graph.NodeProtocol.nodes(graph_node, options) do
      path =
        cond do
          v = options[:path] -> v ++ [id]
          :else -> [id]
        end

      options = put_in(options || %{}, [:path], path)

      my_entry =
        (path == [id] &&
           [
             {id,
              L.element_lookup(
                element: id,
                path: path,
                type: type,
                implementation: graph_node.__struct__
              )}
           ]) || []

      response =
        Enum.map(
          nodes,
          fn n ->
            {:ok, id2} = GenAI.Graph.NodeProtocol.id(n)
            {:ok, nt} = GenAI.Graph.NodeProtocol.node_type(n)

            [
              {id2,
               L.element_lookup(
                 element: id2,
                 path: path ++ [id2],
                 type: nt,
                 implementation: n.__struct__
               )}
              | GenAI.Graph.NodeProtocol.build_node_lookup(n, options)
            ]
          end
        )
        |> List.flatten()

      response ++ my_entry
    end
  end

  def build_handle_lookup(graph_node, options \\ nil) do
    with {:ok, id} <- GenAI.Graph.NodeProtocol.id(graph_node),
         {:ok, nodes} <- GenAI.Graph.NodeProtocol.nodes(graph_node, options) do
      path =
        cond do
          v = options[:path] -> v ++ [id]
          :else -> [id]
        end

      options = put_in(options || %{}, [:path], path)

      my_entry =
        (path == [id] &&
           case GenAI.Graph.NodeProtocol.handle_record(graph_node) do
             {:ok, h = L.graph_handle(scope: :global)} -> [{h, id}]
             {:ok, h = L.graph_handle(scope: :standard)} -> [{h, id}]
             {:ok, h = L.graph_handle(scope: :local)} -> [{h, {path, id}}]
             _ -> []
           end) || []

      response =
        Enum.map(
          nodes,
          fn n ->
            {:ok, id2} = GenAI.Graph.NodeProtocol.id(n)

            case GenAI.Graph.NodeProtocol.handle_record(n) do
              {:ok, h = L.graph_handle(scope: :global)} ->
                [{h, id2} | GenAI.Graph.NodeProtocol.build_handle_lookup(n, options)]

              {:ok, h = L.graph_handle(scope: :standard)} ->
                [{h, id2} | GenAI.Graph.NodeProtocol.build_handle_lookup(n, options)]

              {:ok, h = L.graph_handle(scope: :local)} ->
                [{h, {path, id2}} | GenAI.Graph.NodeProtocol.build_handle_lookup(n, options)]

              _ ->
                GenAI.Graph.NodeProtocol.build_handle_lookup(n, options)
            end
          end
        )
        |> List.flatten()

      response ++ my_entry
    end
  end

  # -------------------------
  # node_type/1
  # -------------------------
  @spec node_type(G.graph_node()) :: T.result(G.graph_node_id(), T.details())
  def node_type(graph_node = %{__struct__: module}) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_node_type, 1) do
      module.do_node_type(graph_node)
    else
      do_node_type(graph_node)
    end
  end

  @spec do_node_type(G.graph_node()) :: T.result(G.graph_node_id(), T.details())
  def do_node_type(graph_node)
  def do_node_type(%{__struct__: module}), do: {:ok, module}

  # -------------------------
  # id/1
  # -------------------------
  @spec id(G.graph_node()) :: T.result(G.graph_node_id(), T.details())
  def id(graph_node = %{__struct__: module}) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_id, 1) do
      module.do_id(graph_node)
    else
      do_id(graph_node)
    end
  end

  @spec do_id(G.graph_node()) :: T.result(G.graph_node_id(), T.details())
  def do_id(graph_node)
  def do_id(%{id: nil}), do: {:error, {:id, :is_nil}}
  def do_id(%{id: id}), do: {:ok, id}

  # -------------------------
  # handle/1
  # -------------------------
  @spec handle(G.graph_node()) :: T.result(T.handle(), T.details())
  def handle(graph_node = %{__struct__: module}) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_handle, 1) do
      module.do_handle(graph_node)
    else
      do_handle(graph_node)
    end
  end

  @spec do_handle(G.graph_node()) :: T.result(T.handle(), T.details())
  def do_handle(graph_node)
  def do_handle(%{handle: nil}), do: {:error, {:handle, :is_nil}}
  def do_handle(%{handle: L.graph_handle(name: handle)}), do: {:ok, handle}
  def do_handle(%{handle: handle}), do: {:ok, handle}

  # -------------------------
  # handle_record/1
  # -------------------------
  @spec handle_record(G.graph_node()) :: T.result(T.handle(), T.details())
  def handle_record(graph_node = %{__struct__: module}) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_handle_record, 1) do
      module.do_handle_record(graph_node)
    else
      do_handle_record(graph_node)
    end
  end

  @spec do_handle_record(G.graph_node()) :: T.result(T.handle(), T.details())
  def do_handle_record(graph_node)
  def do_handle_record(%{handle: nil}), do: {:error, {:handle, :is_nil}}
  def do_handle_record(%{handle: handle}), do: {:ok, handle}

  # -------------------------
  # handle/2
  # -------------------------
  @spec handle(G.graph_node(), T.handle()) :: T.result(T.handle(), T.details())
  def handle(graph_node = %{__struct__: module}, default) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_handle, 2) do
      module.do_handle(graph_node, default)
    else
      do_handle(graph_node, default)
    end
  end

  @spec do_handle(G.graph_node(), T.handle()) :: T.result(T.handle(), T.details())
  def do_handle(graph_node, default)
  def do_handle(%{handle: nil}, default), do: {:ok, default}
  def do_handle(%{handle: handle}, _), do: {:ok, handle}

  # -------------------------
  # name/1
  # -------------------------
  @spec name(G.graph_node()) :: T.result(T.name(), T.details())
  def name(graph_node = %{__struct__: module}) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_name, 1) do
      module.do_name(graph_node)
    else
      do_name(graph_node)
    end
  end

  @spec do_name(G.graph_node()) :: T.result(T.name(), T.details())
  def do_name(graph_node)
  def do_name(%{name: nil}), do: {:error, {:name, :is_nil}}
  def do_name(%{name: name}), do: {:ok, name}

  # -------------------------
  # name/2
  # -------------------------
  @spec name(G.graph_node(), T.name()) :: T.result(T.name(), T.details())
  def name(graph_node = %{__struct__: module}, default) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_name, 2) do
      module.do_name(graph_node, default)
    else
      do_name(graph_node, default)
    end
  end

  @spec do_name(G.graph_node(), T.name()) :: T.result(T.name(), T.details())
  def do_name(graph_node, default)
  def do_name(%{name: nil}, default), do: {:ok, default}
  def do_name(%{name: name}, _), do: {:ok, name}

  # -------------------------
  # description/1
  # -------------------------
  @spec description(G.graph_node()) :: T.result(T.description(), T.details())
  def description(graph_node = %{__struct__: module}) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_description, 1) do
      module.do_description(graph_node)
    else
      do_description(graph_node)
    end
  end

  @spec do_description(G.graph_node()) :: T.result(T.description(), T.details())
  def do_description(graph_node)
  def do_description(%{description: nil}), do: {:error, {:description, :is_nil}}
  def do_description(%{description: description}), do: {:ok, description}

  # -------------------------
  # description/2
  # -------------------------
  @spec description(G.graph_node(), T.description()) :: T.result(T.description(), T.details())
  def description(graph_node = %{__struct__: module}, default) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_description, 2) do
      module.do_description(graph_node, default)
    else
      do_description(graph_node, default)
    end
  end

  @spec do_description(G.graph_node(), T.description()) :: T.result(T.description(), T.details())
  def do_description(graph_node, default)
  def do_description(%{description: nil}, default), do: {:ok, default}
  def do_description(%{description: description}, _), do: {:ok, description}

  # -------------------------
  # with_id/2
  # -------------------------
  @spec with_id(G.graph_node()) :: T.result(G.graph_node(), T.details())
  def with_id(graph_node = %{__struct__: module}) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_with_id, 1) do
      module.do_with_id(graph_node)
    else
      do_with_id(graph_node)
    end
  end

  @spec do_with_id(G.graph_node()) :: T.result(G.graph_node(), T.details())
  def do_with_id(graph_node) do
    graph_node
    |> do_with_id!()
    |> then(&{:ok, &1})
  end

  @spec do_with_id!(G.graph_node()) :: G.graph_node()
  def do_with_id!(graph_node) do
    cond do
      graph_node.id == nil ->
        put_in(graph_node, [Access.key(:id)], UUID.uuid4())

      graph_node.id == :auto ->
        put_in(graph_node, [Access.key(:id)], UUID.uuid4())

      :else ->
        graph_node
    end
  end

  # -------------------------
  # register_link/5
  # -------------------------
  @spec register_link(G.graph_node(), G.graph(), G.graph_link(), map) ::
          T.result(G.graph_node(), T.details())
  def register_link(graph_node = %{__struct__: module}, graph, link, options) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_register_link, 4) do
      module.do_register_link(graph_node, graph, link, options)
    else
      do_register_link(graph_node, graph, link, options)
    end
  end

  @spec do_register_link(G.graph_node(), G.graph(), G.graph_link(), map) ::
          T.result(G.graph_node(), T.details())
  def do_register_link(graph_node, graph, link, options)

  def do_register_link(graph_node, _, link, _) do
    with {:ok, link_id} <- Link.id(link),
         {:ok, source} <- Link.source_connector(link),
         {:ok, target} <- Link.target_connector(link) do
      # 1. For Source Node
      graph_node =
        if R.Link.connector(source, :node) == graph_node.id do
          update_in(
            graph_node,
            [Access.key(:outbound_links), R.Link.connector(source, :socket)],
            &Enum.uniq([link_id | &1 || []])
          )
        else
          graph_node
        end

      # 2. For Target Node
      graph_node =
        if R.Link.connector(target, :node) == graph_node.id do
          update_in(
            graph_node,
            [Access.key(:inbound_links), R.Link.connector(target, :socket)],
            &Enum.uniq([link_id | &1 || []])
          )
        else
          graph_node
        end

      {:ok, graph_node}
    end
  end

  # -------------------------
  # outbound_links/4
  # -------------------------
  @spec outbound_links(G.graph_node(), G.graph(), map) :: {:ok, map} | {:error, term}
  def outbound_links(graph_node = %{__struct__: module}, graph, options) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_outbound_links, 3) do
      module.do_outbound_links(graph_node, graph, options)
    else
      do_outbound_links(graph_node, graph, options)
    end
  end

  @spec do_outbound_links(G.graph_node(), G.graph(), map) :: {:ok, map} | {:error, term}
  def do_outbound_links(graph_node, graph, options) do
    if options[:expand] do
      links =
        graph_node.outbound_links
        |> Enum.map(fn {socket, link_ids} ->
          links =
            Enum.map(
              link_ids,
              fn link_id ->
                {:ok, link} = GenAI.VNext.Graph.link(graph, link_id)
                link
              end
            )

          {socket, links}
        end)
        |> Map.new()

      {:ok, links}
    else
      {:ok, graph_node.outbound_links}
    end
  end

  # -------------------------
  # inbound_links/4
  # -------------------------
  @spec inbound_links(G.graph_node(), G.graph(), map) :: {:ok, map} | {:error, term}
  def inbound_links(graph_node = %{__struct__: module}, graph, options) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_inbound_links, 3) do
      module.do_inbound_links(graph_node, graph, options)
    else
      do_inbound_links(graph_node, graph, options)
    end
  end

  @spec do_inbound_links(G.graph_node(), G.graph(), map) :: {:ok, map} | {:error, term}
  def do_inbound_links(graph_node, graph, options) do
    if options[:expand] do
      links =
        graph_node.inbound_links
        |> Enum.map(fn {socket, link_ids} ->
          links =
            Enum.map(
              link_ids,
              fn link_id ->
                {:ok, link} = GenAI.VNext.Graph.link(graph, link_id)
                link
              end
            )

          {socket, links}
        end)
        |> Map.new()

      {:ok, links}
    else
      {:ok, graph_node.inbound_links}
    end
  end

  # -----------------------------------------------
  # process_node
  # -----------------------------------------------
  @doc """
  Apply/process a node. check/update fingerprint and add any appropriate directives to state.
  """
  def process_node(graph_node, graph_link, graph_container, session, context, options)

  def process_node(
        %{__struct__: module} = graph_node,
        graph_link,
        graph_container,
        session,
        context,
        options
      ) do
    # apply directives
    if Code.ensure_loaded?(module) and function_exported?(module, :process_node, 6) do
      module.process_node(graph_node, graph_link, graph_container, session, context, options)
    else
      do_process_node(graph_node, graph_link, graph_container, session, context, options)
    end
  end

  # -----------------------------------------------
  # do_process_node
  # -----------------------------------------------
  def do_process_node(graph_node, graph_link, graph_container, session, context, options)

  def do_process_node(graph_node, graph_link, graph_container, session, context, options) do
    with {:ok, session} <-
           apply_node_directives(
             graph_node,
             graph_link,
             graph_container,
             session,
             context,
             options
           ) do
      process_node_response(graph_node, graph_link, graph_container, session, context, options)
    end
  end

  # -----------------------------------------------
  # apply_node_directives
  # -----------------------------------------------
  @doc """
  Apply/process a node. check/update fingerprint and add any appropriate directives to state.
  """
  def apply_node_directives(graph_node, graph_link, graph_container, session, context, options)

  def apply_node_directives(
        %{__struct__: module} = graph_node,
        graph_link,
        graph_container,
        session,
        context,
        options
      ) do
    if Code.ensure_loaded?(module) and function_exported?(module, :apply_node_directives, 6) do
      module.apply_node_directives(
        graph_node,
        graph_link,
        graph_container,
        session,
        context,
        options
      )
    else
      {:ok, session}
    end
  end

  # -----------------------------------------------
  # process_node_response
  # -----------------------------------------------
  @doc """
  Apply/process a node. check/update fingerprint and add any appropriate directives to state.
  """
  def process_node_response(graph_node, graph_link, graph_container, session, context, options)

  def process_node_response(
        %{__struct__: module} = graph_node,
        graph_link,
        graph_container,
        session,
        context,
        options
      ) do
    if Code.ensure_loaded?(module) and function_exported?(module, :process_node_response, 6) do
      module.process_node_response(
        graph_node,
        graph_link,
        graph_container,
        session,
        context,
        options
      )
    else
      do_process_node_response(graph_node, graph_link, graph_container, session, context, options)
    end
  end

  # -----------------------------------------------
  # do_process_node_response
  # -----------------------------------------------
  def do_process_node_response(graph_node, graph_link, graph_container, session, context, options)

  def do_process_node_response(graph_node, graph_link, graph_container, session, _, _) do
    case fetch_outbound_links(graph_node, graph_link, graph_container) do
      {:ok, []} ->
        GenAI.Records.Node.process_end(session: session)

      {:ok, [link]} ->
        with {:ok, element} <-
               GenAI.Graph.Root.graph_context_by_link(session.root, link, graph_node) do
          GenAI.Records.Node.process_next(element: element, session: session)
        end
    end
  end

  # ===============================================
  # Private Helpers
  # ===============================================
  defp fetch_outbound_links(graph_node, graph_link, graph_container)
  defp fetch_outbound_links(graph_node, _, graph_container) do
    with {:ok, links} <-
           GenAI.Graph.NodeProtocol.outbound_links(
             graph_node,
             graph_container,
             expand: true
           ) do
      links =
        links
        |> Enum.map(fn {_, x} -> x end)
        |> List.flatten()

      {:ok, links}
    end
  end
  
  def inspect_custom_details(subject, opts)
  def inspect_custom_details(_, _), do: []
  
  def inspect_low_detail(%{__struct__: module} = subject, opts) do
    
    id = case UUID.info(subject.id) do
      {:ok, _} -> ShortUUID.encode!(subject.id)
      _ -> subject.id
    end
    
    name_field = subject.name && ["name: ", Inspect.Algebra. to_doc(subject.name, opts), ", "] || []
    description_field = subject.description && ["name: ", Inspect.Algebra. to_doc(subject.description, opts), ", "] || []
    
    top_fields = [
      "##{subject.__struct__}<",
      "id: ", Inspect.Algebra. to_doc(id, opts), ", ",
    ] ++ name_field ++ description_field

    middle_fields = module.inspect_custom_details(subject, opts)
    
    inbound = Enum.map(subject.inbound_links, fn  {socket, links} -> {socket, length(links)} end)
              |> Enum.into(%{})
    outbound = Enum.map(subject.outbound_links, fn  {socket, links} -> {socket, length(links)} end)
               |> Enum.into(%{})
    
    bottom_fields =
      [
        "inbound_links: ", Inspect.Algebra. to_doc(inbound, opts), ", ",
        "outbound_links: ", Inspect.Algebra. to_doc(outbound, opts),
        ">"
      ]
    Inspect.Algebra.concat(top_fields ++ middle_fields ++ bottom_fields)
  end
  
  def inspect_medium_detail(subject, opts) do
    inspect_low_detail(subject, opts)
  end
  
  require GenAI.Records.Link
  def inspect_high_detail(%{__struct__: module} = subject, opts) do
    
    {:ok, inbound_links} = GenAI.Graph.NodeProtocol.inbound_links(subject, %{}, expand: true)
    inbound_links = inbound_links
                    |> Enum.map(
                         fn {socket, links} ->
                           links = Enum.map(links, fn %{source: GenAI.Records.Link.connector(node: node)} -> node end)
                           {socket, links}
                         end)
                    |> Enum.into(%{})
    {:ok, outbound_links} = GenAI.Graph.NodeProtocol.outbound_links(subject, %{}, expand: true)
    outbound_links = outbound_links
                    |> Enum.map(
                         fn {socket, links} ->
                           links = Enum.map(links, fn %{target: GenAI.Records.Link.connector(node: node)} -> node end)
                           {socket, links}
                         end)
                    |> Enum.into(%{})
    
    
    
    top_fields = [
      "##{subject.__struct__}<",
      "id: ", Inspect.Algebra. to_doc(subject.id, opts), ", ",
      "name: ", Inspect.Algebra. to_doc(subject.name, opts), ", ",
      "description: ", Inspect.Algebra. to_doc(subject.description || "N/A", opts), ", "
    ]
    middle_fields = module.inspect_custom_details(subject, opts)
    bottom_fields =
      [
        "inbound_links: ", Inspect.Algebra. to_doc(inbound_links, opts), ", ",
        "outbound_links: ", Inspect.Algebra. to_doc(outbound_links, opts),
        ">"
      ]
    Inspect.Algebra.concat(top_fields ++ middle_fields ++ bottom_fields)
  end
  
  def inspect_full_detail(subject, opts) do
    Inspect.Algebra.to_doc(Map.from_struct(subject), opts)
  end
  
end
