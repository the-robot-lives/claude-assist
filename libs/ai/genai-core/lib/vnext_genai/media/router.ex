defmodule GenAI.Media.Router do
  @moduledoc """
  Routes a `GenAI.Media.Request` to a provider that DECLARES support for its
  (input, output) modality (ADR-016 D4 + dmitri N2: an explicit registry, not a
  hand-waved candidate set).

  Providers register via `config :genai, :media_providers, [Mod1, Mod2, ...]` — each a
  module that implements `supported_modalities/0` (and `generate_media/2`). An explicit
  `request.provider` is validated against its own declared modalities; `provider: nil`
  enumerates the registry and picks the first capable provider.

  genai-core owns the modality vocab; providers own their lists — the router never
  hardcodes a provider's capabilities.
  """
  alias GenAI.Media.Request

  @spec route(Request.t()) ::
          {:ok, module} | {:error, :no_provider_for_modality | :provider_unsupported}
  # ⟦𓈭𓉻𓎟𓏅⟧ route :: auto-generated pointer for public function route
  def route(%Request{provider: provider} = req) when not is_nil(provider) do
    case provider_module(provider) do
      nil -> {:error, :no_provider_for_modality}
      mod -> if supports?(mod, req), do: {:ok, mod}, else: {:error, :provider_unsupported}
    end
  end

  def route(%Request{} = req) do
    case Enum.find(registry(), &supports?(&1, req)) do
      nil -> {:error, :no_provider_for_modality}
      mod -> {:ok, mod}
    end
  end

  @doc "The configured media-capable provider modules."
  @spec registry() :: [module]
  # ⟦𓃿𓃾𓇰𓊓⟧ registry :: The configured media-capable provider modules.
  def registry, do: Application.get_env(:genai, :media_providers, [])

  # Resolve a provider given as a module OR a config-key atom, against the registry.
  defp provider_module(p) do
    cond do
      is_atom(p) and capable?(p) -> p
      true -> Enum.find(registry(), fn m -> m == p or config_key_match?(m, p) end)
    end
  end

  defp config_key_match?(mod, key) do
    function_exported?(mod, :config_key, 0) and mod.config_key() == key
  end

  defp capable?(mod) do
    Code.ensure_loaded?(mod) and function_exported?(mod, :supported_modalities, 0) and
      function_exported?(mod, :generate_media, 2)
  end

  # A provider supports a request if it declares a capability whose output matches and
  # whose input set covers the request's input modalities.
  defp supports?(mod, %Request{output: out} = req) do
    inputs = input_modalities(req)

    capable?(mod) and
      Enum.any?(mod.supported_modalities(), fn cap ->
        cap.output == out and inputs_covered?(inputs, cap.input)
      end)
  end

  # Input-modality detection. An explicit `input` list wins (e.g. transcription's
  # [:speech], whose audio rides in settings, not the prompt). Otherwise infer from the
  # prompt: text by default; an image part (for image+text -> image edits) adds :image.
  defp input_modalities(%Request{input: input}) when is_list(input) and input != [], do: input

  defp input_modalities(%Request{prompt: prompt}) when is_binary(prompt), do: [:text]

  defp input_modalities(%Request{prompt: parts}) when is_list(parts) do
    image? = Enum.any?(parts, &match?(%GenAI.Message.Content.ImageContent{}, &1))
    audio? = Enum.any?(parts, &audio_part?/1)

    [:text]
    |> then(&if(image?, do: &1 ++ [:image], else: &1))
    |> then(&if(audio?, do: &1 ++ [:speech], else: &1))
  end

  defp input_modalities(_), do: [:text]

  # Audio content part detection without a hard dep on an AudioContent struct existing.
  defp audio_part?(%{__struct__: mod}) do
    mod in [GenAI.Message.Content.AudioContent, GenAI.Message.Content.SpeechContent]
  end

  defp audio_part?(_), do: false

  defp inputs_covered?(inputs, cap_inputs), do: Enum.all?(inputs, &(&1 in cap_inputs))
end
