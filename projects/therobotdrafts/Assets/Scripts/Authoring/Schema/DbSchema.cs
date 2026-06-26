using System;
using System.Collections.Generic;

namespace TheRobotDraft.Schema
{
    /// <summary>
    /// A relational schema snapshot, engine-agnostic. Produced by <see cref="SchemaIntrospector"/> when a live
    /// database is loaded, and reconstructed from the canvas ERD (<c>UmlCanvas.DbImport.ModelToSchema</c>) when a
    /// Liquibase changelog is generated. Pure data ([Serializable] + public fields) so it lives in the engine-free
    /// authoring assembly, unit-tests directly, and round-trips through <c>UnityEngine.JsonUtility</c> for the
    /// persisted baseline snapshot (which the changelog diffs against).
    /// </summary>
    [Serializable]
    public sealed class DbSchema
    {
        /// <summary>Source engine: "postgres" or "mysql".</summary>
        public string engine;
        /// <summary>Database name (MySQL) — the namespace columns/tables belong to. Empty for Postgres.</summary>
        public string database;
        /// <summary>Postgres schema filter (e.g. "public"). Empty for MySQL.</summary>
        public string schema;
        public List<DbTable> tables = new();

        /// <summary>A stable key for the persisted baseline map — "engine/database" or "engine/schema".</summary>
        public string Key()
        {
            string ns = string.IsNullOrEmpty(database) ? (schema ?? "") : database;
            return (engine ?? "db") + "/" + ns;
        }

        public DbTable FindTable(string qualified)
        {
            if (tables == null) return null;
            foreach (var t in tables)
                if (t != null && string.Equals(t.Qualified, qualified, StringComparison.OrdinalIgnoreCase))
                    return t;
            return null;
        }
    }

    [Serializable]
    public sealed class DbTable
    {
        /// <summary>Owning namespace — Postgres schema ("public") or MySQL database. May be empty.</summary>
        public string schema;
        public string name;
        public string comment;
        public List<DbColumn> columns = new();
        /// <summary>Ordered primary-key column names (supports composite keys).</summary>
        public List<string> primaryKey = new();

        /// <summary>schema-qualified table name ("public.users" or just "users" when no schema).</summary>
        public string Qualified => string.IsNullOrEmpty(schema) ? (name ?? "") : schema + "." + name;

        public DbColumn FindColumn(string colName)
        {
            if (columns == null) return null;
            foreach (var c in columns)
                if (c != null && string.Equals(c.name, colName, StringComparison.OrdinalIgnoreCase))
                    return c;
            return null;
        }
    }

    [Serializable]
    public sealed class DbColumn
    {
        public string name;
        /// <summary>Canonical type (see <see cref="DbTypeMap"/>): e.g. "uuid", "varchar(255)", "bigint", "timestamptz".</summary>
        public string dataType;
        public bool nullable = true;
        /// <summary>Raw default expression (e.g. "now()", "0", "'pending'"); empty when none.</summary>
        public string defaultValue;
        public bool isPrimaryKey;
        public bool unique;
        // Single-column foreign key target (the common case modelled inline on the column). Empty when not an FK.
        /// <summary>Referenced table, schema-qualified when known ("public.organizations" or "organizations").</summary>
        public string fkRefTable;
        public string fkRefColumn;

        public bool IsForeignKey => !string.IsNullOrEmpty(fkRefTable) && !string.IsNullOrEmpty(fkRefColumn);
    }

    /// <summary>Parameters for a shell-out introspection. Pure data — no Unity dependency.</summary>
    public struct DbConnInfo
    {
        public string Engine;       // "postgres" | "mysql"
        public string Host;
        public int Port;
        public string Database;
        public string User;
        public string Password;
        public string SchemaFilter; // pg: schema (default "public"); mysql: ignored (database is the namespace)

        public bool IsPostgres => string.Equals(Engine, "postgres", StringComparison.OrdinalIgnoreCase);
        public bool IsMySql => string.Equals(Engine, "mysql", StringComparison.OrdinalIgnoreCase);
    }
}
