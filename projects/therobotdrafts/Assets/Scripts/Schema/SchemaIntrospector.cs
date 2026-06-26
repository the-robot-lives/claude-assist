using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Text;
using Debug = UnityEngine.Debug;

namespace TheRobotDraft.Schema
{
    /// <summary>
    /// Reads a live database's schema by shelling out to the native CLI client (<c>psql</c> for Postgres, <c>mysql</c>
    /// for MySQL) and parsing tab-separated output into a <see cref="DbSchema"/>. This is the reverse-engineering
    /// half of the DB round-trip — the analogue of <c>UmlCanvas.CodeImport</c> for code. We shell out (rather than
    /// bundling a managed driver) to match the editor's existing Process-based integrations (VS Code, osascript) and
    /// avoid a Unity-side DLL. The password is passed via the child process environment (<c>PGPASSWORD</c>/
    /// <c>MYSQL_PWD</c>), never on the command line.
    /// </summary>
    public static class SchemaIntrospector
    {
        /// <summary>Cap on tables ingested in one load — keeps a huge catalog from stalling the editor.</summary>
        public const int TableCap = 500;

        // Section markers we ask psql to \echo between query results so one stdin script yields all sections.
        private const string MTables = "@@TABLES";
        private const string MCols = "@@COLUMNS";
        private const string MPk = "@@PK";
        private const string MUniq = "@@UNIQUE";
        private const string MFk = "@@FK";

        private static readonly string[] PsqlCandidates =
        {
            "/opt/homebrew/opt/libpq/bin/psql", "/opt/homebrew/bin/psql",
            "/usr/local/opt/libpq/bin/psql", "/usr/local/bin/psql", "/usr/bin/psql", "psql",
        };

        private static readonly string[] MysqlCandidates =
        {
            "/opt/homebrew/opt/mysql-client/bin/mysql", "/opt/homebrew/bin/mysql",
            "/usr/local/opt/mysql-client/bin/mysql", "/usr/local/bin/mysql", "/usr/bin/mysql", "mysql",
        };

        /// <summary>Read the full schema for <paramref name="conn"/>, or null + <paramref name="error"/> on failure.</summary>
        public static DbSchema Read(DbConnInfo conn, out string error)
        {
            error = null;
            try
            {
                if (conn.IsPostgres) return ReadPostgres(conn, out error);
                if (conn.IsMySql) return ReadMySql(conn, out error);
                error = "unsupported engine: " + conn.Engine;
                return null;
            }
            catch (Exception ex)
            {
                error = ex.Message;
                return null;
            }
        }

        // ============================================================ Postgres

        private static DbSchema ReadPostgres(DbConnInfo conn, out string error)
        {
            error = null;
            string schema = string.IsNullOrWhiteSpace(conn.SchemaFilter) ? "public" : conn.SchemaFilter.Trim();

            string exe = Resolve(PsqlCandidates);
            var args = new List<string>
            {
                "-X", "-A", "-t", "-q",
                "-F", "\t",
                "-v", "ON_ERROR_STOP=1",
                "--set", "sch=" + schema,
                "-h", conn.Host,
                "-p", conn.Port.ToString(),
                "-U", conn.User,
                "-d", string.IsNullOrWhiteSpace(conn.Database) ? conn.User : conn.Database,
                "-f", "-", // read the script from stdin
            };
            var env = new Dictionary<string, string> { ["PGPASSWORD"] = conn.Password ?? "" };

            string script = PostgresScript();
            if (!Run(exe, args, env, script, out string stdout, out string stderr, out int code) || code != 0)
            {
                error = "psql failed: " + Trim(stderr, stdout);
                return null;
            }

            var schemaObj = new DbSchema { engine = "postgres", schema = schema, database = conn.Database };
            ParsePostgres(stdout, schemaObj);
            return schemaObj;
        }

