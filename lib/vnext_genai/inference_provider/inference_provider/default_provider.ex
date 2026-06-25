defmodule GenAI.InferenceProvider.DefaultProvider do
  @moduledoc """
  Inference Provider Default Provider.
  """

  alias GenAI.ThreadProtocol
  import GenAI.InferenceProvider.Helpers

  # *************************
  # run/4
  # *************************
  @doc """
  Run inference and return completion response and updated session
  """
  def run(module, session, context, options \\ nil) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_run, 3) do
      module.do_run(session, context, options)
    else
      do_run(module, session, context, options)
    end
  end

  # *************************
  # stream/4
  # *************************
  @doc """
  Run inference in streaming mode and return completion response and updated session
  """
  def stream(module, session, context, options \\ nil) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_stream, 3) do
      module.do_stream(session, context, options)
    else
      do_stream(module, session, context, options)
    end
  end

  def do_run(module, session, context, options \\ nil) do
    do_run_or_stream(:run, module, session, context, options)
  end
  
  def do_stream(module, session, context, options \\ nil) do
    do_run_or_stream(:stream, module, session, context, options)
  end
  
  def do_run_or_stream(mode, module, session, context, options \\ nil) do
    with {:ok, {model, session}} <- ThreadProtocol.effective_model(session, context, options),
         {:ok, model_encoder} <- GenAI.ModelProtocol.encoder(model),
         {:ok, {effective, session}} <-
           module.effective_settings(model, session, context, options),
         {:ok, {tools, session}} <-
           ThreadProtocol.effective_tools(session, model, context, options),
         {:ok, {messages, session}} <-
           ThreadProtocol.effective_messages(session, model, context, options) do
      # Build Request
      with {:ok, {req_body, session}} <-
             module.request_body(model, messages, tools, effective, session, context, options),
           {:ok, {req_headers, session}} <-
             module.headers(model, effective, session, context, options),
           {:ok, {{req_method, req_endpoint}, session}} <-
             module.endpoint(model, effective, session, context, options) do
        
        if mode == :run do
          with {:ok, %Finch.Response{status: 200, body: response_body}} <-
                 api_call(req_method, req_endpoint, req_headers, req_body, options[:finch]),
               {:ok, json} <- Jason.decode(response_body, keys: :atoms),
               {:ok, response} <-
                 model_encoder.completion_response(
                   json,
                   model,
                   effective,
                   session,
                   context,
                   options
                 ),
               response <-
                 put_in(response, [Access.key(:seed)], req_body[:seed] || req_body[:random_seed]) do
            {:ok, {response, session}}
          end
        else
          # Streaming Mode
          with {:ok, {settings, session}} <- GenAI.ThreadProtocol.effective_settings(session, context, options),
               stream_handler <- settings[:stream_handler] || GenAI.StreamHandler.Default,
               {:ok, {handler, session}} <- GenAI.StreamHandler.begin_stream(stream_handler, session, context, options),
               {:ok, req} <- stream_api_call(handler, req_method, req_endpoint, req_headers, req_body, options[:finch]) do
            {:ok, {req, session}}
          end
        end
        

        
      end
    end
  end
  
  # ------------------
  # chat/7
  # ------------------
  @doc """
  Low level inference, pass in model, messages, tools, and various settings to prepare final provider specific API requires.
  """

  def chat(
        module,
        model,
        messages,
        tools,
        hyper_parameters,
        provider_settings \\ [],
        context \\ nil,
        options \\ nil
      )

  def chat(module, model, messages, tools, hyper_parameters, provider_settings, context, options) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_chat, 7) do
      module.do_chat(
        model,
        messages,
        tools,
        hyper_parameters,
        provider_settings,
        context,
        options
      )
    else
      do_chat(
        module,
        model,
        messages,
        tools,
        hyper_parameters,
        provider_settings,
        context,
        options
      )
    end
  end

  def do_chat(
        module,
        model,
        messages,
        tools,
        hyper_parameters,
        provider_settings \\ [],
        context \\ nil,
        options \\ nil
      ) do
    # Setup Context
    context = context || Noizu.Context.system()

    # Options
    session_type = options[:session_type] || :standard
    full_response = options[:legacy_mode] === false

    # Standardize Model
    model = module.standardize_model(model)

    # Check Provider
    {:ok, provider} = GenAI.ModelProtocol.provider(model)

    if provider != module,
      do: raise(ArgumentError, "Model Provider #{inspect(provider)} != #{module}")

    # Setup Thread
    thread =
      GenAI.chat(session_type)
      |> GenAI.with_model(model)
      |> GenAI.with_provider_settings(provider, provider_settings)
      |> GenAI.with_settings(hyper_parameters)
      |> GenAI.with_tools(tools)
      |> GenAI.with_messages(messages)

    # Execute and return response
    case GenAI.ThreadProtocol.execute(thread, :run, context, options) do
      {:ok, {response, thread}} ->
        (full_response && {:ok, {response, thread}}) || {:ok, response}

      error = {:error, _} ->
        error

      other ->
        {:error, {:other, other}}
    end
  end

  @doc """
  Sends a chat completion request to the Mistral API.
  This function constructs the request body based on the provided messages, tools, and settings, sends the request to the Mistral API, and returns a `GenAI.ChatCompletion` struct with the response.
  """
  # @deprecated "This function is deprecated. Use `GenAI.Thread.chat/5` instead."
  def chat(module, messages, tools, settings)

  def chat(module, messages, tools, settings) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_chat, 3) do
      module.do_chat(messages, tools, settings)
    else
      do_chat(module, messages, tools, settings)
    end
  end

  def do_chat(module, messages, tools, settings)

  def do_chat(module, messages, tools, settings) do
    settings = settings |> Enum.reverse()

    provider_settings =
      Enum.filter(settings, fn {k, _} -> k in [:api_key, :api_org, :api_project] end)

    module.chat(settings[:model], messages, tools, settings, provider_settings)
  end

  # *************************
  # Run Support
  # *************************

  # ----------------------
  # endpoint/6
  # ----------------------
  @doc "Prepare endpoint and method to make inference call to"
  def endpoint(module, model, settings, session, context, options \\ nil)

  def endpoint(module, model, settings, session, context, options) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_endpoint, 5) do
      module.do_endpoint(model, settings, session, context, options)
    else
      do_endpoint(module, model, settings, session, context, options)
    end
  end

  def do_endpoint(_, model, settings, session, context, options) do
    with {:ok, model_encoder} <- GenAI.ModelProtocol.encoder(model) do
      model_encoder.endpoint(model, settings, session, context, options)
    end
  end

  # ----------------------
  # headers/2
  # ----------------------
  def headers(module, options) do
    config_settings = Application.get_env(:genai, module.config_key(), [])
    context = Noizu.Context.system()

    {:ok, {headers, _}} =
      module.default_encoder().headers(
        nil,
        %{settings: options, config_settings: config_settings},
        nil,
        context,
        []
      )

    headers
  end

  # ----------------------
  # headers/6
  # ----------------------
  @doc "Prepare request headers"
  def headers(module, model, settings, session, context, options \\ nil)

  def headers(module, model, settings, session, context, options) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_headers, 5) do
      module.do_headers(model, settings, session, context, options)
    else
      do_headers(module, model, settings, session, context, options)
    end
  end

  def do_headers(module, model, settings, session, context, options)

  def do_headers(_, model, settings, session, context, options) do
    with {:ok, model_encoder} <- GenAI.ModelProtocol.encoder(model) do
      model_encoder.headers(model, settings, session, context, options)
    end
  end

  # ----------------------
  # request_body/8
  # ----------------------
  @doc "Prepare request body to be passed to inference call."
  def request_body(module, model, messages, tools, settings, session, context, options \\ nil)

  def request_body(module, model, messages, tools, settings, session, context, options) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_request_body, 7) do
      module.do_request_body(model, messages, tools, settings, session, context, options)
    else
      do_request_body(module, model, messages, tools, settings, session, context, options)
    end
  end

  def do_request_body(module, model, messages, tools, settings, session, context, options)

  def do_request_body(_, model, messages, tools, settings, session, context, options) do
    with {:ok, model_encoder} <- GenAI.ModelProtocol.encoder(model) do
      model_encoder.request_body(model, messages, tools, settings, session, context, options)
    end
  end

  # **************************
  # Settings Config
  # *************************

  # ----------------------
  # effective_settings/5
  # ----------------------
  @doc "Obtain map of effective settings: settings, model_settings, provider_settings, config_settings, etc."
  def effective_settings(module, model, session, context, options \\ nil)

  def effective_settings(module, model, session, context, options) do
    if Code.ensure_loaded?(module) and function_exported?(module, :do_effective_settings, 4) do
      module.do_effective_settings(model, session, context, options)
    else
      do_effective_settings(module, model, session, context, options)
    end
  end

  def do_effective_settings(module, model, session, context, options)

  def do_effective_settings(module, model, session, context, options) do
    with {:ok, {settings, session}} <-
           GenAI.ThreadProtocol.effective_settings(session, context, options),
         {:ok, {safety_settings, session}} <-
           GenAI.ThreadProtocol.effective_safety_settings(session, context, options),
         {:ok, {model_settings, session}} <-
           GenAI.ThreadProtocol.effective_model_settings(session, model, context, options),
         {:ok, {provider_settings, session}} <-
           GenAI.ThreadProtocol.effective_provider_settings(session, model, context, options) do
      x = %{
        config_settings: Application.get_env(:genai, module.config_key(), []),
        settings: settings,
        model_settings: model_settings,
        provider_settings: provider_settings,
        safety_settings: safety_settings
      }

      {:ok, {x, session}}
    end
  end

  def standardize_model(module, encoder, model)

  def standardize_model(module, encoder, model) when is_atom(model),
    do: %GenAI.Model{
      model: model,
      provider: module,
      encoder: encoder
    }

  def standardize_model(module, encoder, model) when is_bitstring(model),
    do: %GenAI.Model{
      model: model,
      provider: module,
      encoder: encoder
    }

  def standardize_model(model) do
    if GenAI.Graph.Node.is_node?(model, GenAI.Model) do
      model
    else
      raise GenAI.RequestError, "Unsupported Model"
    end
  end
end
