defmodule GenAI.Model.Encoder.DefaultProvider do
  import GenAI.Records.Directive,
    only: [hyper_param: 1]

  require GenAI.Records.Directive

  # **********************************
  # Prepare Requests
  # **********************************

  # ---------------------------------
  # headers/5
  # ---------------------------------
  @doc "Prepare request headers"
  def headers(module, model, settings, session, context, options)

  def headers(module, _, settings, session, _, options) do
    auth =
      cond do
        key = options[:api_key] -> {"Authorization", "Bearer #{key}"}
        key = settings[:model_settings][:api_key] -> {"Authorization", "Bearer #{key}"}
        key = settings[:provider_settings][:api_key] -> {"Authorization", "Bearer #{key}"}
        key = settings[:config_settings][:api_key] -> {"Authorization", "Bearer #{key}"}
        :else -> raise GenAI.RequestError, message: "API KEY NOT FOUND - #{module}"
      end

    {:ok, {[auth, {"content-type", "application/json"}], session}}
  end

  # ---------------------------------
  # request_body/7
  # ---------------------------------
  @doc "Prepare request body to be passed to inference call."
  def request_body(module, model, messages, tools, settings, session, context, options)

  def request_body(module, model, messages, tools, settings, session, context, options) do
    with {:ok, model_name} <- GenAI.ModelProtocol.name(model),
         {:ok, params} <- module.hyper_params(model, settings, session, context, options) do
      body =
        %{
          model: model_name,
          messages: messages
        }
        |> then(&if tools == [], do: Map.put(&1, :tools, tools), else: &1)

      body = apply_hyper_params_and_adjust(module, body, params, model, settings)
      {:ok, {body, session}}
    end
  end

  def apply_hyper_params_and_adjust(module, body, params, model, settings) do
    body_s1 =
      Enum.reduce(params, body, fn
        hyper_param(name: name, as: nil), body ->
          module.with_dynamic_setting(body, name, model, settings.settings)

        hyper_param(name: name, as: as), body ->
          module.with_dynamic_setting_as(body, as, name, model, settings.settings)
      end)

    body_s2 =
      Enum.reduce(params, body_s1, fn
        hyper_param(sentinel: nil), body ->
          body

        x = hyper_param(name: name, as: as, sentinel: {m, f, a}), body ->
          if Map.has_key?(body, as || name) do
            if apply(m, f, [x, body_s1, model, settings | a]) do
              body
            else
              Map.delete(body, as || name)
            end
          else
            body
          end

        x = hyper_param(name: name, as: as, sentinel: sentinel), body
        when is_function(sentinel, 4) ->
          if Map.has_key?(body, as || name) do
            if sentinel.(x, body_s1, model, settings) do
              body
            else
              Map.delete(body, as || name)
            end
          else
            body
          end
      end)

    body_s3 =
      Enum.reduce(params, body_s2, fn
        hyper_param(adjuster: nil), body ->
          body

        x = hyper_param(name: name, as: as, adjuster: {m, f, a}), body ->
          with true <- Map.has_key?(body, as || name),
               {:ok, update} <- apply(m, f, [x, body_s1, model, settings | a]) do
            Map.put(body, as || name, update)
          else
            _ -> body
          end

        x = hyper_param(name: name, as: as, adjuster: adjuster), body
        when is_function(adjuster, 4) ->
          with true <- Map.has_key?(body, as || name),
               {:ok, update} <- adjuster.(x, body_s1, model, settings) do
            Map.put(body, as || name, update)
          else
            _ -> body
          end
      end)

    body_s3
  end

  def completion_response(module, json, model, settings, session, context, options)

  def completion_response(module, json, model, settings, session, context, options) do
    with {:ok, provider} <- GenAI.ModelProtocol.provider(model),
         %{
           id: id,
           usage: %{},
           model: model,
           choices: choices
         } <- json do
      choices =
        choices
        |> Enum.map(
          &if {:ok, v} =
                module.completion_choices(id, &1, model, settings, session, context, options),
              do: v
        )

      usage = GenAI.ChatCompletion.Usage.new(json.usage)

      completion =
        %{json | usage: usage, choices: choices}
        |> put_in([Access.key(:provider)], provider)
        |> GenAI.ChatCompletion.from_json()

      {:ok, completion}
    end
  end

  def completion_choices(module, id, json, model, settings, session, context, options)
  
  def completion_choices(
        module,
        id,
        json = %{
          index: _,
          message: message,
          finish_reason: _
        },
        model,
        settings,
        session,
        context,
        options
      ) do
    with {:ok, message_struct} <-
           module.completion_choice(id, message, model, settings, session, context, options) do
      choice =
        json
        |> put_in([Access.key(:message)], message_struct)
        |> GenAI.ChatCompletion.Choice.new()

      {:ok, choice}
    end
  end

  def completion_choice(module, id, json, model, settings, session, context, options)
  
  
  def completion_choice(
        _,
        _,
        content,
        _,
        _,
        _,
        _,
        _
      ) when is_bitstring(content) do
    msg = GenAI.Message.assistant(content)
    {:ok, msg}
  end
  
  def completion_choice(
        _,
        _,
        %{role: "assistant", content: content, tool_calls: nil},
        _,
        _,
        _,
        _,
        _
      ) do
    msg = GenAI.Message.assistant(content)
    {:ok, msg}
  end

  def completion_choice(
        _,
        _,
        %{role: "assistant", content: content, tool_calls: tool_calls},
        _,
        _,
        _,
        _,
        _
      ) do
    tool_calls =
      tool_calls
      |> Enum.map(fn
        %{function: _} = call ->
          call
          |> update_in(
            [Access.key(:function), Access.key(:arguments)],
            &Jason.decode!(&1, keys: :atoms)
          )
          |> update_in([Access.key(:id)], &(&1 || gen_unique_call_id()))
          |> update_in([Access.key(:type)], &(&1 || "function"))
      end)

    msg = GenAI.Message.ToolUsage.new(role: :assistant, content: content, tool_calls: tool_calls)
    {:ok, msg}
  end

  def completion_choice(
        _,
        _,
        %{role: "assistant", content: content},
        _,
        _,
        _,
        _,
        _
      ) do
    msg = GenAI.Message.assistant(content)
    {:ok, msg}
  end

  # **********************************
  # Message and Tool Formatting
  # and Normalization
  # **********************************

  # ---------------------------------
  # encode_tool
  # ---------------------------------
  @doc """
  Format tool for provider/model type.
  """
  def encode_tool(module, tool, model, session, context, options)

  def encode_tool(module, tool, model, session, context, options) do
    with {:ok, protocol} <- module.encoder_protocol(model, session, context, options) do
      protocol.encode(tool, model, session, context, options)
    end
  end

  # ---------------------------------
  # encode_message
  # ---------------------------------
  @doc """
  Format message for provider/model type.
  """
  def encode_message(module, message, model, session, context, options)

  def encode_message(module, message, model, session, context, options) do
    with {:ok, protocol} <- module.encoder_protocol(model, session, context, options) do
      protocol.encode(message, model, session, context, options)
    end
  end

  # ---------------------------------
  # normalize_messages
  # ---------------------------------
  def normalize_messages(module, messages, model, session, context, options)

  def normalize_messages(_, messages, _, session, _, _) do
    {:ok, {messages, session}}
  end

  # **********************************
  # Settings
  # **********************************

  # ---------------------------------
  # with_dynamic_setting
  # ---------------------------------
  @doc """
  Set setting with dynamic model based logic.
  """
  def with_dynamic_setting(module, body, setting, model, settings, default \\ nil)

  def with_dynamic_setting(_, body, setting, _, settings, default) do
    GenAI.InferenceProvider.Helpers.with_setting(body, setting, settings, default)
  end

  # ---------------------------------
  # with_dynamic_setting_as
  # ---------------------------------
  @doc """
  Set setting as_setting with dynamic model based logic.
  """
  def with_dynamic_setting_as(module, body, as_setting, setting, model, settings, default \\ nil)

  def with_dynamic_setting_as(_, body, as_setting, setting, _, settings, default) do
    GenAI.InferenceProvider.Helpers.with_setting_as(body, as_setting, setting, settings, default)
  end

  # ---------------------
  # Settings Config
  # ---------------------
  @doc "Obtain list of hyper params supported by given model including mapping and conditional rules/alterations"
  def hyper_params(module, model, settings, session, context, options)

  def hyper_params(module, model, settings, session, context, options) do
    cond do
      (
        x = options[:hyper_params]
        is_list(x) and x != []
      ) ->
        {:ok, x}

      (
        x = settings.config_settings[:hyper_params]
        is_list(x) and x != []
      ) ->
        {:ok, x}

      :else ->
        module.default_hyper_params(model, settings, session, context, options)
    end
  end

  @doc "Obtain list of hyper params supported by given model including mapping and conditional rules/alterations"
  def default_hyper_params(module, model, settings, session, context, options)

  def default_hyper_params(_, _, _, _, _, _) do
    x = [
      hyper_param(name: :frequency_penalty),
      hyper_param(name: :logprobe),
      hyper_param(name: :top_logprobs),
      hyper_param(name: :logit_bias),

      # In the future dynamic_settings or the hyper_param sentinel
      # and adjuster methods may be used to convert max_tokens
      # to max_completions_tokens on thinking models while stripping max_tokens.
      # using max_completion_tokens if set.
      hyper_param(name: :max_tokens),
      hyper_param(name: :max_completion_tokens),
      hyper_param(name: :frequency_penalty),
      hyper_param(name: :completion_choices, as: :n),
      hyper_param(name: :presence_penalty),
      hyper_param(name: :response_format),
      hyper_param(name: :seed),
      hyper_param(name: :stop, type: :list),
      hyper_param(name: :temperature),
      hyper_param(name: :top_p),
      hyper_param(name: :user, type: :string),
      hyper_param(name: :stream, type: :boolean),
      hyper_param(name: :stream_options),
      hyper_param(
        name: :tool_choice,
        type: :string,
        sentinel: fn _, body, _, _ -> body[:tools] && true end
      )
    ]

    {:ok, x}
  end

  defp gen_unique_call_id do
    {:ok, short_uuid} = ShortUUID.encode(UUID.uuid4())
    "call_#{short_uuid}"
  end
end
