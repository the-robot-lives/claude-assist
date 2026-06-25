defmodule GenAI.Support.TestProvider do
  @moduledoc """
  TestProvider.
  """
  use GenAI.InferenceProviderBehaviour

  def run_inference(thread_context, body, model_name, provider)

  def run_inference(thread_context, _, model_name, provider) do
    choice = %GenAI.ChatCompletion.Choice{
      index: 0,
      message: GenAI.Message.assistant("I'm afraid I can't do that Dave."),
      finish_reason: :finished
    }

    usage = %GenAI.ChatCompletion.Usage{
      prompt_tokens: 200,
      completion_tokens: 20,
      total_tokens: 220
    }

    completion =
      GenAI.ChatCompletion.new(
        model: model_name,
        provider: provider,
        seed: 1,
        choices: [choice],
        usage: usage
      )

    {:ok, {completion, thread_context}}
  end

  def do_run(thread_context, context, options)

  def do_run(thread_context, context, options) do
    with {:ok, {model, thread_context}} <-
           GenAI.ThreadProtocol.effective_model(thread_context, context, options),
         {:ok, {settings, thread_context}} <-
           GenAI.ThreadProtocol.effective_settings(thread_context, context, options),
         {:ok, {safety_settings, thread_context}} <-
           GenAI.ThreadProtocol.effective_safety_settings(thread_context, context, options),
         {:ok, {model_settings, thread_context}} <-
           GenAI.ThreadProtocol.effective_model_settings(thread_context, model, context, options),
         {:ok, {provider_settings, thread_context}} <-
           GenAI.ThreadProtocol.effective_provider_settings(
             thread_context,
             model,
             context,
             options
           ),
         {:ok, model_encoder} <- GenAI.ModelProtocol.encoder(model),
         {:ok, model_name} <- GenAI.ModelProtocol.name(model),
         {:ok, provider} <- GenAI.ModelProtocol.provider(model),
         {:ok, {tools, thread_context}} <-
           GenAI.ThreadProtocol.effective_tools(thread_context, model, context, options),
         {:ok, {messages, thread_context}} <-
           GenAI.ThreadProtocol.effective_messages(thread_context, model, context, options) do
      {:ok, thread_context} =
        GenAI.ThreadProtocol.set_artifact(thread_context, :api_key, provider_settings[:api_key])

      {:ok, thread_context} =
        GenAI.ThreadProtocol.set_artifact(thread_context, :api_key, provider_settings[:api_org])

      {:ok, thread_context} =
        GenAI.ThreadProtocol.set_artifact(thread_context, :messages, messages)

      {:ok, thread_context} = GenAI.ThreadProtocol.set_artifact(thread_context, :tools, tools)

      {:ok, thread_context} =
        GenAI.ThreadProtocol.set_artifact(thread_context, :model_settings, model_settings)

      {:ok, thread_context} =
        GenAI.ThreadProtocol.set_artifact(thread_context, :safety_settings, safety_settings)

      body =
        %{
          model: model_name,
          messages: messages
        }
        |> model_encoder.with_dynamic_setting(:frequency_penalty, model, settings)
        |> model_encoder.with_dynamic_setting(:logprobe, model, settings)
        |> model_encoder.with_dynamic_setting(:top_logprobs, model, settings)
        |> model_encoder.with_dynamic_setting(:logit_bias, model, settings)
        |> model_encoder.with_dynamic_setting(:max_tokens, model, settings)
        |> model_encoder.with_dynamic_setting(:frequency_penalty, model, settings)
        |> model_encoder.with_dynamic_setting_as(:n, :completion_choices, model, settings)
        |> model_encoder.with_dynamic_setting(:presence_penalty, model, settings)
        |> model_encoder.with_dynamic_setting(:response_format, model, settings)
        |> model_encoder.with_dynamic_setting(:seed, model, settings)
        |> model_encoder.with_dynamic_setting(:stop, model, settings)
        |> model_encoder.with_dynamic_setting(:temperature, model, settings)
        |> model_encoder.with_dynamic_setting(:top_p, model, settings)
        |> model_encoder.with_dynamic_setting(:user, model, settings)
        |> then(fn
          body ->
            if tools == [] do
              body
            else
              body
              |> with_setting(:tool_choice, settings)
              |> Map.put(:tools, tools)
            end
        end)

      {:ok, thread_context} = GenAI.ThreadProtocol.set_artifact(thread_context, :body, body)
      run_inference(thread_context, body, model_name, provider)
    end
  end
end