        private static string PostgresScript()
        {
            // One script, sections separated by \echo markers. format_type gives clean, length-aware type strings.
            var sb = new StringBuilder();
            sb.Append("\\pset pager off\n");
            sb.Append("\\echo ").Append(MTables).Append('\n');
            sb.Append(
                "SELECT n.nspname, c.relname, COALESCE(obj_description(c.oid),'') " +
                "FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace " +
                "WHERE c.relkind='r' AND n.nspname = :'sch' ORDER BY c.relname;\n");
            sb.Append("\\echo ").Append(MCols).Append('\n');
            sb.Append(
                "SELECT n.nspname, c.relname, a.attname, format_type(a.atttypid, a.atttypmod), " +
                "a.attnotnull, COALESCE(pg_get_expr(d.adbin, d.adrelid),''), a.attnum " +
                "FROM pg_attribute a JOIN pg_class c ON c.oid=a.attrelid " +
                "JOIN pg_namespace n ON n.oid=c.relnamespace " +
                "LEFT JOIN pg_attrdef d ON d.adrelid=a.attrelid AND d.adnum=a.attnum " +
                "WHERE c.relkind='r' AND a.attnum>0 AND NOT a.attisdropped AND n.nspname = :'sch' " +
                "ORDER BY c.relname, a.attnum;\n");
            sb.Append("\\echo ").Append(MPk).Append('\n');
            sb.Append(
                "SELECT n.nspname, c.relname, a.attname " +
                "FROM pg_index i JOIN pg_class c ON c.oid=i.indrelid " +
                "JOIN pg_namespace n ON n.oid=c.relnamespace " +
                "JOIN pg_attribute a ON a.attrelid=c.oid AND a.attnum = ANY(i.indkey) " +
                "WHERE i.indisprimary AND n.nspname = :'sch';\n");
            sb.Append("\\echo ").Append(MUniq).Append('\n');
            sb.Append(
                "SELECT n.nspname, c.relname, a.attname " +
                "FROM pg_index i JOIN pg_class c ON c.oid=i.indrelid " +
                "JOIN pg_namespace n ON n.oid=c.relnamespace " +
                "JOIN pg_attribute a ON a.attrelid=c.oid AND a.attnum = ANY(i.indkey) " +
                "WHERE i.indisunique AND NOT i.indisprimary AND array_length(i.indkey,1)=1 AND n.nspname = :'sch';\n");
            sb.Append("\\echo ").Append(MFk).Append('\n');
            sb.Append(
                "SELECT n.nspname, c.relname, att.attname, fn.nspname, fc.relname, ratt.attname " +
                "FROM pg_constraint con JOIN pg_class c ON c.oid=con.conrelid " +
                "JOIN pg_namespace n ON n.oid=c.relnamespace " +
                "JOIN pg_class fc ON fc.oid=con.confrelid " +
                "JOIN pg_namespace fn ON fn.oid=fc.relnamespace " +
                "JOIN unnest(con.conkey) WITH ORDINALITY AS ck(attnum, ord) ON true " +
                "JOIN unnest(con.confkey) WITH ORDINALITY AS fkk(attnum, ord) ON fkk.ord = ck.ord " +
                "JOIN pg_attribute att ON att.attrelid=c.oid AND att.attnum=ck.attnum " +
                "JOIN pg_attribute ratt ON ratt.attrelid=fc.oid AND ratt.attnum=fkk.attnum " +
                "WHERE con.contype='f' AND n.nspname = :'sch';\n");
            return sb.ToString();
        }

