using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text;

namespace TheRobotDraft.Authoring.Interchange
{
    /// <summary>
    /// Parses <c>.trd-yaml</c> text (the serialization emitted by <see cref="TrdYamlWriter"/>) back into
    /// an <see cref="IxModel"/>. This is the dual of the writer — together they form a round-trip:
    /// <c>Write(Parse(Write(m))) == Write(m)</c>.
    ///
    /// <para>The reader targets the EXACT subset of YAML the writer emits: top-level <c>name:</c>,
    /// then <c>elements:</c>/<c>edges:</c>/<c>diagrams:</c> block lists whose items are either
    /// single-line flow maps (<c>- { k: v, ... }</c>) or a flow-map header followed by nested
    /// block lists (<c>members:</c>, <c>nodes:</c>). It is NOT a general YAML parser. Pure C# + BCL.
    /// Throws <see cref="InterchangeException"/> on malformed input.</para>
    /// </summary>
    public static class TrdYamlReader
    {
        public static IxModel Parse(string text)
        {
            if (text == null) throw new InterchangeException("TrdYamlReader.Parse: null text");
            var model = new IxModel();
            // Normalize line endings; split into lines without their terminators.
            var lines = text.Replace("\r\n", "\n").Replace('\r', '\n').Split('\n');

            int i = 0;
            while (i < lines.Length)
            {
                string raw = lines[i];
                string line = raw.TrimStart();
                if (line.Length == 0 || line.StartsWith("#")) { i++; continue; }

                if (line.StartsWith("name:"))
                {
                    model.Name = Unquote(line.Substring("name:".Length).Trim());
                    i++; continue;
                }
                if (line.StartsWith("elements:"))
                {
                    i = ParseElements(lines, i + 1, model);
                    continue;
                }
                if (line.StartsWith("edges:"))
                {
                    i = ParseEdges(lines, i + 1, model);
                    continue;
                }
                if (line.StartsWith("diagrams:"))
                {
                    i = ParseDiagrams(lines, i + 1, model);
                    continue;
                }
                // Unknown top-level line: skip.
                i++;
            }
            return model;
        }

        // ------------------------------------------------------------------ elements

        private static int ParseElements(string[] lines, int i, IxModel model)
        {
            while (i < lines.Length)
            {
                var (line, indent) = TrimWithIndent(lines[i]);
                if (line.Length == 0 || line.StartsWith("#")) { i++; continue; }
                if (indent == 0) break; // back to top level
                if (!IsListItem(line, indent, out string content)) break;

                int afterDash = indent + 2; // "  - " for a level-1 item
                // Flow map row may be the whole element, or open a block with nested members/nodes.
                string flow = content.Trim();
                if (!flow.StartsWith("{"))
                    throw new InterchangeException("TrdYamlReader: element item is not a flow map: " + flow);
                bool rowClosed = flow.EndsWith("}");
                var pairs = FlowMap.Parse(rowClosed ? flow : flow.TrimEnd());
                var el = new IxElement();
                ApplyElementPairs(el, pairs);

                if (rowClosed)
                {
                    model.Elements.Add(el);
                    i++; continue;
                }

                // Header opened a block: consume nested `members:` block until we see the closing `}` line.
                i++;
                i = ParseElementBlock(lines, i, el);
                model.Elements.Add(el);
            }
            return i;
        }

        private static void ApplyElementPairs(IxElement el, List<KeyValuePair<string, string>> pairs)
        {
            foreach (var kv in pairs)
            {
                switch (kv.Key)
                {
                    case "id": el.Id = Unquote(kv.Value); break;
                    case "type": el.Type = ParseEnum<IxElementType>(kv.Value); break;
                    case "name": el.Name = Unquote(kv.Value); break;
                    case "parentId": el.ParentId = UnquoteOrNull(kv.Value); break;
                    case "stereotype": el.Stereotype = UnquoteOrNull(kv.Value); break;
                    case "isAbstract": el.IsAbstract = kv.Value == "true"; break;
                    case "externalUuid": el.ExternalUuid = UnquoteOrNull(kv.Value); break;
                    case "genericParams": el.GenericParams = UnquoteOrNull(kv.Value); break;
                    case "documentation": el.Documentation = UnquoteOrNull(kv.Value); break;
                    case "fillColor": el.FillColor = UnquoteOrNull(kv.Value); break;
                    case "lineColor": el.LineColor = UnquoteOrNull(kv.Value); break;
                    case "textColor": el.TextColor = UnquoteOrNull(kv.Value); break;
                    case "styleClass": el.StyleClass = UnquoteOrNull(kv.Value); break;
                    case "enumLiterals":
                        foreach (var lit in FlowSeq(kv.Value)) el.EnumLiterals.Add(Unquote(lit));
                        break;
                    case "items":
                        foreach (var item in FlowSeq(kv.Value)) el.Items.Add(Unquote(item));
                        break;
                    case "tags":
                        foreach (var tp in FlowMap.Parse(kv.Value))
                            el.Tags[Unquote(tp.Key)] = Unquote(tp.Value);
                        break;
                    case "aspects":
                        ParseAspectsInto(kv.Value, el.Aspects);
                        break;
                    case "freeform":
                        ParseFreeformInto(kv.Value, el.Freeform);
                        break;
                    case "members":
                        // Inline flow-sequence of member maps: members: [ { ... }, { ... } ]
                        foreach (var mp in FlowSeq(kv.Value))
                        {
                            var mm = FlowMap.Parse(mp);
                            el.Members.Add(ParseMember(mm));
                        }
                        break;
                }
            }
        }

