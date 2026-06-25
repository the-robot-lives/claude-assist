defmodule GenAI.RequestError do
  @moduledoc """
  Custom error for handling request errors in the GenAI module.
  """
  defexception [:message, :details]
end
