defmodule GenAI.Message.Content.ToolUseContent do
  @moduledoc """
  Represents image part of chat message.
  """
  @vsn 1.0
  defstruct id: nil,
            tool_name: nil,
            arguments: %{},
            vsn: @vsn

  def new(options) do
    %__MODULE__{
      id: options[:id],
      tool_name: options[:tool_name],
      arguments: options[:arguments]
    }
  end

  defimpl GenAI.Message.ContentProtocol do
    def content(subject) do
      subject
    end
  end
end
