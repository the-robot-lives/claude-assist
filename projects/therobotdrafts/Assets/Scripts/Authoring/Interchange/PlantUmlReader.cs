using System;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;

namespace TheRobotDraft.Authoring.Interchange
{
    /// <summary>
    /// PlantUML → <see cref="IxModel"/> reader (the first concrete reader of the docs/specs/file-formats.md §7
    /// interchange contract). Tolerant by design: it targets the constrained PlantUML profile the image-import
    /// vision prompt asks the LLM to emit, but degrades gracefully on hand-written diagrams — unknown lines are
    /// skipped, undeclared relation endpoints are auto-created, and the detected diagram family is recorded in
    /// <c>Diagrams[0].Kind</c> ("class", "usecase", "state", "activity", "sequence", "component", "mindmap").
    ///
    /// Families supported: class / ERD (classifiers, members, relations), use case, state machine, activity
    /// (both the arrow-based old syntax and the <c>:action;</c> new syntax), sequence (participants + messages),
    /// component / deployment, and <c>@startmindmap</c> mind maps. Notes (`note … of X`, `note "…" as N`) become
    /// <see cref="IxElementType.Note"/> elements with <see cref="IxEdgeType.NoteLink"/> edges.
    /// </summary>
    public static class PlantUmlReader
    {
        // ------------------------------------------------------------------ public API

        /// <summary>Parse PlantUML text into an IxModel. Throws <see cref="InterchangeException"/> when the text
        /// is empty or a wholly unsupported document type (e.g. @startsalt).</summary>
        public static IxModel Parse(string text)
        {
            if (string.IsNullOrWhiteSpace(text))
                throw new InterchangeException("empty PlantUML input");

            var lines = Preprocess(text);
            if (lines.Count == 0)
                throw new InterchangeException("no PlantUML content found");

            string family = DetectFamily(text, lines);
            if (family == "salt")
            {
                // Salt wireframe markup is a distinct UI-mockup grammar this reader does not structurally
                // parse. Rather than throw (which blocks batch conversion), degrade to a single Note
                // element carrying the raw source so the file round-trips and nothing is lost.
                return DegradedModel(text, lines, "salt");
            }

            var model = new IxModel { Name = FindTitle(lines) ?? FindStartName(lines) };
            model.Diagrams.Add(new IxDiagram { Id = "d1", Name = model.Name, Kind = family });

            switch (family)
            {
                case "mindmap": ParseMindmap(lines, model); break;
                case "sequence": ParseSequence(lines, model); break;
                case "activity": ParseActivity(lines, model); break;
                case "timing": ParseTiming(lines, model); break;
                default: ParseDeclarative(lines, model, family); break; // class / usecase / state / component
            }

            if (model.Elements.Count == 0)
                throw new InterchangeException("no recognizable elements in the PlantUML text");
            return model;
        }

        /// <summary>Classify the diagram family without a full parse (also used by the review UI header).</summary>
        public static string DetectFamily(string text)
        {
            return DetectFamily(text, Preprocess(text));
        }

        // ------------------------------------------------------------------ preprocessing

        /// <summary>Strip fences/@startuml wrappers, comments, and styling directives; join continuation-free
        /// trimmed lines. Keeps `end note` style block terminators so block scanners can see them.</summary>
        private static List<string> Preprocess(string text)
        {
            var outLines = new List<string>();
            if (text == null) return outLines;
            bool inLegend = false;
            foreach (var raw in text.Replace("\r\n", "\n").Replace('\r', '\n').Split('\n'))
            {
                string line = raw.Trim();
                if (line.Length == 0) continue;
                if (line.StartsWith("```")) continue;                     // markdown fences
                if (line.StartsWith("'")) continue;                       // line comment
                if (line.StartsWith("/'")) continue;                      // block comment (single-line form)
                if (line.StartsWith("@start") || line.StartsWith("@end")) { outLines.Add(line); continue; }
                if (inLegend) { if (Eq(line, "endlegend") || Eq(line, "end legend")) inLegend = false; continue; }
                if (StartsWithWord(line, "legend")) { inLegend = true; continue; }
                if (StartsWithWord(line, "skinparam") || StartsWithWord(line, "hide") || StartsWithWord(line, "show")
                    || StartsWithWord(line, "scale") || StartsWithWord(line, "!") || line.StartsWith("!")
                    || StartsWithWord(line, "autonumber") || StartsWithWord(line, "header") || StartsWithWord(line, "footer")
                    || StartsWithWord(line, "caption") || StartsWithWord(line, "left to right direction")
                    || StartsWithWord(line, "top to bottom direction") || StartsWithWord(line, "allowmixing")
                    || StartsWithWord(line, "allow_mixing") || StartsWithWord(line, "mainframe"))
                    continue;
                outLines.Add(line);
            }
            return outLines;
        }

        private static string FindTitle(List<string> lines)
        {
            foreach (var l in lines)
                if (StartsWithWord(l, "title"))
                    return Unquote(l.Substring(5).Trim());
            return null;
        }

        /// <summary>Recover the diagram name from <c>@startuml Name</c> (the form PlantUmlWriter emits) when no
        /// explicit <c>title</c> is present.</summary>
        private static string FindStartName(List<string> lines)
        {
            foreach (var l in lines)
            {
                var m = Regex.Match(l, @"^@startuml\s+(.+)$", RegexOptions.IgnoreCase);
                if (m.Success)
                {
                    string n = Unquote(m.Groups[1].Value.Trim());
                    if (n.Length > 0) return n;
                }
            }
            return null;
        }

        private static string DetectFamily(string text, List<string> lines)
        {
            if (text.IndexOf("@startmindmap", StringComparison.OrdinalIgnoreCase) >= 0) return "mindmap";
            if (text.IndexOf("@startsalt", StringComparison.OrdinalIgnoreCase) >= 0) return "salt";
            if (text.IndexOf("@startwbs", StringComparison.OrdinalIgnoreCase) >= 0) return "mindmap"; // WBS ≈ mindmap tree
            // Timing diagrams: PlantUML `robust`/`concise` lifelines plotted against an @N time axis.
            if (StartsWithWord(text, "robust") || StartsWithWord(text, "concise")
                || text.IndexOf("robust ", StringComparison.OrdinalIgnoreCase) >= 0
                || text.IndexOf("concise ", StringComparison.OrdinalIgnoreCase) >= 0) return "timing";

            int classScore = 0, seqScore = 0, stateScore = 0, activityScore = 0, usecaseScore = 0, componentScore = 0;
            foreach (var l in lines)
            {
                if (StartsWithWord(l, "class") || StartsWithWord(l, "abstract class") || StartsWithWord(l, "abstract")
                    || StartsWithWord(l, "interface") || StartsWithWord(l, "enum") || StartsWithWord(l, "entity")
                    || StartsWithWord(l, "struct")) classScore += 4;
                if (StartsWithWord(l, "participant") || StartsWithWord(l, "activate") || StartsWithWord(l, "deactivate")
                    || StartsWithWord(l, "alt ") || Eq(l, "alt") || StartsWithWord(l, "opt ") || StartsWithWord(l, "loop ")
                    || StartsWithWord(l, "autonumber") || StartsWithWord(l, "return")) seqScore += 4;
                if (l.Contains("[*]") || StartsWithWord(l, "state")) stateScore += 4;
                if (Eq(l, "start") || Eq(l, "stop") || Eq(l, "end") || Regex.IsMatch(l, @"^:.*[;|<>\]/}]$")
                    || l.StartsWith("(*)") || StartsWithWord(l, "fork") || StartsWithWord(l, "endif")
                    || StartsWithWord(l, "if (") || StartsWithWord(l, "if(")) activityScore += 3;
                if (StartsWithWord(l, "usecase") || Regex.IsMatch(l, @"^\([^)]+\)\s*(<?[-.]|as\b)")
                    || Regex.IsMatch(l, @"[-.]+>?\s*\([^)]+\)")) usecaseScore += 4;
                if (StartsWithWord(l, "actor")) usecaseScore += 2;
                if (StartsWithWord(l, "component") || Regex.IsMatch(l, @"^\[[^\]\*]+\]")
                    || Regex.IsMatch(l, @"[-.]+>?\s*\[[^\]\*]+\]")) componentScore += 3;
                if (StartsWithWord(l, "node") || StartsWithWord(l, "database") || StartsWithWord(l, "cloud")
                    || StartsWithWord(l, "artifact")) componentScore += 2;
                // Sequence messages: bare -> arrows with a ':' label and no structural keyword on the line.
                if (Regex.IsMatch(l, @"^[\w""][\w .""]*\s*[<]?[-]{1,2}[>]{1,2}\s*[\w""][\w .""]*\s*:")) seqScore += 1;
            }

            int best = Math.Max(classScore, Math.Max(seqScore, Math.Max(stateScore,
                Math.Max(activityScore, Math.Max(usecaseScore, componentScore)))));
            if (best == 0) return "class";
            if (best == stateScore) return "state";
            if (best == classScore) return "class";
            if (best == seqScore) return "sequence";
            if (best == usecaseScore) return "usecase";
            if (best == activityScore) return "activity";
            return "component";
        }

