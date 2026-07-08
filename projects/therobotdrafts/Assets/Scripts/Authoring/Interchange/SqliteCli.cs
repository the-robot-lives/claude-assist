using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Threading;

namespace TheRobotDraft.Authoring.Interchange
{
    /// <summary>
    /// Thin wrapper over the native <c>sqlite3</c> CLI used by the EA <c>.qea</c> reader/writer. We shell out
    /// (rather than bundle a managed SQLite driver) to match the editor's existing Process-based integrations
    /// (<see cref="TheRobotDraft.Schema.SchemaIntrospector"/>, VS Code, osascript) and avoid a Unity-side native DLL.
    ///
    /// <para><b>ASCII mode.</b> Reads run with <c>-ascii</c>, so fields are separated by the ASCII unit separator
    /// (0x1F) and records by the record separator (0x1E). Values in a <c>.qea</c> — element notes, SQL bodies —
    /// routinely contain embedded newlines, so callers must never split output on <c>\n</c>; split on
    /// <see cref="RecordSeparator"/> then <see cref="UnitSeparator"/> instead. <see cref="Query"/> does this.</para>
    ///
    /// <para><b>NULL vs empty string.</b> <c>sqlite3</c> renders SQL NULL as the empty string in <c>-ascii</c> mode,
    /// which is indistinguishable from a real empty <c>TEXT</c> value. Where the reader must tell them apart it
    /// wraps the column as <c>ifnull(col, char(7))</c>; the resulting BEL sentinel is exposed as
    /// <see cref="NullSentinel"/> and mapped back to null via <see cref="IsNull"/>. Most UML columns treat empty
    /// and NULL identically (both = "absent"), so the sentinel is only used where the distinction matters.</para>
    /// </summary>
    public static class SqliteCli
    {
        /// <summary>Field delimiter emitted by <c>sqlite3 -ascii</c> (ASCII US, 0x1F).</summary>
        public const char UnitSeparator = '\u001F';

        /// <summary>Record delimiter emitted by <c>sqlite3 -ascii</c> (ASCII RS, 0x1E); trails every row.</summary>
        public const char RecordSeparator = '\u001E';

        /// <summary>Value a column wrapped as <c>ifnull(col, char(7))</c> takes when SQL NULL (BEL, 0x07).</summary>
        public const string NullSentinel = "\u0007";

        private static readonly string[] Candidates =
        {
            "/usr/bin/sqlite3", "/opt/homebrew/bin/sqlite3", "/usr/local/bin/sqlite3", "sqlite3",
        };

        /// <summary>True when a usable <c>sqlite3</c> binary is present (tests use this to <c>Assert.Ignore</c>).</summary>
        public static bool IsAvailable => ResolveOrNull() != null;

        /// <summary>Absolute path of the resolved <c>sqlite3</c> binary, or a bare "sqlite3" to fall back to PATH.</summary>
        public static string Resolve()
        {
            return ResolveOrNull() ?? throw new InterchangeException(
                "sqlite3 not found (looked in " + string.Join(", ", Candidates) + " and PATH)");
        }

        private static string ResolveOrNull()
        {
            foreach (var c in Candidates)
            {
                if (c.IndexOf('/') < 0) return c;      // bare name => rely on PATH
                if (File.Exists(c)) return c;          // absolute => must exist
            }
            return null;
        }

        /// <summary>
        /// Run <paramref name="sql"/> against <paramref name="dbPath"/> opened read-only and return the result grid
        /// as rows of string fields. NULL renders as empty string unless the query uses the <see cref="NullSentinel"/>
        /// convention. Throws <see cref="InterchangeException"/> on a nonzero exit (with the captured stderr).
        /// </summary>
        public static string[][] Query(string dbPath, string sql)
        {
            if (!File.Exists(dbPath)) throw new InterchangeException("sqlite3 query: no such file: " + dbPath);

            var args = new List<string> { "-readonly", "-ascii", dbPath };
            Run(Resolve(), args, sql, out string stdout, out string stderr, out int code);
            if (code != 0) throw new InterchangeException("sqlite3 query failed: " + Clip(stderr));

            return ParseAscii(stdout);
        }

