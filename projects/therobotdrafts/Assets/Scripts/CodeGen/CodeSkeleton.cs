using System.Collections.Generic;
using System.Text;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.CodeGen
{
    /// <summary>
    /// A deterministic, offline source skeleton for a <see cref="CodeGenContext"/>. It parses the model's UML
    /// member signatures (Rose/Sparx form, e.g. "- id : Guid", "+ submit(amount : decimal) : void") into the
    /// target language's declaration grammar, emits the type declaration with its extends/implements list (from
    /// Generalization / Realization relationships), and renders the description + attached notes as a doc-comment
    /// header. This is both the no-LLM fallback and the seed shown in the viewer while the LLM runs. Supported
    /// languages: C#, Java, TypeScript, Python; anything else falls back to C#.
    /// </summary>
    public static class CodeSkeleton
    {
        private enum Lang { CSharp, Java, TypeScript, Python, Elixir }

        public static string Generate(CodeGenContext ctx)
        {
            Lang lang = Detect(ctx.Language);
            return lang switch
            {
                Lang.Java => GenerateJava(ctx),
                Lang.TypeScript => GenerateTypeScript(ctx),
                Lang.Python => GeneratePython(ctx),
                Lang.Elixir => GenerateElixir(ctx),
                _ => GenerateCSharp(ctx),
            };
        }

        private static Lang Detect(string language)
        {
            if (string.IsNullOrWhiteSpace(language)) return Lang.CSharp;
            string l = language.Trim().ToLowerInvariant();
            if (l.Contains("elixir") || l == "ex" || l == "exs" || l.Contains("erlang")) return Lang.Elixir;
            if (l.Contains("java") && !l.Contains("javascript")) return Lang.Java;
            if (l.Contains("typescript") || l == "ts" || l.Contains("node") || l.Contains("javascript") || l == "js")
                return Lang.TypeScript;
            if (l.Contains("python") || l == "py") return Lang.Python;
            return Lang.CSharp; // C#, C/C++, Rust, Go, … → closest C-family skeleton
        }

        // --- parsed member signature ---

        /// <summary>A UML member signature decomposed into the parts a code skeleton needs.</summary>
        private struct Member
        {
            public string Visibility;  // "+", "-", "#", "~" or ""
            public string Name;
            public string Type;        // field type, or operation return type; may be empty
            public string Parameters;  // operation parameter list (inside the parens), raw UML; empty for fields
            public bool IsOperation;
        }

        /// <summary>
        /// Parse "± name : Type" (field) or "± name(args) : ReturnType" (operation). Tolerant: missing pieces just
        /// come back empty so the skeleton can apply language defaults.
        /// </summary>
        private static Member ParseMember(string raw, bool isOperation)
        {
            var m = new Member { IsOperation = isOperation };
            string s = (raw ?? "").Trim();
            if (s.Length > 0 && (s[0] == '+' || s[0] == '-' || s[0] == '#' || s[0] == '~'))
            {
                m.Visibility = s[0].ToString();
                s = s.Substring(1).Trim();
            }

            // Split off the return / field type after the last top-level ':'.
            int colon = s.LastIndexOf(':');
            if (colon >= 0)
            {
                m.Type = s.Substring(colon + 1).Trim();
                s = s.Substring(0, colon).Trim();
            }

            int open = s.IndexOf('(');
            if (open >= 0)
            {
                m.IsOperation = true;
                int close = s.LastIndexOf(')');
                if (close > open) m.Parameters = s.Substring(open + 1, close - open - 1).Trim();
                m.Name = s.Substring(0, open).Trim();
            }
            else
            {
                m.Name = s;
            }
            return m;
        }

        private static List<Member> Parse(IEnumerable<string> sigs, bool isOperation)
        {
            var list = new List<Member>();
            foreach (var s in sigs) list.Add(ParseMember(s, isOperation));
            return list;
        }

        // --- supertype / interface lists from relationships ---

        private static void CollectBases(CodeGenContext ctx, out List<string> extends, out List<string> implements)
        {
            extends = new List<string>();
            implements = new List<string>();
            foreach (var r in ctx.Relationships)
            {
                if (r.Kind == CodeGenContext.RelKind.Extends && !string.IsNullOrEmpty(r.OtherName))
                    extends.Add(r.OtherName);
                else if (r.Kind == CodeGenContext.RelKind.Implements && !string.IsNullOrEmpty(r.OtherName))
                    implements.Add(r.OtherName);
            }
        }

        private static string Sanitize(string name) => string.IsNullOrWhiteSpace(name) ? "Generated" : name.Trim();

        // --- visibility mapping ---

        private static string CSharpVis(string v) => v switch
        {
            "-" => "private", "#" => "protected", "~" => "internal", _ => "public",
        };

        private static string JavaVis(string v) => v switch
        {
            "-" => "private", "#" => "protected", "~" => "", _ => "public",
        };

        // --- C# ---

        private static string GenerateCSharp(CodeGenContext ctx)
        {
            var sb = new StringBuilder();
            DocComment(sb, ctx, "/// ", "/// ", "/// ");
            CollectBases(ctx, out var extends, out var implements);

            string name = Sanitize(ctx.Name);
            string keyword = ctx.Kind switch
            {
                ElementKind.Interface => "interface",
                ElementKind.Enum => "enum",
                ElementKind.Struct => "struct",
                _ => "class",
            };

            sb.Append("public ");
            if (ctx.IsAbstract && keyword == "class") sb.Append("abstract ");
            sb.Append(keyword).Append(' ').Append(name);

            var bases = new List<string>(extends);
            bases.AddRange(implements);
            if (bases.Count > 0) sb.Append(" : ").Append(string.Join(", ", bases));
            sb.Append('\n').Append("{\n");

            if (ctx.Kind == ElementKind.Enum)
            {
                foreach (var f in ctx.Attributes)
                {
                    var m = ParseMember(f, false);
                    sb.Append("    ").Append(string.IsNullOrEmpty(m.Name) ? f.Trim() : m.Name).Append(",\n");
                }
            }
            else
            {
                var attrs = Parse(ctx.Attributes, false);
                for (int i = 0; i < attrs.Count; i++)
                {
                    var m = attrs[i];
                    string type = string.IsNullOrEmpty(m.Type) ? "object" : m.Type;
                    MemberDoc(sb, ctx.AttributeComment(i), "    /// ");
                    sb.Append("    ").Append(CSharpVis(m.Visibility)).Append(' ')
                      .Append(type).Append(' ').Append(m.Name).Append(" { get; set; }\n");
                }
                if (ctx.Attributes.Count > 0 && ctx.Operations.Count > 0) sb.Append('\n');
                var ops = Parse(ctx.Operations, true);
                for (int i = 0; i < ops.Count; i++)
                {
                    var m = ops[i];
                    string ret = string.IsNullOrEmpty(m.Type) ? "void" : m.Type;
                    MemberDoc(sb, ctx.OperationComment(i), "    /// ");
                    sb.Append("    ").Append(CSharpVis(m.Visibility)).Append(' ');
                    if (ctx.Kind == ElementKind.Interface)
                    {
                        sb.Append(ret).Append(' ').Append(m.Name).Append('(').Append(m.Parameters).Append(");\n");
                    }
                    else
                    {
                        if (ctx.IsAbstract) sb.Append("abstract ").Append(ret).Append(' ')
                            .Append(m.Name).Append('(').Append(m.Parameters).Append(");\n");
                        else
                        {
                            sb.Append(ret).Append(' ').Append(m.Name).Append('(').Append(m.Parameters).Append(")\n");
                            sb.Append("    {\n        // TODO: implement\n");
                            if (ret != "void") sb.Append("        throw new System.NotImplementedException();\n");
                            sb.Append("    }\n");
                        }
                    }
                }
            }

            sb.Append("}\n");
            return sb.ToString();
        }

        // --- Java ---

        private static string GenerateJava(CodeGenContext ctx)
        {
            var sb = new StringBuilder();
            DocComment(sb, ctx, "/**\n", " * ", " */");
            CollectBases(ctx, out var extends, out var implements);

            string name = Sanitize(ctx.Name);
            string keyword = ctx.Kind switch
            {
                ElementKind.Interface => "interface",
                ElementKind.Enum => "enum",
                _ => "class",
            };

            sb.Append("public ");
            if (ctx.IsAbstract && keyword == "class") sb.Append("abstract ");
            sb.Append(keyword).Append(' ').Append(name);
            if (extends.Count > 0) sb.Append(" extends ").Append(string.Join(", ", extends));
            if (implements.Count > 0) sb.Append(" implements ").Append(string.Join(", ", implements));
            sb.Append(" {\n");

            if (ctx.Kind == ElementKind.Enum)
            {
                var names = new List<string>();
                foreach (var f in ctx.Attributes)
                {
                    var m = ParseMember(f, false);
                    names.Add(string.IsNullOrEmpty(m.Name) ? f.Trim() : m.Name);
                }
                sb.Append("    ").Append(string.Join(", ", names)).Append(";\n");
            }
            else
            {
                var attrs = Parse(ctx.Attributes, false);
                for (int i = 0; i < attrs.Count; i++)
                {
                    var m = attrs[i];
                    string vis = JavaVis(m.Visibility);
                    string type = string.IsNullOrEmpty(m.Type) ? "Object" : m.Type;
                    MemberDoc(sb, ctx.AttributeComment(i), "    // ");
                    sb.Append("    ");
                    if (!string.IsNullOrEmpty(vis)) sb.Append(vis).Append(' ');
                    sb.Append(type).Append(' ').Append(m.Name).Append(";\n");
                }
                if (ctx.Attributes.Count > 0 && ctx.Operations.Count > 0) sb.Append('\n');
                var ops = Parse(ctx.Operations, true);
                for (int i = 0; i < ops.Count; i++)
                {
                    var m = ops[i];
                    string ret = string.IsNullOrEmpty(m.Type) ? "void" : m.Type;
                    string vis = JavaVis(m.Visibility);
                    MemberDoc(sb, ctx.OperationComment(i), "    // ");
                    sb.Append("    ");
                    if (!string.IsNullOrEmpty(vis)) sb.Append(vis).Append(' ');
                    if (ctx.Kind == ElementKind.Interface)
                    {
                        sb.Append(ret).Append(' ').Append(m.Name).Append('(').Append(m.Parameters).Append(");\n");
                    }
                    else
                    {
                        sb.Append(ret).Append(' ').Append(m.Name).Append('(').Append(m.Parameters).Append(") {\n");
                        sb.Append("        // TODO: implement\n");
                        if (ret != "void") sb.Append("        throw new UnsupportedOperationException();\n");
                        sb.Append("    }\n");
                    }
                }
            }

            sb.Append("}\n");
            return sb.ToString();
        }

        // --- TypeScript ---

        private static string GenerateTypeScript(CodeGenContext ctx)
        {
            var sb = new StringBuilder();
            DocComment(sb, ctx, "/**\n", " * ", " */");
            CollectBases(ctx, out var extends, out var implements);

            string name = Sanitize(ctx.Name);

            if (ctx.Kind == ElementKind.Enum)
            {
                sb.Append("export enum ").Append(name).Append(" {\n");
                foreach (var f in ctx.Attributes)
                {
                    var m = ParseMember(f, false);
                    sb.Append("    ").Append(string.IsNullOrEmpty(m.Name) ? f.Trim() : m.Name).Append(",\n");
                }
                sb.Append("}\n");
                return sb.ToString();
            }

            bool isInterface = ctx.Kind == ElementKind.Interface;
            sb.Append("export ");
            if (ctx.IsAbstract && !isInterface) sb.Append("abstract ");
            sb.Append(isInterface ? "interface " : "class ").Append(name);
            if (extends.Count > 0) sb.Append(" extends ").Append(string.Join(", ", extends));
            if (implements.Count > 0) sb.Append(" implements ").Append(string.Join(", ", implements));
            sb.Append(" {\n");

            var tsAttrs = Parse(ctx.Attributes, false);
            for (int i = 0; i < tsAttrs.Count; i++)
            {
                var m = tsAttrs[i];
                string type = string.IsNullOrEmpty(m.Type) ? "unknown" : m.Type;
                MemberDoc(sb, ctx.AttributeComment(i), "    // ");
                sb.Append("    ");
                if (!isInterface && m.Visibility == "-") sb.Append("private ");
                else if (!isInterface && m.Visibility == "#") sb.Append("protected ");
                sb.Append(m.Name).Append(": ").Append(type).Append(";\n");
            }
            if (ctx.Attributes.Count > 0 && ctx.Operations.Count > 0) sb.Append('\n');
            var tsOps = Parse(ctx.Operations, true);
            for (int i = 0; i < tsOps.Count; i++)
            {
                var m = tsOps[i];
                string ret = string.IsNullOrEmpty(m.Type) ? "void" : m.Type;
                MemberDoc(sb, ctx.OperationComment(i), "    // ");
                sb.Append("    ");
                if (!isInterface && m.Visibility == "-") sb.Append("private ");
                else if (!isInterface && m.Visibility == "#") sb.Append("protected ");
                if (isInterface)
                {
                    sb.Append(m.Name).Append('(').Append(m.Parameters).Append("): ").Append(ret).Append(";\n");
                }
                else
                {
                    sb.Append(m.Name).Append('(').Append(m.Parameters).Append("): ").Append(ret).Append(" {\n");
                    sb.Append("        // TODO: implement\n");
                    sb.Append("    }\n");
                }
            }

            sb.Append("}\n");
            return sb.ToString();
        }

        // --- Python ---

        private static string GeneratePython(CodeGenContext ctx)
        {
            var sb = new StringBuilder();
            CollectBases(ctx, out var extends, out var implements);

            string name = Sanitize(ctx.Name);
            var bases = new List<string>(extends);
            bases.AddRange(implements);

            sb.Append("class ").Append(name);
            if (bases.Count > 0) sb.Append('(').Append(string.Join(", ", bases)).Append(')');
            sb.Append(":\n");

            // Docstring (description + notes).
            string doc = DocstringBody(ctx);
            if (!string.IsNullOrEmpty(doc))
            {
                sb.Append("    \"\"\"\n");
                foreach (var line in doc.Split('\n')) sb.Append("    ").Append(line).Append('\n');
                sb.Append("    \"\"\"\n");
            }

            bool wroteBody = false;
            var pyAttrs = Parse(ctx.Attributes, false);
            for (int i = 0; i < pyAttrs.Count; i++)
            {
                var m = pyAttrs[i];
                string type = string.IsNullOrEmpty(m.Type) ? "object" : m.Type;
                MemberDoc(sb, ctx.AttributeComment(i), "    # ");
                sb.Append("    ").Append(m.Name).Append(": ").Append(type).Append('\n');
                wroteBody = true;
            }
            var pyOps = Parse(ctx.Operations, true);
            for (int i = 0; i < pyOps.Count; i++)
            {
                var m = pyOps[i];
                string args = string.IsNullOrEmpty(m.Parameters) ? "self" : "self, " + m.Parameters;
                sb.Append('\n');
                MemberDoc(sb, ctx.OperationComment(i), "    # ");
                sb.Append("    def ").Append(m.Name).Append('(').Append(args).Append(')');
                if (!string.IsNullOrEmpty(m.Type)) sb.Append(" -> ").Append(m.Type);
                sb.Append(":\n        # TODO: implement\n        pass\n");
                wroteBody = true;
            }
            if (!wroteBody && string.IsNullOrEmpty(doc)) sb.Append("    pass\n");

            return sb.ToString();
        }

        // --- Elixir ---

        /// <summary>
        /// Elixir is not class-based: emit a <c>defmodule</c> with a <c>@moduledoc</c> (description + notes), a
        /// <c>defstruct</c> from the attributes, and <c>def</c>/<c>defp</c> functions from the operations.
        /// Realized interfaces become <c>@behaviour</c>s; an enum kind becomes a <c>@type</c> union of atoms.
        /// </summary>
        private static string GenerateElixir(CodeGenContext ctx)
        {
            var sb = new StringBuilder();
            string name = ModuleName(ctx.Name);
            CollectBases(ctx, out var extends, out var implements);

            sb.Append("defmodule ").Append(name).Append(" do\n");
            ElixirModuleDoc(sb, ctx);

            if (ctx.Kind == ElementKind.Enum)
            {
                var atoms = new List<string>();
                foreach (var f in ctx.Attributes)
                {
                    var m = ParseMember(f, false);
                    atoms.Add(":" + SnakeCase(string.IsNullOrEmpty(m.Name) ? f : m.Name));
                }
                if (atoms.Count > 0)
                    sb.Append("  @type t :: ").Append(string.Join(" | ", atoms)).Append('\n');
                else
                    sb.Append("  @type t :: atom()\n");
                sb.Append("end\n");
                return sb.ToString();
            }

            foreach (var b in implements) sb.Append("  @behaviour ").Append(ModuleName(b)).Append('\n');
            foreach (var b in extends) sb.Append("  # extends ").Append(ModuleName(b)).Append(" (compose via use/delegation)\n");
            if (implements.Count > 0 || extends.Count > 0) sb.Append('\n');

            var attrs = Parse(ctx.Attributes, false);
            if (attrs.Count > 0)
            {
                var keys = new List<string>();
                foreach (var a in attrs) keys.Add(":" + SnakeCase(a.Name));
                sb.Append("  defstruct [").Append(string.Join(", ", keys)).Append("]\n\n");
            }

            var ops = Parse(ctx.Operations, true);
            for (int i = 0; i < ops.Count; i++)
            {
                var m = ops[i];
                string def = (m.Visibility == "-" || m.Visibility == "#") ? "defp" : "def";
                // Public functions document with @doc; private ones use a plain # comment (Elixir warns on @doc for defp).
                string comment = ctx.OperationComment(i);
                if (!string.IsNullOrWhiteSpace(comment))
                {
                    string oneLine = comment.Replace("\r\n", "\n").Replace('\n', ' ').Trim();
                    if (def == "def") sb.Append("  @doc \"").Append(oneLine.Replace("\"", "\\\"")).Append("\"\n");
                    else sb.Append("  # ").Append(oneLine).Append('\n');
                }
                sb.Append("  ").Append(def).Append(' ').Append(SnakeCase(m.Name))
                  .Append('(').Append(ElixirArgs(m.Parameters)).Append(") do\n");
                sb.Append("    # TODO: implement\n");
                sb.Append("  end\n\n");
            }
            if (attrs.Count == 0 && ops.Count == 0) sb.Append("  # TODO: implement\n");

            sb.Append("end\n");
            return sb.ToString();
        }

        private static void ElixirModuleDoc(StringBuilder sb, CodeGenContext ctx)
        {
            string body = DocstringBody(ctx);
            if (string.IsNullOrEmpty(body)) return;
            sb.Append("  @moduledoc \"\"\"\n");
            foreach (var line in body.Split('\n')) sb.Append("  ").Append(line).Append('\n');
            sb.Append("  \"\"\"\n\n");
        }

        /// <summary>PascalCase/dotted module alias from a free-form name (keeps '.' for nested modules).</summary>
        private static string ModuleName(string raw)
        {
            string n = Sanitize(raw);
            var sb = new StringBuilder();
            bool up = true;
            foreach (char c in n)
            {
                if (c == '.') { sb.Append('.'); up = true; }
                else if (char.IsLetterOrDigit(c)) { sb.Append(up ? char.ToUpperInvariant(c) : c); up = false; }
                else up = true;
            }
            string r = sb.ToString();
            return string.IsNullOrEmpty(r) ? "Generated" : r;
        }

        /// <summary>snake_case identifier (valid Elixir function name / atom) from a UML member name.</summary>
        private static string SnakeCase(string raw)
        {
            string n = (raw ?? "").Trim();
            var sb = new StringBuilder();
            foreach (char c in n)
            {
                if (char.IsUpper(c)) { if (sb.Length > 0 && sb[sb.Length - 1] != '_') sb.Append('_'); sb.Append(char.ToLowerInvariant(c)); }
                else if (char.IsLetterOrDigit(c) || c == '_') sb.Append(c);
                else if (sb.Length > 0 && sb[sb.Length - 1] != '_') sb.Append('_');
            }
            string r = sb.ToString().Trim('_');
            return string.IsNullOrEmpty(r) ? "value" : r;
        }

        /// <summary>Elixir arg list: the parameter identifiers (UML "name : Type" → "name"), snake_cased.</summary>
        private static string ElixirArgs(string parameters)
        {
            if (string.IsNullOrWhiteSpace(parameters)) return "";
            var names = new List<string>();
            foreach (var part in parameters.Split(','))
            {
                string p = part.Trim();
                if (p.Length == 0) continue;
                int colon = p.IndexOf(':');
                string nm = colon >= 0 ? p.Substring(0, colon).Trim() : p;
                names.Add(SnakeCase(nm));
            }
            return string.Join(", ", names);
        }

        // --- doc-comment helpers ---

        /// <summary>
        /// Emit a member's doc-comment immediately above its declaration, indented and prefixed for the language
        /// (e.g. "    /// " for C#, "    # " for Python). Multi-line comments fold to a single line. Emits nothing
        /// for an empty comment.
        /// </summary>
        private static void MemberDoc(StringBuilder sb, string comment, string linePrefix)
        {
            if (string.IsNullOrWhiteSpace(comment)) return;
            string oneLine = comment.Replace("\r\n", "\n").Replace('\n', ' ').Trim();
            sb.Append(linePrefix).Append(oneLine).Append('\n');
        }

        /// <summary>The plain text body (description + notes) for any doc comment, newline-joined; may be empty.</summary>
        private static string DocstringBody(CodeGenContext ctx)
        {
            var lines = new List<string>();
            if (!string.IsNullOrWhiteSpace(ctx.Description))
                foreach (var l in ctx.Description.Replace("\r\n", "\n").Split('\n')) lines.Add(l);
            foreach (var note in ctx.AttachedNotes)
            {
                lines.Add("Note:");
                foreach (var l in note.Replace("\r\n", "\n").Split('\n')) lines.Add("  " + l);
            }
            return string.Join("\n", lines);
        }

        /// <summary>
        /// Emit a doc-comment header. <paramref name="open"/> is the opening line (e.g. "/**\n" or ""), each body
        /// line is prefixed with <paramref name="linePrefix"/> ("/// " or " * "), and <paramref name="close"/> is the
        /// closing line (" */" or, for C# line comments, the same "/// " — passed but unused there). Emits nothing
        /// when there is no description and no attached notes.
        /// </summary>
        private static void DocComment(StringBuilder sb, CodeGenContext ctx, string open, string linePrefix, string close)
        {
            string body = DocstringBody(ctx);
            if (string.IsNullOrEmpty(body)) return;

            bool block = open.StartsWith("/**");
            if (block) sb.Append(open);
            foreach (var line in body.Split('\n')) sb.Append(linePrefix).Append(line).Append('\n');
            if (block) sb.Append(close).Append('\n');
        }
    }
}
