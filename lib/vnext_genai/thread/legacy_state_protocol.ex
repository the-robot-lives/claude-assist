defprotocol GenAI.Thread.LegacyStateProtocol do
  def apply_model(thread_context, model)
  def apply_setting(thread_context, node)
  def apply_provider_setting(thread_context, node)
  def apply_safety_setting(thread_context, node)
  def apply_model_setting(thread_context, node)
  def apply_tool(thread_context, tool)
  def apply_message(thread_context, message)

  def set_artifact(thread_context, artifact, value)
  def get_artifact(thread_context, artifact)

  def effective_model(thread_context, context, options)
  def effective_settings(thread_context, context, options)
  def effective_safety_settings(thread_context, context, options)
  def effective_model_settings(thread_context, model, context, options)
  def effective_provider_settings(thread_context, model, context, options)
  def effective_messages(thread_context, model, context, options)
  def effective_tools(thread_context, model, context, options)
end
