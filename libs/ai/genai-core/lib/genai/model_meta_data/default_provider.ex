defmodule GenAI.ModelMetadata.DefaultProvider do
  # ⟦𓊙𓎮𓍆𓀅⟧ get :: auto-generated pointer for public function get
  def get(scope, model, options \\ nil)

  def get(scope, model, _) do
    {:ok,
     %GenAI.Model{
       provider: scope,
       model: model,
       details: %GenAI.ModelDetails{}
     }}
  end
end
