defmodule GenAI.Media.Request do
  @moduledoc """
  A media-generation request (ADR-016). The consumer facade `GenAI.generate_media/2`
  takes one of these, the Router picks a provider, and the provider's `generate_media/2`
  fulfils it.

    * `prompt`   - the generation prompt: a string, or content parts (incl. an image part
                   for image+text -> image edits).
    * `output`   - the target modality (`GenAI.InferenceProviderBehaviour.modality`):
                   `:image | :speech | :music | :sfx | :video | :document | :text`. Most
                   media generation outputs non-text; `:text` covers transcription
                   (speech -> text), which also rides this path.
    * `input`    - optional explicit input modality list (e.g. `[:speech]` for
                   transcription). When set, the Router uses it verbatim instead of
                   inferring from `prompt` — needed when the source media rides in
                   `settings` (e.g. audio bytes) rather than in the prompt.
    * `provider` - optional explicit provider (module or config-key atom); nil => the
                   Router picks by declared capability.
    * `model`    - optional model override (e.g. "gpt-image-1").
    * `settings` - provider-interpreted knobs (size, quality, voice, duration, audio, ...).
    * `api_key`  - optional per-request key; providers otherwise read their config/env.
  """
  @type modality :: GenAI.InferenceProviderBehaviour.modality()

  @type t :: %__MODULE__{
          prompt: term,
          output: modality,
          input: [modality] | nil,
          provider: module | atom | nil,
          model: String.t() | nil,
          settings: map,
          api_key: String.t() | nil
        }

  defstruct prompt: nil,
            output: nil,
            input: nil,
            provider: nil,
            model: nil,
            settings: %{},
            api_key: nil
end
