defmodule GenAI.Message.Content.RedactedThinkingContent do
  @moduledoc """
  Represents image part of chat message.
  """
  @vsn 1.0
  defstruct data: nil,
            vsn: @vsn

  defimpl GenAI.Message.ContentProtocol do
    def content(subject) do
      subject
    end
  end
end