defmodule GenAI.Support.TestProvider.EncoderOne do
  @moduledoc """
  TestProvider Encoder
  """
  use GenAI.Model.EncoderBehaviour

  require GenAI.Records.Directive

  def headers(model, settings, session, context, options)

  def headers(_, _, session, _, _) do
    {:ok, {[], session}}
  end

  def endpoint(model, settings, session, context, options)

  def endpoint(_, _, session, _, _) do
    {:ok, {{:get, "https://noizu.com"}, session}}
  end

  def request_body(model, messages, tools, settings, session, _, _) do
    with {:ok, model_name} <- GenAI.ModelProtocol.name(model) do
      # TODO Enum map hyper_params
      body = %{
               model: model_name,
               messages: messages
             }
             |> with_dynamic_setting(:frequency_penalty, model, settings)
             |> with_dynamic_setting(:logprobe, model, settings)
             |> with_dynamic_setting(:top_logprobs, model, settings)
             |> with_dynamic_setting(:logit_bias, model, settings)
             |> with_dynamic_setting(:max_tokens, model, settings)
             |> with_dynamic_setting(:frequency_penalty, model, settings)
             |> with_dynamic_setting_as(:n, :completion_choices, model, settings)
             |> with_dynamic_setting(:presence_penalty, model, settings)
             |> with_dynamic_setting(:response_format, model, settings)
             |> with_dynamic_setting(:seed, model, settings)
             |> with_dynamic_setting(:stop, model, settings)
             |> with_dynamic_setting(:temperature, model, settings)
             |> with_dynamic_setting(:top_p, model, settings)
             |> with_dynamic_setting(:user, model, settings)
             |> then(fn
        body ->
          if tools == [] do
            body
          else
            body
            |> GenAI.InferenceProvider.Helpers.with_setting(:tool_choice, settings)
            |> Map.put(:tools, tools)
          end
      end)
      {:ok, {body, session}}
      
      
      
    end
  end

  # ----------------------
  #
  # ----------------------
  def encode_tool(tool = %GenAI.Tool{}, _, thread_context, _, _) do
    encoded = %{
      type: :function,
      function: %{
        name: tool.name,
        description: tool.description,
        parameters: tool.parameters
      }
    }

    {:ok, {encoded, thread_context}}
  end

  # ----------------------
  #
  # ----------------------
  def encode_message(message, model, thread_context, context, options)

  def encode_message(message = %GenAI.Message{}, _, thread_context, _, _) do
    encoded = %{role: message.role, content: message.content}
    {:ok, {encoded, thread_context}}
  end

  def encode_message(message = %GenAI.Message.ToolResponse{}, _, thread_context, _, _) do
    encoded = %{
      role: :tool,
      tool_call_id: message.tool_call_id,
      content: Jason.encode!(message.tool_response)
    }

    {:ok, {encoded, thread_context}}
  end

  def encode_message(message = %GenAI.Message.ToolUsage{}, _, thread_context, _, _) do
    tool_calls =
      Enum.map(
        message.tool_calls,
        fn tc ->
          update_in(
            tc,
            [Access.key(:function), Access.key(:arguments)],
            &(&1 && Jason.encode!(&1))
          )
        end
      )

    encoded = %{
      role: message.role,
      content: message.content,
      tool_calls: tool_calls
    }

    {:ok, {encoded, thread_context}}
  end

  # ----------------------
  #
  # ----------------------
  def normalize_messages(messages, model, thread_context, context, options)

  def normalize_messages(messages, _, thread_context, _, _) do
    {:ok, {messages, thread_context}}
  end

  # ----------------------
  #
  # ----------------------
  def with_dynamic_setting(body, setting, model, settings, default \\ nil)

  def with_dynamic_setting(body, setting, model, settings, default) do
    with_dynamic_setting_as(body, setting, setting, model, settings, default)
  end

  # ----------------------
  #
  # ----------------------
  def with_dynamic_setting_as(body, as_setting, setting, model, settings, default \\ nil)

  def with_dynamic_setting_as(body, as_setting, setting, _, settings, default) do
    GenAI.InferenceProvider.Helpers.with_setting_as(body, as_setting, setting, settings, default)
  end

  # ----------------------
  #
  # ----------------------
  def hyper_params(model, settings, session, context, options \\ nil)

  def hyper_params(_, _, _, _, _) do
    {:ok, []}
  end
end

