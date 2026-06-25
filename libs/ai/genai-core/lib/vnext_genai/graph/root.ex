defmodule GenAI.Graph.Root do
  @vsn 1.0
  @moduledoc """
  The root data structure that contains nested graphs, nodes and other structures.
  """

  import GenAI.Records.Link

  require GenAI.Records.Link
  require GenAI.Types.Graph

  defstruct [
    # Entry Point
    graph: nil,
    # uuid => element_lookup, handle => {:resolver, %{paths => element_entry}} | element_entry
    lookup_table: %{by_element: %{}, by_handle: %{}},
    # id of last inserted node
    last_node: nil,
    # id of last inserted link
    last_link: nil
  ]

  @doc """
  Retrieve a element_lookup entry by element id.
  """
  def element_entry(this, element)
  def element_entry(_, error = {:error, _}), do: error
  def element_entry(this, element_lookup(element: element)), do: element_entry(this, element)

  def element_entry(%__MODULE__{} = this, id) do
    if entry = this.lookup_table.by_element[id] do
      {:ok, entry}
    else
      {:error, {:element, :not_found}}
    end
  end

  @doc """
  Retrieve an element_lookup entry by handle and base node
  """
  def handle_entry(this, handle, base \\ nil)

  def handle_entry(%__MODULE__{} = this, graph_handle(name: handle), base),
    do: handle_entry(this, handle, base)

  def handle_entry(%__MODULE__{} = this, handle, base) do
    if global_entry = this.lookup_table.by_handle[graph_handle(scope: :global, name: handle)] do
      element_entry(this, global_entry)
    else
      standard_entry = this.lookup_table.by_handle[graph_handle(scope: :standard, name: handle)]
      local_entries = this.lookup_table.by_handle[graph_handle(scope: :local, name: handle)] || []

      with {:ok, element_lookup(path: path)} <- element_entry(this, base) do
        {_, entry} =
          local_entries
          |> Enum.reduce(
            {0, standard_entry},
            fn
              {entry_path, entry_element}, b = {b_depth, _} ->
                e_depth = length(entry_path)

                cond do
                  e_depth > b_depth && List.starts_with?(path, entry_path) ->
                    {e_depth, entry_element}

                  :else ->
                    b
                end
            end
          )

        if entry,
          do: element_entry(this, entry),
          else: {:error, {:element, :not_found}}
      else
        _ ->
          if standard_entry,
            do: element_entry(this, standard_entry),
            else: {:error, {:element, :not_found}}
      end
    end
  end

  @max_depth 1_000_000

  defp if_element_under_path(this, element, under)
  defp if_element_under_path(_, nil, _), do: nil

  defp if_element_under_path(this, element, element_lookup(path: under_path)) do
    case element_entry(this, element) do
      entry = {:ok, element_lookup(path: entry_path)} ->
        if List.starts_with?(entry_path, under_path), do: entry

      _ ->
        nil
    end
  end

  @doc """
  Retrieve closest nested handle nested under base.
  If a global entry is found and under base it will be used.
  If a standard entry is found and under base it will be used.
  Only if no standard or global entry under base exists will locals be checked.
  """
  def nearest_handle_entry(this, handle, base)

  def nearest_handle_entry(%__MODULE__{} = this, graph_handle(name: handle), base),
    do: nearest_handle_entry(this, handle, base)

  def nearest_handle_entry(%__MODULE__{} = this, handle, base = element_lookup(path: under_path)) do
    global_entry = this.lookup_table.by_handle[graph_handle(scope: :global, name: handle)]
    standard_entry = this.lookup_table.by_handle[graph_handle(scope: :standard, name: handle)]
    local_entries = this.lookup_table.by_handle[graph_handle(scope: :local, name: handle)] || []

    cond do
      x = if_element_under_path(this, global_entry, base) ->
        x

      x = if_element_under_path(this, standard_entry, base) ->
        x

      :else ->
        {_, entry} =
          local_entries
          |> Enum.reduce(
            {@max_depth, nil},
            fn
              {entry_path, entry_element}, b = {b_depth, _} ->
                e_depth = length(entry_path)

                cond do
                  e_depth < b_depth && List.starts_with?(entry_path, under_path) ->
                    {e_depth, entry_element}

                  :else ->
                    b
                end
            end
          )

        if entry,
          do: element_entry(this, entry),
          else: {:error, {:element, :not_found}}
    end
  end

  @doc """
  Retrieve a nested element by id from graph
  """
  def element(%__MODULE__{} = this, id) do
    with {:ok, element_lookup(path: [_ | path])} <- element_entry(this, id) do
      get_nested_element(this.graph, path)
    end
  end

  @doc """
  Retrieve a nested element by handle from graph
  """
  def element_by_handle(%__MODULE__{} = this, handle, base \\ nil) do
    with {:ok, element_lookup(path: [_ | path])} <- handle_entry(this, handle, base) do
      get_nested_element(this.graph, path)
    end
  end

  @doc """
  extract nested entry by path from source element.
  """
  def get_nested_element(source, path)

  def get_nested_element(nil, _) do
    {:error, {:element, :not_found}}
  end

  def get_nested_element(element, []) do
    {:ok, element}
  end

  def get_nested_element(element, [h | t]) do
    with {:ok, nested} <- element.__struct__.node(element, h) do
      get_nested_element(nested, t)
    end
  end

  @doc """
  Merge element lookup entries
  """
  def merge_lookup_table_entries(%__MODULE__{} = this, entries) do
    update_in(
      this,
      [Access.key(:lookup_table), Access.key(:by_element)],
      &Enum.into(entries, &1 || %{})
    )
  end

  @doc """
  Merge list of {handle, element or path to element} entries into lookup table.
  """
  def merge_handles(%__MODULE__{} = this, handles) when is_list(handles) do
    Enum.reduce(handles, this, &merge_handle(&2, &1))
  end

  @doc """
  Merge a single graph handle entry into lookup table.
  """
  def merge_handle(this, {handle = graph_handle(scope: :global), element}) do
    put_in(this, [Access.key(:lookup_table), Access.key(:by_handle), handle], element)
  end

  def merge_handle(this, {handle = graph_handle(scope: :standard), element}) do
    put_in(this, [Access.key(:lookup_table), Access.key(:by_handle), handle], element)
  end

  def merge_handle(this, {handle = graph_handle(scope: :local), elements}) do
    elements = (is_list(elements) && elements) || [elements]

    update_in(
      this,
      [Access.key(:lookup_table), Access.key(:by_handle), handle],
      &(elements ++ (&1 || []))
    )
  end

  @doc """
  Retrieve graph context by link
  """
  def graph_context_by_link(this, link, from_element)

  def graph_context_by_link(
        this,
        %GenAI.Graph.Link{target: connector(node: target)} = link,
        from_element
      ) do
    {:ok, base} = GenAI.Graph.NodeProtocol.id(from_element || this.graph)
    base = element_entry(this, base)

    case target do
      anchor_link(anchor_handle: anchor, local_handle: path) ->
        anchor_base = handle_entry(this, anchor, base)
        graph_context_by_link__to_anchor_path(this, link, path, anchor_base)

      handle = graph_handle() ->
        graph_context_by_link__to_handle(this, link, handle, base)

      element ->
        graph_context_by_link__to_element(this, link, element)
    end
  end

  # --------------
  # graph_context_by_link__to_anchor_path/5
  # --------------
  defp graph_context_by_link__to_anchor_path(this, link, path, base)

  defp graph_context_by_link__to_anchor_path(this, link, path, base) when is_list(path) do
    entry = reduce_anchor_path(this, path, base)
    graph_context_by_link__entry(this, link, entry)
  end

  defp graph_context_by_link__to_anchor_path(this, link, nil, base),
    do: graph_context_by_link__to_anchor_path(this, link, [], base)

  defp graph_context_by_link__to_anchor_path(this, link, path, base) when not is_list(path),
    do: graph_context_by_link__to_anchor_path(this, link, [path], base)

  # --------------
  # graph_context_by_link__to_handle/4
  # --------------
  defp graph_context_by_link__to_handle(this, link, handle, base) do
    # return element context for a given element handle under base
    graph_context_by_link__entry(this, link, handle_entry(this, handle, base))
  end

  # --------------
  # graph_context_by_link__to_element/3
  # --------------
  defp graph_context_by_link__to_element(this, link, element) do
    # return element context for a given element identifier
    graph_context_by_link__entry(this, link, element_entry(this, element))
  end

  # --------------
  # graph_context_by_link__entry/3
  # --------------
  defp graph_context_by_link__entry(this, link, entry)

  defp graph_context_by_link__entry(this, link, {:ok, entry}),
    do: graph_context_by_link__entry(this, link, entry)

  defp graph_context_by_link__entry(this, link, element_lookup(path: [_ | path])) do
    # return element context for a given element lookup entry
    with {container_path, target_path} <- Enum.split(path, -1),
         {:ok, target_container} <- get_nested_element(this.graph, container_path),
         {:ok, target_element} <- get_nested_element(target_container, target_path) do
      {:ok, element_context(element: target_element, link: link, container: target_container)}
    end
  end

  defp graph_context_by_link__entry(_, _, entry = {:error, _}),
    do: entry

  # --------------
  # nearest_handle_entry/3
  # --------------
  defp reduce_anchor_path(this, path, base)

  defp reduce_anchor_path(this, path, {:ok, base}),
    do: reduce_anchor_path(this, path, base)

  defp reduce_anchor_path(_, _, error = {:error, _}),
    do: error

  defp reduce_anchor_path(this, path, base) do
    Enum.reduce(path, {:ok, base}, fn
      handle, {:ok, base} ->
        nearest_handle_entry(this, handle, base)

      _, error ->
        error
    end)
  end

  def process_node(subject, _, _, session, context, options) do
    subject =
      subject
      |> GenAI.Graph.Root.merge_lookup_table_entries(
        GenAI.Graph.NodeProtocol.build_node_lookup(subject.graph, [])
      )
      |> GenAI.Graph.Root.merge_handles(
        GenAI.Graph.NodeProtocol.build_handle_lookup(subject.graph, [])
      )

    session = %{session | root: subject}
    GenAI.Graph.NodeProtocol.process_node(subject.graph, nil, subject, session, context, options)
  end
end

#
# defimpl GenAI.Thread.SessionProtocol, for: GenAI.Graph.Root do
#  require GenAI.Records.Session
#  alias GenAI.Records.Session, as: Node
#
#  def process_node(subject, scope, context, options) do
#    subject = subject
#              |> GenAI.Graph.Root.merge_lookup_table_entries(GenAI.Graph.NodeProtocol.build_node_lookup(subject.graph, []))
#              |> GenAI.Graph.Root.merge_handles(GenAI.Graph.NodeProtocol.build_handle_lookup(subject.graph, []))
#
#    updated_scope = Node.scope(
#      scope,
#      graph_node: subject.graph,
#      graph_link: nil,
#      graph_container: subject,
#      session_root: subject
#    )
#    GenAI.Thread.SessionProtocol.process_node(subject.graph, updated_scope, context, options)
#  end
# end