        // ------------------------------------------------------------------ shared helpers

        private static bool Eq(string a, string b) => string.Equals(a, b, StringComparison.OrdinalIgnoreCase);

        private static bool StartsWithWord(string line, string word)
        {
            // Case-sensitive: PlantUML element/directive keywords are lowercase, so a capitalized identifier
            // (e.g. a class literally named "Entity" in `Entity <|-- Customer`) must NOT match the `entity`
            // keyword and be misparsed as a declaration.
            if (!line.StartsWith(word, StringComparison.Ordinal)) return false;
            if (line.Length == word.Length) return true;
            char c = line[word.Length];
            return c == ' ' || c == '\t' || c == '(' || c == '"';
        }

        private static string Unquote(string s)
        {
            if (s == null) return null;
            s = s.Trim();
            if (s.Length >= 2 && s[0] == '"' && s[s.Length - 1] == '"') return s.Substring(1, s.Length - 2);
            return s;
        }

        /// <summary>Strip a trailing <c>#color</c> / <c>#color;line:x</c> decoration from a declaration tail.</summary>
        private static string StripColor(string s)
        {
            int hash = s.IndexOf('#');
            return hash >= 0 ? s.Substring(0, hash).Trim() : s;
        }

        /// <summary>Extract and remove a «stereotype» (<c>&lt;&lt;…&gt;&gt;</c>) from a declaration tail.</summary>
        private static string TakeStereotype(ref string s)
        {
            var m = Regex.Match(s, @"<<\s*([^>]*?)\s*>>");
            if (!m.Success) return null;
            s = (s.Substring(0, m.Index) + s.Substring(m.Index + m.Length)).Trim();
            return m.Groups[1].Value.Trim();
        }

        // ------------------------------------------------------------------ element registry (per parse)

        private sealed class Ctx
        {
            public IxModel Model;
            public string Family;
            public Dictionary<string, IxElement> ByKey = new Dictionary<string, IxElement>(StringComparer.OrdinalIgnoreCase);
            public Stack<IxElement> Containers = new Stack<IxElement>();
            public IxElement LastElement;      // for floating `note left : …`
            public int Synth;                  // synthesized-id counter
            public int EdgeSeq;

            public string ParentId => Containers.Count > 0 ? Containers.Peek().Id : null;

            public IxElement Declare(string key, string displayName, IxElementType type)
            {
                IxElement el;
                if (ByKey.TryGetValue(key, out el))
                {
                    // A later, more specific declaration upgrades an auto-created Unknown endpoint.
                    if (el.Type == IxElementType.Unknown && type != IxElementType.Unknown) el.Type = type;
                    if (!string.IsNullOrEmpty(displayName)) el.Name = displayName;
                    return el;
                }
                el = new IxElement
                {
                    Id = key,
                    Type = type,
                    Name = string.IsNullOrEmpty(displayName) ? key : displayName,
                    ParentId = ParentId,
                };
                ByKey[key] = el;
                Model.Elements.Add(el);
                LastElement = el;
                return el;
            }

            public IxElement Synthesize(string prefix, string name, IxElementType type)
            {
                string id;
                do { id = "~" + prefix + (++Synth); } while (ByKey.ContainsKey(id));
                return Declare(id, name, type);
            }

            public IxEdge AddEdge(IxEdgeType type, string fromId, string toId, string label,
                string fromMult = null, string toMult = null)
            {
                var e = new IxEdge
                {
                    Id = "e" + (++EdgeSeq),
                    Type = type,
                    FromId = fromId,
                    ToId = toId,
                    Label = string.IsNullOrEmpty(label) ? null : label,
                    FromMultiplicity = string.IsNullOrEmpty(fromMult) ? null : fromMult,
                    ToMultiplicity = string.IsNullOrEmpty(toMult) ? null : toMult,
                };
                Model.Edges.Add(e);
                return e;
            }
        }

        // ------------------------------------------------------------------ declaration keywords

        private static IxElementType KeywordType(string keyword, string family)
        {
            switch (keyword.ToLowerInvariant())
            {
                case "class": case "object": case "metaclass": case "protocol": case "exception": return IxElementType.Class;
                case "abstract": return IxElementType.Class; // "abstract class X" / "abstract X"
                case "interface": return IxElementType.Interface;
                case "enum": return IxElementType.Enum;
                case "struct": return IxElementType.Struct;
                case "entity": return family == "sequence" ? IxElementType.Lifeline : IxElementType.Table;
                case "actor": return family == "sequence" ? IxElementType.Lifeline : IxElementType.Actor;
                case "usecase": return IxElementType.UseCase;
                case "state": return IxElementType.State;
                case "component": return IxElementType.Component;
                case "node": return IxElementType.DeploymentNode;
                case "database": return family == "sequence" ? IxElementType.Lifeline : IxElementType.Database;
                case "cloud": return IxElementType.Cloud;
                case "artifact": case "file": return IxElementType.Artifact;
                case "boundary": case "control": case "collections": case "queue":
                    return family == "sequence" ? IxElementType.Lifeline : IxElementType.Boundary;
                case "rectangle": case "frame": return IxElementType.Boundary;
                case "package": case "folder": case "namespace": return IxElementType.Package;
                case "participant": return IxElementType.Lifeline;
                case "card": case "agent": case "storage": case "queue2": return IxElementType.Component;
                case "circle": case "diamond": return IxElementType.Decision;
                default: return IxElementType.Unknown;
            }
        }