defmodule GenAI.Support.TestProvider.EncoderTwo do
  @moduledoc """
  TestProvider Encoder Two
  """
  use GenAI.Model.EncoderBehaviour

  require GenAI.Records.Directive

  def headers(model, settings, session, context, options)

  def headers(_, _, _, _, _) do
    {:error, :unsupported}
  end

  def endpoint(model, settings, session, context, options)

  def endpoint(_, _, _, _, _) do
    {:error, :unsupported}
  end

  def request_body(model, messages, tools, settings, session, context, options)

  def request_body(model, messages, tools, settings, _, _, _) do
    with {:ok, model_name} <- GenAI.ModelProtocol.name(model) do
      # TODO Enum map hyper_params
      %{
        model: model_name,
        messages: messages
      }
      |> with_dynamic_setting(:frequency_penalty, model, settings)
      |> with_dynamic_setting(:logprobe, model, settings)
      |> with_dynamic_setting(:top_logprobs, model, settings)
      |> with_dynamic_setting(:logit_bias, model, settings)
      |> with_dynamic_setting(:max_tokens, model, settings)
      |> with_dynamic_setting(:frequency_penalty, model, settings)
      |> with_dynamic_setting_as(:n, :completion_choices, model, settings)
      |> with_dynamic_setting(:presence_penalty, model, settings)
      |> with_dynamic_setting(:response_format, model, settings)
      |> with_dynamic_setting(:seed, model, settings)
      |> with_dynamic_setting(:stop, model, settings)
      |> with_dynamic_setting(:temperature, model, settings)
      |> with_dynamic_setting(:top_p, model, settings)
      |> with_dynamic_setting(:user, model, settings)
      |> then(fn
        body ->
          if tools == [] do
            body
          else
            body
            |> GenAI.InferenceProvider.Helpers.with_setting(:tool_choice, settings)
            |> Map.put(:tools, tools)
          end
      end)
    end
  end

  def encode_tool(tool = %GenAI.Tool{}, _, thread_context, _, _) do
    encoded = %{
      type: :function,
      function: %{
        name: tool.name,
        description: tool.description,
        parameters: tool.parameters
      }
    }

    {:ok, {encoded, thread_context}}
  end

  def encode_message(message, model, thread_context, context, options)

  def encode_message(message = %GenAI.Message{}, _, thread_context, _, _) do
    role_map = %{
      user: :mike,
      assistant: :agent,
      system: :system
    }

    role = role_map[message.role]
    encoded = %{role: role, content: message.content}
    {:ok, {encoded, thread_context}}
  end

  def encode_message(message = %GenAI.Message.ToolResponse{}, _, thread_context, _, _) do
    encoded = %{
      role: :tool,
      tool_call_id: message.tool_call_id,
      content: Jason.encode!(message.tool_response)
    }

    {:ok, {encoded, thread_context}}
  end

  def encode_message(message = %GenAI.Message.ToolUsage{}, _, thread_context, _, _) do
    tool_calls =
      Enum.map(
        message.tool_calls,
        fn tc ->
          update_in(
            tc,
            [Access.key(:function), Access.key(:arguments)],
            &(&1 && Jason.encode!(&1))
          )
        end
      )

    encoded = %{
      role: message.role,
      content: message.content,
      tool_calls: tool_calls
    }

    {:ok, {encoded, thread_context}}
  end

  def normalize_messages(messages, model, thread_context, context, options)

  def normalize_messages(messages, _, thread_context, _, _) do
    {:ok, {messages, thread_context}}
  end

  def with_dynamic_setting(body, setting, model, settings, default \\ nil)

  def with_dynamic_setting(body, setting, model, settings, default) do
    with_dynamic_setting_as(body, setting, setting, model, settings, default)
  end

  def with_dynamic_setting_as(body, as_setting, setting, model, settings, default \\ nil)

  def with_dynamic_setting_as(body, as_setting, setting, _, settings, default) do
    GenAI.InferenceProvider.Helpers.with_setting_as(body, as_setting, setting, settings, default)
  end

  # ----------------------
  #
  # ----------------------
  def hyper_params(model, settings, session, context, options \\ nil)

  def hyper_params(_, _, _, _, _) do
    {:ok, []}
  end
end

defmodule GenAI.Support.TestProvider.EncoderThree do
  @moduledoc """
  TestProvider Encoder Two
  """
  use GenAI.Model.EncoderBehaviour
end

defprotocol GenAI.Support.TestProvider.EncoderProtocol do
  def encode(subject, model, session, context, options)
end

defimpl GenAI.Support.TestProvider.EncoderProtocol, for: GenAI.Tool do
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

defimpl GenAI.Support.TestProvider.EncoderProtocol, for: GenAI.Message do
  def encode(subject, _, session, _, _) do
    encoded = %{role: subject.role, content: subject.content}
    {:ok, {encoded, session}}
  end
end

defimpl GenAI.Support.TestProvider.EncoderProtocol, for: GenAI.Message.ToolResponse do
  def encode(subject, _, session, _, _) do
    encoded = %{
      role: :tool,
      tool_call_id: subject.tool_call_id,
      content: Jason.encode!(subject.tool_response)
    }

    {:ok, {encoded, session}}
  end
end

defimpl GenAI.Support.TestProvider.EncoderProtocol, for: GenAI.Message.ToolUsage do
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

defmodule GenAI.Support.TestProvider.Models do
  @moduledoc """
  TestProvider Models
  """
  def model_one() do
    GenAI.Model.new(
      provider: GenAI.Support.TestProvider,
      encoder: GenAI.Support.TestProvider.EncoderOne,
      model: "one"
    )
  end

  def model_two() do
    GenAI.Model.new(
      provider: GenAI.Support.TestProvider,
      encoder: GenAI.Support.TestProvider.EncoderTwo,
      model: "two"
    )
  end
end
