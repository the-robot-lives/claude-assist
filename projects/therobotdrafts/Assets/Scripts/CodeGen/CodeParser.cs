using System;
using System.Text;
using UnityEngine;

namespace TheRobotDraft.CodeGen
{
    /// <summary>
    /// The inverse of <see cref="CodeSkeleton"/> / <see cref="CodeGenContext"/>: parses the LLM's structured
    /// description of pasted source back into model-ready data so the canvas can materialize UML elements
    /// (code → model). The DTOs are <see cref="JsonUtility"/>-shaped — a single root object with a named array
    /// of types — because the player runtime has no System.Text.Json (same constraint as <see cref="Llm.LlmClient"/>).
    /// <see cref="SystemPrompt"/> + <see cref="BuildUserPrompt"/> pin the exact JSON the model must emit; the
    /// UmlCanvas.CodeImport partial drives the request and turns a <see cref="ParsedModel"/> into elements + edges.
    /// </summary>
    public static class CodeParser
    {
        // --- structured-output DTOs (JsonUtility-serializable) ---

        /// <summary>One classifier the model found in the pasted source.</summary>
        [Serializable]
        public sealed class ParsedType
        {
            public string name;
            public string kind;        // Class | Interface | Enum | Struct (free text; mapped + defaulted to Class)
            public string language;    // implementation language, e.g. "C#", "TypeScript"
            public string comment;     // the type's doc-comment text, stripped of comment markers; "" when absent
            public string[] fields;    // UML attribute signatures, e.g. "- id : Guid"
            public string[] fieldComments;  // doc-comment per field, index-aligned with fields; "" when absent
            public string[] methods;   // UML operation signatures, e.g. "+ submit() : void"
            public string[] methodComments; // doc-comment per method, index-aligned with methods; "" when absent
            public string[] extends;   // base-type names (Generalization)
            public string[] implements; // interface names (Realization)
            public string[] uses;      // collaborator type names (Dependency)
        }

        /// <summary>The root object — a named array so <see cref="JsonUtility"/> can deserialize it.</summary>
        [Serializable]
        public sealed class ParsedModel
        {
            public ParsedType[] types;
        }

        // --- prompt ---

        /// <summary>System role: a precise instruction to return ONLY the JSON schema, no prose, no fences.</summary>
        public static string SystemPrompt =>
            "You are a senior software engineer that reverse-engineers source code into a UML class model. " +
            "Analyze the supplied source and identify every top-level type (class, interface, enum, struct). " +
            "Return ONLY a single JSON object — no markdown fences, no commentary — matching exactly this shape:\n" +
            "{\n" +
            "  \"types\": [\n" +
            "    {\n" +
            "      \"name\": \"TypeName\",\n" +
            "      \"kind\": \"Class\",                // one of: Class, Interface, Enum, Struct\n" +
            "      \"language\": \"C#\",                // the source language\n" +
            "      \"comment\": \"What this type is for.\",   // the type's doc-comment, plain text, markers stripped\n" +
            "      \"fields\":  [\"- id : Guid\", \"- total : decimal\"],   // UML attribute signatures\n" +
            "      \"fieldComments\": [\"The identity.\", \"\"],            // doc-comment per field, same order\n" +
            "      \"methods\": [\"+ submit() : void\", \"+ amountDue() : decimal\"], // UML operation signatures\n" +
            "      \"methodComments\": [\"Submit the order.\", \"\"],       // doc-comment per method, same order\n" +
            "      \"extends\": [\"BaseType\"],         // base class / parent type names\n" +
            "      \"implements\": [\"IPayable\"],      // interface names this type realizes\n" +
            "      \"uses\": [\"Customer\"]             // other type names this type depends on\n" +
            "    }\n" +
            "  ]\n" +
            "}\n" +
            "Rules: fields and methods are UML signature strings using visibility prefixes " +
            "(+ public, - private, # protected, ~ package) with the type after ':', e.g. \"- name : string\", " +
            "\"+ foo(a : int) : bool\". For enums, list each member as a field with no type, e.g. \"+ Pending\". " +
            "extends/implements/uses are bare type-name strings. Use empty arrays ([]) when a category is absent. " +
            "Extract doc-comments: put the type's documentation (XML doc, Javadoc, docstring, # comment, @doc/@moduledoc) " +
            "into \"comment\" as plain text with the comment markers removed; put each member's doc-comment into " +
            "\"fieldComments\"/\"methodComments\" in the SAME order and SAME length as \"fields\"/\"methods\" (use \"\" for " +
            "members with no comment). Do not invent types or comments that are not present in the source.";

