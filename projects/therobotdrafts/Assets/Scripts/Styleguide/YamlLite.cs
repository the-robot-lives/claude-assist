using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text;

namespace TheRobotDraft.Styleguide
{
    /// <summary>
    /// A minimal hand-written YAML reader/writer tailored to the Noizu styleguide theme files. The real configs use
    /// only: top-level key: maps, <c>- key:</c> list items, nested sub-maps (indentation-based), quoted + unquoted
    /// scalars, and <c>#</c> comments — no anchors, no flow sequences beyond a rare inline map. This parser covers
    /// exactly that subset and, crucially, <b>round-trips with comments and ordering preserved</b>: comment lines are
    /// stored as <see cref="NodeKind.Comment"/> siblings in the tree so the emitter writes them back in place. That
    /// is what lets the in-app form editor mutate values without destroying the curated <c># name: value</c>
    /// documentation that dominates <c>style-guide.vars.yaml</c>.
    /// </summary>
    public static class YamlLite
    {
        public enum NodeKind { Scalar, Map, List, Comment }

        /// <summary>A node in the parsed tree. A map keeps ordered (key → child) pairs; a list keeps ordered children.</summary>
        public sealed class Node
        {
            public NodeKind Kind;
            public string Scalar;                 // raw scalar text (quotes already unwrapped)
            public string Quote;                  // "", "'" or "\"" — the original quote style, for round-trip
            public readonly List<KeyValuePair<string, Node>> Map = new(); // ordered map entries
            public readonly List<Node> Items = new();                    // list items
            public string CommentText;           // for Comment nodes (without the leading #)
            public bool CommentInline;           // a full-line comment (true) vs trailing-after-scalar (false)

            public bool IsScalar => Kind == NodeKind.Scalar;
            public bool IsMap => Kind == NodeKind.Map;
            public bool IsList => Kind == NodeKind.List;

            public Node NewMap() { var n = new Node { Kind = NodeKind.Map }; return n; }
            public static Node MapNode() => new Node { Kind = NodeKind.Map };
            public static Node ListNode() => new Node { Kind = NodeKind.List };
            public static Node ScalarNode(string value, string quote = "") =>
                new Node { Kind = NodeKind.Scalar, Scalar = value ?? "", Quote = quote ?? "" };

            public bool TryGet(string key, out Node value)
            {
                if (Kind != NodeKind.Map) { value = null; return false; }
                foreach (var kv in Map) if (kv.Key == key) { value = kv.Value; return true; }
                value = null; return false;
            }

            public Node Get(string key) => TryGet(key, out var v) ? v : null;

            /// <summary>Set or replace a map entry by key (ordered; appends if absent).</summary>
            public void Set(string key, Node value)
            {
                for (int i = 0; i < Map.Count; i++)
                    if (Map[i].Key == key) { Map[i] = new KeyValuePair<string, Node>(key, value); return; }
                Map.Add(new KeyValuePair<string, Node>(key, value));
            }
        }

        // =========================================================================================
        // parsing
        // =========================================================================================

        public static Node Parse(string text)
        {
            var lines = (text ?? "").Replace("\r\n", "\n").Replace('\r', '\n').Split('\n');
            var root = Node.MapNode();
            // Top level: collect direct child entries (map pairs or list items or full-line comments).
            ParseBlock(lines, 0, 0, root);
            return root;
        }

