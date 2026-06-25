using System;
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
