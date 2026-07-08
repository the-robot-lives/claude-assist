using System;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;

namespace TheRobotDraft.Authoring.Interchange
{
    /// <summary>
    /// Emits an <see cref="IxModel"/> as a Mermaid <c>classDiagram</c> (docs/formats/mermaid-format.md).
    /// Output is a pure, deterministic function of the model — identical input yields byte-identical
    /// text (LF newlines, model-list ordering, no invented ids) so exports diff cleanly and re-import
    /// is stable. Relationships use one canonical orientation each (documented in the format doc and
    /// mirrored by <see cref="MermaidReader"/>). Coloring is the headline feature: elements are grouped
    /// by identical (fill, line, text) tuple, one <c>classDef</c> is emitted per group (reusing the
    /// group's <c>StyleClass</c> name when unanimous, else <c>style1..styleN</c> in first-appearance
    /// order), and members are assigned with sorted <c>class Elem style</c> lines. Colors are never
    /// invented — an element with no color fields produces no styling. Pure C# + BCL.
    /// </summary>
    public static class MermaidWriter
    {
        private static readonly Regex BareIdRx = new Regex(@"^[A-Za-z_][A-Za-z0-9_]*$", RegexOptions.Compiled);
        private static readonly Regex GenericsOutRx = new Regex(@"<([^<>]*)>", RegexOptions.Compiled);

        public static string Write(IxModel model)
        {
            if (model == null) throw new InterchangeException("MermaidWriter.Write: null model");

            var ident = BuildIdents(model);
            var sb = new StringBuilder();
            // Model name rides in YAML frontmatter (the reader recovers `title:` and skips the rest).
            if (!string.IsNullOrEmpty(model.Name))
                sb.Append("---\ntitle: ").Append(model.Name.Replace("\r", " ").Replace("\n", " ")).Append("\n---\n");
            sb.Append("classDiagram\n");

            var packageIds = new HashSet<string>();
            var packages = new List<IxElement>();
            var classifiers = new List<IxElement>();
            var notes = new List<IxElement>();
            foreach (var el in model.Elements)
            {
                if (el == null || el.Id == null) continue;
                if (el.Type == IxElementType.Package) { packages.Add(el); packageIds.Add(el.Id); }
                else if (el.Type == IxElementType.Note) notes.Add(el);
                else classifiers.Add(el);
            }

            // Build the exact emission order once, then declare + group styling from it. Grouping in
            // emission order (not raw model order) is what keeps parse->write->parse->write stable:
            // a re-import lands elements in this order, so generated styleN names never flip.
            var ordered = new List<IxElement>();

            // Namespaces (packages that actually contain classifiers), in first-appearance order.
            foreach (var p in packages)
            {
                var kids = new List<IxElement>();
                foreach (var c in classifiers) if (c.ParentId == p.Id) kids.Add(c);
                if (kids.Count == 0) continue; // empty packages have no Mermaid representation
                ordered.Add(p);
                sb.Append("    namespace ").Append(DeclName(p, ident)).Append(" {\n");
                foreach (var c in kids) { EmitClass(sb, c, ident, "        "); ordered.Add(c); }
                sb.Append("    }\n");
            }

            // Top-level classifiers (no package parent).
            foreach (var c in classifiers)
                if (c.ParentId == null || !packageIds.Contains(c.ParentId))
                { EmitClass(sb, c, ident, "    "); ordered.Add(c); }

            // Notes. Mermaid `note for X` ties one note box to one element, so a note carrying several
            // NoteLinks is emitted as one `note for` line per target (re-import splits it into N notes,
            // preserving every link). A note with no link degrades to a standalone `note "…"`.
            foreach (var n in notes)
            {
                string body = EscapeNote(n.Documentation);
                var targets = NoteTargets(model, n, ident);
                if (targets.Count == 0)
                    sb.Append("    note \"").Append(body).Append("\"\n");
                else
                    foreach (var tid in targets)
                        sb.Append("    note for ").Append(tid).Append(" \"").Append(body).Append("\"\n");
                ordered.Add(n);
            }

            // Relationships (NoteLink emitted above via note-for).
            foreach (var e in model.Edges)
            {
                if (e == null || e.Type == IxEdgeType.NoteLink) continue;
                if (e.FromId == null || e.ToId == null) continue;
                if (!ident.TryGetValue(e.FromId, out var from) || !ident.TryGetValue(e.ToId, out var to)) continue;
                sb.Append("    ").Append(EmitEdge(e, from, to)).Append('\n');
            }

            EmitStyling(sb, ordered, ident);
            return sb.ToString();
        }

        // --- elements --------------------------------------------------------------------------

