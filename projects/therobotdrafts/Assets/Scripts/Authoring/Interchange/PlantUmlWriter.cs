using System;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;

namespace TheRobotDraft.Authoring.Interchange
{
    /// <summary>
    /// Deterministic, minimal PlantUML class-diagram writer — the export half of the docs/formats/plantuml-format.md
    /// §9 contract and the inverse of <see cref="PlantUmlReader"/> for the class-diagram profile. Output is stable
    /// (model order is preserved, colors are never invented) so exports diff cleanly and re-import losslessly.
    ///
    /// Emission order: <c>@startuml</c> + <c>hide empty members</c>; then every classifier declared once, grouped
    /// into nested <c>package</c> blocks; then floating notes; then relationships; then note links; then
    /// <c>@enduml</c>. Members are composed from the structured IR fields (never from RawText) for determinism —
    /// fields before methods, each with visibility glyph and leading <c>{static}</c>/<c>{abstract}</c> modifiers
    /// (the reader only recognizes modifiers ahead of the visibility glyph, so they are emitted there).
    /// </summary>
    public static class PlantUmlWriter
    {
        public static string Write(IxModel model)
        {
            if (model == null)
            {
                throw new InterchangeException("cannot write a null IxModel to PlantUML");
            }

            var sb = new StringBuilder();
            sb.Append("@startuml");
            if (!string.IsNullOrEmpty(model.Name))
            {
                sb.Append(' ').Append(model.Name);
            }
            sb.Append('\n');
            sb.Append("hide empty members\n");
            sb.Append('\n');

            var byId = new Dictionary<string, IxElement>(StringComparer.Ordinal);
            foreach (IxElement el in model.Elements)
            {
                if (el != null && !string.IsNullOrEmpty(el.Id) && !byId.ContainsKey(el.Id))
                {
                    byId[el.Id] = el;
                }
            }

            // Children grouped by container id, preserving model order.
            var childrenOf = new Dictionary<string, List<IxElement>>(StringComparer.Ordinal);
            var roots = new List<IxElement>();
            foreach (IxElement el in model.Elements)
            {
                if (el == null || el.Type == IxElementType.Note)
                {
                    continue; // notes are emitted separately, never as classifier declarations
                }
                string parent = el.ParentId;
                bool nested = !string.IsNullOrEmpty(parent) && byId.TryGetValue(parent, out IxElement p)
                              && p.Type == IxElementType.Package;
                if (nested)
                {
                    if (!childrenOf.TryGetValue(parent, out List<IxElement> list))
                    {
                        list = new List<IxElement>();
                        childrenOf[parent] = list;
                    }
                    list.Add(el);
                }
                else
                {
                    roots.Add(el);
                }
            }

            foreach (IxElement el in roots)
            {
                WriteElement(sb, el, childrenOf, 0);
            }

            // Floating notes.
            bool wroteNote = false;
            foreach (IxElement el in model.Elements)
            {
                if (el != null && el.Type == IxElementType.Note)
                {
                    WriteNote(sb, el);
                    wroteNote = true;
                }
            }
            if (wroteNote)
            {
                sb.Append('\n');
            }

            // Relationships first, then note links (both in model order).
            var noteLinks = new List<IxEdge>();
            bool wroteEdge = false;
            foreach (IxEdge edge in model.Edges)
            {
                if (edge == null)
                {
                    continue;
                }
                if (edge.Type == IxEdgeType.NoteLink)
                {
                    noteLinks.Add(edge);
                    continue;
                }
                WriteEdge(sb, edge);
                wroteEdge = true;
            }
            foreach (IxEdge edge in noteLinks)
            {
                sb.Append(EndpointRef(edge.FromId)).Append(" .. ").Append(EndpointRef(edge.ToId)).Append('\n');
                wroteEdge = true;
            }
            if (wroteEdge)
            {
                sb.Append('\n');
            }

            sb.Append("@enduml\n");
            return sb.ToString();
        }

        // ------------------------------------------------------------------ elements

        private static void WriteElement(StringBuilder sb, IxElement el,
            Dictionary<string, List<IxElement>> childrenOf, int depth)
        {
            string indent = new string(' ', depth * 2);

            if (el.Type == IxElementType.Package)
            {
                sb.Append(indent).Append("package ").Append(NameRef(el)).Append(" {\n");
                if (childrenOf.TryGetValue(el.Id, out List<IxElement> kids))
                {
                    foreach (IxElement kid in kids)
                    {
                        WriteElement(sb, kid, childrenOf, depth + 1);
                    }
                }
                sb.Append(indent).Append("}\n");
                return;
            }

            sb.Append(indent).Append(Keyword(el)).Append(' ').Append(NameRef(el));

            string stereotype = StereotypeFor(el);
            if (!string.IsNullOrEmpty(stereotype))
            {
                sb.Append(" <<").Append(stereotype).Append(">>");
            }

            bool hasBody = el.EnumLiterals.Count > 0 || el.Members.Count > 0;
            if (!hasBody)
            {
                sb.Append('\n');
                return;
            }

            sb.Append(" {\n");
            string memberIndent = indent + "  ";
            foreach (string literal in el.EnumLiterals)
            {
                sb.Append(memberIndent).Append(literal).Append('\n');
            }
            foreach (IxMember m in el.Members)
            {
                if (m != null && !m.IsOperation)
                {
                    sb.Append(memberIndent).Append(MemberText(m)).Append('\n');
                }
            }
            foreach (IxMember m in el.Members)
            {
                if (m != null && m.IsOperation)
                {
                    sb.Append(memberIndent).Append(MemberText(m)).Append('\n');
                }
            }
            sb.Append(indent).Append("}\n");
        }

