defimpl GenAI.Thread.LegacyStateProtocol, for: GenAI.Thread.Standard do
  defp ok(response), do: {:ok, response}

  defp effective_value_fetch_success(response, thread_context),
    do: {:ok, {response, thread_context}}

  defp errors(messages) do
    messages
    |> Enum.filter(&Kernel.match?({:error, _}, &1))
  end

  @doc """
  Add a model selector/constraint
  """
  def apply_model(thread_context, model)

  def apply_model(thread_context, model) do
    thread_context
    |> update_in([Access.key(:state), Access.key(:model)], &[model | &1 || []])
    |> ok()
  end

  @doc """
  Add a setting selector/constraint
  """
  def apply_setting(thread_context, node)

  def apply_setting(thread_context, node) do
    thread_context
    |> update_in(
      [Access.key(:state), Access.key(:settings), node.setting],
      &[node.value | &1 || []]
    )
    |> ok()
  end

  @doc """
  Add a provider specific setting selector/constraint
  """
  def apply_provider_setting(thread_context, node)

  def apply_provider_setting(thread_context, node) do
    thread_context
    |> update_in(
      [Access.key(:state), Access.key(:provider_settings), node.provider],
      fn
        nil ->
          %{node.setting => [node.value]}

        x ->
          update_in(x, [node.setting], &[node.value | &1 || []])
      end
    )
    |> ok()
  end

  @doc """
  Add a model specific setting selector/constraint
  """
  def apply_model_setting(thread_context, node)

  def apply_model_setting(thread_context, node) do
    with {:ok, m} <- GenAI.ModelProtocol.name(node.model),
         {:ok, p} <- GenAI.ModelProtocol.provider(node.model) do
      key = {p, m}

      thread_context
      |> update_in(
        [Access.key(:state), Access.key(:model_settings), key],
        fn
          nil -> %{node.setting => [node.value]}
          x -> update_in(x, [node.setting], &[node.value | &1 || []])
        end
      )
      |> ok()
    end
  end

  @doc """
  Add a model specific setting selector/constraint
  """
  def apply_safety_setting(thread_context, node)

  def apply_safety_setting(thread_context, node) do
    thread_context
    |> put_in(
      [Access.key(:state), Access.key(:safety_settings), node.category],
      node.threshold
    )
    |> ok()
  end

  @doc """
  Add a tool
  """
  def apply_tool(thread_context, tool)

  def apply_tool(thread_context, tool) do
    with {:ok, name} <- GenAI.ToolProtocol.name(tool) do
      thread_context
      |> put_in([Access.key(:state), Access.key(:tools), name], tool)
      |> ok()
    end
  end

  @doc """
  Add a tools
  """
  def apply_tools(thread_context, tools)
  def apply_tools(thread_context, nil), do: {:ok, thread_context}

  def apply_tools(thread_context, tools) when is_list(tools) do
    tools
    |> Enum.reduce_while(
      {:ok, thread_context},
      fn
        tool, {:ok, thread_context} ->
          {:cont, GenAI.Thread.LegacyStateProtocol.apply_tool(thread_context, tool)}

        _, error ->
          {:halt, error}
      end
    )
  end

  @doc """
  Add message
  """
  def apply_message(thread_context, message)

  def apply_message(thread_context, message) do
    thread_context
    |> update_in(
      [Access.key(:state), Access.key(:messages)],
      &[message | &1 || []]
    )
    |> ok()
  end

  @doc """
  Add messages
  """
  def apply_messages(thread_context, messages)

  def apply_messages(thread_context, messages) when is_list(messages) do
    thread_context
    |> update_in(
      [Access.key(:state), Access.key(:messages)],
      &(Enum.reverse(messages) ++ (&1 || []))
    )
    |> ok()
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

  @doc """
  Obtain the effective model as of current thread_context.
  @note temporary logic - pending support for context specific dynamic selection
  """
  def effective_model(thread_context, context, options)

  def effective_model(thread_context, _, _) do
    with %{model: [effective_model | _]} <- thread_context.state do
      effective_value_fetch_success(effective_model, thread_context)
    else
      _ ->
        {:error, :not_set}
    end
  end

  @doc """
  Obtain the effective settings as of current thread_context.
  @note temporary logic - pending support for context specific dynamic selection
  """
  def effective_settings(thread_context, _, _) do
    Enum.map(
      thread_context.state.settings,
      fn
        {{:__multi__, k}, v} ->
          Enum.map(v, &{k, &1})

        {k, [v | _]} ->
          {k, v}
      end
    )
    |> List.flatten()
    |> effective_value_fetch_success(thread_context)
  end

  def effective_model_settings(thread_context, model, _, _) do
    with {:ok, m} <- GenAI.ModelProtocol.name(model),
         {:ok, p} <- GenAI.ModelProtocol.provider(model) do
      key = {p, m}

      with settings = %{} <- thread_context.state.model_settings[key] do
        Enum.map(
          settings,
          fn
            {{:__multi__, k}, v} -> {k, v}
            {k, [v | _]} -> {k, v}
          end
        )
        |> effective_value_fetch_success(thread_context)
      else
        _ ->
          effective_value_fetch_success([], thread_context)
      end
    end
  end

  @doc """
  Obtain the effective provider settings as of current thread_context.
  @note temporary logic - pending support for context specific dynamic selection
  """
  def effective_provider_settings(thread_context, model, _, _) do
    with {:ok, provider} <- GenAI.ModelProtocol.provider(model),
         settings = %{} <- thread_context.state.provider_settings[provider] do
      Enum.map(
        settings,
        fn
          {{:__multi__, k}, v} -> {k, v}
          {k, [v | _]} -> {k, v}
        end
      )
      |> effective_value_fetch_success(thread_context)
    else
      _ ->
        effective_value_fetch_success([], thread_context)
    end
  end

  def effective_safety_settings(thread_context, _, _) do
    {:ok, {thread_context.state.safety_settings |> Enum.to_list(), thread_context}}
  end

  defp encode_message(encoder, message, model, thread_context, context, options) do
    case encoder.encode_message(message, model, thread_context, context, options) do
      {:ok, {encoded_message, thread_context}} -> {encoded_message, thread_context}
      error = {:error, _} -> {error, thread_context}
    end
  end

  def effective_messages(thread_context, model, context, options) do
    with {:ok, encoder} <- GenAI.ModelProtocol.encoder(model) do
      {messages, thread_context} =
        thread_context.state.messages
        |> Enum.reverse()
        |> Enum.map_reduce(
          thread_context,
          &encode_message(encoder, &1, model, &2, context, options)
        )

      errors = errors(messages)

      if errors != [] do
        {:error, {:format_messages, errors}}
      else
        encoder.normalize_messages(messages, model, thread_context, context, options)
      end
    end
  end

  defp encode_tool(encoder, {_, tool}, model, thread_context, context, options) do
    case encoder.encode_tool(tool, model, thread_context, context, options) do
      {:ok, {encoded_tool, thread_context}} -> {encoded_tool, thread_context}
      error = {:error, _} -> {error, thread_context}
    end
  end

  def effective_tools(thread_context, model, context, options) do
    with {:ok, encoder} <- GenAI.ModelProtocol.encoder(model) do
      {tools, thread_context} =
        thread_context.state.tools
        |> Enum.map_reduce(thread_context, &encode_tool(encoder, &1, model, &2, context, options))

      errors = errors(tools)

      cond do
        errors != [] ->
          {:error, {:format_tools, errors}}

        tools == [] ->
          {:ok, {nil, thread_context}}

        :else ->
          effective_value_fetch_success(tools, thread_context)
      end
    end
  end
end
