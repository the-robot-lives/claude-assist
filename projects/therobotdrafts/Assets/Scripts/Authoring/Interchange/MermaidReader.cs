using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;

namespace TheRobotDraft.Authoring.Interchange
{
    /// <summary>
    /// Imports a Mermaid <c>classDiagram</c> into the neutral <see cref="IxModel"/>
    /// (docs/formats/mermaid-format.md). Deliberately lenient on read: the envelope
    /// (<c>---</c> frontmatter, the <c>classDiagram</c> / <c>classDiagram-v2</c> header,
    /// <c>direction</c>, <c>%%</c> comments and <c>%%{init:…}%%</c> directives) is optional
    /// and any line the grammar does not recognize — <c>click</c>/<c>callback</c>/<c>link</c>
    /// interactions, config lines, exotic arrows — is skipped rather than fatal. The only hard
    /// error is a null input; empty/whitespace yields an empty model. Elements first named by a
    /// relationship are auto-created as classes. Styling (<c>classDef</c> + <c>class … style</c>,
    /// <c>:::</c>, <c>cssClass</c>, and per-element <c>style</c>) is resolved into the element
    /// color fields, with 3-digit hex and a small named-color table normalized to <c>#RRGGBB</c>.
    /// Pure C# + BCL; no engine references.
    /// </summary>
    public static class MermaidReader
    {
        // A relationship line: LEFT ["lmult"] ARROW ["rmult"] RIGHT [: label].
        private static readonly Regex RelRx = new Regex(
            @"^(?<l>[A-Za-z0-9_.]+)\s*(?:""(?<lm>[^""]*)"")?\s*" +
            @"(?<arrow>[<>o*()|]*(?:-{2,}|\.{2,})[<>o*()|]*)\s*" +
            @"(?:""(?<rm>[^""]*)"")?\s*(?<r>[A-Za-z0-9_.]+)\s*(?::\s*(?<label>.*?))?\s*$",
            RegexOptions.Compiled);

        private static readonly Regex ArrowRx =
            new Regex(@"^(?<lh>[<>o*()|]*)(?<body>-{2,}|\.{2,})(?<rh>[<>o*()|]*)$", RegexOptions.Compiled);

        private static readonly Regex AnnRx = new Regex(@"<<\s*([^>]*?)\s*>>", RegexOptions.Compiled);
        private static readonly Regex LabelRx =
            new Regex(@"\[(?:""(?<q>[^""]*)""|(?<b>[^\]]*))\]", RegexOptions.Compiled);
        private static readonly Regex GenRx = new Regex(@"~(?<g>[^~]*)~", RegexOptions.Compiled);
        private static readonly Regex NoteForRx =
            new Regex(@"^note\s+for\s+(?<t>[A-Za-z0-9_.]+)\s+(?:""(?<b>[^""]*)""|(?<b2>.*))$",
                RegexOptions.Compiled | RegexOptions.IgnoreCase);
        private static readonly Regex NoteRx =
            new Regex(@"^note\s+(?:""(?<b>[^""]*)""|(?<b2>.*))$", RegexOptions.Compiled | RegexOptions.IgnoreCase);
        private static readonly Regex CssClassRx =
            new Regex(@"^cssClass\s+""(?<names>[^""]*)""\s+(?<style>[A-Za-z0-9_]+)", RegexOptions.Compiled);
        private static readonly Regex InlineTripleRx =
            new Regex(@"^(?<id>[A-Za-z0-9_.]+):::(?<style>[A-Za-z0-9_]+)$", RegexOptions.Compiled);
        private static readonly Regex BareIdRx = new Regex(@"^[A-Za-z_][A-Za-z0-9_]*$", RegexOptions.Compiled);

