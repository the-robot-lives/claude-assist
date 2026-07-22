defmodule GenAI.ModelMetadata.ProviderBehaviour do
  @callback get(scope :: module, model_name :: String.t()) :: {:ok, term} | {:error, term}
  @callback get(scope :: module, model_name :: String.t(), options :: term) ::
              {:ok, term} | {:error, term}

  # ⟦𓄏𓎦𓍼𓈷⟧ get :: auto-generated pointer for public function get
  def get(handler, scope, model), do: apply(handler, :get, [scope, model])
  def get(handler, scope, model, options), do: apply(handler, :get, [scope, model, options])
end
