using System;
using System.Text;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Uml
{
    /// <summary>UML member visibility (Rational Rose / Sparx EA "scope"): the leading glyph on an attribute or operation.</summary>
    public enum UmlVisibility { Public, Private, Protected, Package }

    public static class UmlVisibilityExt
    {
        public static char Glyph(this UmlVisibility v) => v switch
        {
            UmlVisibility.Public => '+',
            UmlVisibility.Private => '-',
            UmlVisibility.Protected => '#',
            UmlVisibility.Package => '~',
            _ => '+',
        };

        public static string Label(this UmlVisibility v) => v switch
        {
            UmlVisibility.Public => "+ public",
            UmlVisibility.Private => "- private",
            UmlVisibility.Protected => "# protected",
            UmlVisibility.Package => "~ package",
            _ => "+ public",
        };

        public static UmlVisibility FromGlyph(char c) => c switch
        {
            '+' => UmlVisibility.Public,
            '-' => UmlVisibility.Private,
            '#' => UmlVisibility.Protected,
            '~' => UmlVisibility.Package,
            _ => UmlVisibility.Public,
        };
    }

    /// <summary>
    /// The structured form of a member signature, decomposed from / composed to the canonical Rose/Sparx text
    /// convention the model stores verbatim in <see cref="ModelElement.Name"/> — e.g. <c>- balance : decimal</c>
    /// or <c>+ deposit(amount : decimal) : void {abstract}</c>. The view's structured editor builds and reads
    /// this so the user picks visibility/type/params from controls instead of hand-typing UML punctuation.
    /// </summary>
    public struct MemberParts
    {
        public UmlVisibility Visibility;
        public string Name;
        public string Type;        // attribute type, OR operation return type
        public string Parameters;  // operation only: "amount : decimal, note : string"
        public string DefaultValue; // attribute only: initial value after '='
        public bool IsStatic;
        public bool IsAbstract;

        /// <summary>Rose/Sparx defaults for a freshly added member: attributes are private, operations public.</summary>
        public static MemberParts ForNew(ElementKind kind) => new MemberParts
        {
            Visibility = kind == ElementKind.Field ? UmlVisibility.Private : UmlVisibility.Public,
            Name = kind == ElementKind.Field ? "field" : "operation",
            Type = kind == ElementKind.Field ? "" : "void",
            Parameters = "",
            DefaultValue = "",
        };
    }

    /// <summary>
    /// Compose / parse the canonical UML member signature string used by Rational Rose, Sparx EA, and most UML
    /// tools. Pure C# (no Unity dependency) so it unit-tests directly and round-trips through the editor.
    /// </summary>
    public static class UmlMemberSignature
    {
        public static string Compose(ElementKind kind, in MemberParts p)
        {
            var sb = new StringBuilder();
            string name = Safe(p.Name, kind == ElementKind.Field ? "field" : "operation");
            sb.Append(p.Visibility.Glyph()).Append(' ').Append(name);

            if (kind == ElementKind.Function)
            {
                sb.Append('(').Append((p.Parameters ?? "").Trim()).Append(')');
                string ret = (p.Type ?? "").Trim();
                // Convention (Rose / Sparx / Visual Paradigm): a void return is implied — show only non-void.
                if (ret.Length > 0 && !ret.Equals("void", StringComparison.OrdinalIgnoreCase))
                    sb.Append(" : ").Append(ret);
            }
            else
            {
                string type = (p.Type ?? "").Trim();
                if (type.Length > 0) sb.Append(" : ").Append(type);
                string def = (p.DefaultValue ?? "").Trim();
                if (def.Length > 0) sb.Append(" = ").Append(def);
            }

            string mods = Modifiers(p);
            if (mods.Length > 0) sb.Append(" {").Append(mods).Append('}');
            return sb.ToString();
        }

        private static string Modifiers(in MemberParts p)
        {
            if (p.IsStatic && p.IsAbstract) return "static, abstract";
            if (p.IsStatic) return "static";
            if (p.IsAbstract) return "abstract";
            return "";
        }

        public static MemberParts Parse(ElementKind kind, string signature)
        {
            var parts = MemberParts.ForNew(kind);
            if (string.IsNullOrWhiteSpace(signature)) return parts;
            string s = signature.Trim();

            // Trailing modifiers: {static, abstract}.
            int brace = s.IndexOf('{');
            if (brace >= 0)
            {
                int close = s.IndexOf('}', brace + 1);
                string inside = close > brace ? s.Substring(brace + 1, close - brace - 1) : s.Substring(brace + 1);
                parts.IsStatic = inside.IndexOf("static", StringComparison.OrdinalIgnoreCase) >= 0;
                parts.IsAbstract = inside.IndexOf("abstract", StringComparison.OrdinalIgnoreCase) >= 0;
                s = s.Substring(0, brace).Trim();
            }

            // Leading visibility glyph.
            if (s.Length > 0 && "+-#~".IndexOf(s[0]) >= 0)
            {
                parts.Visibility = UmlVisibilityExt.FromGlyph(s[0]);
                s = s.Substring(1).Trim();
            }

            if (kind == ElementKind.Function)
            {
                int open = s.IndexOf('(');
                if (open >= 0)
                {
                    parts.Name = s.Substring(0, open).Trim();
                    int close = s.IndexOf(')', open + 1);
                    if (close > open)
                    {
                        parts.Parameters = s.Substring(open + 1, close - open - 1).Trim();
                        string rest = s.Substring(close + 1).Trim();
                        if (rest.StartsWith(":")) parts.Type = rest.Substring(1).Trim();
                    }
                    else
                    {
                        parts.Parameters = s.Substring(open + 1).Trim();
                    }
                }
                else
                {
                    SplitNameType(s, ref parts); // no parens typed — tolerate "name : ret"
                }
            }
            else
            {
                int eq = s.IndexOf('=');
                if (eq >= 0)
                {
                    parts.DefaultValue = s.Substring(eq + 1).Trim();
                    s = s.Substring(0, eq).Trim();
                }
                SplitNameType(s, ref parts);
            }

            if (string.IsNullOrWhiteSpace(parts.Name))
                parts.Name = kind == ElementKind.Field ? "field" : "operation";
            return parts;
        }

        private static void SplitNameType(string s, ref MemberParts parts)
        {
            int colon = s.IndexOf(':');
            if (colon >= 0)
            {
                parts.Name = s.Substring(0, colon).Trim();
                parts.Type = s.Substring(colon + 1).Trim();
            }
            else
            {
                parts.Name = s.Trim();
            }
        }

        private static string Safe(string s, string fallback) =>
            string.IsNullOrWhiteSpace(s) ? fallback : s.Trim();
    }
}
