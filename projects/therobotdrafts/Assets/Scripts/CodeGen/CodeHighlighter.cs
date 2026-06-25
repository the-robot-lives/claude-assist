using System.Collections.Generic;
using System.Text;

namespace TheRobotDraft.CodeGen
{
    /// <summary>
    /// Turns source text into a Unity rich-text string for read-only display in the code viewer. The RAW source is
    /// always kept separately by the caller (for Copy / Approve); <see cref="Highlight"/> only produces the coloured
    /// DISPLAY string and never mutates the original.
    ///
    /// Legacy <c>UnityEngine.UI.Text</c> rich text has no entity escaping and no <c>&lt;noparse&gt;</c>, so literal
    /// <c>&lt;</c>/<c>&gt;</c> in the code (generics, operators, shift) would be eaten as malformed tags. To keep the
    /// listing readable while preventing tag breakage we substitute look-alike angle brackets in the DISPLAY string
    /// only: <c>&lt;</c> → ‹ (U+2039) and <c>&gt;</c> → › (U+203A). The colour markup itself uses real
    /// <c>&lt;color=#RRGGBB&gt;…&lt;/color&gt;</c> tags, which the parser still interprets.
    ///
    /// Tokenisation is line-aware (line comments, block comments, string/char literals, numbers, keywords, and
    /// Capitalized type-ish identifiers) and defensive: on very large input it skips tokenisation and returns a
    /// minimally-escaped string so it can never stall the UI thread.
    /// </summary>
    public static class CodeHighlighter
    {
        /// <summary>Above this many characters we skip tokenisation entirely and just escape angle brackets.</summary>
        private const int MaxTokenizeChars = 200_000;

        // Calm palette tuned for the viewer's dark (#1A1C24-ish) background.
        private const string ColComment = "#7C8A78"; // green-gray
        private const string ColKeyword = "#8B86DA"; // blue/purple
        private const string ColString  = "#D2A062"; // amber/brown
        private const string ColNumber  = "#54B6B0"; // teal
        private const string ColType    = "#6F9CC6"; // steel

        /// <summary>
        /// Produce the coloured DISPLAY string for <paramref name="code"/> in the given <paramref name="language"/>
        /// (a language name like "C#" / "elixir" or a file extension like ".ts"; defaults to C#). The returned string
        /// has its literal angle brackets replaced with look-alikes and is safe to assign to a rich-text Text.
        /// </summary>
        public static string Highlight(string code, string language)
        {
            if (string.IsNullOrEmpty(code)) return code ?? "";
            if (code.Length > MaxTokenizeChars) return EscapeAngles(code);

            var lang = Resolve(language);
            var sb = new StringBuilder(code.Length + 64);
            int n = code.Length;
            int i = 0;

            while (i < n)
            {
                char c = code[i];

                // Block comment  /* … */  (C-family only).
                if (lang.BlockComments && c == '/' && i + 1 < n && code[i + 1] == '*')
                {
                    int end = code.IndexOf("*/", i + 2);
                    end = end < 0 ? n : end + 2;
                    AppendSpan(sb, ColComment, code, i, end);
                    i = end;
                    continue;
                }

                // Line comment  ( // or # or -- depending on language ) → to end of line.
                int lc = LineCommentLen(lang, code, i, n);
                if (lc > 0)
                {
                    int end = code.IndexOf('\n', i);
                    if (end < 0) end = n;
                    AppendSpan(sb, ColComment, code, i, end);
                    i = end;
                    continue;
                }

                // String / char literal. Stops at the matching quote, an unescaped newline, or EOF.
                if (c == '"' || c == '\'' || (lang.BackTickStrings && c == '`'))
                {
                    int end = ScanString(code, i, n);
                    AppendSpan(sb, ColString, code, i, end);
                    i = end;
                    continue;
                }

                // Number literal (only when not in the middle of an identifier).
                if (IsDigit(c) && (i == 0 || !IsIdentPart(code[i - 1])))
                {
                    int end = i + 1;
                    while (end < n && (IsIdentPart(code[end]) || code[end] == '.')) end++;
                    AppendSpan(sb, ColNumber, code, i, end);
                    i = end;
                    continue;
                }

                // Identifier / keyword / type-ish word.
                if (IsIdentStart(c))
                {
                    int end = i + 1;
                    while (end < n && IsIdentPart(code[end])) end++;
                    string word = code.Substring(i, end - i);
                    if (lang.Keywords.Contains(word)) AppendSpan(sb, ColKeyword, word);
                    else if (IsTypeish(word)) AppendSpan(sb, ColType, word);
                    else AppendEscaped(sb, word);
                    i = end;
                    continue;
                }

                // Anything else (operators, punctuation, whitespace) — escape angle brackets and pass through.
                AppendEscapedChar(sb, c);
                i++;
            }

            return sb.ToString();
        }

