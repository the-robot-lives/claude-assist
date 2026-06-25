defmodule GenAI.Session.StateEntry do
  @moduledoc """
  A entry (built by directives) in a session state struct.
  """
  @vsn 1.0

  import GenAI.Records.Directive
  require GenAI.Records.Directive

  defstruct [
    #    entry: nil,
    value: nil,
    #    effective: nil,
    #    selectors: [],
    #    constraints: [],
    #    references: [],
    #    impacts: [],
    #    updated_on: nil,
    vsn: @vsn
  ]

  def update_entry(this, update, context, options)

  def update_entry(nil, value, context, options),
    do: update_entry(%__MODULE__{}, value, context, options)

  def update_entry(%__MODULE__{} = this, concrete_value(value: value), _, _),
    do: %__MODULE__{this | value: value}
end
