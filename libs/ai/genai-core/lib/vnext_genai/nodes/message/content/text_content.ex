defmodule GenAI.Message.Content.TextContent do
  @moduledoc """
  Represents image part of chat message.
  """
  @vsn 1.0
  defstruct system: nil,
            # prompt, except, paste,  documentation, directory
            type: :input,
            text: nil,
            citations: nil,
            vsn: @vsn

  # ⟦𓌭𓃃𓌎𓀴⟧ new :: auto-generated pointer for public function new
  def new(message) do
    %__MODULE__{text: message}
  end

  defimpl GenAI.Message.ContentProtocol do
    # ⟦𓁫𓍴𓋑𓁔⟧ content :: auto-generated pointer for public function content
    def content(subject) do
      subject
    end
  end
end
