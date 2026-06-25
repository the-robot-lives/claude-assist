# ===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
# ===============================================================================

defmodule GenAI.Setting.SafetySetting do
  @moduledoc """
  Represents a Model Safety Setting (used by Gemini)
  """
  @vsn 1.0

  require GenAI.Records.Directive
  import GenAI.Records.Directive

  use GenAI.Graph.NodeBehaviour
  @derive GenAI.Graph.NodeProtocol
  # @derive GenAI.Thread.SessionProtocol
  defnodestruct(category: nil, threshold: nil)
  defnodetype(category: term, threshold: term)

  def do_node_type(%__MODULE__{}), do: {:ok, GenAI.Setting}

  def apply_node_directives(this, graph_link, graph_container, session, context, options)

  def apply_node_directives(this, _, _, session, context, options) do
    entry = safety_setting_entry(category: this.category)
    directive = GenAI.Session.State.Directive.static(entry, this.threshold, {:node, this.id})
    GenAI.Thread.Session.append_directive(session, directive, context, options)
  end
  
  def inspect_custom_details(subject, opts) do
    [
      "category:", Inspect.Algebra.to_doc(subject.category, opts), ", ",
      "threshold:", Inspect.Algebra.to_doc(subject.threshold, opts), ", ",
    ]
  end
  
end
