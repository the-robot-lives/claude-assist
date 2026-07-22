using System;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.CodeGen
{
    /// <summary>
    /// The extraction counterpart to <see cref="CodeSkeleton.EmitAspects"/> + <see cref="AspectSidecar"/>. It reads
    /// previously-generated source text (and/or a meta sidecar) and recovers the <see cref="AspectInstance"/> list +
    /// <see cref="FreeformEntry"/> list the code was emitted from — the back-half of the bidirectional round-trip.
    ///
    /// <para>Three carriers are recognized, in this precedence:
    /// <list type="number">
    /// <item><term>&lt;aspect&gt; doc-tag block</term><description>the authoritative, machine-parseable form emitted
    /// when an aspect's <c>DocTag</c> flag is set. Survives every language because it rides in a comment block.</description></item>
    /// <item><term>comment carrier</term><description><c>aspect NAME (vN):</c> … <c>key = value</c> lines, emitted when
    /// only <c>Comment</c> is set. Same recovery, looser syntax.</description></item>
    /// <item><term>native attribute/decorator</term><description>best-effort: <c>[Name(k = v)]</c> (C#), <c>@Name(k = v)</c>
    /// (Java), <c>@aspect("name", {...})</c> (Python). Used only to fill missing values; the name is captured as-written
    /// (PascalCased in bracket langs) — callers map it back to a registry def, since round-tripping a lowered name is lossy.</description></item>
    /// </list>
    /// Comment markers (<c>//</c>, <c>#</c>, <c>*</c>, <c>///</c>) are stripped from each line before parsing, so the
    /// same logic handles every language.</para>
    ///
    /// <para>Duplicate def names collapse last-wins; the latest carrier seen for a field wins. Locked/default values
    /// are not distinguished here (the registry re-seals them on normalize); ingest only recovers what was written.</para>
    ///
    /// <para>Engine-free: no UnityEngine / no JsonUtility — pure regex over text.</para>
    /// </summary>
    public static class AspectIngest
    {
        // <aspect name="rank" v="3"> ... <field key="votes">42</field> ... </aspect>
        private static readonly Regex DocTagBlock = new Regex(
            @"<aspect\s+name=""(?<name>[^""]+)""(?:\s+v=""(?<ver>\d+)"")?>(?<body>.*?)</aspect>",
            RegexOptions.Singleline | RegexOptions.Compiled);

        private static readonly Regex FieldTag = new Regex(
            @"<field\s+key=""(?<key>[^""]+)"">(?<val>.*?)</field>",
            RegexOptions.Singleline | RegexOptions.Compiled);

        // comment carrier: aspect NAME (vN):  then  key = value  lines until a blank line or next marker
        private static readonly Regex CarrierHead = new Regex(
            @"aspect\s+(?<name>\S+)\s+\(v(?<ver>\d+)\)\s*:",
            RegexOptions.Compiled);

        // native attributes:  [Name(k = v, k = v)]  or  @Name(k = v, k = v)  — capture name + arglist
        private static readonly Regex BracketAttr = new Regex(
            @"\[(?<name>[\w]+)\((?<args>[^)]*)\)\]",
            RegexOptions.Compiled);

        private static readonly Regex AtAttr = new Regex(
            @"@(?<name>[\w]+)\((?<args>[^)]*)\)",
            RegexOptions.Compiled);

        // python decorator form: @aspect("name", { "k": v, "k": v })
        private static readonly Regex PyAspect = new Regex(
            @"@aspect\(""(?<name>[^""]+)""\s*,\s*\{(?<args>[^}]*)\}\)",
            RegexOptions.Compiled);

        // A type declaration — used to attribute each aspect carrier to its owning type by POSITION (the carrier sits
        // directly above the type it decorates). Covers the 5 emit languages' type-bearing keywords. Member-level
        // keywords (def/fn/var/let) are deliberately excluded so they don't shadow the enclosing type.
        private static readonly Regex TypeDecl = new Regex(
            @"\b(?:class|interface|struct|record|enum|defmodule|protocol|object|module)\b\s+(?<name>[A-Za-z_][\w.]*)",
            RegexOptions.Compiled);

        /// <summary>The recovered attachments from a source text.</summary>
        public sealed class Result
        {
            public readonly List<AspectInstance> Aspects = new();
            public readonly List<FreeformEntry> Freeform = new();
        }

        /// <summary>Parse generated source text into aspect instances + freeform, merging every carrier in the file
        /// into one flat result (legacy single-bucket form). Never throws on malformed input. Prefer
        /// <see cref="IngestCodeByType"/> when you need to know which type owns which carrier.</summary>
        public static Result IngestCode(string source) => MergeAll(IngestCodeByType(source));

        /// <summary>Parse generated source text and attribute each carrier to its owning type by position. Aspect
        /// carriers (<c>&lt;aspect&gt;</c> doc-tags, comment carriers, native attributes) are emitted directly above
        /// the type they decorate, so each is bucketed under the NEAREST FOLLOWING type declaration in the file.
        /// Carriers after the last type (genuinely dangling) are dropped. Returns a map keyed by type name; a type
        /// with no carriers simply has no entry.</summary>
        public static Dictionary<string, Result> IngestCodeByType(string source)
        {
            var map = new Dictionary<string, Result>();
            if (string.IsNullOrEmpty(source)) return map;

            // Normalize: strip leading comment markers per line so the block parsers are language-agnostic.
            // Lines are rejoined with \n so the multi-line doc-tag regex spans correctly.
            var clean = new StringBuilder();
            foreach (var raw in source.Replace("\r\n", "\n").Split('\n'))
            {
                string line = raw;
                string t = line.TrimStart();
                if (t.StartsWith("///")) line = t.Substring(3);
                else if (t.StartsWith("//")) line = t.Substring(2);
                else if (t.StartsWith("#")) line = t.Substring(1);
                else if (t.StartsWith("*")) line = t.Substring(1);
                clean.Append(line.Trim()).Append('\n');
            }
            string text = clean.ToString();

            // Ownership fence posts: type declarations in source order. A carrier's owner is the first type decl
            // whose index is strictly greater than the carrier's (the type it sits directly above).
            var types = new List<(int index, string name)>();
            foreach (Match tm in TypeDecl.Matches(text))
                types.Add((tm.Index, tm.Groups["name"].Value));

            // 1) authoritative <aspect> doc-tag blocks — owner is the type after the block's END (</aspect>).
            foreach (Match m in DocTagBlock.Matches(text))
            {
                string owner = OwnerAfter(types, m.Index + m.Length);
                if (owner == null) continue; // dangling after last type
                var res = GetOrAddBucket(map, owner);
                string name = m.Groups["name"].Value;
                int ver = int.TryParse(m.Groups["ver"].Value, out var v) ? v : 1;
                var inst = GetOrAdd(res.Aspects, name, ver);
                foreach (Match fm in FieldTag.Matches(m.Groups["body"].Value))
                    SetOverride(inst, fm.Groups["key"].Value, Unquote(fm.Groups["val"].Value));
            }

            // 2) comment carrier: aspect NAME (vN): + following  key = value  lines (until next carrier)
            var carrierMatches = CarrierHead.Matches(text);
            for (int i = 0; i < carrierMatches.Count; i++)
            {
                var m = carrierMatches[i];
                string owner = OwnerAfter(types, m.Index);
                if (owner == null) continue;
                int bodyStart = m.Index + m.Length;
                int bodyEnd = (i + 1 < carrierMatches.Count) ? carrierMatches[i + 1].Index : text.Length;
                string body = text.Substring(bodyStart, bodyEnd - bodyStart);
                var res = GetOrAddBucket(map, owner);
                string name = m.Groups["name"].Value;
                int ver = int.TryParse(m.Groups["ver"].Value, out var vv) ? vv : 1;
                var inst = GetOrAdd(res.Aspects, name, ver);
                foreach (var ln in body.Split('\n'))
                {
                    string l = ln.Trim();
                    if (l.Length == 0) continue;
                    int eq = l.IndexOf('=');
                    if (eq <= 0) continue;
                    string key = l.Substring(0, eq).Trim();
                    string val = Unquote(l.Substring(eq + 1).Trim());
                    if (AspectResolution.IsValidKey(key)) SetOverride(inst, key, val);
                }
            }

            // 3) best-effort native attributes — bucketed by position too (they sit right above the type keyword).
            ParseNativeByType(text, map, types, BracketAttr);
            ParseNativeByType(text, map, types, AtAttr);
            ParsePythonAspectByType(text, map, types);

            return map;
        }

        // The name of the type whose declaration is the first one strictly after `carrierIndex`, or null when none
        // (carrier trails the last type — dangling, drop it).
        private static string OwnerAfter(List<(int index, string name)> types, int carrierIndex)
        {
            foreach (var t in types) // types is in source order
                if (t.index > carrierIndex) return t.name;
            return null;
        }

        private static Result GetOrAddBucket(Dictionary<string, Result> map, string owner)
        {
            if (!map.TryGetValue(owner, out var res)) { res = new Result(); map[owner] = res; }
            return res;
        }

        private static Result MergeAll(Dictionary<string, Result> byType)
        {
            var merged = new Result();
            foreach (var kv in byType)
            {
                foreach (var a in kv.Value.Aspects)
                {
                    var inst = GetOrAdd(merged.Aspects, a.DefName, a.DefVersion);
                    foreach (var o in a.Overrides) SetOverride(inst, o.Key, o.Value);
                }
                foreach (var f in kv.Value.Freeform) merged.Freeform.Add(f);
            }
            return merged;
        }

        private static void ParseNativeByType(string text, Dictionary<string, Result> map,
            List<(int index, string name)> types, Regex re)
        {
            foreach (Match m in re.Matches(text))
            {
                string owner = OwnerAfter(types, m.Index);
                if (owner == null) continue;
                var res = GetOrAddBucket(map, owner);
                var inst = GetOrAdd(res.Aspects, m.Groups["name"].Value, 1);
                foreach (var pair in m.Groups["args"].Value.Split(','))
                    FillArg(inst, pair, "=");
            }
        }

        private static void ParsePythonAspectByType(string text, Dictionary<string, Result> map,
            List<(int index, string name)> types)
        {
            foreach (Match m in PyAspect.Matches(text))
            {
                string owner = OwnerAfter(types, m.Index);
                if (owner == null) continue;
                var res = GetOrAddBucket(map, owner);
                var inst = GetOrAdd(res.Aspects, m.Groups["name"].Value, 1);
                foreach (var pair in m.Groups["args"].Value.Split(','))
                    FillArg(inst, pair, ":");
            }
        }

        /// <summary>Read a <c>.trd.{file}.meta.yaml</c> sidecar body into aspect instances + freeform. Meta-flagged
        /// entries survive here regardless of the inline emit flags, so round-tripping an element that was
        /// Meta-only still recovers its values.</summary>
        public static Result IngestSidecar(string yaml)
        {
            var res = new Result();
            if (string.IsNullOrEmpty(yaml)) return res;
            string[] lines = yaml.Replace("\r\n", "\n").Split('\n');
            AspectInstance cur = null;
            string section = null; // "aspects" | "freeform" | null
            for (int i = 0; i < lines.Length; i++)
            {
                string line = lines[i];
                if (line.Length == 0) continue;
                // top-level header:  'code':   (indented 0) — start of an element block
                if (!char.IsWhiteSpace(line[0]) && line.TrimEnd().EndsWith("':"))
                {
                    cur = null;
                    section = null;
                    
                    continue;
                }
                string trimmed = line.TrimStart();
                int indent = line.Length - trimmed.Length;

                // section markers at 2 spaces:  'aspects': / 'freeform':
                if (indent == 2 && trimmed.StartsWith("'aspects'"))
                { section = "aspects"; cur = null; continue; }
                if (indent == 2 && trimmed.StartsWith("'freeform'"))
                { section = "freeform"; cur = null; continue; }

                if (section == "aspects")
                {
                    // aspect name at 4 spaces:  'rank':   (strip the trailing ':' before unquoting the key)
                    if (indent == 4 && trimmed.EndsWith("':"))
                    {
                        string name = UnquoteYamlKey(trimmed.Substring(0, trimmed.Length - 1));
                        cur = GetOrAdd(res.Aspects, name, 1);
                        
                        continue;
                    }
                    // 6-space field or _defv
                    if (indent == 6 && cur != null)
                    {
                        var kv = SplitYamlKv(trimmed);
                        if (kv == null) continue;
                        if (kv.Item1 == "_defv") { if (int.TryParse(kv.Item2, out var dv)) cur.DefVersion = dv; }
                        else SetOverride(cur, kv.Item1, Unquote(kv.Item2));
                    }
                }
                else if (section == "freeform")
                {
                    if (indent == 4)
                    {
                        var kv = SplitYamlKv(trimmed);
                        if (kv != null) res.Freeform.Add(new FreeformEntry { Key = kv.Item1, Value = Unquote(kv.Item2) });
                    }
                }
            }
            return res;
        }

        // --- internals ---

        private static void FillArg(AspectInstance inst, string pair, string sep)
        {
            string p = pair.Trim();
            if (p.Length == 0) return;
            int i = p.IndexOf(sep);
            if (i <= 0) return;
            string key = p.Substring(0, i).Trim().Trim('"', '\'');
            string val = Unquote(p.Substring(i + sep.Length).Trim());
            if (AspectResolution.IsValidKey(key)) SetOverride(inst, key, val);
        }

        private static AspectInstance GetOrAdd(List<AspectInstance> list, string name, int ver)
        {
            if (string.IsNullOrEmpty(name)) return null;
            foreach (var a in list) if (a.DefName == name)
            {
                if (ver > a.DefVersion) a.DefVersion = ver;
                return a;
            }
            var inst = new AspectInstance { DefName = name, DefVersion = Math.Max(1, ver), Overrides = new Dictionary<string, string>() };
            list.Add(inst);
            return inst;
        }

        private static void SetOverride(AspectInstance inst, string key, string value)
        {
            if (inst == null || !AspectResolution.IsValidKey(key)) return;
            inst.Overrides[key] = value ?? "";
        }

        // Strip surrounding quotes (single or double) + unescape \" / ''. Leaves bare numbers/bools as-is.
        private static string Unquote(string s)
        {
            if (s == null) return "";
            string t = s.Trim();
            if (t.Length >= 2)
            {
                if ((t[0] == '"' && t[t.Length - 1] == '"') || (t[0] == '\'' && t[t.Length - 1] == '\''))
                {
                    t = t.Substring(1, t.Length - 2);
                    t = t.Replace("\\\"", "\"").Replace("''", "'").Replace("\\\\", "\\");
                }
            }
            return t;
        }

        private static Tuple<string, string> SplitYamlKv(string trimmed)
        {
            int ci = trimmed.IndexOf(':');
            if (ci <= 0) return null;
            return Tuple.Create(UnquoteYamlKey(trimmed.Substring(0, ci)), trimmed.Substring(ci + 1).Trim());
        }

        private static string UnquoteYamlKey(string s)
        {
            string t = s.Trim();
            if (t.Length >= 2 && t[0] == '\'' && t[t.Length - 1] == '\'')
                return t.Substring(1, t.Length - 2).Replace("''", "'");
            return t;
        }
    }
}