        public static IxModel Parse(string text)
        {
            if (text == null) throw new InterchangeException("Mermaid input is null.");

            var ctx = new Ctx { Model = new IxModel() };
            var bodyLines = Preprocess(text, out string title);
            if (title != null) ctx.Model.Name = title;
            foreach (var line in bodyLines)
            {
                string s = line.Trim();
                if (s.Length == 0) continue;
                if (s.EndsWith(";")) s = s.Substring(0, s.Length - 1).TrimEnd();
                if (s.Length == 0) continue;

                // Inside a class body every line is a member/annotation until the closing brace.
                if (ctx.OpenBody != null)
                {
                    if (s == "}") { CloseBody(ctx); }
                    else ctx.BodyLines.Add(s);
                    continue;
                }

                if (s == "}") { if (ctx.NsStack.Count > 0) ctx.NsStack.Pop(); continue; }
                if (s.StartsWith("%%")) continue;                       // comment / %%{init}%% directive
                if (s == "classDiagram" || s == "classDiagram-v2") continue;
                if (StartsWithWord(s, "direction")) continue;
                if (StartsWithWord(s, "click") || StartsWithWord(s, "callback") ||
                    StartsWithWord(s, "link") || StartsWithWord(s, "href")) continue;

                if (StartsWithWord(s, "note")) { HandleNote(s, ctx); continue; }
                if (StartsWithWord(s, "classDef")) { HandleClassDef(s, ctx); continue; }
                if (StartsWithWord(s, "cssClass")) { HandleCssClass(s, ctx); continue; }
                if (StartsWithWord(s, "style")) { HandleStyle(s, ctx); continue; }
                if (StartsWithWord(s, "namespace")) { HandleNamespace(s.Substring("namespace".Length), ctx); continue; }
                if (StartsWithWord(s, "class")) { HandleClass(s.Substring("class".Length), ctx); continue; }

                var im = InlineTripleRx.Match(s);
                if (im.Success) { AddAssignment(ctx, GetOrCreate(ctx, im.Groups["id"].Value).Id, im.Groups["style"].Value); continue; }

                var ann = AnnRx.Match(s);
                if (ann.Success && ann.Index == 0)
                {
                    // "<<interface>> Name" — external annotation.
                    string after = s.Substring(ann.Index + ann.Length).Trim();
                    if (after.Length > 0) { ApplyAnnotation(GetOrCreate(ctx, after), ann.Groups[1].Value.Trim()); continue; }
                }

                if (TryRelationship(s, ctx)) continue;

                // External member:  Name : text
                int colon = s.IndexOf(':');
                if (colon > 0 && !s.Contains(":::"))
                {
                    string target = s.Substring(0, colon).Trim();
                    string body = s.Substring(colon + 1).Trim();
                    if (BareIdRx.IsMatch(StripDots(target)) && body.Length > 0)
                    {
                        var el = GetOrCreate(ctx, target);
                        var a = AnnRx.Match(body);
                        if (a.Success && a.Index == 0) ApplyAnnotation(el, a.Groups[1].Value.Trim());
                        else AddBodyMember(el, body);
                        continue;
                    }
                }
                // Anything else: tolerated and skipped.
            }

            if (ctx.OpenBody != null) CloseBody(ctx); // unterminated body — flush what we have
            ResolveStyles(ctx);
            NormalizeEnums(ctx);
            return ctx.Model;
        }

        // --- envelope --------------------------------------------------------------------------

        private static IEnumerable<string> Preprocess(string text, out string title)
        {
            title = null;
            var raw = text.Replace("\r\n", "\n").Replace("\r", "\n").Split('\n');
            int p = 0;
            while (p < raw.Length && raw[p].Trim().Length == 0) p++;
            int start = 0;
            if (p < raw.Length && raw[p].Trim() == "---")
            {
                int q = p + 1;
                while (q < raw.Length && raw[q].Trim() != "---")
                {
                    // Recover the diagram name from `title:`; every other frontmatter key is skipped.
                    var t = raw[q].Trim();
                    if (title == null && t.StartsWith("title:"))
                    {
                        string v = t.Substring("title:".Length).Trim();
                        if (v.Length >= 2 && ((v[0] == '"' && v[v.Length - 1] == '"') || (v[0] == '\'' && v[v.Length - 1] == '\'')))
                            v = v.Substring(1, v.Length - 2);
                        title = NullIfEmpty(v);
                    }
                    q++;
                }
                start = q < raw.Length ? q + 1 : raw.Length; // drop frontmatter (and skip a stray unterminated one)
            }
            var outp = new List<string>();
            for (int i = start; i < raw.Length; i++) outp.Add(raw[i]);
            return outp;
        }

