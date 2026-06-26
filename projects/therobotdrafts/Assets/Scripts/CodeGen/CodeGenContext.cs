using System.Collections.Generic;
using System.Text;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.CodeGen
{
    /// <summary>
    /// Everything the code generator needs about one element: its identity (name / kind / language / stereotype /
    /// abstract), its members (attribute + operation signature strings as the model stores them), the text of any
    /// UML notes attached to it, and its relationships to other elements (collaborators it uses, callers, and the
    /// base classes / interfaces it extends or implements). Plain data — the UmlCanvas partial walks the model to
    /// populate it. <see cref="ToPromptString"/> renders it as a structured block for the LLM, and the deterministic
    /// <see cref="CodeSkeleton"/> consumes the same fields for the offline fallback.
    /// </summary>
    public sealed class CodeGenContext
    {
        public string Name;
        public ElementKind Kind;
        public string Language;     // null/empty ⇒ unspecified (skeleton defaults to C#)
        public string Stereotype;   // raw custom stereotype, no guillemets; null/empty ⇒ none
        public bool IsAbstract;
        public string Description;  // UML/product description; null/empty ⇒ none
        public string CodeDoc;      // source-code doc-comment text; null/empty ⇒ fallback to Description

        /// <summary>
        /// The original source file's full text when this element was imported from a file (overlay round-trip).
        /// Null/empty ⇒ no stored source, so generation falls back to from-scratch synthesis.
        /// </summary>
        public string OriginalSource;

        /// <summary>The path the original source came from (the element's SourceFile); null ⇒ none. For status text only.</summary>
        public string OriginalSourcePath;

        public readonly List<string> Attributes = new();   // full signatures, e.g. "- id : Guid"
        public readonly List<string> Operations = new();    // full signatures, e.g. "+ submit() : void"
        // Per-member doc-comments, index-aligned with Attributes / Operations (empty string ⇒ no comment).
        public readonly List<string> AttributeComments = new();
        public readonly List<string> OperationComments = new();
        public readonly List<string> AttachedNotes = new(); // verbatim note texts linked via NoteLink

        /// <summary>The doc-comment for the i-th attribute, or "" if none / out of range (ragged-list safe).</summary>
        public string AttributeComment(int i) =>
            i >= 0 && i < AttributeComments.Count ? AttributeComments[i] ?? "" : "";

        /// <summary>The doc-comment for the i-th operation, or "" if none / out of range.</summary>
        public string OperationComment(int i) =>
            i >= 0 && i < OperationComments.Count ? OperationComments[i] ?? "" : "";

        public readonly List<Relationship> Relationships = new();

        /// <summary>How an element relates to a collaborator (a supertype, an interface, a used type, or a caller).</summary>
        public enum RelKind { Extends, Implements, Uses, UsedBy }

        public enum RelDirection { Out, In }

        /// <summary>One relationship to another element, with the other end's identity, role, and its member API.</summary>
        public sealed class Relationship
        {
            public RelKind Kind;
            public RelDirection Direction;
            public EdgeKind Edge;
            public string OtherName;
            public ElementKind OtherKind;
            public string Label;            // association name / role; null/empty ⇒ none
            public string SrcMultiplicity;  // multiplicity at this element's end
            public string TgtMultiplicity;  // multiplicity at the other element's end
            // The collaborator's own member signatures, so the LLM knows the API it calls into / extends.
            public readonly List<string> OtherAttributes = new();
            public readonly List<string> OtherOperations = new();
        }

        /// <summary>Render the context as a clear, structured text block the LLM can follow.</summary>
        public string ToPromptString()
        {
            var sb = new StringBuilder();
            string lang = string.IsNullOrWhiteSpace(Language) ? "C#" : Language.Trim();

            sb.Append("Target language: ").Append(lang).Append('\n');
            sb.Append("Element name: ").Append(Name).Append('\n');
            sb.Append("Element kind: ").Append(Kind).Append('\n');
            if (IsAbstract) sb.Append("Modifier: abstract\n");
            if (!string.IsNullOrWhiteSpace(Stereotype)) sb.Append("Stereotype: «").Append(Stereotype.Trim()).Append("»\n");

            if (!string.IsNullOrWhiteSpace(Description))
                sb.Append("\nUML description:\n").Append(Description.Trim()).Append('\n');

            if (!string.IsNullOrWhiteSpace(CodeDoc))
                sb.Append("\nCode documentation comment:\n").Append(CodeDoc.Trim()).Append('\n');

            if (Attributes.Count > 0)
            {
                sb.Append("\nAttributes (fields), in UML signature form (with their doc-comments):\n");
                for (int i = 0; i < Attributes.Count; i++)
                {
                    sb.Append("  ").Append(Attributes[i]).Append('\n');
                    string c = AttributeComment(i);
                    if (!string.IsNullOrWhiteSpace(c)) sb.Append("      // ").Append(c.Replace("\n", " ").Trim()).Append('\n');
                }
            }

            if (Operations.Count > 0)
            {
                sb.Append("\nOperations (methods), in UML signature form (with their doc-comments):\n");
                for (int i = 0; i < Operations.Count; i++)
                {
                    sb.Append("  ").Append(Operations[i]).Append('\n');
                    string c = OperationComment(i);
                    if (!string.IsNullOrWhiteSpace(c)) sb.Append("      // ").Append(c.Replace("\n", " ").Trim()).Append('\n');
                }
            }

            if (AttachedNotes.Count > 0)
            {
                sb.Append("\nAttached UML notes / constraints:\n");
                foreach (var n in AttachedNotes)
                {
                    // Indent every line of a multi-line note so the block reads as one item.
                    foreach (var line in n.Replace("\r\n", "\n").Split('\n'))
                        sb.Append("  ").Append(line).Append('\n');
                    sb.Append('\n');
                }
            }

            if (Relationships.Count > 0)
            {
                sb.Append("\nRelationships:\n");
                foreach (var r in Relationships)
                {
                    sb.Append("  - ").Append(DescribeRelationship(r)).Append('\n');
                    AppendMemberLines(sb, "      field", r.OtherAttributes);
                    AppendMemberLines(sb, "      method", r.OtherOperations);
                }
            }

            return sb.ToString();
        }

        private static void AppendMemberLines(StringBuilder sb, string prefix, List<string> members)
        {
            foreach (var m in members) sb.Append(prefix).Append(": ").Append(m).Append('\n');
        }

        private static string DescribeRelationship(Relationship r)
        {
            var sb = new StringBuilder();
            switch (r.Kind)
            {
                case RelKind.Extends:
                    sb.Append("extends ");
                    break;
                case RelKind.Implements:
                    sb.Append("implements interface ");
                    break;
                case RelKind.UsedBy:
                    sb.Append("is used by ");
                    break;
                default:
                    sb.Append("uses ");
                    break;
            }
            sb.Append(r.OtherName).Append(" (").Append(r.OtherKind).Append(')');
            if (!string.IsNullOrWhiteSpace(r.Label)) sb.Append(" — role \"").Append(r.Label.Trim()).Append('"');

            string src = string.IsNullOrWhiteSpace(r.SrcMultiplicity) ? null : r.SrcMultiplicity.Trim();
            string tgt = string.IsNullOrWhiteSpace(r.TgtMultiplicity) ? null : r.TgtMultiplicity.Trim();
            if (src != null || tgt != null)
                sb.Append(" [").Append(src ?? "?").Append(" .. ").Append(tgt ?? "?").Append(']');

            return sb.ToString();
        }
    }
}
