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
    /// Aliasing: PlantUML aliases and relationship endpoints must be legal identifiers, but an IxElement.Id is an
    /// arbitrary format-local key (a QEA <c>ea_guid</c> like <c>{B34F..}</c> would be illegal — braces collide with
    /// the block-open <c>{</c>). So every element gets a legal alias derived from its display name (sanitized to
    /// <c>[A-Za-z0-9_]</c>, collisions disambiguated with a numeric suffix); the raw Id is never emitted. A name that
    /// is already a legal identifier needs no <c>as</c> clause. Every relationship / note-link references the bare
    /// alias — never quoted display text.
    ///
    /// Emission order: <c>@startuml</c> + <c>hide empty members</c>; every classifier declared once, grouped into
    /// nested <c>package</c> blocks; then floating notes; then relationships; then note links; then <c>@enduml</c>.
    /// Members are composed from the structured IR fields (never RawText) — fields before methods, each with a
    /// visibility glyph and leading <c>{static}</c>/<c>{abstract}</c> modifiers (the reader only recognizes modifiers
    /// ahead of the visibility glyph).
    /// </summary>
    public static class PlantUmlWriter
    {
        private const int MaxAliasLength = 64;

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

            Dictionary<string, string> aliasOf = BuildAliases(model);

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
                WriteElement(sb, el, childrenOf, aliasOf, 0);
            }

            // Floating notes.
            bool wroteNote = false;
            foreach (IxElement el in model.Elements)
            {
                if (el != null && el.Type == IxElementType.Note)
                {
                    WriteNote(sb, el, aliasOf);
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
                WriteEdge(sb, edge, aliasOf);
                wroteEdge = true;
            }
            foreach (IxEdge edge in noteLinks)
            {
                sb.Append(EndpointRef(edge.FromId, aliasOf)).Append(" .. ").Append(EndpointRef(edge.ToId, aliasOf)).Append('\n');
                wroteEdge = true;
            }
            if (wroteEdge)
            {
                sb.Append('\n');
            }

            sb.Append("@enduml\n");
            return sb.ToString();
        }

        // ------------------------------------------------------------------ aliases

        // Assigns each element (and any dangling edge endpoint) a unique, PlantUML-legal alias derived from its
        // display name. Deterministic: elements are processed in model order.
        private static Dictionary<string, string> BuildAliases(IxModel model)
        {
            var aliasOf = new Dictionary<string, string>(StringComparer.Ordinal);
            // Case-insensitive: the reader resolves aliases case-insensitively, so "User" and "user" must not both
            // be handed out (they would merge into one element on re-import).
            var used = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            foreach (IxElement el in model.Elements)
            {
                if (el == null || string.IsNullOrEmpty(el.Id) || aliasOf.ContainsKey(el.Id))
                {
                    continue;
                }
                // Prefer the Id when it's already a legal identifier (keeps aliases — and thus round-tripped Ids —
                // stable); otherwise derive one from the display name, or a plain "Note" for notes (whose display
                // text is the whole documentation body).
                string basis = IsPlainIdentifier(el.Id)
                    ? el.Id
                    : (el.Type == IxElementType.Note ? "Note" : DisplayName(el));
                aliasOf[el.Id] = MakeUniqueAlias(basis, used);
            }

            // Edge endpoints that aren't declared elements still need a legal token to reference.
            foreach (IxEdge edge in model.Edges)
            {
                if (edge == null)
                {
                    continue;
                }
                RegisterDangling(edge.FromId, aliasOf, used);
                RegisterDangling(edge.ToId, aliasOf, used);
            }
            return aliasOf;
        }

        private static void RegisterDangling(string id, Dictionary<string, string> aliasOf, HashSet<string> used)
        {
            if (!string.IsNullOrEmpty(id) && !aliasOf.ContainsKey(id))
            {
                aliasOf[id] = MakeUniqueAlias(id, used);
            }
        }

        // PlantUML statement/element keywords (lowercase). An alias equal to one of these would be re-read as a
        // statement (e.g. `note .. X` parsed as a note, `class .. X` as a declaration), so such aliases get a
        // trailing underscore. The reader matches keywords case-sensitively, so only a lowercase collision matters.
        private static readonly HashSet<string> Reserved = new HashSet<string>(StringComparer.Ordinal)
        {
            "class", "abstract", "interface", "enum", "struct", "entity", "actor", "usecase", "state",
            "component", "node", "database", "cloud", "artifact", "file", "boundary", "control", "collections",
            "queue", "rectangle", "frame", "package", "folder", "namespace", "participant", "object", "card",
            "agent", "storage", "note", "rnote", "hnote", "title", "skinparam", "hide", "show", "remove",
            "restore", "scale", "legend", "together", "page", "left", "right", "up", "down",
        };

        private static string MakeUniqueAlias(string basis, HashSet<string> used)
        {
            string candidate = Sanitize(basis);
            if (candidate.Length == 0)
            {
                candidate = "e";
            }
            if (Reserved.Contains(candidate))
            {
                candidate += "_";
            }
            string unique = candidate;
            int n = 2;
            while (used.Contains(unique))
            {
                unique = candidate + "_" + n;
                n++;
            }
            used.Add(unique);
            return unique;
        }

        // Collapses any run of characters outside [A-Za-z0-9_] to a single underscore, trims underscores, prefixes a
        // leading digit, and caps the length.
        private static string Sanitize(string s)
        {
            if (string.IsNullOrEmpty(s))
            {
                return "";
            }
            var sb = new StringBuilder(s.Length);
            bool pendingUnderscore = false;
            foreach (char c in s)
            {
                bool legal = (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_';
                if (legal)
                {
                    if (pendingUnderscore && sb.Length > 0)
                    {
                        sb.Append('_');
                    }
                    pendingUnderscore = false;
                    sb.Append(c);
                }
                else
                {
                    pendingUnderscore = true;
                }
            }
            string result = sb.ToString();
            if (result.Length > MaxAliasLength)
            {
                result = result.Substring(0, MaxAliasLength);
            }
            if (result.Length > 0 && result[0] >= '0' && result[0] <= '9')
            {
                result = "_" + result;
            }
            return result;
        }

        // ------------------------------------------------------------------ elements

        private static void WriteElement(StringBuilder sb, IxElement el,
            Dictionary<string, List<IxElement>> childrenOf, Dictionary<string, string> aliasOf, int depth)
        {
            string indent = new string(' ', depth * 2);
            string alias = AliasFor(el.Id, aliasOf);

            if (el.Type == IxElementType.Package)
            {
                sb.Append(indent).Append("package ").Append(DeclRef(el, alias)).Append(" {\n");
                if (childrenOf.TryGetValue(el.Id, out List<IxElement> kids))
                {
                    foreach (IxElement kid in kids)
                    {
                        WriteElement(sb, kid, childrenOf, aliasOf, depth + 1);
                    }
                }
                sb.Append(indent).Append("}\n");
                return;
            }

            sb.Append(indent).Append(Keyword(el)).Append(' ').Append(DeclRef(el, alias));

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

        // `Name` when the display name is a bare identifier that already equals the alias; otherwise
        // `"Display" as Alias`. The alias is always PlantUML-legal; the raw Id is never emitted.
        private static string DeclRef(IxElement el, string alias)
        {
            string generics = string.IsNullOrEmpty(el.GenericParams) ? "" : "<" + el.GenericParams + ">";
            string display = DisplayName(el);
            if (IsPlainIdentifier(display) && alias == display)
            {
                return display + generics;
            }
            return "\"" + QuoteSafe(display) + "\" as " + alias + generics;
        }

        // The display label to emit: the element's Name (or Id if unnamed), with a redundant trailing generic
        // suffix stripped — the reader keeps "<T>" in the re-read display name, but GenericParams re-emits it.
        private static string DisplayName(IxElement el)
        {
            string name = string.IsNullOrEmpty(el.Name) ? el.Id : el.Name;
            if (!string.IsNullOrEmpty(el.GenericParams))
            {
                name = Regex.Replace(name, @"\s*<[^<>]*>\s*$", "");
            }
            return name;
        }

        private static void WriteNote(StringBuilder sb, IxElement note, Dictionary<string, string> aliasOf)
        {
            string text = note.Documentation ?? note.Name ?? "";
            // The paired reader recognizes floating notes only in the single-line `note "…" as Id` form, so encode
            // every line-break variant (CRLF/CR/LF) as \n (the reader decodes it back). A raw CR left in the text
            // would otherwise be re-split into a second physical line and lose the note.
            string encoded = text.Replace("\"", "'").Replace("\r\n", "\\n").Replace("\r", "\\n").Replace("\n", "\\n");
            sb.Append("note \"").Append(encoded).Append("\" as ").Append(AliasFor(note.Id, aliasOf)).Append('\n');
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

        private static void WriteEdge(StringBuilder sb, IxEdge edge, Dictionary<string, string> aliasOf)
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

            sb.Append(EndpointRef(edge.FromId, aliasOf));
            if (!string.IsNullOrEmpty(edge.FromMultiplicity))
            {
                sb.Append(" \"").Append(edge.FromMultiplicity).Append('"');
            }
            sb.Append(' ').Append(arrow).Append(' ');
            if (!string.IsNullOrEmpty(edge.ToMultiplicity))
            {
                sb.Append('"').Append(edge.ToMultiplicity).Append("\" ");
            }
            sb.Append(EndpointRef(edge.ToId, aliasOf));

            string label = trailingLabel ?? edge.Label;
            if (!string.IsNullOrEmpty(label))
            {
                sb.Append(" : ").Append(label);
            }
            sb.Append('\n');
        }

        // The bare, PlantUML-legal alias for an endpoint — never quoted display text, never a raw Id.
        private static string EndpointRef(string id, Dictionary<string, string> aliasOf)
        {
            return AliasFor(id, aliasOf);
        }

        private static string AliasFor(string id, Dictionary<string, string> aliasOf)
        {
            if (string.IsNullOrEmpty(id))
            {
                return "_";
            }
            if (aliasOf.TryGetValue(id, out string alias))
            {
                return alias;
            }
            string sanitized = Sanitize(id);
            return sanitized.Length == 0 ? "_" : sanitized;
        }

        // ------------------------------------------------------------------ helpers

        private static string QuoteSafe(string s)
        {
            return s == null ? "" : s.Replace("\"", "'").Replace("\n", "\\n");
        }

        private static bool IsPlainIdentifier(string s)
        {
            return !string.IsNullOrEmpty(s) && Regex.IsMatch(s, @"^[A-Za-z_][A-Za-z0-9_]*$");
        }
    }
}
