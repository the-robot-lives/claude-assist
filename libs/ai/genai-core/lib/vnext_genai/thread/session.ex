defmodule GenAI.Thread.Session do
  @moduledoc """
  More advanced VNext Thread Implementation
  """
  @vsn 1.0
  require GenAI.Records.Link
  require GenAI.Records.Node
  #  require GenAI.Records.Session
  #  alias GenAI.Records.Session, as: Node
  alias GenAI.Session.Runtime
  # alias GenAI.Session.State

  defstruct state: nil,
            root: nil,
            runtime: nil,
            vsn: @vsn

  def new(options \\ nil)

  def new(options) do
    %__MODULE__{
      state: GenAI.Session.State.new(options[:state]),
      root: %GenAI.Graph.Root{graph: GenAI.VNext.Graph.new(options[:graph])},
      runtime: GenAI.Session.Runtime.new(options[:runtime]),
      vsn: @vsn
    }
  end

  # ------------------------
  # append_directive/4
  # ------------------------
  def append_directive(session, directive, context, options \\ nil)

  def append_directive(session, directive, _, _) do
    update = update_in(session, [Access.key(:state), Access.key(:directives)], &[directive | &1])
    {:ok, update}
  end

  # ------------------------
  # pending_directives?/1
  # ------------------------
  def pending_directives?(session)

  def pending_directives?(session),
    do: session.state.directive_position < length(session.state.directives)

  # ------------------------
  # apply_directives/3
  # ------------------------
  def apply_directives(session, context, options)

  def apply_directives(session, context, options) do
    offset = -(session.state.directive_position + 1)

    session =
      session.state.directives
      |> Enum.slice(0..offset//1)
      |> Enum.reverse()
      |> Enum.reduce(
        session,
        fn
          directive, session ->
            {:ok, session} =
              GenAI.Session.State.Directive.apply_directive(directive, session, context, options)

            session
        end
      )
      |> put_in(
        [Access.key(:state), Access.key(:directive_position)],
        length(session.state.directives)
      )

    {:ok, session}
  end

  # -------------------------------------------
  # GenAI.ThreadProtocol
  # ---------------------------------------------
  defimpl GenAI.ThreadProtocol do
    require Logger

    import GenAI.Helpers, only: [apply_label: 2]

    defp append_node(thread_context, node, options \\ nil)

    defp append_node(thread_context, node, options) do
      update_in(
        thread_context,
        [Access.key(:root), Access.key(:graph)],
        &GenAI.VNext.Graph.attach_node(&1, node, options)
      )
    end

    # ------------------------
    # append_directive/4
    # ------------------------
    def append_directive(session, directive, context, options \\ nil)

    def append_directive(session, directive, _, _) do
      update =
        update_in(session, [Access.key(:state), Access.key(:directives)], &[directive | &1])

      {:ok, update}
    end

    # -------------------------------------
    # with_model/2
    # -------------------------------------
    @doc """
    Specify a specific model or model picker.

      This function allows you to define the model to be used for inference.
    You can either provide a specific model, like `Model.smartest()`, or a model picker function that dynamically selects
    the best model based on the context and available providers.

      Examples:
    * `Model.smartest()` - This will select the "smartest" available model at inference time, based on factors
      like performance and capabilities.
    * `Model.cheapest(params: :best_effort)` - This will select the cheapest available model that can handle the
      given parameters and context size.
    * `CustomProvider.custom_model` - This allows you to use a custom model from a user-defined provider.
    """
    def with_model(thread_context, model) do
      if GenAI.Graph.Node.is_node?(model, GenAI.Model) do
        {:ok, n} = GenAI.Graph.NodeProtocol.with_id(model)
        append_node(thread_context, n)
      else
        raise ArgumentError,
          message: "Model must be a GenAI.Model node, got #{inspect(model)}"
      end
    end

    # -------------------------------------
    #
    # -------------------------------------

    def with_tool(thread_context, tool) do
      if GenAI.Graph.Node.is_node?(tool, GenAI.Tool) do
        {:ok, n} = GenAI.Graph.NodeProtocol.with_id(tool)
        append_node(thread_context, n)
      else
        raise ArgumentError,
          message: "Tool must be a GenAI.Tool node, got #{inspect(tool)}"
      end
    end

    # -------------------------------------
    #
    # -------------------------------------
    def with_tools(context, tools) do
      Enum.reduce(tools || [], context, fn tool, context ->
        with_tool(context, tool)
      end)
    end

    # -------------------------------------
    #
    # -------------------------------------

    @doc """
    Specify an API key for a provider.
    """
    def with_api_key(thread_context, provider, api_key) do
      n =
        GenAI.Setting.ProviderSetting.new(
          provider: provider,
          setting: :api_key,
          value: api_key
        )

      append_node(thread_context, n)
    end

    # -------------------------------------
    #
    # -------------------------------------

    @doc """
    Specify an API org for a provider.
    """
    def with_api_org(thread_context, provider, api_org) do
      n =
        GenAI.Setting.ProviderSetting.new(
          provider: provider,
          setting: :api_org,
          value: api_org
        )

      append_node(thread_context, n)
    end

    # -------------------------------------
    #
    # -------------------------------------

    @doc """
    Set a hyperparameter option.

      Some options are model-specific. The value can be a literal or a picker function that dynamically determines
    the best value based on the context and model.

      Examples:
    * `Parameter.required(name, value)` - This sets a required parameter with the specified name and value.
    * `Gemini.best_temperature_for(:chain_of_thought)` - This uses a picker function to determine the best temperature
       for the Gemini provider when using the "chain of thought" prompting technique.
    """
    def with_setting(thread_context, setting, value) do
      n =
        GenAI.Setting.new(
          setting: setting,
          value: value
        )

      append_node(thread_context, n)
    end

    # -------------------------------------
    #
    # -------------------------------------
    def with_setting(thread_context, setting) do
      if GenAI.Graph.Node.is_node?(setting, GenAI.Setting) do
        {:ok, n} = GenAI.Graph.NodeProtocol.with_id(setting)
        append_node(thread_context, n)
      else
        raise ArgumentError,
          message: "Setting must be a GenAI.Setting node, got #{inspect(setting)}"
      end
    end

    # -------------------------------------
    #
    # -------------------------------------
    def with_settings(thread_context, settings) do
      Enum.reduce(settings || [], thread_context, fn
        {setting, value}, thread_context -> with_setting(thread_context, setting, value)
        value, thread_context when is_struct(value) -> with_setting(thread_context, value)
      end)
    end

    # -------------------------------------
    #
    # -------------------------------------
    def with_safety_setting(thread_context, category, threshold) do
      n =
        GenAI.Setting.SafetySetting.new(
          category: category,
          threshold: threshold
        )

      append_node(thread_context, n)
    end

    # -------------------------------------
    #
    # -------------------------------------
    def with_safety_setting(thread_context, safety_setting) do
      if GenAI.Graph.Node.is_node?(safety_setting, GenAI.Setting) do
        {:ok, n} = GenAI.Graph.NodeProtocol.with_id(safety_setting)
        append_node(thread_context, n)
      else
        raise ArgumentError,
          message: "SafetySetting must be a GenAI.Setting node, got #{inspect(safety_setting)}"
      end
    end

    # -------------------------------------
    #
    # -------------------------------------
    def with_safety_settings(context, safety_settings) do
      Enum.reduce(safety_settings || [], context, fn
        {category, threshold}, context ->
          with_safety_setting(context, category, threshold)

        safety_setting, context when is_struct(safety_setting) ->
          with_safety_setting(context, safety_setting)
      end)
    end

    # -------------------------------------
    #
    # -------------------------------------

    def with_provider_setting(thread_context, provider, setting, value) do
      node =
        GenAI.Setting.ProviderSetting.new(
          provider: provider,
          setting: setting,
          value: value
        )

      append_node(thread_context, node)
    end

    def with_provider_setting(thread_context, setting_node) do
      if GenAI.Graph.Node.is_node?(setting_node, GenAI.Setting) do
        append_node(thread_context, setting_node)
      else
        raise ArgumentError,
          message: "Setting must be a GenAI.Setting node, got #{inspect(setting_node)}"
      end
    end

    def with_provider_settings(thread_context, provider, settings) do
      Enum.reduce(settings || [], thread_context, fn
        {setting, value}, thread_context ->
          with_provider_setting(thread_context, provider, setting, value)

        setting_object, thread_context ->
          with_provider_setting(thread_context, setting_object)
      end)
    end

    def with_provider_settings(thread_context, settings) do
      Enum.reduce(settings || [], thread_context, fn
        setting_object, thread_context -> with_provider_setting(thread_context, setting_object)
      end)
    end

    def with_model_setting(thread_context, model, setting, value) do
      node =
        GenAI.Setting.ModelSetting.new(
          model: model,
          setting: setting,
          value: value
        )

      append_node(thread_context, node)
    end

    def with_model_setting(thread_context, setting_node) do
      if GenAI.Graph.Node.is_node?(setting_node, GenAI.Setting) do
        append_node(thread_context, setting_node)
      else
        raise ArgumentError,
          message: "Setting must be a GenAI.Setting node, got #{inspect(setting_node)}"
      end
    end

    def with_model_settings(thread_context, model, settings) do
      Enum.reduce(settings || [], thread_context, fn
        {setting, value}, thread_context ->
          with_model_setting(thread_context, model, setting, value)

        setting_object, thread_context ->
          with_model_setting(thread_context, setting_object)
      end)
    end

    def with_model_settings(thread_context, settings) do
      Enum.reduce(settings, thread_context, fn
        setting_object, thread_context -> with_model_setting(thread_context, setting_object)
      end)
    end

    @doc """
    Add a message to the conversation.
    """
    def with_message(thread_context, message, options \\ nil)

    def with_message(thread_context, message, _) do
      if GenAI.Graph.Node.is_node?(message, GenAI.Message) do
        {:ok, n} = GenAI.Graph.NodeProtocol.with_id(message)
        append_node(thread_context, n)
      else
        raise ArgumentError,
          message: "Message must be a GenAI.Message node, got #{inspect(message)}"
      end
    end

    # -------------------------------------
    #
    # -------------------------------------
    @doc """
    Add a list of messages to the conversation.
    """
    def with_messages(context, messages, options)

    def with_messages(context, messages, options) do
      Enum.reduce(messages || [], context, fn message, context ->
        with_message(context, message, options)
      end)
    end

    # -------------------------------------
    #
    # -------------------------------------
    @doc """
    specify/override default stream handler
    """
    def with_stream_handler(thread_context, handler, options \\ nil)

    def with_stream_handler(thread_context, handler, _) do
      node =
        GenAI.Setting.new(
          setting: :stream_handler,
          value: handler
        )

      append_node(thread_context, node)
    end

    # -------------------------------------
    #
    # -------------------------------------
    defp initialize_session(command, %GenAI.Thread.Session{} = session, context, options) do
      with %GenAI.Thread.Session{state: state, runtime: runtime} <-
             session,
           {:ok, runtime} <-
             Runtime.command(runtime, command, context, options),
           {:ok, state} <-
             GenAI.Session.State.initialize(state, runtime, context, options),
           {:ok, {state, runtime}} <-
             GenAI.Session.State.monitor(state, runtime, context, options) do
        {:ok, %GenAI.Thread.Session{session | state: state, runtime: runtime}}
      end
    end

    # -------------------------------------
    #
    # -------------------------------------
    @doc """
    Run inference.

      This function performs the following steps:
    * Picks the appropriate model and hyperparameters based on the provided context and settings.
    * Performs any necessary pre-processing, such as RAG (Retrieval-Augmented Generation) or message consolidation.
    * Runs inference on the selected model with the prepared input.
    * Returns the inference result.
    """
    def execute(thread_context, command, context, options \\ nil)

    def execute(session, :run = command, context, options) do
      context = context || Noizu.Context.system()

      with {:ok, session} <-
             initialize_session(command, session, context, options),
           GenAI.Records.Node.process_end(session: session) <-
             GenAI.Graph.Root.process_node(session.root, nil, nil, session, context, options),
           {:ok, session} <- GenAI.Thread.Session.apply_directives(session, context, options),
           {:effective_model, {model, session}} <-
             session
             |> GenAI.ThreadProtocol.effective_model(context, options)
             |> apply_label(:effective_model),
           {:effective_provider, provider} <-
             model
             |> GenAI.ModelProtocol.provider()
             |> apply_label(:effective_provider) do
        # We now have a session populated with directives.
        # We need to expand directives then run inferences.
        # response = [:get_model, :get_provider, :call_provider_execute]
        # {:ok, {response, session}}

        provider.run(session, context, options)
      end
    end

    def execute(session, :stream, context, options) do
      context = context || Noizu.Context.system()

      with {:ok, session} <-
             initialize_session(:stream, session, context, options),
           GenAI.Records.Node.process_end(session: session) <-
             GenAI.Graph.Root.process_node(session.root, nil, nil, session, context, options),
           {:ok, session} <- GenAI.Thread.Session.apply_directives(session, context, options),
           {:effective_model, {model, session}} <-
             session
             |> GenAI.ThreadProtocol.effective_model(context, options)
             |> apply_label(:effective_model),
           {:effective_provider, provider} <-
             model
             |> GenAI.ModelProtocol.provider()
             |> apply_label(:effective_provider) do
        # We now have a session populated with directives.
        # We need to expand directives then run inferences.
        # response = [:get_model, :get_provider, :call_provider_execute]
        # {:ok, {response, session}}
        # TODO - handle existing stream options
        session = GenAI.with_setting(session, :stream, true)
        provider.stream(session, context, options)
      end
    end
    
    
    def effective_model(thread_context, context, options)

    def effective_model(this, _, _),
      do: {:ok, {this.state.model.value, this}}

    def effective_settings(thread_context, context, options)

    def effective_settings(this, _, _) do
      x =
        Enum.map(
          this.state.settings,
          fn
            {setting, value} ->
              {setting, value.value}
          end
        )

      {:ok, {x, this}}
    end

    def effective_safety_settings(thread_context, context, options)

    def effective_safety_settings(this, _, _) do
      x =
        Enum.map(
          this.state.safety_settings,
          fn
            {setting, value} ->
              {setting, value.value}
          end
        )

      {:ok, {x, this}}
    end

    def effective_model_settings(thread_context, model, context, options)

    def effective_model_settings(this, model, _, _) do
      with {:ok, name} <- GenAI.ModelProtocol.name(model),
           {:ok, provider} <- GenAI.ModelProtocol.provider(model) do
        key = {name, provider}

        x =
          Enum.map(
            this.state.model_settings[key] || [],
            fn
              {setting, value} ->
                {setting, value.value}
            end
          )

        {:ok, {x, this}}
      end
    end

    def effective_provider_settings(thread_context, model, context, options)

    def effective_provider_settings(this, model, _, _) do
      with {:ok, provider} <- GenAI.ModelProtocol.provider(model) do
        x =
          Enum.map(
            this.state.provider_settings[provider] || [],
            fn
              {setting, value} ->
                {setting, value.value}
            end
          )

        {:ok, {x, this}}
      end
    end

    def effective_messages(thread_context, model, context, options)

    def effective_messages(thread_context, model, context, options) do
      with {:ok, encoder} <- GenAI.ModelProtocol.encoder(model) do
        {messages, thread_context} =
          thread_context.state.thread
          |> Enum.reverse()
          |> Enum.map_reduce(
            thread_context,
            &encode_message(
              encoder,
              thread_context.state.thread_messages[&1],
              model,
              &2,
              context,
              options
            )
          )

        errors = errors(messages)

        if errors != [] do
          {:error, {:format_messages, errors}}
        else
          encoder.normalize_messages(messages, model, thread_context, context, options)
        end
      end
    end

    defp encode_message(encoder, message, model, session, context, options) do
      case encoder.encode_message(message.value, model, session, context, options) do
        {:ok, {encoded_message, session}} -> {encoded_message, session}
        error = {:error, _} -> {error, session}
      end
    end

    def effective_tools(thread_context, model, context, options)

    def effective_tools(thread_context, model, context, options) do
      with {:ok, encoder} <- GenAI.ModelProtocol.encoder(model) do
        {tools, thread_context} =
          thread_context.state.tools
          |> Enum.map_reduce(
            thread_context,
            &encode_tool(encoder, &1, model, &2, context, options)
          )

        errors = errors(tools)

        cond do
          errors != [] ->
            {:error, {:format_tools, errors}}

          tools == [] ->
            {:ok, {nil, thread_context}}

          :else ->
            {:ok, {tools, thread_context}}
        end
      end
    end

    defp encode_tool(encoder, {_, tool}, model, thread_context, context, options) do
      case encoder.encode_tool(tool.value, model, thread_context, context, options) do
        {:ok, {encoded_tool, thread_context}} -> {encoded_tool, thread_context}
        error = {:error, _} -> {error, thread_context}
      end
    end

    def set_artifact(thread_context, artifact, value)

    def set_artifact(thread_context, artifact, value) do
      thread_context
      |> put_in([Access.key(:state), Access.key(:artifacts), artifact], value)
      |> ok()
    end

    def get_artifact(thread_context, artifact)

    def get_artifact(thread_context, artifact) do
      thread_context
      |> get_in([Access.key(:state), Access.key(:artifacts), artifact])
      |> ok()
    end

    defp errors(messages) do
      messages
      |> Enum.filter(&Kernel.match?({:error, _}, &1))
    end

    defp ok(response), do: {:ok, response}
  end
end
