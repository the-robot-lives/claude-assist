defmodule GenAI.Support.TestProvider2 do
  @moduledoc """
  TestProvider2
  """
  use GenAI.InferenceProviderBehaviour
end

defmodule GenAI.Support.TestProvider2.Encoder do
  use GenAI.Model.EncoderBehaviour
end

defprotocol GenAI.Support.TestProvider2.EncoderProtocol do
  def encode(subject, model, session, context, options)
end

defimpl GenAI.Support.TestProvider2.EncoderProtocol, for: GenAI.Tool do
  def encode(subject, model, session, context, options)

  def encode(subject, _, session, _, _) do
    encoded = %{
      type: :function,
      function: %{
        name: subject.name,
        description: subject.description,
        parameters: subject.parameters
      }
    }

    {:ok, {encoded, session}}
  end
end

defimpl GenAI.Support.TestProvider2.EncoderProtocol, for: GenAI.Message do
  def content(content)

  def content(content) when is_bitstring(content) do
    %{type: :text, text: content}
  end

  def content(%GenAI.Message.Content.TextContent{} = content) do
    %{type: :text, text: content.text}
  end

  def content(%GenAI.Message.Content.ImageContent{} = content) do
    {:ok, encoded} = GenAI.Message.Content.ImageContent.base64(content)
    base64 = "data:image/#{content.type};base64," <> encoded
    %{type: :image_url, image_url: %{url: base64}}
  end

  def encode(subject, _, session, _, _) do
    encoded =
      case subject.content do
        x when is_bitstring(x) ->
          %{role: subject.role, content: subject.content}

        x when is_list(x) ->
          content_list = Enum.map(x, &content/1)
          %{role: subject.role, content: content_list}
      end

    {:ok, {encoded, session}}
  end
end

defimpl GenAI.Support.TestProvider2.EncoderProtocol, for: GenAI.Message.ToolResponse do
  def encode(subject, _, session, _, _) do
    encoded = %{
      role: :tool,
      tool_call_id: subject.tool_call_id,
      content: Jason.encode!(subject.tool_response)
    }

    {:ok, {encoded, session}}
  end
end

defimpl GenAI.Support.TestProvider2.EncoderProtocol, for: GenAI.Message.ToolUsage do
  def encode(subject, _, session, _, _) do
    tool_calls =
      Enum.map(
        subject.tool_calls,
        fn tc ->
          update_in(
            tc,
            [Access.key(:function), Access.key(:arguments)],
            &(&1 && Jason.encode!(&1))
          )
        end
      )

    encoded = %{
      role: subject.role,
      content: subject.content,
      tool_calls: tool_calls
    }

    {:ok, {encoded, session}}
  end
end

defmodule GenAI.Support.TestProvider2.Models do
  @moduledoc """
  TestProvider Models
  """
  def model_one() do
    GenAI.Model.new(
      provider: GenAI.Support.TestProvider2,
      encoder: GenAI.Support.TestProvider2.Encoder,
      model: "one"
    )
  end
end