        private static readonly string[] DeclKeywords =
        {
            "abstract class", "class", "interface", "enum", "struct", "entity", "actor", "usecase", "state",
            "component", "node", "database", "cloud", "artifact", "file", "boundary", "control", "collections",
            "queue", "rectangle", "frame", "package", "folder", "namespace", "participant", "object", "card",
            "agent", "storage", "abstract",
        };

        // ------------------------------------------------------------------ timing diagrams

        /// <summary>Minimal UML timing-diagram projection. Each <c>robust</c>/<c>concise</c> declaration is a
        /// Lifeline; each <c>@N</c> time point with <c>X is "State"</c> becomes a self-transition on that
        /// lifeline labelled with the time and the new state. The waveform's exact geometry isn't captured,
        /// but the lifelines, their states, and the ordering of state changes survive into the model.</summary>
        private static void ParseTiming(List<string> lines, IxModel model)
        {
            var aliasToEl = new Dictionary<string, IxElement>(StringComparer.OrdinalIgnoreCase);
            string currentTime = null;
            foreach (var raw in lines)
            {
                string l = raw.Trim();
                if (l.Length == 0) continue;
                // robust "Name" as Alias   /   concise "Name" as Alias
                var decl = Regex.Match(l, @"^(?:robust|concise)\s+""?([^""]+)""?\s+as\s+(\w+)", RegexOptions.IgnoreCase);
                if (decl.Success)
                {
                    string name = decl.Groups[1].Value, alias = decl.Groups[2].Value;
                    var el = new IxElement { Id = alias, Name = name, Type = IxElementType.Lifeline };
                    model.Elements.Add(el);
                    aliasToEl[alias] = el;
                    continue;
                }
                // @N  — a time observation; remember it for the next "X is State" line.
                var t = Regex.Match(l, @"^@(\d+)");
                if (t.Success) { currentTime = t.Groups[1].Value; continue; }
                // X is "State"  — state change at the current time point.
                var ch = Regex.Match(l, @"^(\w+)\s+is\s+""?([^""]+)""?", RegexOptions.IgnoreCase);
                if (ch.Success && aliasToEl.TryGetValue(ch.Groups[1].Value, out var owner))
                {
                    string state = ch.Groups[2].Value;
                    string label = (currentTime != null ? "@" + currentTime + " " : "") + "is " + state;
                    model.Edges.Add(new IxEdge
                    {
                        Id = "t" + model.Edges.Count,
                        Type = IxEdgeType.Transition,
                        FromId = owner.Id,
                        ToId = owner.Id,
                        Label = label
                    });
                }
            }
        }

        /// <summary>Degraded model for document types the reader cannot structurally parse (e.g. salt
        /// wireframes). Captures the raw source as a single Note element so the file converts and
        /// round-trips without loss, and tags the diagram kind so callers can detect the degraded path.</summary>
        private static IxModel DegradedModel(string text, List<string> lines, string family)
        {
            string title = FindTitle(lines) ?? FindStartName(lines) ?? family;
            var model = new IxModel { Name = title };
            model.Diagrams.Add(new IxDiagram { Id = "d1", Name = title, Kind = family });
            model.Elements.Add(new IxElement
            {
                Id = "src",
                Name = family + " source",
                Type = IxElementType.Note,
                Documentation = "[degraded — " + family + " markup not structurally parsed]\n" + text,
                Tags = { ["degraded"] = "true" }
            });
            return model;
        }

        // ------------------------------------------------------------------ declarative families (class / usecase / state / component)

        private static void ParseDeclarative(List<string> lines, IxModel model, string family)
        {
            var ctx = new Ctx { Model = model, Family = family };
            IxElement pendingBody = null;      // element whose `{ … }` body we are inside
            int bodyDepth = 0;

            for (int i = 0; i < lines.Count; i++)
            {
                string line = lines[i];
                if (line.StartsWith("@")) continue;
                if (StartsWithWord(line, "title")) continue;

                // ---- inside a classifier body: members / literals until the closing brace
                if (pendingBody != null)
                {
                    if (bodyDepth > 0)
                    {
                        // swallow nested blocks (rare) until they close
                        if (line == "}") bodyDepth--;
                        else if (line.EndsWith("{")) bodyDepth++;
                        continue;
                    }
                    if (line == "}" || line == "},") { pendingBody = null; continue; }
                    if (line.EndsWith("{")) { bodyDepth++; continue; }
                    ParseBodyLine(pendingBody, line);
                    continue;
                }

                // ---- container close
                if (line == "}")
                {
                    if (ctx.Containers.Count > 0) ctx.Containers.Pop();
                    continue;
                }

                // ---- notes
                if (StartsWithWord(line, "note") || StartsWithWord(line, "rnote") || StartsWithWord(line, "hnote"))
                {
                    i = ParseNote(lines, i, ctx);
                    continue;
                }
                if (Eq(line, "end note") || Eq(line, "endnote")) continue;

                // ---- declarations
                IxElement declared;
                bool opensBody, opensContainer;
                if (TryParseDeclaration(line, ctx, family, out declared, out opensBody, out opensContainer))
                {
                    if (opensContainer) ctx.Containers.Push(declared);
                    else if (opensBody) pendingBody = declared;
                    continue;
                }

                // ---- `X : member` shorthand (adds a member/description to an element)
                var colonShorthand = Regex.Match(line, @"^(""[^""]+""|[\w.\[\]()]+)\s*:\s*(.+)$");
                if (colonShorthand.Success && !ContainsArrow(line))
                {
                    var el = ResolveEndpoint(colonShorthand.Groups[1].Value, ctx, family);
                    if (el != null)
                    {
                        if (el.Type == IxElementType.State || family == "state")
                            el.Documentation = string.IsNullOrEmpty(el.Documentation)
                                ? colonShorthand.Groups[2].Value.Trim()
                                : el.Documentation + "\n" + colonShorthand.Groups[2].Value.Trim();
                        else
                            ParseBodyLine(el, colonShorthand.Groups[2].Value);
                    }
                    continue;
                }

                // ---- relations
                if (TryParseRelation(line, ctx, family)) continue;

                // anything else (skinparam leftovers, direction hints, etc.) is skipped
            }
        }

