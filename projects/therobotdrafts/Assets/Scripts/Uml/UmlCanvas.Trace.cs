using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using TheRobotDraft.Authoring.Debug;
using TheRobotDraft.Authoring.Model;
using TheRobotDraft.CodeGen;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// The Bubble Trace IDE: a special view that traces from a UML element to its code, makes each call site in
    /// that code clickable to open the referenced element's code as a NEW bubble (linked by a green trace edge),
    /// and lets a line gutter set breakpoints on the element. It has two modes: <b>Edit</b> (open the element's
    /// code in the existing code viewer to change it) and <b>Debug</b> (drive a <see cref="IDebugSession"/> —
    /// Launch / Continue / Step — with the current line highlighted across the open bubbles).
    ///
    /// Breakpoints are authoring data held in <see cref="_breakpoints"/> (persisted with the diagram). The debugger
    /// is reached only through the <see cref="IDebugSession"/> seam; today that is the deterministic
    /// <see cref="TraceDebugSession"/> walking the modeled code, and a real DAP/LSP adapter can replace it without
    /// touching this view.
    /// </summary>
    public sealed partial class UmlCanvas
    {
        // Breakpoints across the whole diagram (persisted). Public-ish to the persistence partial in this assembly.
        private readonly BreakpointStore _breakpoints = new();

        // Open trace state. _traceBubbles is the ordered chain of elements shown left→right (root first); the rest
        // is rebuilt from it so every interaction is just "mutate state, rebuild window".
        private readonly List<ElementId> _traceBubbles = new();
        private bool _traceDebug;               // false = Edit mode, true = Debug mode
        private TraceDebugSession _debug;        // live session in Debug mode (null otherwise)
        private GameObject _traceWindow;         // the full-canvas overlay (also assigned to _menu so Esc closes it)

        private const float TraceBubbleW = 380f, TraceBubbleH = 560f, TraceGap = 64f, TraceTop = -88f;
        private const int TraceMaxLines = 400;
        private static readonly Color TraceEdgeColor = new Color(0.40f, 0.86f, 0.42f, 1f);     // the green trace line
        private static readonly Color BreakpointColor = new Color(0.86f, 0.24f, 0.24f, 1f);
        private static readonly Color CurrentLineColor = new Color(0.86f, 0.74f, 0.20f, 0.30f);

        // --- entry point ---

        /// <summary>Open (or refocus) the trace view rooted at <paramref name="id"/> — the node-menu / inspector hook.</summary>
        public void ShowTraceView(ElementId id)
        {
            CloseMenu();
            if (!_model.TryGet(id, out var el) || !KindInfo.IsDiagramNode(el.Kind) || el.Kind == ElementKind.Note)
            { Flash("trace works on a class / function bubble"); return; }

            _traceBubbles.Clear();
            _traceBubbles.Add(id);
            _traceDebug = false;
            _debug = null;
            RebuildTraceWindow();
            Flash("trace view — click a call to open it as a bubble; click a line number to set a breakpoint");
        }

        /// <summary>True while the trace overlay is open (so Update / other features can defer to it if needed).</summary>
        private bool TraceOpen => _traceWindow != null;

        // --- code listing per element (Code → imported-source slice → deterministic skeleton) ---

        /// <summary>
        /// The source listing shown for an element in a bubble: its approved <see cref="ModelElement.Code"/>, else its
        /// imported source file sliced to this element's definition, else the deterministic skeleton. Mirrors the
        /// precedence the code viewer uses so the trace and the editor agree on "this element's code".
        /// </summary>
        private string TraceListingFor(ElementId id)
        {
            if (!_model.TryGet(id, out var el)) return "";
            if (!string.IsNullOrWhiteSpace(el.Code)) return el.Code;
            if (!string.IsNullOrEmpty(el.SourceFile) && _sourceFiles.TryGetValue(el.SourceFile, out var src))
            {
                int declLine = FindDeclarationLine(src, el.Name);
                if (declLine > 0) return ExtractDefinitionSection(src, declLine, out _);
                return src;
            }
            if (KindInfo.IsWireframeRegion(el.Kind)) return "";
            return CodeSkeleton.Generate(BuildCodeContext(id));
        }

        /// <summary>Map every diagram-node element name → its id, so call-site scanning can resolve references.</summary>
        private Dictionary<string, ElementId> BuildNameIndex()
        {
            var index = new Dictionary<string, ElementId>();
            foreach (var el in _model.Elements)
            {
                if (!KindInfo.IsDiagramNode(el.Kind) || el.Kind == ElementKind.Note) continue;
                if (string.IsNullOrWhiteSpace(el.Name)) continue;
                index[el.Name.Trim()] = el.Id; // last-wins on a name clash is fine for navigation
            }
            return index;
        }

        /// <summary>A model-backed <see cref="ICodeGraph"/> for the debug session: caches each element's listing + call sites.</summary>
        private sealed class ModelCodeGraph : ICodeGraph
        {
            private readonly UmlCanvas _c;
            private readonly Dictionary<string, ElementId> _names;
            private readonly Dictionary<ElementId, List<string>> _lines = new();
            private readonly Dictionary<ElementId, List<CallSite>> _calls = new();

            public ModelCodeGraph(UmlCanvas c)
            {
                _c = c;
                _names = c.BuildNameIndex();
            }

            private void Ensure(ElementId el)
            {
                if (_lines.ContainsKey(el)) return;
                string listing = _c.TraceListingFor(el);
                var lines = new List<string>(listing.Replace("\r\n", "\n").Replace('\r', '\n').Split('\n'));
                _lines[el] = lines;
                _calls[el] = CallSiteScanner.Scan(listing, el, _names);
            }

            public IReadOnlyList<string> LinesFor(ElementId element) { Ensure(element); return _lines[element]; }

            public IReadOnlyList<CallSite> CallSitesOn(ElementId element, int line)
            {
                Ensure(element);
                var hits = new List<CallSite>();
                foreach (var cs in _calls[element]) if (cs.Line == line) hits.Add(cs);
                return hits;
            }
        }

        // --- window build ---

        private void RebuildTraceWindow()
        {
            CloseMenu(); // also destroys a prior _traceWindow (it is assigned to _menu)

            // A full-canvas dim overlay that blocks the diagram beneath; the bubbles + toolbar sit on it.
            var overlay = new GameObject("TraceOverlay", typeof(RectTransform));
            var ort = (RectTransform)overlay.transform;
            ort.SetParent(_root, false);
            Stretch(ort);
            TheRobotDraft.Uml.Chrome.MacOsControlKit.ApplyBackdrop(overlay.AddComponent<Image>());
            // Trace needs a heavier veil than form modals.
            overlay.GetComponent<Image>().color = new Color(0.05f, 0.06f, 0.08f, 0.92f);
            overlay.AddComponent<UmlModalBackdrop>().Canvas = this; // swallow stray clicks
            _menu = overlay;
            _traceWindow = overlay;

            BuildTraceToolbar(ort);

            // Horizontally-scrolling strip holding the bubble chain.
            float stripH = TraceBubbleH + 24f;
            var viewport = new GameObject("TraceStrip", typeof(RectTransform));
            var vpRt = (RectTransform)viewport.transform;
            vpRt.SetParent(ort, false);
            vpRt.anchorMin = new Vector2(0f, 1f); vpRt.anchorMax = new Vector2(1f, 1f);
            vpRt.pivot = new Vector2(0f, 1f);
            vpRt.offsetMin = new Vector2(0f, 0f); vpRt.offsetMax = new Vector2(0f, 0f);
            vpRt.sizeDelta = new Vector2(0f, stripH);
            vpRt.anchoredPosition = new Vector2(0f, TraceTop);
            viewport.AddComponent<RectMask2D>();
            var scroll = viewport.AddComponent<ScrollRect>();
            scroll.vertical = false; scroll.horizontal = true; scroll.scrollSensitivity = 36f;
            scroll.movementType = ScrollRect.MovementType.Clamped;

            var content = new GameObject("TraceContent", typeof(RectTransform));
            var cRt = (RectTransform)content.transform;
            cRt.SetParent(vpRt, false);
            cRt.anchorMin = new Vector2(0f, 0f); cRt.anchorMax = new Vector2(0f, 1f);
            cRt.pivot = new Vector2(0f, 1f);
            float totalW = TraceGap + _traceBubbles.Count * (TraceBubbleW + TraceGap);
            cRt.sizeDelta = new Vector2(totalW, 0f);
            cRt.anchoredPosition = Vector2.zero;
            scroll.viewport = vpRt; scroll.content = cRt;

            // Green connectors between consecutive bubbles, drawn behind the panels.
            for (int i = 1; i < _traceBubbles.Count; i++)
            {
                float x = TraceGap + i * (TraceBubbleW + TraceGap) - TraceGap;
                var bar = new GameObject("TraceEdge", typeof(RectTransform));
                var bRt = (RectTransform)bar.transform;
                bRt.SetParent(cRt, false);
                bRt.anchorMin = bRt.anchorMax = new Vector2(0f, 1f);
                bRt.pivot = new Vector2(0f, 0.5f);
                bRt.sizeDelta = new Vector2(TraceGap, 8f);
                bRt.anchoredPosition = new Vector2(x, -TraceBubbleH * 0.5f - 12f);
                var img = bar.AddComponent<Image>();
                img.color = TraceEdgeColor;
                img.raycastTarget = false;
            }

            var graph = _traceDebug ? new ModelCodeGraph(this) : null;
            for (int i = 0; i < _traceBubbles.Count; i++)
            {
                float x = TraceGap + i * (TraceBubbleW + TraceGap);
                BuildBubble(cRt, _traceBubbles[i], new Vector2(x, -12f), graph);
            }
        }

        private void BuildTraceToolbar(RectTransform parent)
        {
            MakeText(parent, _traceDebug ? "Trace · DEBUG" : "Trace · EDIT", new Vector2(16f, -12f),
                new Vector2(220f, 26f), 18, new Color(0.90f, 0.94f, 1f, 1f), TextAnchor.MiddleLeft)
                .fontStyle = FontStyle.Bold;

            // Mode toggle.
            MakeButton(parent, _traceDebug ? "✎ Edit mode" : "🐞 Debug mode", new Vector2(240f, -46f),
                new Vector2(132f, 30f), new Color(0.24f, 0.30f, 0.42f, 1f), ToggleTraceMode);

            float x = 384f;
            if (_traceDebug)
            {
                // Debug controls drive the session; each rebuilds so the current-line highlight follows.
                (string lbl, System.Action act)[] controls =
                {
                    ("▶ Launch", () => { _debug?.Launch(_traceBubbles[0]); SyncTraceToCurrent(); }),
                    ("⏵ Continue", () => { _debug?.Continue(); SyncTraceToCurrent(); }),
                    ("⤵ Step into", () => { _debug?.StepInto(); SyncTraceToCurrent(); }),
                    ("⤼ Step over", () => { _debug?.StepOver(); SyncTraceToCurrent(); }),
                    ("⤴ Step out", () => { _debug?.StepOut(); SyncTraceToCurrent(); }),
                    ("■ Stop", () => { _debug?.Stop(); SyncTraceToCurrent(); }),
                };
                foreach (var c in controls)
                {
                    var act = c.act;
                    MakeButton(parent, c.lbl, new Vector2(x, -46f), new Vector2(108f, 30f),
                        new Color(0.20f, 0.34f, 0.30f, 1f), () => act());
                    x += 116f;
                }
            }

            // Status + breakpoint count + close.
            string status = _traceDebug ? DebugStatus() : $"{_breakpoints.Count} breakpoint(s) set";
            MakeText(parent, status, new Vector2(16f, -46f), new Vector2(220f, 24f), 13,
                new Color(0.66f, 0.72f, 0.82f, 1f), TextAnchor.MiddleLeft);

            float right = Screen.width / Mathf.Max(ScaleFactor, 0.0001f);
            MakeButton(parent, "✕ Close", new Vector2(right - 104f, -12f),
                new Vector2(88f, 30f), new Color(0.34f, 0.22f, 0.24f, 1f), CloseTraceView);
        }

        private string DebugStatus()
        {
            if (_debug == null || !_debug.IsRunning) return _debug != null && _debug.Reason == StopReason.Exited
                ? "program exited — Launch to restart" : "not started — press Launch";
            var cur = _debug.Current.Value;
            string name = _model.TryGet(cur.Element, out var el) ? el.Name : "?";
            return $"stopped ({_debug.Reason}) at {name}:{cur.Line} · stack {_debug.CallStack.Count}";
        }

        /// <summary>One bubble: the element's code as line rows with a breakpoint gutter and clickable call chips.</summary>
        private void BuildBubble(RectTransform parent, ElementId id, Vector2 topLeft, ICodeGraph graph)
        {
            _model.TryGet(id, out var el);
            string name = el != null ? el.Name : "?";

            var panel = new GameObject("Bubble", typeof(RectTransform));
            var pRt = (RectTransform)panel.transform;
            pRt.SetParent(parent, false);
            pRt.anchorMin = pRt.anchorMax = new Vector2(0f, 1f);
            pRt.pivot = new Vector2(0f, 1f);
            pRt.sizeDelta = new Vector2(TraceBubbleW, TraceBubbleH);
            pRt.anchoredPosition = topLeft;
            TheRobotDraft.Uml.Chrome.MacOsControlKit.ApplyPanel(panel.AddComponent<Image>(),
                new Color(0.13f, 0.15f, 0.19f, 1f));

            // Header: name + per-bubble actions (open in editor; close this bubble unless it is the root).
            MakeText(pRt, (el != null ? "«" + el.Kind + "»  " : "") + name, new Vector2(10f, -8f),
                new Vector2(TraceBubbleW - 150f, 22f), 15, new Color(0.92f, 0.95f, 1f, 1f), TextAnchor.MiddleLeft)
                .fontStyle = FontStyle.Bold;
            MakeButton(pRt, "✎ Edit code", new Vector2(TraceBubbleW - 138f, -8f), new Vector2(86f, 22f),
                new Color(0.20f, 0.42f, 0.52f, 1f), () => GenerateCodeForElement(id));
            if (id != _traceBubbles[0])
                MakeButton(pRt, "✕", new Vector2(TraceBubbleW - 44f, -8f), new Vector2(28f, 22f),
                    new Color(0.34f, 0.24f, 0.26f, 1f), () => { _traceBubbles.Remove(id); RebuildTraceWindow(); });

            // Scrollable code body of per-line rows.
            const float bodyTop = -40f, rowH = 16f, gutterW = 40f;
            float bodyH = TraceBubbleH - 48f;
            var vp = new GameObject("BubbleVp", typeof(RectTransform));
            var vpRt = (RectTransform)vp.transform;
            vpRt.SetParent(pRt, false);
            vpRt.anchorMin = new Vector2(0f, 1f); vpRt.anchorMax = new Vector2(1f, 1f);
            vpRt.pivot = new Vector2(0f, 1f);
            vpRt.sizeDelta = new Vector2(TraceBubbleW, bodyH);
            vpRt.anchoredPosition = new Vector2(0f, bodyTop);
            TheRobotDraft.Uml.Chrome.MacOsControlKit.ApplyScrollWell(vp.AddComponent<Image>());
            vp.AddComponent<RectMask2D>();
            var scroll = vp.AddComponent<ScrollRect>();
            scroll.horizontal = false; scroll.vertical = true; scroll.scrollSensitivity = 24f;
            scroll.movementType = ScrollRect.MovementType.Clamped;

            var body = new GameObject("BubbleBody", typeof(RectTransform));
            var bodyRt = (RectTransform)body.transform;
            bodyRt.SetParent(vpRt, false);
            bodyRt.anchorMin = new Vector2(0f, 1f); bodyRt.anchorMax = new Vector2(1f, 1f);
            bodyRt.pivot = new Vector2(0f, 1f);
            scroll.viewport = vpRt; scroll.content = bodyRt;

            string listing = TraceListingFor(id);
            var names = BuildNameIndex();
            var allCalls = CallSiteScanner.Scan(listing, id, names);
            var callsByLine = new Dictionary<int, List<CallSite>>();
            foreach (var cs in allCalls)
            {
                if (!callsByLine.TryGetValue(cs.Line, out var l)) { l = new List<CallSite>(); callsByLine[cs.Line] = l; }
                l.Add(cs);
            }

            var lines = listing.Replace("\r\n", "\n").Replace('\r', '\n').Split('\n');
            int shown = Mathf.Min(lines.Length, TraceMaxLines);

            // Current debug line (for highlight) when this bubble is the running frame.
            int currentLine = 0;
            if (_traceDebug && _debug != null && _debug.IsRunning && _debug.Current.HasValue
                && _debug.Current.Value.Element == id)
                currentLine = _debug.Current.Value.Line;

            float ry = 0f;
            for (int i = 0; i < shown; i++)
            {
                int lineNo = i + 1;
                BuildLineRow(bodyRt, id, lineNo, lines[i], ry, rowH, gutterW,
                    callsByLine.TryGetValue(lineNo, out var lineCalls) ? lineCalls : null,
                    lineNo == currentLine);
                ry -= rowH;
            }
            if (lines.Length > shown)
            {
                MakeText(bodyRt, $"… {lines.Length - shown} more lines (Edit code to view all)",
                    new Vector2(gutterW + 6f, ry), new Vector2(TraceBubbleW - gutterW - 12f, rowH), 12,
                    new Color(0.55f, 0.60f, 0.68f, 1f), TextAnchor.MiddleLeft);
                ry -= rowH;
            }
            bodyRt.sizeDelta = new Vector2(TraceBubbleW, Mathf.Max(bodyH, -ry + 8f));

            // Scroll the running line into view.
            if (currentLine > 0)
            {
                float contentH = Mathf.Max(bodyH, shown * rowH);
                float scrollable = Mathf.Max(0f, contentH - bodyH);
                if (scrollable > 0f)
                    scroll.verticalNormalizedPosition = 1f - Mathf.Clamp01((currentLine - 1) * rowH / scrollable);
            }
        }

        /// <summary>One code row: a clickable line-number gutter (toggles a breakpoint), the source text, and a clickable chip per callee.</summary>
        private void BuildLineRow(RectTransform parent, ElementId id, int lineNo, string text, float topY,
            float rowH, float gutterW, List<CallSite> calls, bool isCurrent)
        {
            if (isCurrent)
            {
                var hl = new GameObject("Cur", typeof(RectTransform));
                var hRt = (RectTransform)hl.transform;
                hRt.SetParent(parent, false);
                hRt.anchorMin = hRt.anchorMax = new Vector2(0f, 1f);
                hRt.pivot = new Vector2(0f, 1f);
                hRt.sizeDelta = new Vector2(TraceBubbleW, rowH);
                hRt.anchoredPosition = new Vector2(0f, topY);
                var img = hl.AddComponent<Image>();
                img.color = CurrentLineColor; img.raycastTarget = false;
            }

            // Gutter button: line number, with a red ● when a breakpoint is set on this line. Built inline (rather
            // than via MakeButton) so the label can be recolored red and sized small for the gutter.
            bool hasBp = _breakpoints.HasLine(id, lineNo);
            var gutterGo = new GameObject("Gutter", typeof(RectTransform));
            var gRt = (RectTransform)gutterGo.transform;
            gRt.SetParent(parent, false);
            gRt.anchorMin = gRt.anchorMax = new Vector2(0f, 1f);
            gRt.pivot = new Vector2(0f, 1f);
            gRt.sizeDelta = new Vector2(gutterW, rowH);
            gRt.anchoredPosition = new Vector2(0f, topY);
            var gImg = gutterGo.AddComponent<Image>();
            gImg.color = new Color(0.16f, 0.18f, 0.22f, 1f);
            var gBtn = gutterGo.AddComponent<Button>();
            gBtn.targetGraphic = gImg;
            int capturedLine = lineNo;
            gBtn.onClick.AddListener(() => { _breakpoints.Toggle(id, capturedLine); RebuildTraceWindow(); });
            MakeText(gRt, (hasBp ? "● " : "") + lineNo, Vector2.zero, new Vector2(gutterW - 2f, rowH), 11,
                hasBp ? BreakpointColor : new Color(0.46f, 0.50f, 0.58f, 1f), TextAnchor.MiddleRight);

            // Source text (reserve room on the right for call chips).
            int chipCount = calls != null ? Mathf.Min(DistinctTargets(calls).Count, 2) : 0;
            float chipsW = chipCount * 92f;
            float codeW = TraceBubbleW - gutterW - 8f - chipsW;
            MakeText(parent, text.Replace("\t", "    "), new Vector2(gutterW + 6f, topY),
                new Vector2(codeW, rowH), 12, new Color(0.82f, 0.86f, 0.92f, 1f), TextAnchor.MiddleLeft);

            // Call chips: one per distinct callee on this line → open that element as a bubble.
            if (chipCount > 0)
            {
                float cx = TraceBubbleW - chipsW - 4f;
                foreach (var target in DistinctTargets(calls))
                {
                    if (chipCount-- <= 0) break;
                    var tid = target;
                    string tname = _model.TryGet(tid, out var te) ? te.Name : "?";
                    MakeButton(parent, "→ " + Ellipsize(tname, 8), new Vector2(cx, topY),
                        new Vector2(88f, rowH), new Color(0.18f, 0.40f, 0.22f, 1f), () => OpenCallBubble(tid));
                    cx += 92f;
                }
            }
        }

        private static List<ElementId> DistinctTargets(List<CallSite> calls)
        {
            var seen = new List<ElementId>();
            foreach (var c in calls) if (!seen.Contains(c.Target)) seen.Add(c.Target);
            return seen;
        }

        /// <summary>Open a callee as the next bubble in the chain (or just refocus if already open).</summary>
        private void OpenCallBubble(ElementId target)
        {
            if (!_traceBubbles.Contains(target)) _traceBubbles.Add(target);
            RebuildTraceWindow();
        }

        // --- mode + debug sync ---

        private void ToggleTraceMode()
        {
            _traceDebug = !_traceDebug;
            if (_traceDebug)
            {
                _debug = new TraceDebugSession(new ModelCodeGraph(this), _breakpoints);
                _debug.Launch(_traceBubbles[0]);
                SyncTraceToCurrent();
                return;
            }
            _debug = null;
            RebuildTraceWindow();
        }

        /// <summary>Ensure the running frame's element is an open bubble, then rebuild so the highlight + status update.</summary>
        private void SyncTraceToCurrent()
        {
            if (_debug != null && _debug.IsRunning && _debug.Current.HasValue)
            {
                var el = _debug.Current.Value.Element;
                if (!_traceBubbles.Contains(el)) _traceBubbles.Add(el);
            }
            RebuildTraceWindow();
        }

        private void CloseTraceView()
        {
            _traceBubbles.Clear();
            _debug = null;
            _traceDebug = false;
            CloseMenu();
            _traceWindow = null;
        }
    }
}