        // --- namespaces & classes --------------------------------------------------------------

        private static void HandleNamespace(string rest, Ctx ctx)
        {
            rest = rest.Trim();
            bool closedInline = false;
            int bi = rest.IndexOf('{');
            if (bi >= 0)
            {
                string tail = rest.Substring(bi + 1);
                closedInline = tail.Contains("}");
                rest = rest.Substring(0, bi).Trim();
            }
            string label = null;
            var lm = LabelRx.Match(rest);
            if (lm.Success) { label = lm.Groups["q"].Success ? lm.Groups["q"].Value : lm.Groups["b"].Value; rest = rest.Remove(lm.Index, lm.Length).Trim(); }
            string id = rest.Trim();
            if (id.Length == 0) return;

            var pkg = GetOrCreate(ctx, id);
            pkg.Type = IxElementType.Package;
            if (label != null) pkg.Name = label;
            SetNs(ctx, pkg);
            if (!closedInline) ctx.NsStack.Push(pkg.Id);
        }

        private static void HandleClass(string afterKw, Ctx ctx)
        {
            int bi = afterKw.IndexOf('{');
            if (bi < 0) { HandleClassDecl(afterKw, false, ctx); return; }

            string namePart = afterKw.Substring(0, bi);
            string tail = afterKw.Substring(bi + 1);
            bool closed = tail.Contains("}");
            string inner = closed ? tail.Substring(0, tail.LastIndexOf('}')) : tail;

            HandleClassDecl(namePart, true, ctx); // creates the element and opens a body
            foreach (var seg in inner.Split(';', '\n'))
            {
                string t = seg.Trim();
                if (t.Length > 0) ctx.BodyLines.Add(t);
            }
            if (closed) CloseBody(ctx);
        }

        // A `class …` declaration line (no opening brace here, or brace already peeled off).
        private static void HandleClassDecl(string rest, bool bodyOpen, Ctx ctx)
        {
            rest = rest.Trim();

            string stereo = null;
            var am = AnnRx.Match(rest);
            if (am.Success) { stereo = am.Groups[1].Value.Trim(); rest = rest.Remove(am.Index, am.Length).Trim(); }

            string label = null;
            var lm = LabelRx.Match(rest);
            if (lm.Success) { label = lm.Groups["q"].Success ? lm.Groups["q"].Value : lm.Groups["b"].Value; rest = rest.Remove(lm.Index, lm.Length).Trim(); }

            string inlineStyle = null;
            int ci = rest.IndexOf(":::");
            if (ci >= 0)
            {
                var mstyle = Regex.Match(rest.Substring(ci), @"^:::(?<s>[A-Za-z0-9_]+)");
                if (mstyle.Success) { inlineStyle = mstyle.Groups["s"].Value; rest = rest.Remove(ci, 3 + inlineStyle.Length).Trim(); }
            }

            string gen = null;
            var gm = GenRx.Match(rest);
            if (gm.Success) { gen = gm.Groups["g"].Value; rest = rest.Remove(gm.Index, gm.Length).Trim(); }

            bool decorated = stereo != null || label != null || gen != null || inlineStyle != null;
            var parts = rest.Split((char[])null, StringSplitOptions.RemoveEmptyEntries);

            if (bodyOpen)
            {
                string name = parts.Length > 0 ? parts[0] : rest.Trim();
                var el = GetOrCreate(ctx, name);
                Decorate(ctx, el, label, stereo, gen, inlineStyle);
                OpenBody(ctx, el);
                return;
            }

            if (!decorated && parts.Length >= 2)
            {
                // Style assignment:  class A,B styleName
                string style = parts[parts.Length - 1];
                foreach (var n in parts[0].Split(','))
                {
                    string nm = n.Trim();
                    if (nm.Length == 0) continue;
                    AddAssignment(ctx, GetOrCreate(ctx, nm).Id, style);
                }
                return;
            }

            // Declaration (possibly a comma list).
            string first = parts.Length > 0 ? parts[0] : rest.Trim();
            var names = first.Split(',');
            IxElement created = null;
            foreach (var n in names)
            {
                string nm = n.Trim();
                if (nm.Length == 0) continue;
                var e = GetOrCreate(ctx, nm);
                if (created == null) created = e;
            }
            if (names.Length == 1 && created != null) Decorate(ctx, created, label, stereo, gen, inlineStyle);
        }

