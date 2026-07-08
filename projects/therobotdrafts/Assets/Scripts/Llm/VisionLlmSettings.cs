using UnityEngine;

namespace TheRobotDraft.Llm
{
    /// <summary>
    /// Persisted connection settings for the vision-enabled OpenAI-compatible endpoint used by the
    /// "Import diagram from image" feature. A fully separate triple from <see cref="LlmSettings"/> so a local
    /// text model (LM Studio) and a cloud vision model (or a different local multimodal model) can coexist.
    /// Any field left empty falls back to the corresponding <see cref="LlmSettings"/> value, so a single-endpoint
    /// setup keeps working with zero extra configuration.
    /// </summary>
    public static class VisionLlmSettings
    {
        private const string BaseUrlKey = "trd.llm.vision.baseUrl";
        private const string ApiKeyKey = "trd.llm.vision.apiKey";
        private const string ModelKey = "trd.llm.vision.model";

        /// <summary>Vision endpoint root, falling back to the main LLM endpoint when unset.</summary>
        public static string BaseUrl
        {
            get
            {
                string url = Trim(PlayerPrefs.GetString(BaseUrlKey, ""));
                return string.IsNullOrEmpty(url) ? LlmSettings.BaseUrl : url;
            }
        }

        /// <summary>Bearer token for the vision endpoint. Falls back to the main key only when the vision
        /// base URL is also unset (a key for provider A must never be sent to provider B).</summary>
        public static string ApiKey
        {
            get
            {
                string url = Trim(PlayerPrefs.GetString(BaseUrlKey, ""));
                string key = PlayerPrefs.GetString(ApiKeyKey, "");
                if (!string.IsNullOrEmpty(url)) return key; // dedicated endpoint → its own key (possibly empty)
                return string.IsNullOrEmpty(key) ? LlmSettings.ApiKey : key;
            }
        }

        /// <summary>Vision model id, falling back to the main model when unset.</summary>
        public static string Model
        {
            get
            {
                string model = PlayerPrefs.GetString(ModelKey, "");
                return string.IsNullOrWhiteSpace(model) ? LlmSettings.Model : model.Trim();
            }
        }

        /// <summary>True when either a dedicated vision endpoint or the main endpoint is configured.</summary>
        public static bool IsConfigured => !string.IsNullOrEmpty(BaseUrl);

        /// <summary>True when a dedicated (non-fallback) vision endpoint or model has been saved.</summary>
        public static bool HasDedicatedSettings =>
            !string.IsNullOrEmpty(PlayerPrefs.GetString(BaseUrlKey, ""))
            || !string.IsNullOrEmpty(PlayerPrefs.GetString(ModelKey, ""));

        /// <summary>Load the raw (untrimmed, no-fallback) values for the settings dialog.</summary>
        public static void Load(out string baseUrl, out string apiKey, out string model)
        {
            baseUrl = PlayerPrefs.GetString(BaseUrlKey, "");
            apiKey = PlayerPrefs.GetString(ApiKeyKey, "");
            model = PlayerPrefs.GetString(ModelKey, "");
        }

        public static void Save(string baseUrl, string apiKey, string model)
        {
            PlayerPrefs.SetString(BaseUrlKey, baseUrl ?? "");
            PlayerPrefs.SetString(ApiKeyKey, apiKey ?? "");
            PlayerPrefs.SetString(ModelKey, model == null ? "" : model.Trim());
            PlayerPrefs.Save();
        }

        private static string Trim(string url) => string.IsNullOrEmpty(url) ? url : url.TrimEnd('/');
    }
}