        // --- scanning helpers ---

        /// <summary>Length of the line-comment opener at <paramref name="i"/> (0 if none).</summary>
        private static int LineCommentLen(LangSpec lang, string s, int i, int n)
        {
            if (lang.SlashComments && s[i] == '/' && i + 1 < n && s[i + 1] == '/') return 2;
            if (lang.HashComments && s[i] == '#') return 1;
            if (lang.DashComments && s[i] == '-' && i + 1 < n && s[i + 1] == '-') return 2;
            return 0;
        }

        /// <summary>Index just past a string/char literal starting at the opening quote <paramref name="start"/>.</summary>
        private static int ScanString(string s, int start, int n)
        {
            char quote = s[start];
            int i = start + 1;
            while (i < n)
            {
                char c = s[i];
                if (c == '\\' && i + 1 < n) { i += 2; continue; } // escaped char
                if (c == '\n') return i;                          // unterminated — stop at newline
                if (c == quote) return i + 1;
                i++;
            }
            return n;
        }

        private static bool IsDigit(char c) => c >= '0' && c <= '9';
        private static bool IsIdentStart(char c) => char.IsLetter(c) || c == '_';
        private static bool IsIdentPart(char c) => char.IsLetterOrDigit(c) || c == '_';

        /// <summary>A "type-ish" word is a Capitalized identifier (e.g. a class or type name).</summary>
        private static bool IsTypeish(string w) => w.Length > 1 && char.IsUpper(w[0]) && HasLower(w);
        private static bool HasLower(string w)
        {
            for (int i = 0; i < w.Length; i++) if (char.IsLower(w[i])) return true;
            return false;
        }

        // --- output helpers (all literal text goes through angle-bracket escaping) ---

        private static void AppendSpan(StringBuilder sb, string color, string text)
        {
            sb.Append("<color=").Append(color).Append('>');
            AppendEscaped(sb, text);
            sb.Append("</color>");
        }

        private static void AppendSpan(StringBuilder sb, string color, string src, int start, int end)
        {
            sb.Append("<color=").Append(color).Append('>');
            for (int i = start; i < end; i++) AppendEscapedChar(sb, src[i]);
            sb.Append("</color>");
        }

        private static void AppendEscaped(StringBuilder sb, string text)
        {
            for (int i = 0; i < text.Length; i++) AppendEscapedChar(sb, text[i]);
        }

        private static void AppendEscapedChar(StringBuilder sb, char c)
        {
            if (c == '<') sb.Append('‹');       // ‹
            else if (c == '>') sb.Append('›');  // ›
            else sb.Append(c);
        }

        /// <summary>Minimal pass for oversized input: only neutralise angle brackets, no tokenisation.</summary>
        private static string EscapeAngles(string code)
        {
            var sb = new StringBuilder(code.Length);
            for (int i = 0; i < code.Length; i++) AppendEscapedChar(sb, code[i]);
            return sb.ToString();
        }

        // --- language table ---

        private sealed class LangSpec
        {
            public HashSet<string> Keywords;
            public bool SlashComments; // //
            public bool HashComments;  // #
            public bool DashComments;  // --
            public bool BlockComments; // /* */
            public bool BackTickStrings; // `…` (JS/TS template, Go raw)
        }

        private static LangSpec Resolve(string language)
        {
            switch (Normalize(language))
            {
                case "java":   return Java;
                case "ts":     return TypeScript;
                case "js":     return TypeScript;
                case "python": return Python;
                case "go":     return Go;
                case "rust":   return Rust;
                case "elixir": return Elixir;
                default:       return CSharp; // includes "cs"/"c#" and any unknown language
            }
        }

        /// <summary>Map a language name or file extension to a canonical key.</summary>
        private static string Normalize(string language)
        {
            if (string.IsNullOrWhiteSpace(language)) return "cs";
            string s = language.Trim().ToLowerInvariant().TrimStart('.');
            switch (s)
            {
                case "c#": case "csharp": case "cs": return "cs";
                case "java": return "java";
                case "typescript": case "ts": case "tsx": return "ts";
                case "javascript": case "js": case "jsx": case "mjs": return "js";
                case "python": case "py": return "python";
                case "go": case "golang": return "go";
                case "rust": case "rs": return "rust";
                case "elixir": case "ex": case "exs": return "elixir";
                default: return s;
            }
        }

        private static HashSet<string> Set(params string[] words) => new HashSet<string>(words);

