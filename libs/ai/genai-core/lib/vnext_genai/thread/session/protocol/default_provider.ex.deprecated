defmodule GenAI.Thread.SessionProtocol.DefaultProvider do
  require GenAI.Records.Session
  alias GenAI.Records.Session, as: Node
  
  #-----------------------------------------------
  # process_node
  #-----------------------------------------------
  @doc """
  Apply/process a node. check/update fingerprint and add any appropriate directives to state.
  """
  def process_node(%{__struct__: module} = graph_node, scope, context, options) do
    if Code.ensure_loaded?(module) and function_exported?(module, :process_node, 4) do
      module.process_node(graph_node, scope, context, options)
    else
      do_process_node(graph_node, scope, context, options)
    end
  end
  
  #-----------------------------------------------
  # do_process_node
  #-----------------------------------------------
  def do_process_node(graph_node, scope, context, options)
  def do_process_node(
        %{__struct__: module} = graph_node,
        scope = Node.scope(
          graph_container: graph_container,
        ),
        context,
        options) do
    
    # apply directives
    with {:ok, scope} <- process_node_directives(graph_node, scope, context, options) do
      process_node_response(graph_node, graph_container, scope)
    end
  end
  
  
  #-----------------------------------------------
  # process_node_directives
  #-----------------------------------------------
  @doc """
  Apply/process a node. check/update fingerprint and add any appropriate directives to state.
  """
  def process_node_directives(%{__struct__: module} = graph_node, scope, context, options) do
    if Code.ensure_loaded?(module) and function_exported?(module, :process_node_directives, 4) do
      module.process_node_directives(graph_node, scope, context, options)
    else
      do_process_node_directives(graph_node, scope, context, options)
    end
  end
  
  #-----------------------------------------------
  # do_process_node_directives
  #-----------------------------------------------
  def do_process_node_directives(graph_node, scope, context, options)
  def do_process_node_directives(_, scope, _, _) do
    {:ok, scope}
  end
  
  
  #-----------------------------------------------
  # process_node_response
  #-----------------------------------------------
  def process_node_response(graph_node, graph_container, update) do
    with {:ok, links} <- GenAI.Graph.NodeProtocol.outbound_links(
      graph_node,
      graph_container,
      expand: true
    ) do
      links = links
              |> Enum.map(fn {socket, links} -> links end)
              |> List.flatten()
      # Single node support only
      case links do
        [] ->
          Node.process_end(
            exit_on: {graph_node, :no_links},
            update: update
          )
        [link] ->
          Node.process_next(
            link: link,
            update: update
          )
      end
    end
  end
end