        /// <summary>Parse a `keyword Name …` declaration; returns false when the line isn't one.</summary>
        private static bool TryParseDeclaration(string line, Ctx ctx, string family,
            out IxElement element, out bool opensBody, out bool opensContainer)
        {
            element = null; opensBody = false; opensContainer = false;

            string matched = null;
            foreach (var kw in DeclKeywords)
                if (StartsWithWord(line, kw)) { matched = kw; break; }

            string rest;
            IxElementType type;
            if (matched != null)
            {
                rest = line.Substring(matched.Length).Trim();
                type = KeywordType(matched, family);
                if (Eq(matched, "abstract class") || Eq(matched, "abstract")) type = IxElementType.Class;
            }
            else if (family == "usecase" && Regex.IsMatch(line, @"^\([^)]+\)\s*(as\s+\S+)?\s*(<<[^>]*>>)?\s*$"))
            {
                // bare `(Do the thing)` or `(Do the thing) as UC1`
                rest = line; type = IxElementType.UseCase;
            }
            else if (family == "component" && Regex.IsMatch(line, @"^\[[^\]]+\]\s*(as\s+\S+)?\s*(<<[^>]*>>)?\s*$"))
            {
                rest = line; type = IxElementType.Component;
            }
            else return false;

            bool isAbstract = matched != null && (Eq(matched, "abstract class") || Eq(matched, "abstract"));

            // body / container braces
            if (rest.EndsWith("{"))
            {
                rest = rest.Substring(0, rest.Length - 1).Trim();
                if (type == IxElementType.Package || type == IxElementType.Boundary || type == IxElementType.State
                    || type == IxElementType.DeploymentNode || type == IxElementType.Cloud
                    || type == IxElementType.Database || type == IxElementType.Component)
                    opensContainer = true;
                else opensBody = true;
            }

            string stereo = TakeStereotype(ref rest);
            rest = StripColor(rest);

            // `"Display" as Alias`  |  `Name as "Display"`  |  `(text) as Alias`  |  `[text] as Alias`  |  `Name`
            string key = null, display = null, generics = null;
            var asMatch = Regex.Match(rest, @"^(.*?)\s+as\s+(.+)$", RegexOptions.IgnoreCase);
            if (asMatch.Success)
            {
                string left = asMatch.Groups[1].Value.Trim();
                string right = asMatch.Groups[2].Value.Trim();
                bool leftQuoted = left.StartsWith("\"") || left.StartsWith("(") || left.StartsWith("[");
                if (leftQuoted) { display = TrimWrappers(left); key = TrimWrappers(right); }
                else { key = TrimWrappers(left); display = TrimWrappers(right); }
            }
            else
            {
                key = TrimWrappers(rest);
                display = key;
            }
            if (string.IsNullOrEmpty(key)) return false;

            // generics: `class Cache<K,V>`
            var gen = Regex.Match(key, @"^(\S+?)\s*<\s*([^>]+)\s*>$");
            if (gen.Success) { key = gen.Groups[1].Value; generics = gen.Groups[2].Value.Trim(); }

            // state stereotypes flip the node type
            if (type == IxElementType.State && stereo != null)
            {
                string s = stereo.ToLowerInvariant();
                if (s == "choice") type = IxElementType.Decision;
                else if (s == "fork" || s == "join") type = IxElementType.ForkJoin;
                else if (s == "start") type = IxElementType.StateStart;
                else if (s == "end") type = IxElementType.StateEnd;
            }

            // «table» stereotype on a class marks an ERD table (round-trips PlantUmlWriter's Table output);
            // the type carries the semantics, so the stereotype text itself is dropped.
            if (stereo != null && (type == IxElementType.Class || type == IxElementType.Table) && Eq(stereo, "table"))
            {
                type = IxElementType.Table;
                stereo = null;
            }

            // Notation-fidelity stereotypes: a class/rectangle carrying one of these marks is promoted to a
            // first-class SysML/BPMN/DMN element type. The stereotype text is dropped (the type carries it),
            // mirroring the «table» rule above.
            if (stereo != null && type == IxElementType.Class)
            {
                string st = stereo.ToLowerInvariant();
                // SysML
                if (st == "block") { type = IxElementType.Block; stereo = null; }
                else if (st == "valuetype") { type = IxElementType.ValueType; stereo = null; }
                else if (st == "constraint") { type = IxElementType.Constraint; stereo = null; }
                else if (st == "requirement") { type = IxElementType.Requirement; stereo = null; }
                else if (st == "testcase" || st == "test") { type = IxElementType.TestCase; stereo = null; }
                // DMN
                else if (st == "decision") { type = IxElementType.DmnDecision; stereo = null; }
                else if (st == "inputdata" || st == "input") { type = IxElementType.InputData; stereo = null; }
                else if (st == "knowledgesource") { type = IxElementType.KnowledgeSource; stereo = null; }
                else if (st == "businessknowledge" || st == "businessknowledgemodel") { type = IxElementType.BusinessKnowledge; stereo = null; }
                // BPMN (also accepts the EA-style activity stereotype)
                else if (st == "bpmsubprocess" || st == "bpmnactivity" || st == "subprocess") { type = IxElementType.BpmnActivity; stereo = null; }
                else if (st == "bpmevent" || st == "event") { type = IxElementType.BpmnEvent; stereo = null; }
                else if (st == "bpmngateway" || st == "gateway") { type = IxElementType.BpmnGateway; stereo = null; }
                else if (st == "bpmndataobject" || st == "dataobject") { type = IxElementType.BpmnDataObject; stereo = null; }
                else if (st == "pool") { type = IxElementType.BpmnPool; stereo = null; }
                else if (st == "lane") { type = IxElementType.BpmnLane; stereo = null; }
            }

            element = ctx.Declare(key, display, type);
            element.IsAbstract = isAbstract || element.IsAbstract;
            if (stereo != null && element.Stereotype == null
                && !(type == IxElementType.Decision || type == IxElementType.ForkJoin)) element.Stereotype = stereo;
            if (generics != null) element.GenericParams = generics;
            return true;
        }

        private static string TrimWrappers(string s)
        {
            s = s.Trim();
            if (s.Length >= 2 && s[0] == '"' && s[s.Length - 1] == '"') return s.Substring(1, s.Length - 2).Trim();
            if (s.Length >= 2 && s[0] == '(' && s[s.Length - 1] == ')') return s.Substring(1, s.Length - 2).Trim();
            if (s.Length >= 2 && s[0] == '[' && s[s.Length - 1] == ']') return s.Substring(1, s.Length - 2).Trim();
            return s;
        }

        /// <summary>Add one classifier-body line as a member / enum literal / separator (skipped).</summary>
        private static void ParseBodyLine(IxElement owner, string line)
        {
            string t = line.Trim().TrimEnd(',', ';');
            if (t.Length == 0) return;
            if (Regex.IsMatch(t, @"^[-.=_]{2,}")) return;               // -- .. == __ separators
            if (t.StartsWith("'")) return;

            if (owner.Type == IxElementType.Enum && !t.Contains("(") && !t.Contains(":"))
            {
                owner.EnumLiterals.Add(Unquote(t));
                return;
            }

            var m = new IxMember { RawText = t };
            string s = t;

            // modifiers
            while (true)
            {
                var mod = Regex.Match(s, @"^\{(static|abstract|classifier|field|method)\}\s*", RegexOptions.IgnoreCase);
                if (!mod.Success) break;
                string w = mod.Groups[1].Value.ToLowerInvariant();
                if (w == "static" || w == "classifier") m.IsStatic = true;
                if (w == "abstract") m.IsAbstract = true;
                s = s.Substring(mod.Length);
            }

            if (s.Length > 0)
            {
                switch (s[0])
                {
                    case '+': m.Visibility = IxVisibility.Public; s = s.Substring(1).Trim(); break;
                    case '-': m.Visibility = IxVisibility.Private; s = s.Substring(1).Trim(); break;
                    case '#': m.Visibility = IxVisibility.Protected; s = s.Substring(1).Trim(); break;
                    case '~': m.Visibility = IxVisibility.Package; s = s.Substring(1).Trim(); break;
                }
            }

            int paren = s.IndexOf('(');
            m.IsOperation = paren >= 0;
            if (m.IsOperation)
            {
                m.Name = s.Substring(0, paren).Trim();
                int close = s.LastIndexOf(')');
                string args = close > paren ? s.Substring(paren + 1, close - paren - 1) : "";
                foreach (var a in SplitArgs(args))
                {
                    string an = a.Trim();
                    if (an.Length == 0) continue;
                    var p = new IxParam();
                    int c = an.IndexOf(':');
                    if (c >= 0) { p.Name = an.Substring(0, c).Trim(); p.Type = an.Substring(c + 1).Trim(); }
                    else p.Name = an;
                    m.Parameters.Add(p);
                }
                string tail = close >= 0 && close + 1 < s.Length ? s.Substring(close + 1).Trim() : "";
                if (tail.StartsWith(":")) m.Type = tail.Substring(1).Trim();
            }
            else
            {
                int c = s.IndexOf(':');
                if (c >= 0)
                {
                    m.Name = s.Substring(0, c).Trim();
                    string rest = s.Substring(c + 1).Trim();
                    int eq = rest.IndexOf('=');
                    if (eq >= 0) { m.Type = rest.Substring(0, eq).Trim(); m.DefaultValue = rest.Substring(eq + 1).Trim(); }
                    else m.Type = rest;
                }
                else
                {
                    int eq = s.IndexOf('=');
                    if (eq >= 0) { m.Name = s.Substring(0, eq).Trim(); m.DefaultValue = s.Substring(eq + 1).Trim(); }
                    else m.Name = s.Trim();
                }
            }
            if (string.IsNullOrEmpty(m.Name)) return;
            owner.Members.Add(m);
        }