        private static IxMember ParseMember(List<KeyValuePair<string, string>> pairs)
        {
            var m = new IxMember();
            foreach (var kv in pairs)
            {
                switch (kv.Key)
                {
                    case "name": m.Name = Unquote(kv.Value); break;
                    case "isOperation": m.IsOperation = kv.Value == "true"; break;
                    case "visibility": m.Visibility = ParseEnum<IxVisibility>(kv.Value); break;
                    case "type": m.Type = UnquoteOrNull(kv.Value); break;
                    case "isStatic": m.IsStatic = kv.Value == "true"; break;
                    case "isAbstract": m.IsAbstract = kv.Value == "true"; break;
                    case "defaultValue": m.DefaultValue = UnquoteOrNull(kv.Value); break;
                    case "externalUuid": m.ExternalUuid = UnquoteOrNull(kv.Value); break;
                    case "rawText": m.RawText = UnquoteOrNull(kv.Value); break;
                    case "params":
                        foreach (var pp in FlowSeq(kv.Value))
                        {
                            var pm = FlowMap.Parse(pp);
                            var p = new IxParam();
                            foreach (var pkv in pm)
                            {
                                switch (pkv.Key)
                                {
                                    case "name": p.Name = Unquote(pkv.Value); break;
                                    case "type": p.Type = UnquoteOrNull(pkv.Value); break;
                                    case "direction": p.Direction = UnquoteOrNull(pkv.Value); break;
                                    case "defaultValue": p.DefaultValue = UnquoteOrNull(pkv.Value); break;
                                }
                            }
                            m.Parameters.Add(p);
                        }
                        break;
                }
            }
            return m;
        }

        private static int ParseElementBlock(string[] lines, int i, IxElement el)
        {
            while (i < lines.Length)
            {
                var (line, indent) = TrimWithIndent(lines[i]);
                if (line.Length == 0 || line.StartsWith("#")) { i++; continue; }
                if (line == "}" && indent == 2) { i++; break; } // closing brace of the element flow header
                if (indent == 2 && line.StartsWith("}")) { i++; break; }

                if (line.StartsWith("members:"))
                {
                    i = ParseMembers(lines, i + 1, el);
                    continue;
                }
                i++; // skip unknown nested content
            }
            return i;
        }

        private static int ParseMembers(string[] lines, int i, IxElement el)
        {
            while (i < lines.Length)
            {
                var (line, indent) = TrimWithIndent(lines[i]);
                if (line.Length == 0 || line.StartsWith("#")) { i++; continue; }
                if (!IsListItem(line, indent, out string content)) break;
                if (!content.TrimStart().StartsWith("{"))
                    throw new InterchangeException("TrdYamlReader: member item is not a flow map: " + content);
                var pairs = FlowMap.Parse(content.TrimStart().TrimEnd());
                var m = new IxMember();
                foreach (var kv in pairs)
                {
                    switch (kv.Key)
                    {
                        case "name": m.Name = Unquote(kv.Value); break;
                        case "isOperation": m.IsOperation = kv.Value == "true"; break;
                        case "visibility": m.Visibility = ParseEnum<IxVisibility>(kv.Value); break;
                        case "type": m.Type = UnquoteOrNull(kv.Value); break;
                        case "isStatic": m.IsStatic = kv.Value == "true"; break;
                        case "isAbstract": m.IsAbstract = kv.Value == "true"; break;
                        case "defaultValue": m.DefaultValue = UnquoteOrNull(kv.Value); break;
                        case "externalUuid": m.ExternalUuid = UnquoteOrNull(kv.Value); break;
                        case "rawText": m.RawText = UnquoteOrNull(kv.Value); break;
                        case "params":
                            foreach (var pp in FlowSeq(kv.Value))
                            {
                                var pm = FlowMap.Parse(pp);
                                var p = new IxParam();
                                foreach (var pkv in pm)
                                {
                                    switch (pkv.Key)
                                    {
                                        case "name": p.Name = Unquote(pkv.Value); break;
                                        case "type": p.Type = UnquoteOrNull(pkv.Value); break;
                                        case "direction": p.Direction = UnquoteOrNull(pkv.Value); break;
                                        case "defaultValue": p.DefaultValue = UnquoteOrNull(pkv.Value); break;
                                    }
                                }
                                m.Parameters.Add(p);
                            }
                            break;
                    }
                }
                el.Members.Add(m);
                i++;
            }
            return i;
        }

