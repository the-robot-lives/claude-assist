defmodule GenAI.Media.Request do
  @moduledoc """
  A media-generation request (ADR-016). The consumer facade `GenAI.generate_media/2`
  takes one of these, the Router picks a provider, and the provider's `generate_media/2`
  fulfils it.

    * `prompt`   - the generation prompt: a string, or content parts (incl. an image part
                   for image+text -> image edits).
    * `output`   - the target modality (`GenAI.InferenceProviderBehaviour.modality`):
                   `:image | :speech | :music | :sfx | :video | :document` (`:text` rides
                   the normal chat/Thread path, not this).
    * `provider` - optional explicit provider (module or config-key atom); nil => the
                   Router picks by declared capability.
    * `model`    - optional model override (e.g. "gpt-image-1").
    * `settings` - provider-interpreted knobs (size, quality, voice, duration, ...).
    * `api_key`  - optional per-request key; providers otherwise read their config/env.
  """
  @type modality :: GenAI.InferenceProviderBehaviour.modality()

  @type t :: %__MODULE__{
          prompt: term,
          output: modality,
          provider: module | atom | nil,
          model: String.t() | nil,
          settings: map,
          api_key: String.t() | nil
        }

  defstruct prompt: nil,
            output: nil,
            provider: nil,
            model: nil,
            settings: %{},
            api_key: nil
end