        private static void ParsePostgres(string stdout, DbSchema schema)
        {
            var byName = new Dictionary<string, DbTable>(StringComparer.OrdinalIgnoreCase);
            DbTable Get(string sch, string name)
            {
                string key = sch + "." + name;
                if (!byName.TryGetValue(key, out var t))
                {
                    t = new DbTable { schema = sch, name = name };
                    byName[key] = t;
                    schema.tables.Add(t);
                }
                return t;
            }

            string section = null;
            foreach (var raw in SplitLines(stdout))
            {
                string line = raw;
                if (line.Length == 0) continue;
                if (line[0] == '@' && line.StartsWith("@@")) { section = line.Trim(); continue; }
                var f = line.Split('\t');

                switch (section)
                {
                    case MTables:
                        if (f.Length >= 2)
                        {
                            if (byName.Count >= TableCap) { Debug.LogWarning($"[DB] table cap {TableCap} hit; truncating"); break; }
                            var t = Get(f[0], f[1]);
                            if (f.Length >= 3) t.comment = f[2];
                        }
                        break;
                    case MCols:
                        if (f.Length >= 6)
                        {
                            string sch = f[0];
                            if (!byName.ContainsKey(sch + "." + f[1])) break; // table was capped out
                            var tt = Get(sch, f[1]);
                            tt.columns.Add(new DbColumn
                            {
                                name = f[2],
                                dataType = DbTypeMap.Canonical(f[3]),
                                nullable = !IsTrue(f[4]),       // attnotnull: t => NOT nullable
                                defaultValue = f[5],
                            });
                        }
                        break;
                    case MPk:
                        if (f.Length >= 3 && byName.TryGetValue(f[0] + "." + f[1], out var pkt))
                        {
                            pkt.primaryKey.Add(f[2]);
                            var col = pkt.FindColumn(f[2]);
                            if (col != null) col.isPrimaryKey = true;
                        }
                        break;
                    case MUniq:
                        if (f.Length >= 3 && byName.TryGetValue(f[0] + "." + f[1], out var ut))
                        {
                            var col = ut.FindColumn(f[2]);
                            if (col != null) col.unique = true;
                        }
                        break;
                    case MFk:
                        if (f.Length >= 6 && byName.TryGetValue(f[0] + "." + f[1], out var ft))
                        {
                            var col = ft.FindColumn(f[2]);
                            if (col != null)
                            {
                                col.fkRefTable = string.IsNullOrEmpty(f[3]) ? f[4] : f[3] + "." + f[4];
                                col.fkRefColumn = f[5];
                            }
                        }
                        break;
                }
            }
        }

        // ============================================================ MySQL

        private static DbSchema ReadMySql(DbConnInfo conn, out string error)
        {
            error = null;
            string db = string.IsNullOrWhiteSpace(conn.Database) ? conn.User : conn.Database.Trim();
            string exe = Resolve(MysqlCandidates);
            var env = new Dictionary<string, string> { ["MYSQL_PWD"] = conn.Password ?? "" };

            List<string> BaseArgs(string sql) => new List<string>
            {
                "--batch", "--raw", "-N",
                "-h", conn.Host, "-P", conn.Port.ToString(), "-u", conn.User,
                "-e", sql,
            };

            string esc = db.Replace("'", "''");
            string tablesSql =
                $"SELECT TABLE_SCHEMA, TABLE_NAME, COALESCE(TABLE_COMMENT,'') FROM information_schema.TABLES " +
                $"WHERE TABLE_SCHEMA='{esc}' AND TABLE_TYPE='BASE TABLE' ORDER BY TABLE_NAME;";
            string colsSql =
                $"SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COALESCE(COLUMN_DEFAULT,''), " +
                $"COLUMN_KEY, ORDINAL_POSITION FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='{esc}' " +
                $"ORDER BY TABLE_NAME, ORDINAL_POSITION;";
            string fkSql =
                $"SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, REFERENCED_TABLE_SCHEMA, REFERENCED_TABLE_NAME, " +
                $"REFERENCED_COLUMN_NAME FROM information_schema.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA='{esc}' " +
                $"AND REFERENCED_TABLE_NAME IS NOT NULL;";

            if (!Run(exe, BaseArgs(tablesSql), env, null, out string tOut, out string tErr, out int tCode) || tCode != 0)
            { error = "mysql failed: " + Trim(tErr, tOut); return null; }
            if (!Run(exe, BaseArgs(colsSql), env, null, out string cOut, out string cErr, out int cCode) || cCode != 0)
            { error = "mysql failed: " + Trim(cErr, cOut); return null; }
            if (!Run(exe, BaseArgs(fkSql), env, null, out string fOut, out string fErr, out int fCode) || fCode != 0)
            { error = "mysql failed: " + Trim(fErr, fOut); return null; }

            var schemaObj = new DbSchema { engine = "mysql", database = db, schema = "" };
            var byName = new Dictionary<string, DbTable>(StringComparer.OrdinalIgnoreCase);
            DbTable Get(string sch, string name)
            {
                string key = sch + "." + name;
                if (!byName.TryGetValue(key, out var t))
                {
                    t = new DbTable { schema = sch, name = name };
                    byName[key] = t; schemaObj.tables.Add(t);
                }
                return t;
            }

            foreach (var line in SplitLines(tOut))
            {
                var f = line.Split('\t');
                if (f.Length < 2) continue;
                if (byName.Count >= TableCap) { Debug.LogWarning($"[DB] table cap {TableCap} hit; truncating"); break; }
                var t = Get(f[0], f[1]);
                if (f.Length >= 3) t.comment = f[2];
            }
            foreach (var line in SplitLines(cOut))
            {
                var f = line.Split('\t');
                if (f.Length < 7) continue;
                if (!byName.ContainsKey(f[0] + "." + f[1])) continue; // capped out
                var t = Get(f[0], f[1]);
                bool pk = string.Equals(f[6], "PRI", StringComparison.OrdinalIgnoreCase);
                var col = new DbColumn
                {
                    name = f[2],
                    dataType = DbTypeMap.Canonical(f[3]),
                    nullable = string.Equals(f[4], "YES", StringComparison.OrdinalIgnoreCase),
                    defaultValue = f[5],
                    isPrimaryKey = pk,
                    unique = string.Equals(f[6], "UNI", StringComparison.OrdinalIgnoreCase),
                };
                t.columns.Add(col);
                if (pk) t.primaryKey.Add(col.name);
            }
            foreach (var line in SplitLines(fOut))
            {
                var f = line.Split('\t');
                if (f.Length < 6) continue;
                if (!byName.TryGetValue(f[0] + "." + f[1], out var t)) continue;
                var col = t.FindColumn(f[2]);
                if (col != null)
                {
                    col.fkRefTable = string.IsNullOrEmpty(f[3]) ? f[4] : f[3] + "." + f[4];
                    col.fkRefColumn = f[5];
                }
            }
            return schemaObj;
        }

