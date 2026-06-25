using UnityEngine;

namespace TheRobotDraft.Llm
{
    /// <summary>
    /// Persisted connection settings for the OpenAI-compatible chat endpoint used by the "Generate code" feature.
    /// Stored in <see cref="PlayerPrefs"/> so they survive across sessions; the defaults target a local LM Studio
    /// server (the common offline setup). The base URL is trimmed of a trailing '/' on use so callers can append
    /// "/chat/completions" without doubling the slash.
    /// </summary>
    public static class LlmSettings
    {
        private const string BaseUrlKey = "trd.llm.baseUrl";
        private const string ApiKeyKey = "trd.llm.apiKey";
        private const string ModelKey = "trd.llm.model";

        public const string DefaultBaseUrl = "http://localhost:1234/v1"; // LM Studio's OpenAI-compatible default
        public const string DefaultApiKey = "";
        public const string DefaultModel = "local-model";

        /// <summary>Endpoint root (e.g. "http://localhost:1234/v1"), with any trailing slash stripped. Empty ⇒ not configured.</summary>
        public static string BaseUrl => Trim(PlayerPrefs.GetString(BaseUrlKey, DefaultBaseUrl));

        /// <summary>Bearer token. Empty ⇒ no Authorization header is sent (local servers usually need none).</summary>
        public static string ApiKey => PlayerPrefs.GetString(ApiKeyKey, DefaultApiKey);

        /// <summary>Model id passed in the request body (e.g. "gpt-4o-mini", "local-model").</summary>
        public static string Model => PlayerPrefs.GetString(ModelKey, DefaultModel);

        /// <summary>Load the raw (untrimmed) values for an editor dialog.</summary>
        public static void Load(out string baseUrl, out string apiKey, out string model)
        {
            baseUrl = PlayerPrefs.GetString(BaseUrlKey, DefaultBaseUrl);
            apiKey = PlayerPrefs.GetString(ApiKeyKey, DefaultApiKey);
            model = PlayerPrefs.GetString(ModelKey, DefaultModel);
        }

        public static void Save(string baseUrl, string apiKey, string model)
        {
            PlayerPrefs.SetString(BaseUrlKey, baseUrl ?? "");
            PlayerPrefs.SetString(ApiKeyKey, apiKey ?? "");
            PlayerPrefs.SetString(ModelKey, string.IsNullOrWhiteSpace(model) ? DefaultModel : model.Trim());
            PlayerPrefs.Save();
        }

        private static string Trim(string url) => string.IsNullOrEmpty(url) ? url : url.TrimEnd('/');
    }
}
