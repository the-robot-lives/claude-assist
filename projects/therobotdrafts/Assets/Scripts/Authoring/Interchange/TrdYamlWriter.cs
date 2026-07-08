using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text;

namespace TheRobotDraft.Authoring.Interchange
{
    /// <summary>
    /// Emits an <see cref="IxModel"/> as `.trd-yaml` — TheRobotDrafts' native model format
    /// (docs/specs/model-files-browse-nav-plan.md §2). The format is a YAML serialization of the
    /// interchange IR: a <c>name</c>, an <c>elements</c> pool (single-parent containment via
    /// <c>parentId</c>), <c>edges</c>, and <c>diagrams</c> (each a list of <c>IxNodePlacement</c>).
    ///
    /// Output is a pure, deterministic function of the model (LF newlines, model-list ordering,
    /// no invented ids/colors) so exports diff cleanly and re-import is stable. Null/empty fields are
    /// omitted to keep output clean. Enum values are written by their <c>.ToString()</c> name
    /// (Package, Class, Association, Authored, Public, ...). Pure C# + BCL.
    /// </summary>
    public static class TrdYamlWriter
    {
        /// <summary>Serialize <paramref name="model"/> to `.trd-yaml` text. Throws on null model.</summary>
        public static string Write(IxModel model)
        {
            if (model == null) throw new InterchangeException("TrdYamlWriter.Write: null model");

            var sb = new StringBuilder();
            sb.Append("# .trd-yaml — TheRobotDrafts native model (IxModel serialization)\n");
            if (!string.IsNullOrEmpty(model.Name))
                sb.Append("name: ").Append(Scalar(model.Name)).Append('\n');

            if (model.Elements.Count > 0)
            {
                sb.Append("elements:\n");
                foreach (var el in model.Elements)
                {
                    if (el == null) continue;
                    AppendElement(sb, el);
                }
            }

            if (model.Edges.Count > 0)
            {
                sb.Append("edges:\n");
                foreach (var e in model.Edges)
                {
                    if (e == null) continue;
                    AppendEdge(sb, e);
                }
            }

            if (model.Diagrams.Count > 0)
            {
                sb.Append("diagrams:\n");
                foreach (var d in model.Diagrams)
                {
                    if (d == null) continue;
                    AppendDiagram(sb, d);
                }
            }

            return sb.ToString();
        }

        // ------------------------------------------------------------------ elements

        private static void AppendElement(StringBuilder sb, IxElement el)
        {
            // The element is emitted as ONE flow-map list item (`- { ... }`). Everything that
            // belongs to the element — including members — MUST live inside those braces, because
            // a flow map after `- ` is the whole node; a block `members:` key on the next line is
            // not part of it and produces invalid YAML. Members therefore go in as a flow sequence.
            sb.Append("  - { ");
            AppendPair(sb, "id", el.Id, first: true);
            AppendPair(sb, "type", el.Type.ToString());
            AppendPair(sb, "name", el.Name);
            AppendPair(sb, "parentId", el.ParentId);
            AppendPair(sb, "stereotype", el.Stereotype);
            if (el.IsAbstract) AppendPair(sb, "isAbstract", "true");
            AppendPair(sb, "externalUuid", el.ExternalUuid);
            AppendPair(sb, "genericParams", el.GenericParams);
            AppendPair(sb, "documentation", el.Documentation);
            AppendPair(sb, "fillColor", el.FillColor);
            AppendPair(sb, "lineColor", el.LineColor);
            AppendPair(sb, "textColor", el.TextColor);
            AppendPair(sb, "styleClass", el.StyleClass);

            if (el.EnumLiterals != null && el.EnumLiterals.Count > 0)
            {
                sb.Append(", enumLiterals: [");
                for (int i = 0; i < el.EnumLiterals.Count; i++)
                {
                    if (i > 0) sb.Append(", ");
                    sb.Append(Scalar(el.EnumLiterals[i]));
                }
                sb.Append(']');
            }

            if (el.Tags != null && el.Tags.Count > 0)
            {
                bool firstTag = true;
                foreach (var kv in el.Tags)
                {
                    sb.Append(firstTag ? ", tags: {" : ", ");
                    sb.Append(Scalar(kv.Key)).Append(": ").Append(Scalar(kv.Value));
                    firstTag = false;
                }
                sb.Append('}');
            }

            // members as a flow sequence inside the element's flow map (keeps the node valid YAML).
            if (el.Members != null && el.Members.Count > 0)
            {
                sb.Append(", members: [");
                for (int i = 0; i < el.Members.Count; i++)
                {
                    if (el.Members[i] == null) continue;
                    if (i > 0) sb.Append(", ");
                    AppendMemberFlow(sb, el.Members[i]);
                }
                sb.Append(']');
            }

            sb.Append(" }\n");
        }

