defprotocol GenAI.Legacy.NodeProtocol do
  def apply(node, thread_context)
end

defimpl GenAI.Legacy.NodeProtocol, for: [GenAI.Graph.Node] do
  def apply(node, thread_context)

  def apply(_, thread_context) do
    {:ok, thread_context}
  end
end

defimpl GenAI.Legacy.NodeProtocol, for: GenAI.Tool do
  def apply(node, thread_context)

  def apply(node, thread_context) do
    GenAI.Thread.LegacyStateProtocol.apply_tool(thread_context, node)
  end
end

defimpl GenAI.Legacy.NodeProtocol, for: GenAI.Setting do
  def apply(node, thread_context)

  def apply(node, thread_context) do
    GenAI.Thread.LegacyStateProtocol.apply_setting(thread_context, node)
  end
end

defimpl GenAI.Legacy.NodeProtocol, for: GenAI.Setting.SafetySetting do
  def apply(node, thread_context)

  def apply(node, thread_context) do
    GenAI.Thread.LegacyStateProtocol.apply_safety_setting(thread_context, node)
  end
end

defimpl GenAI.Legacy.NodeProtocol, for: GenAI.Setting.ModelSetting do
  def apply(node, thread_context)

  def apply(node, thread_context) do
    GenAI.Thread.LegacyStateProtocol.apply_model_setting(thread_context, node)
  end
end

defimpl GenAI.Legacy.NodeProtocol, for: GenAI.Setting.ProviderSetting do
  def apply(node, thread_context)

  def apply(node, thread_context) do
    GenAI.Thread.LegacyStateProtocol.apply_provider_setting(thread_context, node)
  end
end

defimpl GenAI.Legacy.NodeProtocol, for: GenAI.Model do
  def apply(node, thread_context)

  def apply(model_or_selector, thread_context) do
    cond do
      GenAI.ModelProtocol.impl_for(model_or_selector) ->
        with {:ok, {registered_model, thread_context}} <-
               GenAI.ModelProtocol.register(model_or_selector, thread_context) do
          GenAI.Thread.LegacyStateProtocol.apply_model(thread_context, registered_model)
        else
          x = {:error, _} -> x
          x -> {:error, {:unexpected, x}}
        end

      :else ->
        GenAI.Thread.LegacyStateProtocol.apply_model(thread_context, model_or_selector)
    end
  end
end



defimpl GenAI.Legacy.NodeProtocol, for: GenAI.ExternalModel do
  def apply(node, thread_context)
  
  def apply(model_or_selector, thread_context) do
    cond do
      GenAI.ModelProtocol.impl_for(model_or_selector) ->
        with {:ok, {registered_model, thread_context}} <-
               GenAI.ModelProtocol.register(model_or_selector, thread_context) do
          GenAI.Thread.LegacyStateProtocol.apply_model(thread_context, registered_model)
        else
          x = {:error, _} -> x
          x -> {:error, {:unexpected, x}}
        end
      
      :else ->
        GenAI.Thread.LegacyStateProtocol.apply_model(thread_context, model_or_selector)
    end
  end
end

defimpl GenAI.Legacy.NodeProtocol,
  for: [GenAI.Message, GenAI.Message.ToolUsage, GenAI.Message.ToolResponse] do
  def apply(node, thread_context)

  def apply(node, thread_context) do
    GenAI.Thread.LegacyStateProtocol.apply_message(thread_context, node)
  end
end

defimpl GenAI.Legacy.NodeProtocol, for: GenAI.Graph do
  def apply(this, thread_context) do
    Enum.reduce(this.nodes, {:ok, thread_context}, fn
      _, thread_context = {:error, _} ->
        thread_context

      node, {:ok, thread_context} ->
        GenAI.Legacy.NodeProtocol.apply(node, thread_context)
    end)
  end
end
