defmodule GenAI.State.Entry do
  @moduledoc """
  A setting entry like model, provider, temperature set via directive.
  """
  @vsn 1.0

  defstruct [
    # current effective value
    effective_value: :pending,
    # list of selectors set by directives to control how the effective entry is calculated.
    selectors: [],
    vsn: @vsn
  ]

  def apply_selector(this = %__MODULE__{}, selector) do
    # temp logic
    this
    |> put_in([Access.key(:selectors)], selector)
    |> put_in([Access.key(:effective_value)], :pending)
  end
end
