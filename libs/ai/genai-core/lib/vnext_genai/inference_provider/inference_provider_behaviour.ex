defmodule GenAI.InferenceProviderBehaviour do
  @type session :: any
  @type context :: any
  @type options :: any
  @type completion :: any
  @type model :: any
  @type settings :: map()
  @type headers :: list()
  @type url :: String.t()
  @type uri :: url
  @type method :: :get | :post | :put | :delete | :option | :patch
  @type request_body :: any
  @type messages :: list()
  @type tools :: list() | nil

  # ---------------------
  # Core
  # ---------------------
  @doc "Return config_key inference provide application config stored under :genai entry"
  @callback config_key() :: atom

  # @doc "Base url for provider, may be overriden/ignored by encoder"
  # @callback base_url(model, settings, session, context, options) :: {:ok, url} | {:ok, {url, session}} | {:error, term}

  # ---------------------
  # Run
  # ---------------------
  @doc "Build and run inference thread"
  @callback run(session, context, options) :: {:ok, {completion, session}} | {:error, term}

  @doc "Build and run inference thread in streaming mode"
  @callback stream(session, context, options) :: {:ok, {completion, session}} | {:error, term} | :nyi

  @callback chat(any, any, any, any, any, any, any) :: {:ok, term} | {:error, term}

  # ---------------------
  # Run Support
  # ---------------------
  @doc "Prepare request headers"
  @callback headers(model, settings, session, context, options) ::
              {:ok, headers} | {:ok, {headers, session}} | {:error, term}

  @doc "Prepare endpoint and method to make inference call to"
  @callback endpoint(model, settings, session, context, options) ::
              {:ok, {method, uri}} | {:ok, {{method, uri}, session}} | {:error, term}

  @doc "Prepare request body to be passed to inference call."
  @callback request_body(model, messages, tools, settings, session, context, options) ::
              {:ok, headers} | {:ok, {headers, session}} | {:error, term}

  # ---------------------
  # Settings Config
  # ---------------------
  @doc "Obtain map of effective settings: settings, model_settings, provider_settings, config_settings, etc."
  @callback effective_settings(model, session, context, options) ::
              {:ok, {settings, session}} | {:error, term}

  @callback standardize_model(model) :: model

  # ---------------------
  # Media generation (ADR-016)
  # ---------------------
  @type modality :: :text | :image | :speech | :music | :sfx | :video | :document

  @doc """
  The (input, output, mode) modality triples this provider supports, e.g.
  `[%{input: [:text], output: :image, mode: :sync}]`. genai-core owns the modality
  vocab; each provider declares its own list. Default (text-only chat) is provided.
  """
  @callback supported_modalities() :: [%{input: [modality], output: modality, mode: :sync | :async}]

  @doc """
  Generate non-text media (text/parts -> image/audio/video). Sync providers return the
  bytes; long-running (audio/video) providers return a Job to poll. Default: unsupported.
  """
  @callback generate_media(request :: GenAI.Media.Request.t(), options :: keyword) ::
              {:ok, %{data: binary, mime: String.t(), meta: map}}
              | {:ok, GenAI.Media.Job.t()}
              | {:error, term}

  # ⟦𓇙𓄾𓊵𓂞⟧ __using__ :: auto-generated pointer for public function __using__
  defmacro __using__(options \\ []) do
    quote do
      @provider unquote(options[:provider]) || GenAI.InferenceProvider.DefaultProvider
      @behaviour GenAI.InferenceProviderBehaviour

      import GenAI.InferenceProvider.Helpers
      import GenAI.Helpers

      require GenAI.Helpers

      # ---------------------
      # Core
      # ---------------------

      @config_key unquote(options[:config_key]) ||
                    Module.get_attribute(__MODULE__, :config_key) ||
                    Module.split(__MODULE__)
                    |> List.last()
                    |> Macro.underscore()
                    |> String.to_atom()

      @doc "Return config_key inference provide application config stored under :genai entry"
      # ⟦𓏲𓁑𓉉𓂝⟧ config_key :: Return config_key inference provide application config stored under :genai entry
      def config_key(),
        do: @config_key

      @default_encoder unquote(options[:default_encoder]) ||
                         Module.get_attribute(__MODULE__, :default_encoder) ||
                         Module.concat(__MODULE__, Encoder)

      # ⟦𓃬𓀃𓂯𓏨⟧ default_encoder :: auto-generated pointer for public function default_encoder
      def default_encoder(), do: @default_encoder

      # @doc "Base url for provider, may be overriden/ignored by encoder"
      # def base_url(model, settings, session, context, options \\ nil),
      #    do: unquote(options[:base_url])

      # ---------------------
      # Run
      # ---------------------
      @doc "Build and run inference thread"
      # ⟦𓊘𓈶𓃤𓅅⟧ run :: Build and run inference thread
      def run(session, context, options \\ nil),
          do: @provider.run(__MODULE__, session, context, options)

      @doc "Build and run inference thread in streaming mode"
      # ⟦𓃯𓐒𓏺𓀶⟧ stream :: Build and run inference thread in streaming mode
      def stream(session, context, options \\ nil),
          do: @provider.stream(__MODULE__, session, context, options)

      # ⟦𓂎𓐞𓀛𓀶⟧ chat :: auto-generated pointer for public function chat
      def chat(
            model,
            messages,
            tools,
            hyper_parameters,
            provider_settings \\ [],
            context \\ nil,
            options \\ nil
          ),
          do:
            @provider.chat(
              __MODULE__,
              model,
              messages,
              tools,
              hyper_parameters,
              provider_settings,
              context,
              options
            )

      def chat(messages, tools, settings),
        do: @provider.chat(__MODULE__, messages, tools, settings)

      # ---------------------
      # Run Support
      # ---------------------
      @doc "Prepare endpoint and method to make inference call to"
      # ⟦𓁁𓉎𓀩𓏬⟧ endpoint :: Prepare endpoint and method to make inference call to
      def endpoint(model, settings, session, context, options \\ nil),
        do: @provider.endpoint(__MODULE__, model, settings, session, context, options)

      # ⟦𓅸𓐡𓀳𓌂⟧ headers :: auto-generated pointer for public function headers
      def headers(options),
        do: @provider.headers(__MODULE__, options)

      @doc "Prepare request headers"
      def headers(model, settings, session, context, options \\ nil),
        do: @provider.headers(__MODULE__, model, settings, session, context, options)

      @doc "Prepare request body to be passed to inference call."
      # ⟦𓃇𓇰𓅩𓃲⟧ request_body :: Prepare request body to be passed to inference call.
      def request_body(model, messages, tools, settings, session, context, options \\ nil),
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

      # ---------------------
      # Settings Config
      # ---------------------
      @doc "Obtain map of effective settings: settings, model_settings, provider_settings, config_settings, etc."
      # ⟦𓀥𓆋𓐌𓃑⟧ effective_settings :: Obtain map of effective settings: settings, model_settings, provider_settings, config_settings, etc.
      def effective_settings(model, session, context, options \\ nil),
        do: @provider.effective_settings(__MODULE__, model, session, context, options)

      # ⟦𓀏𓀑𓏞𓐤⟧ standardize_model :: auto-generated pointer for public function standardize_model
      def standardize_model(model),
        do: @provider.standardize_model(__MODULE__, @default_encoder, model)

      # ---------------------
      # Media generation (ADR-016) — defaults so existing text providers compile unchanged.
      # ---------------------
      # ⟦𓇟𓃢𓃞𓌷⟧ supported_modalities :: auto-generated pointer for public function supported_modalities
      def supported_modalities(), do: [%{input: [:text], output: :text, mode: :sync}]

      # ⟦𓍸𓁅𓇄𓎁⟧ generate_media :: auto-generated pointer for public function generate_media
      def generate_media(_request, _options), do: {:error, :unsupported_modality}

      defoverridable config_key: 0,
                     default_encoder: 0,
                     headers: 1,
                     standardize_model: 1,
                     supported_modalities: 0,
                     generate_media: 2

      # base_url: 4,
      # base_url: 5,
    end
  end
end