        private static void Decorate(Ctx ctx, IxElement el, string label, string stereo, string gen, string inlineStyle)
        {
            SetNs(ctx, el);
            if (label != null) el.Name = label;
            if (stereo != null) ApplyAnnotation(el, stereo);
            if (gen != null) el.GenericParams = gen;
            if (inlineStyle != null) AddAssignment(ctx, el.Id, inlineStyle);
        }

        private static void OpenBody(Ctx ctx, IxElement el)
        {
            if (ctx.OpenBody != null) CloseBody(ctx);
            ctx.OpenBody = el.Id;
            ctx.BodyLines.Clear();
        }

        private static void CloseBody(Ctx ctx)
        {
            var el = Find(ctx, ctx.OpenBody);
            var lines = ctx.BodyLines;
            ctx.OpenBody = null;
            ctx.BodyLines = new List<string>();
            if (el == null) return;

            // Annotations first so the element type is known before members are classified.
            foreach (var l in lines)
            {
                var a = AnnRx.Match(l);
                if (a.Success && a.Index == 0) ApplyAnnotation(el, a.Groups[1].Value.Trim());
            }
            foreach (var l in lines)
            {
                var a = AnnRx.Match(l);
                if (a.Success && a.Index == 0) continue; // already applied
                AddBodyMember(el, l);
            }
        }

        private static void AddBodyMember(IxElement el, string raw)
        {
            raw = raw.Trim();
            if (raw.Length == 0) return;
            if (el.Type == IxElementType.Enum && raw.IndexOf('(') < 0) { el.EnumLiterals.Add(raw); return; }
            el.Members.Add(ParseMember(raw));
        }

        // --- members ---------------------------------------------------------------------------

        private static IxMember ParseMember(string raw)
        {
            string original = raw;
            raw = raw.Trim();

            var vis = IxVisibility.Public;
            if (raw.Length > 0 && "+-#~".IndexOf(raw[0]) >= 0)
            {
                vis = VisFromChar(raw[0]);
                raw = raw.Substring(1).Trim();
            }

            bool isStatic = false, isAbstract = false;
            while (raw.Length > 0 && (raw[raw.Length - 1] == '*' || raw[raw.Length - 1] == '$'))
            {
                if (raw[raw.Length - 1] == '*') isAbstract = true; else isStatic = true;
                raw = raw.Substring(0, raw.Length - 1).TrimEnd();
            }

            var m = new IxMember { Visibility = vis, IsStatic = isStatic, IsAbstract = isAbstract, RawText = original };

            int lp = raw.IndexOf('(');
            if (lp >= 0)
            {
                m.IsOperation = true;
                int rp = raw.LastIndexOf(')');
                if (rp < lp) rp = raw.Length;
                string head = raw.Substring(0, lp).Trim();
                string paramStr = rp > lp ? raw.Substring(lp + 1, rp - lp - 1) : "";
                string tail = rp + 1 <= raw.Length ? raw.Substring(Math.Min(rp + 1, raw.Length)).Trim() : "";

                var headTokens = head.Split((char[])null, StringSplitOptions.RemoveEmptyEntries);
                if (tail.Length > 0)
                {
                    m.Name = headTokens.Length > 0 ? headTokens[headTokens.Length - 1] : head;
                    m.Type = ConvertGenericsIn(tail);
                }
                else if (headTokens.Length >= 2)
                {
                    // Tolerate Java-style "Ret name()".
                    m.Name = headTokens[headTokens.Length - 1];
                    m.Type = ConvertGenericsIn(string.Join(" ", headTokens, 0, headTokens.Length - 1));
                }
                else
                {
                    m.Name = head;
                }
                foreach (var praw in SplitParams(paramStr))
                {
                    string pt = praw.Trim();
                    if (pt.Length == 0) continue;
                    int sp = LastWhitespace(pt);
                    if (sp > 0) m.Parameters.Add(new IxParam { Type = ConvertGenericsIn(pt.Substring(0, sp).Trim()), Name = pt.Substring(sp + 1).Trim() });
                    else m.Parameters.Add(new IxParam { Type = ConvertGenericsIn(pt) });
                }
            }
            else
            {
                // Field — Mermaid is type-first: "Type name". Name is the last whitespace token.
                int sp = LastWhitespace(raw);
                if (sp > 0) { m.Name = raw.Substring(sp + 1).Trim(); m.Type = ConvertGenericsIn(raw.Substring(0, sp).Trim()); }
                else m.Name = raw;
            }
            return m;
        }

