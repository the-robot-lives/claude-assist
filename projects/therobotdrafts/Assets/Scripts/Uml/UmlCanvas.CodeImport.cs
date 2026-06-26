using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEngine.Networking;
using UnityEngine.UI;
using TheRobotDraft.Authoring.Model;
using TheRobotDraft.Authoring.State;
using TheRobotDraft.CodeGen;
using TheRobotDraft.Llm;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// The "Import code" feature — the inverse of UmlCanvas.CodeGen: paste source, send it to the configured
    /// LLM endpoint (<see cref="LlmSettings"/>), and turn the structured reply (<see cref="CodeParser.ParsedModel"/>)
    /// into UML classifiers + members + relationships on the active package. Drives element creation through the
    /// same authoring verbs SeedSample / PasteElement use (<c>_ctl.EnterAddNode</c> → <c>CommitAddNode</c>,
    /// <c>SetMeta</c>, <c>EnterConnect</c>/<c>BeginConnect</c>/<c>CommitConnect</c>) so undo / persistence behave
    /// identically. Reuses the canvas's model + modal helpers from the other partials.
    /// </summary>
    public sealed partial class UmlCanvas
    {
        /// <summary>
        /// Original text of each imported source file, keyed by its path (the same path stored on each element's
        /// <see cref="ModelElement.SourceFile"/>). Backs the surgical overlay round-trip: regeneration of an element
        /// that has a stored source edits that file in place instead of synthesizing from scratch. Cleared in
        /// <c>NewWorld</c>, persisted in <see cref="DiagramDto.sourceFiles"/>.
        /// </summary>
        private readonly Dictionary<string, string> _sourceFiles = new();

        /// <summary>Source-file extensions the folder importer ingests (lower-case, leading dot).</summary>
        private static readonly HashSet<string> ImportExtensions = new()
        {
            ".cs", ".java", ".ts", ".tsx", ".js", ".py", ".go", ".rs", ".ex", ".exs", ".rb", ".cpp", ".h", ".hpp", ".c",
        };

        /// <summary>Cap on files ingested in one folder import — keeps a huge tree from stalling the coroutine.</summary>
        private const int ImportFileCap = 200;

        /// <summary>Synthetic <see cref="ModelElement.SourceFile"/> key for paste imports, so pasted text round-trips like a file.</summary>
        private const string PasteSourceKey = "<pasted>";

        // --- public entry point ---

        /// <summary>
        /// Open a modal to paste source code (with an optional language hint), then import it as UML elements.
        /// The parent wires this onto a canvas menu item.
        /// </summary>
        public void ShowImportCodeDialog(Vector2 screenPos)
        {
            CloseMenu();

            float w = 620f, h = 560f;
            var panel = BeginModal(w, h, "Import code   —   paste source or migrate a folder, build UML via LLM");

            float y = -50f;
            FormLabel(panel, "Source code   (paste one or more types — any language)", ref y, w);
            float codeH = 260f;
            var codeInput = MakeMultilineInput(panel, new Vector2(16f, y), w - 32f, codeH, "",
                "// paste classes / interfaces / enums here…");
            y -= codeH + 12f;

            FormLabel(panel, "Language hint   (optional — e.g. C#, TypeScript, Python)", ref y, w);
            var langInput = MakeInput(panel, new Vector2(16f, y), w - 32f, "", "auto-detect");
            y -= 50f;

            // Folder import: a path text field plus a native macOS picker (the manual field is the cross-platform fallback).
            FormLabel(panel, "Folder path   (recursively import every source file under this directory)", ref y, w);
            var folderInput = MakeInput(panel, new Vector2(16f, y), w - 240f, "", "/path/to/src");

            // A native "Browse…" picker. In the editor we use EditorUtility; in a macOS player we shell out to
            // osascript (same pattern as UmlImageClipboard). On other standalone platforms the manual field stands in.
            bool canBrowse =
#if UNITY_EDITOR
                true;
#else
                Application.platform == RuntimePlatform.OSXPlayer;
#endif
            if (canBrowse)
            {
                MakeButton(panel, "Browse…", new Vector2(w - 218f, y), new Vector2(80f, 30f),
                    new Color(0.22f, 0.24f, 0.29f, 1f), () =>
                    {
                        string picked = BrowseForFolder();
                        if (!string.IsNullOrEmpty(picked)) folderInput.text = picked;
                    });
            }

            MakeButton(panel, "Import folder", new Vector2(w - 132f, y), new Vector2(116f, 30f),
                new Color(0.20f, 0.42f, 0.52f, 1f), () =>
                {
                    string folder = folderInput.text;
                    string langHint = langInput.text;
                    CloseMenu();
                    ImportFolder(folder, langHint);
                });

            void Submit()
            {
                string code = codeInput.text;
                string langHint = langInput.text;
                CloseMenu();
                ImportCode(code, langHint);
            }

            float yBtn = -(h - 46f);
            MakeButton(panel, "Import paste", new Vector2(w - 214f, yBtn), new Vector2(106f, 34f),
                new Color(0.20f, 0.42f, 0.52f, 1f), Submit);
            MakeButton(panel, "Cancel", new Vector2(w - 104f, yBtn), new Vector2(88f, 34f),
                new Color(0.22f, 0.24f, 0.29f, 1f), CloseMenu);

            FocusInput(codeInput);
        }

        /// <summary>
        /// Open a native folder chooser and return the selected POSIX path (or "" on cancel / unsupported platform). In
        /// the editor this uses <c>EditorUtility.OpenFolderPanel</c>; in a macOS player it shells out to <c>osascript</c>
        /// (mirroring <see cref="UmlImageClipboard"/>'s Process usage). A user cancel makes osascript exit non-zero with
        /// no stdout, which we read as "" and ignore.
        /// </summary>
        private static string BrowseForFolder()
        {
#if UNITY_EDITOR
            return UnityEditor.EditorUtility.OpenFolderPanel("Select source folder", "", "") ?? "";
#else
            if (Application.platform != RuntimePlatform.OSXPlayer) return "";
            try
            {
                // `choose folder` returns an alias; coerce it to a POSIX path so it drops straight into the path field.
                const string script = "POSIX path of (choose folder with prompt \"Select source folder\")";
                var psi = new System.Diagnostics.ProcessStartInfo("osascript")
                {
                    UseShellExecute = false,
                    CreateNoWindow = true,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                };
                psi.ArgumentList.Add("-e");
                psi.ArgumentList.Add(script);
                using (var proc = System.Diagnostics.Process.Start(psi))
                {
                    string outText = proc.StandardOutput.ReadToEnd();
                    proc.WaitForExit();
                    if (proc.ExitCode != 0) return ""; // user cancelled (osascript -128) or error
                    return (outText ?? "").Trim();
                }
            }
            catch (System.Exception ex)
            {
                Debug.LogWarning("folder picker failed: " + ex.Message);
                return "";
            }
#endif
        }

        // --- import driver ---

        /// <summary>
        /// Validate input, ensure there is a package to drop classifiers into, then kick off the async LLM
        /// request. The canvas is left untouched until the reply parses successfully.
        /// </summary>
        private void ImportCode(string code, string langHint)
        {
            if (string.IsNullOrWhiteSpace(code)) { Flash("paste some code to import"); return; }

            if (!ImportEnsurePackage()) { Flash("couldn't create a package to import into"); return; }

            // Deterministic first: a network-free structural parse handles the common case (C# / TS / Java) instantly.
            if (CodeStructParser.TryParse(code, langHint, out var model))
            {
                _sourceFiles[PasteSourceKey] = code; // pasted text round-trips like an imported file
                IngestParsed(model, PasteSourceKey);
                return;
            }

            // Deterministic parse found nothing — fall back to the LLM if one is configured, else explain why.
            if (string.IsNullOrEmpty(LlmSettings.BaseUrl))
            {
                Flash("couldn't parse the pasted code (unsupported language?) and no LLM configured — set one in LLM settings…");
                return;
            }

            Flash("importing code via LLM…");
            StartCoroutine(RunImport(code, langHint));
        }

        /// <summary>Make sure <c>_activePackage</c> is valid — create an "Imported" package if none exists (cf. SeedSample).</summary>
        private bool ImportEnsurePackage()
        {
            EnsureActivePackage();
            if (_activePackage.IsValid) return true;

            _ctl.EnterAddNode(ElementKind.Package);
            var pkg = _ctl.CommitAddNode(ElementId.None, "Imported");
            _ctl.EnterSelect();
            if (!pkg.IsValid) return false;
            _activePackage = pkg;
            return true;
        }

        private IEnumerator RunImport(string code, string langHint)
        {
            string userPrompt = CodeParser.BuildUserPrompt(code, langHint);
            using (var req = LlmClient.BuildChatRequest(CodeParser.SystemPrompt, userPrompt))
            {
                req.timeout = 60; // don't hang the import on a slow/unreachable endpoint
                yield return req.SendWebRequest();

                if (req.result != UnityWebRequest.Result.Success)
                {
                    ShowLlmErrorToast("Code import couldn't reach the LLM:  " + req.error);
                    yield break;
                }

                if (!LlmClient.TryParseContent(req.downloadHandler.text, out var content, out var apiError))
                {
                    Flash("import failed: " + apiError);
                    yield break;
                }

                if (!CodeParser.TryParse(content, out var model, out var parseError))
                {
                    Flash("import failed: " + parseError);
                    yield break;
                }

                _sourceFiles[PasteSourceKey] = code; // keep the original for surgical overlay regeneration
                IngestParsed(model, PasteSourceKey);
            }
        }

        // --- folder import ---

        /// <summary>
        /// Migrate a whole source tree: validate the path, then ingest every code file under it (recursively) via
        /// the same LLM parse path as paste import, tagging each created element with its file's <c>SourceFile</c>
        /// and stashing the file's original text in <see cref="_sourceFiles"/> for the overlay round-trip.
        /// </summary>
        private void ImportFolder(string folder, string langHint)
        {
            if (string.IsNullOrWhiteSpace(folder)) { Flash("enter a folder path to import"); return; }
            folder = folder.Trim();
            if (!Directory.Exists(folder)) { Flash("folder not found: " + folder); return; }

            if (!ImportEnsurePackage()) { Flash("couldn't create a package to import into"); return; }

            // No LLM gate here anymore: the deterministic parser runs offline. Files it can't handle fall back to the
            // LLM per-file when one is configured (RunImportFolder), so an unconfigured endpoint is no longer fatal.

            List<string> files;
            bool truncated; int skippedBig;
            try { files = EnumerateSourceFiles(folder, out truncated, out skippedBig); }
            catch (System.Exception ex) { Flash("couldn't read folder: " + ex.Message); return; }

            if (files.Count == 0) { Flash("no source files found under " + folder); return; }
            if (truncated) Flash($"importing first {ImportFileCap} of many files…");

            StartCoroutine(RunImportFolder(files, langHint));
        }

        /// <summary>Directories never descended into — dependency, build, and tooling trees that aren't your source.</summary>
        private static readonly HashSet<string> SkipDirs = new(System.StringComparer.OrdinalIgnoreCase)
        {
            // JS / web
            "node_modules", "bower_components", "dist", "build", "out", ".next", ".nuxt", ".svelte-kit",
            ".angular", "elm-stuff",
            // .NET / Java / JVM
            "bin", "obj", "packages", "target", ".gradle", "gradle",
            // Elixir / Erlang
            "deps", "_build", ".elixir_ls", ".rebar3", "_checkouts",
            // Rust
            ".cargo",                                   // ("target" already covered above)
            // Python
            "__pycache__", ".venv", "venv", "env", ".tox", ".eggs", "site-packages",
            ".mypy_cache", ".pytest_cache", ".ruff_cache",
            // Ruby / PHP / Go
            ".bundle", "vendor",
            // Dart/Flutter, Haskell, Terraform, misc tooling
            ".dart_tool", ".stack-work", "dist-newstyle", ".terraform", "_opam",
            // Apple / IDE / VCS / engine caches
            "Pods", "DerivedData", ".git", ".svn", ".hg", ".idea", ".vs", ".vscode",
            "Library", "Temp", "Logs", "coverage", ".cache",
        };

        /// <summary>Skip files larger than this — bundles / minified / generated blobs that aren't hand-written source
        /// (and that can choke the regex parser or stall the LLM).</summary>
        private const long ImportMaxFileBytes = 256 * 1024;

        /// <summary>
        /// Recursively collect hand-written code files under <paramref name="root"/>, capped at
        /// <see cref="ImportFileCap"/>. Skips dependency/build dirs (<see cref="SkipDirs"/>), hidden dirs, oversized
        /// files, and obvious minified/generated blobs. <paramref name="skippedBig"/> counts the size/minified skips.
        /// </summary>
        private static List<string> EnumerateSourceFiles(string root, out bool truncated, out int skippedBig)
        {
            var files = new List<string>();
            truncated = false; skippedBig = 0;
            var stack = new Stack<string>();
            stack.Push(root);
            while (stack.Count > 0)
            {
                string dir = stack.Pop();
                try
                {
                    foreach (var sub in Directory.EnumerateDirectories(dir))
                    {
                        string name = Path.GetFileName(sub);
                        if (SkipDirs.Contains(name) || name.StartsWith(".")) continue; // deps/build/hidden
                        stack.Push(sub);
                    }
                }
                catch { /* unreadable dir — skip */ }

                IEnumerable<string> entries;
                try { entries = Directory.EnumerateFiles(dir); }
                catch { continue; }
                foreach (var path in entries)
                {
                    if (!ImportExtensions.Contains(Path.GetExtension(path).ToLowerInvariant())) continue;
                    string fn = Path.GetFileName(path).ToLowerInvariant();
                    if (fn.Contains(".min.") || fn.EndsWith(".bundle.js") || fn.Contains(".generated.")
                        || fn.EndsWith(".g.cs") || fn.EndsWith(".d.ts")) { skippedBig++; continue; }
                    long len; try { len = new FileInfo(path).Length; } catch { continue; }
                    if (len > ImportMaxFileBytes) { skippedBig++; continue; }
                    files.Add(path);
                    if (files.Count >= ImportFileCap) { truncated = true; return files; }
                }
            }
            return files;
        }

        /// <summary>True if the text looks machine-generated/minified (an extremely long line) — skip it so the
        /// regex parser can't catastrophically backtrack and the importer can't stall on a single file.</summary>
        private static bool LooksMinified(string text)
        {
            if (string.IsNullOrEmpty(text)) return false;
            int lineLen = 0;
            foreach (char c in text)
            {
                if (c == '\n') lineLen = 0;
                else if (++lineLen > 5000) return true;
            }
            return false;
        }

        /// <summary>
        /// Sequentially parse each file via the LLM and materialize its types, sharing one name→id map across the
        /// whole batch so cross-file relationships resolve. A second pass adds edges once every type exists.
        /// </summary>
        private IEnumerator RunImportFolder(List<string> files, string langHint)
        {
            var created = new Dictionary<string, ElementId>();
            var models = new List<CodeParser.ParsedModel>(files.Count);
            int typeCount = 0, parsedFiles = 0, gridIndex = 0;
            bool llmConfigured = !string.IsNullOrEmpty(LlmSettings.BaseUrl);
            string firstFailure = null; // surfaced when nothing parsed at all

            for (int i = 0; i < files.Count; i++)
            {
                string path = files[i];
                Flash($"importing {i + 1}/{files.Count}: {Path.GetFileName(path)}…");

                string text;
                try { text = File.ReadAllText(path); }
                catch (System.Exception ex)
                {
                    firstFailure ??= Path.GetFileName(path) + ": unreadable — " + ex.Message;
                    continue; // unreadable file — skip, keep going
                }

                // Skip minified/generated blobs (extremely long lines) so neither the regex parser nor the LLM
                // can stall the whole import on one file (e.g. a bundled frontend index.js).
                if (LooksMinified(text))
                {
                    firstFailure ??= Path.GetFileName(path) + ": looks minified/generated — skipped";
                    if ((i % 10) == 9) yield return null;
                    continue;
                }

                // Deterministic first: structural parse runs offline and is fast, so we batch many files per frame.
                string langForFile = string.IsNullOrWhiteSpace(langHint) ? Path.GetExtension(path) : langHint;
                if (CodeStructParser.TryParse(text, langForFile, out var detModel))
                {
                    _sourceFiles[path] = text; // keep the original for surgical overlay regeneration
                    typeCount += MaterializeTypes(detModel, created, ref gridIndex, path);
                    models.Add(detModel);
                    parsedFiles++;
                    if ((i % 10) == 9) yield return null; // let the progress hint repaint periodically
                    continue;
                }

                // Deterministic parse found nothing — fall back to the LLM per-file, but only if one is configured.
                if (!llmConfigured)
                {
                    firstFailure ??= Path.GetFileName(path) + ": no types parsed and no LLM configured";
                    continue;
                }

                string userPrompt = CodeParser.BuildUserPrompt(text, langHint);
                using (var req = LlmClient.BuildChatRequest(CodeParser.SystemPrompt, userPrompt))
                {
                    req.timeout = 60; // don't stall the whole folder import on one slow/unreachable request
                    yield return req.SendWebRequest();
                    if (req.result != UnityWebRequest.Result.Success)
                    {
                        firstFailure ??= "LLM unreachable: " + req.error;
                        continue;
                    }
                    if (!LlmClient.TryParseContent(req.downloadHandler.text, out var content, out var apiErr))
                    {
                        firstFailure ??= "LLM error: " + apiErr;
                        continue;
                    }
                    if (!CodeParser.TryParse(content, out var model, out var parseErr))
                    {
                        firstFailure ??= Path.GetFileName(path) + ": " + parseErr;
                        continue;
                    }

                    _sourceFiles[path] = text; // keep the original for surgical overlay regeneration
                    typeCount += MaterializeTypes(model, created, ref gridIndex, path);
                    models.Add(model);
                    parsedFiles++;
                }
            }

            // Pass 2: resolve relationships by type name across the whole batch.
            int edgeCount = 0, skipped = 0;
            foreach (var model in models)
                edgeCount += LinkTypes(model, created, ref skipped);

            _ctl.EnterSelect();
            SetSelected(ElementId.None);
            // Organize the freshly imported set by source file instead of leaving it on the per-file seed grid (a
            // cramped tall strip); AutoLayout rebuilds + frames the scene. Its flash is overwritten by the note below.
            AutoLayout("source");

            if (parsedFiles == 0)
            {
                string reason = firstFailure ?? (llmConfigured
                    ? "deterministic parse found none and the LLM returned nothing"
                    : "deterministic parse found none and no LLM is configured");
                Flash($"imported 0 types from 0/{files.Count} files — {reason}");
                yield break;
            }

            WriteShadowsForImport(); // editable on-disk copies for the "Edit code in VS Code" round-trip
            string note = $"imported {typeCount} types from {parsedFiles}/{files.Count} files, {edgeCount} relationships";
            if (skipped > 0) note += $" ({skipped} external ref{(skipped == 1 ? "" : "s")} skipped)";
            Flash(note);
        }

        // --- model materialization ---

        /// <summary>
        /// Create one classifier per parsed type (with its members), lay them out on a grid near the canvas
        /// center, then add extends/implements/uses edges between types that resolved within this import.
        /// </summary>
        private void IngestParsed(CodeParser.ParsedModel model, string sourceFile = null)
        {
            if (model == null || model.types == null || model.types.Length == 0)
            { Flash("nothing to import"); return; }

            // name → created element id, so relationships can resolve targets created in this same import.
            var created = new Dictionary<string, ElementId>();
            int gridIndex = 0;
            int typeCount = MaterializeTypes(model, created, ref gridIndex, sourceFile);

            int skipped = 0;
            int edgeCount = LinkTypes(model, created, ref skipped);

            _ctl.EnterSelect();
            SetSelected(ElementId.None);
            // Lay the imported types out by source so they arrive organized instead of stacked on a small grid;
            // AutoLayout rebuilds + frames the scene. Its flash is overwritten by the import note below.
            AutoLayout("source");

            WriteShadowsForImport(); // editable on-disk copies for the "Edit code in VS Code" round-trip
            string note = $"imported {typeCount} types, {edgeCount} relationships";
            if (skipped > 0) note += $" ({skipped} external ref{(skipped == 1 ? "" : "s")} skipped)";
            Flash(note);
        }

        /// <summary>
        /// Create a classifier (with members + comments) for each parsed type, laying them out on a grid that
        /// continues from <paramref name="gridIndex"/> (so a folder import groups each file's types and doesn't
        /// stack files on top of one another). Records each in <paramref name="created"/> and, when
        /// <paramref name="sourceFile"/> is set, tags the element with it. Returns the number of types created.
        /// </summary>
        private int MaterializeTypes(CodeParser.ParsedModel model, Dictionary<string, ElementId> created,
            ref int gridIndex, string sourceFile)
        {
            if (model?.types == null) return 0;

            // Grid layout: a small spread around the canvas center so imported boxes don't stack on the origin.
            const float colW = 240f, rowH = 200f, originX = -360f, originY = 160f;
            int made = 0;

            foreach (var pt in model.types)
            {
                if (pt == null || string.IsNullOrWhiteSpace(pt.name)) continue;

                var kind = ImportKind(pt.kind);
                _ctl.EnterAddNode(kind);
                var id = _ctl.CommitAddNode(_activePackage, ImportUniqueName(pt.name.Trim()));
                if (!id.IsValid) { _ctl.EnterSelect(); continue; }

                if (!string.IsNullOrWhiteSpace(pt.language))
                    _ctl.SetMeta(id, pt.language.Trim(), null);
                if (!string.IsNullOrWhiteSpace(pt.comment))
                    _ctl.SetCodeDoc(id, pt.comment.Trim()); // class doc-comment -> element CodeDoc
                if (!string.IsNullOrEmpty(sourceFile))
                    _ctl.SetSourceFile(id, sourceFile);

                ImportAddMembers(id, ElementKind.Field, pt.fields, pt.fieldComments);
                ImportAddMembers(id, ElementKind.Function, pt.methods, pt.methodComments);

                _ctl.EnterSelect();

                _pos[id] = new Vector2(
                    originX + (gridIndex % 4) * colW,
                    originY - (gridIndex / 4) * rowH);
                _ctl.SetZLayer(id, _activeLayer); // import onto the active layer

                // First writer wins on a name collision (we deduped the box name, but key on the original).
                if (!created.ContainsKey(pt.name.Trim())) created[pt.name.Trim()] = id;
                gridIndex++;
                made++;
            }
            return made;
        }

        /// <summary>
        /// Add extends/implements/uses edges for one parsed model, resolving targets against <paramref name="created"/>
        /// (which may span multiple files in a folder import). Returns the number of edges created.
        /// </summary>
        private int LinkTypes(CodeParser.ParsedModel model, Dictionary<string, ElementId> created, ref int skipped)
        {
            if (model?.types == null) return 0;
            int edgeCount = 0;
            foreach (var pt in model.types)
            {
                if (pt == null || string.IsNullOrWhiteSpace(pt.name)) continue;
                if (!created.TryGetValue(pt.name.Trim(), out var fromId)) continue;

                edgeCount += ImportConnect(fromId, pt.extends, EdgeKind.Generalization, created, ref skipped);
                edgeCount += ImportConnect(fromId, pt.implements, EdgeKind.Realization, created, ref skipped);
                // A class/module that references another "consumes" it — directed consumer → consumed.
                edgeCount += ImportConnect(fromId, pt.uses, EdgeKind.Consumes, created, ref skipped);
            }
            return edgeCount;
        }

        /// <summary>
        /// Add each signature string as a member child of <paramref name="owner"/> (UML signature verbatim), setting
        /// the member's CodeDoc from the index-aligned <paramref name="comments"/> doc-comment when present.
        /// </summary>
        private void ImportAddMembers(ElementId owner, ElementKind memberKind, string[] signatures, string[] comments)
        {
            if (signatures == null) return;
            for (int i = 0; i < signatures.Length; i++)
            {
                string sig = signatures[i];
                if (string.IsNullOrWhiteSpace(sig)) continue;
                _ctl.EnterAddNode(memberKind);
                var mid = _ctl.CommitAddNode(owner, sig.Trim());
                if (!mid.IsValid) continue;
                string comment = comments != null && i < comments.Length ? comments[i] : null;
                if (!string.IsNullOrWhiteSpace(comment))
                    _ctl.SetCodeDoc(mid, comment.Trim());
            }
        }

        /// <summary>
        /// Connect <paramref name="fromId"/> to each named target with <paramref name="edgeKind"/>, but only when
        /// the name resolves to a type created in this import. Counts unresolved (external) names into
        /// <paramref name="skipped"/>. Returns the number of edges actually created.
        /// </summary>
        private int ImportConnect(ElementId fromId, string[] targetNames, EdgeKind edgeKind,
            Dictionary<string, ElementId> created, ref int skipped)
        {
            if (targetNames == null) return 0;
            int made = 0;
            foreach (var raw in targetNames)
            {
                if (string.IsNullOrWhiteSpace(raw)) continue;
                string name = raw.Trim();
                if (!created.TryGetValue(name, out var toId) || toId == fromId) { skipped++; continue; }

                _ctl.EnterConnect(CommitStyle.OneShot, edgeKind);
                _ctl.BeginConnect(fromId);
                var edge = _ctl.CommitConnect(toId);
                if (edge.IsValid) made++;
            }
            return made;
        }

        /// <summary>Map the model's free-text kind string onto an <see cref="ElementKind"/> classifier (default Class).</summary>
        private static ElementKind ImportKind(string kind)
        {
            if (string.IsNullOrWhiteSpace(kind)) return ElementKind.Class;
            switch (kind.Trim().ToLowerInvariant())
            {
                case "interface": return ElementKind.Interface;
                case "enum":
                case "enumeration": return ElementKind.Enum;
                case "struct":
                case "structure": return ElementKind.Struct;
                default: return ElementKind.Class;
            }
        }

        /// <summary>Dedupe a classifier name against the active package so two imported types can't clash (cf. UniqueName).</summary>
        private string ImportUniqueName(string baseName)
        {
            if (!NameExistsInActive(baseName)) return baseName;
            int n = 2;
            string candidate;
            do { candidate = baseName + n++; } while (NameExistsInActive(candidate));
            return candidate;
        }
    }
}
