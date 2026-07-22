defmodule GenAI.Graph.Node do
  @vsn 1.0
  @moduledoc """
  Represent a node on graph (generic type).
  """

  use GenAI.Graph.NodeBehaviour
  @derive GenAI.Graph.NodeProtocol
  # @derive GenAI.Thread.SessionProtocol
  defnodestruct(content: nil)
  defnodetype(content: term)

  # ⟦𓂤𓅃𓆠𓏣⟧ is_node? :: auto-generated pointer for public function is_node?
  def is_node?(subject) do
    GenAI.Graph.NodeProtocol.impl_for(subject)
  end

  def is_node?(subject, of_type) do
    GenAI.Graph.NodeProtocol.impl_for(subject) &&
      {:ok, of_type} == GenAI.Graph.NodeProtocol.node_type(subject)
  end
end
