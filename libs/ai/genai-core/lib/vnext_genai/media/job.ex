defmodule GenAI.Media.Job do
  @moduledoc """
  A handle for an ASYNC (submit -> poll -> download) media generation (ADR-016) —
  the shape long-running providers (music/video) return instead of inline bytes.

  Defined in genai-core NOW so sync and async share ONE `generate_media/2` return
  contract from day one (`{:ok, %{data, mime, meta}}` | `{:ok, %Job{}}` | `{:error, _}`).
  The submit/poll/download HARNESS is owned by the audio/video lane (soren); this is
  just the contract struct.
  """
  @type status :: :pending | :running | :succeeded | :failed

  @type t :: %__MODULE__{
          id: String.t() | nil,
          provider: module | atom | nil,
          status: status,
          output: %{data: binary, mime: String.t()} | nil,
          meta: map
        }

  defstruct id: nil,
            provider: nil,
            status: :pending,
            output: nil,
            meta: %{}
end
