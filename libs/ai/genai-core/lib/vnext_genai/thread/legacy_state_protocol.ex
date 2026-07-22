defprotocol GenAI.Thread.LegacyStateProtocol do
  # ⟦𓌬𓊐𓃜𓈗⟧ apply_model :: auto-generated pointer for public function apply_model
  def apply_model(thread_context, model)
  # ⟦𓇉𓍭𓉈𓍁⟧ apply_setting :: auto-generated pointer for public function apply_setting
  def apply_setting(thread_context, node)
  # ⟦𓆔𓀺𓈀𓀩⟧ apply_provider_setting :: auto-generated pointer for public function apply_provider_setting
  def apply_provider_setting(thread_context, node)
  # ⟦𓅱𓍚𓎒𓁏⟧ apply_safety_setting :: auto-generated pointer for public function apply_safety_setting
  def apply_safety_setting(thread_context, node)
  # ⟦𓌪𓆧𓆋𓌓⟧ apply_model_setting :: auto-generated pointer for public function apply_model_setting
  def apply_model_setting(thread_context, node)
  # ⟦𓄟𓇚𓇜𓏯⟧ apply_tool :: auto-generated pointer for public function apply_tool
  def apply_tool(thread_context, tool)
  # ⟦𓀥𓆖𓊶𓎁⟧ apply_message :: auto-generated pointer for public function apply_message
  def apply_message(thread_context, message)

  # ⟦𓍯𓏵𓆝𓆣⟧ set_artifact :: auto-generated pointer for public function set_artifact
  def set_artifact(thread_context, artifact, value)
  # ⟦𓄌𓇃𓎢𓂝⟧ get_artifact :: auto-generated pointer for public function get_artifact
  def get_artifact(thread_context, artifact)

  # ⟦𓏀𓌻𓈐𓄺⟧ effective_model :: auto-generated pointer for public function effective_model
  def effective_model(thread_context, context, options)
  # ⟦𓈐𓅼𓅎𓍦⟧ effective_settings :: auto-generated pointer for public function effective_settings
  def effective_settings(thread_context, context, options)
  # ⟦𓉭𓉞𓍳𓊦⟧ effective_safety_settings :: auto-generated pointer for public function effective_safety_settings
  def effective_safety_settings(thread_context, context, options)
  # ⟦𓌽𓉭𓍇𓇜⟧ effective_model_settings :: auto-generated pointer for public function effective_model_settings
  def effective_model_settings(thread_context, model, context, options)
  # ⟦𓂑𓎿𓈝𓁡⟧ effective_provider_settings :: auto-generated pointer for public function effective_provider_settings
  def effective_provider_settings(thread_context, model, context, options)
  # ⟦𓈿𓀍𓅖𓂟⟧ effective_messages :: auto-generated pointer for public function effective_messages
  def effective_messages(thread_context, model, context, options)
  # ⟦𓅛𓀗𓀄𓌨⟧ effective_tools :: auto-generated pointer for public function effective_tools
  def effective_tools(thread_context, model, context, options)
end