        private static IEnumerable<string> SplitParams(string s)
        {
            var outp = new List<string>();
            if (string.IsNullOrEmpty(s)) return outp;
            bool inTilde = false;
            int startIdx = 0;
            for (int i = 0; i < s.Length; i++)
            {
                char c = s[i];
                if (c == '~') inTilde = !inTilde;
                else if (c == ',' && !inTilde) { outp.Add(s.Substring(startIdx, i - startIdx)); startIdx = i + 1; }
            }
            outp.Add(s.Substring(startIdx));
            return outp;
        }

        // --- relationships ---------------------------------------------------------------------

        private static bool TryRelationship(string s, Ctx ctx)
        {
            // Peel inline ":::style" off either operand first, so the label ":" logic stays simple.
            s = Regex.Replace(s, @"([A-Za-z0-9_.]+):::([A-Za-z0-9_]+)", mm =>
            {
                AddAssignment(ctx, GetOrCreate(ctx, mm.Groups[1].Value).Id, mm.Groups[2].Value);
                return mm.Groups[1].Value;
            });

            var m = RelRx.Match(s);
            if (!m.Success) return false;
            var am = ArrowRx.Match(m.Groups["arrow"].Value);
            if (!am.Success) return false;

            var left = GetOrCreate(ctx, m.Groups["l"].Value);
            var right = GetOrCreate(ctx, m.Groups["r"].Value);
            string lmult = m.Groups["lm"].Success ? NullIfEmpty(m.Groups["lm"].Value) : null;
            string rmult = m.Groups["rm"].Success ? NullIfEmpty(m.Groups["rm"].Value) : null;
            string label = m.Groups["label"].Success ? NullIfEmpty(m.Groups["label"].Value.Trim()) : null;

            bool dashed = am.Groups["body"].Value[0] == '.';
            var lMark = ClassifyHead(am.Groups["lh"].Value);
            var rMark = ClassifyHead(am.Groups["rh"].Value);

            IxEdgeType type;
            bool swap; // true => From = right operand
            Decode(lMark, rMark, dashed, out type, out swap);

            var edge = new IxEdge
            {
                Type = type,
                FromId = swap ? right.Id : left.Id,
                ToId = swap ? left.Id : right.Id,
                FromMultiplicity = swap ? rmult : lmult,
                ToMultiplicity = swap ? lmult : rmult,
                Label = label,
            };
            ctx.Model.Edges.Add(edge);
            return true;
        }

        private enum Mark { None, Triangle, DiamondFilled, DiamondHollow, Arrow, Lollipop }

        private static Mark ClassifyHead(string head)
        {
            if (string.IsNullOrEmpty(head)) return Mark.None;
            if (head.IndexOf('|') >= 0) return Mark.Triangle;
            if (head.IndexOf('*') >= 0) return Mark.DiamondFilled;
            if (head.IndexOf('o') >= 0) return Mark.DiamondHollow;
            if (head.IndexOf('(') >= 0 || head.IndexOf(')') >= 0) return Mark.Lollipop;
            if (head.IndexOf('<') >= 0 || head.IndexOf('>') >= 0) return Mark.Arrow;
            return Mark.None;
        }

