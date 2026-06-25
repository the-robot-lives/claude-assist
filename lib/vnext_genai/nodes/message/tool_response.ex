defmodule GenAI.Message.ToolResponse do
  @moduledoc """
  Represents a tool response in a message thread.
  """
  @vsn 1.0

  require GenAI.Records.Directive
  import GenAI.Records.Directive

  use GenAI.Graph.NodeBehaviour
  @derive GenAI.Graph.NodeProtocol
  # @derive GenAI.Thread.SessionProtocol
  defnodestruct(tool_name: nil, tool_response: nil, tool_call_id: nil)
  defnodetype(tool_name: term, tool_response: term, tool_call_id: term)

  def do_node_type(%__MODULE__{}), do: {:ok, GenAI.Message}

  def apply_node_directives(this, graph_link, graph_container, session, context, options)

  def apply_node_directives(this, _, _, session, context, options) do
    entry = message_entry(msg: this.id)
    directive = GenAI.Session.State.Directive.static(entry, this, {:node, this.id})
    GenAI.Thread.Session.append_directive(session, directive, context, options)
  end
  
  def inspect_custom_details(subject, opts) do
      [
        "tool_name:", Inspect.Algebra.to_doc(subject.tool_name, opts), ", ",
        "tool_response:", Inspect.Algebra.to_doc(subject.tool_response, opts), ", ",
        "tool_call_id:", Inspect.Algebra.to_doc(subject.tool_call_id, opts), ", ",
      ]
  end
  
  defimpl GenAI.MessageProtocol do
    def message(message), do: message
    def content(_), do: :unsupported
  end
end
