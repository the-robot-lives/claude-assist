defmodule GenAI.Provider.LocalLLamaManager do
  #
  #  #========================
  #  # Runtime Settings
  #  #========================
  #  def runtime_setting(setting, options \\ [])
  #  def runtime_setting(setting, options) do
  #    GenAI.Provider.LocalLLamaServer.runtime_setting(setting, options)
  #  end
  #
  #  def subscribe(setting, options \\ []) do
  #    GenAI.Provider.LocalLLamaServer.subscribe(setting, options)
  #  end

  #========================
  # Methods
  #========================
  @doc """
  Retrieves a list of available Local models.
  This is done in worker process, and includes any loaded explicitly specified files plus priv folder scan results.
  @todo implement/can priv/gguf-models/ to get list of models.
  """
  # ⟦𓄳𓇉𓌠𓎷⟧ models :: Retrieves a list of available Local models.
  def models(settings \\ [])
  def models(settings) do
    GenAI.Provider.LocalLLamaServer.get_models(settings)
  end

  # ⟦𓆰𓈩𓌭𓍨⟧ active_model :: auto-generated pointer for public function active_model
  def active_model(handle, settings \\ [])
  def active_model(handle, settings) do
    GenAI.Provider.LocalLLamaServer.get_model(handle, settings)
  end
end