        // Resolve arrow marks to an edge type + orientation per the IxEdge direction convention:
        // Generalization/Realization To=parent/interface (triangle end); Composition/Aggregation
        // From=whole (diamond end); DirectedAssociation/Dependency To=arrowhead end.
        private static void Decode(Mark left, Mark right, bool dashed, out IxEdgeType type, out bool swap)
        {
            if (left == Mark.Triangle || right == Mark.Triangle)
            {
                type = dashed ? IxEdgeType.Realization : IxEdgeType.Generalization;
                swap = left == Mark.Triangle; // triangle end is To
            }
            else if (left == Mark.DiamondFilled || right == Mark.DiamondFilled)
            {
                type = IxEdgeType.Composition;
                swap = right == Mark.DiamondFilled; // diamond end is From (whole)
            }
            else if (left == Mark.DiamondHollow || right == Mark.DiamondHollow)
            {
                type = IxEdgeType.Aggregation;
                swap = right == Mark.DiamondHollow;
            }
            else if (left == Mark.Arrow || right == Mark.Arrow)
            {
                if (left == Mark.Arrow && right == Mark.Arrow) { type = IxEdgeType.Association; swap = false; } // two-way
                else { type = dashed ? IxEdgeType.Dependency : IxEdgeType.DirectedAssociation; swap = left == Mark.Arrow; }
            }
            else if (left == Mark.Lollipop || right == Mark.Lollipop)
            {
                type = IxEdgeType.Association; swap = false; // lollipop not modeled — keep as a plain link
            }
            else
            {
                type = dashed ? IxEdgeType.Dependency : IxEdgeType.Association; swap = false;
            }
        }

        // --- notes -----------------------------------------------------------------------------

        private static void HandleNote(string s, Ctx ctx)
        {
            var mf = NoteForRx.Match(s);
            if (mf.Success)
            {
                var note = NewNote(ctx, mf.Groups["b"].Success ? mf.Groups["b"].Value : mf.Groups["b2"].Value.Trim());
                var target = GetOrCreate(ctx, mf.Groups["t"].Value);
                ctx.Model.Edges.Add(new IxEdge { Type = IxEdgeType.NoteLink, FromId = note.Id, ToId = target.Id });
                return;
            }
            var m = NoteRx.Match(s);
            if (m.Success) NewNote(ctx, m.Groups["b"].Success ? m.Groups["b"].Value : m.Groups["b2"].Value.Trim());
        }

        private static IxElement NewNote(Ctx ctx, string body)
        {
            var note = new IxElement
            {
                Id = "note" + (++ctx.NoteSeq),
                Type = IxElementType.Note,
                Name = "note" + ctx.NoteSeq,
                Documentation = UnescapeNote(body),
            };
            ctx.Model.Elements.Add(note);
            ctx.ById[note.Id] = note;
            return note;
        }

        // --- styling ---------------------------------------------------------------------------

        private static void HandleClassDef(string s, Ctx ctx)
        {
            string rest = s.Substring("classDef".Length).Trim();
            int sp = FirstWhitespace(rest);
            if (sp < 0) return;
            string names = rest.Substring(0, sp);
            string props = rest.Substring(sp + 1);
            var style = ParseProps(props);
            foreach (var n in names.Split(','))
            {
                string nm = n.Trim();
                if (nm.Length == 0) continue;
                ctx.StyleDefs[nm] = style;
                if (nm == "default") ctx.DefaultStyle = style;
            }
        }

        private static void HandleCssClass(string s, Ctx ctx)
        {
            var m = CssClassRx.Match(s);
            if (!m.Success) return;
            foreach (var n in m.Groups["names"].Value.Split(','))
            {
                string nm = n.Trim();
                if (nm.Length == 0) continue;
                AddAssignment(ctx, GetOrCreate(ctx, nm).Id, m.Groups["style"].Value);
            }
        }

        private static void HandleStyle(string s, Ctx ctx)
        {
            string rest = s.Substring("style".Length).Trim();
            int sp = FirstWhitespace(rest);
            if (sp < 0) return;
            string name = rest.Substring(0, sp).Trim();
            var style = ParseProps(rest.Substring(sp + 1));
            ctx.StyleLines.Add((GetOrCreate(ctx, name).Id, style));
        }

