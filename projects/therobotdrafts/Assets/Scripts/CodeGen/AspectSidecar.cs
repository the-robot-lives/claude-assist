using System.Collections.Generic;
using System.IO;
using System.Text;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.CodeGen
{
    /// <summary>
    /// Writes the <c>.trd.{filename.ext}.meta.yaml</c> sidecar — the extraction counterpart to code generation. It is
    /// keyed by each element/edge's compact <c>DeepLinkCode</c> (the four-glyph ⟦code⟧ token), and carries the aspects
    /// + freeform metadata that don't fit as native annotations / doc-tags / comments: by convention the entries whose
    /// effective <see cref="EmitFlags"/> set the <c>Meta</c> flag, plus all freeform key-values. Sparse by design — only
    /// overridden field values are emitted per aspect (defaults live on the def, not the sidecar).
    ///
    /// <para>The sidecar is a merge target: re-running against an existing file preserves unknown keys (other tools /
    /// manual edits) and only rewrites the keys for the elements supplied. This makes it safe to regenerate alongside
    /// a code overlay without clobbering unrelated metadata.</para>
    ///
    /// <para>Engine-free (no UnityEngine / JsonUtility): hand-rolled YAML, consistent with <c>TrdYamlWriter</c>'s flow
    /// subset — keys are always single-quoted (the unicode/weirdness rule), scalars are quoted per need.</para>
    /// </summary>
    public static class AspectSidecar
    {
        /// <summary>One entry to write: the DeepLinkCode key + the resolved aspect values + freeform to emit.</summary>
        public sealed class Entry
        {
            /// <summary>The four-glyph DeepLinkCode (without ⟦⟧ markers). Used as the YAML map key.</summary>
            public string Code;
            /// <summary>Aspects to emit. Only those whose <see cref="AspectView.Emit"/> sets Meta are written; within
            /// each, only the field values present in <see cref="AspectView.Values"/> are emitted (sparse).</summary>
            public List<CodeGenContext.AspectView> Aspects = new();
            /// <summary>Freeform key-values (all emitted, unconstrained by schema).</summary>
            public List<FreeformEntry> Freeform = new();
        }

        /// <summary>The canonical sidecar path for a source file: <c>{dir}/.trd.{basename}.meta.yaml</c>.</summary>
        public static string PathFor(string sourceFile)
        {
            string dir = string.IsNullOrEmpty(sourceFile) ? "" : (System.IO.Path.GetDirectoryName(sourceFile) ?? "");
            string baseName = System.IO.Path.GetFileName(sourceFile);
            string fileName = ".trd." + baseName + ".meta.yaml";
            return string.IsNullOrEmpty(dir) ? fileName : System.IO.Path.Combine(dir, fileName);
        }

        /// <summary>
        /// Render the sidecar YAML for the supplied entries (one map per DeepLinkCode). Does NOT touch disk — callers
        /// pass the result to <see cref="Write"/> or use it directly. Stable order: entries in the order given.
        /// </summary>
        public static string Render(IList<Entry> entries)
        {
            var sb = new StringBuilder();
            sb.Append("# The Robot Drafts aspect metadata sidecar. Keyed by DeepLinkCode (⟦code⟧). Sparse + merge-friendly.\n");
            if (entries == null || entries.Count == 0) return sb.ToString();
            foreach (var e in entries)
            {
                if (e == null || string.IsNullOrEmpty(e.Code)) continue;
                bool hasAspect = HasMetaAspect(e);
                bool hasFreeform = e.Freeform != null && e.Freeform.Count > 0;
                if (!hasAspect && !hasFreeform) continue; // nothing to emit for this key

                sb.Append(QuotedKey(e.Code)).Append(":\n");
                if (hasAspect)
                {
                    sb.Append("  'aspects':\n");
                    foreach (var a in e.Aspects)
                    {
                        if (a == null || !a.Emit.Meta || string.IsNullOrEmpty(a.Name)) continue;
                        sb.Append("    ").Append(QuotedKey(a.Name)).Append(":\n");
                        if (a.DefVersion > 0) sb.Append("      '_defv': ").Append(a.DefVersion).Append('\n');
                        foreach (var kv in a.Values)
                            sb.Append("      ").Append(QuotedKey(kv.Key)).Append(": ").Append(Scalar(kv.Value)).Append('\n');
                    }
                }
                if (hasFreeform)
                {
                    sb.Append("  'freeform':\n");
                    foreach (var f in e.Freeform)
                        if (f != null && !string.IsNullOrEmpty(f.Key))
                            sb.Append("    ").Append(QuotedKey(f.Key)).Append(": ").Append(Scalar(f.Value)).Append('\n');
                }
            }
            return sb.ToString();
        }

        /// <summary>Write (or merge) the rendered sidecar to disk. Existing unknown top-level keys are preserved.</summary>
        public static void Write(string path, IList<Entry> entries)
        {
            if (string.IsNullOrEmpty(path)) return;
            string fresh = Render(entries);
            // Merge: keep any existing top-level DeepLinkCode blocks we did NOT supply this run. We do a coarse
            // preserve-by-key merge — parse the top-level (un-indented) `code:` headers from the old file and keep the
            // blocks for codes absent from the current entries. This is intentionally simple (the sidecar is append-mostly).
            string result = fresh;
            var supplied = new HashSet<string>();
            if (entries != null) foreach (var e in entries) if (e != null && !string.IsNullOrEmpty(e.Code)) supplied.Add(e.Code);
            if (File.Exists(path))
            {
                var kept = new StringBuilder();
                var old = File.ReadAllText(path);
                string[] lines = old.Split('\n');
                int i = 0;
                while (i < lines.Length)
                {
                    string line = lines[i];
                    string headerKey = HeaderKey(line);
                    if (headerKey != null && !supplied.Contains(headerKey))
                    {
                        // copy this header + its indented block through
                        kept.Append(line).Append('\n');
                        i++;
                        while (i < lines.Length)
                        {
                            // stop at the next top-level header (a new key at column 0)
                            if (HeaderKey(lines[i]) != null) break;
                            kept.Append(lines[i]).Append('\n');
                            i++;
                        }
                    }
                    else i++;
                }
                string keptStr = kept.ToString();
                if (keptStr.Trim().Length > 0)
                {
                    // drop the trailing header comment duplication: append preserved blocks after our fresh header
                    result = fresh.TrimEnd('\n') + "\n" + keptStr;
                }
            }
            File.WriteAllText(path, result);
        }

        // --- internals ---

        private static bool HasMetaAspect(Entry e)
        {
            if (e.Aspects == null) return false;
            foreach (var a in e.Aspects) if (a != null && a.Emit.Meta && !string.IsNullOrEmpty(a.Name)) return true;
            return false;
        }

        private static string QuotedKey(string s)
        {
            string c = (s ?? "").Replace("'", "''");
            return "'" + c + "'";
        }

        // Always-quote would be safest, but ints/floats/bools read better bare; quote everything else.
        private static string Scalar(string s)
        {
            if (s == null) return "''";
            string t = s.Trim();
            if (t == "true" || t == "false") return t;
            if (double.TryParse(t, out _)) return t;
            return "'" + t.Replace("'", "''") + "'";
        }

        // A top-level header is a line starting at column 0 with a quoted '...': form.
        private static string HeaderKey(string line)
        {
            if (line == null || line.Length == 0 || char.IsWhiteSpace(line[0])) return null;
            if (line[0] != '\'') return null;
            // matches 'key': (unquoted colon)
            int close = line.IndexOf("':", System.StringComparison.Ordinal);
            if (close <= 0) return null;
            string key = line.Substring(1, close - 1).Replace("''", "'");
            return key;
        }
    }
}