        private static IEnumerable<string> SplitArgs(string args)
        {
            var list = new List<string>();
            int depth = 0, start = 0;
            for (int i = 0; i < args.Length; i++)
            {
                char c = args[i];
                if (c == '<' || c == '(' || c == '[') depth++;
                else if (c == '>' || c == ')' || c == ']') depth--;
                else if (c == ',' && depth == 0) { list.Add(args.Substring(start, i - start)); start = i + 1; }
            }
            if (start < args.Length) list.Add(args.Substring(start));
            return list;
        }

        // ------------------------------------------------------------------ notes

        /// <summary>Parse `note … of X : text`, `note … of X … end note`, `note "text" as N`, or a floating
        /// `note left : text`. Returns the (possibly advanced) line index.</summary>
        private static int ParseNote(List<string> lines, int i, Ctx ctx)
        {
            string line = lines[i];
            string body = Regex.Replace(line, @"^[rh]?note\s+", "", RegexOptions.IgnoreCase);

            // `note "text" as N` — decode the writer's \n escapes back into real newlines.
            var named = Regex.Match(body, @"^""([^""]*)""\s+as\s+(\S+)\s*$", RegexOptions.IgnoreCase);
            if (named.Success)
            {
                string noteText = named.Groups[1].Value.Replace("\\n", "\n");
                var el = ctx.Declare(named.Groups[2].Value, noteText, IxElementType.Note);
                el.Documentation = noteText;
                return i;
            }

            // `note left|right|top|bottom [of X]` with either `: text` inline or a block until `end note`
            var m = Regex.Match(body,
                @"^(left|right|top|bottom|over)\s*(?:of\s+)?(""[^""]+""|[\w.()\[\]]+)?\s*(?:#\S+\s*)?(?::\s*(.*))?$",
                RegexOptions.IgnoreCase);
            if (!m.Success) return i;

            string targetTok = m.Groups[2].Success ? m.Groups[2].Value : null;
            string text = m.Groups[3].Success ? m.Groups[3].Value.Trim() : null;

            if (text == null)
            {
                var sb = new StringBuilder();
                int j = i + 1;
                for (; j < lines.Count; j++)
                {
                    if (Eq(lines[j], "end note") || Eq(lines[j], "endnote") || Eq(lines[j], "end rnote")
                        || Eq(lines[j], "end hnote")) break;
                    if (sb.Length > 0) sb.Append('\n');
                    sb.Append(lines[j]);
                }
                text = sb.ToString();
                i = j;
            }
            if (string.IsNullOrWhiteSpace(text)) return i;

            var note = ctx.Synthesize("note", FirstLine(text), IxElementType.Note);
            note.Documentation = text;

            IxElement target = null;
            if (targetTok != null) target = ResolveEndpoint(targetTok, ctx, ctx.Family);
            else target = ctx.LastElement != note ? ctx.LastElement : null;
            if (target != null && target != note)
                ctx.AddEdge(IxEdgeType.NoteLink, note.Id, target.Id, null);
            return i;
        }

        private static string FirstLine(string s)
        {
            int nl = s.IndexOf('\n');
            string first = nl >= 0 ? s.Substring(0, nl) : s;
            return first.Length > 48 ? first.Substring(0, 48) + "…" : first;
        }

        // ------------------------------------------------------------------ relations

        private static readonly Regex ArrowRegex = new Regex(
            @"^(?<lh><\||<<|<|o|\*|\+|#|x|\})?(?<shaft>[-.~=]{1,4})(?<rh>\|>|>>|>|o|\*|\+|#|x|\{)?$",
            RegexOptions.Compiled);

        private static bool ContainsArrow(string line)
        {
            foreach (var tok in line.Split(' ', '\t'))
                if (tok.Length > 0 && ArrowRegex.IsMatch(StripDirection(tok))) return true;
            return false;
        }

        private static string StripDirection(string arrow)
        {
            return Regex.Replace(arrow, @"(?<=[-.])(left|right|up|down|le?|ri?|u|d)(?=[-.])", "", RegexOptions.IgnoreCase);
        }