        private static Style ParseProps(string props)
        {
            var st = new Style();
            foreach (var part in props.Split(','))
            {
                int c = part.IndexOf(':');
                if (c <= 0) continue;
                string key = part.Substring(0, c).Trim().ToLowerInvariant();
                string val = part.Substring(c + 1).Trim();
                if (key == "fill") st.Fill = NormalizeColor(val);
                else if (key == "stroke") st.Line = NormalizeColor(val);
                else if (key == "color") st.Text = NormalizeColor(val);
            }
            return st;
        }

        private static void AddAssignment(Ctx ctx, string elemId, string styleName) =>
            ctx.Assignments.Add((elemId, styleName));

        private static void ResolveStyles(Ctx ctx)
        {
            var explicitly = new HashSet<string>();
            foreach (var a in ctx.Assignments) explicitly.Add(a.Item1);
            foreach (var s in ctx.StyleLines) explicitly.Add(s.Item1);

            if (ctx.DefaultStyle != null)
                foreach (var el in ctx.Model.Elements)
                    if (el.Type != IxElementType.Package && el.Type != IxElementType.Note && !explicitly.Contains(el.Id))
                        Apply(el, ctx.DefaultStyle.Value);

            foreach (var a in ctx.Assignments)
            {
                var el = Find(ctx, a.Item1);
                if (el == null) continue;
                if (ctx.StyleDefs.TryGetValue(a.Item2, out var st)) Apply(el, st);
                el.StyleClass = a.Item2;
            }

            foreach (var s in ctx.StyleLines)
            {
                var el = Find(ctx, s.Item1);
                if (el != null) Apply(el, s.Item2);
            }
        }

        private static void Apply(IxElement el, Style st)
        {
            if (st.Fill != null) el.FillColor = st.Fill;
            if (st.Line != null) el.LineColor = st.Line;
            if (st.Text != null) el.TextColor = st.Text;
        }

        // External and late-annotated enums leave bare members behind; fold plain public
        // untyped fields back into literals once the whole model is known.
        private static void NormalizeEnums(Ctx ctx)
        {
            foreach (var el in ctx.Model.Elements)
            {
                if (el.Type != IxElementType.Enum) continue;
                for (int i = el.Members.Count - 1; i >= 0; i--)
                {
                    var m = el.Members[i];
                    if (!m.IsOperation && m.Type == null && m.DefaultValue == null &&
                        m.Parameters.Count == 0 && m.Visibility == IxVisibility.Public && !string.IsNullOrEmpty(m.Name))
                    {
                        el.EnumLiterals.Insert(0, m.Name);
                        el.Members.RemoveAt(i);
                    }
                }
            }
        }

        // --- element table ---------------------------------------------------------------------

        private static IxElement GetOrCreate(Ctx ctx, string id)
        {
            id = id.Trim();
            if (ctx.ById.TryGetValue(id, out var el)) return el;
            el = new IxElement { Id = id, Name = id, Type = IxElementType.Class };
            ctx.Model.Elements.Add(el);
            ctx.ById[id] = el;
            return el;
        }

        private static IxElement Find(Ctx ctx, string id) =>
            id != null && ctx.ById.TryGetValue(id, out var el) ? el : null;

        private static void SetNs(Ctx ctx, IxElement el)
        {
            if (el.ParentId == null && ctx.NsStack.Count > 0) el.ParentId = ctx.NsStack.Peek();
        }

        private static void ApplyAnnotation(IxElement el, string text)
        {
            switch (text.Trim().ToLowerInvariant())
            {
                case "interface": el.Type = IxElementType.Interface; break;
                case "enumeration":
                case "enum": el.Type = IxElementType.Enum; break;
                case "abstract": el.IsAbstract = true; break;
                default: el.Stereotype = text.Trim(); break;
            }
        }

        // --- color helpers ---------------------------------------------------------------------

        internal static string NormalizeColor(string raw)
        {
            if (string.IsNullOrWhiteSpace(raw)) return null;
            string s = raw.Trim();
            if (s.StartsWith("#"))
            {
                string hex = s.Substring(1);
                if (hex.Length == 3 && IsHex(hex))
                    return "#" + Dup(hex[0]) + Dup(hex[1]) + Dup(hex[2]);
                if ((hex.Length == 6 || hex.Length == 8) && IsHex(hex))
                    return "#" + hex.ToUpperInvariant();
                return s;
            }
            if (Named.TryGetValue(s.ToLowerInvariant(), out var mapped)) return mapped;
            return s;
        }

