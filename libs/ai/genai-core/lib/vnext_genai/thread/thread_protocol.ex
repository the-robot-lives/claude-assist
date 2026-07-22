defprotocol GenAI.ThreadProtocol do
  @doc """
  Specify a specific model or model picker.

  This function allows you to define the model to be used for inference. You can either provide a specific model, like `Model.smartest()`, or a model picker function that dynamically selects the best model based on the context and available providers.

  Examples:
  * `Model.smartest()` - This will select the "smartest" available model at inference time, based on factors like performance and capabilities.
  * `Model.cheapest(params: :best_effort)` - This will select the cheapest available model that can handle the given parameters and context size.
  * `CustomProvider.custom_model` - This allows you to use a custom model from a user-defined provider.
  """
  # ⟦𓊗𓄱𓃽𓀔⟧ with_model :: Specify a specific model or model picker.
  def with_model(context, model)

  # ⟦𓌞𓆏𓉔𓍋⟧ with_tool :: auto-generated pointer for public function with_tool
  def with_tool(context, tool)
  # ⟦𓍲𓉊𓅠𓉜⟧ with_tools :: auto-generated pointer for public function with_tools
  def with_tools(context, tools)

  @doc """
  Specify an API key for a provider.
  """
  # ⟦𓇟𓎴𓆨𓍸⟧ with_api_key :: Specify an API key for a provider.
  def with_api_key(context, provider, api_key)

  @doc """
  Specify an API org for a provider.
  """
  # ⟦𓐔𓉆𓃎𓍮⟧ with_api_org :: Specify an API org for a provider.
  def with_api_org(context, provider, api_org)

  @doc """
  Set a hyperparameter option.

  Some options are model-specific. The value can be a literal or a picker function that dynamically determines the best value based on the context and model.

  Examples:
  * `Parameter.required(name, value)` - This sets a required parameter with the specified name and value.
  * `Gemini.best_temperature_for(:chain_of_thought)` - This uses a picker function to determine the best temperature for the Gemini provider when using the "chain of thought" prompting technique.
  """
  # ⟦𓉍𓍔𓇭𓅩⟧ with_setting :: Set a hyperparameter option.
  def with_setting(context, setting, value)
  def with_setting(context, setting_object)

  # ⟦𓀻𓇮𓋃𓀃⟧ with_settings :: auto-generated pointer for public function with_settings
  def with_settings(context, settings)

  # ⟦𓉉𓂵𓌯𓀅⟧ with_safety_setting :: auto-generated pointer for public function with_safety_setting
  def with_safety_setting(context, safety_setting, threshold)
  def with_safety_setting(context, safety_setting_object)

  # ⟦𓉀𓍜𓆭𓎔⟧ with_safety_settings :: auto-generated pointer for public function with_safety_settings
  def with_safety_settings(context, entries)

  # ⟦𓊘𓆌𓆃𓎟⟧ with_provider_setting :: auto-generated pointer for public function with_provider_setting
  def with_provider_setting(context, provider, setting, value)
  def with_provider_setting(context, node)

  # ⟦𓋽𓌛𓈘𓆊⟧ with_provider_settings :: auto-generated pointer for public function with_provider_settings
  def with_provider_settings(context, entries)
  def with_provider_settings(context, provider, entries)

  # ⟦𓉴𓃰𓂲𓂈⟧ with_model_setting :: auto-generated pointer for public function with_model_setting
  def with_model_setting(context, model, setting, value)
  def with_model_setting(context, node)

  # ⟦𓅰𓄹𓉤𓊯⟧ with_model_settings :: auto-generated pointer for public function with_model_settings
  def with_model_settings(context, model, entries)
  def with_model_settings(context, entries)

  @doc """
  Add a message to the conversation.
  """
  # ⟦𓉆𓍁𓅻𓐒⟧ with_message :: Add a message to the conversation.
  def with_message(context, message, options)

  @doc """
  Add a list of messages to the conversation.
  """
  # ⟦𓆈𓅾𓄁𓋕⟧ with_messages :: Add a list of messages to the conversation.
  def with_messages(context, messages, options)

  # ⟦𓁣𓊢𓋲𓄹⟧ with_stream_handler :: auto-generated pointer for public function with_stream_handler
  def with_stream_handler(context, handler, options \\ nil)

  # ⟦𓀩𓀘𓇛𓈒⟧ execute :: auto-generated pointer for public function execute
  def execute(session, command, context, options \\ nil)

  #  @doc """
  #  Start inference using a streaming handler.
  #
  #  If the selected model does not support streaming, the handler will be called with the final inference result.
  #  """
  #  def stream(thread_context, context)
  #
  #  @doc """
  #  Run inference.
  #
  #  This function performs the following steps:
  #  * Picks the appropriate model and hyperparameters based on the provided context and settings.
  #  * Performs any necessary pre-processing, such as RAG (Retrieval-Augmented Generation) or message consolidation.
  #  * Runs inference on the selected model with the prepared input.
  #  * Returns the inference result.
  #  """
  #  def run(context)

  # ⟦𓏓𓄯𓇄𓆀⟧ effective_model :: auto-generated pointer for public function effective_model
  def effective_model(thread_context, context, options)
  # ⟦𓎡𓌭𓄈𓌥⟧ effective_settings :: auto-generated pointer for public function effective_settings
  def effective_settings(thread_context, context, options)
  # ⟦𓁹𓀬𓎉𓆚⟧ effective_safety_settings :: auto-generated pointer for public function effective_safety_settings
  def effective_safety_settings(thread_context, context, options)
  # ⟦𓁀𓎧𓎊𓈶⟧ effective_model_settings :: auto-generated pointer for public function effective_model_settings
  def effective_model_settings(thread_context, model, context, options)
  # ⟦𓃇𓇸𓌧𓊄⟧ effective_provider_settings :: auto-generated pointer for public function effective_provider_settings
  def effective_provider_settings(thread_context, model, context, options)
  # ⟦𓋋𓇤𓉚𓌰⟧ effective_messages :: auto-generated pointer for public function effective_messages
  def effective_messages(thread_context, model, context, options)
  # ⟦𓅹𓎥𓏟𓃧⟧ effective_tools :: auto-generated pointer for public function effective_tools
  def effective_tools(thread_context, model, context, options)

  # ⟦𓏔𓈃𓏦𓐀⟧ append_directive :: auto-generated pointer for public function append_directive
  def append_directive(thread_context, directive, context, options)

  # ⟦𓆰𓂿𓍲𓀅⟧ set_artifact :: auto-generated pointer for public function set_artifact
  def set_artifact(thread_context, artifact, value)
  # ⟦𓅤𓂈𓊇𓈛⟧ get_artifact :: auto-generated pointer for public function get_artifact
  def get_artifact(thread_context, artifact)
end