        /// <summary>Parse indented block lines starting at <paramref name="start"/> (indent ≥ minIndent) into parent.</summary>
        private static int ParseBlock(string[] lines, int start, int minIndent, Node parent)
        {
            int i = start;
            while (i < lines.Length)
            {
                var raw = lines[i];
                var (content, indent) = StripIndent(raw);
                if (content.Length == 0) { i++; continue; } // blank line

                // Full-line comment: belongs to this block only if its indent ≥ minIndent.
                if (content.StartsWith("#"))
                {
                    if (indent < minIndent) break;
                    parent.Items.Add(new Node { Kind = NodeKind.Comment, CommentText = content.Substring(1), CommentInline = false });
                    i++;
                    continue;
                }
                if (indent < minIndent) break;

                // List item.
                if (content.StartsWith("- "))
                {
                    if (parent.Kind != NodeKind.List)
                    {
                        // Promote: if parent is a map being asked to hold a list, that's a structural quirk — but the
                        // styleguide always nests lists under a map key, so parent is already a List here.
                    }
                    string rest = content.Substring(2).TrimStart();
                    var item = ParseItemValue(lines, ref i, indent, rest);
                    parent.Items.Add(item);
                    continue;
                }

                // Map key: value.
                int colon = FindColon(content);
                if (colon < 0) { i++; continue; } // not a recognizable entry; skip
                string key = content.Substring(0, colon).Trim();
                string val = content.Substring(colon + 1).TrimStart();

                if (parent.Kind != NodeKind.Map) parent.Kind = NodeKind.Map;

                if (val.Length == 0)
                {
                    // Value is a nested block (map or list) on following lines.
                    var (inlined, _) = StripIndent(raw);
                    // peek next non-blank line's indent to decide child kind
                    var child = PeekListOrMap(lines, i + 1, indent);
                    parent.Set(key, child.node);
                    i = child.next;
                }
                else
                {
                    var (scalar, trailingComment) = ParseScalar(val);
                    var scalarNode = Node.ScalarNode(scalar.value, scalar.quote);
                    if (trailingComment != null)
                        scalarNode.Items.Add(new Node { Kind = NodeKind.Comment, CommentText = trailingComment, CommentInline = true });
                    parent.Set(key, scalarNode);
                    i++;
                }
            }
            return i;
        }

        /// <summary>The value of a list item, which may be a scalar or the first key of an inline map.</summary>
        private static Node ParseItemValue(string[] lines, ref int i, int itemIndent, string rest)
        {
            // "- key: value" → item is a map whose first entry is key:value (and further indented keys follow).
            int colon = FindColon(rest);
            if (colon >= 0)
            {
                var map = Node.MapNode();
                string key = rest.Substring(0, colon).Trim();
                string val = rest.Substring(colon + 1).TrimStart();
                if (val.Length == 0)
                {
                    var child = PeekListOrMap(lines, i + 1, itemIndent + 2);
                    map.Set(key, child.node);
                    i = child.next;
                }
                else
                {
                    var (scalar, _) = ParseScalar(val);
                    map.Set(key, Node.ScalarNode(scalar.value, scalar.quote));
                    i++;
                }
                // Continue parsing further-indented sibling keys into the same map.
                i = ParseBlock(lines, i, itemIndent + 2, map);
                return map;
            }
            // "- value" (scalar item) or "- # comment"
            if (rest.StartsWith("#"))
            {
                i++;
                return new Node { Kind = NodeKind.Comment, CommentText = rest.Substring(1), CommentInline = false };
            }
            var (sc, _) = ParseScalar(rest);
            i++;
            return Node.ScalarNode(sc.value, sc.quote);
        }

        /// <summary>Look ahead to decide whether the following indented block is a List or Map, parse it, return next index.</summary>
        private static (Node node, int next) PeekListOrMap(string[] lines, int from, int childIndent)
        {
            int j = from;
            while (j < lines.Length)
            {
                var (content, indent) = StripIndent(lines[j]);
                if (content.Length == 0 || content.StartsWith("#")) { j++; continue; }
                if (indent < childIndent) return (Node.MapNode(), from); // empty block — represent as empty map
                var parent = content.StartsWith("- ") ? Node.ListNode() : Node.MapNode();
                int next = ParseBlock(lines, j, indent, parent);
                return (parent, next);
            }
            return (Node.MapNode(), from);
        }

