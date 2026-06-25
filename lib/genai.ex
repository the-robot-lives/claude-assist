defmodule GenAI do
  @doc """
  Creates a new chat context.
  """
  def chat(context_type \\ :default, options \\ nil)
  def chat(:default, options), do: GenAI.Thread.Standard.new(options)
  def chat(:standard, options), do: GenAI.Thread.Standard.new(options)
  def chat(:session, options), do: GenAI.Thread.Session.new(options)

  # Delegate function calls to the GenAI.Session implementation for the current context.

  @doc """
  Set model or model selector constraint for inference.
  """
  defdelegate with_model(thead_context, model), to: GenAI.ThreadProtocol

  @doc """
  Set tool for inference.
  """
  defdelegate with_tool(thead_context, tool), to: GenAI.ThreadProtocol

  @doc """
  Set tools for inference.
  """
  defdelegate with_tools(thead_context, tools), to: GenAI.ThreadProtocol

  @doc """
  Set API Key or API Key constraint for inference.
  @todo we will need per model keys for ollam and hugging face.
  """
  defdelegate with_api_key(thead_context, provider, api_key), to: GenAI.ThreadProtocol

  @doc """
  Set API Org or API Org constraint for inference.
  """
  defdelegate with_api_org(thead_context, provider, api_org), to: GenAI.ThreadProtocol

  @doc """
  Set Inference setting.
  `GenAI.Session`
  """
  defdelegate with_setting(thead_context, setting, value), to: GenAI.ThreadProtocol

  @doc """
  Set setting or setting selector constraint for inference.
  """
  defdelegate with_setting(thead_context, setting_object), to: GenAI.ThreadProtocol

  @doc """
  Set settings setting selector constraints for inference.
  """
  defdelegate with_settings(thead_context, setting_object), to: GenAI.ThreadProtocol

  @doc """
  Set safety setting for inference.
  @note - only fully supported by Gemini. backwards compatibility can be enabled via prompting but will be less reliable.
  """
  defdelegate with_safety_setting(thead_context, safety_setting, threshold),
    to: GenAI.ThreadProtocol

  defdelegate with_safety_setting(thead_context, safety_setting_object), to: GenAI.ThreadProtocol

  defdelegate with_provider_setting(thead_context, provider, setting, value),
    to: GenAI.ThreadProtocol

  defdelegate with_provider_setting(thead_context, provider_setting), to: GenAI.ThreadProtocol

  defdelegate with_provider_settings(thead_context, provider_settings), to: GenAI.ThreadProtocol

  defdelegate with_provider_settings(thead_context, provider, provider_settings),
    to: GenAI.ThreadProtocol

  defdelegate with_model_setting(thead_context, model, setting, value), to: GenAI.ThreadProtocol
  defdelegate with_model_setting(thead_context, model_setting), to: GenAI.ThreadProtocol

  @doc """
  Append message to thread.
  @note Message may be dynamic/generated.
  """
  defdelegate with_message(thead_context, message, options \\ nil), to: GenAI.ThreadProtocol

  @doc """
  Append messages to thread.
  @note Messages may be dynamic/generated.
  """
  defdelegate with_messages(thead_context, messages, options \\ nil), to: GenAI.ThreadProtocol

  @doc """
  Override streaming handler module.
  """
  defdelegate with_stream_handler(context, handler, options \\ nil), to: GenAI.ThreadProtocol

  @doc """
  Execute command.

    # Notes
  Used, for example, to retrieve full report of a thread with an optimization loop or data loop command.
  Under usual processing not final/accepted grid search loops are not returned in response and a linear thread is returned. Execute mode however will return a graph of all runs, or meta data based on options, and grid search configuration.
  """
  defdelegate execute(thread_context, command, context, options \\ nil), to: GenAI.ThreadProtocol

  @doc """
  Shorthand for execute report
  """
  def report(thread_context, context, options \\ nil) do
    GenAI.ThreadProtocol.execute(thread_context, :report, context, options)
  end

  @doc """
  Run inference in streaming mode, interstitial messages (dynamics) if any will sent to the stream handler using the interstitial handle
  """
  def stream(thread_context, context, options \\ nil) do
    GenAI.ThreadProtocol.execute(thread_context, :stream, context, options)
  end

  @doc """
  Run inference. Returning update chat completion and updated thread state.
  """
  def run(thread_context) do
    context = Noizu.Context.system()

    with {:ok, {completion, _}} <- run(thread_context, context, []) do
      {:ok, completion}
    end
  end

  def run(thread_context, context, options \\ nil) do
    GenAI.ThreadProtocol.execute(thread_context, :run, context, options)
  end
end
