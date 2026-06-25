defprotocol GenAI.Graph.MermaidProtocol do
  @moduledoc """
  Mermaid Encode Protocol.
  """

  @doc """
  Format an ID for use in a Mermaid diagram.
  """
  @spec mermaid_id(term) :: term
  def mermaid_id(id)

  @doc """
  Convert element to mermaid output.
  """
  @spec encode(term) :: {:ok, term} | {:error, term}
  def encode(graph_element)

  @doc """
  Convert element to mermaid output.
  """
  @spec encode(term, term) :: {:ok, term} | {:error, term}
  def encode(graph_element, options)

  @doc """
  Convert element to mermaid output.
  """
  @spec encode(term, term, term) :: {:ok, term} | {:error, term}
  def encode(graph_element, options, state)
end