        private static void EmitClass(StringBuilder sb, IxElement el, Dictionary<string, string> ident, string indent)
        {
            string header = DeclName(el, ident);
            if (!string.IsNullOrEmpty(el.GenericParams)) header += "~" + el.GenericParams + "~";

            string annotation = AnnotationOf(el);
            bool hasBody = annotation != null || el.Members.Count > 0 || el.EnumLiterals.Count > 0;

            if (!hasBody) { sb.Append(indent).Append("class ").Append(header).Append('\n'); return; }

            sb.Append(indent).Append("class ").Append(header).Append(" {\n");
            string inner = indent + "    ";
            if (annotation != null) sb.Append(inner).Append("<<").Append(annotation).Append(">>\n");
            foreach (var lit in el.EnumLiterals) sb.Append(inner).Append(lit).Append('\n');
            foreach (var m in el.Members) sb.Append(inner).Append(MemberText(m)).Append('\n');
            sb.Append(indent).Append("}\n");
        }

        private static string AnnotationOf(IxElement el)
        {
            if (el.Type == IxElementType.Interface) return "interface";
            if (el.Type == IxElementType.Enum) return "enumeration";
            if (!string.IsNullOrEmpty(el.Stereotype)) return el.Stereotype;
            if (el.IsAbstract) return "abstract";
            return null;
        }

        private static string MemberText(IxMember m)
        {
            var sb = new StringBuilder();
            sb.Append(VisChar(m.Visibility));
            if (m.IsOperation)
            {
                sb.Append(m.Name).Append('(');
                for (int i = 0; i < m.Parameters.Count; i++)
                {
                    if (i > 0) sb.Append(", ");
                    sb.Append(ParamText(m.Parameters[i]));
                }
                sb.Append(')');
                if (!string.IsNullOrEmpty(m.Type)) sb.Append(' ').Append(GenericsOut(m.Type));
                if (m.IsAbstract) sb.Append('*');
                else if (m.IsStatic) sb.Append('$');
            }
            else
            {
                if (!string.IsNullOrEmpty(m.Type)) sb.Append(GenericsOut(m.Type)).Append(' ').Append(m.Name);
                else sb.Append(m.Name);
                if (m.IsStatic) sb.Append('$');
            }
            return sb.ToString();
        }

        private static string ParamText(IxParam p)
        {
            bool hasType = !string.IsNullOrEmpty(p.Type);
            bool hasName = !string.IsNullOrEmpty(p.Name);
            if (hasType && hasName) return GenericsOut(p.Type) + " " + p.Name;
            if (hasType) return GenericsOut(p.Type);
            return hasName ? p.Name : "";
        }

        // --- relationships ---------------------------------------------------------------------

        // Canonical orientations (see MermaidReader.Decode for the inverse):
        //   Generalization: Parent <|-- Child   (To <|-- From)
        //   Realization:    Impl ..|> Iface      (From ..|> To)
        //   Composition:    Whole *-- Part        (From *-- To)
        //   Aggregation:    Whole o-- Part         (From o-- To)
        //   DirectedAssoc:  Source --> Target       (From --> To)
        //   Association:    From -- To
        //   Dependency:     From ..> To
        private static string EmitEdge(IxEdge e, string from, string to)
        {
            switch (e.Type)
            {
                case IxEdgeType.Generalization:
                case IxEdgeType.Extension:
                    return EdgeLine(to, "<|--", from, e.ToMultiplicity, e.FromMultiplicity, e.Label);
                case IxEdgeType.Realization:
                    return EdgeLine(from, "..|>", to, e.FromMultiplicity, e.ToMultiplicity, e.Label);
                case IxEdgeType.Composition:
                    return EdgeLine(from, "*--", to, e.FromMultiplicity, e.ToMultiplicity, e.Label);
                case IxEdgeType.Aggregation:
                    return EdgeLine(from, "o--", to, e.FromMultiplicity, e.ToMultiplicity, e.Label);
                case IxEdgeType.DirectedAssociation:
                    return EdgeLine(from, "-->", to, e.FromMultiplicity, e.ToMultiplicity, e.Label);
                case IxEdgeType.Dependency:
                    return EdgeLine(from, "..>", to, e.FromMultiplicity, e.ToMultiplicity, e.Label);
                default: // Association, Unknown
                    return EdgeLine(from, "--", to, e.FromMultiplicity, e.ToMultiplicity, e.Label);
            }
        }

        private static string EdgeLine(string left, string arrow, string right, string lMult, string rMult, string label)
        {
            var sb = new StringBuilder();
            sb.Append(left).Append(' ');
            if (!string.IsNullOrEmpty(lMult)) sb.Append('"').Append(lMult).Append("\" ");
            sb.Append(arrow).Append(' ');
            if (!string.IsNullOrEmpty(rMult)) sb.Append('"').Append(rMult).Append("\" ");
            sb.Append(right);
            if (!string.IsNullOrEmpty(label)) sb.Append(" : ").Append(label);
            return sb.ToString();
        }

        // --- styling (deterministic) -----------------------------------------------------------

