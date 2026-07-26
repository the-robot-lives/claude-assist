using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Uml
{
    // =====================================================================
    // Integration seam. UmlCanvas implements both (see UmlCanvas.BrowseNav.cs).
    // Element-id based on purpose so it survives C0's per-diagram placement
    // becoming one-to-many: the v1 tree renders the CONTAINMENT hierarchy
    // ("where an element LIVES"); placement multiplicity ("where it APPEARS")
    // surfaces only via drag-created placements + the shared badge.
    // =====================================================================

    /// <summary>READ side: everything the tree needs to render + resolve drops.</summary>
    public interface IBrowseTreeSource
    {
        /// Top-level diagrams (top-level ElementKind.Package) in tab order.
        IEnumerable<ElementId> Diagrams { get; }

        /// Tree children under a node: pages (nested packages) + diagram nodes.
        /// Members (fields/operations) are excluded by the source so the tree is
        /// "diagrams -> packages -> nodes".
        IEnumerable<ElementId> ChildrenOf(ElementId id);

        bool TryGetElement(ElementId id, out ModelElement element);

        /// The diagram currently open on the canvas (TopLevelOf(_activePackage)).
        ElementId ActiveDiagram { get; }

        /// Containment owner (TopLevelOf) — the diagram in which an element LIVES (v1).
        ElementId OwningDiagramOf(ElementId id);

        /// Diagrams that currently PLACE this element (read over C0's PlacementStore).
        /// Drives the drag "already placed" guard and (via Count) the shared badge.
        IEnumerable<ElementId> DiagramsPlacing(ElementId element);

        /// Screen px -> model px (Y-up). The canvas owns the camera math.
        Vector2 ScreenToModel(Vector2 screenPos);
    }

    /// <summary>INTENT side: verbs the panel invokes; the canvas performs them.</summary>
    public interface IBrowseNavActions
    {
        void EditProperties(ElementId id);   // open the element's edit modal
        void RenameElement(ElementId id);    // name prompt -> _ctl.Rename -> rebuild
        void DeleteElement(ElementId id);    // _ctl.Delete -> rebuild
        void SelectAndFrame(ElementId id);   // go to its diagram + center camera
        void OpenDiagram(ElementId diagramId); // switch the active tab/diagram

        /// Build + show the row context menu on the canvas (it owns CreateMenu/MenuItem).
        void ShowRowMenu(ElementId id, bool isDiagram, Vector2 screenPos);

        /// THE C0 SEAM. Link an existing element into a diagram WITHOUT cloning.
        /// modelPos set = dropped on the canvas (Placement.At(pos)); null = dropped
        /// on a diagram row (canvas seeds a default position).
        void RequestPlacement(ElementId element, ElementId diagram, Vector2? modelPos);

        /// True when a drop at this screen point lands in the diagram viewport rather than on
        /// chrome (docks, bars). Guards drag-to-link the same way the palette drag is guarded.
        bool IsCanvasDropPoint(Vector2 screenPos);

        void Flash(string msg);
    }

    /// <summary>
    /// Right-rail outline of the whole model (Diagrams -> pages -> nodes). A plain
    /// view-builder (not a MonoBehaviour): it owns child GameObjects on the HUD
    /// overlay, built once via <see cref="Build"/> and re-rendered by
    /// <see cref="RebuildTree"/>. Selection is mirrored from the canvas through
    /// <see cref="RefreshSelection"/>. Structure/patterns mirror UmlCanvas.BuildPalette().
    /// </summary>
    public sealed class BrowseNavPanel
    {
        private const float RowH = 24f;
        private const float SearchH = 30f;
        private const float IndentPx = 14f;

        private readonly RectTransform _root;
        private readonly Font _font;
        private readonly IBrowseTreeSource _source;
        private readonly IBrowseNavActions _actions;
        private Canvas _canvas;

        private RectTransform _panel, _body, _content;
        private string _search = "";
        /// <summary>Effective width, supplied by the host panel at build time.</summary>
        private float _width;

        // Per-node disclosure state (keyed by ElementId; cf. palette's _paletteCollapsed by title).
        private readonly HashSet<ElementId> _expanded = new();
        // Row background image per element, for cheap selection highlight without a full rebuild.
        private readonly Dictionary<ElementId, Image> _rowBg = new();
        private ElementId _selected = ElementId.None;

        // Active drag (element being linked). Mirrors UmlCanvas._paletteGhost/_paletteDragKind.
        private GameObject _ghost;
        private ElementId _dragElement = ElementId.None;
        private ElementId _hoverRow = ElementId.None; // tree row under the cursor mid-drag (set by row Enter/Exit)

        public BrowseNavPanel(RectTransform root, Font font, IBrowseTreeSource source, IBrowseNavActions actions)
        {
            _root = root; _font = font; _source = source; _actions = actions;
        }

        private float Scale => _canvas != null ? _canvas.scaleFactor : 1f;

        // ---------------------------------------------------------------
        // Build — one-time, into the left palette's Outline tab.
        // ---------------------------------------------------------------
        /// <summary>
        /// Build the model tree into <paramref name="host"/> — the content area of the left
        /// palette's Outline tab (IA v2: "Left rail → Model Browser", panel tabs Files · Outline ·
        /// Recents). The host owns the panel surface, width, collapse state and tab visibility;
        /// this class owns only the filter box and the scrolling tree.
        /// </summary>
        public void Build(RectTransform host, float width)
        {
            _canvas = _root.GetComponentInParent<Canvas>();
            _width = width;

            var container = new GameObject("BrowseNav", typeof(RectTransform));
            _panel = (RectTransform)container.transform;
            _panel.SetParent(host, false);
            _panel.anchorMin = Vector2.zero; _panel.anchorMax = Vector2.one;
            _panel.offsetMin = Vector2.zero; _panel.offsetMax = Vector2.zero;
            _body = _panel; // the host already supplies the panel surface

            // Invisible but raycastable, so a wheel over blank tree area resolves to THIS
            // ScrollRect. Without it the event falls through to the palette's outer scroller,
            // whose content is empty on the Outline tab — the tree would simply refuse to scroll.
            var catcher = container.AddComponent<Image>();
            catcher.color = new Color(0f, 0f, 0f, 0f);
            catcher.raycastTarget = true;

            var search = MakeInput(_body, new Vector2(6f, -4f), _width - 12f, _search, "filter model…");
            ((RectTransform)search.transform).sizeDelta = new Vector2(_width - 12f, SearchH);
            search.onValueChanged.AddListener(v => { _search = v ?? ""; RebuildTree(); });

            var viewport = new GameObject("Viewport", typeof(RectTransform));
            var vrt = (RectTransform)viewport.transform;
            vrt.SetParent(_body, false);
            vrt.anchorMin = Vector2.zero; vrt.anchorMax = Vector2.one;
            vrt.pivot = new Vector2(0f, 1f);
            vrt.offsetMin = Vector2.zero;
            vrt.offsetMax = new Vector2(0f, -(SearchH + 8f)); // clear the filter box
            viewport.AddComponent<RectMask2D>();

            var scroll = container.AddComponent<ScrollRect>();
            scroll.horizontal = false; scroll.vertical = true;
            scroll.movementType = ScrollRect.MovementType.Clamped; scroll.scrollSensitivity = 26f;

            var contentGo = new GameObject("Content", typeof(RectTransform));
            _content = (RectTransform)contentGo.transform;
            _content.SetParent(vrt, false);
            _content.anchorMin = new Vector2(0f, 1f); _content.anchorMax = new Vector2(1f, 1f);
            _content.pivot = new Vector2(0.5f, 1f);
            _content.anchoredPosition = Vector2.zero;
            scroll.viewport = vrt; scroll.content = _content;

            RebuildTree();
        }

        // ---------------------------------------------------------------
        // RebuildTree — flatten Diagrams -> ChildrenOf DFS into rows.
        // Same shape as UmlCanvas.RebuildPaletteContent().
        // ---------------------------------------------------------------
        public void RebuildTree()
        {
            if (_content == null) return;
            for (int i = _content.childCount - 1; i >= 0; i--) Object.Destroy(_content.GetChild(i).gameObject);
            _rowBg.Clear();

            float y = -6f;
            string q = (_search ?? "").Trim();
            foreach (var diagram in _source.Diagrams)
                y = EmitNode(diagram, 0, true, q, y);

            if (_rowBg.Count == 0)
            {
                MakeText(_content, q.Length > 0 ? "no matches" : "no diagrams yet",
                    new Vector2(8f, y), new Vector2(_width - 16f, 22f), 13,
                    new Color(0.55f, 0.60f, 0.68f, 1f), TextAnchor.MiddleLeft).raycastTarget = false;
                y -= RowH;
            }
            _content.sizeDelta = new Vector2(0f, -y + 4f);
        }

        /// Emit one node + (if expanded / matching) its children. When filtering, a
        /// node shows if it or any descendant matches, and match paths force-expand.
        private float EmitNode(ElementId id, int depth, bool isDiagram, string q, float y)
        {
            if (!_source.TryGetElement(id, out var el)) return y;

            bool hasChildren = HasAnyChild(id);
            if (q.Length > 0 && !NameMatches(el, q) && !DescendantMatches(id, q)) return y;

            bool expanded = q.Length > 0 ? true : _expanded.Contains(id);
            MakeRow(id, el, depth, isDiagram, hasChildren, expanded, y);
            y -= RowH;

            if (hasChildren && expanded)
                foreach (var child in _source.ChildrenOf(id))
                    y = EmitNode(child, depth + 1, false, q, y);

            return y;
        }

        private void MakeRow(ElementId id, ModelElement el, int depth, bool isDiagram,
            bool hasChildren, bool expanded, float y)
        {
            var go = new GameObject("Row:" + (el.Name ?? "?"), typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(_content, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0f, 1f);
            rt.pivot = new Vector2(0f, 1f);
            rt.sizeDelta = new Vector2(_width - 10f, RowH - 1f);
            rt.anchoredPosition = new Vector2(4f, y);

            var bg = go.AddComponent<Image>();
            bg.color = RowColor(id, isDiagram);
            _rowBg[id] = bg;

            bool draggable = !isDiagram && KindInfo.IsDiagramNode(el.Kind) && !KindInfo.IsMember(el.Kind);
            var handler = go.AddComponent<UmlBrowseNavRow>();
            handler.Panel = this; handler.Id = id; handler.IsDiagram = isDiagram;
            handler.Label = el.Name; handler.Draggable = draggable;

            float x = depth * IndentPx + 4f;

            if (hasChildren)
            {
                MakeDisclosure(rt, expanded, x, id);
                x += 16f;
            }
            else x += 16f;

            // Shared badge: element placed in more than one diagram (derive from placement count for v1;
            // D's SharedElementBadge is a separate step and can replace this predicate later).
            string prefix = "";
            if (!isDiagram && IsShared(id)) prefix = "◆ ";

            var label = MakeText(rt, prefix + (el.Name ?? "?"), new Vector2(x + 4f, 0f),
                new Vector2(_width - x - 18f, RowH - 1f),
                TheRobotDraft.Uml.Chrome.ChromeMetrics.FontRow,
                isDiagram
                    ? TheRobotDraft.Uml.Chrome.ConceptDTheme.Text
                    : TheRobotDraft.Uml.Chrome.ConceptDTheme.TextDim,
                TextAnchor.MiddleLeft);
            if (isDiagram) label.fontStyle = FontStyle.Bold;
            label.raycastTarget = false;
        }

        private void MakeDisclosure(RectTransform parent, bool expanded, float x, ElementId id)
        {
            var go = new GameObject("Disclose", typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0f, 0.5f);
            rt.pivot = new Vector2(0f, 0.5f);
            rt.sizeDelta = new Vector2(16f, RowH - 3f);
            rt.anchoredPosition = new Vector2(x, 0f);
            var img = go.AddComponent<Image>();
            img.color = new Color(1f, 1f, 1f, 0.001f); // near-invisible but raycastable
            var btn = go.AddComponent<Button>();
            btn.targetGraphic = img;
            var cid = id;
            btn.onClick.AddListener(() => ToggleExpand(cid));
            MakeText(rt, expanded ? "▾" : "▸", Vector2.zero, new Vector2(16f, RowH - 3f), 12,
                new Color(0.6f, 0.66f, 0.74f, 1f), TextAnchor.MiddleCenter).raycastTarget = false;
        }

        public void ToggleExpand(ElementId id)
        {
            if (!_expanded.Remove(id)) _expanded.Add(id);
            RebuildTree();
        }

        // ---------------------------------------------------------------
        // Row events (called from UmlBrowseNavRow).
        // ---------------------------------------------------------------
        public void OnRowClick(ElementId id, bool isDiagram, PointerEventData e)
        {
            if (e.button == PointerEventData.InputButton.Right
                || (e.button == PointerEventData.InputButton.Left && UmlCanvas.CtrlOrCmd()))
            { _actions.ShowRowMenu(id, isDiagram, e.position); return; }

            if (isDiagram) _actions.OpenDiagram(id);
            else _actions.SelectAndFrame(id);
        }

        // ---------------------------------------------------------------
        // Drag-drop LINK (mirrors UmlCanvas.BeginPaletteDrag/Update/End).
        // ---------------------------------------------------------------
        public void BeginDrag(ElementId id, string label)
        {
            _dragElement = id; _hoverRow = ElementId.None;
            if (_ghost != null) Object.Destroy(_ghost);
            _ghost = MakeGhost(string.IsNullOrEmpty(label) ? "link" : label);
        }

        public void UpdateDrag(Vector2 screenPos)
        {
            if (_ghost != null)
                ((RectTransform)_ghost.transform).anchoredPosition = screenPos / Mathf.Max(Scale, 0.0001f);
        }

        public void SetHoverRow(ElementId id) => _hoverRow = id;
        public void ClearHoverRow(ElementId id) { if (_hoverRow == id) _hoverRow = ElementId.None; }

        public void EndDrag(Vector2 screenPos)
        {
            if (_ghost != null) { Object.Destroy(_ghost); _ghost = null; }
            if (!_dragElement.IsValid) return;
            var element = _dragElement; _dragElement = ElementId.None;

            // Dropped on a tree row: only a DIAGRAM row is a valid link target (no pos).
            if (_hoverRow.IsValid)
            {
                if (IsDiagramId(_hoverRow)) TryPlace(element, _hoverRow, null);
                else _actions.Flash("drop on a diagram or the canvas to link");
                return;
            }

            // Dropped off the tree: only the diagram viewport is a valid target. Without this the
            // drop would land on chrome (tab strip, filter box, status bar) and still place the
            // element at a model coordinate sitting behind the dock.
            if (!_actions.IsCanvasDropPoint(screenPos))
            {
                _actions.Flash("drop on a diagram row or the canvas to link");
                return;
            }

            // Place into the ACTIVE diagram at the drop point.
            if (_source.ActiveDiagram.IsValid)
                TryPlace(element, _source.ActiveDiagram, _source.ScreenToModel(screenPos));
        }

        /// Honor the (diagram,element) uniqueness rule: no-op + Flash if already placed there.
        private void TryPlace(ElementId element, ElementId diagram, Vector2? modelPos)
        {
            if (AlreadyPlaced(element, diagram)) { _actions.Flash("already placed here"); return; }
            _actions.RequestPlacement(element, diagram, modelPos);
        }

        // ---------------------------------------------------------------
        // Selection sync (canvas -> panel), from UmlCanvas.SetSelected.
        // ---------------------------------------------------------------
        public void RefreshSelection(ElementId selected)
        {
            if (_rowBg.TryGetValue(_selected, out var prev) && prev != null)
                prev.color = RowColor(_selected, IsDiagramId(_selected));
            _selected = selected;
            if (_rowBg.TryGetValue(_selected, out var now) && now != null)
                now.color = TheRobotDraft.Uml.Chrome.ConceptDTheme.SelectionRow;
        }

        // ---------------------------------------------------------------
        // small helpers (mirrored from UmlCanvas's palette rig)
        // ---------------------------------------------------------------
        private bool HasAnyChild(ElementId id) { foreach (var _ in _source.ChildrenOf(id)) return true; return false; }

        private static bool NameMatches(ModelElement el, string q) =>
            (el.Name ?? "").IndexOf(q, System.StringComparison.OrdinalIgnoreCase) >= 0;

        private bool DescendantMatches(ElementId id, string q)
        {
            foreach (var c in _source.ChildrenOf(id))
                if (_source.TryGetElement(c, out var ce) && (NameMatches(ce, q) || DescendantMatches(c, q)))
                    return true;
            return false;
        }

        private bool IsDiagramId(ElementId id)
        {
            if (!id.IsValid) return false;
            foreach (var d in _source.Diagrams) if (d == id) return true;
            return false;
        }

        private bool AlreadyPlaced(ElementId element, ElementId diagram)
        { foreach (var d in _source.DiagramsPlacing(element)) if (d == diagram) return true; return false; }

        private bool IsShared(ElementId element)
        {
            int n = 0;
            foreach (var _ in _source.DiagramsPlacing(element)) if (++n > 1) return true;
            return false;
        }

        /// <summary>
        /// Row fill. Must stay distinct from the host panel surface (<c>ConceptDTheme.Panel</c>) —
        /// the tree now sits inside the left palette, which paints that same color, so tinting
        /// rows with Panel would render them invisible.
        /// </summary>
        private Color RowColor(ElementId id, bool isDiagram) => id == _selected
            ? TheRobotDraft.Uml.Chrome.ConceptDTheme.SelectionRow
            : isDiagram
                ? TheRobotDraft.Uml.Chrome.ConceptDTheme.Bg3
                : TheRobotDraft.Uml.Chrome.ConceptDTheme.MenuRow;

        private GameObject MakeGhost(string label)
        {
            var go = new GameObject("BrowseGhost", typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(_root, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0f, 0f);
            rt.pivot = new Vector2(0.5f, 0.5f);
            rt.sizeDelta = new Vector2(150f, 26f);
            var img = go.AddComponent<Image>();
            img.color = new Color(0.20f, 0.45f, 0.65f, 0.85f);
            img.raycastTarget = false;
            var tgo = new GameObject("L", typeof(RectTransform));
            var trt = (RectTransform)tgo.transform;
            trt.SetParent(rt, false);
            trt.anchorMin = Vector2.zero; trt.anchorMax = Vector2.one;
            trt.offsetMin = Vector2.zero; trt.offsetMax = Vector2.zero;
            var tx = tgo.AddComponent<Text>();
            tx.font = _font; tx.text = "link  " + label; tx.fontSize = 13; tx.alignment = TextAnchor.MiddleCenter;
            tx.color = new Color(0.96f, 0.98f, 1f, 1f); tx.raycastTarget = false;
            return go;
        }

        private Text MakeText(RectTransform parent, string text, Vector2 topLeft, Vector2 size, int fontSize,
            Color color, TextAnchor align)
        {
            var go = new GameObject("Text", typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0f, 1f);
            rt.pivot = new Vector2(0f, 1f);
            rt.sizeDelta = size;
            rt.anchoredPosition = topLeft;
            var t = go.AddComponent<Text>();
            t.font = _font;
            t.text = text;
            t.fontSize = TheRobotDraft.Uml.Chrome.UiPrefs.ScaleFont(fontSize); // user font-size pref
            t.color = color;
            t.alignment = align;
            t.supportRichText = false; t.raycastTarget = false;
            return t;
        }

        private InputField MakeInput(RectTransform parent, Vector2 topLeft, float width, string value, string placeholder)
        {
            var inputGo = new GameObject("Input", typeof(RectTransform));
            var inRt = (RectTransform)inputGo.transform;
            inRt.SetParent(parent, false);
            inRt.anchorMin = inRt.anchorMax = new Vector2(0f, 1f);
            inRt.pivot = new Vector2(0f, 1f);
            inRt.sizeDelta = new Vector2(width, 32f);
            inRt.anchoredPosition = topLeft;
            var fieldImg = inputGo.AddComponent<Image>();
            TheRobotDraft.Uml.Chrome.MacOsControlKit.ApplyTextField(fieldImg);
            var input = inputGo.AddComponent<InputField>();

            var textComp = MakeText(inRt, "", new Vector2(8f, 0f), new Vector2(width - 16f, 32f), 15,
                new Color(0.96f, 0.97f, 1f, 1f), TextAnchor.MiddleLeft);
            textComp.raycastTarget = true;
            var ph = MakeText(inRt, placeholder ?? "", new Vector2(8f, 0f), new Vector2(width - 16f, 32f), 15,
                new Color(0.5f, 0.55f, 0.62f, 1f), TextAnchor.MiddleLeft);
            ph.fontStyle = FontStyle.Italic;

            input.textComponent = textComp;
            input.placeholder = ph;
            input.lineType = InputField.LineType.SingleLine;
            input.text = value ?? "";
            return input;
        }
    }

    /// <summary>
    /// Per-row pointer handler: left-click (open/frame), right/ctrl-click (menu),
    /// drag-to-link, and hover tracking so a drop can resolve the diagram row under
    /// the cursor. Mirrors UmlPaletteItem. Drag events fire on the drag SOURCE row;
    /// Enter/Exit on the rows the cursor passes over update the panel's hover target.
    /// </summary>
    public sealed class UmlBrowseNavRow : MonoBehaviour,
        IPointerClickHandler, IBeginDragHandler, IDragHandler, IEndDragHandler,
        IPointerEnterHandler, IPointerExitHandler
    {
        public BrowseNavPanel Panel;
        public ElementId Id;
        public bool IsDiagram;
        public bool Draggable;
        public string Label;

        public void OnPointerClick(PointerEventData e) => Panel.OnRowClick(Id, IsDiagram, e);

        public void OnBeginDrag(PointerEventData e) { if (Draggable) Panel.BeginDrag(Id, Label); }
        public void OnDrag(PointerEventData e) { if (Draggable) Panel.UpdateDrag(e.position); }
        public void OnEndDrag(PointerEventData e) { if (Draggable) Panel.EndDrag(e.position); }

        public void OnPointerEnter(PointerEventData e) { if (e.dragging) Panel.SetHoverRow(Id); }
        public void OnPointerExit(PointerEventData e) { if (e.dragging) Panel.ClearHoverRow(Id); }
    }
}
