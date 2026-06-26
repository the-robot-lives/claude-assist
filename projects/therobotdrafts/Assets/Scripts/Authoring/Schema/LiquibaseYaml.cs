using System;
using System.Collections.Generic;
using System.Text;

namespace TheRobotDraft.Schema
{
    /// <summary>
    /// Emits a Liquibase YAML changelog from a <see cref="SchemaDiff"/> — the forward-engineering half of the DB
    /// round-trip ("prepare liquibase update changelogs based on local changes"). One changeSet per logical change,
    /// in a safe order (create tables → add columns → modify columns → add FKs → drop FKs → drop columns → drop
    /// tables) so a generated changelog applies cleanly. Deterministic; this is the seed an LLM pass may then refine.
    /// Pure C# (hand-rolled YAML, two-space indent) so it unit-tests without a Liquibase install.
    /// </summary>
    public static class LiquibaseYaml
    {
        /// <summary>
        /// Render <paramref name="diff"/> as a Liquibase YAML document. <paramref name="idStamp"/> is a caller-supplied
        /// timestamp token (e.g. "20260626-0855") that prefixes changeSet ids so successive generations stay unique
        /// and sortable. An empty diff yields a valid, empty <c>databaseChangeLog</c>.
        /// </summary>
        public static string Emit(SchemaDiff diff, string author, string idStamp)
        {
            author = string.IsNullOrWhiteSpace(author) ? "therobotdrafts" : author.Trim();
            idStamp = string.IsNullOrWhiteSpace(idStamp) ? "0" : idStamp.Trim();
            var sb = new StringBuilder();
            sb.Append("databaseChangeLog:\n");
            if (diff == null || diff.IsEmpty)
            {
                sb.Append("  # no local changes detected — model matches the loaded baseline\n");
                return sb.ToString();
            }

            int n = 0;

            // 1. createTable
            foreach (var t in diff.AddedTables)
                EmitCreateTable(sb, t, author, idStamp, ref n);

            // 2. addColumn
            foreach (var ac in diff.AddedColumns)
                EmitAddColumn(sb, ac, author, idStamp, ref n);

            // 3. modifyColumn (type / nullable / default), one changeSet per column
            foreach (var mc in diff.ModifiedColumns)
                EmitModifyColumn(sb, mc, author, idStamp, ref n);

            // 4. addForeignKeyConstraint
            foreach (var fk in diff.AddedForeignKeys)
                EmitAddForeignKey(sb, fk, author, idStamp, ref n);

            // 5. dropForeignKeyConstraint
            foreach (var fk in diff.DroppedForeignKeys)
                EmitDropForeignKey(sb, fk, author, idStamp, ref n);

            // 6. dropColumn
            foreach (var dc in diff.DroppedColumns)
                EmitDropColumn(sb, dc, author, idStamp, ref n);

            // 7. dropTable
            foreach (var qn in diff.DroppedTables)
                EmitDropTable(sb, qn, author, idStamp, ref n);

            return sb.ToString();
        }

        // --- changeSet emitters (each opens a changeSet then writes its single change) ---

        private static void EmitCreateTable(StringBuilder sb, DbTable t, string author, string stamp, ref int n)
        {
            ChangeSetHeader(sb, author, stamp, ++n, "create table " + t.Qualified);
            sb.Append("          - createTable:\n");
            sb.Append("              tableName: ").Append(Scalar(t.name)).Append('\n');
            AppendSchema(sb, t.schema, 14);
            if (!string.IsNullOrWhiteSpace(t.comment))
                sb.Append("              remarks: ").Append(Scalar(t.comment)).Append('\n');
            sb.Append("              columns:\n");
            foreach (var c in t.columns ?? new List<DbColumn>())
                EmitColumnNode(sb, c, t, 16);
        }

        private static void EmitAddColumn(StringBuilder sb, SchemaDiff.AddColumn ac, string author, string stamp, ref int n)
        {
            var (schema, table) = Split(ac.Table);
            ChangeSetHeader(sb, author, stamp, ++n, "add column " + ac.Table + "." + ac.Column.name);
            sb.Append("          - addColumn:\n");
            sb.Append("              tableName: ").Append(Scalar(table)).Append('\n');
            AppendSchema(sb, schema, 14);
            sb.Append("              columns:\n");
            EmitColumnNode(sb, ac.Column, null, 16);
        }

