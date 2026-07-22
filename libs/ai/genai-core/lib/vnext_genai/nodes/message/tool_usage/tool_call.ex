defmodule GenAI.Message.ToolCall do
  defstruct id: nil,
            type: :function,
            tool_name: nil,
            arguments: %{}

  # ⟦𓆜𓁉𓏾𓍵⟧ to_json :: auto-generated pointer for public function to_json
  def to_json(this, format \\ :default)

  def to_json(this, :default) do
    %{
      id: this.id,
      type: this.type,
      function: %{
        name: this.tool_name,
        arguments: this.arguments
      }
    }
  end
end