        // ------------------------------------------------------------------ edges

        private static int ParseEdges(string[] lines, int i, IxModel model)
        {
            while (i < lines.Length)
            {
                var (line, indent) = TrimWithIndent(lines[i]);
                if (line.Length == 0 || line.StartsWith("#")) { i++; continue; }
                if (indent == 0) break;
                if (!IsListItem(line, indent, out string content)) break;
                var pairs = FlowMap.Parse(content.TrimStart().TrimEnd());
                var e = new IxEdge();
                foreach (var kv in pairs)
                {
                    switch (kv.Key)
                    {
                        case "id": e.Id = Unquote(kv.Value); break;
                        case "type": e.Type = ParseEnum<IxEdgeType>(kv.Value); break;
                        case "from": e.FromId = Unquote(kv.Value); break;
                        case "to": e.ToId = Unquote(kv.Value); break;
                        case "label": e.Label = UnquoteOrNull(kv.Value); break;
                        case "fromMultiplicity": e.FromMultiplicity = UnquoteOrNull(kv.Value); break;
                        case "toMultiplicity": e.ToMultiplicity = UnquoteOrNull(kv.Value); break;
                        case "fromRole": e.FromRole = UnquoteOrNull(kv.Value); break;
                        case "toRole": e.ToRole = UnquoteOrNull(kv.Value); break;
                        case "externalUuid": e.ExternalUuid = UnquoteOrNull(kv.Value); break;
                        case "aspects":
                            ParseAspectsInto(kv.Value, e.Aspects);
                            break;
                        case "freeform":
                            ParseFreeformInto(kv.Value, e.Freeform);
                            break;
                    }
                }
                model.Edges.Add(e);
                i++;
            }
            return i;
        }

        // ------------------------------------------------------------------ diagrams

        private static int ParseDiagrams(string[] lines, int i, IxModel model)
        {
            while (i < lines.Length)
            {
                var (line, indent) = TrimWithIndent(lines[i]);
                if (line.Length == 0 || line.StartsWith("#")) { i++; continue; }
                if (indent == 0) break;
                if (!IsListItem(line, indent, out string content)) break;
                var pairs = FlowMap.Parse(content.TrimStart().TrimEnd());
                var d = new IxDiagram();
                foreach (var kv in pairs)
                {
                    switch (kv.Key)
                    {
                        case "id": d.Id = Unquote(kv.Value); break;
                        case "name": d.Name = UnquoteOrNull(kv.Value); break;
                        case "kind": d.Kind = UnquoteOrNull(kv.Value); break;
                        case "layoutProvenance": d.LayoutProvenance = ParseEnum<IxLayoutProvenance>(kv.Value); break;
                    }
                }
                i++;
                // Nested nodes: block list at deeper indent.
                while (i < lines.Length)
                {
                    var (nline, nindent) = TrimWithIndent(lines[i]);
                    if (nline.Length == 0 || nline.StartsWith("#")) { i++; continue; }
                    if (nindent == 2) break; // next diagram item
                    if (!nline.StartsWith("nodes:")) break;
                    i = ParseNodes(lines, i + 1, d);
                    break;
                }
                model.Diagrams.Add(d);
            }
            return i;
        }

        private static int ParseNodes(string[] lines, int i, IxDiagram d)
        {
            while (i < lines.Length)
            {
                var (line, indent) = TrimWithIndent(lines[i]);
                if (line.Length == 0 || line.StartsWith("#")) { i++; continue; }
                if (!IsListItem(line, indent, out string content)) break;
                var pairs = FlowMap.Parse(content.TrimStart().TrimEnd());
                var n = new IxNodePlacement();
                foreach (var kv in pairs)
                {
                    switch (kv.Key)
                    {
                        case "elementId": n.ElementId = Unquote(kv.Value); break;
                        case "x": n.X = ParseFloat(kv.Value); break;
                        case "y": n.Y = ParseFloat(kv.Value); break;
                        case "w": n.Width = ParseFloat(kv.Value); break;
                        case "h": n.Height = ParseFloat(kv.Value); break;
                    }
                }
                d.Nodes.Add(n);
                i++;
            }
            return i;
        }

