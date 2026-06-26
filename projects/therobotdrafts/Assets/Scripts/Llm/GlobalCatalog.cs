using System;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

namespace TheRobotDraft.Llm
{
    /// <summary>
    /// Global authoring lookup data shared by every diagram/project on this machine. Stored under Unity's persistent
    /// data path, not inside saved project files.
    /// </summary>
    public static class GlobalCatalog
    {
        [Serializable]
        public sealed class LlmProviderEntry
        {
            public string name;
            public string baseUrl;
            public string envVar;
        }

        [Serializable]
        private sealed class LanguageValue
        {
            public string language;
            public string value;
        }

        [Serializable]
        private sealed class CatalogData
        {
            public List<string> languages = new List<string>();
            public List<string> fieldTypes = new List<string>();
            public List<string> constraints = new List<string>();
            public List<string> stereotypes = new List<string>();
            public List<LanguageValue> languageFieldTypes = new List<LanguageValue>();
            public List<LanguageValue> languageConstraints = new List<LanguageValue>();
            public List<LanguageValue> languageStereotypes = new List<LanguageValue>();
            public List<LlmProviderEntry> llmProviders = new List<LlmProviderEntry>();
            public List<string> llmModels = new List<string>();
        }

        private static CatalogData _data;

        private static readonly string[] DefaultLanguages =
            { "C#", "C/C++", "Rust", "Go", "Java", "Python", "Node.js", "Elixir", "TypeScript" };

        private static readonly string[] DefaultFieldTypes =
        {
            "string", "bool", "int", "long", "float", "double", "decimal", "Guid", "DateTime",
            "List<T>", "Dictionary<TKey,TValue>", "object", "void"
        };

        private static readonly string[] DefaultConstraints =
            { "{ordered}", "{unique}", "{subset}", "{xor}", "{readOnly}", "{not null}", "{pk}", "{fk}" };

        private static readonly string[] DefaultStereotypes =
            { "entity", "service", "controller", "value", "repository", "aggregate", "boundary", "dto" };

        private static readonly LlmProviderEntry[] DefaultProviders =
        {
            Provider("LM Studio (local)", "http://localhost:1234/v1", null),
            Provider("Ollama (local)", "http://localhost:11434/v1", null),
            Provider("OpenAI", "https://api.openai.com/v1", "OPENAI_API_KEY"),
            Provider("OpenRouter", "https://openrouter.ai/api/v1", "OPENROUTER_API_KEY"),
            Provider("Groq", "https://api.groq.com/openai/v1", "GROQ_API_KEY"),
            Provider("Together", "https://api.together.xyz/v1", "TOGETHER_API_KEY"),
            Provider("Mistral", "https://api.mistral.ai/v1", "MISTRAL_API_KEY"),
            Provider("DeepSeek", "https://api.deepseek.com/v1", "DEEPSEEK_API_KEY"),
            Provider("Cerebras", "https://api.cerebras.ai/v1", "CEREBRAS_API_KEY"),
            Provider("z.ai", "https://api.z.ai/api/paas/v4", "ZAI_API_KEY"),
        };

        public static List<string> Languages => Copy(Load().languages);
        public static List<string> FieldTypes => Copy(Load().fieldTypes);
        public static List<string> Constraints => Copy(Load().constraints);
        public static List<string> Stereotypes => Copy(Load().stereotypes);
        public static List<LlmProviderEntry> LlmProviders => CopyProviders(Load().llmProviders);
        public static List<string> LlmModels => Copy(Load().llmModels);

        public static List<string> FieldTypesForLanguage(string language) =>
            WithLanguageValues(Load().fieldTypes, Load().languageFieldTypes, language);

        public static List<string> ConstraintsForLanguage(string language) =>
            WithLanguageValues(Load().constraints, Load().languageConstraints, language);

        public static List<string> StereotypesForLanguage(string language) =>
            WithLanguageValues(Load().stereotypes, Load().languageStereotypes, language);