        /// <summary>
        /// Execute <paramref name="sqlScript"/> (the caller supplies its own BEGIN/COMMIT) against
        /// <paramref name="dbPath"/> read-write, piping the script via stdin. Throws
        /// <see cref="InterchangeException"/> with the captured stderr on a nonzero exit.
        /// </summary>
        public static void Execute(string dbPath, string sqlScript)
        {
            if (!File.Exists(dbPath)) throw new InterchangeException("sqlite3 execute: no such file: " + dbPath);

            var args = new List<string> { dbPath };
            Run(Resolve(), args, sqlScript, out string stdout, out string stderr, out int code);
            if (code != 0)
                throw new InterchangeException("sqlite3 execute failed: " + Clip(string.IsNullOrEmpty(stderr) ? stdout : stderr));
        }

        // -ascii output: fields joined by US, each record terminated by a trailing RS. An empty result set is the
        // empty string. We strip a single trailing RS then split so record/field counts come out exact.
        private static string[][] ParseAscii(string stdout)
        {
            if (string.IsNullOrEmpty(stdout)) return Array.Empty<string[]>();

            string body = stdout;
            if (body[body.Length - 1] == RecordSeparator) body = body.Substring(0, body.Length - 1);
            if (body.Length == 0) return Array.Empty<string[]>();

            var records = body.Split(RecordSeparator);
            var rows = new string[records.Length][];
            for (int i = 0; i < records.Length; i++)
                rows[i] = records[i].Split(UnitSeparator);
            return rows;
        }

        /// <summary>True when a cell wrapped with <c>ifnull(col, char(7))</c> came back as SQL NULL.</summary>
        public static bool IsNull(string cell) => cell == NullSentinel;

        // Run a child process, feed stdin, capture stdout/stderr/exit. stderr is drained on a background thread
        // so a large stdout can never deadlock against a stderr pipe that has filled (and vice versa).
        private static void Run(string exe, List<string> args, string stdin,
            out string stdout, out string stderr, out int exitCode)
        {
            var psi = new ProcessStartInfo(exe)
            {
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                RedirectStandardInput = true,
                StandardOutputEncoding = Encoding.UTF8,
                StandardErrorEncoding = Encoding.UTF8,
            };
            foreach (var a in args) psi.ArgumentList.Add(a);

            string errText = "";
            try
            {
                using var proc = Process.Start(psi);
                if (proc == null) throw new InterchangeException("could not start " + exe);

                var errThread = new Thread(() => { try { errText = proc.StandardError.ReadToEnd(); } catch { } })
                {
                    IsBackground = true,
                };
                errThread.Start();

                // Write UTF-8 bytes straight to the pipe so the script's encoding never depends on the platform
                // default StandardInput encoding (which we cannot set under this .NET Standard 2.0 profile).
                var inBytes = Encoding.UTF8.GetBytes(stdin ?? "");
                proc.StandardInput.BaseStream.Write(inBytes, 0, inBytes.Length);
                proc.StandardInput.BaseStream.Flush();
                proc.StandardInput.Close();

                stdout = proc.StandardOutput.ReadToEnd();
                if (!proc.WaitForExit(120_000))
                {
                    try { proc.Kill(); } catch { }
                    throw new InterchangeException("sqlite3 timed out");
                }
                errThread.Join(2_000);
                stderr = errText;
                exitCode = proc.ExitCode;
            }
            catch (InterchangeException) { throw; }
            catch (Exception ex)
            {
                throw new InterchangeException("sqlite3 process error: " + ex.Message, ex);
            }
        }

        private static string Clip(string s)
        {
            s = (s ?? "").Trim();
            return s.Length > 600 ? s.Substring(0, 600) + "…" : s;
        }
    }
}
