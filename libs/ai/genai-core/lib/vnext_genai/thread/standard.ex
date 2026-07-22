defmodule GenAI.Thread.Standard do
  @moduledoc """
  This module defines the chat struct used to manage conversations with generative AI models.
  """

  @vsn 1.0

  defstruct state: %GenAI.Thread.State{},
            graph: %GenAI.Graph{},
            vsn: @vsn

  # ⟦𓍷𓂡𓂢𓎔⟧ new :: auto-generated pointer for public function new
  def new(options \\ nil)

  def new(_) do
    %__MODULE__{}
  end

  defimpl GenAI.ThreadProtocol do
    @moduledoc """
    This allows chat contexts to be used for configuring and running GenAI interactions.
    """

    import GenAI.Helpers, only: [apply_label: 2]

    defp append_node(thread_context, node) do
      update_in(thread_context, [Access.key(:graph)], &GenAI.Graph.append_node(&1, node))
    end

    # ------------------------
    # append_directive/4
    # ------------------------
    # ⟦𓄏𓋲𓂢𓏛⟧ append_directive :: auto-generated pointer for public function append_directive
    def append_directive(session, directive, context, options \\ nil)

    def append_directive(session, _, _, _) do
      {:ok, session}
    end

    # ⟦𓎐𓁊𓂓𓀠⟧ with_model :: auto-generated pointer for public function with_model
    def with_model(thread_context, model) do
      if GenAI.Graph.Node.is_node?(model, GenAI.Model) do
        append_node(thread_context, model)
      else
        raise ArgumentError,
          message: "Model must be a GenAI.Model node, got #{inspect(model)}"
      end
    end

    # ⟦𓎶𓂈𓍗𓀙⟧ with_tool :: auto-generated pointer for public function with_tool
    def with_tool(thread_context, tool) do
      if GenAI.Graph.Node.is_node?(tool, GenAI.Tool) do
        append_node(thread_context, tool)
      else
        raise ArgumentError,
          message: "Tool must be a GenAI.Tool node, got #{inspect(tool)}"
      end
    end

    # ⟦𓏏𓋡𓊟𓊮⟧ with_tools :: auto-generated pointer for public function with_tools
    def with_tools(thread_context, tools)

    def with_tools(thread_context, nil),
      do: thread_context

    def with_tools(thread_context, tools) do
      Enum.reduce(tools, thread_context, fn tool, thread_context ->
        with_tool(thread_context, tool)
      end)
    end

    # ⟦𓐑𓉄𓋴𓁡⟧ with_api_key :: auto-generated pointer for public function with_api_key
    def with_api_key(thread_context, provider, api_key) do
      node =
        GenAI.Setting.ProviderSetting.new(
          provider: provider,
          setting: :api_key,
          value: api_key
        )

      append_node(thread_context, node)
    end

    # ⟦𓄱𓍰𓎷𓂴⟧ with_api_org :: auto-generated pointer for public function with_api_org
    def with_api_org(thread_context, provider, api_org) do
      node =
        GenAI.Setting.ProviderSetting.new(
          provider: provider,
          setting: :api_org,
          value: api_org
        )

      append_node(thread_context, node)
    end

    # ⟦𓐢𓂱𓋾𓆏⟧ with_setting :: auto-generated pointer for public function with_setting
    def with_setting(thread_context, setting, value) do
      node =
        GenAI.Setting.new(
          setting: setting,
          value: value
        )

      append_node(thread_context, node)
    end

    def with_setting(thread_context, setting_node) do
      if GenAI.Graph.Node.is_node?(setting_node, GenAI.Setting) do
        append_node(thread_context, setting_node)
      else
        raise ArgumentError,
          message: "Setting must be a GenAI.Setting node, got #{inspect(setting_node)}"
      end
    end

    # ⟦𓏇𓎜𓃂𓈲⟧ with_settings :: auto-generated pointer for public function with_settings
    def with_settings(thread_context, nil), do: thread_context

    def with_settings(thread_context, settings) do
      Enum.reduce(settings, thread_context, fn
        {setting, value}, thread_context -> with_setting(thread_context, setting, value)
        setting_object, thread_context -> with_setting(thread_context, setting_object)
      end)
    end

    # ⟦𓉿𓆕𓏯𓇚⟧ with_safety_setting :: auto-generated pointer for public function with_safety_setting
    def with_safety_setting(thread_context, category, threshold) do
      node =
        GenAI.Setting.SafetySetting.new(
          category: category,
          threshold: threshold
        )

      append_node(thread_context, node)
    end

    def with_safety_setting(thread_context, setting_node) do
      if GenAI.Graph.Node.is_node?(setting_node, GenAI.Setting) do
        append_node(thread_context, setting_node)
      else
        raise ArgumentError,
          message: "Setting must be a GenAI.Setting node, got #{inspect(setting_node)}"
      end
    end

    # ⟦𓈦𓆮𓄽𓅙⟧ with_safety_settings :: auto-generated pointer for public function with_safety_settings
    def with_safety_settings(thread_context, nil), do: thread_context

    def with_safety_settings(thread_context, entries) do
      Enum.reduce(entries, thread_context, fn
        {category, threshold}, thread_context ->
          with_safety_setting(thread_context, category, threshold)

        setting_object, thread_context ->
          with_safety_setting(thread_context, setting_object)
      end)
    end

    # ⟦𓄚𓀌𓎚𓏈⟧ with_provider_setting :: auto-generated pointer for public function with_provider_setting
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

    # ⟦𓌌𓄘𓅕𓎠⟧ with_provider_settings :: auto-generated pointer for public function with_provider_settings
    def with_provider_settings(thread_context, provider, settings)
    def with_provider_settings(thread_context, _, nil), do: thread_context

    def with_provider_settings(thread_context, provider, settings) do
      Enum.reduce(settings, thread_context, fn
        {setting, value}, thread_context ->
          with_provider_setting(thread_context, provider, setting, value)

        setting_object, thread_context ->
          with_provider_setting(thread_context, setting_object)
      end)
    end

    def with_provider_settings(thread_context, settings)
    def with_provider_settings(thread_context, nil), do: thread_context

    def with_provider_settings(thread_context, settings) do
      Enum.reduce(settings, thread_context, fn
        setting_object, thread_context -> with_provider_setting(thread_context, setting_object)
      end)
    end

    # ⟦𓋍𓆺𓎓𓄳⟧ with_model_setting :: auto-generated pointer for public function with_model_setting
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

    # ⟦𓍂𓂊𓄱𓏄⟧ with_model_settings :: auto-generated pointer for public function with_model_settings
    def with_model_settings(thread_context, model, settings) do
      Enum.reduce(settings, thread_context, fn
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

    # ⟦𓉔𓉾𓈀𓊮⟧ with_message :: auto-generated pointer for public function with_message
    def with_message(thread_context, message, options)

    def with_message(thread_context, message_node, _) do
      if GenAI.Graph.Node.is_node?(message_node, GenAI.Message) do
        append_node(thread_context, message_node)
      else
        raise ArgumentError,
          message: "Message must be a GenAI.Message node, got #{inspect(message_node)}"
      end
    end

    # ⟦𓐪𓂏𓊣𓃂⟧ with_messages :: auto-generated pointer for public function with_messages
    def with_messages(thread_context, messages, options) do
      Enum.reduce(messages, thread_context, fn message, thread_context ->
        with_message(thread_context, message, options)
      end)
    end

    # ⟦𓆨𓇾𓃇𓀝⟧ with_stream_handler :: auto-generated pointer for public function with_stream_handler
    def with_stream_handler(thread_context, handler, options \\ nil)

    def with_stream_handler(thread_context, handler, _) do
      node =
        GenAI.Setting.new(
          setting: :stream_handler,
          value: handler
        )

      append_node(thread_context, node)
    end

    @doc """
    Runs inference on the chat context.

    This function determines the final settings and model, prepares the messages, and then delegates the actual inference execution to the selected provider's `chat/3` function.
    """
    # ⟦𓋪𓏋𓀉𓋊⟧ execute :: Runs inference on the chat context.
    def execute(thread_context, command, context, options \\ nil)

    def execute(thread_context, :run, context, options) do
      with {:prep, thread_context} <-
             thread_context.graph
             |> GenAI.Legacy.NodeProtocol.apply(thread_context)
             |> apply_label(:prep),
           {:effective_model, {model, thread_context}} <-
             thread_context
             |> GenAI.Thread.LegacyStateProtocol.effective_model(context, options)
             |> apply_label(:effective_model),
           {:effective_provider, provider} <-
             model
             |> GenAI.ModelProtocol.provider()
             |> apply_label(:effective_provider) do
        provider.run(thread_context, context, options)
      end
    end

    def execute(thread_context, :stream, context, options) do
      with {:prep, thread_context} <-
             thread_context.graph
             |> GenAI.Legacy.NodeProtocol.apply(thread_context)
             |> apply_label(:prep),
           {:effective_model, {model, thread_context}} <-
             thread_context
             |> GenAI.Thread.LegacyStateProtocol.effective_model(context, options)
             |> apply_label(:effective_model),
           {:effective_provider, provider} <-
             model
             |> GenAI.ModelProtocol.provider()
             |> apply_label(:effective_provider) do
        # TODO - handle existing stream options
        thread_context = GenAI.with_setting(thread_context, :stream, true)
        provider.stream(thread_context, context, options)
      end
    end

    defdelegate effective_model(thread_context, context, options),
      to: GenAI.Thread.LegacyStateProtocol

    defdelegate effective_settings(thread_context, context, options),
      to: GenAI.Thread.LegacyStateProtocol

    defdelegate effective_safety_settings(thread_context, context, options),
      to: GenAI.Thread.LegacyStateProtocol

    defdelegate effective_model_settings(thread_context, model, context, options),
      to: GenAI.Thread.LegacyStateProtocol

    defdelegate effective_provider_settings(thread_context, model, context, options),
      to: GenAI.Thread.LegacyStateProtocol

    defdelegate effective_messages(thread_context, model, context, options),
      to: GenAI.Thread.LegacyStateProtocol

    defdelegate effective_tools(thread_context, model, context, options),
      to: GenAI.Thread.LegacyStateProtocol

    defdelegate set_artifact(thread_context, artifact, value),
      to: GenAI.Thread.LegacyStateProtocol

    defdelegate get_artifact(thread_context, artifact), to: GenAI.Thread.LegacyStateProtocol
  end
end