        private static void EmitStyling(StringBuilder sb, List<IxElement> ordered, Dictionary<string, string> ident)
        {
            var groups = new List<Group>();
            var byColor = new Dictionary<string, Group>();
            foreach (var el in ordered)
            {
                if (el == null || el.Id == null) continue;
                if (el.FillColor == null && el.LineColor == null && el.TextColor == null) continue;
                if (!ident.TryGetValue(el.Id, out var id)) continue;
                string key = (el.FillColor ?? "") + "|" + (el.LineColor ?? "") + "|" + (el.TextColor ?? "");
                if (!byColor.TryGetValue(key, out var g))
                {
                    g = new Group { Fill = el.FillColor, Line = el.LineColor, Text = el.TextColor };
                    byColor[key] = g;
                    groups.Add(g);
                }
                g.Members.Add(id);
                g.Styles.Add(el.StyleClass);
            }
            if (groups.Count == 0) return;

            // Name each group: reuse a unanimous, unique StyleClass; otherwise a generated styleN.
            var nameCount = new Dictionary<string, int>();
            foreach (var g in groups) { var c = Unanimous(g); if (c != null) nameCount[c] = nameCount.TryGetValue(c, out var n) ? n + 1 : 1; }

            var used = new HashSet<string>();
            int counter = 0;
            foreach (var g in groups)
            {
                string cand = Unanimous(g);
                if (cand != null && nameCount[cand] == 1 && !used.Contains(cand)) g.Name = cand;
                else { do { counter++; g.Name = "style" + counter; } while (used.Contains(g.Name)); }
                used.Add(g.Name);
            }

            sb.Append('\n');
            foreach (var g in groups)
            {
                sb.Append("    classDef ").Append(g.Name);
                var props = new List<string>();
                if (g.Fill != null) props.Add("fill:" + g.Fill);
                if (g.Line != null) props.Add("stroke:" + g.Line);
                if (g.Text != null) props.Add("color:" + g.Text);
                sb.Append(' ').Append(string.Join(",", props)).Append('\n');
            }

            var assigns = new List<(string id, string style)>();
            foreach (var g in groups) foreach (var id in g.Members) assigns.Add((id, g.Name));
            assigns.Sort((a, b) => string.CompareOrdinal(a.id, b.id));
            foreach (var a in assigns) sb.Append("    class ").Append(a.id).Append(' ').Append(a.style).Append('\n');
        }

        private static string Unanimous(Group g)
        {
            string first = null;
            foreach (var s in g.Styles)
            {
                if (string.IsNullOrEmpty(s)) return null;
                if (first == null) first = s;
                else if (first != s) return null;
            }
            return first;
        }

        // --- identifiers -----------------------------------------------------------------------

        private static Dictionary<string, string> BuildIdents(IxModel model)
        {
            var map = new Dictionary<string, string>();
            var used = new HashSet<string>();
            foreach (var el in model.Elements)
            {
                if (el == null || el.Id == null || map.ContainsKey(el.Id)) continue;
                map[el.Id] = Sanitize(el.Name ?? el.Id, used);
            }
            return map;
        }

        // Emitted class header: bare id, or Id["Display"] when the name is not a bare identifier.
        private static string DeclName(IxElement el, Dictionary<string, string> ident)
        {
            string id = ident[el.Id];
            if (el.Name != null && el.Name != id) return id + "[\"" + el.Name.Replace("\"", "'") + "\"]";
            return id;
        }

        private static string Sanitize(string name, HashSet<string> used)
        {
            string baseId;
            if (BareIdRx.IsMatch(name)) baseId = name;
            else
            {
                baseId = Regex.Replace(name, @"[^A-Za-z0-9_]", "_");
                if (baseId.Length == 0 || !(char.IsLetter(baseId[0]) || baseId[0] == '_')) baseId = "n" + baseId;
            }
            string candidate = baseId;
            int k = 1;
            while (used.Contains(candidate)) candidate = baseId + "_" + k++;
            used.Add(candidate);
            return candidate;
        }

        // --- notes -----------------------------------------------------------------------------

        // Every element this note links to, as emitted idents, in edge order (a note may target many).
        private static List<string> NoteTargets(IxModel model, IxElement note, Dictionary<string, string> ident)
        {
            var outp = new List<string>();
            foreach (var e in model.Edges)
            {
                if (e == null || e.Type != IxEdgeType.NoteLink) continue;
                string other = e.FromId == note.Id ? e.ToId : (e.ToId == note.Id ? e.FromId : null);
                if (other != null && ident.TryGetValue(other, out var tid)) outp.Add(tid);
            }
            return outp;
        }

        // --- small helpers ---------------------------------------------------------------------

        internal static string GenericsOut(string s) =>
            string.IsNullOrEmpty(s) ? s : GenericsOutRx.Replace(s, "~$1~");

        private static char VisChar(IxVisibility v)
        {
            switch (v)
            {
                case IxVisibility.Private: return '-';
                case IxVisibility.Protected: return '#';
                case IxVisibility.Package: return '~';
                default: return '+';
            }
        }

        private static string EscapeNote(string s) =>
            s == null ? "" : s.Replace("\"", "'").Replace("\r\n", "\\n").Replace("\n", "\\n");

        private sealed class Group
        {
            public string Fill, Line, Text, Name;
            public readonly List<string> Members = new List<string>();
            public readonly List<string> Styles = new List<string>();
        }
    }
}
