defmodule GenAI.Session.State.DirectiveBehaviour do
  @moduledoc false

  @callback apply_directive(directive :: any, session :: any, context :: any, options :: any) ::
              {:ok, session :: any} | {:error, details :: any}
end