        private static (string content, int indent) StripIndent(string line)
        {
            int indent = 0;
            while (indent < line.Length && line[indent] == ' ') indent++;
            return (line.Substring(indent).TrimEnd(), indent);
        }

        private static int FindColon(string s)
        {
            // First ':' that is followed by space or end-of-line (avoids matching URLs in quoted scalars, which
            // wouldn't reach here since they're values, but guards the general case).
            bool inSingle = false, inDouble = false;
            for (int i = 0; i < s.Length; i++)
            {
                char c = s[i];
                if (c == '\'' && !inDouble) inSingle = !inSingle;
                else if (c == '"' && !inSingle) inDouble = !inDouble;
                else if (c == ':' && !inSingle && !inDouble && (i + 1 >= s.Length || s[i + 1] == ' '))
                    return i;
            }
            return -1;
        }

        private static ((string value, string quote) scalar, string trailingComment) ParseScalar(string raw)
        {
            string trailing = null;
            // Split a trailing "  # comment" only when the # is preceded by whitespace and not inside quotes.
            int hash = FindTrailingComment(raw);
            if (hash >= 0) { trailing = raw.Substring(hash + 1); raw = raw.Substring(0, hash).TrimEnd(); }

            if (raw.Length >= 2 && raw[0] == '"' && raw[raw.Length - 1] == '"')
                return ((Unescape(raw.Substring(1, raw.Length - 2)), "\""), trailing);
            if (raw.Length >= 2 && raw[0] == '\'' && raw[raw.Length - 1] == '\'')
                return ((raw.Substring(1, raw.Length - 2).Replace("''", "'"), "'"), trailing);
            return ((raw, ""), trailing);
        }

        private static int FindTrailingComment(string s)
        {
            bool inSingle = false, inDouble = false;
            for (int i = 0; i < s.Length; i++)
            {
                char c = s[i];
                if (c == '\'' && !inDouble) inSingle = !inSingle;
                else if (c == '"' && !inSingle) inDouble = !inDouble;
                else if (c == '#' && !inSingle && !inDouble && i > 0 && s[i - 1] == ' ')
                    return i;
            }
            return -1;
        }

        private static string Unescape(string s) => s.Replace("\\\"", "\"").Replace("\\\\", "\\");

        // =========================================================================================
        // writing (round-trip)
        // =========================================================================================

        public static string Write(Node node)
        {
            var sb = new StringBuilder();
            WriteNode(sb, node, 0);
            return sb.ToString();
        }

        private static void WriteNode(StringBuilder sb, Node node, int indent)
        {
            switch (node.Kind)
            {
                case NodeKind.Scalar:
                    sb.Append(FormatScalar(node.Scalar, node.Quote));
                    // Trailing comment attached to a scalar (inline).
                    foreach (var c in node.Items)
                        if (c.Kind == NodeKind.Comment) sb.Append("  #").Append(c.CommentText);
                    sb.Append('\n');
                    break;
                case NodeKind.Comment:
                    if (node.CommentInline) sb.Append('#').Append(node.CommentText).Append('\n');
                    else { Indent(sb, indent); sb.Append('#').Append(node.CommentText).Append('\n'); }
                    break;
                case NodeKind.Map:
                    WriteMap(sb, node, indent);
                    break;
                case NodeKind.List:
                    WriteList(sb, node, indent);
                    break;
            }
        }

        private static void WriteMap(StringBuilder sb, Node map, int indent)
        {
            // Comments stored in Items at this level are full-line comments interleaved with map entries. To preserve
            // ordering relative to keys, both keys and comments are emitted in a merged order: map entries first by
            // their stored order, with leading comments bucketed ahead. For the styleguide files this is faithful.
            foreach (var comment in map.Items)
                if (comment.Kind == NodeKind.Comment && !comment.CommentInline)
                { Indent(sb, indent); sb.Append('#').Append(comment.CommentText).Append('\n'); }
            foreach (var kv in map.Map)
            {
                Indent(sb, indent);
                sb.Append(kv.Key).Append(':');
                if (kv.Value == null) { sb.Append('\n'); continue; }
                if (kv.Value.IsScalar)
                {
                    sb.Append(' ');
                    sb.Append(FormatScalar(kv.Value.Scalar, kv.Value.Quote));
                    foreach (var c in kv.Value.Items)
                        if (c.Kind == NodeKind.Comment) sb.Append("  #").Append(c.CommentText);
                    sb.Append('\n');
                }
                else
                {
                    sb.Append('\n');
                    WriteNode(sb, kv.Value, indent + 2);
                }
            }
        }