        public static void RememberLanguage(string value) => Remember(Load().languages, value);
        public static void RememberFieldType(string value) => Remember(Load().fieldTypes, value);
        public static void RememberConstraint(string value) => Remember(Load().constraints, value);
        public static void RememberStereotype(string value) => Remember(Load().stereotypes, value);

        public static void RememberFieldType(string language, string value) =>
            RememberLanguageValue(Load().fieldTypes, Load().languageFieldTypes, language, value);

        public static void RememberConstraint(string language, string value) =>
            RememberLanguageValue(Load().constraints, Load().languageConstraints, language, value);

        public static void RememberStereotype(string language, string value) =>
            RememberLanguageValue(Load().stereotypes, Load().languageStereotypes, language, value);

        public static void RememberLlmModel(string value)
        {
            Remember(Load().llmModels, value);
        }

        public static void RememberLlmProvider(string name, string baseUrl, string envVar = null)
        {
            if (string.IsNullOrWhiteSpace(baseUrl)) return;
            var data = Load();
            string url = baseUrl.Trim().TrimEnd('/');
            foreach (var provider in data.llmProviders)
            {
                if (!string.Equals((provider.baseUrl ?? "").TrimEnd('/'), url, StringComparison.OrdinalIgnoreCase))
                    continue;

                provider.name = string.IsNullOrWhiteSpace(name) ? provider.name : name.Trim();
                provider.envVar = string.IsNullOrWhiteSpace(envVar) ? provider.envVar : envVar.Trim();
                Save();
                return;
            }

            data.llmProviders.Add(new LlmProviderEntry
            {
                name = string.IsNullOrWhiteSpace(name) ? url : name.Trim(),
                baseUrl = url,
                envVar = string.IsNullOrWhiteSpace(envVar) ? null : envVar.Trim(),
            });
            SortProviders(data.llmProviders);
            Save();
        }

        private static CatalogData Load()
        {
            if (_data != null) return _data;
            try
            {
                string path = PathForCatalog();
                if (File.Exists(path))
                    _data = JsonUtility.FromJson<CatalogData>(File.ReadAllText(path));
            }
            catch (Exception e)
            {
                Debug.LogWarning("Global catalog load failed: " + e.Message);
            }

            if (_data == null) _data = new CatalogData();
            EnsureLists();
            SeedDefaults();
            return _data;
        }

        private static void EnsureLists()
        {
            if (_data.languages == null) _data.languages = new List<string>();
            if (_data.fieldTypes == null) _data.fieldTypes = new List<string>();
            if (_data.constraints == null) _data.constraints = new List<string>();
            if (_data.stereotypes == null) _data.stereotypes = new List<string>();
            if (_data.languageFieldTypes == null) _data.languageFieldTypes = new List<LanguageValue>();
            if (_data.languageConstraints == null) _data.languageConstraints = new List<LanguageValue>();
            if (_data.languageStereotypes == null) _data.languageStereotypes = new List<LanguageValue>();
            if (_data.llmProviders == null) _data.llmProviders = new List<LlmProviderEntry>();
            if (_data.llmModels == null) _data.llmModels = new List<string>();
        }

        private static void SeedDefaults()
        {
            bool changed = false;
            changed |= Seed(_data.languages, DefaultLanguages);
            changed |= Seed(_data.fieldTypes, DefaultFieldTypes);
            changed |= Seed(_data.constraints, DefaultConstraints);
            changed |= Seed(_data.stereotypes, DefaultStereotypes);

            foreach (var provider in DefaultProviders)
            {
                bool found = false;
                string url = (provider.baseUrl ?? "").TrimEnd('/');
                foreach (var existing in _data.llmProviders)
                    if (string.Equals((existing.baseUrl ?? "").TrimEnd('/'), url, StringComparison.OrdinalIgnoreCase))
                    {
                        found = true;
                        break;
                    }
                if (!found)
                {
                    _data.llmProviders.Add(new LlmProviderEntry
                    {
                        name = provider.name,
                        baseUrl = provider.baseUrl,
                        envVar = provider.envVar,
                    });
                    changed = true;
                }
            }
            SortProviders(_data.llmProviders);
            if (changed) Save();
        }