        private static readonly LangSpec CSharp = new LangSpec
        {
            SlashComments = true, BlockComments = true,
            Keywords = Set(
                "abstract", "as", "base", "bool", "break", "byte", "case", "catch", "char", "checked", "class",
                "const", "continue", "decimal", "default", "delegate", "do", "double", "else", "enum", "event",
                "explicit", "extern", "false", "finally", "fixed", "float", "for", "foreach", "goto", "if", "implicit",
                "in", "int", "interface", "internal", "is", "lock", "long", "namespace", "new", "null", "object",
                "operator", "out", "override", "params", "private", "protected", "public", "readonly", "ref", "return",
                "sbyte", "sealed", "short", "sizeof", "stackalloc", "static", "string", "struct", "switch", "this",
                "throw", "true", "try", "typeof", "uint", "ulong", "unchecked", "unsafe", "ushort", "using", "var",
                "virtual", "void", "volatile", "while", "async", "await", "record", "nameof", "when", "yield", "get",
                "set", "value", "partial")
        };

        private static readonly LangSpec Java = new LangSpec
        {
            SlashComments = true, BlockComments = true,
            Keywords = Set(
                "abstract", "assert", "boolean", "break", "byte", "case", "catch", "char", "class", "const",
                "continue", "default", "do", "double", "else", "enum", "extends", "final", "finally", "float", "for",
                "goto", "if", "implements", "import", "instanceof", "int", "interface", "long", "native", "new",
                "package", "private", "protected", "public", "return", "short", "static", "strictfp", "super",
                "switch", "synchronized", "this", "throw", "throws", "transient", "try", "void", "volatile", "while",
                "true", "false", "null", "var", "record", "sealed", "yield")
        };

        private static readonly LangSpec TypeScript = new LangSpec
        {
            SlashComments = true, BlockComments = true, BackTickStrings = true,
            Keywords = Set(
                "abstract", "any", "as", "asserts", "async", "await", "boolean", "break", "case", "catch", "class",
                "const", "continue", "debugger", "declare", "default", "delete", "do", "else", "enum", "export",
                "extends", "false", "finally", "for", "from", "function", "get", "if", "implements", "import", "in",
                "infer", "instanceof", "interface", "is", "keyof", "let", "namespace", "never", "new", "null",
                "number", "object", "of", "private", "protected", "public", "readonly", "return", "set", "static",
                "string", "super", "switch", "this", "throw", "true", "try", "type", "typeof", "undefined", "unknown",
                "var", "void", "while", "yield")
        };

        private static readonly LangSpec Python = new LangSpec
        {
            HashComments = true,
            Keywords = Set(
                "and", "as", "assert", "async", "await", "break", "class", "continue", "def", "del", "elif", "else",
                "except", "finally", "for", "from", "global", "if", "import", "in", "is", "lambda", "nonlocal", "not",
                "or", "pass", "raise", "return", "try", "while", "with", "yield", "True", "False", "None", "self",
                "match", "case")
        };

        private static readonly LangSpec Go = new LangSpec
        {
            SlashComments = true, BlockComments = true, BackTickStrings = true,
            Keywords = Set(
                "break", "case", "chan", "const", "continue", "default", "defer", "else", "fallthrough", "for",
                "func", "go", "goto", "if", "import", "interface", "map", "package", "range", "return", "select",
                "struct", "switch", "type", "var", "nil", "true", "false", "string", "int", "int8", "int16", "int32",
                "int64", "uint", "uint8", "uint16", "uint32", "uint64", "byte", "rune", "float32", "float64", "bool",
                "error")
        };

        private static readonly LangSpec Rust = new LangSpec
        {
            SlashComments = true, BlockComments = true,
            Keywords = Set(
                "as", "async", "await", "break", "const", "continue", "crate", "dyn", "else", "enum", "extern",
                "false", "fn", "for", "if", "impl", "in", "let", "loop", "match", "mod", "move", "mut", "pub", "ref",
                "return", "self", "Self", "static", "struct", "super", "trait", "true", "type", "unsafe", "use",
                "where", "while", "i8", "i16", "i32", "i64", "u8", "u16", "u32", "u64", "usize", "isize", "f32",
                "f64", "bool", "char", "str")
        };

        private static readonly LangSpec Elixir = new LangSpec
        {
            HashComments = true,
            Keywords = Set(
                "def", "defp", "defmodule", "defstruct", "defprotocol", "defimpl", "defmacro", "defmacrop",
                "defdelegate", "defguard", "defexception", "do", "end", "else", "if", "unless", "case", "cond",
                "for", "with", "when", "fn", "in", "and", "or", "not", "true", "false", "nil", "import", "alias",
                "require", "use", "receive", "after", "rescue", "catch", "raise", "try", "quote", "unquote")
        };
    }
}
