using System;
using System.Collections.Generic;
using System.Text;
using UnityEngine;
using UnityEngine.Networking;

namespace TheRobotDraft.Llm
{
    /// <summary>
    /// A tiny, dependency-free client for an OpenAI-compatible <c>/chat/completions</c> endpoint. Builds the
    /// request with <see cref="JsonUtility"/> (no System.Text.Json in the player runtime) and parses the first
    /// choice's message content back out. The caller owns the <see cref="UnityWebRequest"/> lifecycle (send it
    /// inside a coroutine and dispose it); this class only constructs and parses.
    /// </summary>
    public static class LlmClient
    {
        // --- request DTOs (JsonUtility-serializable) ---

        [Serializable]
        public sealed class Message
        {
            public string role;
            public string content;
            public Message() { }
            public Message(string role, string content) { this.role = role; this.content = content; }
        }

        [Serializable]
        private sealed class Request
        {
            public string model;
            public Message[] messages;
            public float temperature;
        }

        // --- response DTOs ---

        [Serializable]
        private sealed class Choice
        {
            public Message message;
        }

        [Serializable]
        private sealed class Response
        {
            public Choice[] choices;
        }

        [Serializable]
        private sealed class ErrorEnvelope
        {
            public ApiError error;
        }

        [Serializable]
        private sealed class ApiError
        {
            public string message;
        }

        // --- /models listing ---

        [Serializable]
        private sealed class ModelList { public ModelEntry[] data; }

        [Serializable]
        private sealed class ModelEntry { public string id; }

        /// <summary>Build (but do not send) a GET to <c>{baseUrl}/models</c> using the supplied (unsaved) credentials —
        /// used by the settings dialog's "Test connection" and "Fetch models" before the values are persisted.</summary>
        public static UnityWebRequest BuildModelsRequest(string baseUrl, string apiKey)
        {
            string url = TrimUrl(baseUrl) + "/models";
            var req = UnityWebRequest.Get(url);
            if (!string.IsNullOrEmpty(apiKey)) req.SetRequestHeader("Authorization", "Bearer " + apiKey);
            return req;
        }

        /// <summary>Parse the model ids out of an OpenAI-style <c>{"data":[{"id":"…"}]}</c> listing.</summary>
        public static bool TryParseModels(string json, out List<string> models, out string error)
        {
            models = new List<string>();
            error = null;
            if (string.IsNullOrWhiteSpace(json)) { error = "empty response"; return false; }
            try
            {
                var parsed = JsonUtility.FromJson<ModelList>(json);
                if (parsed != null && parsed.data != null)
                    foreach (var m in parsed.data)
                        if (m != null && !string.IsNullOrEmpty(m.id)) models.Add(m.id);
                if (models.Count > 0) { models.Sort(StringComparer.OrdinalIgnoreCase); return true; }

                var envelope = JsonUtility.FromJson<ErrorEnvelope>(json);
                if (envelope != null && envelope.error != null && !string.IsNullOrEmpty(envelope.error.message))
                { error = envelope.error.message; return false; }
                error = "no models in response";
                return false;
            }
            catch (Exception e) { error = "parse error: " + e.Message; return false; }
        }

        private static string TrimUrl(string url) => string.IsNullOrEmpty(url) ? url : url.TrimEnd('/');

        /// <summary>
        /// Build (but do not send) a POST to <c>{BaseUrl}/chat/completions</c> carrying the system + user prompt.
        /// Sets the JSON content type and a Bearer header only when an API key is configured.
        /// </summary>
        public static UnityWebRequest BuildChatRequest(string systemPrompt, string userPrompt)
        {
            var body = new Request
            {
                model = LlmSettings.Model,
                temperature = 0.2f,
                messages = new[]
                {
                    new Message("system", systemPrompt ?? ""),
                    new Message("user", userPrompt ?? ""),
                },
            };
            string json = JsonUtility.ToJson(body);
            byte[] payload = Encoding.UTF8.GetBytes(json);

            string url = LlmSettings.BaseUrl + "/chat/completions";
            var req = new UnityWebRequest(url, UnityWebRequest.kHttpVerbPOST)
            {
                uploadHandler = new UploadHandlerRaw(payload),
                downloadHandler = new DownloadHandlerBuffer(),
            };
            req.SetRequestHeader("Content-Type", "application/json");
            string key = LlmSettings.ApiKey;
            if (!string.IsNullOrEmpty(key))
                req.SetRequestHeader("Authorization", "Bearer " + key);
            return req;
        }

