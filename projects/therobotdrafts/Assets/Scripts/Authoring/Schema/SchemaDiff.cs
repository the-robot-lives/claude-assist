using System;
using System.Collections.Generic;

namespace TheRobotDraft.Schema
{
    /// <summary>
    /// The delta between a loaded baseline schema and the current (canvas-edited) schema — "local changes". Computed
    /// by <see cref="Compute"/>, consumed by <see cref="LiquibaseYaml"/>. Tables and columns match by name
    /// (case-insensitive, schema-qualified). Single-column foreign keys are modelled inline on columns, so an FK
    /// change surfaces as an add/drop-FK entry alongside the column add/modify. Pure C#; unit-testable.
    /// </summary>
    public sealed class SchemaDiff
    {
        public readonly List<DbTable> AddedTables = new();
        public readonly List<string> DroppedTables = new();            // qualified names
        public readonly List<AddColumn> AddedColumns = new();
        public readonly List<DropColumn> DroppedColumns = new();
        public readonly List<ModifyColumn> ModifiedColumns = new();
        public readonly List<FkRef> AddedForeignKeys = new();
        public readonly List<FkRef> DroppedForeignKeys = new();

        public bool IsEmpty =>
            AddedTables.Count == 0 && DroppedTables.Count == 0 &&
            AddedColumns.Count == 0 && DroppedColumns.Count == 0 && ModifiedColumns.Count == 0 &&
            AddedForeignKeys.Count == 0 && DroppedForeignKeys.Count == 0;

        public int Count =>
            AddedTables.Count + DroppedTables.Count + AddedColumns.Count + DroppedColumns.Count +
            ModifiedColumns.Count + AddedForeignKeys.Count + DroppedForeignKeys.Count;

        public sealed class AddColumn { public string Table; public DbColumn Column; }
        public sealed class DropColumn { public string Table; public string Column; }
        public sealed class ModifyColumn { public string Table; public DbColumn Before; public DbColumn After; }

        /// <summary>One single-column foreign key, identified by its owning table + column and its referenced target.</summary>
        public sealed class FkRef
        {
            public string Table;       // owning table, qualified
            public string Column;      // owning column
            public string RefTable;    // referenced table, qualified
            public string RefColumn;   // referenced column
        }

        /// <summary>
        /// Diff <paramref name="current"/> against <paramref name="baseline"/>. Either may be null/empty (a first load
        /// with no edits yields an empty diff). Comparison is name-based; column equality covers type (canonicalized),
        /// nullability, primary-key membership, uniqueness, default, and FK target.
        /// </summary>
        public static SchemaDiff Compute(DbSchema baseline, DbSchema current)
        {
            var diff = new SchemaDiff();
            var baseTables = baseline?.tables ?? new List<DbTable>();
            var curTables = current?.tables ?? new List<DbTable>();

            var baseByName = Index(baseTables);
            var curByName = Index(curTables);

            // Added / dropped tables.
            foreach (var t in curTables)
                if (t != null && !baseByName.ContainsKey(Norm(t.Qualified)))
                    diff.AddedTables.Add(t);
            foreach (var t in baseTables)
                if (t != null && !curByName.ContainsKey(Norm(t.Qualified)))
                    diff.DroppedTables.Add(t.Qualified);

            // Column-level diffs across tables present in both.
            foreach (var cur in curTables)
            {
                if (cur == null) continue;
                if (!baseByName.TryGetValue(Norm(cur.Qualified), out var bas)) continue; // new table handled above

                var curCols = cur.columns ?? new List<DbColumn>();
                var basCols = bas.columns ?? new List<DbColumn>();
                var basColByName = IndexCols(basCols);
                var curColByName = IndexCols(curCols);

                // Added columns (+ their FK).
                foreach (var c in curCols)
                {
                    if (c == null || string.IsNullOrEmpty(c.name)) continue;
                    if (basColByName.ContainsKey(Norm(c.name))) continue;
                    diff.AddedColumns.Add(new AddColumn { Table = cur.Qualified, Column = c });
                    if (c.IsForeignKey)
                        diff.AddedForeignKeys.Add(Fk(cur.Qualified, c));
                }

                // Dropped columns (+ their FK).
                foreach (var c in basCols)
                {
                    if (c == null || string.IsNullOrEmpty(c.name)) continue;
                    if (curColByName.ContainsKey(Norm(c.name))) continue;
                    diff.DroppedColumns.Add(new DropColumn { Table = cur.Qualified, Column = c.name });
                    if (c.IsForeignKey)
                        diff.DroppedForeignKeys.Add(Fk(cur.Qualified, c));
                }

                // Modified columns + FK retargets.
                foreach (var c in curCols)
                {
                    if (c == null || string.IsNullOrEmpty(c.name)) continue;
                    if (!basColByName.TryGetValue(Norm(c.name), out var b)) continue;

                    if (!ColumnsEqualIgnoringFk(b, c))
                        diff.ModifiedColumns.Add(new ModifyColumn { Table = cur.Qualified, Before = b, After = c });

                    if (!FkEqual(b, c))
                    {
                        if (b.IsForeignKey) diff.DroppedForeignKeys.Add(Fk(cur.Qualified, b));
                        if (c.IsForeignKey) diff.AddedForeignKeys.Add(Fk(cur.Qualified, c));
                    }
                }
            }

            return diff;
        }

        // --- helpers ---

        private static FkRef Fk(string table, DbColumn c) => new FkRef
        {
            Table = table, Column = c.name, RefTable = c.fkRefTable, RefColumn = c.fkRefColumn,
        };

        private static bool ColumnsEqualIgnoringFk(DbColumn a, DbColumn b)
            => DbTypeMap.SameType(a.dataType, b.dataType)
               && a.nullable == b.nullable
               && a.isPrimaryKey == b.isPrimaryKey
               && a.unique == b.unique
               && string.Equals(NullToEmpty(a.defaultValue), NullToEmpty(b.defaultValue), StringComparison.Ordinal);

        private static bool FkEqual(DbColumn a, DbColumn b)
            => string.Equals(Norm(a.fkRefTable), Norm(b.fkRefTable), StringComparison.OrdinalIgnoreCase)
               && string.Equals(Norm(a.fkRefColumn), Norm(b.fkRefColumn), StringComparison.OrdinalIgnoreCase);

        private static Dictionary<string, DbTable> Index(List<DbTable> tables)
        {
            var d = new Dictionary<string, DbTable>();
            foreach (var t in tables)
                if (t != null && !string.IsNullOrEmpty(t.name)) d[Norm(t.Qualified)] = t;
            return d;
        }

        private static Dictionary<string, DbColumn> IndexCols(List<DbColumn> cols)
        {
            var d = new Dictionary<string, DbColumn>();
            foreach (var c in cols)
                if (c != null && !string.IsNullOrEmpty(c.name)) d[Norm(c.name)] = c;
            return d;
        }

        private static string Norm(string s) => (s ?? "").Trim().ToLowerInvariant();
        private static string NullToEmpty(string s) => s ?? "";
    }
}