        private static string Dup(char c) { string u = char.ToUpperInvariant(c).ToString(); return u + u; }
        private static bool IsHex(string s) { foreach (var c in s) if (!IsHexChar(c)) return false; return true; }
        private static bool IsHexChar(char c) => (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');

        private static readonly Dictionary<string, string> Named = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            { "white", "#FFFFFF" }, { "black", "#000000" }, { "red", "#FF0000" }, { "green", "#008000" },
            { "lime", "#00FF00" }, { "blue", "#0000FF" }, { "yellow", "#FFFF00" }, { "cyan", "#00FFFF" },
            { "aqua", "#00FFFF" }, { "magenta", "#FF00FF" }, { "fuchsia", "#FF00FF" }, { "gray", "#808080" },
            { "grey", "#808080" }, { "silver", "#C0C0C0" }, { "maroon", "#800000" }, { "olive", "#808000" },
            { "navy", "#000080" }, { "teal", "#008080" }, { "purple", "#800080" }, { "orange", "#FFA500" },
            { "pink", "#FFC0CB" }, { "gold", "#FFD700" }, { "lightblue", "#ADD8E6" }, { "lightgreen", "#90EE90" },
            { "lightgrey", "#D3D3D3" }, { "lightgray", "#D3D3D3" }, { "darkgray", "#A9A9A9" }, { "darkgrey", "#A9A9A9" },
            { "darkblue", "#00008B" }, { "darkgreen", "#006400" }, { "darkred", "#8B0000" }, { "brown", "#A52A2A" },
            { "beige", "#F5F5DC" }, { "ivory", "#FFFFF0" }, { "khaki", "#F0E68C" }, { "salmon", "#FA8072" },
            { "coral", "#FF7F50" }, { "tan", "#D2B48C" }, { "violet", "#EE82EE" }, { "indigo", "#4B0082" },
        };

        // --- small helpers ---------------------------------------------------------------------

        internal static string ConvertGenericsIn(string s) =>
            string.IsNullOrEmpty(s) ? s : GenRx.Replace(s, "<${g}>");

        private static IxVisibility VisFromChar(char c)
        {
            switch (c)
            {
                case '-': return IxVisibility.Private;
                case '#': return IxVisibility.Protected;
                case '~': return IxVisibility.Package;
                default: return IxVisibility.Public;
            }
        }

        private static bool StartsWithWord(string s, string word)
        {
            if (!s.StartsWith(word, StringComparison.Ordinal)) return false;
            return s.Length == word.Length || char.IsWhiteSpace(s[word.Length]) ||
                   s[word.Length] == '{' || s[word.Length] == '"';
        }

        private static int FirstWhitespace(string s)
        {
            for (int i = 0; i < s.Length; i++) if (char.IsWhiteSpace(s[i])) return i;
            return -1;
        }

        private static int LastWhitespace(string s)
        {
            for (int i = s.Length - 1; i >= 0; i--) if (char.IsWhiteSpace(s[i])) return i;
            return -1;
        }

        private static string StripDots(string s) => s.Replace(".", "");
        private static string NullIfEmpty(string s) => string.IsNullOrEmpty(s) ? null : s;
        private static string UnescapeNote(string s) => s == null ? null : s.Replace("\\n", "\n");

        private struct Style { public string Fill, Line, Text; }

        private sealed class Ctx
        {
            public IxModel Model;
            public readonly Dictionary<string, IxElement> ById = new Dictionary<string, IxElement>();
            public readonly Stack<string> NsStack = new Stack<string>();
            public string OpenBody;
            public List<string> BodyLines = new List<string>();
            public readonly Dictionary<string, Style> StyleDefs = new Dictionary<string, Style>();
            public readonly List<(string, string)> Assignments = new List<(string, string)>();
            public readonly List<(string, Style)> StyleLines = new List<(string, Style)>();
            public Style? DefaultStyle;
            public int NoteSeq;
        }
    }
}
