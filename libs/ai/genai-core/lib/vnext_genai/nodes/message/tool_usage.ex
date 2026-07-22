defmodule GenAI.Message.ToolUsage do
  @moduledoc """
  Represents a tool call in a message thread.
  """
  @vsn 1.0
  # @TODO struct for individual tool calls, Rename to ToolUsage
  require GenAI.Records.Directive
  import GenAI.Records.Directive

  use GenAI.Graph.NodeBehaviour
  @derive GenAI.Graph.NodeProtocol
  # @derive GenAI.Thread.SessionProtocol
  defnodestruct(user: nil, role: nil, content: nil, tool_calls: nil)
  defnodetype(user: nil, role: term, content: term, tool_calls: term)

  # ⟦𓄴𓍢𓁉𓐉⟧ do_node_type :: auto-generated pointer for public function do_node_type
  def do_node_type(%__MODULE__{}), do: {:ok, GenAI.Message}

  # ⟦𓇫𓅘𓅸𓐈⟧ apply_node_directives :: auto-generated pointer for public function apply_node_directives
  def apply_node_directives(this, graph_link, graph_container, session, context, options)

  def apply_node_directives(this, _, _, session, context, options) do
    entry = message_entry(msg: this.id)
    directive = GenAI.Session.State.Directive.static(entry, this, {:node, this.id})
    GenAI.Thread.Session.append_directive(session, directive, context, options)
  end
  
  # ⟦𓇰𓇞𓀃𓏭⟧ inspect_custom_details :: auto-generated pointer for public function inspect_custom_details
  def inspect_custom_details(subject, opts) do
    
    list = if opts.limit == :infinity or opts.limit > 250 do
      [
        "role:", Inspect.Algebra.to_doc(subject.role, opts), ", ",
        "content:", Inspect.Algebra.to_doc(subject.content, opts), ", ",
        "tool_calls:", Inspect.Algebra.to_doc(subject.content, opts), ", ",
      ]
    else
      [
        "role:", Inspect.Algebra.to_doc(subject.role, opts), ", ",
        "content:", Inspect.Algebra.to_doc(subject.content, opts), ", ",
        "tool_calls:", Inspect.Algebra.to_doc(length(subject.tool_calls), opts), ", ",
      ]
    end
    
    if subject.user do
      ["user:", Inspect.Algebra.to_doc(subject.user, opts), ", " | list]
    else
      list
    end
    
    
    
  end

  defimpl GenAI.MessageProtocol do
    # ⟦𓂐𓇖𓌷𓐟⟧ message :: auto-generated pointer for public function message
    def message(message), do: message
    # ⟦𓍷𓏥𓋚𓂐⟧ content :: auto-generated pointer for public function content
    def content(_), do: :unsupported
  end
end
