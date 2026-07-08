using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using TheRobotDraft.Authoring.Interchange;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Authoring.State
{
    /// <summary>
    /// The aspect-definition registry: the source of truth for typed aspect <see cref="AspectDef"/>s. Backed by a
    /// SQLite database at <c>~/.local/state/the-robot-drafts/aspects.db</c> via the <see cref="SqliteCli"/> shell
    /// wrapper (no managed driver — the codebase deliberately avoids bundling a native SQLite DLL).
    ///
    /// <para>Definitions are VERSIONED and IMMUTABLE per version: a new version is a new row. <see cref="Save"/>
    /// appends the next version, writes a structured-diff revision row (so any two versions can be compared via
    /// <see cref="Diff"/>), and bumps the head pointer. The in-code <see cref="SystemAspects"/> baseline seeds the
    /// table on first run and is always <c>SystemOwned</c>; a user edit of a system aspect adds a higher version,
    /// and "revert to system" points the head back at version 1.</para>
    ///
    /// <para>All access is guarded by <see cref="SqliteCli.IsAvailable"/>: when sqlite3 is absent the registry
    /// degrades to read-only (just the system defaults) rather than throwing.</para>
    /// </summary>
    public static class AspectRegistry
    {
        // ------------------------------------------------------------------ path

        /// <summary>Resolve <c>~/.local/state/the-robot-drafts/aspects.db</c>, creating the directory.</summary>
        public static string DbPath()
        {
            string home = Environment.GetEnvironmentVariable("HOME")
                ?? Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            if (string.IsNullOrWhiteSpace(home)) home = Directory.GetCurrentDirectory();
            string dir = Path.Combine(home, ".local", "state", "the-robot-drafts");
            Directory.CreateDirectory(dir);
            return Path.Combine(dir, "aspects.db");
        }

        // ------------------------------------------------------------------ load

        /// <summary>Load the current (head) version of every definition: user DB heads overlaid on system defaults.</summary>
        public static List<AspectDef> LoadAll()
        {
            var byName = new Dictionary<string, AspectDef>();
            foreach (var d in SystemAspects.Defaults) byName[d.Name] = CloneDef(d);
            if (!SqliteCli.IsAvailable || !File.Exists(DbPath())) return new List<AspectDef>(byName.Values);

            EnsureSchema();
            foreach (var row in QuerySafe("SELECT name, current_version FROM aspect_def_head;"))
            {
                string name = row[0];
                int ver = ParseInt(row, 1, 1);
                var d = LoadVersion(name, ver);
                if (d != null) byName[name] = d; // user version overrides the system baseline
            }
            return new List<AspectDef>(byName.Values);
        }

        /// <summary>
        /// Get the current (head) version of a named def, or null when unknown. The returned object is a fresh
        /// instance (DB rows are built new; the shared system baseline is cloned because it is singleton state).
        /// Callers MAY mutate it freely; clone-on-write in <see cref="Save"/> also guards against the baseline.
        /// </summary>
        public static AspectDef Get(string name)
        {
            if (string.IsNullOrEmpty(name)) return null;
            // A head pointer means a user version overrides the baseline.
            if (SqliteCli.IsAvailable && File.Exists(DbPath()))
            {
                EnsureSchema();
                var rows = QuerySafe($"SELECT current_version FROM aspect_def_head WHERE name = {SqlStr(name)};");
                if (rows.Count > 0)
                {
                    var d = LoadVersion(name, ParseInt(rows[0], 0, 1));
                    if (d != null) return d; // already a fresh instance
                }
            }
            foreach (var s in SystemAspects.Defaults) if (s.Name == name) return CloneDef(s); // clone shared baseline
            return null;
        }

        /// <summary>Load a SPECIFIC version of a def (immutable history). Null when absent. Returns a CLONE.</summary>
        public static AspectDef GetVersion(string name, int version)
        {
            if (string.IsNullOrEmpty(name) || version < 1) return null;
            // System baseline lives at version 1.
            if (version == 1)
            {
                foreach (var s in SystemAspects.Defaults) if (s.Name == name) return CloneDef(s);
            }
            if (!SqliteCli.IsAvailable || !File.Exists(DbPath())) return null;
            EnsureSchema();
            return LoadVersion(name, version);
        }

        // ------------------------------------------------------------------ save (versioned)

        /// <summary>
        /// Save a (possibly changed) definition as a NEW version: append an immutable version row, write a
        /// revision-diff row against the previous head, and bump the head pointer. Returns the new version number
        /// (1 when the DB is unavailable — the change is in-memory only). Throws if <paramref name="def"/> has no
        /// valid name. Never deletes history.
        /// </summary>
        public static int Save(AspectDef def)
        {
            if (def == null || string.IsNullOrWhiteSpace(def.Name))
                throw new ArgumentException("AspectRegistry.Save: def must have a name");
            NormalizeKeys(def);
            string name = def.Name;
            if (!SqliteCli.IsAvailable) return 1; // degrade gracefully

            // Clone-on-write: the caller may have handed us the shared SystemAspects baseline (via Get), so never
            // mutate the passed-in object — copy it, bump the copy's version, persist the copy. (Reads return
            // references; cloning here is the only place we need a defensive copy, not on every Get.)
            def = CloneDef(def);

            EnsureSchema();
            int prev = HeadVersion(name);                 // 0 if brand new, 1 if system-baseline-only
            int next = Math.Max(prev + 1, def.Version + 1);
            if (prev == 0) prev = 1;                      // diff against the system baseline at v1
            def.Version = next;

            var prevDef = LoadVersion(name, prev) ?? SystemBaseline(name);
            var diff = DiffDefs(prevDef, def);

            var sql = new StringBuilder();
            sql.Append("BEGIN;\n");
            sql.Append($"INSERT INTO aspect_defs(name, version, scope, element_type, graph_type, description, fields_json, emit, emit_locks, system_owned) VALUES(");
            sql.Append(SqlStr(name)).Append(", ").Append(next).Append(", ")
                .Append(SqlStr(def.Scope.ToString())).Append(", ")
                .Append(def.ElementType.HasValue ? SqlStr(def.ElementType.Value.ToString()) : "NULL").Append(", ")
                .Append(def.GraphType.HasValue ? SqlStr(def.GraphType.Value.ToString()) : "NULL").Append(", ")
                .Append(SqlStr(def.Description ?? "")).Append(", ")
                .Append(SqlStr(FieldsToJson(def.Fields))).Append(", ")
                .Append(SqlStr(EmitToString(def.Emit))).Append(", ")
                .Append(SqlStr(EmitLocksToString(def.EmitLocks))).Append(", ")
                .Append(def.SystemOwned ? 1 : 0).Append(");\n");
            sql.Append($"INSERT INTO aspect_revisions(name, version, prev_version, changed_at, change_json) VALUES(");
            sql.Append(SqlStr(name)).Append(", ").Append(next).Append(", ").Append(prev).Append(", ")
                .Append(SqlStr(Timestamp())).Append(", ").Append(SqlStr(ChangeToJson(diff))).Append(");\n");
            sql.Append($"INSERT OR REPLACE INTO aspect_def_head(name, current_version) VALUES(")
                .Append(SqlStr(name)).Append(", ").Append(next).Append(");\n");
            sql.Append("COMMIT;\n");
            SqliteCli.Execute(DbPath(), sql.ToString());
            return next;
        }

        /// <summary>Delete a definition's head (history is retained). System defs revert to the baseline.</summary>
        public static void Delete(string name)
        {
            if (string.IsNullOrEmpty(name) || !SqliteCli.IsAvailable || !File.Exists(DbPath())) return;
            EnsureSchema();
            bool isSystem = SystemBaseline(name) != null;
            var sql = new StringBuilder();
            sql.Append("BEGIN;\n");
            if (isSystem)
                sql.Append($"UPDATE aspect_def_head SET current_version = 1 WHERE name = {SqlStr(name)};\n");
            else
                sql.Append($"DELETE FROM aspect_def_head WHERE name = {SqlStr(name)};\n");
            sql.Append("COMMIT;\n");
            SqliteCli.Execute(DbPath(), sql.ToString());
        }

        // ------------------------------------------------------------------ diff (version history)

        /// <summary>A structured change record between two def versions (powers the history panel).</summary>
        public sealed class ChangeRecord
        {
            public int FromVersion;
            public int ToVersion;
            public readonly List<string> FieldsAdded = new List<string>();
            public readonly List<string> FieldsRemoved = new List<string>();
            public readonly List<string> DefaultsChanged = new List<string>(); // "field: old -> new"
            public readonly List<string> LocksChanged = new List<string>();    // "field: ...locked/unlocked"
            public readonly List<string> RestrictionsChanged = new List<string>();
            public bool EmitChanged;
            public bool EmitLocksChanged;
            public bool ScopeChanged;
            public bool DescriptionChanged;

            public bool AnyChange => FieldsAdded.Count + FieldsRemoved.Count + DefaultsChanged.Count
                + LocksChanged.Count + RestrictionsChanged.Count > 0
                || EmitChanged || EmitLocksChanged || ScopeChanged || DescriptionChanged;
        }

        /// <summary>Compute the structured diff between two named versions of a definition.</summary>
        public static ChangeRecord Diff(string name, int fromVersion, int toVersion)
        {
            var a = GetVersion(name, fromVersion) ?? new AspectDef { Name = name };
            var b = GetVersion(name, toVersion) ?? new AspectDef { Name = name };
            return DiffDefs(a, b);
        }

        /// <summary>List all revisions for a def (version, prev_version, timestamp) newest-first.</summary>
        public static List<(int version, int prevVersion, string changedAt)> History(string name)
        {
            var list = new List<(int, int, string)>();
            if (string.IsNullOrEmpty(name) || !SqliteCli.IsAvailable || !File.Exists(DbPath())) return list;
            EnsureSchema();
            foreach (var row in QuerySafe($"SELECT version, prev_version, changed_at FROM aspect_revisions WHERE name = {SqlStr(name)} ORDER BY version DESC;"))
                list.Add((ParseInt(row, 0, 0), ParseInt(row, 1, 0), Cell(row, 2)));
            return list;
        }

        /// <summary>The change-json for one revision row (already stored). Null when absent.</summary>
        public static string RevisionChangeJson(string name, int version)
        {
            if (string.IsNullOrEmpty(name) || !SqliteCli.IsAvailable || !File.Exists(DbPath())) return null;
            EnsureSchema();
            foreach (var row in QuerySafe($"SELECT change_json FROM aspect_revisions WHERE name = {SqlStr(name)} AND version = {version};"))
                return Cell(row, 0);
            return null;
        }

        // ------------------------------------------------------------------ stereotype bundles

        /// <summary>Aspects auto-attached when a stereotype is applied (shallow — values resolved at attach time).</summary>
        public static List<string> BundleFor(string stereotype)
        {
            var list = new List<string>();
            if (string.IsNullOrEmpty(stereotype)) return list;
            if (!SqliteCli.IsAvailable || !File.Exists(DbPath())) return list;
            EnsureSchema();
            foreach (var row in QuerySafe($"SELECT aspect_name FROM stereotype_bundles WHERE stereotype = {SqlStr(stereotype)} ORDER BY ordinal;"))
                list.Add(Cell(row, 0));
            return list;
        }

        /// <summary>Set the ordered list of aspect names auto-attached by a stereotype (one undo-less write).</summary>
        public static void SetBundle(string stereotype, IEnumerable<string> aspectNames)
        {
            if (string.IsNullOrEmpty(stereotype) || !SqliteCli.IsAvailable || !File.Exists(DbPath())) return;
            EnsureSchema();
            var sql = new StringBuilder();
            sql.Append("BEGIN;\n");
            sql.Append($"DELETE FROM stereotype_bundles WHERE stereotype = {SqlStr(stereotype)};\n");
            int ordinal = 0;
            foreach (var n in aspectNames)
            {
                if (string.IsNullOrEmpty(n)) continue;
                sql.Append($"INSERT INTO stereotype_bundles(stereotype, aspect_name, ordinal) VALUES(")
                    .Append(SqlStr(stereotype)).Append(", ").Append(SqlStr(n)).Append(", ").Append(ordinal).Append(");\n");
                ordinal++;
            }
            sql.Append("COMMIT;\n");
            SqliteCli.Execute(DbPath(), sql.ToString());
        }

        // ------------------------------------------------------------------ internals: schema + load

        private static bool _schemaReady;
        private static void EnsureSchema()
        {
            if (_schemaReady) return;
            string db = DbPath();
            if (!File.Exists(db)) File.WriteAllBytes(db, Array.Empty<byte>()); // sqlite3 opens empty file as new DB
            // versioned immutable defs + head pointer + revision history + stereotype bundles
            SqliteCli.Execute(db,
                "BEGIN;\n" +
                "CREATE TABLE IF NOT EXISTS aspect_defs(\n" +
                "  name TEXT NOT NULL, version INTEGER NOT NULL,\n" +
                "  scope TEXT, element_type TEXT, graph_type TEXT, description TEXT,\n" +
                "  fields_json TEXT, emit TEXT, emit_locks TEXT, system_owned INTEGER,\n" +
                "  PRIMARY KEY(name, version));\n" +
                "CREATE TABLE IF NOT EXISTS aspect_def_head(name TEXT PRIMARY KEY, current_version INTEGER NOT NULL);\n" +
                "CREATE TABLE IF NOT EXISTS aspect_revisions(\n" +
                "  name TEXT NOT NULL, version INTEGER NOT NULL, prev_version INTEGER,\n" +
                "  changed_at TEXT, change_json TEXT, PRIMARY KEY(name, version));\n" +
                "CREATE TABLE IF NOT EXISTS stereotype_bundles(\n" +
                "  stereotype TEXT NOT NULL, aspect_name TEXT NOT NULL, ordinal INTEGER,\n" +
                "  PRIMARY KEY(stereotype, aspect_name));\n" +
                "COMMIT;\n");
            _schemaReady = true;
        }

        private static AspectDef LoadVersion(string name, int version)
        {
            foreach (var row in QuerySafe(
                $"SELECT scope, element_type, graph_type, description, fields_json, emit, emit_locks, system_owned FROM aspect_defs WHERE name = {SqlStr(name)} AND version = {version};"))
            {
                var d = new AspectDef { Name = name, Version = version };
                d.Scope = Enum.TryParse<AspectScope>(Cell(row, 0), out var sc) ? sc : AspectScope.AdHoc;
                if (Enum.TryParse<ElementKind>(Cell(row, 1), out var ek)) d.ElementType = ek;
                if (Enum.TryParse<GraphType>(Cell(row, 2), out var gt)) d.GraphType = gt;
                d.Description = Cell(row, 3);
                d.Fields = FieldsFromJson(Cell(row, 4));
                d.Emit = StringToEmit(Cell(row, 5));
                d.EmitLocks = StringToEmitLocks(Cell(row, 6));
                d.SystemOwned = ParseInt(row, 7, 0) != 0;
                return d;
            }
            return null;
        }

        private static int HeadVersion(string name)
        {
            foreach (var row in QuerySafe($"SELECT current_version FROM aspect_def_head WHERE name = {SqlStr(name)};"))
                return ParseInt(row, 0, 0);
            return 0;
        }

        private static AspectDef SystemBaseline(string name)
        {
            foreach (var s in SystemAspects.Defaults) if (s.Name == name) return s;
            return null;
        }

        // ------------------------------------------------------------------ internals: sql helpers

        private static List<string[]> QuerySafe(string sql)
        {
            try { return new List<string[]>(SqliteCli.Query(DbPath(), sql)); }
            catch { return new List<string[]>(); } // a missing table / transient error degrades to empty
        }

        private static string SqlStr(string s) => "'" + (s ?? "").Replace("'", "''") + "'";
        private static string Cell(string[] row, int i) => i < row.Length ? (row[i] ?? "") : "";
        private static int ParseInt(string[] row, int i, int fallback) =>
            int.TryParse(Cell(row, i), out var v) ? v : fallback;

        // Stable timestamp WITHOUT touching the system clock at construction — SqliteCli shells sqlite3 which
        // renders CURRENT_TIMESTAMP server-side, so this is only a fallback for the change-json envelope.
        private static string Timestamp() => "";

        // ------------------------------------------------------------------ internals: field JSON

        // Compact hand-rolled JSON for the field list (engine-free: no JsonUtility/UnityEngine here). Each field
        // is {name,type,restriction,default,locked}. Strings are quoted+escaped; null default omitted.
        private static string FieldsToJson(List<AspectFieldDef> fields)
        {
            var sb = new StringBuilder("[");
            bool first = true;
            if (fields != null) foreach (var f in fields)
            {
                if (f == null || string.IsNullOrEmpty(f.Name)) continue;
                if (!first) sb.Append(",");
                first = false;
                sb.Append("{").Append(JsonKV("name", f.Name)).Append(",")
                    .Append("\"type\":\"").Append(f.Type.ToString()).Append("\"");
                if (!string.IsNullOrEmpty(f.Restriction)) sb.Append(",").Append(JsonKV("restriction", f.Restriction));
                if (f.Default != null) sb.Append(",").Append(JsonKV("default", f.Default));
                if (f.Locked) sb.Append(",\"locked\":true");
                sb.Append("}");
            }
            return sb.Append("]").ToString();
        }

        private static List<AspectFieldDef> FieldsFromJson(string json)
        {
            var list = new List<AspectFieldDef>();
            if (string.IsNullOrWhiteSpace(json)) return list;
            foreach (var obj in JsonObjects(json))
            {
                var f = new AspectFieldDef();
                if (JsonTryGet(obj, "name", out string n)) f.Name = JsonUnquote(n);
                if (JsonTryGet(obj, "type", out string t) && Enum.TryParse<AspectFieldType>(JsonUnquote(t), out var ft)) f.Type = ft;
                if (JsonTryGet(obj, "restriction", out string r)) f.Restriction = JsonUnquote(r);
                if (JsonTryGet(obj, "default", out string d)) f.Default = JsonUnquote(d);
                if (JsonTryGet(obj, "locked", out string lk)) f.Locked = lk == "true";
                if (!string.IsNullOrEmpty(f.Name)) list.Add(f);
            }
            return list;
        }

        // ------------------------------------------------------------------ internals: diff

        private static ChangeRecord DiffDefs(AspectDef a, AspectDef b)
        {
            var rec = new ChangeRecord { FromVersion = a?.Version ?? 0, ToVersion = b?.Version ?? 0 };
            var af = IndexFields(a);
            var bf = IndexFields(b);
            foreach (var k in bf.Keys) if (!af.ContainsKey(k)) rec.FieldsAdded.Add(k);
            foreach (var k in af.Keys) if (!bf.ContainsKey(k)) rec.FieldsRemoved.Add(k);
            foreach (var k in af.Keys)
                if (bf.TryGetValue(k, out var nb))
                {
                    var oa = af[k];
                    if ((oa.Default ?? "") != (nb.Default ?? ""))
                        rec.DefaultsChanged.Add($"{k}: {oa.Default ?? ""} -> {nb.Default ?? ""}");
                    if (oa.Locked != nb.Locked)
                        rec.LocksChanged.Add($"{k}: {(nb.Locked ? "locked" : "unlocked")}");
                    if ((oa.Restriction ?? "") != (nb.Restriction ?? ""))
                        rec.RestrictionsChanged.Add($"{k}: {oa.Restriction ?? ""} -> {nb.Restriction ?? ""}");
                }
            rec.EmitChanged = !SameEmit(a?.Emit ?? default, b?.Emit ?? default);
            rec.EmitLocksChanged = !SameEmitLocks(a?.EmitLocks ?? default, b?.EmitLocks ?? default);
            rec.ScopeChanged = (a?.Scope ?? AspectScope.AdHoc) != (b?.Scope ?? AspectScope.AdHoc)
                || (a?.ElementType?.ToString() ?? "") != (b?.ElementType?.ToString() ?? "")
                || (a?.GraphType?.ToString() ?? "") != (b?.GraphType?.ToString() ?? "");
            rec.DescriptionChanged = (a?.Description ?? "") != (b?.Description ?? "");
            return rec;
        }

        private static Dictionary<string, AspectFieldDef> IndexFields(AspectDef d)
        {
            var idx = new Dictionary<string, AspectFieldDef>();
            if (d?.Fields == null) return idx;
            foreach (var f in d.Fields) if (f != null && !string.IsNullOrEmpty(f.Name)) idx[f.Name] = f;
            return idx;
        }

        private static string ChangeToJson(ChangeRecord c)
        {
            var sb = new StringBuilder("{");
            sb.Append(JsonKA("fieldsAdded", c.FieldsAdded)).Append(",")
                .Append(JsonKA("fieldsRemoved", c.FieldsRemoved)).Append(",")
                .Append(JsonKA("defaultsChanged", c.DefaultsChanged)).Append(",")
                .Append(JsonKA("locksChanged", c.LocksChanged)).Append(",")
                .Append(JsonKA("restrictionsChanged", c.RestrictionsChanged)).Append(",")
                .Append("\"emitChanged\":").Append(c.EmitChanged ? "true" : "false").Append(",")
                .Append("\"emitLocksChanged\":").Append(c.EmitLocksChanged ? "true" : "false").Append(",")
                .Append("\"scopeChanged\":").Append(c.ScopeChanged ? "true" : "false").Append(",")
                .Append("\"descriptionChanged\":").Append(c.DescriptionChanged ? "true" : "false");
            return sb.Append("}").ToString();
        }

        // ------------------------------------------------------------------ internals: emit (de)serialize

        internal static string EmitToString(EmitFlags f) =>
            (f.Annotate ? "A" : "") + (f.DocTag ? "D" : "") + (f.Comment ? "C" : "") + (f.Meta ? "M" : "");

        internal static EmitFlags StringToEmit(string s)
        {
            var f = new EmitFlags();
            if (string.IsNullOrEmpty(s)) return f;
            foreach (char c in s) switch (c)
                {
                    case 'A': f.Annotate = true; break;
                    case 'D': f.DocTag = true; break;
                    case 'C': f.Comment = true; break;
                    case 'M': f.Meta = true; break;
                }
            return f;
        }

        internal static string EmitLocksToString(EmitLocks l) =>
            (l.Annotate ? "A" : "") + (l.DocTag ? "D" : "") + (l.Comment ? "C" : "") + (l.Meta ? "M" : "");

        internal static EmitLocks StringToEmitLocks(string s)
        {
            var f = new EmitLocks();
            if (string.IsNullOrEmpty(s)) return f;
            foreach (char c in s) switch (c)
                {
                    case 'A': f.Annotate = true; break;
                    case 'D': f.DocTag = true; break;
                    case 'C': f.Comment = true; break;
                    case 'M': f.Meta = true; break;
                }
            return f;
        }

        private static bool SameEmit(EmitFlags a, EmitFlags b) =>
            a.Annotate == b.Annotate && a.DocTag == b.DocTag && a.Comment == b.Comment && a.Meta == b.Meta;
        private static bool SameEmitLocks(EmitLocks a, EmitLocks b) =>
            a.Annotate == b.Annotate && a.DocTag == b.DocTag && a.Comment == b.Comment && a.Meta == b.Meta;

        // ------------------------------------------------------------------ internals: key normalize + clone

        private static void NormalizeKeys(AspectDef def)
        {
            if (def?.Fields == null) return;
            var keep = new List<AspectFieldDef>();
            foreach (var f in def.Fields)
                if (f != null && AspectResolution.IsValidKey(f.Name)) keep.Add(f);
            def.Fields = keep;
        }

        private static AspectDef CloneDef(AspectDef d)
        {
            if (d == null) return null;
            var c = new AspectDef
            {
                Name = d.Name,
                Description = d.Description,
                Emit = d.Emit,
                EmitLocks = d.EmitLocks,
                Version = d.Version,
                SystemOwned = d.SystemOwned,
                Scope = d.Scope,
                ElementType = d.ElementType,
                GraphType = d.GraphType,
                Fields = new List<AspectFieldDef>(),
            };
            if (d.Fields != null) foreach (var f in d.Fields)
                c.Fields.Add(new AspectFieldDef { Name = f.Name, Type = f.Type, Restriction = f.Restriction, Default = f.Default, Locked = f.Locked });
            return c;
        }

        // ------------------------------------------------------------------ internals: minimal JSON (engine-free)

        private static string JsonKV(string key, string val) => "\"" + key + "\":" + JsonStr(val);
        private static string JsonStr(string s) => "\"" + (s ?? "").Replace("\\", "\\\\").Replace("\"", "\\\"") + "\"";
        private static string JsonKA(string key, List<string> arr)
        {
            var sb = new StringBuilder("\"").Append(key).Append("\":[");
            for (int i = 0; i < arr.Count; i++) { if (i > 0) sb.Append(","); sb.Append(JsonStr(arr[i])); }
            return sb.Append("]").ToString();
        }

        // Split a JSON array of objects into the raw text of each top-level {...} object.
        private static List<string> JsonObjects(string json)
        {
            var list = new List<string>();
            int i = 0;
            while (i < json.Length && json[i] != '[') i++;
            i++; // past '['
            while (i < json.Length)
            {
                while (i < json.Length && json[i] != '{') i++;
                if (i >= json.Length) break;
                int start = i, depth = 0;
                bool instr = false;
                while (i < json.Length)
                {
                    char c = json[i];
                    if (instr) { if (c == '\\' && i + 1 < json.Length) { i += 2; continue; } if (c == '"') instr = false; }
                    else
                    {
                        if (c == '"') instr = true;
                        else if (c == '{') depth++;
                        else if (c == '}') { depth--; if (depth == 0) { i++; break; } }
                    }
                    i++;
                }
                list.Add(json.Substring(start, i - start));
            }
            return list;
        }

        // Extract a top-level "key":value from one object string (values are raw: quoted strings or bare tokens).
        private static bool JsonTryGet(string obj, string key, out string value)
        {
            value = null;
            string needle = "\"" + key + "\"";
            int k = obj.IndexOf(needle, StringComparison.Ordinal);
            if (k < 0) return false;
            int j = k + needle.Length;
            while (j < obj.Length && (obj[j] == ' ' || obj[j] == ':' || obj[j] == '\t')) j++;
            if (j >= obj.Length) return false;
            if (obj[j] == '"')
            {
                int s = j + 1, e = s; bool esc = false;
                while (e < obj.Length) { if (esc) { esc = false; } else if (obj[e] == '\\') { esc = true; } else if (obj[e] == '"') break; e++; }
                value = obj.Substring(s, e - s); // still escaped — JsonUnquote unescapes
                return true;
            }
            int be = j;
            while (be < obj.Length && obj[be] != ',' && obj[be] != '}') be++;
            value = obj.Substring(j, be - j).Trim();
            return true;
        }

        private static string JsonUnquote(string s)
        {
            if (s == null) return null;
            return s.Replace("\\\"", "\"").Replace("\\\\", "\\");
        }
    }
}
