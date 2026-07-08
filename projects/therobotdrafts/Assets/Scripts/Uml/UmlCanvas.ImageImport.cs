using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEngine.Networking;
using UnityEngine.UI;
using TheRobotDraft.Authoring.Interchange;
using TheRobotDraft.Authoring.Model;
using TheRobotDraft.Llm;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// "Import diagram from image" — point a vision-enabled LLM (configured separately in
    /// <see cref="VisionLlmSettings"/>) at a whiteboard photo / screenshot / sketch, let it classify the diagram
    /// family and transcribe it into PlantUML (a notation every model knows, unlike our own schema), parse that
    /// with <see cref="PlantUmlReader"/>, and stage everything in a review modal — a table of nodes (include ·
    /// kind · name · members · notes) and links (include · kind · label), the editable PlantUML intermediate with
    /// re-parse, and an LLM revision loop ("the middle box is a database, not a class" → re-extract → re-review) —
    /// before committing through <see cref="CommitIxReview"/>. Image sources: file browse, clipboard paste, or a
    /// node's attached picture.
    /// </summary>
    public sealed partial class UmlCanvas
    {
        /// <summary>Set by the analysis modal's Cancel; the vision coroutine aborts its request and stops.</summary>
        private bool _imageImportCancel;

        // ------------------------------------------------------------------ entry dialog

        /// <summary>Open the import dialog with no preloaded image (canvas Generate menu).</summary>
        public void ShowImageImportDialog(Vector2 screenPos) => ShowImageImportDialogCore(screenPos, null);

        /// <summary>Open the import dialog preloaded with the picture already attached to a node.</summary>
        public void ShowImageImportDialogForNode(ElementId nodeId, Vector2 screenPos)
        {
            byte[] png = ReadNodeImageBytes(nodeId);
            if (png == null) { Flash("that node has no readable image"); return; }
            ShowImageImportDialogCore(screenPos, png);
        }

        private void ShowImageImportDialogCore(Vector2 screenPos, byte[] preloaded)
        {
            CloseMenu();
            float w = 640f, h = 470f;
            var panel = BeginModal(w, h, "Import diagram from image   —   vision LLM → PlantUML → review");

            byte[] pending = null;
            var status = MakeText(panel, "", new Vector2(16f, -(h - 92f)), new Vector2(w - 32f, 18f), 13,
                LabelColor, TextAnchor.MiddleLeft);
            Text imageInfo = null;

            float y = -50f;
            FormLabel(panel, "Image   (browse a file, paste from the clipboard, or right-click a node's picture)", ref y, w);
            var pathInput = MakeInput(panel, new Vector2(16f, y), w - 300f, "", "/path/to/diagram.png");
            MakeButton(panel, "Browse…", new Vector2(w - 276f, y), new Vector2(84f, 30f),
                new Color(0.22f, 0.24f, 0.29f, 1f), () =>
                {
                    string picked = BrowseForImageFile();
                    if (!string.IsNullOrEmpty(picked)) pathInput.text = picked;
                });
            MakeButton(panel, "Load", new Vector2(w - 186f, y), new Vector2(60f, 30f),
                new Color(0.20f, 0.42f, 0.52f, 1f), () =>
                {
                    var png = LoadImageFileAsPng(pathInput.text, out var info, out var err);
                    if (png == null) { status.text = "✗ " + err; return; }
                    pending = png; imageInfo.text = info; status.text = "";
                });
            MakeButton(panel, "📋 Paste", new Vector2(w - 118f, y), new Vector2(102f, 30f),
                new Color(0.20f, 0.42f, 0.52f, 1f), () =>
                {
                    var png = UmlImageClipboard.TryReadClipboardPng();
                    if (png == null) { status.text = "✗ no image on the clipboard"; return; }
                    pending = NormalizePng(png, out var info);
                    imageInfo.text = info;
                    status.text = "";
                });
            y -= 38f;

            imageInfo = MakeText(panel, "", new Vector2(16f, y), new Vector2(w - 32f, 18f), 13,
                new Color(0.70f, 0.78f, 0.66f, 1f), TextAnchor.MiddleLeft);
            y -= 26f;

            FormLabel(panel, "Processing instructions   (optional — e.g. 'the dashed boxes are external services; ignore the legend')", ref y, w);
            var promptInput = MakeMultilineInput(panel, new Vector2(16f, y), w - 32f, 96f, "",
                "extra guidance for the vision model…");
            y -= 96f + 14f;

            // Vision endpoint summary + settings shortcut.
            string endpoint = VisionLlmSettings.IsConfigured
                ? $"{VisionLlmSettings.Model}   @   {VisionLlmSettings.BaseUrl}" +
                  (VisionLlmSettings.HasDedicatedSettings ? "" : "   (falling back to the main LLM settings)")
                : "not configured";
            MakeText(panel, "Vision LLM:   " + Ellipsize(endpoint, 64), new Vector2(16f, y), new Vector2(w - 200f, 18f), 13,
                LabelColor, TextAnchor.MiddleLeft);
            MakeButton(panel, "Vision LLM settings…", new Vector2(w - 186f, y + 6f), new Vector2(170f, 30f),
                new Color(0.22f, 0.24f, 0.29f, 1f), () => ShowVisionLlmSettings(screenPos));

            if (preloaded != null)
            {
                pending = NormalizePng(preloaded, out var info);
                imageInfo.text = info + "   (from node image)";
            }

            float yBtn = -(h - 46f);
            MakeButton(panel, "Analyze image", new Vector2(w - 260f, yBtn), new Vector2(146f, 34f),
                new Color(0.18f, 0.46f, 0.30f, 1f), () =>
                {
                    // Late-load from the path field if the user typed a path but never pressed Load.
                    if (pending == null && !string.IsNullOrWhiteSpace(pathInput.text))
                    {
                        pending = LoadImageFileAsPng(pathInput.text, out _, out var err);
                        if (pending == null) { status.text = "✗ " + err; return; }
                    }
                    if (pending == null) { status.text = "✗ load or paste an image first"; return; }
                    if (!VisionLlmSettings.IsConfigured)
                    { status.text = "✗ no vision endpoint — open Vision LLM settings…"; return; }
                    string instructions = promptInput.text;
                    StartImageAnalysis(pending, instructions, null);
                });
            MakeButton(panel, "Cancel", new Vector2(w - 104f, yBtn), new Vector2(88f, 34f),
                new Color(0.22f, 0.24f, 0.29f, 1f), CloseMenu);

            FocusInput(pathInput);
        }

        // ------------------------------------------------------------------ image loading helpers

        /// <summary>Bytes of the picture attached to a node (via the Images partial), or null.</summary>
        private byte[] ReadNodeImageBytes(ElementId id)
        {
            if (!_nodeImage.TryGetValue(id, out var file) || string.IsNullOrEmpty(file)) return null;
            try
            {
                string path = Path.Combine(ImageDir, file);
                return File.Exists(path) ? File.ReadAllBytes(path) : null;
            }
            catch (Exception ex) { Debug.LogWarning("node image read failed: " + ex.Message); return null; }
        }

        /// <summary>Load any Unity-decodable image file (png/jpg) and normalize it to PNG bytes.</summary>
        private static byte[] LoadImageFileAsPng(string path, out string info, out string error)
        {
            info = null; error = null;
            if (string.IsNullOrWhiteSpace(path)) { error = "enter an image path"; return null; }
            path = path.Trim();
            if (!File.Exists(path)) { error = "file not found: " + path; return null; }
            byte[] raw;
            try { raw = File.ReadAllBytes(path); }
            catch (Exception ex) { error = "unreadable: " + ex.Message; return null; }
            var png = NormalizePng(raw, out info);
            if (png == null) { error = "not a decodable image (png/jpg expected)"; return null; }
            info = Path.GetFileName(path) + "   " + info;
            return png;
        }

        /// <summary>Decode arbitrary image bytes and re-encode as PNG (also yields a "W×H, N KB" info line).</summary>
        private static byte[] NormalizePng(byte[] bytes, out string info)
        {
            info = null;
            if (bytes == null || bytes.Length == 0) return null;
            Texture2D tex = null;
            try
            {
                tex = new Texture2D(2, 2, TextureFormat.RGBA32, false);
                if (!tex.LoadImage(bytes)) return null;
                var png = tex.EncodeToPNG();
                if (png == null || png.Length == 0) return null;
                info = $"{tex.width}×{tex.height}px, {png.Length / 1024} KB";
                return png;
            }
            catch { return null; }
            finally { if (tex != null) UnityEngine.Object.Destroy(tex); }
        }

        /// <summary>Native image-file chooser (editor panel / macOS osascript), mirroring <c>BrowseForFolder</c>.</summary>
        private static string BrowseForImageFile()
        {
#if UNITY_EDITOR
            return UnityEditor.EditorUtility.OpenFilePanel("Select diagram image", "", "png,jpg,jpeg") ?? "";
#else
            if (Application.platform != RuntimePlatform.OSXPlayer) return "";
            try
            {
                const string script = "POSIX path of (choose file with prompt \"Select diagram image\" of type {\"public.image\"})";
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
                    if (proc.ExitCode != 0) return "";
                    return (outText ?? "").Trim();
                }
            }
            catch (Exception ex)
            {
                Debug.LogWarning("image picker failed: " + ex.Message);
                return "";
            }
#endif
        }

        // ------------------------------------------------------------------ vision analysis

        /// <summary>The extraction contract: classify the diagram family and transcribe to the constrained
        /// PlantUML profile <see cref="PlantUmlReader"/> parses. PlantUML is the intermediate because vision
        /// models know it natively — our own schema is mapped afterwards, under user review.</summary>
        private const string VisionSystemPrompt =
            "You are a diagram-extraction engine inside a UML modeling tool. You receive ONE image of a diagram " +
            "(whiteboard photo, screenshot, sketch, or tool export).\n" +
            "1. Identify the diagram family: class, ERD, use case, state machine, activity/flowchart, sequence, " +
            "component/deployment, or mind map.\n" +
            "2. Extract every node, its exact text, and every connection, as faithfully as the image allows.\n" +
            "3. Output ONLY PlantUML for that family — no commentary, no markdown fences.\n" +
            "Rules:\n" +
            "- Wrap in @startuml … @enduml (@startmindmap … @endmindmap for a mind map).\n" +
            "- Declare every element explicitly with a short alias: class \"Display Name\" as C1, " +
            "usecase \"…\" as U1, state \"…\" as S1, participant \"…\" as P1, component \"…\" as X1, " +
            "actor \"…\" as A1, entity \"…\" as E1, database \"…\" as D1.\n" +
            "- class/ERD: class / interface / enum / entity with a { } body listing attributes (name : type) and " +
            "operations (name(args) : ret), visibility glyphs + - # ~ when shown. Relationships: --|> extends, " +
            "..|> implements, *-- composition, o-- aggregation, --> directed, ..> dependency, -- plain; " +
            "multiplicities in quotes; edge labels after a colon.\n" +
            "- use case: A1 --> U1 for actor participation; U1 .> U2 : <<include>> or : <<extend>>.\n" +
            "- state: [*] for initial/final, S1 --> S2 : event, state X <<choice>> for decision diamonds.\n" +
            "- activity/flowchart: block syntax only — start / :Action; / if (Question?) then (yes) … else (no) " +
            "… endif / while (cond) … endwhile / fork … fork again … end fork / stop.\n" +
            "- sequence: declare all participants first, then P1 -> P2 : message (sync), ->> (async), --> (reply).\n" +
            "- component/deployment: component / database / node / cloud declarations, [Name] boxes, --> and ..> links.\n" +
            "- mind map: @startmindmap with * / ** / *** depth lines.\n" +
            "- Unreadable text: give your best guess and add   note right of <alias> : text unclear in image.\n" +
            "- Never invent elements that are not in the image; preserve the original wording.";

        /// <summary>Kick off (or re-run, for a revision) the vision call behind a small progress modal.</summary>
        private void StartImageAnalysis(byte[] png, string instructions, string previousPlantUml)
        {
            CloseMenu();
            float w = 520f, h = 190f;
            var panel = BeginModal(w, h, previousPlantUml == null
                ? "Analyzing image…   —   vision LLM"
                : "Revising extraction…   —   vision LLM");
            var status = MakeText(panel, $"sending image to {VisionLlmSettings.Model}…",
                new Vector2(16f, -60f), new Vector2(w - 32f, 44f), 13,
                new Color(0.84f, 0.88f, 0.94f, 1f), TextAnchor.UpperLeft);
            _imageImportCancel = false;
            MakeButton(panel, "Cancel", new Vector2(w - 104f, -(h - 46f)), new Vector2(88f, 34f),
                new Color(0.22f, 0.24f, 0.29f, 1f), () => { _imageImportCancel = true; CloseMenu(); });

            StartCoroutine(RunImageAnalysis(png, instructions, previousPlantUml, status));
        }

        private IEnumerator RunImageAnalysis(byte[] png, string instructions, string previousPlantUml, Text status)
        {
            string userText;
            if (previousPlantUml == null)
            {
                userText = "Extract the diagram in the attached image into PlantUML per the rules.";
                if (!string.IsNullOrWhiteSpace(instructions))
                    userText += "\n\nAdditional processing instructions from the user:\n" + instructions.Trim();
            }
            else
            {
                userText =
                    "You previously extracted the attached diagram image into this PlantUML:\n\n" + previousPlantUml +
                    "\n\nRevise the extraction according to these instructions, re-checking the image:\n" +
                    (string.IsNullOrWhiteSpace(instructions) ? "(fix any extraction mistakes you can find)" : instructions.Trim()) +
                    "\n\nOutput ONLY the full corrected PlantUML.";
            }

            using (var req = LlmClient.BuildVisionChatRequest(VisionLlmSettings.BaseUrl, VisionLlmSettings.ApiKey,
                       VisionLlmSettings.Model, VisionSystemPrompt, userText, png))
            {
                req.timeout = 300; // vision + a large diagram can be slow, especially on local models
                var op = req.SendWebRequest();
                float t0 = Time.realtimeSinceStartup;
                while (!op.isDone)
                {
                    if (_imageImportCancel) { req.Abort(); yield break; }
                    if (status != null)
                        status.text = $"waiting for {VisionLlmSettings.Model}…   {Time.realtimeSinceStartup - t0:0}s";
                    yield return null;
                }
                if (_imageImportCancel) yield break;

                if (req.result != UnityWebRequest.Result.Success)
                {
                    CloseMenu();
                    ShowLlmErrorToast("Image import couldn't reach the vision LLM:  " + req.error,
                        ("Open Vision LLM settings…", () => ShowVisionLlmSettings(Input.mousePosition)));
                    yield break;
                }
                if (!LlmClient.TryParseContent(req.downloadHandler.text, out var content, out var apiError))
                {
                    CloseMenu();
                    ShowLlmErrorToast("Vision LLM error:  " + apiError,
                        ("Open Vision LLM settings…", () => ShowVisionLlmSettings(Input.mousePosition)));
                    yield break;
                }

                string plantUml = StripFences(content).Trim();
                IxModel model;
                try { model = PlantUmlReader.Parse(plantUml); }
                catch (InterchangeException ex)
                {
                    // Show what came back so the user can fix it by hand and re-parse.
                    ShowImageImportReview(png, plantUml, null, instructions, "✗ parse failed: " + ex.Message);
                    yield break;
                }
                ShowImageImportReview(png, plantUml, model, instructions, null);
            }
        }

        // ------------------------------------------------------------------ review modal

        /// <summary>
        /// The confirmation step: every extracted node and link in an editable table (include? · kind · name ·
        /// members · notes), the PlantUML intermediate (editable, "Re-parse"), and a revision-instruction box that
        /// re-runs the vision LLM with the current PlantUML for another pass — each cycle lands back here.
        /// </summary>
        private void ShowImageImportReview(byte[] png, string plantUml, IxModel ix, string instructions, string initialStatus)
        {
            CloseMenu();
            float w = Mathf.Min(1100f, Screen.width - 60f), h = Mathf.Min(760f, Screen.height - 40f);
            string family = ix != null && ix.Diagrams.Count > 0 && !string.IsNullOrEmpty(ix.Diagrams[0].Kind)
                ? ix.Diagrams[0].Kind : "class";
            var panel = BeginModal(w, h, "Review extracted diagram   —   confirm nodes · links · kinds before import");

            List<IxCommitNode> nodeRows;
            List<IxCommitEdge> edgeRows;
            BuildIxReviewRows(ix, out nodeRows, out edgeRows);

            var status = MakeText(panel, initialStatus ?? "", new Vector2(16f, -(h - 66f)), new Vector2(w - 320f, 18f), 13,
                initialStatus != null ? new Color(0.95f, 0.65f, 0.55f, 1f) : LabelColor, TextAnchor.MiddleLeft);

            float y = -44f;
            string header = ix == null
                ? "nothing parsed yet — fix the PlantUML below and press Re-parse"
                : $"detected:  {FamilyDisplay(family)}   ·   {nodeRows.Count} node(s), {edgeRows.Count} link(s)   ·   via {VisionLlmSettings.Model}";
            MakeText(panel, header, new Vector2(16f, y), new Vector2(w - 32f, 18f), 13,
                new Color(0.70f, 0.78f, 0.66f, 1f), TextAnchor.MiddleLeft);
            y -= 24f;

            // ---------------- nodes table
            MakeText(panel, "Nodes      ✓ import  ·  kind  ·  name  ·  members (';' or ↵ separated)  ·  notes",
                new Vector2(16f, y), new Vector2(w - 32f, 18f), 13, LabelColor, TextAnchor.MiddleLeft);
            y -= 20f;
            float nodesH = Mathf.Max(120f, h * 0.30f);
            var (nodesVp, nodesContent) = BuildScroll(panel, new Vector2(16f, y), w - 32f, nodesH);
            y -= nodesH + 8f;

            var kindOptions = KindOptionsFor(family);
            var nodeWidgets = new List<(IxCommitNode row, Func<bool> inc, DropdownHandle kind, InputField name, InputField members, InputField notes)>();
            {
                const float rowH = 36f;
                float ry = -6f;
                float innerW = w - 64f;
                float nameW = Mathf.Max(140f, innerW * 0.18f);
                float membersW = Mathf.Max(200f, innerW * 0.33f);
                float notesW = Mathf.Max(160f, innerW * 0.26f);
                float kindW = 168f;
                foreach (var row in nodeRows)
                {
                    var opts = new List<string>(kindOptions);
                    if (!opts.Contains(row.Kind.ToString())) opts.Insert(0, row.Kind.ToString());
                    var inc = MakeCheckbox(nodesContent, new Vector2(8f, ry - 6f), "", true);
                    var kindDd = MakeDropdown(nodesContent, new Vector2(38f, ry - 2f), kindW, opts, row.Kind.ToString(), _ => { });
                    var nameIn = MakeInput(nodesContent, new Vector2(38f + kindW + 8f, ry - 2f), nameW, row.Name, "name");
                    var memIn = MakeInput(nodesContent, new Vector2(38f + kindW + nameW + 16f, ry - 2f), membersW,
                        (row.MembersText ?? "").Replace("\n", ";  "), "members");
                    var noteIn = MakeInput(nodesContent, new Vector2(38f + kindW + nameW + membersW + 24f, ry - 2f), notesW,
                        OneLine(row.Notes), "notes");
                    nodeWidgets.Add((row, inc, kindDd, nameIn, memIn, noteIn));
                    ry -= rowH;
                }
                nodesContent.sizeDelta = new Vector2(0f, Mathf.Max(nodesH, nodeRows.Count * rowH + 12f));
                if (nodeRows.Count == 0)
                    MakeText(nodesContent, "(no nodes)", new Vector2(12f, -8f), new Vector2(300f, 18f), 13, LabelColor, TextAnchor.MiddleLeft);
            }

            // ---------------- links table
            MakeText(panel, "Links      ✓ import  ·  kind  ·  endpoints  ·  label",
                new Vector2(16f, y), new Vector2(w - 32f, 18f), 13, LabelColor, TextAnchor.MiddleLeft);
            y -= 20f;
            float edgesH = Mathf.Max(90f, h * 0.17f);
            var (edgesVp, edgesContent) = BuildScroll(panel, new Vector2(16f, y), w - 32f, edgesH);
            y -= edgesH + 10f;

            var nameOf = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            if (ix != null)
                foreach (var el in ix.Elements)
                    if (el != null && el.Id != null && !nameOf.ContainsKey(el.Id))
                        nameOf[el.Id] = string.IsNullOrEmpty(el.Name) ? el.Id : el.Name;

            var edgeWidgets = new List<(IxCommitEdge row, Func<bool> inc, DropdownHandle kind, InputField label)>();
            {
                const float rowH = 36f;
                float ry = -6f;
                float kindW = 190f;
                float endpointsW = Mathf.Max(240f, (w - 64f) * 0.36f);
                float labelW = Mathf.Max(180f, (w - 64f) * 0.28f);
                foreach (var row in edgeRows)
                {
                    var inc = MakeCheckbox(edgesContent, new Vector2(8f, ry - 6f), "", true);
                    var opts = new List<string>(EdgeKindOptions);
                    if (!opts.Contains(row.Kind.ToString())) opts.Insert(0, row.Kind.ToString());
                    var kindDd = MakeDropdown(edgesContent, new Vector2(38f, ry - 2f), kindW, opts, row.Kind.ToString(), _ => { });
                    string fromName = nameOf.TryGetValue(row.FromId ?? "", out var fn) ? fn : row.FromId;
                    string toName = nameOf.TryGetValue(row.ToId ?? "", out var tn) ? tn : row.ToId;
                    MakeText(edgesContent, Ellipsize($"{fromName}   →   {toName}", 52),
                        new Vector2(38f + kindW + 10f, ry - 8f), new Vector2(endpointsW, 22f), 13,
                        new Color(0.84f, 0.88f, 0.94f, 1f), TextAnchor.MiddleLeft);
                    var labelIn = MakeInput(edgesContent, new Vector2(38f + kindW + endpointsW + 18f, ry - 2f), labelW,
                        row.Label, "label");
                    edgeWidgets.Add((row, inc, kindDd, labelIn));
                    ry -= rowH;
                }
                edgesContent.sizeDelta = new Vector2(0f, Mathf.Max(edgesH, edgeRows.Count * rowH + 12f));
                if (edgeRows.Count == 0)
                    MakeText(edgesContent, "(no links)", new Vector2(12f, -8f), new Vector2(300f, 18f), 13, LabelColor, TextAnchor.MiddleLeft);
            }

            // ---------------- PlantUML intermediate + LLM revision loop
            float bottomH = Mathf.Max(110f, h + y - 74f); // space left above the button row
            float colGap = 16f;
            float pumlW = (w - 32f - colGap) * 0.58f;
            float revW = (w - 32f - colGap) * 0.42f;

            MakeText(panel, "PlantUML   (edit, then Re-parse to refresh the tables)",
                new Vector2(16f, y), new Vector2(pumlW, 18f), 13, LabelColor, TextAnchor.MiddleLeft);
            var pumlInput = MakeMultilineInput(panel, new Vector2(16f, y - 20f), pumlW, bottomH - 20f,
                plantUml ?? "", "@startuml …");
            MakeButton(panel, "⟳ Re-parse", new Vector2(16f + pumlW - 96f, y + 2f), new Vector2(96f, 24f),
                new Color(0.20f, 0.42f, 0.52f, 1f), () =>
                {
                    try
                    {
                        var reparsed = PlantUmlReader.Parse(pumlInput.text);
                        ShowImageImportReview(png, pumlInput.text, reparsed, instructions, null);
                    }
                    catch (InterchangeException ex) { status.text = "✗ " + ex.Message; }
                });

            float revX = 16f + pumlW + colGap;
            MakeText(panel, "Revision instructions   (re-runs the vision LLM against the image)",
                new Vector2(revX, y), new Vector2(revW, 18f), 13, LabelColor, TextAnchor.MiddleLeft);
            var reviseInput = MakeMultilineInput(panel, new Vector2(revX, y - 20f), revW, bottomH - 56f, "",
                "e.g. the middle box is a database, not a class; there's a missing arrow from Cache to Store");
            MakeButton(panel, "✨ Revise via LLM", new Vector2(revX, y - 20f - (bottomH - 56f) - 6f),
                new Vector2(revW, 28f), new Color(0.22f, 0.34f, 0.46f, 1f), () =>
                {
                    if (png == null) { status.text = "✗ the source image is gone — re-parse instead"; return; }
                    StartImageAnalysis(png, reviseInput.text, pumlInput.text);
                });

            // ---------------- commit
            float yBtn = -(h - 46f);
            MakeButton(panel, "Import checked", new Vector2(w - 262f, yBtn), new Vector2(148f, 34f),
                new Color(0.18f, 0.46f, 0.30f, 1f), () =>
                {
                    if (ix == null) { status.text = "✗ nothing parsed — Re-parse the PlantUML first"; return; }

                    // Fold the live widget state back into the rows.
                    foreach (var nw in nodeWidgets)
                    {
                        nw.row.Include = nw.inc();
                        nw.row.Name = nw.name.text;
                        nw.row.MembersText = nw.members.text;
                        nw.row.Notes = nw.notes.text;
                        if (Enum.TryParse<ElementKind>(nw.kind.Get(), out var k)) nw.row.Kind = k;
                    }
                    foreach (var ew in edgeWidgets)
                    {
                        ew.row.Include = ew.inc();
                        ew.row.Label = ew.label.text;
                        if (Enum.TryParse<EdgeKind>(ew.kind.Get(), out var k)) ew.row.Kind = k;
                    }

                    CloseMenu();
                    string sourceTag = null;
                    if (png != null)
                    {
                        string file = SaveImageBytes(png);   // keep the source image alongside the diagram
                        if (file != null) sourceTag = "image://" + file;
                    }
                    CommitIxReview(nodeRows, edgeRows, family, sourceTag);
                });
            MakeButton(panel, "Cancel", new Vector2(w - 104f, yBtn), new Vector2(88f, 34f),
                new Color(0.22f, 0.24f, 0.29f, 1f), CloseMenu);
        }

        private static string OneLine(string s)
        {
            if (string.IsNullOrEmpty(s)) return "";
            return s.Replace("\r", "").Replace("\n", "  ");
        }

        private static string FamilyDisplay(string family)
        {
            switch (family)
            {
                case "class": return "class / ERD diagram";
                case "usecase": return "use-case diagram";
                case "state": return "state machine";
                case "activity": return "activity / flowchart";
                case "sequence": return "sequence diagram";
                case "component": return "component / deployment diagram";
                case "mindmap": return "mind map";
                default: return family + " diagram";
            }
        }

        /// <summary>Curated per-family kind choices for the review table's dropdown (full enum would be unusable).</summary>
        private static List<string> KindOptionsFor(string family)
        {
            switch (family)
            {
                case "usecase":
                    return new List<string> { "UseCase", "Actor", "Boundary", "Note", "Class", "Component" };
                case "state":
                    return new List<string> { "State", "StateStart", "StateEnd", "Decision", "ForkJoin", "Junction",
                        "History", "Terminate", "Activity", "Note" };
                case "activity":
                    return new List<string> { "Activity", "CallActivity", "Decision", "ForkJoin", "StateStart",
                        "StateEnd", "FlowFinal", "AsyncSend", "AsyncReceive", "FlowProcess", "FlowTerminator",
                        "FlowIO", "FlowDocument", "Note" };
                case "sequence":
                    return new List<string> { "Lifeline", "Actor", "Boundary", "Note" };
                case "component":
                    return new List<string> { "Component", "DeploymentNode", "Database", "Cloud", "Server", "Client",
                        "Firewall", "Artifact", "PackageNode", "Interface", "Note" };
                case "mindmap":
                    return new List<string> { "MindNode", "Note", "WhiteboardSticky", "WhiteboardCard", "WhiteboardText" };
                default: // class / ERD
                    return new List<string> { "Class", "Interface", "Enum", "Struct", "DataType", "EntityTable",
                        "ObjectInstance", "Component", "PackageNode", "Actor", "Note", "External" };
            }
        }

        private static readonly List<string> EdgeKindOptions = new List<string>
        {
            "Association", "DirectedAssociation", "Dependency", "Generalization", "Realization", "Aggregation",
            "Composition", "Transition", "Include", "Extend", "NoteLink", "MessageSync", "MessageAsync",
            "MessageReply", "Consumes", "SketchConnector",
        };

        // ------------------------------------------------------------------ vision LLM settings dialog

        /// <summary>
        /// Edit the vision endpoint (provider preset / base URL / API key / model), mirroring
        /// <see cref="ShowLlmSettings"/>. Leaving base URL and model empty falls back to the main LLM settings.
        /// </summary>
        public void ShowVisionLlmSettings(Vector2 screenPos)
        {
            CloseMenu();
            VisionLlmSettings.Load(out var baseUrl, out var apiKey, out var model);

            const float w = 520f, h = 424f;
            var panel = BeginModal(w, h, "Vision LLM settings   —   image-capable OpenAI-compatible endpoint");

            float y = -50f;
            MakeText(panel, "Blank base URL + model  ⇒  reuse the main LLM settings (it must be vision-capable).",
                new Vector2(16f, y), new Vector2(w - 32f, 18f), 12, LabelColor, TextAnchor.MiddleLeft);
            y -= 24f;

            FormLabel(panel, "Provider preset", ref y, w);
            var status = MakeText(panel, "", new Vector2(16f, -(h - 78f)), new Vector2(w - 32f, 18f), 13,
                LabelColor, TextAnchor.MiddleLeft);

            InputField urlInput = null, keyInput = null;
            DropdownHandle modelDd = null;
            var knownProviders = CurrentLlmProviders();

            var providerNames = new List<string> { "Custom…" };
            foreach (var p in knownProviders) providerNames.Add(p.Name);
            string currentProvider = "Custom…";
            foreach (var p in knownProviders)
                if (string.Equals(p.BaseUrl.TrimEnd('/'), (baseUrl ?? "").TrimEnd('/'), StringComparison.OrdinalIgnoreCase))
                    currentProvider = p.Name;

            var providerDd = MakeDropdown(panel, new Vector2(16f, y), w - 32f, providerNames, currentProvider, sel =>
            {
                foreach (var p in knownProviders)
                    if (p.Name == sel)
                    {
                        if (urlInput != null) urlInput.text = p.BaseUrl;
                        if (keyInput != null && !string.IsNullOrEmpty(p.EnvVar))
                        {
                            string envKey = Environment.GetEnvironmentVariable(p.EnvVar);
                            if (!string.IsNullOrEmpty(envKey)) { keyInput.text = envKey; status.text = $"API key loaded from ${p.EnvVar}"; }
                            else status.text = $"{p.EnvVar} not set in the environment — paste a key below";
                        }
                        else if (keyInput != null && string.IsNullOrEmpty(p.EnvVar)) status.text = "local provider — no API key needed";
                        break;
                    }
            });
            y -= 42f;

            FormLabel(panel, "Base URL   (blank = main LLM endpoint)", ref y, w);
            urlInput = MakeInput(panel, new Vector2(16f, y), w - 32f, baseUrl, LlmSettings.BaseUrl);
            y -= 42f;

            FormLabel(panel, "API key   (blank on a dedicated URL = no auth header)", ref y, w);
            keyInput = MakeInput(panel, new Vector2(16f, y), w - 200f, apiKey, "sk-…  (optional for local)");
            keyInput.contentType = InputField.ContentType.Password;
            MakeButton(panel, "Test connection", new Vector2(w - 176f, y), new Vector2(160f, 32f),
                new Color(0.22f, 0.40f, 0.34f, 1f), () => StartCoroutine(TestLlmConnection(
                    string.IsNullOrWhiteSpace(urlInput.text) ? LlmSettings.BaseUrl : urlInput.text,
                    keyInput.text, status)));
            y -= 42f;

            FormLabel(panel, "Vision model   (blank = main model; Fetch lists the provider's models)", ref y, w);
            var models = GlobalCatalog.LlmModels;
            if (!string.IsNullOrEmpty(model) && !ContainsIgnoreCase(models, model)) models.Add(model);
            models.Sort(StringComparer.OrdinalIgnoreCase);
            modelDd = MakeDropdown(panel, new Vector2(16f, y), w - 200f, models,
                string.IsNullOrEmpty(model) ? "(main model)" : model, _ => { });
            MakeButton(panel, "↻ Fetch models", new Vector2(w - 176f, y), new Vector2(160f, 32f),
                new Color(0.22f, 0.34f, 0.46f, 1f),
                () => StartCoroutine(FetchLlmModels(
                    string.IsNullOrWhiteSpace(urlInput.text) ? LlmSettings.BaseUrl : urlInput.text,
                    keyInput.text, modelDd, status)));
            y -= 46f;

            Action submit = () =>
            {
                string selectedModel = modelDd.Get();
                if (string.IsNullOrWhiteSpace(selectedModel) || selectedModel == "(main model)"
                    || selectedModel == "(fetch models)")
                    selectedModel = "";
                if (!string.IsNullOrWhiteSpace(selectedModel)) GlobalCatalog.RememberLlmModel(selectedModel);
                VisionLlmSettings.Save(urlInput.text, keyInput.text, selectedModel);
                CloseMenu();
                Flash("vision LLM settings saved");
            };

            float yBtn = -(h - 46f);
            MakeButton(panel, "Save", new Vector2(w - 198f, yBtn), new Vector2(84f, 34f),
                new Color(0.20f, 0.42f, 0.52f, 1f), () => submit());
            MakeButton(panel, "Cancel", new Vector2(w - 104f, yBtn), new Vector2(88f, 34f),
                new Color(0.22f, 0.24f, 0.29f, 1f), CloseMenu);

            FocusInput(urlInput);
        }
    }
}
