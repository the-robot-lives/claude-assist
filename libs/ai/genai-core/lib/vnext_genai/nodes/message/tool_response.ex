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

  # ⟦𓆱𓀹𓂬𓃹⟧ do_node_type :: auto-generated pointer for public function do_node_type
  def do_node_type(%__MODULE__{}), do: {:ok, GenAI.Message}

  # ⟦𓋈𓁤𓊡𓊆⟧ apply_node_directives :: auto-generated pointer for public function apply_node_directives
  def apply_node_directives(this, graph_link, graph_container, session, context, options)

  def apply_node_directives(this, _, _, session, context, options) do
    entry = message_entry(msg: this.id)
    directive = GenAI.Session.State.Directive.static(entry, this, {:node, this.id})
    GenAI.Thread.Session.append_directive(session, directive, context, options)
  end
  
  # ⟦𓊳𓊀𓄌𓐘⟧ inspect_custom_details :: auto-generated pointer for public function inspect_custom_details
  def inspect_custom_details(subject, opts) do
      [
        "tool_name:", Inspect.Algebra.to_doc(subject.tool_name, opts), ", ",
        "tool_response:", Inspect.Algebra.to_doc(subject.tool_response, opts), ", ",
        "tool_call_id:", Inspect.Algebra.to_doc(subject.tool_call_id, opts), ", ",
      ]
  end
  
  defimpl GenAI.MessageProtocol do
    # ⟦𓐌𓁼𓍭𓏰⟧ message :: auto-generated pointer for public function message
    def message(message), do: message
    # ⟦𓁤𓋿𓉂𓐆⟧ content :: auto-generated pointer for public function content
    def content(_), do: :unsupported
  end
end