        /// <summary>Scan a line as `endpoint ["mult"] arrow ["mult"] endpoint [: label]`; add the edge on success.</summary>
        private static bool TryParseRelation(string line, Ctx ctx, string family)
        {
            int pos = 0;
            string leftTok = ReadEndpoint(line, ref pos);
            if (leftTok == null) return false;
            SkipWs(line, ref pos);
            string leftMult = ReadQuoted(line, ref pos);
            SkipWs(line, ref pos);
            string arrowTok = ReadRun(line, ref pos);
            if (arrowTok == null) return false;
            arrowTok = StripDirection(arrowTok);
            var arrow = ArrowRegex.Match(arrowTok);
            if (!arrow.Success || arrow.Groups["shaft"].Value.Length == 0) return false;
            SkipWs(line, ref pos);
            string rightMult = ReadQuoted(line, ref pos);
            SkipWs(line, ref pos);
            string rightTok = ReadEndpoint(line, ref pos);
            if (rightTok == null) return false;
            SkipWs(line, ref pos);
            string label = null;
            if (pos < line.Length && line[pos] == ':') label = line.Substring(pos + 1).Trim();
            else if (pos < line.Length && line.Substring(pos).Trim().Length > 0
                     && !line.Substring(pos).TrimStart().StartsWith("#")) return false; // trailing junk → not a relation

            var from = ResolveEndpoint(leftTok, ctx, family, true);
            var to = ResolveEndpoint(rightTok, ctx, family, false);
            if (from == null || to == null) return false;

            string lh = arrow.Groups["lh"].Value, rh = arrow.Groups["rh"].Value;
            bool dotted = arrow.Groups["shaft"].Value.IndexOf('.') >= 0;

            // «include» / «extend» via the label
            string cleanLabel = label;
            var stereoInLabel = cleanLabel != null ? TakeStereotype(ref cleanLabel) : null;

            IxEdgeType type;
            IxElement eFrom = from, eTo = to;

            if (from.Type == IxElementType.Note || to.Type == IxElementType.Note)
            {
                type = IxEdgeType.NoteLink;
                if (to.Type == IxElementType.Note && from.Type != IxElementType.Note) { eFrom = to; eTo = from; }
            }
            else if (stereoInLabel != null && Eq(stereoInLabel, "include")) { type = IxEdgeType.Include; }
            else if (stereoInLabel != null && Eq(stereoInLabel, "extend")) { type = IxEdgeType.Extend; }
            else if (stereoInLabel != null && Eq(stereoInLabel, "extension")) { type = IxEdgeType.Extension; }
            // SysML / requirements-traceability relationships (from «satisfy», «verify», «deriveReqt», ...)
            else if (stereoInLabel != null && Eq(stereoInLabel, "satisfy")) { type = IxEdgeType.Satisfy; }
            else if (stereoInLabel != null && Eq(stereoInLabel, "verify")) { type = IxEdgeType.Verify; }
            else if (stereoInLabel != null && (Eq(stereoInLabel, "derive") || Eq(stereoInLabel, "derivereqt"))) { type = IxEdgeType.Derive; }
            else if (stereoInLabel != null && Eq(stereoInLabel, "refine")) { type = IxEdgeType.Refine; }
            else if (stereoInLabel != null && Eq(stereoInLabel, "trace")) { type = IxEdgeType.Trace; }
            else if (stereoInLabel != null && Eq(stereoInLabel, "copy")) { type = IxEdgeType.Copy; }
            // BPMN message flow (dashed arrow with the «messageFlow» stereotype, or the canonical
            // <<messageFlow>> used to distinguish cross-pool messages from plain sequence flow).
            else if (stereoInLabel != null && Eq(stereoInLabel, "messageflow")) { type = IxEdgeType.MessageFlow; }
            else if (stereoInLabel != null && Eq(stereoInLabel, "sequenceflow")) { type = IxEdgeType.SequenceFlow; }
            else if (lh == "<|" || rh == "|>")
            {
                // arrowhead marks the parent; normalize From=child, To=parent
                type = dotted ? IxEdgeType.Realization : IxEdgeType.Generalization;
                if (lh == "<|") { eFrom = to; eTo = from; }
            }
            else if (lh == "*" || rh == "*")
            {
                type = IxEdgeType.Composition; // whole at the * side
                if (rh == "*") { eFrom = to; eTo = from; }
            }
            else if (lh == "o" || rh == "o")
            {
                type = IxEdgeType.Aggregation;
                if (rh == "o") { eFrom = to; eTo = from; }
            }
            else if (lh == "<" || lh == "<<" || rh == ">" || rh == ">>")
            {
                bool reversed = lh == "<" || lh == "<<";
                if (reversed) { eFrom = to; eTo = from; string tm = leftMult; leftMult = rightMult; rightMult = tm; }
                if (family == "state" || family == "activity"
                    || IsBehavioral(eFrom.Type) || IsBehavioral(eTo.Type)) type = IxEdgeType.Transition;
                else if (IsBpmn(eFrom.Type) || IsBpmn(eTo.Type))
                {
                    // BPMN: solid = sequence flow, dotted = message flow (cross-pool).
                    type = dotted ? IxEdgeType.MessageFlow : IxEdgeType.SequenceFlow;
                }
                else if (family == "sequence")
                {
                    // Sequence-diagram convention: `->` solid call, `-->` (two dashes) IS the dotted reply arrow.
                    bool seqDotted = dotted || arrow.Groups["shaft"].Value.Length > 1;
                    type = (lh == "<<" || rh == ">>") ? IxEdgeType.MessageAsync
                        : seqDotted ? IxEdgeType.MessageReply
                        : IxEdgeType.MessageSync;
                }
                else type = dotted ? IxEdgeType.Dependency : IxEdgeType.DirectedAssociation;
            }
            else
            {
                type = dotted ? IxEdgeType.Dependency : IxEdgeType.Association;
            }

            ctx.AddEdge(type, eFrom.Id, eTo.Id,
                string.IsNullOrEmpty(cleanLabel) ? (stereoInLabel != null && type != IxEdgeType.Include && type != IxEdgeType.Extend && type != IxEdgeType.Extension ? stereoInLabel : cleanLabel) : cleanLabel,
                eFrom == from ? leftMult : rightMult,
                eFrom == from ? rightMult : leftMult);
            return true;
        }

        private static bool IsBehavioral(IxElementType t)
        {
            return t == IxElementType.State || t == IxElementType.StateStart || t == IxElementType.StateEnd
                || t == IxElementType.Decision || t == IxElementType.ForkJoin || t == IxElementType.Activity
                || t == IxElementType.FlowFinal;
        }

        /// <summary>True for BPMN flow-object element types. A plain arrow between two BPMN elements is a
        /// BPMN sequence flow, not a generic association.</summary>
        private static bool IsBpmn(IxElementType t)
        {
            return t == IxElementType.BpmnEvent || t == IxElementType.BpmnActivity
                || t == IxElementType.BpmnGateway || t == IxElementType.BpmnDataObject;
        }

        private static void SkipWs(string s, ref int pos)
        {
            while (pos < s.Length && (s[pos] == ' ' || s[pos] == '\t')) pos++;
        }

        private static string ReadQuoted(string s, ref int pos)
        {
            if (pos >= s.Length || s[pos] != '"') return null;
            int end = s.IndexOf('"', pos + 1);
            if (end < 0) return null;
            string v = s.Substring(pos + 1, end - pos - 1);
            pos = end + 1;
            return v;
        }

        /// <summary>Read a relation endpoint token: `"quoted"`, `(usecase)`, `[component]`, `[*]`, `(*)`, or a bare word.</summary>
        private static string ReadEndpoint(string s, ref int pos)
        {
            if (pos >= s.Length) return null;
            char c = s[pos];
            if (c == '"')
            {
                int end = s.IndexOf('"', pos + 1);
                if (end < 0) return null;
                string v = s.Substring(pos, end - pos + 1);
                pos = end + 1;
                return v;
            }
            if (c == '(' || c == '[')
            {
                char close = c == '(' ? ')' : ']';
                int end = s.IndexOf(close, pos + 1);
                if (end < 0) return null;
                string v = s.Substring(pos, end - pos + 1);
                pos = end + 1;
                return v;
            }
            int start = pos;
            while (pos < s.Length && !char.IsWhiteSpace(s[pos]) && s[pos] != ':') pos++;
            if (pos == start) return null;
            return s.Substring(start, pos - start);
        }

        /// <summary>Read a whitespace-delimited run (candidate arrow token).</summary>
        private static string ReadRun(string s, ref int pos)
        {
            int start = pos;
            while (pos < s.Length && !char.IsWhiteSpace(s[pos])) pos++;
            return pos > start ? s.Substring(start, pos - start) : null;
        }

