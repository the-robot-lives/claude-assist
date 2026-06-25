defmodule GenAI.Message.Content.ThinkingContent do
  @moduledoc """
  Represents image part of chat message.
  """
  @vsn 1.0
  defstruct thinking: nil,
            signature: nil,
            vsn: @vsn

  defimpl GenAI.Message.ContentProtocol do
    def content(subject) do
      subject
    end
  end
end