        /// <summary>User role: the pasted source plus an optional language hint, framing it for analysis.</summary>
        public static string BuildUserPrompt(string code, string languageHint)
        {
            var sb = new StringBuilder();
            if (!string.IsNullOrWhiteSpace(languageHint))
                sb.Append("Language hint: ").Append(languageHint.Trim()).Append('\n');
            sb.Append("Analyze the following source and return the JSON model described above.\n\n");
            sb.Append("SOURCE:\n");
            sb.Append(code ?? "");
            return sb.ToString();
        }

        // --- parsing ---

        /// <summary>
        /// Parse the assistant's reply into a <see cref="ParsedModel"/>. Tolerates a stray markdown fence and any
        /// leading/trailing prose around the JSON object. On failure (no JSON, bad shape, no types) returns false
        /// and sets <paramref name="error"/>.
        /// </summary>
        public static bool TryParse(string content, out ParsedModel model, out string error)
        {
            model = null;
            error = null;
            if (string.IsNullOrWhiteSpace(content))
            {
                error = "empty response";
                return false;
            }

            string json = ExtractJsonObject(StripFences(content));
            if (string.IsNullOrWhiteSpace(json))
            {
                error = "no JSON object in response";
                return false;
            }

            try
            {
                var parsed = JsonUtility.FromJson<ParsedModel>(json);
                if (parsed == null || parsed.types == null)
                {
                    error = "JSON missing a \"types\" array";
                    return false;
                }
                if (parsed.types.Length == 0)
                {
                    error = "no types found in the source";
                    return false;
                }
                model = parsed;
                return true;
            }
            catch (Exception e)
            {
                error = "parse error: " + e.Message;
                return false;
            }
        }

        /// <summary>Strip a leading/trailing markdown code fence (```lang … ```) if the model added one anyway.</summary>
        private static string StripFences(string text)
        {
            if (string.IsNullOrEmpty(text)) return text;
            string s = text.Trim();
            if (!s.StartsWith("```")) return s;

            int firstNl = s.IndexOf('\n');
            if (firstNl < 0) return s;
            s = s.Substring(firstNl + 1); // drop the opening ```lang line

            int lastFence = s.LastIndexOf("```");
            if (lastFence >= 0) s = s.Substring(0, lastFence);
            return s.Trim();
        }

        /// <summary>Slice out the first balanced top-level <c>{ … }</c> so leading/trailing prose can't break parsing.</summary>
        private static string ExtractJsonObject(string s)
        {
            if (string.IsNullOrEmpty(s)) return s;
            int start = s.IndexOf('{');
            if (start < 0) return null;

            int depth = 0;
            bool inString = false, escaped = false;
            for (int i = start; i < s.Length; i++)
            {
                char c = s[i];
                if (inString)
                {
                    if (escaped) escaped = false;
                    else if (c == '\\') escaped = true;
                    else if (c == '"') inString = false;
                    continue;
                }
                if (c == '"') inString = true;
                else if (c == '{') depth++;
                else if (c == '}')
                {
                    depth--;
                    if (depth == 0) return s.Substring(start, i - start + 1);
                }
            }
            return null; // unbalanced — let the caller report a parse failure
        }
    }
}
