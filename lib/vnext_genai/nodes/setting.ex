defmodule GenAI.Setting do
  @moduledoc """
  A module representing a setting node in a graph structure.
  This module defines the structure and behavior of a setting node,
  including its identifier, setting, and value.
  """
  @vsn 1.0

  # import GenAI.Records.Session, only: [scope: 1, scope: 2]
  # require GenAI.Records.Session
  require GenAI.Records.Directive
  import GenAI.Records.Directive

  use GenAI.Graph.NodeBehaviour
  @derive GenAI.Graph.NodeProtocol
  # @derive GenAI.Thread.SessionProtocol
  defnodestruct(setting: nil, value: nil)
  defnodetype(setting: term, value: term)

  def apply_node_directives(this, graph_link, graph_container, session, context, options)

  def apply_node_directives(this, _, _, session, context, options) do
    entry = setting_entry(setting: this.setting)
    directive = GenAI.Session.State.Directive.static(entry, this.value, {:node, this.id})
    GenAI.Thread.Session.append_directive(session, directive, context, options)
  end
  
  def inspect_custom_details(subject, opts) do
    [
      "setting:", Inspect.Algebra.to_doc(subject.setting, opts), ", ",
      "value:", Inspect.Algebra.to_doc(subject.value, opts), ", ",
    ]
  end
  
end
