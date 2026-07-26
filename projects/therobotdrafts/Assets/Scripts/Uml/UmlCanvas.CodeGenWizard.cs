using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Text;
using UnityEngine;
using UnityEngine.UI;
using TheRobotDraft.Authoring.Model;
using TheRobotDraft.CodeGen;
using TheRobotDraft.Llm;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// A guided code-export flow layered over <see cref="UmlCanvas.CodeGen"/>: pick elements, choose a target language,
    /// choose an output root, skip specific output files, generate, then review/write the result in the shared viewer.
    /// The deterministic skeleton remains the offline seed; when an LLM endpoint is configured, the selected target
    /// language drives the refinement/conversion pass.
    /// </summary>
    public sealed partial class UmlCanvas
    {
        private sealed class CodeExportJob
        {
            public ElementId Id;
            public string ElementName;
            public string TargetLanguage;
            public string RelativePath;
            public string FullPath;
            public bool SkipWrite;
            public CodeGenContext Context;
            public string Code;
        }

        private static readonly List<string> CodeExportLanguages = new List<string>
        {
            "C#", "TypeScript", "JavaScript", "Java", "Python", "Elixir",
            "Go", "Rust", "C++", "C", "Ruby", "Kotlin", "Swift", "Custom…"
        };

        private static string DefaultCodeExportRoot => Path.Combine(Application.persistentDataPath, "code-export");

        /// <summary>Open the code-export wizard: source elements, target language, output root, and write skips.</summary>
        public void ShowCodeGenWizard(Vector2 screenPos)
        {
            CloseMenu();

            // Generatable = diagram-node classifiers (not notes/members). Pre-check the current selection, else all.
            var candidates = new List<ModelElement>();
            foreach (var el in _model.Elements)
                if (KindInfo.IsDiagramNode(el.Kind) && el.Kind != ElementKind.Note)
                    candidates.Add(el);
            if (candidates.Count == 0) { Flash("no elements to generate code for"); return; }

            var preselected = new HashSet<ElementId>();
            foreach (var sid in SelectedIds) preselected.Add(sid);
            bool defaultAll = preselected.Count == 0;

            float w = 760f, h = 640f;
            var panel = BeginModal(w, h, "Export code   —   pick files, target language, output path");
            var rows = new List<(ModelElement el, Func<bool> process, Func<bool> skip, Text pathText)>(candidates.Count);
            DropdownHandle langDd = null;
            InputField customLangInput = null;

            void RefreshPaths()
            {
                if (langDd == null || customLangInput == null || rows.Count == 0) return;
                string lang = ResolveWizardLanguage(langDd, customLangInput);
                foreach (var row in rows)
                {
                    string rel = RelativeTargetPathFor(row.el, lang);
                    row.pathText.text = Ellipsize($"{row.el.Name}   ›   {rel}", 76);
                }
            }

            float y = -46f;
            FormLabel(panel, "Target language   (type a custom language to add another output target)", ref y, w);
            langDd = MakeDropdown(panel, new Vector2(16f, y), 210f, CodeExportLanguages, "C#", _ => RefreshPaths());
            customLangInput = MakeInput(panel, new Vector2(236f, y), 210f, "", "custom language");
            customLangInput.onValueChanged.AddListener(_ => RefreshPaths());
            var skipExisting = MakeCheckbox(panel, new Vector2(466f, y + 5f), "skip existing files", true);
            y -= 44f;

            FormLabel(panel, "Output root", ref y, w);
            var rootInput = MakeInput(panel, new Vector2(16f, y), w - 132f, DefaultCodeExportRoot, "/path/to/output");
            MakeButton(panel, "Browse…", new Vector2(w - 104f, y), new Vector2(88f, 30f),
                new Color(0.22f, 0.24f, 0.29f, 1f), () =>
                {
                    string picked = BrowseForFolder();
                    if (!string.IsNullOrEmpty(picked)) rootInput.text = picked;
                });
            y -= 44f;

            MakeText(panel, $"{candidates.Count} element(s) — process checked rows; skip rows preview but do not write",
                new Vector2(16f, y),
                new Vector2(w - 32f, 18f), 13, LabelColor, TextAnchor.MiddleLeft);
            y -= 26f;

            // Scrollable checkbox list.
            const float pad = 16f, rowH = 30f;
            float listTop = y, listH = h + y - 68f, listW = w - pad * 2f;
            var viewportGo = new GameObject("WizViewport", typeof(RectTransform));
            var vpRt = (RectTransform)viewportGo.transform;
            vpRt.SetParent(panel, false);
            vpRt.anchorMin = vpRt.anchorMax = new Vector2(0f, 1f);
            vpRt.pivot = new Vector2(0f, 1f);
            vpRt.sizeDelta = new Vector2(listW, listH);
            vpRt.anchoredPosition = new Vector2(pad, listTop);
            TheRobotDraft.Uml.Chrome.MacOsControlKit.ApplyScrollWell(viewportGo.AddComponent<Image>());
            viewportGo.AddComponent<RectMask2D>();
            var scroll = viewportGo.AddComponent<ScrollRect>();
            scroll.horizontal = false; scroll.vertical = true; scroll.movementType = ScrollRect.MovementType.Clamped;
            scroll.scrollSensitivity = 28f;

            var contentGo = new GameObject("WizContent", typeof(RectTransform));
            var contentRt = (RectTransform)contentGo.transform;
            contentRt.SetParent(vpRt, false);
            contentRt.anchorMin = new Vector2(0f, 1f); contentRt.anchorMax = new Vector2(1f, 1f);
            contentRt.pivot = new Vector2(0.5f, 1f);
            contentRt.sizeDelta = new Vector2(0f, Mathf.Max(listH, candidates.Count * rowH + 8f));
            contentRt.anchoredPosition = Vector2.zero;
            scroll.viewport = vpRt; scroll.content = contentRt;

            float ry = -6f;
            foreach (var el in candidates)
            {
                bool initial = defaultAll || preselected.Contains(el.Id);
                var process = MakeCheckbox(contentRt, new Vector2(8f, ry), "process", initial);
                var skip = MakeCheckbox(contentRt, new Vector2(106f, ry), "skip", false);
                var label = MakeText(contentRt, "", new Vector2(184f, ry), new Vector2(listW - 198f, 22f), 13,
                    new Color(0.84f, 0.88f, 0.94f, 1f), TextAnchor.MiddleLeft);
                rows.Add((el, process, skip, label));
                ry -= rowH;
            }

            List<CodeExportJob> BuildJobs()
            {
                string lang = ResolveWizardLanguage(langDd, customLangInput);
                string root = string.IsNullOrWhiteSpace(rootInput.text) ? DefaultCodeExportRoot : rootInput.text.Trim();
                var jobs = new List<CodeExportJob>();
                foreach (var row in rows)
                {
                    if (!row.process()) continue;
                    string rel = RelativeTargetPathFor(row.el, lang);
                    jobs.Add(new CodeExportJob
                    {
                        Id = row.el.Id,
                        ElementName = string.IsNullOrWhiteSpace(row.el.Name) ? "Untitled" : row.el.Name.Trim(),
                        TargetLanguage = lang,
                        RelativePath = rel,
                        FullPath = Path.Combine(root, rel),
                        SkipWrite = row.skip(),
                    });
                }
                return jobs;
            }
            RefreshPaths();

            float yBtn = -(h - 46f);
            MakeButton(panel, "Generate preview", new Vector2(pad, yBtn), new Vector2(156f, 34f),
                new Color(0.18f, 0.46f, 0.30f, 1f), () =>
                {
                    var jobs = BuildJobs();
                    if (jobs.Count == 0) { Flash("check at least one element"); return; }
                    GenerateCodeForExportJobs(jobs, skipExisting());
                });
            MakeButton(panel, "Cancel", new Vector2(w - 104f, yBtn), new Vector2(88f, 34f),
                new Color(0.22f, 0.24f, 0.29f, 1f), CloseMenu);
        }

        /// <summary>
        /// Backward-compatible helper for callers that only supply ids. Uses each element's own language and writes
        /// under the default export root.
        /// </summary>
        private void GenerateCodeForIds(List<ElementId> ids)
        {
            if (ids == null || ids.Count == 0) { Flash("nothing selected"); return; }
            var jobs = new List<CodeExportJob>(ids.Count);
            foreach (var id in ids)
            {
                if (!_model.TryGet(id, out var el)) continue;
                string lang = string.IsNullOrWhiteSpace(el.Language) ? "C#" : el.Language.Trim();
                string rel = RelativeTargetPathFor(el, lang);
                jobs.Add(new CodeExportJob
                {
                    Id = id,
                    ElementName = string.IsNullOrWhiteSpace(el.Name) ? "Untitled" : el.Name.Trim(),
                    TargetLanguage = lang,
                    RelativePath = rel,
                    FullPath = Path.Combine(DefaultCodeExportRoot, rel),
                });
            }
            GenerateCodeForExportJobs(jobs, skipExisting: true);
        }

        private void GenerateCodeForExportJobs(List<CodeExportJob> jobs, bool skipExisting)
        {
            if (jobs == null || jobs.Count == 0) { Flash("nothing to export"); return; }

            var sb = new StringBuilder();
            foreach (var job in jobs)
            {
                if (!_model.TryGet(job.Id, out _)) continue;
                var ctx = BuildCodeContext(job.Id);
                ctx.Language = job.TargetLanguage;
                ctx.OriginalSource = null;
                ctx.OriginalSourcePath = null;
                job.Context = ctx;
                job.Code = CodeSkeleton.Generate(ctx);
                AppendExportSection(sb, job);
            }

            if (sb.Length == 0) { Flash("nothing to export"); return; }

            var setText = ShowCodeViewer($"Export code — {jobs.Count} file(s)", sb.ToString(),
                "review generated files, then write to output root", ElementId.None,
                onRegenerate: () => GenerateCodeForExportJobs(jobs, skipExisting),
                language: jobs.Count == 1 ? jobs[0].TargetLanguage : null,
                onSaveToFile: _ => WriteCodeExportFiles(jobs, skipExisting),
                onAudit: code => RunAudit(code, jobs.Count == 1 ? jobs[0].TargetLanguage : ""),
                saveToFileLabel: "Write files…");

            if (string.IsNullOrEmpty(LlmSettings.BaseUrl))
            {
                setText(sb.ToString(), "LLM not configured — showing skeletons");
                Flash("LLM not configured — showing skeletons");
                return;
            }
            StartCoroutine(RunLlmCodeExportBatch(jobs, setText));
        }

        private IEnumerator RunLlmCodeExportBatch(List<CodeExportJob> jobs, Action<string, string> setText)
        {
            var sb = new StringBuilder();
            int ok = 0;
            for (int i = 0; i < jobs.Count; i++)
            {
                var job = jobs[i];
                if (job.Context == null) continue;
                setText(sb.Length == 0 ? "generating…" : sb.ToString(),
                    $"generating {i + 1}/{jobs.Count}: {job.RelativePath}…");

                using (var req = LlmClient.BuildChatRequest(
                    SystemPromptFor(job.TargetLanguage),
                    job.Context.ToPromptString()))
                {
                    yield return req.SendWebRequest();
                    if (req.result == UnityEngine.Networking.UnityWebRequest.Result.Success
                        && LlmClient.TryParseContent(req.downloadHandler.text, out var content, out _))
                    {
                        job.Code = StripFences(content);
                        ok++;
                    }
                }
                AppendExportSection(sb, job);
                setText(sb.ToString(), $"generated {i + 1}/{jobs.Count}…");
            }

            setText(sb.ToString(), $"generated {ok}/{jobs.Count} with {LlmSettings.Model} — review and write files");
            Flash($"code export generated ({ok}/{jobs.Count})");
        }

        private void WriteCodeExportFiles(List<CodeExportJob> jobs, bool skipExisting)
        {
            int written = 0, skipped = 0, failed = 0;
            foreach (var job in jobs)
            {
                if (job.SkipWrite) { skipped++; continue; }
                if (skipExisting && File.Exists(job.FullPath)) { skipped++; continue; }
                try
                {
                    string dir = Path.GetDirectoryName(job.FullPath);
                    if (!string.IsNullOrEmpty(dir)) Directory.CreateDirectory(dir);
                    File.WriteAllText(job.FullPath, job.Code ?? "");
                    written++;
                }
                catch (Exception ex)
                {
                    failed++;
                    Debug.LogWarning("code export failed for " + job.FullPath + ": " + ex.Message);
                }
            }
            Flash($"code export: {written} written, {skipped} skipped, {failed} failed");
        }

        private static void AppendExportSection(StringBuilder sb, CodeExportJob job)
        {
            if (job == null) return;
            if (sb.Length > 0) sb.Append('\n');
            sb.Append("// ===== ").Append(job.RelativePath);
            if (job.SkipWrite) sb.Append("  [skip write]");
            sb.Append(" =====\n");
            sb.Append(job.Code ?? "");
            if (job.Code == null || !job.Code.EndsWith("\n")) sb.Append('\n');
        }

        // ------------------------------------------------------------------ on-request LLM audit

        /// <summary>Open a review pane and ask the configured LLM to audit the given code. Wired into every code viewer.</summary>
        private void RunAudit(string code, string language)
        {
            if (string.IsNullOrWhiteSpace(code)) { Flash("nothing to audit"); return; }
            var setText = ShowCodeViewer("Code audit   —   LLM review", "running audit…",
                "auditing…", ElementId.None, null, language: "markdown");

            if (string.IsNullOrEmpty(LlmSettings.BaseUrl))
            {
                setText("LLM not configured — set an endpoint via 'LLM settings…' on the canvas menu.", "not configured");
                return;
            }
            StartCoroutine(RunLlmAudit(code, language, setText));
        }

        private IEnumerator RunLlmAudit(string code, string language, Action<string, string> setText)
        {
            string lang = string.IsNullOrWhiteSpace(language) ? "the target language" : language.Trim();
            string sys =
                "You are a meticulous senior code reviewer. Review the provided " + lang + " code and report concrete, " +
                "actionable findings grouped under these Markdown headings: Correctness & bugs, Security, Performance, " +
                "Style & idiom, Suggestions. Cite the specific code in each finding. If a section has no issues, say so " +
                "briefly. Output Markdown only — no code fences around the whole report.";
            string user = "Review this code:\n\n" + code;

            using (var req = LlmClient.BuildChatRequest(sys, user))
            {
                req.timeout = 60;
                yield return req.SendWebRequest();

                if (req.result != UnityEngine.Networking.UnityWebRequest.Result.Success)
                { setText("Audit unavailable — " + req.error, "LLM error"); yield break; }
                if (!LlmClient.TryParseContent(req.downloadHandler.text, out var content, out var apiError))
                { setText("Audit failed — " + apiError, "LLM error"); yield break; }

                setText(content, "audit complete — reviewed by " + LlmSettings.Model);
            }
        }

        // ------------------------------------------------------------------ helpers

        private static string ResolveWizardLanguage(DropdownHandle dd, InputField customInput)
        {
            string custom = customInput == null ? null : customInput.text;
            if (!string.IsNullOrWhiteSpace(custom)) return custom.Trim();
            string selected = dd?.Get?.Invoke();
            if (string.IsNullOrWhiteSpace(selected) || selected.StartsWith("Custom", StringComparison.OrdinalIgnoreCase))
                return "C#";
            return selected.Trim();
        }

        /// <summary>Language-aware relative output path. Some targets need project layout conventions, not flat files.</summary>
        private static string RelativeTargetPathFor(ModelElement el, string language)
        {
            string name = string.IsNullOrWhiteSpace(el.Name) ? "Untitled" : el.Name.Trim();
            string lang = CanonicalLanguage(language);
            switch (lang)
            {
                case "java":
                    return Path.Combine("src", "main", "java", "generated", PascalName(name) + ".java");
                case "kotlin":
                    return Path.Combine("src", "main", "kotlin", "generated", PascalName(name) + ".kt");
                case "python":
                    return Path.Combine("src", SnakeName(name) + ".py");
                case "elixir":
                    return Path.Combine("lib", SnakeName(name) + ".ex");
                case "rust":
                    return Path.Combine("src", SnakeName(name) + ".rs");
                case "typescript":
                    return Path.Combine("src", PascalName(name) + ".ts");
                case "javascript":
                    return Path.Combine("src", PascalName(name) + ".js");
                case "swift":
                    return Path.Combine("Sources", PascalName(name) + ".swift");
                default:
                    return PascalName(name) + ExtFor(language);
            }
        }

        private static string ExtFor(string language)
        {
            switch ((language ?? "").Trim().ToLowerInvariant())
            {
                case "typescript": case "ts": case "node": case "node.js": return ".ts";
                case "javascript": case "js": return ".js";
                case "python": case "py": return ".py";
                case "java": return ".java";
                case "kotlin": case "kt": return ".kt";
                case "go": case "golang": return ".go";
                case "rust": case "rs": return ".rs";
                case "elixir": case "ex": return ".ex";
                case "ruby": case "rb": return ".rb";
                case "c++": case "cpp": return ".cpp";
                case "c": return ".c";
                case "swift": return ".swift";
                default: return ".cs";
            }
        }

        private static string CanonicalLanguage(string language)
        {
            string l = (language ?? "").Trim().ToLowerInvariant();
            if (l.Contains("typescript") || l == "ts" || l == "node" || l == "node.js") return "typescript";
            if (l.Contains("javascript") || l == "js") return "javascript";
            if (l.Contains("python") || l == "py") return "python";
            if (l.Contains("java") && !l.Contains("javascript")) return "java";
            if (l.Contains("kotlin") || l == "kt") return "kotlin";
            if (l.Contains("elixir") || l == "ex" || l == "exs") return "elixir";
            if (l.Contains("rust") || l == "rs") return "rust";
            if (l == "go" || l.Contains("golang")) return "go";
            if (l.Contains("swift")) return "swift";
            return l;
        }

        private static string PascalName(string raw)
        {
            var sb = new StringBuilder();
            bool upper = true;
            foreach (char c in raw ?? "")
            {
                if (char.IsLetterOrDigit(c))
                {
                    sb.Append(upper ? char.ToUpperInvariant(c) : c);
                    upper = false;
                }
                else upper = true;
            }
            return sb.Length == 0 ? "Generated" : sb.ToString();
        }

        private static string SnakeName(string raw)
        {
            var sb = new StringBuilder();
            foreach (char c in raw ?? "")
            {
                if (char.IsUpper(c))
                {
                    if (sb.Length > 0 && sb[sb.Length - 1] != '_') sb.Append('_');
                    sb.Append(char.ToLowerInvariant(c));
                }
                else if (char.IsLetterOrDigit(c)) sb.Append(char.ToLowerInvariant(c));
                else if (sb.Length > 0 && sb[sb.Length - 1] != '_') sb.Append('_');
            }
            string r = sb.ToString().Trim('_');
            return string.IsNullOrEmpty(r) ? "generated" : r;
        }
    }
}
