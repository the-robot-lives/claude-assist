using System;

namespace TheRobotDraft.Schema
{
    /// <summary>
    /// Normalizes engine-reported column types into a compact, comparable canonical form used everywhere downstream:
    /// the on-canvas column signature, the schema diff (so a no-op re-import doesn't read as a change), and the
    /// emitted Liquibase <c>type:</c> field. Pure C#; unit-testable. Intentionally conservative — it folds obvious
    /// vendor aliases (Postgres <c>int4</c>→<c>int</c>, <c>character varying</c>→<c>varchar</c>; MySQL display widths
    /// like <c>int(11)</c>→<c>int</c>) and otherwise passes the lower-cased type through untouched.
    /// </summary>
    public static class DbTypeMap
    {
        /// <summary>Canonicalize a raw engine type. Length/precision args (e.g. "(255)", "(10,2)") are preserved
        /// except for integer display widths, which carry no meaning and are dropped.</summary>
        public static string Canonical(string rawType)
        {
            if (string.IsNullOrWhiteSpace(rawType)) return "";
            string t = rawType.Trim();

            // Split "base(args)" — keep args to re-attach after base normalization.
            string args = "";
            int p = t.IndexOf('(');
            if (p >= 0)
            {
                int q = t.IndexOf(')', p);
                if (q > p) { args = t.Substring(p, q - p + 1); t = t.Substring(0, p); }
            }

            string baseLower = t.Trim().ToLowerInvariant();
            // Postgres/MySQL alias folding to a shared canonical vocabulary.
            string canon = baseLower switch
            {
                "character varying" => "varchar",
                "varchar2" => "varchar",
                "character" or "bpchar" => "char",
                "int4" or "integer" => "int",
                "int8" => "bigint",
                "int2" => "smallint",
                "int1" or "tinyint" => "tinyint",
                "serial" or "serial4" => "int",
                "bigserial" or "serial8" => "bigint",
                "bool" => "boolean",
                "float8" or "double precision" => "double",
                "float4" => "real",
                "numeric" => "decimal",
                "timestamp without time zone" => "timestamp",
                "timestamp with time zone" or "timestamptz" => "timestamptz",
                "time without time zone" => "time",
                "time with time zone" or "timetz" => "timetz",
                _ => baseLower,
            };

            // Integer display widths (MySQL int(11)) are noise — strip them.
            if (canon is "int" or "bigint" or "smallint" or "tinyint" or "boolean")
                args = "";

            return canon + args;
        }

        /// <summary>True when two raw types canonicalize to the same thing (the diff's type-equality test).</summary>
        public static bool SameType(string a, string b)
            => string.Equals(Canonical(a), Canonical(b), StringComparison.OrdinalIgnoreCase);
    }
}
