using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using TheRobotDraft.Authoring.Commands;
using TheRobotDraft.Authoring.Model;
using TheRobotDraft.Authoring.Rules;
using TheRobotDraft.Authoring.Seams;
using TheRobotDraft.Authoring.State;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// The interactive 2D UML editor harness. Builds an overlay canvas and drives the real
    /// <see cref="AuthoringController"/>: right-click / ctrl-click context menus add containment-filtered
    /// elements (§3.1), dragging a node's connect handle draws a relationship with a valid-kind type picker
    /// (§4.2/§4.4), and Ctrl/Cmd+Z / +Shift+Z undo and redo (§1). It is a desktop stand-in for the DOTS bubble
    /// renderer — the harness owns 2D positions; the real <see cref="IPacker"/> owns 3D placement (ADR-003).
    /// </summary>
    public sealed class UmlCanvas : MonoBehaviour
    {
        // Order kinds are offered in menus.
        private static readonly ElementKind[] AllKinds =
        {
            ElementKind.Package, ElementKind.Class, ElementKind.Interface,
            ElementKind.Enum, ElementKind.Struct, ElementKind.Function, ElementKind.Field,
        };
        private static readonly EdgeKind[] AllEdgeKinds =
        {
            EdgeKind.Association, EdgeKind.Dependency, EdgeKind.Generalization,
            EdgeKind.Realization, EdgeKind.Aggregation, EdgeKind.Composition,
        };

        private static readonly Color EdgeColor = new Color(0.67f, 0.72f, 0.82f, 1f);
        private static readonly Color ContainColor = new Color(0.32f, 0.36f, 0.42f, 1f);

        private Canvas _canvas;
        private RectTransform _root, _nodeLayer, _edgeLayer;
        private Font _font;

        private AuthoringModel _model;
        private AuthoringController _ctl;
        private UndoStack _history;

        private readonly Dictionary<ElementId, UmlNodeView> _nodes = new();
        private readonly Dictionary<ElementId, Vector2> _pos = new();
        private readonly List<EdgeBinding> _edges = new();
        private ElementId _selectedId = ElementId.None;

        // Link-drag state.
        private UmlNodeView _linkSource;
        private UmlEdgeView _tempLink;
        private UmlNodeView _hoverTarget;

        private GameObject _menu;
        private Text _hint;

        public float ScaleFactor => _canvas != null ? _canvas.scaleFactor : 1f;

        private struct EdgeBinding
        {
            public UmlEdgeView View;
            public ElementId From, To;
        }

        // --- lifecycle ---

        private void Awake()
        {
            _font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            BuildCanvas();
            NewWorld();
            RebuildFromModel();
        }

        private void NewWorld()
        {
            _model = new AuthoringModel();
            var ctx = new CommandContext(_model, new NullPacker(), new CountingIdFactory());
            _history = new UndoStack(ctx);
            _ctl = new AuthoringController(_model, _history);
            _selectedId = ElementId.None;
            _pos.Clear();
        }

        private void Update()
        {
            bool ctrl = CtrlOrCmd();
            bool shift = Input.GetKey(KeyCode.LeftShift) || Input.GetKey(KeyCode.RightShift);

            if (ctrl && Input.GetKeyDown(KeyCode.Z)) { if (shift) Redo(); else Undo(); }
            else if (ctrl && Input.GetKeyDown(KeyCode.Y)) Redo();
            else if (Input.GetKeyDown(KeyCode.Delete) || Input.GetKeyDown(KeyCode.Backspace)) DeleteSelected();
        }

        private void LateUpdate()
        {
            // Edges follow their endpoints as nodes are dragged.
            foreach (var b in _edges)
            {
                if (b.View == null) continue;
                if (_nodes.TryGetValue(b.From, out var f) && _nodes.TryGetValue(b.To, out var t))
                    b.View.SetEndpoints(f.Rt.anchoredPosition, t.Rt.anchoredPosition);
            }
            if (_tempLink != null && _linkSource != null)
            {
                Vector2 a = _linkSource.Rt.anchoredPosition;
                Vector2 bb = ScreenToLayer(Input.mousePosition);
                _tempLink.SetEndpoints(a, bb);
            }
        }

        // --- commands invoked by the views ---

        public void Select(UmlNodeView node)
        {
            CloseMenu();
            SetSelected(node != null ? node.Id : ElementId.None);
        }

        public void OnNodeMoved(ElementId id, Vector2 pos) => _pos[id] = pos;

        public void ShowNodeMenu(UmlNodeView node, Vector2 screenPos)
        {
            CloseMenu();
            SetSelected(node.Id);
            if (!_model.TryGet(node.Id, out var el)) return;

            var items = new List<MenuItem>();
            foreach (var k in AllKinds)
                if (ContainmentRules.CanContain(el.Kind, k).IsValid)
                {
                    var kind = k; var parent = node.Id;
                    items.Add(new MenuItem($"Add {k}", true, () => AddElement(parent, kind, screenPos)));
                }
            if (items.Count == 0)
                items.Add(new MenuItem("(nothing can nest here)", false, null));
            items.Add(MenuItem.Separator());
            var delId = node.Id;
            items.Add(new MenuItem("Delete", true, () => { _ctl.Delete(delId); SetSelected(ElementId.None); RebuildFromModel(); }));

            CreateMenu(screenPos, $"{el.Name} ({el.Kind})", items);
        }

        public void ShowEmptyMenu(Vector2 screenPos)
        {
            CloseMenu();
            SetSelected(ElementId.None);
            var items = new List<MenuItem>
            {
                new MenuItem("Add Package", true, () => AddElement(ElementId.None, ElementKind.Package, screenPos)),
            };
            CreateMenu(screenPos, "Canvas (root)", items);
        }

        private void AddElement(ElementId parent, ElementKind kind, Vector2 screenPos)
        {
            CloseMenu();
            _ctl.EnterAddNode(kind);
            var id = _ctl.CommitAddNode(parent, $"{kind}{CountOf(kind)}");
            if (!id.IsValid) { Flash("invalid placement"); _ctl.EnterSelect(); return; }
            _pos[id] = ScreenToLayer(screenPos);
            RebuildFromModel();
            SetSelected(id);
            Flash($"added {kind} — drag the cyan handle to link, right-click to add children");
        }

        // --- link drag (§4) ---

        public void BeginLink(UmlNodeView source, Vector2 screenPos)
        {
            CloseMenu();
            _linkSource = source;
            var go = new GameObject("TempLink", typeof(RectTransform));
            go.transform.SetParent(_edgeLayer, false);
            _tempLink = go.AddComponent<UmlEdgeView>();
            _tempLink.IsContainment = true; // non-clickable while dragging
            _tempLink.Init(_font, new Color(0.85f, 0.90f, 0.96f, 1f), null, null);
        }

        public void UpdateLink(Vector2 screenPos)
        {
            var target = NodeAt(screenPos, exclude: _linkSource);
            if (target != _hoverTarget)
            {
                if (_hoverTarget != null) _hoverTarget.SetAffordance(AffordanceTint.None);
                _hoverTarget = target;
            }
            if (target != null)
            {
                bool anyValid = AnyValidEdge(_linkSource.Id, target.Id);
                target.SetAffordance(anyValid ? AffordanceTint.Valid : AffordanceTint.Invalid);
            }
        }

        public void EndLink(Vector2 screenPos)
        {
            var target = NodeAt(screenPos, exclude: _linkSource);
            if (_hoverTarget != null) _hoverTarget.SetAffordance(AffordanceTint.None);
            if (_tempLink != null) Destroy(_tempLink.gameObject);
            _tempLink = null;
            _hoverTarget = null;

            var source = _linkSource;
            _linkSource = null;
            if (source == null || target == null || target.Id == source.Id) return;

            ShowTypePicker(source.Id, target.Id, screenPos);
        }

        private void ShowTypePicker(ElementId from, ElementId to, Vector2 screenPos)
        {
            CloseMenu();
            var items = new List<MenuItem>();
            foreach (var k in AllEdgeKinds)
            {
                var v = EdgeRules.CanConnect(_model, k, from, to);
                if (v.IsValid)
                {
                    var kind = k;
                    items.Add(new MenuItem(k.ToString(), true, () => Connect(from, to, kind)));
                }
            }
            if (items.Count == 0)
                items.Add(new MenuItem("(no valid relationship here)", false, null));
            CreateMenu(screenPos, "Link type", items);
        }

        private void Connect(ElementId from, ElementId to, EdgeKind kind)
        {
            CloseMenu();
            _ctl.EnterConnect(CommitStyle.OneShot, kind);
            _ctl.BeginConnect(from);
            var edge = _ctl.CommitConnect(to);
            if (edge.IsValid) Flash($"linked: {kind}");
            RebuildFromModel();
        }

        public void ShowEdgeMenu(UmlEdgeView edge, Vector2 screenPos)
        {
            if (!_model.TryGet(edge.Edge, out var e)) return;
            CloseMenu();
            var items = new List<MenuItem>();
            foreach (var k in AllEdgeKinds)
            {
                var v = EdgeRules.CanConnect(_model, k, e.From, e.To);
                if (v.IsValid)
                {
                    var kind = k; var edgeId = edge.Edge;
                    items.Add(new MenuItem(k.ToString() + (k == e.Kind ? "  ✓" : ""), true,
                        () => { _history.Execute(new ReTypeEdgeCommand(edgeId, kind)); CloseMenu(); RebuildFromModel(); }));
                }
            }
            items.Add(MenuItem.Separator());
            var delEdge = edge.Edge;
            items.Add(new MenuItem("Delete link", true,
                () => { _history.Execute(new DeleteEdgeShim(delEdge)); CloseMenu(); RebuildFromModel(); }));
            CreateMenu(screenPos, "Re-type / delete link", items);
        }

        public void OnBackgroundClick(PointerEventData e)
        {
            if (e.button == PointerEventData.InputButton.Right
                || (e.button == PointerEventData.InputButton.Left && CtrlOrCmd()))
                ShowEmptyMenu(e.position);
            else
            {
                CloseMenu();
                Select(null);
            }
        }

        // --- history ---

        private void Undo() { if (_ctl.Undo()) { Flash("↶ undo"); RebuildFromModel(); } }
        private void Redo() { if (_ctl.Redo()) { Flash("↷ redo"); RebuildFromModel(); } }
        private void DeleteSelected()
        {
            if (!_selectedId.IsValid) return;
            _ctl.Delete(_selectedId);
            SetSelected(ElementId.None);
            RebuildFromModel();
        }

        // --- view rebuild ---

        private void RebuildFromModel()
        {
            foreach (var nv in _nodes.Values) if (nv != null) Destroy(nv.gameObject);
            _nodes.Clear();
            foreach (var b in _edges) if (b.View != null) Destroy(b.View.gameObject);
            _edges.Clear();

            int spread = 0;
            foreach (var el in _model.Elements)
            {
                if (!_pos.TryGetValue(el.Id, out var p))
                {
                    p = new Vector2(-300f + (spread % 5) * 200f, 200f - (spread / 5) * 110f);
                    _pos[el.Id] = p;
                }
                spread++;
                CreateNodeView(el, p);
            }

            // Containment connectors (muted), then relationship edges (labelled).
            foreach (var el in _model.Elements)
                if (el.Parent.IsValid && _model.Contains(el.Parent))
                    CreateEdgeView(EdgeId.None, el.Parent, el.Id, ContainColor, null, isContainment: true);

            foreach (var edge in _model.Edges)
                CreateEdgeView(edge.Id, edge.From, edge.To, EdgeColor, edge.Kind.ToString(), isContainment: false);

            if (_selectedId.IsValid && _nodes.TryGetValue(_selectedId, out var sel)) sel.SetSelected(true);
        }

        private void CreateNodeView(ModelElement el, Vector2 pos)
        {
            var go = new GameObject("Node:" + el.Name, typeof(RectTransform));
            go.transform.SetParent(_nodeLayer, false);
            var nv = go.AddComponent<UmlNodeView>();
            ColorUtility.TryParseHtmlString(KindInfo.Hue(el.Kind), out var hue);
            nv.Init(this, el.Id, el.Name, el.Kind, hue, _font);
            nv.Rt.anchoredPosition = pos;
            _nodes[el.Id] = nv;
        }

        private void CreateEdgeView(EdgeId id, ElementId from, ElementId to, Color color, string label, bool isContainment)
        {
            var go = new GameObject(isContainment ? "Containment" : "Edge:" + label, typeof(RectTransform));
            go.transform.SetParent(_edgeLayer, false);
            var ev = go.AddComponent<UmlEdgeView>();
            ev.Edge = id;
            ev.IsContainment = isContainment;
            ev.Init(_font, color, label, ShowEdgeMenu);
            _edges.Add(new EdgeBinding { View = ev, From = from, To = to });
        }

        // --- helpers ---

        private void SetSelected(ElementId id)
        {
            if (_selectedId.IsValid && _nodes.TryGetValue(_selectedId, out var prev) && prev != null)
                prev.SetSelected(false);
            _selectedId = id;
            if (id.IsValid && _nodes.TryGetValue(id, out var nv) && nv != null) nv.SetSelected(true);
        }

        private bool AnyValidEdge(ElementId from, ElementId to)
        {
            foreach (var k in AllEdgeKinds)
                if (EdgeRules.CanConnect(_model, k, from, to).IsValid) return true;
            return false;
        }

        private int CountOf(ElementKind kind)
        {
            int n = 0;
            foreach (var e in _model.Elements) if (e.Kind == kind) n++;
            return n + 1;
        }

        private UmlNodeView NodeAt(Vector2 screenPos, UmlNodeView exclude)
        {
            UmlNodeView found = null;
            foreach (var nv in _nodes.Values)
            {
                if (nv == exclude) continue;
                if (RectTransformUtility.RectangleContainsScreenPoint(nv.Rt, screenPos, null))
                    found = nv; // last match = topmost sibling
            }
            return found;
        }

        private Vector2 ScreenToLayer(Vector2 screenPos)
        {
            RectTransformUtility.ScreenPointToLocalPointInRectangle(_nodeLayer, screenPos, null, out var local);
            return local;
        }

        public static bool CtrlOrCmd() =>
            Input.GetKey(KeyCode.LeftControl) || Input.GetKey(KeyCode.RightControl) ||
            Input.GetKey(KeyCode.LeftCommand) || Input.GetKey(KeyCode.RightCommand);

        private void Flash(string msg) { if (_hint != null) _hint.text = msg; }

        // --- canvas / menu construction ---

        private void BuildCanvas()
        {
            _canvas = gameObject.AddComponent<Canvas>();
            _canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            _canvas.sortingOrder = 32760;
            var scaler = gameObject.AddComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1920f, 1080f);
            scaler.matchWidthOrHeight = 0.5f;
            gameObject.AddComponent<GraphicRaycaster>();
            _root = (RectTransform)transform;

            // Background catcher for empty-canvas clicks.
            var bgGo = new GameObject("Background", typeof(RectTransform));
            var bgRt = (RectTransform)bgGo.transform;
            bgRt.SetParent(_root, false);
            Stretch(bgRt);
            var bgImg = bgGo.AddComponent<Image>();
            bgImg.color = new Color(0.07f, 0.08f, 0.10f, 1f);
            bgGo.AddComponent<UmlBackground>().Canvas = this;

            _edgeLayer = NewLayer("EdgeLayer");
            _nodeLayer = NewLayer("NodeLayer");

            // Header hint.
            var hintGo = new GameObject("Hint", typeof(RectTransform));
            var hintRt = (RectTransform)hintGo.transform;
            hintRt.SetParent(_root, false);
            hintRt.anchorMin = new Vector2(0f, 1f); hintRt.anchorMax = new Vector2(1f, 1f);
            hintRt.pivot = new Vector2(0f, 1f);
            hintRt.sizeDelta = new Vector2(0f, 40f);
            hintRt.anchoredPosition = new Vector2(16f, -8f);
            _hint = hintGo.AddComponent<Text>();
            _hint.font = _font;
            _hint.fontSize = 20;
            _hint.color = new Color(0.62f, 0.68f, 0.78f, 1f);
            _hint.alignment = TextAnchor.MiddleLeft;
            _hint.supportRichText = false;
            _hint.text = "Right-click empty → Add Package · right-click a node → add child / delete · " +
                         "drag the cyan handle → link · Ctrl/Cmd+Z undo, +Shift+Z redo · Del removes selection";
        }

        private RectTransform NewLayer(string name)
        {
            var go = new GameObject(name, typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(_root, false);
            Stretch(rt);
            return rt;
        }

        private static void Stretch(RectTransform rt)
        {
            rt.anchorMin = Vector2.zero; rt.anchorMax = Vector2.one;
            rt.offsetMin = Vector2.zero; rt.offsetMax = Vector2.zero;
        }

        private void CloseMenu() { if (_menu != null) Destroy(_menu); _menu = null; }

        private void CreateMenu(Vector2 screenPos, string header, List<MenuItem> items)
        {
            CloseMenu();
            const float w = 240f, ih = 32f, hh = 26f, pad = 6f;
            float h = hh + pad + items.Count * ih + pad;

            var go = new GameObject("Menu", typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(_root, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0f, 0f);
            rt.pivot = new Vector2(0f, 1f);
            rt.sizeDelta = new Vector2(w, h);
            rt.anchoredPosition = new Vector2(screenPos.x, screenPos.y) / ScaleFactor;
            go.AddComponent<Image>().color = new Color(0.12f, 0.14f, 0.17f, 0.98f);
            _menu = go;

            var head = MakeText(rt, header, new Vector2(10f, -4f), new Vector2(w - 20f, hh), 15,
                new Color(0.55f, 0.61f, 0.71f, 1f), TextAnchor.MiddleLeft);
            head.fontStyle = FontStyle.Bold;

            float y = -(hh + pad);
            foreach (var item in items)
            {
                if (item.IsSeparator) { y -= 6f; continue; }
                MakeMenuButton(rt, item, new Vector2(4f, y), new Vector2(w - 8f, ih));
                y -= ih;
            }
        }

        private void MakeMenuButton(RectTransform parent, MenuItem item, Vector2 topLeft, Vector2 size)
        {
            var go = new GameObject("Item", typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0f, 1f);
            rt.pivot = new Vector2(0f, 1f);
            rt.sizeDelta = size;
            rt.anchoredPosition = topLeft;

            var img = go.AddComponent<Image>();
            img.color = new Color(0.16f, 0.18f, 0.22f, item.Enabled ? 1f : 0.4f);

            if (item.Enabled && item.Action != null)
            {
                var btn = go.AddComponent<Button>();
                btn.targetGraphic = img;
                var act = item.Action;
                btn.onClick.AddListener(() => act());
            }

            MakeText(rt, item.Label, new Vector2(10f, 0f), new Vector2(size.x - 14f, size.y), 16,
                item.Enabled ? new Color(0.91f, 0.94f, 0.98f, 1f) : new Color(0.6f, 0.64f, 0.72f, 1f),
                TextAnchor.MiddleLeft);
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
            t.fontSize = fontSize;
            t.color = color;
            t.alignment = align;
            t.supportRichText = false;
            t.raycastTarget = false;
            return t;
        }

        private readonly struct MenuItem
        {
            public readonly string Label;
            public readonly bool Enabled;
            public readonly System.Action Action;
            public readonly bool IsSeparator;

            public MenuItem(string label, bool enabled, System.Action action)
            {
                Label = label; Enabled = enabled; Action = action; IsSeparator = false;
            }
            private MenuItem(bool sep) { Label = null; Enabled = false; Action = null; IsSeparator = sep; }
            public static MenuItem Separator() => new MenuItem(true);
        }
    }

    /// <summary>Full-canvas backdrop that routes empty-space clicks (add menu / deselect) to the canvas.</summary>
    public sealed class UmlBackground : MonoBehaviour, IPointerClickHandler
    {
        public UmlCanvas Canvas;
        public void OnPointerClick(PointerEventData eventData) => Canvas.OnBackgroundClick(eventData);
    }

    /// <summary>Deletes an edge by id as a single undo step (small command the controller doesn't expose directly).</summary>
    public sealed class DeleteEdgeShim : IAuthoringCommand
    {
        private readonly EdgeId _id;
        private EdgeKind _kind;
        private ElementId _from, _to;
        public DeleteEdgeShim(EdgeId id) => _id = id;
        public string Label => "Delete link";
        public void Do(CommandContext ctx)
        {
            var e = ctx.Model.Get(_id);
            _kind = e.Kind; _from = e.From; _to = e.To;
            ctx.Model.RemoveEdge(_id);
        }
        public void Undo(CommandContext ctx) => ctx.Model.AddEdge(_id, _kind, _from, _to);
    }
}
