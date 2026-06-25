# ===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
# ===============================================================================

defmodule GenAI.Setting.ProviderSetting do
  @moduledoc """
  Represents a Provider Setting (used by Gemini)
  """
  @vsn 1.0

  require GenAI.Records.Directive
  import GenAI.Records.Directive

  use GenAI.Graph.NodeBehaviour
  @derive GenAI.Graph.NodeProtocol
  # @derive GenAI.Thread.SessionProtocol
  defnodestruct(provider: nil, setting: nil, value: nil)
  defnodetype(provider: term, setting: term, value: term)

  def do_node_type(%__MODULE__{}), do: {:ok, GenAI.Setting}

  def apply_node_directives(this, graph_link, graph_container, session, context, options)

  def apply_node_directives(this, _, _, session, context, options) do
    entry = provider_setting_entry(provider: this.provider, setting: this.setting)
    directive = GenAI.Session.State.Directive.static(entry, this.value, {:node, this.id})
    GenAI.Thread.Session.append_directive(session, directive, context, options)
  end
  
  
  def inspect_custom_details(subject, opts) do
    [
      "provider:", Inspect.Algebra.to_doc(subject.provider, opts), ", ",
      "setting:", Inspect.Algebra.to_doc(subject.setting, opts), ", ",
      "value:", Inspect.Algebra.to_doc(subject.value, opts), ", ",
    ]
  end
  
end