        /// <summary>Resolve (or auto-create) the element a relation endpoint token refers to. For the `[*]` / `(*)`
        /// pseudo-state, syntactic position decides: as a relation source it is the initial node, as a target the
        /// final node (matching PlantUML semantics); each is shared across the diagram.</summary>
        private static IxElement ResolveEndpoint(string token, Ctx ctx, string family, bool asSource = true)
        {
            if (token == null) return null;
            token = token.Trim();
            if (token.Length == 0) return null;

            if (token == "[*]" || token == "(*)")
            {
                string cacheKey = token + (asSource ? "start" : "end");
                IxElement pseudo;
                if (!ctx.ByKey.TryGetValue(cacheKey, out pseudo))
                {
                    pseudo = asSource
                        ? ctx.Synthesize("start", "start", IxElementType.StateStart)
                        : ctx.Synthesize("end", "end", IxElementType.StateEnd);
                    ctx.ByKey[cacheKey] = pseudo;
                }
                return pseudo;
            }

            IxElementType autoType = IxElementType.Unknown;
            string key = token, display = null;
            if (token.StartsWith("(") && token.EndsWith(")"))
            {
                display = token.Substring(1, token.Length - 2).Trim();
                key = display; autoType = IxElementType.UseCase;
            }
            else if (token.StartsWith("[") && token.EndsWith("]"))
            {
                display = token.Substring(1, token.Length - 2).Trim();
                key = display; autoType = IxElementType.Component;
            }
            else if (token.StartsWith("\"") && token.EndsWith("\""))
            {
                display = Unquote(token);
                key = display;
                if (family == "activity") autoType = IxElementType.Activity;
            }
            else if (token.StartsWith(":") && token.EndsWith(":") && token.Length > 2)
            {
                display = token.Substring(1, token.Length - 2);
                key = display; autoType = IxElementType.Actor;   // :Actor: shorthand
            }

            if (autoType == IxElementType.Unknown)
            {
                if (family == "state") autoType = IxElementType.State;
                else if (family == "activity") autoType = IxElementType.Activity;
                else if (family == "sequence") autoType = IxElementType.Lifeline;
                else if (family == "component") autoType = IxElementType.Component;
                else if (family == "usecase") autoType = IxElementType.Actor;   // bare names in usecase ≈ actors
                else autoType = IxElementType.Class;
            }
            return ctx.Declare(key, display, autoType);
        }

        // ------------------------------------------------------------------ sequence

        private static void ParseSequence(List<string> lines, IxModel model)
        {
            var ctx = new Ctx { Model = model, Family = "sequence" };
            for (int i = 0; i < lines.Count; i++)
            {
                string line = lines[i];
                if (line.StartsWith("@")) continue;
                if (StartsWithWord(line, "title")) continue;
                if (StartsWithWord(line, "activate") || StartsWithWord(line, "deactivate")
                    || StartsWithWord(line, "destroy") || StartsWithWord(line, "create")
                    || StartsWithWord(line, "alt") || StartsWithWord(line, "else") || StartsWithWord(line, "opt")
                    || StartsWithWord(line, "loop") || StartsWithWord(line, "par") || StartsWithWord(line, "group")
                    || StartsWithWord(line, "break") || StartsWithWord(line, "critical") || Eq(line, "end")
                    || line.StartsWith("==") || line.StartsWith("...") || StartsWithWord(line, "ref")
                    || StartsWithWord(line, "return") || StartsWithWord(line, "delay"))
                    continue;
                if (StartsWithWord(line, "note") || StartsWithWord(line, "rnote") || StartsWithWord(line, "hnote"))
                { i = ParseNote(lines, i, ctx); continue; }
                if (Eq(line, "end note") || Eq(line, "endnote")) continue;

                IxElement declared; bool b1, b2;
                if (TryParseDeclaration(line, ctx, "sequence", out declared, out b1, out b2))
                {
                    if (declared.Type == IxElementType.Actor) declared.Type = IxElementType.Lifeline;
                    if (declared.Stereotype == null && StartsWithWord(line, "actor")) declared.Stereotype = "actor";
                    continue;
                }

                TryParseRelation(line, ctx, "sequence");
            }
        }

        // ------------------------------------------------------------------ activity (new `:action;` syntax + old arrows)