        private static string Keyword(IxElement el)
        {
            switch (el.Type)
            {
                case IxElementType.Interface: return "interface";
                case IxElementType.Enum: return "enum";
                case IxElementType.Struct: return "struct";
                case IxElementType.Actor: return "actor";
                case IxElementType.Artifact: return "artifact";
                case IxElementType.Boundary: return "boundary";
                case IxElementType.Class:
                case IxElementType.DataType:
                case IxElementType.Table:
                case IxElementType.Unknown:
                default:
                    return el.IsAbstract ? "abstract class" : "class";
            }
        }

        private static string StereotypeFor(IxElement el)
        {
            if (el.Type == IxElementType.Table)
            {
                return string.IsNullOrEmpty(el.Stereotype) ? "table" : el.Stereotype;
            }
            return el.Stereotype;
        }

        // `Name` when the display name is a bare identifier equal to the id; otherwise `"Display" as Alias`.
        private static string NameRef(IxElement el)
        {
            string generics = string.IsNullOrEmpty(el.GenericParams) ? "" : "<" + el.GenericParams + ">";
            if (!string.IsNullOrEmpty(el.Name) && el.Name == el.Id && IsPlainIdentifier(el.Name))
            {
                return el.Name + generics;
            }
            string display = string.IsNullOrEmpty(el.Name) ? el.Id : el.Name;
            return "\"" + display + "\" as " + el.Id + generics;
        }

        private static void WriteNote(StringBuilder sb, IxElement note)
        {
            string text = note.Documentation ?? note.Name ?? "";
            // The paired reader recognizes floating notes only in the single-line `note "…" as Id` form, so encode
            // embedded newlines as \n rather than emitting a block that would not be read back.
            string encoded = text.Replace("\n", "\\n").Replace("\"", "'");
            sb.Append("note \"").Append(encoded).Append("\" as ").Append(note.Id).Append('\n');
        }

        // ------------------------------------------------------------------ members

        private static string MemberText(IxMember m)
        {
            var sb = new StringBuilder();
            if (m.IsStatic)
            {
                sb.Append("{static} ");
            }
            if (m.IsAbstract)
            {
                sb.Append("{abstract} ");
            }
            sb.Append(VisibilityGlyph(m.Visibility)).Append(' ');
            sb.Append(string.IsNullOrEmpty(m.Name) ? "" : m.Name);

            if (m.IsOperation)
            {
                sb.Append('(');
                for (int i = 0; i < m.Parameters.Count; i++)
                {
                    if (i > 0)
                    {
                        sb.Append(", ");
                    }
                    IxParam p = m.Parameters[i];
                    sb.Append(p.Name);
                    if (!string.IsNullOrEmpty(p.Type))
                    {
                        sb.Append(": ").Append(p.Type);
                    }
                    if (!string.IsNullOrEmpty(p.DefaultValue))
                    {
                        sb.Append(" = ").Append(p.DefaultValue);
                    }
                }
                sb.Append(')');
                if (!string.IsNullOrEmpty(m.Type))
                {
                    sb.Append(" : ").Append(m.Type);
                }
            }
            else
            {
                if (!string.IsNullOrEmpty(m.Type))
                {
                    sb.Append(" : ").Append(m.Type);
                }
                if (!string.IsNullOrEmpty(m.DefaultValue))
                {
                    sb.Append(" = ").Append(m.DefaultValue);
                }
            }
            return sb.ToString();
        }

        private static string VisibilityGlyph(IxVisibility v)
        {
            switch (v)
            {
                case IxVisibility.Private: return "-";
                case IxVisibility.Protected: return "#";
                case IxVisibility.Package: return "~";
                default: return "+";
            }
        }

        // ------------------------------------------------------------------ relationships

        private static void WriteEdge(StringBuilder sb, IxEdge edge)
        {
            string arrow;
            string trailingLabel = null;
            switch (edge.Type)
            {
                case IxEdgeType.Generalization: arrow = "--|>"; break;
                case IxEdgeType.Realization: arrow = "..|>"; break;
                case IxEdgeType.Composition: arrow = "*--"; break;
                case IxEdgeType.Aggregation: arrow = "o--"; break;
                case IxEdgeType.DirectedAssociation: arrow = "-->"; break;
                case IxEdgeType.Dependency: arrow = "..>"; break;
                case IxEdgeType.Extension: arrow = "..>"; trailingLabel = "<<extension>>"; break;
                case IxEdgeType.Association: arrow = "--"; break;
                case IxEdgeType.Unknown:
                default: arrow = "--"; break;
            }

            sb.Append(EndpointRef(edge.FromId));
            if (!string.IsNullOrEmpty(edge.FromMultiplicity))
            {
                sb.Append(" \"").Append(edge.FromMultiplicity).Append('"');
            }
            sb.Append(' ').Append(arrow).Append(' ');
            if (!string.IsNullOrEmpty(edge.ToMultiplicity))
            {
                sb.Append('"').Append(edge.ToMultiplicity).Append("\" ");
            }
            sb.Append(EndpointRef(edge.ToId));

            string label = trailingLabel ?? edge.Label;
            if (!string.IsNullOrEmpty(label))
            {
                sb.Append(" : ").Append(label);
            }
            sb.Append('\n');
        }

        private static string EndpointRef(string id)
        {
            if (string.IsNullOrEmpty(id))
            {
                return "\"\"";
            }
            return IsPlainIdentifier(id) ? id : "\"" + id + "\"";
        }

        // ------------------------------------------------------------------ helpers

        private static bool IsPlainIdentifier(string s)
        {
            return !string.IsNullOrEmpty(s) && Regex.IsMatch(s, @"^[A-Za-z_][A-Za-z0-9_]*$");
        }
    }
}