        private static void EmitModifyColumn(StringBuilder sb, SchemaDiff.ModifyColumn mc, string author, string stamp, ref int n)
        {
            var (schema, table) = Split(mc.Table);
            var before = mc.Before;
            var after = mc.After;

            // Type change → modifyDataType.
            if (!DbTypeMap.SameType(before.dataType, after.dataType))
            {
                ChangeSetHeader(sb, author, stamp, ++n, "alter type " + mc.Table + "." + after.name);
                sb.Append("          - modifyDataType:\n");
                sb.Append("              tableName: ").Append(Scalar(table)).Append('\n');
                AppendSchema(sb, schema, 14);
                sb.Append("              columnName: ").Append(Scalar(after.name)).Append('\n');
                sb.Append("              newDataType: ").Append(Scalar(after.dataType)).Append('\n');
            }

            // Nullability change → add/drop NOT NULL constraint.
            if (before.nullable != after.nullable)
            {
                if (!after.nullable)
                {
                    ChangeSetHeader(sb, author, stamp, ++n, "set not-null " + mc.Table + "." + after.name);
                    sb.Append("          - addNotNullConstraint:\n");
                    sb.Append("              tableName: ").Append(Scalar(table)).Append('\n');
                    AppendSchema(sb, schema, 14);
                    sb.Append("              columnName: ").Append(Scalar(after.name)).Append('\n');
                    sb.Append("              columnDataType: ").Append(Scalar(after.dataType)).Append('\n');
                }
                else
                {
                    ChangeSetHeader(sb, author, stamp, ++n, "drop not-null " + mc.Table + "." + after.name);
                    sb.Append("          - dropNotNullConstraint:\n");
                    sb.Append("              tableName: ").Append(Scalar(table)).Append('\n');
                    AppendSchema(sb, schema, 14);
                    sb.Append("              columnName: ").Append(Scalar(after.name)).Append('\n');
                    sb.Append("              columnDataType: ").Append(Scalar(after.dataType)).Append('\n');
                }
            }

            // Default change → addDefaultValue / dropDefaultValue.
            string bd = before.defaultValue ?? "", ad = after.defaultValue ?? "";
            if (!string.Equals(bd, ad, StringComparison.Ordinal))
            {
                if (!string.IsNullOrEmpty(ad))
                {
                    ChangeSetHeader(sb, author, stamp, ++n, "set default " + mc.Table + "." + after.name);
                    sb.Append("          - addDefaultValue:\n");
                    sb.Append("              tableName: ").Append(Scalar(table)).Append('\n');
                    AppendSchema(sb, schema, 14);
                    sb.Append("              columnName: ").Append(Scalar(after.name)).Append('\n');
                    sb.Append("              defaultValue: ").Append(Scalar(ad)).Append('\n');
                }
                else
                {
                    ChangeSetHeader(sb, author, stamp, ++n, "drop default " + mc.Table + "." + after.name);
                    sb.Append("          - dropDefaultValue:\n");
                    sb.Append("              tableName: ").Append(Scalar(table)).Append('\n');
                    AppendSchema(sb, schema, 14);
                    sb.Append("              columnName: ").Append(Scalar(after.name)).Append('\n');
                }
            }
        }

        private static void EmitAddForeignKey(StringBuilder sb, SchemaDiff.FkRef fk, string author, string stamp, ref int n)
        {
            var (schema, table) = Split(fk.Table);
            var (refSchema, refTable) = Split(fk.RefTable);
            string fkName = "fk_" + Sanitize(table) + "_" + Sanitize(fk.Column);
            ChangeSetHeader(sb, author, stamp, ++n, "add fk " + fk.Table + "." + fk.Column + " -> " + fk.RefTable);
            sb.Append("          - addForeignKeyConstraint:\n");
            sb.Append("              constraintName: ").Append(Scalar(fkName)).Append('\n');
            sb.Append("              baseTableName: ").Append(Scalar(table)).Append('\n');
            if (!string.IsNullOrEmpty(schema)) sb.Append("              baseTableSchemaName: ").Append(Scalar(schema)).Append('\n');
            sb.Append("              baseColumnNames: ").Append(Scalar(fk.Column)).Append('\n');
            sb.Append("              referencedTableName: ").Append(Scalar(refTable)).Append('\n');
            if (!string.IsNullOrEmpty(refSchema)) sb.Append("              referencedTableSchemaName: ").Append(Scalar(refSchema)).Append('\n');
            sb.Append("              referencedColumnNames: ").Append(Scalar(fk.RefColumn)).Append('\n');
        }

        private static void EmitDropForeignKey(StringBuilder sb, SchemaDiff.FkRef fk, string author, string stamp, ref int n)
        {
            var (schema, table) = Split(fk.Table);
            string fkName = "fk_" + Sanitize(table) + "_" + Sanitize(fk.Column);
            ChangeSetHeader(sb, author, stamp, ++n, "drop fk " + fk.Table + "." + fk.Column);
            sb.Append("          - dropForeignKeyConstraint:\n");
            sb.Append("              baseTableName: ").Append(Scalar(table)).Append('\n');
            if (!string.IsNullOrEmpty(schema)) sb.Append("              baseTableSchemaName: ").Append(Scalar(schema)).Append('\n');
            sb.Append("              constraintName: ").Append(Scalar(fkName)).Append('\n');
        }