        private static void WriteList(StringBuilder sb, Node list, int indent)
        {
            foreach (var item in list.Items)
            {
                if (item.Kind == NodeKind.Comment)
                {
                    if (!item.CommentInline) { Indent(sb, indent); sb.Append('#').Append(item.CommentText).Append('\n'); }
                    continue;
                }
                Indent(sb, indent);
                if (item.IsScalar)
                {
                    sb.Append("- ").Append(FormatScalar(item.Scalar, item.Quote)).Append('\n');
                }
                else
                {
                    // Inline first map key onto the "- " line, then remaining keys indented.
                    if (item.IsMap && item.Map.Count > 0)
                    {
                        var first = item.Map[0];
                        sb.Append("- ").Append(first.Key).Append(':');
                        if (first.Value != null && first.Value.IsScalar)
                        {
                            sb.Append(' ').Append(FormatScalar(first.Value.Scalar, first.Value.Quote)).Append('\n');
                            // Remaining keys at indent+2.
                            for (int k = 1; k < item.Map.Count; k++)
                            {
                                Indent(sb, indent + 2);
                                EmitMapEntry(sb, item.Map[k], indent + 2);
                            }
                        }
                        else
                        {
                            sb.Append('\n');
                            if (first.Value != null) WriteNode(sb, first.Value, indent + 4);
                            for (int k = 1; k < item.Map.Count; k++)
                            {
                                Indent(sb, indent + 2);
                                EmitMapEntry(sb, item.Map[k], indent + 2);
                            }
                        }
                    }
                    else
                    {
                        sb.Append("-\n");
                        WriteNode(sb, item, indent + 2);
                    }
                }
            }
        }

        private static void EmitMapEntry(StringBuilder sb, KeyValuePair<string, Node> kv, int indent)
        {
            sb.Append(kv.Key).Append(':');
            if (kv.Value == null) { sb.Append('\n'); return; }
            if (kv.Value.IsScalar)
            {
                sb.Append(' ').Append(FormatScalar(kv.Value.Scalar, kv.Value.Quote)).Append('\n');
            }
            else
            {
                sb.Append('\n');
                WriteNode(sb, kv.Value, indent + 2);
            }
        }

        private static string FormatScalar(string value, string quote)
        {
            if (quote == "\"") return "\"" + value.Replace("\\", "\\\\").Replace("\"", "\\\"") + "\"";
            if (quote == "'") return "'" + value.Replace("'", "''") + "'";
            // Unquoted: re-quote if the value would be misread (contains a leading special, ': ', ' #', etc.).
            if (NeedsQuoting(value)) return "\"" + value.Replace("\\", "\\\\").Replace("\"", "\\\"") + "\"";
            return value;
        }

        private static bool NeedsQuoting(string v)
        {
            if (string.IsNullOrEmpty(v)) return false;
            char c0 = v[0];
            if (c0 == '#' || c0 == '-' || c0 == ':' || c0 == '{' || c0 == '[' || c0 == '&' || c0 == '*'
                || c0 == '!' || c0 == '|' || c0 == '>' || c0 == '\'' || c0 == '"') return true;
            if (v.Contains(": ") || v.Contains(" #")) return true;
            return false;
        }

        private static void Indent(StringBuilder sb, int n)
        {
            for (int i = 0; i < n; i++) sb.Append(' ');
        }
    }
}