        /// <summary>
        /// Build (but do not send) a multimodal POST to <c>{baseUrl}/chat/completions</c>: a system prompt plus a
        /// user turn carrying text and an inline base64 PNG (<c>image_url</c> content part, data-URL form — the
        /// OpenAI-compatible vision convention LM Studio / Ollama / OpenRouter all accept). The body is composed by
        /// hand because <see cref="JsonUtility"/> cannot serialize the polymorphic <c>content</c> array. Explicit
        /// endpoint arguments (rather than <see cref="LlmSettings"/>) so the vision endpoint can differ from the
        /// text one. The caller owns the request lifecycle, as with <see cref="BuildChatRequest"/>.
        /// </summary>
        public static UnityWebRequest BuildVisionChatRequest(string baseUrl, string apiKey, string model,
            string systemPrompt, string userText, byte[] imagePng)
        {
            var sb = new StringBuilder(4096 + (imagePng != null ? (imagePng.Length / 3 + 1) * 4 : 0));
            sb.Append("{\"model\":").Append(JsonString(model))
              .Append(",\"temperature\":0.1,\"messages\":[");
            sb.Append("{\"role\":\"system\",\"content\":").Append(JsonString(systemPrompt ?? "")).Append("},");
            sb.Append("{\"role\":\"user\",\"content\":[");
            sb.Append("{\"type\":\"text\",\"text\":").Append(JsonString(userText ?? "")).Append('}');
            if (imagePng != null && imagePng.Length > 0)
            {
                sb.Append(",{\"type\":\"image_url\",\"image_url\":{\"url\":\"data:image/png;base64,")
                  .Append(Convert.ToBase64String(imagePng))
                  .Append("\"}}");
            }
            sb.Append("]}]}");

            byte[] payload = Encoding.UTF8.GetBytes(sb.ToString());
            string url = TrimUrl(baseUrl) + "/chat/completions";
            var req = new UnityWebRequest(url, UnityWebRequest.kHttpVerbPOST)
            {
                uploadHandler = new UploadHandlerRaw(payload),
                downloadHandler = new DownloadHandlerBuffer(),
            };
            req.SetRequestHeader("Content-Type", "application/json");
            if (!string.IsNullOrEmpty(apiKey))
                req.SetRequestHeader("Authorization", "Bearer " + apiKey);
            return req;
        }

        /// <summary>Encode a string as a JSON literal (quotes included), escaping per RFC 8259.</summary>
        private static string JsonString(string s)
        {
            var sb = new StringBuilder((s == null ? 0 : s.Length) + 8);
            sb.Append('"');
            foreach (char c in s ?? "")
            {
                switch (c)
                {
                    case '"': sb.Append("\\\""); break;
                    case '\\': sb.Append("\\\\"); break;
                    case '\n': sb.Append("\\n"); break;
                    case '\r': sb.Append("\\r"); break;
                    case '\t': sb.Append("\\t"); break;
                    case '\b': sb.Append("\\b"); break;
                    case '\f': sb.Append("\\f"); break;
                    default:
                        if (c < 0x20) sb.Append("\\u").Append(((int)c).ToString("x4"));
                        else sb.Append(c);
                        break;
                }
            }
            sb.Append('"');
            return sb.ToString();
        }

        /// <summary>
        /// Pull <c>choices[0].message.content</c> out of a chat-completions response body. On failure (empty body,
        /// missing choices, or an error envelope) returns false and sets <paramref name="error"/>.
        /// </summary>
        public static bool TryParseContent(string responseJson, out string content, out string error)
        {
            content = null;
            error = null;
            if (string.IsNullOrWhiteSpace(responseJson))
            {
                error = "empty response";
                return false;
            }

            try
            {
                var parsed = JsonUtility.FromJson<Response>(responseJson);
                if (parsed != null && parsed.choices != null && parsed.choices.Length > 0
                    && parsed.choices[0] != null && parsed.choices[0].message != null
                    && !string.IsNullOrEmpty(parsed.choices[0].message.content))
                {
                    content = parsed.choices[0].message.content;
                    return true;
                }

                // Surface an API-side error message if the server returned one instead of a completion.
                var envelope = JsonUtility.FromJson<ErrorEnvelope>(responseJson);
                if (envelope != null && envelope.error != null && !string.IsNullOrEmpty(envelope.error.message))
                {
                    error = envelope.error.message;
                    return false;
                }

                error = "no choices in response";
                return false;
            }
            catch (Exception e)
            {
                error = "parse error: " + e.Message;
                return false;
            }
        }
    }
}
