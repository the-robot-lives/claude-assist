# ===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
# ===============================================================================

defmodule GenAI.Setting.ModelSetting do
  @moduledoc """
  Represents a Provider Setting (used by Gemini)
  """
  @vsn 1.0

  require GenAI.Records.Directive
  import GenAI.Records.Directive

  use GenAI.Graph.NodeBehaviour
  @derive GenAI.Graph.NodeProtocol
  # @derive GenAI.Thread.SessionProtocol
  defnodestruct(model: nil, setting: nil, value: nil)
  defnodetype(model: nil, setting: term, value: term)

  # ⟦𓈂𓅬𓐜𓊷⟧ do_node_type :: auto-generated pointer for public function do_node_type
  def do_node_type(%__MODULE__{}), do: {:ok, GenAI.Setting}

  # ⟦𓋿𓆶𓄟𓍗⟧ apply_node_directives :: auto-generated pointer for public function apply_node_directives
  def apply_node_directives(this, graph_link, graph_container, session, context, options)

  def apply_node_directives(this, _, _, session, context, options) do
    entry = model_setting_entry(model: this.model, setting: this.setting)
    directive = GenAI.Session.State.Directive.static(entry, this.value, {:node, this.id})
    GenAI.Thread.Session.append_directive(session, directive, context, options)
  end
  
  # ⟦𓌈𓋬𓋓𓈰⟧ inspect_custom_details :: auto-generated pointer for public function inspect_custom_details
  def inspect_custom_details(subject, opts) do
    [
      "model:", Inspect.Algebra.to_doc(subject.model, opts), ", ",
      "provider:", Inspect.Algebra.to_doc(subject.provider, opts), ", ",
      "setting:", Inspect.Algebra.to_doc(subject.setting, opts), ", ",
      "value:", Inspect.Algebra.to_doc(subject.value, opts), ", ",
    ]
  end
  
end