        // ------------------------------------------------------------------ helpers

        private static (string line, int indent) TrimWithIndent(string raw)
        {
            int indent = 0;
            while (indent < raw.Length && (raw[indent] == ' ' || raw[indent] == '\t')) indent++;
            return (raw.Substring(indent), indent);
        }

        private static bool IsListItem(string trimmedLine, int indent, out string content)
        {
            // "- { ... }" or "- text" — the dash must be at the given indent.
            if (trimmedLine.StartsWith("- "))
            {
                content = trimmedLine.Substring(2);
                return true;
            }
            if (trimmedLine == "-")
            {
                content = "";
                return true;
            }
            content = null;
            return false;
        }

        private static T ParseEnum<T>(string value) where T : struct
        {
            string v = Unquote(value);
            if (Enum.TryParse<T>(v, out var result)) return result;
            throw new InterchangeException($"TrdYamlReader: unknown enum {typeof(T).Name} value: {value}");
        }

        private static float ParseFloat(string value)
        {
            if (int.TryParse(Unquote(value), NumberStyles.Integer, CultureInfo.InvariantCulture, out int i)) return i;
            if (float.TryParse(Unquote(value), NumberStyles.Float, CultureInfo.InvariantCulture, out float f)) return f;
            return 0f;
        }

        /// <summary>Unwrap a single-quoted scalar; un-escape the writer's \n / \t; bare scalars pass through. "null" → null.</summary>
        private static string Unquote(string value)
        {
            if (value == null) return null;
            string v = value.Trim();
            if (v == "null") return null;
            if (v.Length >= 2 && v[0] == '\'' && v[v.Length - 1] == '\'')
            {
                string inner = v.Substring(1, v.Length - 2).Replace("''", "'");
                return inner.Replace("\\n", "\n").Replace("\\t", "\t");
            }
            return v;
        }

        private static string UnquoteOrNull(string value)
        {
            string r = Unquote(value);
            return r == null ? null : r;
        }

        // Parse "aspects" value: { defName: { _defv: N, _emit: ADCM, field: value, ... }, ... }. Each inner map
        // is a sparse instance — only overridden keys appear; defaults live on the registry AspectDef.
        private static void ParseAspectsInto(string value, List<IxAspectInstance> list)
        {
            if (string.IsNullOrWhiteSpace(value)) return;
            foreach (var outer in FlowMap.Parse(value))
            {
                string defName = Unquote(outer.Key);
                if (string.IsNullOrEmpty(defName)) continue;
                var inst = new IxAspectInstance { DefName = defName };
                foreach (var inner in FlowMap.Parse(outer.Value))
                {
                    string k = Unquote(inner.Key);
                    if (k == "_defv")
                    {
                        int.TryParse(Unquote(inner.Value), out int v);
                        inst.DefVersion = v <= 0 ? 1 : v;
                    }
                    else if (k == "_emit")
                    {
                        inst.EmitOverride = ParseEmitFlags(Unquote(inner.Value));
                    }
                    else
                    {
                        inst.Overrides[k] = UnquoteOrNull(inner.Value) ?? "";
                    }
                }
                list.Add(inst);
            }
        }

        private static void ParseFreeformInto(string value, List<IxFreeformEntry> list)
        {
            if (string.IsNullOrWhiteSpace(value)) return;
            foreach (var kv in FlowMap.Parse(value))
            {
                string key = Unquote(kv.Key);
                if (string.IsNullOrEmpty(key)) continue;
                list.Add(new IxFreeformEntry { Key = key, Value = UnquoteOrNull(kv.Value) ?? "" });
            }
        }

        // Inverse of TrdYamlWriter.EmitFlagsString: letters A/D/C/M in any order; "-" or empty = none.
        private static IxEmitFlags ParseEmitFlags(string s)
        {
            var f = new IxEmitFlags();
            if (string.IsNullOrEmpty(s) || s == "-") return f;
            foreach (char c in s)
            {
                switch (c)
                {
                    case 'A': case 'a': f.Annotate = true; break;
                    case 'D': case 'd': f.DocTag = true; break;
                    case 'C': case 'c': f.Comment = true; break;
                    case 'M': case 'm': f.Meta = true; break;
                }
            }
            return f;
        }