        // ============================================================ process plumbing

        /// <summary>Run a child process, optionally feeding <paramref name="stdin"/>, capturing stdout/stderr/exit.</summary>
        private static bool Run(string exe, List<string> args, Dictionary<string, string> env, string stdin,
            out string stdout, out string stderr, out int exitCode)
        {
            stdout = stderr = ""; exitCode = -1;
            var psi = new ProcessStartInfo(exe)
            {
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                RedirectStandardInput = stdin != null,
            };
            foreach (var a in args) psi.ArgumentList.Add(a);
            if (env != null) foreach (var kv in env) psi.EnvironmentVariables[kv.Key] = kv.Value;

            try
            {
                using var proc = Process.Start(psi);
                if (proc == null) { stderr = "could not start " + exe; return false; }
                if (stdin != null)
                {
                    proc.StandardInput.Write(stdin);
                    proc.StandardInput.Close();
                }
                stdout = proc.StandardOutput.ReadToEnd();
                stderr = proc.StandardError.ReadToEnd();
                if (!proc.WaitForExit(60_000)) { try { proc.Kill(); } catch { } stderr = "timed out"; return false; }
                exitCode = proc.ExitCode;
                return true;
            }
            catch (Exception ex)
            {
                stderr = ex.Message;
                return false;
            }
        }

        private static string Resolve(string[] candidates)
        {
            foreach (var c in candidates)
                if (c.IndexOf('/') < 0 || File.Exists(c)) return c; // bare name => rely on PATH; absolute => must exist
            return candidates[candidates.Length - 1];
        }

        private static IEnumerable<string> SplitLines(string s)
        {
            if (string.IsNullOrEmpty(s)) yield break;
            foreach (var line in s.Replace("\r\n", "\n").Split('\n'))
                if (line.Length > 0) yield return line;
        }

        private static bool IsTrue(string s) => s == "t" || string.Equals(s, "true", StringComparison.OrdinalIgnoreCase);

        private static string Trim(string a, string b)
        {
            string s = string.IsNullOrWhiteSpace(a) ? b : a;
            s = (s ?? "").Trim();
            return s.Length > 400 ? s.Substring(0, 400) + "…" : s;
        }
    }
}
