defmodule GenAI.State.Directive do
  @moduledoc """
  A state directive applies selection values for specified state entries
  """
  @vsn 1.0

  defstruct [
    # map of selector record to selection entry or entries.
    entries: %{},
    vsn: @vsn
  ]
end
