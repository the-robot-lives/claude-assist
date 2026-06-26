using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEngine.Networking;
using TheRobotDraft.Authoring.Model;
using TheRobotDraft.Llm;
using TheRobotDraft.Schema;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// Forward-engineering: emit a Liquibase YAML changelog from the local ERD edits — the DB analogue of
    /// <c>UmlCanvas.CodeGen</c>. Reconstructs the current schema from the canvas (<see cref="ModelToSchema"/>), diffs
    /// it against the baseline captured at load (<see cref="SchemaDiff.Compute"/>), renders deterministic Liquibase
    /// YAML (<see cref="LiquibaseYaml"/>), and — when an LLM endpoint is configured — refines that seed. Shown in the
    /// shared code viewer with a Save-to-file button.
    /// </summary>
    public sealed partial class UmlCanvas
    {
        /// <summary>Diff the canvas ERD against the loaded baseline and present a Liquibase changelog of the delta.</summary>
        public void GenerateLiquibaseChangelog()
        {
            CloseMenu();
            if (_dbBaseline.Count == 0)
            {
                Flash("load a DB schema first  (canvas menu ▸ DB ▸ Load schema)");
                return;
            }

            string key = !string.IsNullOrEmpty(_dbActiveBaseline) && _dbBaseline.ContainsKey(_dbActiveBaseline)
                ? _dbActiveBaseline
                : FirstKey(_dbBaseline);

            var baseline = JsonUtility.FromJson<DbSchema>(_dbBaseline[key]);
            var current = ModelToSchema(baseline);
            var diff = SchemaDiff.Compute(baseline, current);

            string stamp = DateTime.Now.ToString("yyyyMMdd-HHmmss");
            string yaml = LiquibaseYaml.Emit(diff, DbSettings.Author, stamp);
            string status = diff.IsEmpty
                ? "no local changes vs the loaded baseline"
                : $"{diff.Count} change(s) — review, audit, or save";

            var setText = ShowCodeViewer(
                "Liquibase changelog   —   local schema changes",
                yaml, status, ElementId.None,
                onRegenerate: GenerateLiquibaseChangelog,
                language: "yaml",
                onSaveToFile: SaveChangelogToFile);

            // Optional LLM audit/refine pass when an endpoint is configured and there is something to refine.
            if (!diff.IsEmpty && !string.IsNullOrEmpty(LlmSettings.BaseUrl))
                StartCoroutine(RunLlmDbChangelog(yaml, baseline.engine, setText));
        }

        /// <summary>
        /// Ask the configured LLM to audit/refine the deterministic changelog: keep the same changes and semantics,
        /// sanity-check Postgres↔MySQL type mappings, add concise comments, and guarantee valid Liquibase YAML.
        /// Falls back to the deterministic seed on any error.
        /// </summary>
        private IEnumerator RunLlmDbChangelog(string seed, string engine, Action<string, string> setText)
        {
            setText(seed, "asking the model to audit the changelog…");

            const string sys =
                "You are a database migration expert. You are given a deterministic Liquibase YAML changelog produced " +
                "from a schema diff. Return an improved, VALID Liquibase YAML changelog that preserves exactly the same " +
                "set of changes and their semantics. Fix any obvious data-type issues for the target engine, add a short " +
                "comment to each changeSet, and ensure it parses as Liquibase YAML. Return ONLY the YAML — no markdown " +
                "fences, no commentary.";
            string user = "Target engine: " + (string.IsNullOrEmpty(engine) ? "postgres" : engine) +
                          "\n\nDeterministic changelog to refine:\n" + seed;

            using (var req = LlmClient.BuildChatRequest(sys, user))
            {
                req.timeout = 60;
                yield return req.SendWebRequest();

                if (req.result != UnityWebRequest.Result.Success)
                {
                    setText(seed, "LLM unavailable — showing the deterministic changelog  (" + req.error + ")");
                    yield break;
                }
                if (!LlmClient.TryParseContent(req.downloadHandler.text, out var content, out var apiError))
                {
                    setText(seed, "kept the deterministic changelog  (" + apiError + ")");
                    yield break;
                }

                string refined = StripFences(content);
                if (string.IsNullOrWhiteSpace(refined)) { setText(seed, "kept the deterministic changelog (empty reply)"); yield break; }
                setText(refined, "audited & refined by " + LlmSettings.Model + " — review and save");
            }
        }

        /// <summary>Write the changelog to a user-picked location (editor save panel / macOS osascript), defaulting to a
        /// db/changelog folder under the persistent data path.</summary>
        private void SaveChangelogToFile(string yaml)
        {
            string defaultDir = Path.Combine(Application.persistentDataPath, "db", "changelog");
            string defaultName = DateTime.Now.ToString("yyyyMMddHHmmss") + "_changes.yaml";

            string path = BrowseForSaveFile(defaultDir, defaultName);
            if (string.IsNullOrEmpty(path)) { Flash("save cancelled"); return; }

            try
            {
                Directory.CreateDirectory(Path.GetDirectoryName(path) ?? defaultDir);
                File.WriteAllText(path, yaml ?? "");
                Flash("changelog saved: " + path);
            }
            catch (Exception ex)
            {
                Flash("save failed: " + ex.Message);
            }
        }

        /// <summary>Native "save as" picker: <c>EditorUtility.SaveFilePanel</c> in the editor, osascript in a macOS
        /// player, else a deterministic path under the default dir. Mirrors <see cref="BrowseForFolder"/>.</summary>
        private static string BrowseForSaveFile(string defaultDir, string defaultName)
        {
#if UNITY_EDITOR
            try { Directory.CreateDirectory(defaultDir); } catch { /* best effort */ }
            return UnityEditor.EditorUtility.SaveFilePanel("Save Liquibase changelog", defaultDir, defaultName, "yaml") ?? "";
#else
            if (Application.platform == RuntimePlatform.OSXPlayer)
            {
                try
                {
                    string script =
                        "POSIX path of (choose file name with prompt \"Save Liquibase changelog\" default name \"" +
                        defaultName.Replace("\"", "\\\"") + "\")";
                    var psi = new System.Diagnostics.ProcessStartInfo("osascript")
                    {
                        UseShellExecute = false, CreateNoWindow = true,
                        RedirectStandardOutput = true, RedirectStandardError = true,
                    };
                    psi.ArgumentList.Add("-e");
                    psi.ArgumentList.Add(script);
                    using var proc = System.Diagnostics.Process.Start(psi);
                    string outText = proc.StandardOutput.ReadToEnd();
                    proc.WaitForExit();
                    if (proc.ExitCode != 0) return "";
                    return (outText ?? "").Trim();
                }
                catch { return ""; }
            }
            return Path.Combine(defaultDir, defaultName);
#endif
        }

        private static string FirstKey(Dictionary<string, string> d)
        {
            foreach (var k in d.Keys) return k;
            return null;
        }
    }
}
