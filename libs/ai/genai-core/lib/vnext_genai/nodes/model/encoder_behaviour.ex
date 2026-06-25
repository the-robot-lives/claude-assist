defmodule GenAI.Model.EncoderBehaviour do
  @type session :: any
  @type context :: any
  @type options :: any
  @type completion :: any
  @type model :: any
  @type settings :: map()
  @type headers :: list()
  @type url :: String.t()
  @type uri :: url
  @type message :: any
  @type messages :: list()
  @type json :: any
  @type method :: :get | :post | :put | :delete | :option | :patch
  @type request_body :: any
  @type tool :: any()
  @type tools :: list() | nil

  # **********************************
  # Prepare Requests
  # **********************************

  # ---------------------------------
  # headers
  # ---------------------------------
  @doc """
  Prepare request headers
  """
  @callback headers(model, settings, session, context, options) ::
              {:ok, headers} | {:ok, {headers, session}} | {:error, term}

  # ---------------------------------
  #
  # ---------------------------------
  @doc """
  Prepare endpoint and method to make inference call to
  """
  @callback endpoint(model, settings, session, context, options) ::
              {:ok, {method, uri}} | {:ok, {{method, uri}, session}} | {:error, term}

  # ---------------------------------
  # endpoint
  # ---------------------------------
  @doc """
  Prepare request body to be passed to inference call.
  """
  @callback request_body(model, messages, tools, settings, session, context, options) ::
              {:ok, headers} | {:ok, {headers, session}} | {:error, term}

  @callback completion_response(json, model, settings, session, context, options) ::
              {:ok, completion} | {:error, term}

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
  @callback encode_tool(tool, model, session, context, options) ::
              {:ok, {tool, session}} | {:error, term}

  # ---------------------------------
  # encode_message
  # ---------------------------------
  @doc """
  Format message for provider/model type.
  """
  @callback encode_message(message, model, session, context, options) ::
              {:ok, {message, session}} | {:error, term}

  # ---------------------------------
  # normalize_messages
  # ---------------------------------
  @callback normalize_messages(messages, model, session, context, options) ::
              {:ok, {any, any}} | {:error, any}

  # **********************************
  # Settings
  # **********************************

  # ---------------------------------
  # with_dynamic_setting
  # ---------------------------------
  @doc """
  Set setting with dynamic model based logic.
  """
  @callback with_dynamic_setting(body :: term, setting :: term, model :: term, settings :: term) ::
              term
  @callback with_dynamic_setting(
              body :: term,
              setting :: term,
              model :: term,
              settings :: term,
              default :: term
            ) :: term

  # ---------------------------------
  # with_dynamic_setting_as
  # ---------------------------------
  @doc """
  Set setting as_setting with dynamic model based logic.
  """
  @callback with_dynamic_setting_as(
              body :: term,
              as_setting :: term,
              setting :: term,
              model :: term,
              settings :: term
            ) :: term
  @callback with_dynamic_setting_as(
              body :: term,
              as_setting :: term,
              setting :: term,
              model :: term,
              settings :: term,
              default :: term
            ) :: term

  # ---------------------------------
  # hyper_params
  # ---------------------------------
  @doc """
  Obtain list of hyper params supported by given model including mapping and conditional rules/alterations
  """
  @callback hyper_params(model, settings, session, context, options) ::
              {:ok, {settings, session}} | {:error, term}

  @callback default_hyper_params(model, settings, session, context, options) ::
              {:ok, {settings, session}} | {:error, term}

  # =============================================================================
  # =============================================================================
  # USING MACRO
  # =============================================================================
  # =============================================================================
  defmacro __using__(options \\ []) do
    quote do
      @provider unquote(options[:provider]) || GenAI.Model.Encoder.DefaultProvider
      @behaviour GenAI.Model.EncoderBehaviour

      import GenAI.InferenceProvider.Helpers
      import GenAI.Helpers

      import GenAI.Records.Directive,
        only: [hyper_param: 1]

      require GenAI.Records.Directive
      require GenAI.Helpers

      @base_url unquote(options[:base_url]) ||
                  Module.get_attribute(__MODULE__, :base_url, "https://api.sandbox.local")

      @default_encoder_protocol ((Module.split(__MODULE__) |> Enum.slice(0..-2//1)) ++
                                   [EncoderProtocol])
                                |> Module.concat()
      @encoder_protocol unquote(options[:encoder_protocol]) || @default_encoder_protocol

      # ---------------------------------
      # encoder_protocol
      # ---------------------------------
      @doc "Prepare endpoint and method to make inference call to"
      def encoder_protocol(model, session, context, options)

      def encoder_protocol(_, _, _, _),
        do: {:ok, @encoder_protocol}

      # ---------------------------------
      # endpoint/5
      # ---------------------------------
      @doc "Prepare endpoint and method to make inference call to"
      def endpoint(model, settings, session, context, options)

      def endpoint(_, _, session, _, _),
        do: {:ok, {{:post, "#{@base_url}/v1/chat/completions"}, session}}

      # ---------------------------------
      # headers/5
      # ---------------------------------
      @doc "Prepare request headers"
      def headers(model, settings, session, context, options),
        do: @provider.headers(__MODULE__, model, settings, session, context, options)

      # ---------------------------------
      # request_body/7
      # ---------------------------------
      @doc "Prepare request body to be passed to inference call."
      def request_body(model, messages, tools, settings, session, context, options),
        do:
          @provider.request_body(
            __MODULE__,
            model,
            messages,
            tools,
            settings,
            session,
            context,
            options
          )

      def completion_response(json, model, settings, session, context, options),
        do:
          @provider.completion_response(
            __MODULE__,
            json,
            model,
            settings,
            session,
            context,
            options
          )

      def completion_choices(id, json, model, settings, session, context, options),
        do:
          @provider.completion_choices(
            __MODULE__,
            id,
            json,
            model,
            settings,
            session,
            context,
            options
          )

      def completion_choice(id, json, model, settings, session, context, options),
        do:
          @provider.completion_choice(
            __MODULE__,
            id,
            json,
            model,
            settings,
            session,
            context,
            options
          )

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
      def encode_tool(tool, model, session, context, options),
        do: @provider.encode_tool(__MODULE__, tool, model, session, context, options)

      # ---------------------------------
      # encode_message
      # ---------------------------------
      @doc """
      Format message for provider/model type.
      """
      def encode_message(message, model, session, context, options),
        do: @provider.encode_message(__MODULE__, message, model, session, context, options)

      # ---------------------------------
      # normalize_messages
      # ---------------------------------
      def normalize_messages(messages, model, session, context, options),
        do: @provider.normalize_messages(__MODULE__, messages, model, session, context, options)

      # **********************************
      # Settings
      # **********************************

      # ---------------------------------
      # with_dynamic_setting
      # ---------------------------------
      @doc """
      Set setting with dynamic model based logic.
      """
      def with_dynamic_setting(body, setting, model, settings),
        do: @provider.with_dynamic_setting(__MODULE__, body, setting, model, settings)

      def with_dynamic_setting(body, setting, model, settings, default),
        do: @provider.with_dynamic_setting(__MODULE__, body, setting, model, settings, default)

      # ---------------------------------
      # with_dynamic_setting_as
      # ---------------------------------
      @doc """
      Set setting as_setting with dynamic model based logic.
      """
      def with_dynamic_setting_as(body, as_setting, setting, model, settings),
        do:
          @provider.with_dynamic_setting_as(
            __MODULE__,
            body,
            as_setting,
            setting,
            model,
            settings
          )

      def with_dynamic_setting_as(body, as_setting, setting, model, settings, default),
        do:
          @provider.with_dynamic_setting_as(
            __MODULE__,
            body,
            as_setting,
            setting,
            model,
            settings,
            default
          )

      # ---------------------
      # Settings Config
      # ---------------------
      @doc "Obtain list of hyper params supported by given model including mapping and conditional rules/alterations"
      def hyper_params(model, settings, session, context, options),
        do: @provider.hyper_params(__MODULE__, model, settings, session, context, options)

      def default_hyper_params(model, settings, session, context, options),
        do: @provider.default_hyper_params(__MODULE__, model, settings, session, context, options)

      defoverridable encoder_protocol: 4,
                     endpoint: 5,
                     headers: 5,
                     request_body: 7,
                     completion_response: 6,
                     completion_choices: 7,
                     completion_choice: 7,
                     encode_message: 5,
                     encode_tool: 5,
                     normalize_messages: 5,
                     with_dynamic_setting: 4,
                     with_dynamic_setting: 5,
                     with_dynamic_setting_as: 5,
                     with_dynamic_setting_as: 6,
                     hyper_params: 5,
                     default_hyper_params: 5
    end
  end
end
