using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using UnityEngine;
using UnityEngine.UI;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// The folder-import UX: a pre-flight <b>plan</b> modal (pick files, set extension filters, add custom LLM
    /// modeling guidance) and a live <b>progress</b> modal (incremental population, running tallies, an issue log,
    /// and pause / resume / cancel). The actual parsing/materialization loop lives in <c>RunImportFolder</c>
    /// (UmlCanvas.CodeImport); this partial only drives it and renders its state.
    /// </summary>
    public sealed partial class UmlCanvas
    {
        /// <summary>Set by the progress modal's Pause button; the import coroutine spins while true.</summary>
        private bool _importPaused;
        /// <summary>Set by the progress modal's Cancel/Close; the import coroutine breaks and finalizes what it has.</summary>
        private bool _importCancel;

        /// <summary>Live handles the import coroutine calls to update the progress modal. All null-guarded so the
        /// coroutine survives the modal being closed mid-run.</summary>
        private sealed class ImportProgressHandle
        {
            public Action<int, int, string> Progress;   // (done, total, currentFile)
            public Action<int, int, int> Tallies;       // (types, relationships, issues)
            public Action<string> Issue;                // append one issue line
            public Action<string> Status;               // status word (e.g. "paused")
            public Action<string> Done;                 // final summary; flips buttons to "Close"
        }

        // ------------------------------------------------------------------ plan / pre-flight modal

        private void ShowImportPlanModal(string folder, List<string> allFiles, string langHint, bool truncated)
        {
            CloseMenu();
            float w = 700f, h = 640f;
            var panel = BeginModal(w, h, "Import folder   —   pick files · filter · customize");

            float y = -46f;
            MakeText(panel, Ellipsize(folder, 92), new Vector2(16f, y), new Vector2(w - 32f, 18f), 13,
                new Color(0.62f, 0.68f, 0.78f, 1f), TextAnchor.MiddleLeft);
            y -= 26f;

            // Extension filters.
            MakeText(panel, "Only extensions (csv, blank = all)", new Vector2(16f, y), new Vector2(300f, 18f), 13, LabelColor, TextAnchor.MiddleLeft);
            MakeText(panel, "Exclude extensions (csv)", new Vector2(360f, y), new Vector2(220f, 18f), 13, LabelColor, TextAnchor.MiddleLeft);
            y -= 20f;
            var includeInput = MakeInput(panel, new Vector2(16f, y), 330f, "", "ex, java");
            var excludeInput = MakeInput(panel, new Vector2(360f, y), 200f, "", "tsx, d.ts");
            var countText = MakeText(panel, "", new Vector2(16f, y - 34f), new Vector2(w - 200f, 18f), 13,
                new Color(0.70f, 0.78f, 0.66f, 1f), TextAnchor.MiddleLeft);

            // Scrollable file checklist.
            const float rowH = 26f;
            float listTop = y - 58f, listH = 250f, listW = w - 32f;
            var (_, contentRt) = BuildScroll(panel, new Vector2(16f, listTop), listW, listH);

            var rows = new List<(string path, Func<bool> getChecked)>();

            HashSet<string> ParseExts(string csv)
            {
                var set = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                foreach (var raw in (csv ?? "").Split(','))
                {
                    string e = raw.Trim().TrimStart('*');
                    if (e.Length == 0) continue;
                    if (!e.StartsWith(".")) e = "." + e;
                    set.Add(e.ToLowerInvariant());
                }
                return set;
            }

            bool PassesFilter(string path, HashSet<string> inc, HashSet<string> exc)
            {
                string fn = Path.GetFileName(path).ToLowerInvariant();
                string ext = Path.GetExtension(path).ToLowerInvariant();
                // Compound extensions like ".d.ts" / ".tsx": match by suffix so "tsx"/"d.ts" filters work.
                bool ExtIn(HashSet<string> s) { foreach (var e in s) if (fn.EndsWith(e)) return true; return false; }
                if (inc.Count > 0 && !ExtIn(inc)) return false;
                if (exc.Count > 0 && ExtIn(exc)) return false;
                return true;
            }

            void Rebuild(Func<string, bool> initialChecked)
            {
                foreach (Transform t in contentRt) Destroy(t.gameObject);
                rows.Clear();
                float ry = -4f;
                int checkedCount = 0;
                foreach (var path in allFiles)
                {
                    bool init = initialChecked(path);
                    if (init) checkedCount++;
                    string rel = path.StartsWith(folder) ? path.Substring(folder.Length).TrimStart('/', '\\') : Path.GetFileName(path);
                    var getter = MakeCheckbox(contentRt, new Vector2(6f, ry), Ellipsize(rel, 80), init);
                    rows.Add((path, getter));
                    ry -= rowH;
                }
                contentRt.sizeDelta = new Vector2(0f, Mathf.Max(listH, allFiles.Count * rowH + 8f));
                countText.text = $"{checkedCount} of {allFiles.Count} files selected" + (truncated ? $"  (capped at {ImportFileCap})" : "");
            }

            void ApplyFilters()
            {
                var inc = ParseExts(includeInput.text);
                var exc = ParseExts(excludeInput.text);
                Rebuild(p => PassesFilter(p, inc, exc));
            }

            MakeButton(panel, "Apply filters", new Vector2(w - 132f, y + 2f), new Vector2(116f, 30f),
                new Color(0.22f, 0.40f, 0.34f, 1f), ApplyFilters);

            // Bulk select.
            float bulkY = listTop - listH - 6f;
            MakeButton(panel, "All", new Vector2(16f, bulkY), new Vector2(64f, 26f),
                new Color(0.22f, 0.24f, 0.29f, 1f), () => Rebuild(_ => true));
            MakeButton(panel, "None", new Vector2(86f, bulkY), new Vector2(64f, 26f),
                new Color(0.22f, 0.24f, 0.29f, 1f), () => Rebuild(_ => false));

            // Custom LLM modeling prompt.
            float promptLabelY = bulkY - 30f;
            MakeText(panel, "Custom guidance for the LLM (optional — how to model these files as UML)",
                new Vector2(16f, promptLabelY), new Vector2(w - 32f, 18f), 13, LabelColor, TextAnchor.MiddleLeft);
            var promptInput = MakeMultilineInput(panel, new Vector2(16f, promptLabelY - 22f), w - 32f, 70f, "",
                "e.g. treat GenServer modules as «service» classes; ignore test modules");

            // Actions.
            float yBtn = -(h - 46f);
            MakeButton(panel, "Start import", new Vector2(w - 250f, yBtn), new Vector2(146f, 34f),
                new Color(0.18f, 0.46f, 0.30f, 1f), () =>
                {
                    var selected = new List<string>();
                    foreach (var (path, getChecked) in rows) if (getChecked()) selected.Add(path);
                    if (selected.Count == 0) { Flash("select at least one file"); return; }
                    string customPrompt = promptInput.text;
                    var ui = ShowImportProgressUi(selected.Count);
                    _importPaused = false; _importCancel = false;
                    StartCoroutine(RunImportFolder(selected, langHint, customPrompt, ui));
                });
            MakeButton(panel, "Cancel", new Vector2(w - 100f, yBtn), new Vector2(84f, 34f),
                new Color(0.22f, 0.24f, 0.29f, 1f), CloseMenu);

            Rebuild(_ => true); // start with everything selected
        }

        // ------------------------------------------------------------------ live progress modal

        private ImportProgressHandle ShowImportProgressUi(int total)
        {
            float w = 640f, h = 520f;
            var panel = BeginModal(w, h, "Importing…   —   live progress");

            // Progress bar.
            float barW = w - 32f, barH = 22f;
            var barBg = new GameObject("Bar", typeof(RectTransform));
            var barRt = (RectTransform)barBg.transform;
            barRt.SetParent(panel, false);
            barRt.anchorMin = barRt.anchorMax = new Vector2(0f, 1f);
            barRt.pivot = new Vector2(0f, 1f);
            barRt.sizeDelta = new Vector2(barW, barH);
            barRt.anchoredPosition = new Vector2(16f, -48f);
            TheRobotDraft.Uml.Chrome.MacOsControlKit.ApplyProgressTrack(barBg.AddComponent<Image>());

            var fill = new GameObject("Fill", typeof(RectTransform));
            var fillRt = (RectTransform)fill.transform;
            fillRt.SetParent(barRt, false);
            fillRt.anchorMin = new Vector2(0f, 0f); fillRt.anchorMax = new Vector2(0f, 1f);
            fillRt.pivot = new Vector2(0f, 0.5f);
            fillRt.sizeDelta = new Vector2(0f, 0f);
            fillRt.anchoredPosition = Vector2.zero;
            var fillImg = fill.AddComponent<Image>();
            // Accent fill on raised track (primary action green).
            TheRobotDraft.Uml.Chrome.MacOsControlKit.ApplyButton(fillImg, new Color(0.20f, 0.52f, 0.36f, 1f));

            var pctText = MakeText(panel, $"0 / {total}", new Vector2(16f, -74f), new Vector2(w - 32f, 18f), 13,
                new Color(0.84f, 0.88f, 0.94f, 1f), TextAnchor.MiddleLeft);
            var fileText = MakeText(panel, "", new Vector2(16f, -94f), new Vector2(w - 32f, 18f), 13,
                new Color(0.62f, 0.70f, 0.80f, 1f), TextAnchor.MiddleLeft);
            var tallyText = MakeText(panel, "types: 0   relationships: 0   issues: 0", new Vector2(16f, -116f),
                new Vector2(w - 32f, 18f), 13, new Color(0.72f, 0.80f, 0.70f, 1f), TextAnchor.MiddleLeft);

            MakeText(panel, "Issues", new Vector2(16f, -142f), new Vector2(200f, 18f), 13, LabelColor, TextAnchor.MiddleLeft);
            var (vpRt, contentRt) = BuildScroll(panel, new Vector2(16f, -162f), w - 32f, h - 162f - 64f);
            var issuesText = MakeText(contentRt, "", new Vector2(8f, -4f), new Vector2(w - 64f, 20f), 13,
                new Color(0.90f, 0.74f, 0.66f, 1f), TextAnchor.UpperLeft);
            issuesText.horizontalOverflow = HorizontalWrapMode.Wrap;
            issuesText.verticalOverflow = VerticalWrapMode.Overflow;
            var issuesSb = new StringBuilder();

            bool finished = false;

            // Buttons: Pause/Resume + Cancel, swapped to Close on completion. Build Pause/Resume manually (not via
            // MakeButton) so its label + tint can flip in place.
            float yBtn = -(h - 46f);
            Text pauseLabel;
            var pauseGo = new GameObject("Button:Pause", typeof(RectTransform));
            var pRt = (RectTransform)pauseGo.transform;
            pRt.SetParent(panel, false);
            pRt.anchorMin = pRt.anchorMax = new Vector2(0f, 1f); pRt.pivot = new Vector2(0f, 1f);
            pRt.sizeDelta = new Vector2(120f, 34f); pRt.anchoredPosition = new Vector2(16f, yBtn);
            var pImg = pauseGo.AddComponent<Image>(); pImg.color = new Color(0.30f, 0.30f, 0.16f, 1f);
            var pBtn = pauseGo.AddComponent<Button>(); pBtn.targetGraphic = pImg;
            pauseLabel = MakeText(pRt, "Pause", Vector2.zero, new Vector2(120f, 34f), 16, new Color(0.95f, 0.97f, 1f), TextAnchor.MiddleCenter);
            pBtn.onClick.AddListener(() =>
            {
                if (finished) return;
                _importPaused = !_importPaused;
                pauseLabel.text = _importPaused ? "Resume" : "Pause";
                pImg.color = _importPaused ? new Color(0.20f, 0.40f, 0.30f, 1f) : new Color(0.30f, 0.30f, 0.16f, 1f);
            });

            MakeButton(panel, "Cancel", new Vector2(146f, yBtn), new Vector2(120f, 34f),
                new Color(0.46f, 0.22f, 0.24f, 1f), () => { _importCancel = true; });
            MakeButton(panel, "Close", new Vector2(w - 104f, yBtn), new Vector2(88f, 34f),
                new Color(0.22f, 0.24f, 0.29f, 1f), () => { _importCancel = true; CloseMenu(); });

            void SetProgress(int done, int tot, string file)
            {
                if (pctText == null) return;
                float frac = tot > 0 ? Mathf.Clamp01((float)done / tot) : 0f;
                if (fillRt != null) fillRt.sizeDelta = new Vector2(barW * frac, 0f);
                pctText.text = $"{done} / {tot}";
                if (fileText != null) fileText.text = Ellipsize(file ?? "", 84);
            }

            return new ImportProgressHandle
            {
                Progress = SetProgress,
                Tallies = (t, e, iss) => { if (tallyText != null) tallyText.text = $"types: {t}   relationships: {e}   issues: {iss}"; },
                Issue = m =>
                {
                    if (issuesText == null) return;
                    issuesSb.Append("• ").Append(m).Append('\n');
                    issuesText.text = issuesSb.ToString();
                    issuesText.rectTransform.sizeDelta = new Vector2(w - 64f, Mathf.Max(20f, issuesText.preferredHeight));
                    contentRt.sizeDelta = new Vector2(0f, Mathf.Max(vpRt.sizeDelta.y, issuesText.preferredHeight + 12f));
                },
                Status = s => { if (fileText != null && _importPaused) fileText.text = "⏸ " + s; },
                Done = summary =>
                {
                    finished = true;
                    if (pctText != null) pctText.text = summary;
                    if (fillRt != null) fillRt.sizeDelta = new Vector2(barW, 0f);
                    if (pauseLabel != null) { pauseLabel.text = "Done"; pBtn.interactable = false; }
                },
            };
        }

        // ------------------------------------------------------------------ shared scroll-view builder

        /// <summary>Build a vertical scroll view (viewport + content) at the given top-left; returns both RectTransforms.</summary>
        private (RectTransform viewport, RectTransform content) BuildScroll(RectTransform parent, Vector2 topLeft, float width, float height)
        {
            var viewportGo = new GameObject("Viewport", typeof(RectTransform));
            var vpRt = (RectTransform)viewportGo.transform;
            vpRt.SetParent(parent, false);
            vpRt.anchorMin = vpRt.anchorMax = new Vector2(0f, 1f);
            vpRt.pivot = new Vector2(0f, 1f);
            vpRt.sizeDelta = new Vector2(width, height);
            vpRt.anchoredPosition = topLeft;
            TheRobotDraft.Uml.Chrome.MacOsControlKit.ApplyScrollWell(viewportGo.AddComponent<Image>());
            viewportGo.AddComponent<RectMask2D>();
            var scroll = viewportGo.AddComponent<ScrollRect>();
            scroll.horizontal = false; scroll.vertical = true; scroll.movementType = ScrollRect.MovementType.Clamped;
            scroll.scrollSensitivity = 28f;

            var contentGo = new GameObject("Content", typeof(RectTransform));
            var contentRt = (RectTransform)contentGo.transform;
            contentRt.SetParent(vpRt, false);
            contentRt.anchorMin = new Vector2(0f, 1f); contentRt.anchorMax = new Vector2(1f, 1f);
            contentRt.pivot = new Vector2(0.5f, 1f);
            contentRt.sizeDelta = new Vector2(0f, height);
            contentRt.anchoredPosition = Vector2.zero;
            scroll.viewport = vpRt; scroll.content = contentRt;
            return (vpRt, contentRt);
        }
    }
}
