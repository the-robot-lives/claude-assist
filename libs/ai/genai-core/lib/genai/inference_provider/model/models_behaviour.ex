defmodule GenAI.Provider.ModelsBehaviour do
  @callback load_metadata(options :: any) :: term

  # ⟦𓄶𓅳𓄬𓎔⟧ load_metadata :: auto-generated pointer for public function load_metadata
  def load_metadata(%{provider: handler}, options), do: load_metadata(handler, options)
  def load_metadata(handler, options), do: apply(handler, :load_metadata, [options])
end
