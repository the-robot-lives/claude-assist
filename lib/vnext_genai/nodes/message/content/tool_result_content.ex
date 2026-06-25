defmodule GenAI.Message.Content.ToolResultContent do
  @moduledoc """
  Represents image part of chat message.
  """
  @vsn 1.0
  defstruct tool_name: nil,
            tool_use_id: nil,
            response: nil,
            fetched_at: nil,
            cached_at: nil,
            expires_at: nil,
            vsn: @vsn

  def new(options) do
    %__MODULE__{
      tool_name: options[:tool_name] || options[:name],
      tool_use_id: options[:tool_use_id],
      response: options[:response],
      fetched_at: options[:fetched_at],
      cached_at: options[:cached_at],
      expires_at: options[:expires_at]
    }
  end

  defimpl GenAI.Message.ContentProtocol do
    def content(subject) do
      subject
    end
  end
end