        private static void ParseActivity(List<string> lines, IxModel model)
        {
            var ctx = new Ctx { Model = model, Family = "activity" };
            var frontier = new List<IxElement>();
            string pendingLabel = null;

            var ifStack = new Stack<IfFrame>();
            var forkStack = new Stack<ForkFrame>();
            var repeatStack = new Stack<IxElement>();
            var whileStack = new Stack<WhileFrame>();

            Action<IxElement, string> connectFrontier = (target, label) =>
            {
                foreach (var f in frontier)
                    ctx.AddEdge(IxEdgeType.Transition, f.Id, target.Id, label);
                frontier.Clear();
            };

            StringBuilder multi = null; // multi-line `:action …;` accumulator

            for (int i = 0; i < lines.Count; i++)
            {
                string line = lines[i];
                if (line.StartsWith("@")) continue;
                if (StartsWithWord(line, "title")) continue;
                if (StartsWithWord(line, "note") || StartsWithWord(line, "rnote") || StartsWithWord(line, "hnote"))
                { i = ParseNote(lines, i, ctx); continue; }
                if (Eq(line, "end note") || Eq(line, "endnote")) continue;
                if (StartsWithWord(line, "partition") || line == "}" || StartsWithWord(line, "swimlane")
                    || line.StartsWith("|")) continue;
                if (StartsWithWord(line, "detach")) { frontier.Clear(); continue; }

                // multi-line action continuation
                if (multi != null)
                {
                    multi.Append('\n').Append(line.TrimEnd(';'));
                    if (line.EndsWith(";"))
                    {
                        var actEl = ctx.Synthesize("act", multi.ToString().Trim(), IxElementType.Activity);
                        connectFrontier(actEl, pendingLabel); pendingLabel = null;
                        frontier.Add(actEl);
                        multi = null;
                    }
                    continue;
                }

                // `-> label;` / `-[#color]-> label;` between activities
                var lbl = Regex.Match(line, @"^-(\[[^\]]*\])?->\s*(.*?);?$");
                if (lbl.Success) { pendingLabel = lbl.Groups[2].Value.Trim(); continue; }

                if (Eq(line, "start"))
                {
                    var st = ctx.Synthesize("start", "start", IxElementType.StateStart);
                    frontier.Clear(); frontier.Add(st);
                    continue;
                }
                if (Eq(line, "stop") || Eq(line, "end"))
                {
                    var en = ctx.Synthesize("end", "end",
                        Eq(line, "stop") ? IxElementType.StateEnd : IxElementType.FlowFinal);
                    connectFrontier(en, pendingLabel); pendingLabel = null;
                    continue;
                }
                if (Eq(line, "kill")) { frontier.Clear(); continue; }

                // `:action;` — possibly multi-line, possibly with a trailing shape char (| < > / ])
                if (line.StartsWith(":"))
                {
                    string body = line.Substring(1);
                    if (Regex.IsMatch(body, @"[;|<>\]/}]$"))
                    {
                        body = body.Substring(0, body.Length - 1).Trim();
                        var actEl = ctx.Synthesize("act", body, IxElementType.Activity);
                        connectFrontier(actEl, pendingLabel); pendingLabel = null;
                        frontier.Add(actEl);
                    }
                    else multi = new StringBuilder(body);
                    continue;
                }

                // if / elseif / else / endif
                var ifm = Regex.Match(line, @"^if\s*\((.*?)\)\s*(?:then\s*(?:\((.*?)\))?)?\s*$", RegexOptions.IgnoreCase);
                if (ifm.Success)
                {
                    var dec = ctx.Synthesize("dec", ifm.Groups[1].Value.Trim(), IxElementType.Decision);
                    connectFrontier(dec, pendingLabel); pendingLabel = null;
                    var frame = new IfFrame { Decision = dec, HadElse = false };
                    ifStack.Push(frame);
                    frontier.Add(dec);
                    pendingLabel = ifm.Groups[2].Success ? ifm.Groups[2].Value.Trim() : "yes";
                    continue;
                }
                var elifm = Regex.Match(line, @"^else\s*if\s*\((.*?)\)\s*(?:then\s*(?:\((.*?)\))?)?\s*$", RegexOptions.IgnoreCase);
                if (!elifm.Success)
                    elifm = Regex.Match(line, @"^elseif\s*\((.*?)\)\s*(?:then\s*(?:\((.*?)\))?)?\s*$", RegexOptions.IgnoreCase);
                if (elifm.Success && ifStack.Count > 0)
                {
                    var frame = ifStack.Peek();
                    frame.Merged.AddRange(frontier); frontier.Clear();
                    var dec2 = ctx.Synthesize("dec", elifm.Groups[1].Value.Trim(), IxElementType.Decision);
                    ctx.AddEdge(IxEdgeType.Transition, frame.Decision.Id, dec2.Id, "no");
                    frame.Decision = dec2; frame.HadElse = false;
                    frontier.Add(dec2);
                    pendingLabel = elifm.Groups[2].Success ? elifm.Groups[2].Value.Trim() : "yes";
                    continue;
                }
                var elsem = Regex.Match(line, @"^else\s*(?:\((.*?)\))?\s*$", RegexOptions.IgnoreCase);
                if (elsem.Success && ifStack.Count > 0)
                {
                    var frame = ifStack.Peek();
                    frame.Merged.AddRange(frontier); frontier.Clear();
                    frame.HadElse = true;
                    frontier.Add(frame.Decision);
                    pendingLabel = elsem.Groups[1].Success ? elsem.Groups[1].Value.Trim() : "no";
                    continue;
                }
                if (Eq(line, "endif") && ifStack.Count > 0)
                {
                    var frame = ifStack.Pop();
                    frame.Merged.AddRange(frontier); frontier.Clear();
                    frontier.AddRange(frame.Merged);
                    if (!frame.HadElse) frontier.Add(frame.Decision); // untaken "no" branch flows onward
                    pendingLabel = null;
                    continue;
                }

                // while / endwhile
                var wm = Regex.Match(line, @"^while\s*\((.*?)\)\s*(?:is\s*\((.*?)\))?\s*$", RegexOptions.IgnoreCase);
                if (wm.Success)
                {
                    var dec = ctx.Synthesize("loop", wm.Groups[1].Value.Trim(), IxElementType.Decision);
                    connectFrontier(dec, pendingLabel); pendingLabel = null;
                    whileStack.Push(new WhileFrame { Decision = dec });
                    frontier.Add(dec);
                    pendingLabel = wm.Groups[2].Success ? wm.Groups[2].Value.Trim() : "yes";
                    continue;
                }
                var ewm = Regex.Match(line, @"^endwhile\s*(?:\((.*?)\))?\s*$", RegexOptions.IgnoreCase);
                if (ewm.Success && whileStack.Count > 0)
                {
                    var frame = whileStack.Pop();
                    foreach (var f in frontier)
                        ctx.AddEdge(IxEdgeType.Transition, f.Id, frame.Decision.Id, null); // loop back
                    frontier.Clear();
                    frontier.Add(frame.Decision);
                    pendingLabel = ewm.Groups[1].Success ? ewm.Groups[1].Value.Trim() : "no";
                    continue;
                }

                // repeat / repeat while
                if (Eq(line, "repeat"))
                {
                    repeatStack.Push(null); // marker; entry node is the next created node
                    continue;
                }
                var rwm = Regex.Match(line, @"^repeat\s*while\s*\((.*?)\)\s*(?:is\s*\((.*?)\))?\s*(?:not\s*\((.*?)\))?\s*$", RegexOptions.IgnoreCase);
                if (rwm.Success)
                {
                    var dec = ctx.Synthesize("loop", rwm.Groups[1].Value.Trim(), IxElementType.Decision);
                    connectFrontier(dec, pendingLabel); pendingLabel = null;
                    if (repeatStack.Count > 0) repeatStack.Pop();
                    frontier.Add(dec);
                    pendingLabel = rwm.Groups[3].Success ? rwm.Groups[3].Value.Trim() : "no";
                    continue;
                }

                // fork / fork again / end fork
                if (Eq(line, "fork"))
                {
                    var bar = ctx.Synthesize("fork", "fork", IxElementType.ForkJoin);
                    connectFrontier(bar, pendingLabel); pendingLabel = null;
                    forkStack.Push(new ForkFrame { Bar = bar });
                    frontier.Add(bar);
                    continue;
                }
                if (Eq(line, "fork again") && forkStack.Count > 0)
                {
                    var frame = forkStack.Peek();
                    frame.Merged.AddRange(frontier); frontier.Clear();
                    frontier.Add(frame.Bar);
                    continue;
                }
                if ((Eq(line, "end fork") || Eq(line, "endfork") || Eq(line, "end merge")) && forkStack.Count > 0)
                {
                    var frame = forkStack.Pop();
                    frame.Merged.AddRange(frontier); frontier.Clear();
                    var join = ctx.Synthesize("join", "join", IxElementType.ForkJoin);
                    foreach (var f in frame.Merged) ctx.AddEdge(IxEdgeType.Transition, f.Id, join.Id, null);
                    frontier.Add(join);
                    continue;
                }

                // old-syntax arrows: `(*) --> "Do thing"` — reuse the generic relation parser
                if (TryParseRelation(line, ctx, "activity")) { pendingLabel = null; continue; }
            }
        }

        private sealed class IfFrame
        {
            public IxElement Decision;
            public bool HadElse;
            public List<IxElement> Merged = new List<IxElement>();
        }

        private sealed class ForkFrame
        {
            public IxElement Bar;
            public List<IxElement> Merged = new List<IxElement>();
        }

        private sealed class WhileFrame
        {
            public IxElement Decision;
        }

        // ------------------------------------------------------------------ mindmap

        private static void ParseMindmap(List<string> lines, IxModel model)
        {
            var ctx = new Ctx { Model = model, Family = "mindmap" };
            var stack = new List<IxElement>(); // stack[d] = last node at depth d (1-based → index d-1)

            foreach (var raw in lines)
            {
                string line = raw;
                if (line.StartsWith("@")) continue;
                if (StartsWithWord(line, "title")) continue;

                var m = Regex.Match(line, @"^(?<marker>\*+|\++|-+)(?<nb>_)?\s*(?:\[#\w+\]\s*)?(?<text>.+)$");
                if (!m.Success) continue;
                int depth = m.Groups["marker"].Value.Length;
                string text = m.Groups["text"].Value.Trim();
                if (text.Length == 0) continue;
                if (text.StartsWith(":") && text.EndsWith(";")) text = text.Substring(1, text.Length - 2).Trim();

                var node = ctx.Synthesize("mm", text, IxElementType.MindNode);
                if (depth > 1)
                {
                    int parentDepth = Math.Min(depth - 1, stack.Count);
                    if (parentDepth >= 1)
                        ctx.AddEdge(IxEdgeType.DirectedAssociation, stack[parentDepth - 1].Id, node.Id, null);
                }
                // record this node at its depth
                while (stack.Count < depth) stack.Add(node);
                stack[depth - 1] = node;
                if (stack.Count > depth) stack.RemoveRange(depth, stack.Count - depth);
            }
        }
    }
}
