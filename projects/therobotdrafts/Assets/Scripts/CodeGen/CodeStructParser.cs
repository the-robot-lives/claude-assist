using System;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.CodeGen
{
    /// <summary>
    /// A deterministic, network-free structural parser that recovers the same <see cref="CodeParser.ParsedModel"/>
    /// shape the LLM path produces — used as the first-choice import strategy so code → model round-trips work
    /// offline (and instantly). C# is handled well via brace-matching + a doc-comment scanner; TypeScript and Java
    /// get a lighter regex pass. Anything else returns <c>false</c> so the caller can fall back to <see cref="CodeParser"/>'s
    /// LLM prompt. The parser is deliberately tolerant: it skips what it can't understand rather than throwing, and
    /// top-level type extraction is enough (nested types are best-effort, partial classes import as separate boxes).
    /// </summary>
    public static class CodeStructParser
    {
        /// <summary>
        /// Try to extract the types in <paramref name="source"/> without any LLM call. Chooses a language strategy from
        /// <paramref name="languageHint"/> (a language name or a file extension). Returns <c>true</c> with a populated
        /// <paramref name="model"/> when at least one type was found; otherwise <c>false</c> with <c>model = null</c>
        /// (unsupported language, empty source, or nothing recognizable — let the caller fall back to the LLM).
        /// </summary>
        public static bool TryParse(string source, string languageHint, out CodeParser.ParsedModel model)
        {
            model = null;
            if (string.IsNullOrWhiteSpace(source)) return false;

            string lang = NormalizeLanguage(languageHint, source);
            List<CodeParser.ParsedType> types;
            switch (lang)
            {
                case "C#":
                    types = ParseCSharp(source);
                    break;
                case "TypeScript":
                    types = ParseCurlyBraceRegex(source, "TypeScript");
                    break;
                case "Java":
                    types = ParseCurlyBraceRegex(source, "Java");
                    break;
                default:
                    return false; // unsupported — caller falls back to the LLM
            }

            if (types == null || types.Count == 0) return false;
            model = new CodeParser.ParsedModel { types = types.ToArray() };
            return true;
        }

        /// <summary>
        /// Map a language hint or extension onto a canonical language label. An explicit hint wins; otherwise we sniff
        /// a leading extension-like token. Returns "" when nothing matches (caller treats that as "fall back to LLM").
        /// </summary>
        private static string NormalizeLanguage(string hint, string source)
        {
            string h = (hint ?? "").Trim().TrimStart('.').ToLowerInvariant();
            switch (h)
            {
                case "cs":
                case "c#":
                case "csharp": return "C#";
                case "ts":
                case "tsx":
                case "typescript": return "TypeScript";
                case "java": return "Java";
            }
            // No usable hint — the only language we can reliably auto-detect for the deterministic path is C#
            // (its using/namespace/`: base` grammar is distinctive). Other languages need an explicit hint.
            if (string.IsNullOrEmpty(h) && LooksLikeCSharp(source)) return "C#";
            return "";
        }

        /// <summary>Cheap heuristic: does this source read like C#? Used only when no language hint was supplied.</summary>
        private static bool LooksLikeCSharp(string source)
        {
            return Regex.IsMatch(source, @"\busing\s+[A-Za-z_][\w.]*\s*;")
                || Regex.IsMatch(source, @"\bnamespace\s+[A-Za-z_]")
                || source.Contains("MonoBehaviour")
                || Regex.IsMatch(source, @"\b(public|internal|private|protected)\s+(sealed\s+|abstract\s+|static\s+|partial\s+)*(class|interface|enum|struct)\b");
        }

        // ===================================================================================================
        //  C# parser (the well-supported path)
        // ===================================================================================================

        // Modifiers that may precede a type/member keyword. Order-independent; matched as a run.
        private const string ModifierPattern =
            @"(?:public|internal|private|protected|abstract|sealed|static|partial|readonly|const|virtual|override|new|extern|unsafe|volatile|async|ref|required|file)\b\s*";

        // A type declaration: optional modifiers, the type keyword, the name, optional generics, optional base list.
        private static readonly Regex TypeDeclRegex = new Regex(
            @"(?<mods>(?:" + ModifierPattern + @")*)(?<keyword>class|interface|enum|struct|record)\b" +
            @"(?:\s+(?:class|struct))?" +              // `record class` / `record struct`
            @"\s+(?<name>[A-Za-z_]\w*)" +
            @"\s*(?<generics><[^=;{]*?>)?" +           // generic params (non-greedy, stops before { ; =)
            @"\s*(?:\((?<primary>[^)]*)\))?" +         // record/primary-constructor params (ignored structurally)
            @"\s*(?::\s*(?<bases>[^{;]+?))?" +         // base list up to the body/`where`
            @"\s*(?:where\b[^{;]*)?" +                 // generic constraints — skip
            @"\s*(?=[{;])",                            // followed by a body or a forward-declared `;`
            RegexOptions.Compiled | RegexOptions.Singleline);

        /// <summary>
        /// Parse C# by scanning the comment-stripped source for type declarations, then brace-matching each type's
        /// body in the ORIGINAL text (so member doc-comments survive). Top-level types are captured; nested types are
        /// reached recursively from a body, best-effort.
        /// </summary>
        private static List<CodeParser.ParsedType> ParseCSharp(string original)
        {
            var types = new List<CodeParser.ParsedType>();
            // A comment-blanked copy keeps offsets identical to the original (comments replaced by spaces/newlines),
            // so a regex match at index i in the blanked text maps to the same i in the original.
            string scan = BlankComments(original);
            ParseCSharpScope(original, scan, 0, original.Length, types);
            return types;
        }

        /// <summary>
        /// Find every top-level type declaration whose body falls within [<paramref name="start"/>, <paramref name="end"/>)
        /// of the blanked <paramref name="scan"/> text, materialize it from the original, and recurse into its body for
        /// nested types. Declarations found inside an already-consumed body are skipped (handled by the recursion).
        /// </summary>
        private static void ParseCSharpScope(string original, string scan, int start, int end,
            List<CodeParser.ParsedType> outTypes)
        {
            int cursor = start;
            foreach (Match m in TypeDeclRegex.Matches(scan))
            {
                if (m.Index < cursor) continue;        // inside a body we've already consumed
                if (m.Index >= end) break;

                int afterDecl = m.Index + m.Length;
                // Locate the body: the next '{' in the blanked text (or a ';' for a forward declaration).
                int brace = scan.IndexOf('{', afterDecl);
                int semi = scan.IndexOf(';', afterDecl);
                if (semi >= 0 && (brace < 0 || semi < brace))
                {
                    // forward declaration / no body — record the type with no members.
                    outTypes.Add(BuildType(original, scan, m, -1, -1));
                    cursor = semi + 1;
                    continue;
                }
                if (brace < 0 || brace >= end) break;

                int bodyEnd = MatchBrace(scan, brace);
                if (bodyEnd < 0) bodyEnd = end;        // unbalanced — take the rest of the scope

                var pt = BuildType(original, scan, m, brace + 1, bodyEnd);
                outTypes.Add(pt);

                // Recurse for nested types (best-effort): they share the same out list as separate boxes.
                ParseCSharpScope(original, scan, brace + 1, bodyEnd, outTypes);

                cursor = bodyEnd + 1;
            }
        }

        /// <summary>
        /// Build one <see cref="CodeParser.ParsedType"/> from a matched declaration and (when present) its body span
        /// [<paramref name="bodyStart"/>, <paramref name="bodyEnd"/>) in the comment-blanked <paramref name="scan"/>.
        /// Members are walked from the body; the preceding doc-comment is pulled from the original text.
        /// </summary>
        private static CodeParser.ParsedType BuildType(string original, string scan, Match decl,
            int bodyStart, int bodyEnd)
        {
            string keyword = decl.Groups["keyword"].Value;
            string name = decl.Groups["name"].Value;
            bool isInterface = keyword == "interface";
            bool isEnum = keyword == "enum";
            bool isStruct = keyword == "struct";
            // `record` is a reference type → treat as Class; `record struct` already matched the struct keyword above.

            string comment = DocCommentBefore(original, decl.Index);
            DeepLinkIdentity.TryExtract(ref comment, out var deepUuid, out var deepCode);

            var pt = new CodeParser.ParsedType
            {
                name = name,
                kind = isInterface ? "Interface" : isEnum ? "Enum" : isStruct ? "Struct" : "Class",
                language = "C#",
                comment = comment,
                deepLinkUuid = deepUuid ?? "",
                deepLinkCode = deepCode ?? "",
                fields = Array.Empty<string>(),
                fieldComments = Array.Empty<string>(),
                fieldDeepLinkUuids = Array.Empty<string>(),
                fieldDeepLinkCodes = Array.Empty<string>(),
                methods = Array.Empty<string>(),
                methodComments = Array.Empty<string>(),
                methodDeepLinkUuids = Array.Empty<string>(),
                methodDeepLinkCodes = Array.Empty<string>(),
                extends = Array.Empty<string>(),
                implements = Array.Empty<string>(),
                uses = Array.Empty<string>(),
            };

            // Base list: class → first entry to extends, rest implements (heuristic; interfaces start uppercase 'I'…
            // but we don't rely on naming). For interface/struct, all bases → implements.
            var bases = SplitBases(decl.Groups["bases"].Value);
            if (bases.Count > 0)
            {
                if (!isInterface && !isStruct && !isEnum)
                {
                    // Class: conventionally the (optional) base class is first. We can't always tell a base class from
                    // an interface, so put the first into extends and the remainder into implements — approximate by design.
                    pt.extends = new[] { bases[0] };
                    if (bases.Count > 1) pt.implements = bases.GetRange(1, bases.Count - 1).ToArray();
                }
                else
                {
                    pt.implements = bases.ToArray();
                }
            }

            if (bodyStart < 0 || bodyEnd <= bodyStart) return pt; // forward decl / empty

            if (isEnum)
                ParseEnumMembers(original, bodyStart, bodyEnd, pt);
            else
                ParseTypeMembers(original, scan, bodyStart, bodyEnd, pt);

            return pt;
        }

        /// <summary>Split a comma-separated base list into bare type names, stripping generics and namespaces.</summary>
        private static List<string> SplitBases(string baseList)
        {
            var result = new List<string>();
            if (string.IsNullOrWhiteSpace(baseList)) return result;

            // Split on commas that are not inside generic angle brackets.
            int depth = 0, last = 0;
            for (int i = 0; i < baseList.Length; i++)
            {
                char c = baseList[i];
                if (c == '<') depth++;
                else if (c == '>') { if (depth > 0) depth--; }
                else if (c == ',' && depth == 0)
                {
                    AddBase(result, baseList.Substring(last, i - last));
                    last = i + 1;
                }
            }
            AddBase(result, baseList.Substring(last));
            return result;
        }

        private static void AddBase(List<string> list, string raw)
        {
            string name = CleanTypeName(raw);
            if (!string.IsNullOrEmpty(name)) list.Add(name);
        }

        /// <summary>Reduce a type expression to a bare, readable name: drop namespace qualifier, keep generic suffix.</summary>
        private static string CleanTypeName(string raw)
        {
            if (string.IsNullOrWhiteSpace(raw)) return "";
            string s = raw.Trim();
            // Keep generics on the simple name: strip a leading namespace from the base name only.
            int angle = s.IndexOf('<');
            string head = angle >= 0 ? s.Substring(0, angle) : s;
            string tail = angle >= 0 ? s.Substring(angle) : "";
            int dot = head.LastIndexOf('.');
            if (dot >= 0) head = head.Substring(dot + 1);
            return (head + tail).Trim();
        }

        /// <summary>Enum body: each comma-separated member name becomes a "+ Member" field signature with its doc-comment.</summary>
        private static void ParseEnumMembers(string original, int bodyStart, int bodyEnd, CodeParser.ParsedType pt)
        {
            var fields = new List<string>();
            var comments = new List<string>();
            var uuids = new List<string>();
            var codes = new List<string>();

            int i = bodyStart;
            while (i < bodyEnd)
            {
                // Skip whitespace/commas to the next member token, capturing any doc-comment we pass.
                while (i < bodyEnd && (char.IsWhiteSpace(original[i]) || original[i] == ',')) i++;
                if (i >= bodyEnd) break;

                // An attribute like [Flags] on a member — skip the bracketed run.
                if (original[i] == '[') { i = SkipBalanced(original, i, '[', ']', bodyEnd); continue; }

                int memberStart = i;
                // A member runs until ',' or '=' (explicit value) or end of body.
                while (i < bodyEnd && original[i] != ',' && original[i] != '=' && original[i] != '}') i++;
                string token = original.Substring(memberStart, i - memberStart).Trim();
                if (i < bodyEnd && original[i] == '=')
                {
                    // skip the assigned value up to the next comma
                    while (i < bodyEnd && original[i] != ',' && original[i] != '}') i++;
                }
                var nameMatch = Regex.Match(token, @"[A-Za-z_]\w*");
                if (nameMatch.Success)
                {
                    string comment = DocCommentBefore(original, memberStart);
                    DeepLinkIdentity.TryExtract(ref comment, out var uuid, out var code);
                    fields.Add("+ " + nameMatch.Value);
                    comments.Add(comment);
                    uuids.Add(uuid ?? "");
                    codes.Add(code ?? "");
                }
            }

            pt.fields = fields.ToArray();
            pt.fieldComments = comments.ToArray();
            pt.fieldDeepLinkUuids = uuids.ToArray();
            pt.fieldDeepLinkCodes = codes.ToArray();
        }

        /// <summary>
        /// Walk a class/interface/struct body, splitting it into top-level member declarations by brace/paren/semicolon,
        /// and classify each as a method (has a parameter list) or a field/property. Captures each member's preceding
        /// doc-comment into the parallel comment arrays. Nested types are skipped here (handled by the scope recursion).
        /// </summary>
        private static void ParseTypeMembers(string original, string scan, int bodyStart, int bodyEnd,
            CodeParser.ParsedType pt)
        {
            var fields = new List<string>();
            var fieldComments = new List<string>();
            var fieldUuids = new List<string>();
            var fieldCodes = new List<string>();
            var methods = new List<string>();
            var methodComments = new List<string>();
            var methodUuids = new List<string>();
            var methodCodes = new List<string>();

            int i = bodyStart;
            int memberStart = SkipLeading(scan, bodyStart, bodyEnd);
            while (i < bodyEnd)
            {
                char c = scan[i];
                if (c == '{')
                {
                    // A block: a method/property body or a nested type's body. Either way, the member ends after it.
                    int close = MatchBrace(scan, i);
                    if (close < 0 || close >= bodyEnd) close = bodyEnd - 1;
                    string decl = original.Substring(memberStart, i - memberStart);
                    ClassifyMember(original, scan, decl, memberStart, true,
                        fields, fieldComments, fieldUuids, fieldCodes, methods, methodComments, methodUuids, methodCodes);
                    i = close + 1;
                    // skip a trailing ; after a property/auto block
                    while (i < bodyEnd && (char.IsWhiteSpace(scan[i]) || scan[i] == ';')) i++;
                    memberStart = i;
                    continue;
                }
                if (c == ';')
                {
                    string decl = original.Substring(memberStart, i - memberStart);
                    ClassifyMember(original, scan, decl, memberStart, false,
                        fields, fieldComments, fieldUuids, fieldCodes, methods, methodComments, methodUuids, methodCodes);
                    i++;
                    memberStart = SkipLeading(scan, i, bodyEnd);
                    i = memberStart;
                    continue;
                }
                if (c == '(')
                {
                    // A parameter list: this member is a method/ctor. Consume to the matching ')', then to its body or ';'.
                    int closeParen = SkipBalanced(scan, i, '(', ')', bodyEnd);
                    // Find whether a body or a ';' follows (interface methods + expression-bodied/abstract use ';').
                    int j = closeParen;
                    // skip return-type-less arrow body `=> expr;` or `{ }`
                    int nextBrace = scan.IndexOf('{', j);
                    int nextSemi = scan.IndexOf(';', j);
                    int memberEnd;
                    bool hadBlock = false;
                    if (nextBrace >= bodyStart && nextBrace < bodyEnd && (nextSemi < 0 || nextBrace < nextSemi))
                    {
                        int close = MatchBrace(scan, nextBrace);
                        memberEnd = (close < 0 || close >= bodyEnd) ? bodyEnd - 1 : close;
                        hadBlock = true;
                    }
                    else if (nextSemi >= 0 && nextSemi < bodyEnd)
                    {
                        memberEnd = nextSemi;
                    }
                    else
                    {
                        memberEnd = bodyEnd - 1;
                    }
                    string decl = original.Substring(memberStart, memberEnd - memberStart + (hadBlock ? 0 : 0));
                    // For methods we want the signature only (up to and including the param list).
                    string sigSource = original.Substring(memberStart, closeParen - memberStart);
                    ClassifyMethod(original, sigSource, memberStart, methods, methodComments, methodUuids, methodCodes);
                    i = memberEnd + 1;
                    while (i < bodyEnd && (char.IsWhiteSpace(scan[i]) || scan[i] == ';')) i++;
                    memberStart = i;
                    continue;
                }
                i++;
            }

            pt.fields = fields.ToArray();
            pt.fieldComments = fieldComments.ToArray();
            pt.fieldDeepLinkUuids = fieldUuids.ToArray();
            pt.fieldDeepLinkCodes = fieldCodes.ToArray();
            pt.methods = methods.ToArray();
            pt.methodComments = methodComments.ToArray();
            pt.methodDeepLinkUuids = methodUuids.ToArray();
            pt.methodDeepLinkCodes = methodCodes.ToArray();
        }

        /// <summary>
        /// Classify a non-method member declaration (field, auto-property, or const) into a "± name : Type" signature.
        /// <paramref name="hadBlock"/> marks a property with an accessor block. Nested type declarations are ignored.
        /// </summary>
        private static void ClassifyMember(string original, string scan, string decl, int memberStart, bool hadBlock,
            List<string> fields, List<string> fieldComments,
            List<string> fieldUuids, List<string> fieldCodes,
            List<string> methods, List<string> methodComments,
            List<string> methodUuids, List<string> methodCodes)
        {
            string trimmed = StripAttributes(decl).Trim();
            if (trimmed.Length == 0) return;

            // Skip nested type declarations — the scope recursion handles those as their own boxes.
            if (Regex.IsMatch(trimmed, @"\b(class|interface|enum|struct|record)\b\s+[A-Za-z_]\w*"))
                return;
            // Skip property accessor noise that can leak through (get/set/init keywords on their own).
            if (Regex.IsMatch(trimmed, @"^\s*(get|set|init|add|remove)\b")) return;

            string vis = VisibilityPrefix(trimmed);
            string body = StripModifiers(trimmed);
            if (body.Length == 0) return;

            // Drop an initializer (= …) when present.
            int eq = IndexOfTopLevel(body, '=');
            if (eq >= 0) body = body.Substring(0, eq).Trim();

            // Expect "Type name" (optionally "Type name1, name2" for multi-field declarations).
            string sig = FieldSignature(vis, body);
            if (sig == null) return;
            string comment = DocCommentBefore(original, memberStart);
            DeepLinkIdentity.TryExtract(ref comment, out var uuid, out var code);
            fields.Add(sig);
            fieldComments.Add(comment);
            fieldUuids.Add(uuid ?? "");
            fieldCodes.Add(code ?? "");
        }

        /// <summary>Turn a "Type name" (or "name : Type") fragment into a UML "± name : Type" attribute signature.</summary>
        private static string FieldSignature(string vis, string body)
        {
            // Already UML-ish ("name : Type")? keep the name + type.
            var uml = Regex.Match(body, @"^([A-Za-z_]\w*)\s*:\s*(.+)$");
            if (uml.Success)
                return vis + " " + uml.Groups[1].Value + " : " + CleanTypeName(uml.Groups[2].Value);

            // C# "Type name" — type may be generic / array / nullable; the name is the last identifier token.
            var m = Regex.Match(body, @"^(?<type>.+?)\s+(?<name>[A-Za-z_]\w*)$", RegexOptions.Singleline);
            if (!m.Success)
            {
                // A bare identifier (e.g. enum-ish leak) — emit as a typeless attribute.
                var bare = Regex.Match(body, @"^[A-Za-z_]\w*$");
                return bare.Success ? vis + " " + body : null;
            }
            string type = CleanTypeName(m.Groups["type"].Value);
            string name = m.Groups["name"].Value;
            // Reject keywords masquerading as names (e.g. "return").
            if (IsKeyword(name)) return null;
            return vis + " " + name + " : " + type;
        }

        /// <summary>Classify a member with a parameter list into a UML "± name(params) : ReturnType" operation signature.</summary>
        private static void ClassifyMethod(string original, string sigSource, int memberStart,
            List<string> methods, List<string> methodComments,
            List<string> methodUuids, List<string> methodCodes)
        {
            string s = StripAttributes(sigSource).Trim();
            if (s.Length == 0) return;

            int paren = s.IndexOf('(');
            if (paren < 0) return;
            string head = s.Substring(0, paren).Trim();   // modifiers + return type + name (+ generics)
            string paramList = s.Substring(paren + 1).Trim().TrimEnd(')');

            string vis = VisibilityPrefix(head);
            head = StripModifiers(head);

            // head is now "ReturnType Name" or just "Name" (constructor / operator). Name = last identifier (pre-generics).
            // Strip generic params on the method name.
            head = Regex.Replace(head, @"<[^>]*>", "").Trim();
            var hm = Regex.Match(head, @"^(?:(?<ret>.+?)\s+)?(?<name>[A-Za-z_]\w*)$", RegexOptions.Singleline);
            if (!hm.Success) return;
            string name = hm.Groups["name"].Value;
            if (IsKeyword(name)) return;
            string ret = hm.Groups["ret"].Success ? CleanTypeName(hm.Groups["ret"].Value) : "";

            string umlParams = SummarizeParams(paramList);
            string sig = vis + " " + name + "(" + umlParams + ")";
            if (!string.IsNullOrEmpty(ret)) sig += " : " + ret;

            string comment = DocCommentBefore(original, memberStart);
            DeepLinkIdentity.TryExtract(ref comment, out var uuid, out var code);
            methods.Add(sig);
            methodComments.Add(comment);
            methodUuids.Add(uuid ?? "");
            methodCodes.Add(code ?? "");
        }

        /// <summary>Render a C# parameter list as UML "name : Type, …", dropping default values, modifiers, and attributes.</summary>
        private static string SummarizeParams(string paramList)
        {
            if (string.IsNullOrWhiteSpace(paramList)) return "";
            var outParams = new List<string>();
            foreach (var raw in SplitTopLevel(paramList, ','))
            {
                string p = StripAttributes(raw).Trim();
                if (p.Length == 0) continue;
                // Drop a default value.
                int eq = IndexOfTopLevel(p, '=');
                if (eq >= 0) p = p.Substring(0, eq).Trim();
                // Drop parameter modifiers.
                p = Regex.Replace(p, @"^\s*(?:this\s+|ref\s+|out\s+|in\s+|params\s+|readonly\s+|scoped\s+)+", "");
                var m = Regex.Match(p, @"^(?<type>.+?)\s+(?<name>[A-Za-z_]\w*)$", RegexOptions.Singleline);
                if (m.Success)
                    outParams.Add(m.Groups["name"].Value + " : " + CleanTypeName(m.Groups["type"].Value));
                else
                    outParams.Add(CleanTypeName(p)); // couldn't split — keep the type alone
            }
            return string.Join(", ", outParams);
        }

        // ---- C# lexical helpers ----

        private static readonly Regex VisRegex =
            new Regex(@"\b(public|private|protected|internal)\b", RegexOptions.Compiled);

        /// <summary>Map the leading visibility keyword(s) to a UML prefix. Default is "-" (C# member default is private).</summary>
        private static string VisibilityPrefix(string decl)
        {
            var m = VisRegex.Match(decl);
            if (!m.Success) return "-";
            // protected internal / private protected → use the broader/most-visible mark; keep it simple:
            switch (m.Value)
            {
                case "public": return "+";
                case "protected": return "#";
                case "internal": return "~";
                default: return "-";
            }
        }

        private static readonly Regex ModifiersLeadRegex = new Regex(
            @"^\s*(?:" + ModifierPattern + @")*", RegexOptions.Compiled);

        /// <summary>Strip leading C# modifiers (and any attribute runs) from a declaration fragment.</summary>
        private static string StripModifiers(string decl)
        {
            return ModifiersLeadRegex.Replace(StripAttributes(decl), "").Trim();
        }

        /// <summary>Remove leading [Attribute]… runs from a declaration fragment.</summary>
        private static string StripAttributes(string decl)
        {
            if (string.IsNullOrEmpty(decl)) return decl ?? "";
            string s = decl;
            // Repeatedly strip a leading [..] (balanced) run, with whitespace around it.
            while (true)
            {
                string t = s.TrimStart();
                if (t.Length == 0 || t[0] != '[') break;
                int close = SkipBalanced(t, 0, '[', ']', t.Length);
                if (close <= 0 || close >= t.Length) { s = ""; break; }
                s = t.Substring(close);
            }
            return s.Trim();
        }

        private static readonly HashSet<string> Keywords = new HashSet<string>(StringComparer.Ordinal)
        {
            "return", "if", "else", "for", "foreach", "while", "do", "switch", "case", "break", "continue",
            "throw", "try", "catch", "finally", "using", "lock", "yield", "get", "set", "init", "add", "remove",
            "namespace", "var", "new", "base", "this", "true", "false", "null",
        };

        private static bool IsKeyword(string name) => Keywords.Contains(name);

        // ===================================================================================================
        //  TypeScript / Java (light regex pass — bonus, not the primary path)
        // ===================================================================================================

        /// <summary>
        /// A deliberately light pass for curly-brace languages: find type declarations and capture each one's body, but
        /// extract only a coarse member list (TS supports many member forms; we keep it simple and tolerant). Good enough
        /// to give the user real boxes offline; the LLM remains the high-fidelity path for these.
        /// </summary>
        private static List<CodeParser.ParsedType> ParseCurlyBraceRegex(string original, string language)
        {
            var types = new List<CodeParser.ParsedType>();
            string scan = BlankComments(original);

            var declRe = new Regex(
                @"\b(?<keyword>class|interface|enum)\b\s+(?<name>[A-Za-z_]\w*)" +
                @"(?:\s*<[^>{]*>)?" +
                @"(?<bases>(?:\s+(?:extends|implements)\s+[^\{]+?)?)" +
                @"\s*\{",
                RegexOptions.Singleline);

            foreach (Match m in declRe.Matches(scan))
            {
                int brace = scan.IndexOf('{', m.Index + m.Length - 1);
                if (brace < 0) continue;
                int bodyEnd = MatchBrace(scan, brace);
                if (bodyEnd < 0) continue;

                string keyword = m.Groups["keyword"].Value;
                string comment = DocCommentBefore(original, m.Index);
                DeepLinkIdentity.TryExtract(ref comment, out var deepUuid, out var deepCode);

                var pt = new CodeParser.ParsedType
                {
                    name = m.Groups["name"].Value,
                    kind = keyword == "interface" ? "Interface" : keyword == "enum" ? "Enum" : "Class",
                    language = language,
                    comment = comment,
                    deepLinkUuid = deepUuid ?? "",
                    deepLinkCode = deepCode ?? "",
                    fields = Array.Empty<string>(),
                    fieldComments = Array.Empty<string>(),
                    fieldDeepLinkUuids = Array.Empty<string>(),
                    fieldDeepLinkCodes = Array.Empty<string>(),
                    methods = Array.Empty<string>(),
                    methodComments = Array.Empty<string>(),
                    methodDeepLinkUuids = Array.Empty<string>(),
                    methodDeepLinkCodes = Array.Empty<string>(),
                    extends = Array.Empty<string>(),
                    implements = Array.Empty<string>(),
                    uses = Array.Empty<string>(),
                };

                ParseCurlyBases(m.Groups["bases"].Value, pt);
                if (keyword == "enum")
                    ParseEnumMembers(original, brace + 1, bodyEnd, pt);
                else
                    ParseCurlyMembers(original, scan, brace + 1, bodyEnd, pt);

                types.Add(pt);
            }
            return types;
        }

        /// <summary>Parse `extends A` / `implements B, C` clauses for TS/Java into the parsed type's edges.</summary>
        private static void ParseCurlyBases(string clause, CodeParser.ParsedType pt)
        {
            if (string.IsNullOrWhiteSpace(clause)) return;
            var ext = Regex.Match(clause, @"extends\s+(?<list>[^{]+?)(?=\s+implements\b|$)", RegexOptions.Singleline);
            if (ext.Success) pt.extends = SplitBases(ext.Groups["list"].Value).ToArray();
            var impl = Regex.Match(clause, @"implements\s+(?<list>[^{]+)$", RegexOptions.Singleline);
            if (impl.Success) pt.implements = SplitBases(impl.Groups["list"].Value).ToArray();
        }

        /// <summary>Coarse member extraction for TS/Java bodies: methods (have `()`) vs fields, with doc-comments.</summary>
        private static void ParseCurlyMembers(string original, string scan, int bodyStart, int bodyEnd,
            CodeParser.ParsedType pt)
        {
            var fields = new List<string>();
            var fieldComments = new List<string>();
            var fieldUuids = new List<string>();
            var fieldCodes = new List<string>();
            var methods = new List<string>();
            var methodComments = new List<string>();
            var methodUuids = new List<string>();
            var methodCodes = new List<string>();

            int i = bodyStart, memberStart = SkipLeading(scan, bodyStart, bodyEnd);
            while (i < bodyEnd)
            {
                char c = scan[i];
                if (c == '{')
                {
                    int close = MatchBrace(scan, i);
                    if (close < 0 || close >= bodyEnd) close = bodyEnd - 1;
                    EmitCurlyMember(original, original.Substring(memberStart, i - memberStart), memberStart,
                        fields, fieldComments, fieldUuids, fieldCodes, methods, methodComments, methodUuids, methodCodes);
                    i = close + 1;
                    while (i < bodyEnd && (char.IsWhiteSpace(scan[i]) || scan[i] == ';')) i++;
                    memberStart = i;
                    continue;
                }
                if (c == ';')
                {
                    EmitCurlyMember(original, original.Substring(memberStart, i - memberStart), memberStart,
                        fields, fieldComments, fieldUuids, fieldCodes, methods, methodComments, methodUuids, methodCodes);
                    i++;
                    memberStart = SkipLeading(scan, i, bodyEnd);
                    i = memberStart;
                    continue;
                }
                i++;
            }

            pt.fields = fields.ToArray();
            pt.fieldComments = fieldComments.ToArray();
            pt.fieldDeepLinkUuids = fieldUuids.ToArray();
            pt.fieldDeepLinkCodes = fieldCodes.ToArray();
            pt.methods = methods.ToArray();
            pt.methodComments = methodComments.ToArray();
            pt.methodDeepLinkUuids = methodUuids.ToArray();
            pt.methodDeepLinkCodes = methodCodes.ToArray();
        }

        /// <summary>Emit one TS/Java member: methods get "+ name(params) : Ret"; fields get "+ name : Type" (default + visibility).</summary>
        private static void EmitCurlyMember(string original, string decl, int memberStart,
            List<string> fields, List<string> fieldComments,
            List<string> fieldUuids, List<string> fieldCodes,
            List<string> methods, List<string> methodComments,
            List<string> methodUuids, List<string> methodCodes)
        {
            string s = StripAttributes(decl).Trim();
            if (s.Length == 0) return;
            if (Regex.IsMatch(s, @"\b(class|interface|enum)\b\s+[A-Za-z_]\w*")) return; // nested decl
            if (Regex.IsMatch(s, @"^\s*(get|set|public|private|protected)?\s*(get|set)\b")) { /* accessor, fall through */ }

            string vis = CurlyVisibility(s);
            string bodyDecl = Regex.Replace(s, @"^\s*(public|private|protected|static|readonly|abstract|final|async|export|declare)\b\s*", "",
                RegexOptions.IgnoreCase);
            bodyDecl = Regex.Replace(bodyDecl, @"^\s*(public|private|protected|static|readonly|abstract|final|async|export|declare)\b\s*", "",
                RegexOptions.IgnoreCase).Trim();

            int paren = bodyDecl.IndexOf('(');
            if (paren >= 0 && (bodyDecl.IndexOf(':') < 0 || bodyDecl.IndexOf(':') > paren))
            {
                // method
                var nameMatch = Regex.Match(bodyDecl.Substring(0, paren), @"([A-Za-z_]\w*)\s*$");
                if (!nameMatch.Success) return;
                string name = nameMatch.Groups[1].Value;
                if (IsKeyword(name)) return;
                int closeParen = SkipBalanced(bodyDecl, paren, '(', ')', bodyDecl.Length);
                string paramList = bodyDecl.Substring(paren + 1, Math.Max(0, closeParen - paren - 2));
                string ret = "";
                var retMatch = Regex.Match(bodyDecl.Substring(Math.Min(closeParen, bodyDecl.Length)), @":\s*([A-Za-z_][\w.<>\[\]]*)");
                if (retMatch.Success) ret = CleanTypeName(retMatch.Groups[1].Value);
                string sig = vis + " " + name + "(" + SummarizeParams(NormalizeTsParams(paramList)) + ")";
                if (!string.IsNullOrEmpty(ret)) sig += " : " + ret;
                string comment = DocCommentBefore(original, memberStart);
                DeepLinkIdentity.TryExtract(ref comment, out var uuid, out var code);
                methods.Add(sig);
                methodComments.Add(comment);
                methodUuids.Add(uuid ?? "");
                methodCodes.Add(code ?? "");
                return;
            }

            // field: "name : Type" (TS) or "Type name" (Java)
            var ts = Regex.Match(bodyDecl, @"^([A-Za-z_]\w*)\??\s*:\s*([^=;]+)");
            if (ts.Success)
            {
                string comment = DocCommentBefore(original, memberStart);
                DeepLinkIdentity.TryExtract(ref comment, out var uuid, out var code);
                fields.Add(vis + " " + ts.Groups[1].Value + " : " + CleanTypeName(ts.Groups[2].Value));
                fieldComments.Add(comment);
                fieldUuids.Add(uuid ?? "");
                fieldCodes.Add(code ?? "");
                return;
            }
            var java = Regex.Match(bodyDecl, @"^(?<type>[A-Za-z_][\w.<>\[\]]*)\s+(?<name>[A-Za-z_]\w*)");
            if (java.Success && !IsKeyword(java.Groups["name"].Value))
            {
                string comment = DocCommentBefore(original, memberStart);
                DeepLinkIdentity.TryExtract(ref comment, out var uuid, out var code);
                fields.Add(vis + " " + java.Groups["name"].Value + " : " + CleanTypeName(java.Groups["type"].Value));
                fieldComments.Add(comment);
                fieldUuids.Add(uuid ?? "");
                fieldCodes.Add(code ?? "");
            }
        }

        /// <summary>TS optional params (`a?: T`) → drop the `?` so the shared param summarizer can split "name : Type".</summary>
        private static string NormalizeTsParams(string paramList)
        {
            if (string.IsNullOrWhiteSpace(paramList)) return "";
            // Convert "name: Type" to "Type name" so SummarizeParams' C#-shaped regex can read it.
            var outParams = new List<string>();
            foreach (var raw in SplitTopLevel(paramList, ','))
            {
                string p = raw.Trim().Replace("?", "");
                var m = Regex.Match(p, @"^([A-Za-z_]\w*)\s*:\s*(.+)$");
                if (m.Success) outParams.Add(m.Groups[2].Value.Trim() + " " + m.Groups[1].Value);
                else outParams.Add(p);
            }
            return string.Join(", ", outParams);
        }

        private static string CurlyVisibility(string decl)
        {
            if (Regex.IsMatch(decl, @"^\s*private\b")) return "-";
            if (Regex.IsMatch(decl, @"^\s*protected\b")) return "#";
            return "+"; // TS/Java members default to public-ish visibility for a diagram
        }

        // ===================================================================================================
        //  Shared lexical utilities
        // ===================================================================================================

        /// <summary>
        /// Return a copy of <paramref name="src"/> with all comments replaced by spaces (newlines preserved), so a
        /// structural scan never trips on braces/semicolons inside comments or strings while offsets stay aligned with
        /// the original. String and char literals are also blanked (their contents can't be code), '@'/$ strings handled.
        /// </summary>
        private static string BlankComments(string src)
        {
            var sb = new StringBuilder(src.Length);
            int i = 0, n = src.Length;
            while (i < n)
            {
                char c = src[i];

                // line comment
                if (c == '/' && i + 1 < n && src[i + 1] == '/')
                {
                    while (i < n && src[i] != '\n') { sb.Append(src[i] == '\n' ? '\n' : ' '); i++; }
                    continue;
                }
                // block comment
                if (c == '/' && i + 1 < n && src[i + 1] == '*')
                {
                    while (i < n && !(src[i] == '*' && i + 1 < n && src[i + 1] == '/'))
                    { sb.Append(src[i] == '\n' ? '\n' : ' '); i++; }
                    if (i < n) { sb.Append(' '); i++; }      // '*'
                    if (i < n) { sb.Append(' '); i++; }      // '/'
                    continue;
                }
                // verbatim string @"..."
                if (c == '@' && i + 1 < n && src[i + 1] == '"')
                {
                    sb.Append(' '); sb.Append(' '); i += 2;
                    while (i < n)
                    {
                        if (src[i] == '"')
                        {
                            if (i + 1 < n && src[i + 1] == '"') { sb.Append(' '); sb.Append(' '); i += 2; continue; }
                            sb.Append(' '); i++; break;
                        }
                        sb.Append(src[i] == '\n' ? '\n' : ' '); i++;
                    }
                    continue;
                }
                // regular string "..."
                if (c == '"')
                {
                    sb.Append(' '); i++;
                    while (i < n && src[i] != '"')
                    {
                        if (src[i] == '\\' && i + 1 < n) { sb.Append(' '); sb.Append(' '); i += 2; continue; }
                        sb.Append(src[i] == '\n' ? '\n' : ' '); i++;
                    }
                    if (i < n) { sb.Append(' '); i++; }
                    continue;
                }
                // char literal '.'
                if (c == '\'')
                {
                    sb.Append(' '); i++;
                    while (i < n && src[i] != '\'')
                    {
                        if (src[i] == '\\' && i + 1 < n) { sb.Append(' '); sb.Append(' '); i += 2; continue; }
                        sb.Append(' '); i++;
                    }
                    if (i < n) { sb.Append(' '); i++; }
                    continue;
                }

                sb.Append(c);
                i++;
            }
            return sb.ToString();
        }

        /// <summary>
        /// Read the doc-comment immediately preceding <paramref name="declStart"/> in the ORIGINAL text (XML <c>///</c>
        /// run or a <c>/** … */</c> block), with markers stripped, joined to one line. Returns "" when there is none
        /// (e.g. only blank lines or code precede the declaration). Attributes/blank lines between the comment and the
        /// declaration are tolerated.
        /// </summary>
        private static string DocCommentBefore(string original, int declStart)
        {
            // Walk back over whitespace and any attribute lines to find the line before the declaration.
            int i = declStart - 1;
            // Skip back over the current line's leading whitespace.
            while (i >= 0 && original[i] != '\n') i--;
            // Now i is at the newline before the declaration line (or -1).

            var lines = new List<string>();
            int blockCount = 0; // safety cap on how far back we scan
            while (i >= 0 && blockCount++ < 200)
            {
                int lineEnd = i;               // points at '\n'
                int lineStart = i - 1;
                while (lineStart >= 0 && original[lineStart] != '\n') lineStart--;
                string line = original.Substring(lineStart + 1, lineEnd - lineStart - 1).Trim();

                if (line.Length == 0) { i = lineStart; continue; } // tolerate blank lines
                if (line.StartsWith("[") && line.EndsWith("]")) { i = lineStart; continue; } // attribute line

                if (line.StartsWith("///"))
                {
                    lines.Insert(0, StripXmlDoc(line));
                    i = lineStart;
                    continue;
                }
                if (line.EndsWith("*/"))
                {
                    // Gather a /** ... */ block backwards.
                    return ExtractBlockDocBackward(original, lineEnd);
                }
                break; // a code line — no doc-comment
            }

            return JoinDoc(lines);
        }

        /// <summary>Strip a single <c>///</c> XML-doc line down to its readable text (drops the slashes + simple tags).</summary>
        private static string StripXmlDoc(string line)
        {
            string s = line.TrimStart('/').Trim();
            s = Regex.Replace(s, @"</?summary>", "", RegexOptions.IgnoreCase);
            s = Regex.Replace(s, @"<see\s+cref=""[^""]*?([A-Za-z_]\w*)""\s*/?>", "$1", RegexOptions.IgnoreCase);
            s = Regex.Replace(s, @"<[^>]+>", ""); // any other tag
            return s.Trim();
        }

        /// <summary>Extract a <c>/** … */</c> block ending at <paramref name="blockEnd"/> (the '\n' after "*/"), markers stripped.</summary>
        private static string ExtractBlockDocBackward(string original, int blockEnd)
        {
            // Find the matching /** start before blockEnd.
            int end = original.LastIndexOf("*/", Math.Max(0, blockEnd), StringComparison.Ordinal);
            if (end < 0) return "";
            int start = original.LastIndexOf("/*", end, StringComparison.Ordinal);
            if (start < 0) return "";
            // Only treat /** … */ (or /* … */) as documentation if it directly precedes the decl (it does by construction).
            string inner = original.Substring(start + 2, end - start - 2);
            var parts = new List<string>();
            foreach (var rawLine in inner.Split('\n'))
            {
                string l = rawLine.Trim();
                if (l.StartsWith("*")) l = l.Substring(1).Trim();
                if (l.StartsWith("/")) l = l.Substring(1).Trim(); // leading extra '*' became '/' edge
                l = Regex.Replace(l, @"<[^>]+>", "");
                if (l.Length > 0) parts.Add(l);
            }
            return JoinDoc(parts);
        }

        private static string JoinDoc(List<string> lines)
        {
            if (lines == null || lines.Count == 0) return "";
            var nonEmpty = lines.FindAll(l => !string.IsNullOrWhiteSpace(l));
            return string.Join("\n", nonEmpty).Trim();
        }

        /// <summary>Index of the matching '}' for the '{' at <paramref name="open"/> in the blanked text, or -1.</summary>
        private static int MatchBrace(string s, int open)
        {
            int depth = 0;
            for (int i = open; i < s.Length; i++)
            {
                if (s[i] == '{') depth++;
                else if (s[i] == '}') { depth--; if (depth == 0) return i; }
            }
            return -1;
        }

        /// <summary>Index just past the matching close for the bracket at <paramref name="open"/> (one past it), or end.</summary>
        private static int SkipBalanced(string s, int open, char openCh, char closeCh, int end)
        {
            int depth = 0;
            for (int i = open; i < end && i < s.Length; i++)
            {
                if (s[i] == openCh) depth++;
                else if (s[i] == closeCh) { depth--; if (depth == 0) return i + 1; }
            }
            return end;
        }

        /// <summary>Skip leading whitespace from <paramref name="i"/> up to <paramref name="end"/>.</summary>
        private static int SkipLeading(string s, int i, int end)
        {
            while (i < end && char.IsWhiteSpace(s[i])) i++;
            return i;
        }

        /// <summary>Index of the first top-level (depth-0) occurrence of <paramref name="ch"/>, ignoring &lt;&gt;()[] nesting; -1 if none.</summary>
        private static int IndexOfTopLevel(string s, char ch)
        {
            int angle = 0, paren = 0, square = 0;
            for (int i = 0; i < s.Length; i++)
            {
                char c = s[i];
                if (c == '<') angle++;
                else if (c == '>') { if (angle > 0) angle--; }
                else if (c == '(') paren++;
                else if (c == ')') { if (paren > 0) paren--; }
                else if (c == '[') square++;
                else if (c == ']') { if (square > 0) square--; }
                else if (c == ch && angle == 0 && paren == 0 && square == 0) return i;
            }
            return -1;
        }

        /// <summary>Split on a delimiter at top level (ignoring &lt;&gt;()[]{} nesting).</summary>
        private static List<string> SplitTopLevel(string s, char delim)
        {
            var parts = new List<string>();
            int angle = 0, paren = 0, square = 0, curly = 0, last = 0;
            for (int i = 0; i < s.Length; i++)
            {
                char c = s[i];
                switch (c)
                {
                    case '<': angle++; break;
                    case '>': if (angle > 0) angle--; break;
                    case '(': paren++; break;
                    case ')': if (paren > 0) paren--; break;
                    case '[': square++; break;
                    case ']': if (square > 0) square--; break;
                    case '{': curly++; break;
                    case '}': if (curly > 0) curly--; break;
                    default:
                        if (c == delim && angle == 0 && paren == 0 && square == 0 && curly == 0)
                        {
                            parts.Add(s.Substring(last, i - last));
                            last = i + 1;
                        }
                        break;
                }
            }
            parts.Add(s.Substring(last));
            return parts;
        }
    }
}