        private static bool Seed(List<string> list, string[] defaults)
        {
            bool changed = false;
            foreach (var value in defaults)
                if (AddUnique(list, value)) changed = true;
            list.Sort(StringComparer.OrdinalIgnoreCase);
            return changed;
        }

        private static void Remember(List<string> list, string value)
        {
            if (!AddUnique(list, value)) return;
            list.Sort(StringComparer.OrdinalIgnoreCase);
            Save();
        }

        private static void RememberLanguageValue(List<string> globalList, List<LanguageValue> languageList,
            string language, string value)
        {
            bool changed = AddUnique(globalList, value);
            if (!string.IsNullOrWhiteSpace(language) && !string.IsNullOrWhiteSpace(value))
            {
                string lang = language.Trim();
                string val = value.Trim();
                bool found = false;
                foreach (var item in languageList)
                    if (string.Equals(item.language, lang, StringComparison.OrdinalIgnoreCase)
                        && string.Equals(item.value, val, StringComparison.OrdinalIgnoreCase))
                    {
                        found = true;
                        break;
                    }
                if (!found)
                {
                    languageList.Add(new LanguageValue { language = lang, value = val });
                    changed = true;
                }
            }
            globalList.Sort(StringComparer.OrdinalIgnoreCase);
            if (changed) Save();
        }

        private static bool AddUnique(List<string> list, string value)
        {
            if (string.IsNullOrWhiteSpace(value)) return false;
            string normalized = value.Trim();
            foreach (var existing in list)
                if (string.Equals(existing, normalized, StringComparison.OrdinalIgnoreCase))
                    return false;
            list.Add(normalized);
            return true;
        }

        private static void Save()
        {
            try
            {
                string path = PathForCatalog();
                Directory.CreateDirectory(Path.GetDirectoryName(path));
                File.WriteAllText(path, JsonUtility.ToJson(_data, true));
            }
            catch (Exception e)
            {
                Debug.LogWarning("Global catalog save failed: " + e.Message);
            }
        }

        private static string PathForCatalog() =>
            Path.Combine(Application.persistentDataPath, "global-catalog.json");

        private static LlmProviderEntry Provider(string name, string baseUrl, string envVar) =>
            new LlmProviderEntry { name = name, baseUrl = baseUrl, envVar = envVar };

        private static List<string> Copy(List<string> source) =>
            source == null ? new List<string>() : new List<string>(source);

        private static List<string> WithLanguageValues(List<string> globalList, List<LanguageValue> languageList,
            string language)
        {
            var values = Copy(globalList);
            if (!string.IsNullOrWhiteSpace(language) && languageList != null)
            {
                string lang = language.Trim();
                foreach (var item in languageList)
                    if (item != null
                        && string.Equals(item.language, lang, StringComparison.OrdinalIgnoreCase)
                        && AddUnique(values, item.value))
                    {
                    }
            }
            values.Sort(StringComparer.OrdinalIgnoreCase);
            return values;
        }

        private static List<LlmProviderEntry> CopyProviders(List<LlmProviderEntry> source)
        {
            var copy = new List<LlmProviderEntry>();
            if (source == null) return copy;
            foreach (var p in source)
                copy.Add(new LlmProviderEntry { name = p.name, baseUrl = p.baseUrl, envVar = p.envVar });
            return copy;
        }

        private static void SortProviders(List<LlmProviderEntry> providers) =>
            providers.Sort((a, b) => string.Compare(a?.name, b?.name, StringComparison.OrdinalIgnoreCase));
    }
}
