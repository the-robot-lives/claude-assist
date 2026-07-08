using System;
using System.Collections.Generic;
using System.Text;
using UnityEngine;
using UnityEngine.UI;
using TheRobotDraft.Authoring.Model;
using TheRobotDraft.Authoring.State;
using TheRobotDraft.Llm;
using TheRobotDraft.Schema;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// The database reverse-engineering feature — the ERD analogue of <see cref="UmlCanvas.CodeImport"/>. Connects to
    /// a live Postgres/MySQL database (via <see cref="SchemaIntrospector"/>, which shells out to <c>psql</c>/<c>mysql</c>),
    /// materializes each table as an <see cref="ElementKind.EntityTable"/> node whose columns are <see cref="ElementKind.Field"/>
    /// members and whose foreign keys are association edges, and captures a baseline snapshot of the loaded schema.
    /// Local edits to that ERD are later diffed against the baseline to emit a Liquibase changelog
    /// (<see cref="UmlCanvas.DbChangelog"/>). Reuses the same authoring verbs and modal helpers as the code import.
    /// </summary>
    public sealed partial class UmlCanvas
    {
        /// <summary>
        /// Loaded-schema snapshots keyed by <see cref="DbSchema.Key"/> (engine/namespace), serialized as JSON. The
        /// changelog diffs the current canvas ERD against these. Cleared in <c>NewWorld</c>, persisted in
        /// <see cref="DiagramDto.dbBaselines"/>.
        /// </summary>
        private readonly Dictionary<string, string> _dbBaseline = new();

        /// <summary>The most recently loaded baseline key — the default the changelog diffs against.</summary>
        private string _dbActiveBaseline;

        private const string DbSourcePrefix = "db://";

        // ------------------------------------------------------------------ connect / settings UI

        /// <summary>Open the DB connection modal with Test / Save / Connect-&amp;-load. Wired onto the canvas menu.</summary>
        public void ShowDbConnectDialog(Vector2 screenPos)
        {
            CloseMenu();
            DbSettings.Load(out var engine, out var host, out var port, out var database,
                out var user, out var password, out var schema, out var author);

            float w = 540f, h = 470f;
            var panel = BeginModal(w, h, "Database connection   —   reverse-engineer a schema into an ERD");

            float y = -50f;
            var status = MakeText(panel, "", new Vector2(16f, -(h - 92f)), new Vector2(w - 32f, 18f), 13,
                LabelColor, TextAnchor.MiddleLeft);

            InputField hostInput = null, portInput = null, dbInput = null, userInput = null, pwInput = null,
                schemaInput = null, authorInput = null;

            FormLabel(panel, "Engine", ref y, w);
            var engineDd = MakeDropdown(panel, new Vector2(16f, y), w - 32f,
                new List<string> { "postgres", "mysql" }, string.IsNullOrEmpty(engine) ? "postgres" : engine, sel =>
                {
                    // Flip the default port when switching engines and the field still holds the other default.
                    if (portInput != null && int.TryParse(portInput.text, out var cur))
                    {
                        if (sel == "mysql" && cur == DbSettings.DefaultPgPort) portInput.text = DbSettings.DefaultMySqlPort.ToString();
                        else if (sel == "postgres" && cur == DbSettings.DefaultMySqlPort) portInput.text = DbSettings.DefaultPgPort.ToString();
                    }
                });
            y -= 42f;

            FormLabel(panel, "Host", ref y, w);
            hostInput = MakeInput(panel, new Vector2(16f, y), w - 200f, host, DbSettings.DefaultHost);
            MakeText(panel, "Port", new Vector2(w - 176f, y + 20f), new Vector2(40f, 18f), 13, LabelColor, TextAnchor.MiddleLeft);
            portInput = MakeInput(panel, new Vector2(w - 176f, y), 160f, port.ToString(), "5432");
            portInput.contentType = InputField.ContentType.IntegerNumber;
            y -= 42f;

            FormLabel(panel, "Database", ref y, w);
            dbInput = MakeInput(panel, new Vector2(16f, y), w - 32f, database, "database name");
            y -= 42f;

            FormLabel(panel, "User", ref y, w);
            userInput = MakeInput(panel, new Vector2(16f, y), w - 200f, user, "role / user");
            MakeText(panel, "Schema", new Vector2(w - 176f, y + 20f), new Vector2(60f, 18f), 13, LabelColor, TextAnchor.MiddleLeft);
            schemaInput = MakeInput(panel, new Vector2(w - 176f, y), 160f, schema, "public  (pg only)");
            y -= 42f;

            FormLabel(panel, "Password", ref y, w);
            pwInput = MakeInput(panel, new Vector2(16f, y), w - 200f, password, "(stored locally)");
            pwInput.contentType = InputField.ContentType.Password;
            MakeText(panel, "Author", new Vector2(w - 176f, y + 20f), new Vector2(60f, 18f), 13, LabelColor, TextAnchor.MiddleLeft);
            authorInput = MakeInput(panel, new Vector2(w - 176f, y), 160f, author, "changelog author");
            y -= 42f;

            DbConnInfo Conn()
            {
                int.TryParse(portInput.text, out var p);
                return new DbConnInfo
                {
                    Engine = engineDd.Get(), Host = hostInput.text.Trim(), Port = p,
                    Database = dbInput.text.Trim(), User = userInput.text.Trim(),
                    Password = pwInput.text, SchemaFilter = schemaInput.text.Trim(),
                };
            }

            void Persist()
            {
                int.TryParse(portInput.text, out var p);
                DbSettings.Save(engineDd.Get(), hostInput.text, p, dbInput.text, userInput.text,
                    pwInput.text, schemaInput.text, authorInput.text);
            }

            float yBtn = -(h - 46f);
            MakeButton(panel, "Test", new Vector2(16f, yBtn), new Vector2(80f, 34f),
                new Color(0.22f, 0.40f, 0.34f, 1f), () =>
                {
                    var schemaObj = SchemaIntrospector.Read(Conn(), out var err);
                    status.text = schemaObj != null
                        ? $"connected — {schemaObj.tables.Count} table(s) found"
                        : "failed: " + err;
                });
            MakeButton(panel, "Save", new Vector2(104f, yBtn), new Vector2(80f, 34f),
                new Color(0.22f, 0.24f, 0.29f, 1f), () => { Persist(); status.text = "saved"; });
            MakeButton(panel, "Connect & load", new Vector2(w - 250f, yBtn), new Vector2(150f, 34f),
                new Color(0.18f, 0.46f, 0.30f, 1f), () =>
                {
                    Persist();
                    var schemaObj = SchemaIntrospector.Read(Conn(), out var err);
                    if (schemaObj == null) { status.text = "failed: " + err; return; }
                    CloseMenu();
                    IngestSchema(schemaObj);
                });
            MakeButton(panel, "Cancel", new Vector2(w - 92f, yBtn), new Vector2(76f, 34f),
                new Color(0.22f, 0.24f, 0.29f, 1f), CloseMenu);

            FocusInput(hostInput);
        }

        /// <summary>Menu alias — the connection modal doubles as the settings editor.</summary>
        public void ShowDbSettings(Vector2 screenPos) => ShowDbConnectDialog(screenPos);

        // ------------------------------------------------------------------ materialize schema → ERD

        /// <summary>
        /// Create one <see cref="ElementKind.EntityTable"/> per table (columns as <see cref="ElementKind.Field"/>
        /// members), add FK association edges, lay everything out, and capture the schema as the diff baseline.
        /// Mirrors <c>MaterializeTypes</c>/<c>LinkTypes</c> from the code import.
        /// </summary>
        private void IngestSchema(DbSchema schema)
        {
            if (schema == null || schema.tables == null || schema.tables.Count == 0)
            { Flash("no tables to load"); return; }
            if (!ImportEnsurePackage()) { Flash("couldn't create a package to load into"); return; }

            string engine = string.IsNullOrEmpty(schema.engine) ? "db" : schema.engine;

            // name → created table id, so FK edges can resolve targets (qualified, case-insensitive).
            var created = new Dictionary<string, ElementId>(StringComparer.OrdinalIgnoreCase);
            const float colW = 280f, rowH = 220f, originX = -420f, originY = 200f;
            int gridIndex = 0;

            foreach (var t in schema.tables)
            {
                if (t == null || string.IsNullOrWhiteSpace(t.name)) continue;

                _ctl.EnterAddNode(ElementKind.EntityTable);
                var id = _ctl.CommitAddNode(_activePackage, ImportUniqueName(t.name.Trim()));
                if (!id.IsValid) { _ctl.EnterSelect(); continue; }

                _ctl.SetMeta(id, engine, "table");
                if (!string.IsNullOrWhiteSpace(t.comment)) _ctl.SetCodeDoc(id, t.comment.Trim());
                _ctl.SetSourceFile(id, DbSourcePrefix + engine + "/" + t.Qualified);

                foreach (var c in t.columns ?? new List<DbColumn>())
                {
                    if (c == null || string.IsNullOrWhiteSpace(c.name)) continue;
                    _ctl.EnterAddNode(ElementKind.Field);
                    _ctl.CommitAddNode(id, ComposeColumn(c));
                }

                _ctl.EnterSelect();
                _placements.SetPos(id, new Vector2(originX + (gridIndex % 4) * colW, originY - (gridIndex / 4) * rowH));
                _ctl.SetZLayer(id, _activeLayer);
                created[t.Qualified] = id;
                gridIndex++;
            }

            // Second pass: FK edges (table → referenced table) once every table node exists.
            int fkCount = 0, skipped = 0;
            foreach (var t in schema.tables)
            {
                if (t == null || !created.TryGetValue(t.Qualified, out var fromId)) continue;
                foreach (var c in t.columns ?? new List<DbColumn>())
                {
                    if (c == null || !c.IsForeignKey) continue;
                    var toId = ResolveFkTarget(c.fkRefTable, created, schema);
                    if (!toId.IsValid || toId == fromId) { skipped++; continue; }
                    _ctl.EnterConnect(CommitStyle.OneShot, EdgeKind.Association);
                    _ctl.BeginConnect(fromId);
                    var edge = _ctl.CommitConnect(toId);
                    if (edge.IsValid) { _ctl.SetEdgeMeta(edge, c.name, "*", "1"); fkCount++; }
                }
            }

            // Capture the baseline the changelog diffs against, and persist it.
            string key = schema.Key();
            _dbBaseline[key] = JsonUtility.ToJson(schema);
            _dbActiveBaseline = key;

            _ctl.EnterSelect();
            SetSelected(ElementId.None);
            AutoLayout("source");
            string note = $"loaded {created.Count} table(s), {fkCount} FK edge(s) from {engine}";
            if (skipped > 0) note += $" ({skipped} external ref{(skipped == 1 ? "" : "s")} skipped)";
            Flash(note);
        }

        /// <summary>Resolve an FK target table name (which may be unqualified) to a created node, tolerating schema prefixes.</summary>
        private static ElementId ResolveFkTarget(string refTable, Dictionary<string, ElementId> created, DbSchema schema)
        {
            if (string.IsNullOrEmpty(refTable)) return ElementId.None;
            if (created.TryGetValue(refTable, out var id)) return id;
            // refTable may be bare ("users") while keys are qualified ("public.users") — match on the table part.
            string bare = refTable.Contains('.') ? refTable.Substring(refTable.LastIndexOf('.') + 1) : refTable;
            string qualified = string.IsNullOrEmpty(schema?.schema) ? bare : schema.schema + "." + bare;
            if (created.TryGetValue(qualified, out id)) return id;
            foreach (var kv in created)
            {
                string k = kv.Key;
                string kb = k.Contains('.') ? k.Substring(k.LastIndexOf('.') + 1) : k;
                if (string.Equals(kb, bare, StringComparison.OrdinalIgnoreCase)) return kv.Value;
            }
            return ElementId.None;
        }

        // ------------------------------------------------------------------ column signature convention

        /// <summary>
        /// Render a column as the on-canvas member signature this tool round-trips:
        /// <c>name : type {pk, notnull, unique, default=…, fk=refTable.refCol}</c>. Editable directly in the member
        /// editor; parsed back by <see cref="ParseColumn"/> when building the changelog.
        /// </summary>
        internal static string ComposeColumn(DbColumn c)
        {
            var sb = new StringBuilder();
            sb.Append(c.name).Append(" : ").Append(string.IsNullOrEmpty(c.dataType) ? "text" : c.dataType);
            var flags = new List<string>();
            if (c.isPrimaryKey) flags.Add("pk");
            if (!c.nullable && !c.isPrimaryKey) flags.Add("notnull");
            if (c.unique) flags.Add("unique");
            if (!string.IsNullOrEmpty(c.defaultValue)) flags.Add("default=" + c.defaultValue);
            if (c.IsForeignKey) flags.Add("fk=" + c.fkRefTable + "." + c.fkRefColumn);
            if (flags.Count > 0) sb.Append(" {").Append(string.Join(", ", flags)).Append('}');
            return sb.ToString();
        }

        /// <summary>Parse a column member signature back into a <see cref="DbColumn"/> (inverse of <see cref="ComposeColumn"/>).</summary>
        internal static DbColumn ParseColumn(string signature)
        {
            var c = new DbColumn { nullable = true };
            if (string.IsNullOrWhiteSpace(signature)) return c;
            string s = signature.Trim();

            string flags = "";
            int b = s.IndexOf('{');
            if (b >= 0)
            {
                int e = s.IndexOf('}', b + 1);
                flags = e > b ? s.Substring(b + 1, e - b - 1) : s.Substring(b + 1);
                s = s.Substring(0, b).Trim();
            }

            string type = "";
            int colon = s.IndexOf(':');
            if (colon >= 0) { c.name = s.Substring(0, colon).Trim(); type = s.Substring(colon + 1).Trim(); }
            else c.name = s.Trim();

            // Tolerate a leading UML visibility glyph if the user typed one.
            if (!string.IsNullOrEmpty(c.name) && "+-#~".IndexOf(c.name[0]) >= 0)
                c.name = c.name.Substring(1).Trim();
            c.dataType = DbTypeMap.Canonical(type);

            foreach (var raw in flags.Split(','))
            {
                string f = raw.Trim();
                if (f.Length == 0) continue;
                string fl = f.ToLowerInvariant();
                if (fl is "pk" or "primarykey" or "primary key") c.isPrimaryKey = true;
                else if (fl is "notnull" or "not null" or "nn") c.nullable = false;
                else if (fl is "nullable" or "null") c.nullable = true;
                else if (fl is "unique" or "uq") c.unique = true;
                else if (fl.StartsWith("default=")) c.defaultValue = f.Substring("default=".Length).Trim();
                else if (fl.StartsWith("fk"))
                {
                    // accept fk=t.c, fk->t.c, fk -> t.c
                    int eq = f.IndexOfAny(new[] { '=', '>' });
                    string tgt = eq >= 0 ? f.Substring(eq + 1).Trim() : "";
                    int lastDot = tgt.LastIndexOf('.');
                    if (lastDot > 0)
                    {
                        c.fkRefTable = tgt.Substring(0, lastDot).Trim();
                        c.fkRefColumn = tgt.Substring(lastDot + 1).Trim();
                    }
                }
            }
            if (c.isPrimaryKey) c.nullable = false;
            return c;
        }

        // ------------------------------------------------------------------ model → schema (for the changelog diff)

        /// <summary>
        /// Reconstruct a <see cref="DbSchema"/> from the current canvas: every <see cref="ElementKind.EntityTable"/>
        /// node becomes a table, its <see cref="ElementKind.Field"/> children become columns (parsed from their
        /// signatures). Used as the "current" side of the Liquibase diff.
        /// </summary>
        internal DbSchema ModelToSchema(DbSchema baselineForNamespace)
        {
            var schema = new DbSchema
            {
                engine = baselineForNamespace?.engine ?? DbSettings.ToConn().Engine,
                database = baselineForNamespace?.database ?? "",
                schema = baselineForNamespace?.schema ?? DbSettings.ToConn().SchemaFilter,
            };

            foreach (var el in _model.Elements)
            {
                if (el.Kind != ElementKind.EntityTable) continue;
                var t = new DbTable { name = el.Name?.Trim(), schema = SchemaOf(el, schema.schema), comment = el.CodeDoc };

                foreach (var child in _model.Elements)
                {
                    if (child.Kind != ElementKind.Field || child.Parent != el.Id) continue;
                    var col = ParseColumn(child.Name);
                    if (string.IsNullOrWhiteSpace(col.name)) continue;
                    t.columns.Add(col);
                    if (col.isPrimaryKey) t.primaryKey.Add(col.name);
                }
                schema.tables.Add(t);
            }
            return schema;
        }

        /// <summary>The owning schema for a table node — parsed from its <c>db://engine/schema.table</c> source tag, else the default.</summary>
        private static string SchemaOf(ModelElement el, string fallback)
        {
            string sf = el.SourceFile;
            if (!string.IsNullOrEmpty(sf) && sf.StartsWith(DbSourcePrefix))
            {
                int slash = sf.IndexOf('/', DbSourcePrefix.Length);
                string qualified = slash >= 0 ? sf.Substring(slash + 1) : "";
                int dot = qualified.IndexOf('.');
                if (dot > 0) return qualified.Substring(0, dot);
            }
            return fallback ?? "";
        }
    }
}