        private static void AppendMemberFlow(StringBuilder sb, IxMember m)
        {
            sb.Append("{ ");
            bool first = true;
            first = AppendPair(sb, "name", m.Name, first);
            first = AppendPair(sb, "isOperation", m.IsOperation ? "true" : "false", first);
            first = AppendPair(sb, "visibility", m.Visibility.ToString(), first);
            first = AppendPair(sb, "type", m.Type, first);
            if (m.IsStatic) first = AppendPair(sb, "isStatic", "true", first);
            if (m.IsAbstract) first = AppendPair(sb, "isAbstract", "true", first);
            first = AppendPair(sb, "defaultValue", m.DefaultValue, first);
            first = AppendPair(sb, "externalUuid", m.ExternalUuid, first);

            if (m.Parameters != null && m.Parameters.Count > 0)
            {
                if (!first) sb.Append(", ");
                sb.Append("params: [");
                for (int i = 0; i < m.Parameters.Count; i++)
                {
                    if (i > 0) sb.Append(", ");
                    AppendParamFlow(sb, m.Parameters[i]);
                }
                sb.Append(']');
                first = false;
            }

            AppendPair(sb, "rawText", m.RawText, first);
            sb.Append(" }");
        }

        private static void AppendParamFlow(StringBuilder sb, IxParam p)
        {
            sb.Append("{ ");
            bool first = true;
            first = AppendPair(sb, "name", p.Name, first);
            first = AppendPair(sb, "type", p.Type, first);
            first = AppendPair(sb, "direction", p.Direction, first);
            AppendPair(sb, "defaultValue", p.DefaultValue, first);
            sb.Append(" }");
        }

        // ------------------------------------------------------------------ edges

        private static void AppendEdge(StringBuilder sb, IxEdge e)
        {
            sb.Append("  - { ");
            AppendPair(sb, "id", e.Id, first: true);
            AppendPair(sb, "type", e.Type.ToString());
            AppendPair(sb, "from", e.FromId);
            AppendPair(sb, "to", e.ToId);
            AppendPair(sb, "label", e.Label);
            AppendPair(sb, "fromMultiplicity", e.FromMultiplicity);
            AppendPair(sb, "toMultiplicity", e.ToMultiplicity);
            AppendPair(sb, "fromRole", e.FromRole);
            AppendPair(sb, "toRole", e.ToRole);
            AppendPair(sb, "externalUuid", e.ExternalUuid);
            sb.Append(" }\n");
        }

        // ------------------------------------------------------------------ diagrams

        private static void AppendDiagram(StringBuilder sb, IxDiagram d)
        {
            sb.Append("  - { ");
            AppendPair(sb, "id", d.Id ?? "", first: true);
            AppendPair(sb, "name", d.Name);
            AppendPair(sb, "kind", d.Kind);
            AppendPair(sb, "layoutProvenance", d.LayoutProvenance.ToString());
            sb.Append(" }\n");
            if (d.Nodes != null && d.Nodes.Count > 0)
            {
                sb.Append("    nodes:\n");
                foreach (var n in d.Nodes)
                {
                    if (n == null) continue;
                    sb.Append("      - { ");
                    AppendPair(sb, "elementId", n.ElementId, first: true);
                    sb.Append(", x: ").Append(Num(n.X));
                    sb.Append(", y: ").Append(Num(n.Y));
                    sb.Append(", w: ").Append(Num(n.Width));
                    sb.Append(", h: ").Append(Num(n.Height));
                    sb.Append(" }\n");
                }
            }
        }

        // ------------------------------------------------------------------ scalars

        private static readonly char[] QuoteTriggers = { ':', '#', '{', '}', '[', ']', ',', '*', '&', '!', '|', '>', '%', '@', '`', '?', '"' };

        /// <summary>Quote a string scalar when it contains a YAML-significant char, a control char, or is empty; otherwise emit bare.
        /// Inside single quotes: <c>'</c> is doubled, and <c>\n</c>/<c>\r</c> are escaped to literal <c>\n</c> so the line stays on one row.
        /// <see cref="TrdYamlReader"/> un-escapes both on parse.</summary>
        private static string Scalar(string s)
        {
            if (s == null) return "null";
            if (s.Length == 0) return "''";
            bool needs = false;
            if (char.IsWhiteSpace(s[0]) || char.IsWhiteSpace(s[s.Length - 1])) needs = true;
            else
            {
                for (int i = 0; i < s.Length; i++)
                {
                    char c = s[i];
                    if (c == '\'' || c == '\n' || c == '\r' || c == '\t' || Array.IndexOf(QuoteTriggers, c) >= 0) { needs = true; break; }
                }
            }
            if (!needs) return s;
            // normalize CR/LF to \n escape, double internal ', escape tabs too
            string cleaned = s.Replace("\r\n", "\n").Replace('\r', '\n').Replace("\n", "\\n").Replace("\t", "\\t");
            return "'" + cleaned.Replace("'", "''") + "'";
        }

        /// <summary>Append <c>, key: value</c> (or the first one without a leading comma) when value is non-null/non-empty.</summary>
        private static bool AppendPair(StringBuilder sb, string key, string value, bool first = false)
        {
            if (value == null) return first;
            if (value.Length == 0) return first; // omit empties
            if (!first) sb.Append(", ");
            sb.Append(key).Append(": ").Append(Scalar(value));
            return false;
        }

        private static string Num(float f)
        {
            // round to int for geometry (deterministic; floats from readers are coarse)
            int r = (int)Math.Round(f, MidpointRounding.AwayFromZero);
            return r.ToString(CultureInfo.InvariantCulture);
        }
    }
}
