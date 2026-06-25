defmodule GenAI.MediaTest do
  @moduledoc """
  genai-core media framework (ADR-016): the supported_modalities/generate_media behaviour
  defaults, the capability Router + provider registry, and the GenAI.generate_media facade.
  Uses lightweight stub providers — no real provider APIs.
  """
  use ExUnit.Case, async: false

  alias GenAI.Media.Request

  # Minimal media-capable provider (implements only what the router/facade call).
  defmodule ImageStub do
    def config_key, do: :image_stub
    def supported_modalities, do: [%{input: [:text], output: :image, mode: :sync}]
    def generate_media(%Request{}, _opts), do: {:ok, %{data: "PNGBYTES", mime: "image/png", meta: %{}}}
  end

  # Transcription-style provider: speech INPUT -> text output (audio rides in settings).
  defmodule SpeechToTextStub do
    def config_key, do: :stt_stub
    def supported_modalities, do: [%{input: [:speech], output: :text, mode: :sync}]
    def generate_media(%Request{}, _opts), do: {:ok, %{data: "transcript", mime: "text/plain", meta: %{}}}
  end

  # A vanilla provider using the behaviour — should inherit the media defaults.
  defmodule DefaultProv do
    use GenAI.InferenceProviderBehaviour
  end

  setup do
    Application.put_env(:genai, :media_providers, [ImageStub, SpeechToTextStub])
    on_exit(fn -> Application.delete_env(:genai, :media_providers) end)
    :ok
  end

  describe "Router" do
    test "routes a request to a registry provider that declares the (input,output)" do
      assert {:ok, ImageStub} = GenAI.Media.Router.route(%Request{output: :image, prompt: "a cat"})
    end

    test "no registry provider for an unsupported output modality" do
      assert {:error, :no_provider_for_modality} =
               GenAI.Media.Router.route(%Request{output: :video, prompt: "x"})
    end

    test "explicit capable provider is validated + selected" do
      assert {:ok, ImageStub} =
               GenAI.Media.Router.route(%Request{output: :image, provider: ImageStub, prompt: "x"})
    end

    test "explicit provider that doesn't support the output -> :provider_unsupported" do
      assert {:error, :provider_unsupported} =
               GenAI.Media.Router.route(%Request{output: :video, provider: ImageStub, prompt: "x"})
    end

    test "explicit input hint ([:speech]) routes transcription, not the image provider" do
      assert {:ok, SpeechToTextStub} =
               GenAI.Media.Router.route(%Request{output: :text, input: [:speech], settings: %{audio: "..."}})
    end

    test "without the input hint, a text prompt does NOT route to the speech->text provider" do
      assert {:error, :no_provider_for_modality} =
               GenAI.Media.Router.route(%Request{output: :text, prompt: "just text"})
    end
  end

  describe "GenAI.generate_media facade" do
    test "routes + runs the provider's generate_media" do
      assert {:ok, %{data: "PNGBYTES", mime: "image/png"}} =
               GenAI.generate_media(%Request{output: :image, prompt: "a cat"})
    end

    test "no capable provider surfaces the router error" do
      assert {:error, :no_provider_for_modality} =
               GenAI.generate_media(%Request{output: :video, prompt: "x"})
    end
  end

  describe "behaviour defaults" do
    test "a vanilla provider declares text-only sync + denies media generation" do
      assert [%{input: [:text], output: :text, mode: :sync}] = DefaultProv.supported_modalities()
      assert {:error, :unsupported_modality} = DefaultProv.generate_media(%Request{output: :image}, [])
    end
  end
end
