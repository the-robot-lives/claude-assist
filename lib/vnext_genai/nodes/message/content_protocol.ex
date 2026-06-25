defprotocol GenAI.Message.ContentProtocol do
  @moduledoc """
  A protocol for handling different types of content in messages.
  """

  @doc """
  Return content of a message component.
  """
  def content(message)
end

defimpl GenAI.Message.ContentProtocol, for: BitString do
  def content(text) do
    %GenAI.Message.Content.TextContent{text: text}
  end
end