        private static void EmitDropColumn(StringBuilder sb, SchemaDiff.DropColumn dc, string author, string stamp, ref int n)
        {
            var (schema, table) = Split(dc.Table);
            ChangeSetHeader(sb, author, stamp, ++n, "drop column " + dc.Table + "." + dc.Column);
            sb.Append("          - dropColumn:\n");
            sb.Append("              tableName: ").Append(Scalar(table)).Append('\n');
            AppendSchema(sb, schema, 14);
            sb.Append("              columnName: ").Append(Scalar(dc.Column)).Append('\n');
        }

        private static void EmitDropTable(StringBuilder sb, string qualified, string author, string stamp, ref int n)
        {
            var (schema, table) = Split(qualified);
            ChangeSetHeader(sb, author, stamp, ++n, "drop table " + qualified);
            sb.Append("          - dropTable:\n");
            sb.Append("              tableName: ").Append(Scalar(table)).Append('\n');
            AppendSchema(sb, schema, 14);
        }

        // --- shared fragments ---

        private static void ChangeSetHeader(StringBuilder sb, string author, string stamp, int n, string comment)
        {
            sb.Append("  - changeSet:\n");
            sb.Append("      id: ").Append(Scalar(stamp + "-" + n)).Append('\n');
            sb.Append("      author: ").Append(Scalar(author)).Append('\n');
            sb.Append("      comment: ").Append(Scalar(comment)).Append('\n');
            sb.Append("      changes:\n");
        }

        /// <summary>Write one "- column:" node at <paramref name="indent"/> spaces, with constraints when present.
        /// <paramref name="owner"/> (non-null for createTable) supplies composite-PK awareness.</summary>
        private static void EmitColumnNode(StringBuilder sb, DbColumn c, DbTable owner, int indent)
        {
            string pad = new string(' ', indent);
            string pad2 = new string(' ', indent + 4);
            string pad3 = new string(' ', indent + 6);
            sb.Append(pad).Append("- column:\n");
            sb.Append(pad2).Append("name: ").Append(Scalar(c.name)).Append('\n');
            sb.Append(pad2).Append("type: ").Append(Scalar(string.IsNullOrEmpty(c.dataType) ? "varchar(255)" : c.dataType)).Append('\n');
            if (!string.IsNullOrEmpty(c.defaultValue))
                sb.Append(pad2).Append("defaultValue: ").Append(Scalar(c.defaultValue)).Append('\n');

            bool pk = c.isPrimaryKey;
            bool notNull = !c.nullable;
            bool uniq = c.unique;
            if (pk || notNull || uniq)
            {
                sb.Append(pad2).Append("constraints:\n");
                if (pk) sb.Append(pad3).Append("primaryKey: true\n");
                if (notNull) sb.Append(pad3).Append("nullable: false\n");
                if (uniq) sb.Append(pad3).Append("unique: true\n");
            }
        }

        private static void AppendSchema(StringBuilder sb, string schema, int indent)
        {
            if (string.IsNullOrWhiteSpace(schema)) return;
            sb.Append(new string(' ', indent)).Append("schemaName: ").Append(Scalar(schema)).Append('\n');
        }

        private static (string schema, string table) Split(string qualified)
        {
            if (string.IsNullOrEmpty(qualified)) return ("", "");
            int dot = qualified.IndexOf('.');
            return dot < 0 ? ("", qualified) : (qualified.Substring(0, dot), qualified.Substring(dot + 1));
        }

        private static string Sanitize(string s)
        {
            if (string.IsNullOrEmpty(s)) return "x";
            var sb = new StringBuilder();
            foreach (char ch in s) sb.Append(char.IsLetterOrDigit(ch) ? ch : '_');
            return sb.ToString();
        }

        /// <summary>Quote a YAML scalar when it contains characters that would otherwise break parsing or change type.</summary>
        private static string Scalar(string s)
        {
            if (s == null) return "\"\"";
            if (s.Length == 0) return "\"\"";
            bool needsQuote = false;
            foreach (char ch in s)
                if (ch is ':' or '#' or '{' or '}' or '[' or ']' or ',' or '&' or '*' or '!' or '|' or '>'
                    or '\'' or '"' or '%' or '@' or '`' or '\n' or '\t')
                { needsQuote = true; break; }
            char c0 = s[0];
            if (!needsQuote && (char.IsWhiteSpace(c0) || c0 == '-' || c0 == '?' || char.IsWhiteSpace(s[s.Length - 1])))
                needsQuote = true;
            // Bareword that YAML would read as bool/null/number stays safe quoted too — cheap insurance for defaults.
            if (!needsQuote) return s;
            return "\"" + s.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\n", "\\n").Replace("\t", "\\t") + "\"";
        }
    }
}
