using System.Collections.Generic;
using System.Text;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Authoring.Debug
{
    /// <summary>
    /// One reference to another modeled element found inside an element's code listing — the thing the trace
    /// view turns into a clickable token so a click opens the referenced element's own code as a new bubble
    /// (the sketch's <c>s = Class2()</c> → open Class2). It is a lexical match of the other element's <em>name</em>
    /// on a given line, not a resolved call: good enough to navigate the bubble-IDE without a compiler frontend
    /// (the LSP/compiler path can refine this later behind the same model).
    /// </summary>
    public readonly struct CallSite
    {
        /// <summary>The element being referenced (its name matched on this line).</summary>
        public readonly ElementId Target;
        /// <summary>The matched name (the target's name as it appears on the line).</summary>
        public readonly string Name;
        /// <summary>1-based line in the source listing where the reference occurs.</summary>
        public readonly int Line;
        /// <summary>0-based character column of the match start on that line (for hit-testing the token).</summary>
        public readonly int Column;

        public CallSite(ElementId target, string name, int line, int column)
        {
            Target = target;
            Name = name;
            Line = line;
            Column = column;
        }
    }

    /// <summary>
    /// Finds, for one element's code listing, every reference to another modeled element by name — the call sites
    /// the trace view makes clickable. Pure logic (no engine refs): it blanks comments and string/char literals so
    /// a name inside a comment or string is not mistaken for a reference, then matches each known name on identifier
    /// boundaries. The element's own name and language keywords are skipped. The result is line-ordered.
    /// </summary>
    public static class CallSiteScanner
    {
        /// <summary>
        /// Scan <paramref name="source"/> for references to any name in <paramref name="namesToIds"/> (typically every
        /// classifier in the diagram except <paramref name="self"/>). Returns the matches in (line, column) order.
        /// A line/column offset is reported relative to the listing as given (so pass the same text the viewer shows).
        /// </summary>
        public static List<CallSite> Scan(string source, ElementId self,
            IReadOnlyDictionary<string, ElementId> namesToIds)
        {
            var sites = new List<CallSite>();
            if (string.IsNullOrEmpty(source) || namesToIds == null || namesToIds.Count == 0) return sites;

            string scan = BlankCommentsAndStrings(source);
            // Walk line by line so we can report a 1-based line + 0-based column.
            int line = 1, lineStart = 0;
            for (int i = 0; i <= scan.Length; i++)
            {
                bool eol = i == scan.Length || scan[i] == '\n';
                if (!eol) continue;

                string row = scan.Substring(lineStart, i - lineStart);
                ScanLine(row, line, namesToIds, self, sites);
                line++;
                lineStart = i + 1;
            }
            return sites;
        }

        private static void ScanLine(string row, int line,
            IReadOnlyDictionary<string, ElementId> namesToIds, ElementId self, List<CallSite> sites)
        {
            int col = 0;
            int n = row.Length;
            while (col < n)
            {
                // Find the next identifier start.
                if (!IsIdentStart(row[col])) { col++; continue; }
                int start = col;
                while (col < n && IsIdentChar(row[col])) col++;
                string word = row.Substring(start, col - start);
                if (namesToIds.TryGetValue(word, out var id) && id.IsValid && id != self)
                    sites.Add(new CallSite(id, word, line, start));
            }
        }

        private static bool IsIdentStart(char c) => char.IsLetter(c) || c == '_';
        private static bool IsIdentChar(char c) => char.IsLetterOrDigit(c) || c == '_';

        /// <summary>
        /// Replace comments and string/char literals with spaces (newlines preserved so offsets stay aligned with the
        /// original). A compact, language-agnostic pass covering <c>// … </c>, <c>/* … */</c>, <c># … </c> (shell /
        /// python / ruby / elixir line comments), and <c>" "</c> / <c>' '</c> / <c>` `</c> literals. Good enough to
        /// stop a name inside a comment or string from reading as a call site for any of the languages the app emits.
        /// </summary>
        private static string BlankCommentsAndStrings(string src)
        {
            var sb = new StringBuilder(src.Length);
            int i = 0, n = src.Length;
            while (i < n)
            {
                char c = src[i];

                if (c == '/' && i + 1 < n && src[i + 1] == '/')
                { while (i < n && src[i] != '\n') { sb.Append(' '); i++; } continue; }

                if (c == '#') // line comment in shell/python/ruby/elixir; harmless for C-family (rare mid-line)
                { while (i < n && src[i] != '\n') { sb.Append(' '); i++; } continue; }

                if (c == '/' && i + 1 < n && src[i + 1] == '*')
                {
                    while (i < n && !(src[i] == '*' && i + 1 < n && src[i + 1] == '/'))
                    { sb.Append(src[i] == '\n' ? '\n' : ' '); i++; }
                    if (i < n) { sb.Append(' '); i++; }
                    if (i < n) { sb.Append(' '); i++; }
                    continue;
                }

                if (c == '"' || c == '\'' || c == '`')
                {
                    char quote = c;
                    sb.Append(' '); i++;
                    while (i < n && src[i] != quote)
                    {
                        if (src[i] == '\\' && i + 1 < n) { sb.Append(' '); sb.Append(' '); i += 2; continue; }
                        sb.Append(src[i] == '\n' ? '\n' : ' '); i++;
                    }
                    if (i < n) { sb.Append(' '); i++; }
                    continue;
                }

                sb.Append(c);
                i++;
            }
            return sb.ToString();
        }
    }
}