        /// <summary>Split a flow-sequence value <c>[a, b, c]</c> into its items (each item may itself be a flow map).</summary>
        private static List<string> FlowSeq(string value)
        {
            var result = new List<string>();
            if (value == null) return result;
            string v = value.Trim();
            if (v.Length < 2 || v[0] != '[' || v[v.Length - 1] != ']') return result;
            string body = v.Substring(1, v.Length - 2);
            int depth = 0;
            var sb = new StringBuilder();
            bool inQuote = false;
            foreach (char c in body)
            {
                if (c == '\'' ) inQuote = !inQuote;
                if (!inQuote)
                {
                    if (c == '{' || c == '[') depth++;
                    else if (c == '}' || c == ']') depth--;
                    if (c == ',' && depth == 0) { result.Add(sb.ToString().Trim()); sb.Clear(); continue; }
                }
                sb.Append(c);
            }
            if (sb.ToString().Trim().Length > 0) result.Add(sb.ToString().Trim());
            return result;
        }

        // ------------------------------------------------------------------ flow map parser

        private static class FlowMap
        {
            /// <summary>Parse <c>{ k: v, k2: { ... }, k3: [...] }</c> into ordered key/value pairs.
            /// Values are kept RAW (still quoted/bracketed); callers unquote as needed.</summary>
            public static List<KeyValuePair<string, string>> Parse(string text)
            {
                var result = new List<KeyValuePair<string, string>>();
                if (text == null) return result;
                string v = text.Trim();
                // Strip an optional leading/trailing brace pair.
                if (v.Length >= 2 && v[0] == '{' && v[v.Length - 1] == '}')
                    v = v.Substring(1, v.Length - 2);
                else if (v.StartsWith("{"))
                    v = v.Substring(1); // opening brace only (block header)

                int i = 0;
                while (i < v.Length)
                {
                    i = SkipSpace(v, i);
                    if (i >= v.Length) break;
                    string key = ReadKey(v, ref i);
                    i = SkipSpace(v, i);
                    if (i >= v.Length || v[i] != ':') { i++; continue; }
                    i++; // consume ':'
                    i = SkipSpace(v, i);
                    string val = ReadValue(v, ref i);
                    result.Add(new KeyValuePair<string, string>(key, val));
                    i = SkipSpace(v, i);
                    if (i < v.Length && v[i] == ',') i++;
                }
                return result;
            }

            private static int SkipSpace(string s, int i)
            {
                while (i < s.Length && (s[i] == ' ' || s[i] == '\t')) i++;
                return i;
            }

            private static string ReadKey(string s, ref int i)
            {
                // A single-quoted key (may contain spaces/colons/commas): read the whole quoted span.
                if (i < s.Length && s[i] == '\'')
                {
                    int start = i; i++;
                    while (i < s.Length)
                    {
                        if (s[i] == '\'') { if (i + 1 < s.Length && s[i + 1] == '\'') { i += 2; continue; } break; }
                        i++;
                    }
                    if (i < s.Length) i++; // closing quote
                    return s.Substring(start, i - start);
                }
                int start2 = i;
                while (i < s.Length && s[i] != ':' && s[i] != ',' && s[i] != ' ' && s[i] != '\t') i++;
                return s.Substring(start2, i - start2);
            }

            private static string ReadValue(string s, ref int i)
            {
                if (i >= s.Length) return "";
                if (s[i] == '\'')
                {
                    int start = i; i++; // opening quote
                    while (i < s.Length)
                    {
                        if (s[i] == '\'') { if (i + 1 < s.Length && s[i + 1] == '\'') { i += 2; continue; } break; }
                        i++;
                    }
                    if (i < s.Length) i++; // closing quote
                    return s.Substring(start, i - start);
                }
                if (s[i] == '{' || s[i] == '[')
                {
                    char open = s[i], close = (open == '{') ? '}' : ']';
                    int start = i, depth = 0;
                    while (i < s.Length)
                    {
                        if (s[i] == '\'') { i++; while (i < s.Length && s[i] != '\'') i++; if (i < s.Length) i++; continue; }
                        if (s[i] == open) depth++;
                        else if (s[i] == close) { depth--; if (depth == 0) { i++; break; } }
                        i++;
                    }
                    return s.Substring(start, i - start);
                }
                // bare scalar: read until top-level comma
                int bstart = i;
                while (i < s.Length && s[i] != ',') i++;
                return s.Substring(bstart, i - bstart).TrimEnd();
            }
        }
    }
}
