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
    /// The interactive standard-UML editor harness. A tab bar selects the active package; the canvas shows
    /// that package's classifiers as UML boxes with member compartments (fields/methods inside). Right-click /
    /// ctrl-click adds containment-filtered elements (§3.1) with a name prompt (§3.5); dragging a node's
    /// connect handle draws a relationship with a valid-kind type picker and proper UML arrowheads
    /// (§4.2/§4.4); boxes drag to move and resize from the corner grip; Ctrl/Cmd+Z / +Shift+Z undo/redo (§1).
    /// Desktop stand-in for the DOTS bubble renderer — the harness owns 2D layout, the real packer owns 3D
    /// (ADR-003). The authoring core (model/rules/commands/controller) is reused unchanged.
    /// </summary>
    public sealed partial class UmlCanvas : MonoBehaviour
    {
        private static readonly EdgeKind[] AllEdgeKinds =
        {
            EdgeKind.Association, EdgeKind.Dependency, EdgeKind.Generalization,
            EdgeKind.Realization, EdgeKind.Aggregation, EdgeKind.Composition,
        };
        // Classifier kinds offered when adding into a package.
        private static readonly ElementKind[] ClassifierKinds =
        {
            ElementKind.Class, ElementKind.Interface, ElementKind.Enum, ElementKind.Struct,
        };

        private static readonly Color EdgeColor = new Color(0.28f, 0.30f, 0.36f, 1f);

        private Canvas _canvas;
        private RectTransform _root, _nodeLayer, _edgeLayer, _tabBar;
        private Font _font;
        private Text _hint;

        private AuthoringModel _model;
        private AuthoringController _ctl;
        private UndoStack _history;

        private readonly Dictionary<ElementId, UmlNodeView> _nodes = new();
        private readonly Dictionary<ElementId, Vector2> _pos = new();
        private readonly Dictionary<ElementId, Vector2> _size = new();
        private readonly List<EdgeBinding> _edges = new();
        private ElementId _activePackage = ElementId.None;
        private ElementId _selectedId = ElementId.None;

        // Orthogonal-route view-state (geometry is not the model's job, ADR-003): per-edge interior bend points
        // in layer-local coords. Empty/absent → auto-routed. Plus the selected edge and its live bend handles.
        private readonly Dictionary<EdgeId, List<Vector2>> _waypoints = new();
        // Fixed endpoint attachments (which side of the box + position along it). Absent → auto facing-side.
        private readonly Dictionary<EdgeId, EndAnchor> _srcAnchor = new();
        private readonly Dictionary<EdgeId, EndAnchor> _tgtAnchor = new();
        private readonly List<UmlEdgeHandle> _bendHandles = new();
        private RectTransform _handleLayer;
        private EdgeId _selectedEdge = EdgeId.None;

        // Active edge-handle drag (endpoint reposition or vertex move).
        private EdgeId _hEdge = EdgeId.None;
        private UmlHandleKind _hKind;
        private int _hIndex;

        // Pending anchors captured during a link drag, applied to the edge once it is created.
        private BoxSide _linkSide;
        private BoxSide _pendingSrcSide;
        private EndAnchor _pendingTgtAnchor;

        private const float StubLen = 22f;

        // Edges drawn as smooth curves instead of right-angle polylines (view-state).
        private readonly HashSet<EdgeId> _curved = new();

        // Copy/paste clipboard: a deep snapshot of one element + its members.
        private ClipElement _clipboard;

        /// <summary>A fixed endpoint attachment: a side of the box and a 0..1 position along that side.</summary>
        private struct EndAnchor
        {
            public BoxSide Side;
            public float T;
            public EndAnchor(BoxSide side, float t) { Side = side; T = t; }
        }

        private sealed class ClipMember { public ElementKind Kind; public string Name; }
        private sealed class ClipElement
        {
            public ElementKind Kind;
            public string Name, Language, Stereotype;
            public bool IsAbstract, HasPos;
            public Vector2 Pos;
            public readonly List<ClipMember> Members = new();
        }

        private UmlNodeView _linkSource;
        private UmlEdgeView _tempLink;
        private UmlNodeView _hoverTarget;

        private GameObject _menu;

        // Diagram zoom (mouse wheel / Ctrl +/-/0). Scales the node+edge layers around the canvas center.
        private float _zoom = 1f;
        private const float MinZoom = 0.3f, MaxZoom = 3f;

        public float ScaleFactor => _canvas != null ? _canvas.scaleFactor : 1f;

        /// <summary>Diagram zoom factor (1 = 100%). Pointer-delta math multiplies by this so drags track the cursor.</summary>
        public float Zoom => _zoom;

        private struct EdgeBinding { public UmlEdgeView View; public ElementId From, To; }

        // --- lifecycle ---

        private void Awake()
        {
            _font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            BuildCanvas();
            // Restore the saved diagram if present, else open the sample.
            if (!LoadDiagram())
            {
                NewWorld();
                SeedSample();
                RebuildFromModel();
            }
        }

        private void OnApplicationQuit() => SaveDiagram();

        /// <summary>Initial sample so the editor opens showing standard UML. Fully removable (undo / delete).</summary>
        private void SeedSample()
        {
            _ctl.EnterAddNode(ElementKind.Package);
            var pkg = _ctl.CommitAddNode(ElementId.None, "Domain");
            _activePackage = pkg;

            ElementId Add(ElementKind k, ElementId parent, string name)
            {
                _ctl.EnterAddNode(k);
                return _ctl.CommitAddNode(parent, name);
            }

            var order = Add(ElementKind.Class, pkg, "Order");
            _pos[order] = new Vector2(-250f, 30f);
            _ctl.SetMeta(order, "C#", null);
            Add(ElementKind.Field, order, "- id : Guid");
            Add(ElementKind.Field, order, "- total : decimal");
            Add(ElementKind.Function, order, "+ submit() : void");

            var payable = Add(ElementKind.Interface, pkg, "Payable");
            _pos[payable] = new Vector2(230f, 60f);
            _ctl.SetMeta(payable, "C#", null);
            Add(ElementKind.Function, payable, "+ amountDue() : decimal");

            var note = Add(ElementKind.Note, pkg, "Order is immutable once submitted;\npayment must clear first.");
            _pos[note] = new Vector2(250f, -150f);

            var customer = Add(ElementKind.Class, pkg, "Customer");
            _pos[customer] = new Vector2(-250f, -200f);
            _ctl.SetMeta(customer, "C#", null);
            Add(ElementKind.Field, customer, "- name : string");
            Add(ElementKind.Field, customer, "- active : bool");

            // Association Customer 1 ── places ──> 0..* Order (multiplicities + role label).
            _ctl.EnterConnect(CommitStyle.OneShot, EdgeKind.Association);
            _ctl.BeginConnect(customer);
            var places = _ctl.CommitConnect(order);
            _ctl.SetEdgeMeta(places, "places", "1", "0..*");

            _ctl.EnterConnect(CommitStyle.OneShot, EdgeKind.Realization);
            _ctl.BeginConnect(order);
            _ctl.CommitConnect(payable);
            _ctl.EnterSelect();
        }

        private void NewWorld()
        {
            _model = new AuthoringModel();
            var ctx = new CommandContext(_model, new NullPacker(), new CountingIdFactory());
            _history = new UndoStack(ctx);
            _ctl = new AuthoringController(_model, _history);
            _activePackage = _selectedId = ElementId.None;
            _selectedEdge = EdgeId.None;
            _pos.Clear(); _size.Clear();
            _waypoints.Clear(); _srcAnchor.Clear(); _tgtAnchor.Clear(); _curved.Clear();
            _pan = Vector2.zero; ApplyPan();
        }

        /// <summary>Start an empty diagram (no undo of the previous one).</summary>
        public void NewDiagram()
        {
            CloseMenu();
            NewWorld();           // fresh model + empty history
            RebuildFromModel();
            Flash("new empty diagram");
        }

        /// <summary>Discard the current diagram and reopen the built-in sample (not undoable).</summary>
        public void ResetToSample()
        {
            CloseMenu();
            NewWorld();
            SeedSample();
            _ctl.ClearHistory();  // reset is not an undoable edit
            RebuildFromModel();
            Flash("reset to sample");
        }

        // --- copy / paste (with rename) ---

        public void CopyElement(ElementId id)
        {
            CloseMenu();
            if (!_model.TryGet(id, out var el)) return;
            var clip = new ClipElement
            {
                Kind = el.Kind, Name = el.Name, Language = el.Language,
                Stereotype = el.Stereotype, IsAbstract = el.IsAbstract,
            };
            if (_pos.TryGetValue(id, out var p)) { clip.Pos = p; clip.HasPos = true; }
            foreach (var cid in el.ChildIds)
                if (_model.TryGet(cid, out var c) && KindInfo.IsMember(c.Kind))
                    clip.Members.Add(new ClipMember { Kind = c.Kind, Name = c.Name });
            _clipboard = clip;
            Flash("copied " + el.Kind + " — Ctrl/Cmd+V to paste");
        }

        public void PasteElement()
        {
            CloseMenu();
            if (_clipboard == null) { Flash("clipboard empty"); return; }
            if (!_activePackage.IsValid) { Flash("no package to paste into"); return; }
            var c = _clipboard;

            _ctl.EnterAddNode(c.Kind);
            var nid = _ctl.CommitAddNode(_activePackage, UniqueName(c.Name));
            if (!nid.IsValid) { Flash("paste not allowed here"); _ctl.EnterSelect(); return; }
            if (c.IsAbstract) _ctl.SetAbstract(nid, true);
            if (!string.IsNullOrEmpty(c.Language) || !string.IsNullOrEmpty(c.Stereotype))
                _ctl.SetMeta(nid, c.Language, c.Stereotype);
            foreach (var m in c.Members)
            {
                _ctl.EnterAddNode(m.Kind);
                _ctl.CommitAddNode(nid, m.Name);
            }
            _ctl.EnterSelect();
            _pos[nid] = c.HasPos ? c.Pos + new Vector2(34f, -34f) : Vector2.zero;
            RebuildFromModel();
            SetSelected(nid);
            Flash("pasted (renamed)");
        }

        private string UniqueName(string baseName)
        {
            // Notes hold freeform text → tag "(copy)"; classifiers get a deduped "Copy" suffix.
            bool freeform = string.IsNullOrEmpty(baseName) || baseName.Contains("\n") || baseName.Length > 24;
            string candidate = baseName + (freeform ? " (copy)" : "Copy");
            int n = 2;
            while (NameExistsInActive(candidate)) candidate = baseName + "Copy" + n++;
            return candidate;
        }

        private bool NameExistsInActive(string name)
        {
            foreach (var el in _model.Elements)
                if (el.Parent == _activePackage && el.Name == name) return true;
            return false;
        }

        private void Update()
        {
            if (Input.GetKeyDown(KeyCode.Escape)) { CloseMenu(); return; }

            // Don't steal typing from the name prompt.
            if (EventSystem.current != null && EventSystem.current.currentSelectedGameObject != null
                && EventSystem.current.currentSelectedGameObject.GetComponent<InputField>() != null)
                return;

            bool ctrl = CtrlOrCmd();
            bool shift = Input.GetKey(KeyCode.LeftShift) || Input.GetKey(KeyCode.RightShift);
            if (ctrl && Input.GetKeyDown(KeyCode.S)) { SaveDiagram(); return; }
            if (ctrl && Input.GetKeyDown(KeyCode.C)) { if (_selectedId.IsValid) CopyElement(_selectedId); return; }
            if (ctrl && Input.GetKeyDown(KeyCode.V)) { PasteElement(); return; }
            if (ctrl && Input.GetKeyDown(KeyCode.Z)) { if (shift) Redo(); else Undo(); }
            else if (ctrl && Input.GetKeyDown(KeyCode.Y)) Redo();
            else if (Input.GetKeyDown(KeyCode.Delete) || Input.GetKeyDown(KeyCode.Backspace)) DeleteSelected();

            // Zoom: mouse wheel anywhere on the canvas, or Ctrl/Cmd +/- ; Ctrl/Cmd+0 resets to 100%.
            float scroll = Input.mouseScrollDelta.y;
            if (Mathf.Abs(scroll) > 0.01f) SetZoom(_zoom * (1f + scroll * 0.1f));
            else if (ctrl && (Input.GetKeyDown(KeyCode.Equals) || Input.GetKeyDown(KeyCode.KeypadPlus))) SetZoom(_zoom * 1.1f);
            else if (ctrl && (Input.GetKeyDown(KeyCode.Minus) || Input.GetKeyDown(KeyCode.KeypadMinus))) SetZoom(_zoom / 1.1f);
            else if (ctrl && (Input.GetKeyDown(KeyCode.Alpha0) || Input.GetKeyDown(KeyCode.Keypad0))) SetZoom(1f);
        }

        // --- pan (drag empty canvas to scroll the diagram) ---

        private Vector2 _pan;

        public void BeginPan() => CloseMenu();

        public void PanBy(Vector2 screenDelta)
        {
            _pan += screenDelta / Mathf.Max(ScaleFactor, 0.0001f);
            ApplyPan();
        }

        private void ApplyPan()
        {
            SetLayerOffset(_nodeLayer);
            SetLayerOffset(_edgeLayer);
            SetLayerOffset(_handleLayer);
        }

        private void SetLayerOffset(RectTransform rt)
        {
            if (rt != null) { rt.offsetMin = _pan; rt.offsetMax = _pan; }
        }

        /// <summary>Apply a clamped zoom to both layers. Scales around the canvas center (v1; cursor-anchored later).</summary>
        private void SetZoom(float z)
        {
            float clamped = Mathf.Clamp(z, MinZoom, MaxZoom);
            if (Mathf.Approximately(clamped, _zoom)) return;
            _zoom = clamped;
            var s = new Vector3(_zoom, _zoom, 1f);
            if (_nodeLayer != null) _nodeLayer.localScale = s;
            if (_edgeLayer != null) _edgeLayer.localScale = s;
            if (_handleLayer != null) _handleLayer.localScale = s;
            Flash($"zoom {_zoom * 100f:0}%  ·  Ctrl/Cmd +/− , 0 to reset");
        }

        private void LateUpdate()
        {
            foreach (var b in _edges)
            {
                if (b.View == null) continue;
                if (_nodes.ContainsKey(b.From) && _nodes.ContainsKey(b.To))
                    b.View.SetRoute(RouteEdge(b.From, b.To, b.View.Edge));
            }
            if (_tempLink != null && _linkSource != null)
            {
                Vector2 start = AnchorPoint(_linkSource.Rt.anchoredPosition, _linkSource.Rt.sizeDelta,
                    new EndAnchor(_linkSide, 0.5f));
                _tempLink.SetRoute(new List<Vector2> { start, ScreenToLayer(Input.mousePosition) });
            }

            PositionBendHandles();
        }

        // --- selection / movement / resize ---

        public void Select(UmlNodeView node) { CloseMenu(); ClearSelectedEdge(); SetSelected(node != null ? node.Id : ElementId.None); }
        public void OnNodeMoved(ElementId id, Vector2 pos) => _pos[id] = pos;
        public void OnNodeResized(ElementId id, Vector2 size) => _size[id] = size;

        // --- context menus ---

        public void ShowNodeMenu(UmlNodeView node, Vector2 screenPos)
        {
            CloseMenu();
            SetSelected(node.Id);
            if (!_model.TryGet(node.Id, out var el)) return;

            if (el.Kind == ElementKind.Note)
            {
                var noteId = node.Id; var noteParent = el.Parent;
                var noteItems = new List<MenuItem>
                {
                    new MenuItem("Edit text…", true, () => ShowNoteEditor(noteParent, noteId, screenPos)),
                    new MenuItem("Copy", true, () => CopyElement(noteId)),
                    MenuItem.Separator(),
                    new MenuItem("Delete", true,
                        () => { _ctl.Delete(noteId); SetSelected(ElementId.None); RebuildFromModel(); }),
                };
                CreateMenu(screenPos, "Note", noteItems);
                return;
            }

            var items = new List<MenuItem>();
            // Members live inside the box: offer the legal member kinds via the structured editor (Rose/Sparx).
            foreach (var k in new[] { ElementKind.Field, ElementKind.Function })
                if (ContainmentRules.CanContain(el.Kind, k).IsValid)
                {
                    var kind = k; var parent = node.Id;
                    string verb = k == ElementKind.Field ? "＋ Attribute (field)…" : "＋ Operation (method)…";
                    items.Add(new MenuItem(verb, true, () => ShowMemberEditor(parent, kind, ElementId.None, screenPos)));
                }

            // Existing members — edit signature in place (visibility / type / params / return).
            bool anyMember = false;
            foreach (var childId in el.ChildIds)
            {
                if (!_model.TryGet(childId, out var c) || !KindInfo.IsMember(c.Kind)) continue;
                if (!anyMember) { items.Add(MenuItem.Separator()); anyMember = true; }
                var cid = childId; var ckind = c.Kind; var parent = node.Id;
                items.Add(new MenuItem("✎  " + Ellipsize(c.Name, 30), true,
                    () => ShowMemberEditor(parent, ckind, cid, screenPos)));
            }

            items.Add(MenuItem.Separator());
            var pid = node.Id;
            items.Add(new MenuItem("Edit element…  (fields · operations · properties)", true,
                () => ShowClassifierEditor(pid, screenPos)));
            items.Add(new MenuItem("Copy  (Ctrl/Cmd+C)", true, () => CopyElement(pid)));
            items.Add(new MenuItem("Delete", true,
                () => { _ctl.Delete(pid); SetSelected(ElementId.None); RebuildFromModel(); }));

            CreateMenu(screenPos, $"{el.Name} ({el.Kind})", items);
        }

        public void ShowEmptyMenu(Vector2 screenPos)
        {
            CloseMenu();
            SetSelected(ElementId.None);
            var items = new List<MenuItem>();
            if (_activePackage.IsValid)
            {
                foreach (var k in ClassifierKinds)
                {
                    var kind = k;
                    items.Add(new MenuItem($"Add {k}", true, () => PromptAndAdd(_activePackage, kind, screenPos)));
                }
                items.Add(new MenuItem("Add Note", true, () => ShowNoteEditor(_activePackage, ElementId.None, screenPos)));
            }
            else
            {
                items.Add(new MenuItem("Add Package", true,
                    () => PromptAndAdd(ElementId.None, ElementKind.Package, screenPos)));
            }

            // Document actions.
            items.Add(MenuItem.Separator());
            if (_clipboard != null && _activePackage.IsValid)
                items.Add(new MenuItem("Paste  (Ctrl/Cmd+V)", true, () => PasteElement()));
            items.Add(new MenuItem("New (empty diagram)", true, () => NewDiagram()));
            items.Add(new MenuItem("Reset to sample", true, () => ResetToSample()));
            items.Add(new MenuItem("Save  (Ctrl/Cmd+S)", true, () => { CloseMenu(); SaveDiagram(); }));
            items.Add(new MenuItem("Delete saved file", true, () => { CloseMenu(); DeleteSavedDiagram(); }));

            CreateMenu(screenPos, _activePackage.IsValid ? PackageName(_activePackage) : "Canvas (no package yet)", items);
        }

        public void OnBackgroundClick(PointerEventData e)
        {
            if (e.button == PointerEventData.InputButton.Right
                || (e.button == PointerEventData.InputButton.Left && CtrlOrCmd()))
            { ClearSelectedEdge(); ShowEmptyMenu(e.position); }
            else { CloseMenu(); Select(null); }
        }

        // --- add with name prompt (§3.5) ---

        private void PromptAndAdd(ElementId parent, ElementKind kind, Vector2 screenPos)
        {
            CloseMenu();
            // Convention-following templates (Rational Rose / Sparx EA): visibility +/-/#/~, types after ':'.
            (string title, string template) = kind switch
            {
                ElementKind.Field => ("Attribute   —   visibility name : Type", "- name : Type"),
                ElementKind.Function => ("Operation   —   visibility name(args) : ReturnType", "+ name() : void"),
                ElementKind.Interface => ("Interface name", "I" + CountOf(kind)),
                ElementKind.Enum => ("Enumeration name", "Enum" + CountOf(kind)),
                _ => ($"{kind} name", kind.ToString() + CountOf(kind)),
            };

            ShowNamePrompt(title, template, value =>
            {
                _ctl.EnterAddNode(kind);
                var id = _ctl.CommitAddNode(parent, string.IsNullOrWhiteSpace(value) ? template : value.Trim());
                if (!id.IsValid) { Flash("invalid placement"); _ctl.EnterSelect(); return; }
                if (kind == ElementKind.Package) _activePackage = id;
                else _pos[id] = ScreenToLayer(screenPos);
                RebuildFromModel();
                SetSelected(id);
                Flash($"added {kind}");
            });
        }

        // --- link drag (§4) ---

        public void BeginLink(UmlNodeView source, BoxSide side, Vector2 screenPos)
        {
            CloseMenu();
            _linkSource = source;
            _linkSide = side;
            var go = new GameObject("TempLink", typeof(RectTransform));
            go.transform.SetParent(_edgeLayer, false);
            _tempLink = go.AddComponent<UmlEdgeView>();
            _tempLink.Interactive = false;
            _tempLink.Init(null, _font, new Color(0.20f, 0.45f, 0.65f, 1f), null, null, null, false,
                EndMarker.None, EndMarker.OpenArrow);
        }

        public void UpdateLink(Vector2 screenPos)
        {
            var target = NodeAt(screenPos, _linkSource);
            if (target != _hoverTarget)
            {
                if (_hoverTarget != null) _hoverTarget.SetAffordance(AffordanceTint.None);
                _hoverTarget = target;
            }
            if (target != null)
                target.SetAffordance(AnyValidEdge(_linkSource.Id, target.Id) ? AffordanceTint.Valid : AffordanceTint.Invalid);
        }

        public void EndLink(Vector2 screenPos)
        {
            var target = NodeAt(screenPos, _linkSource);
            if (_hoverTarget != null) _hoverTarget.SetAffordance(AffordanceTint.None);
            if (_tempLink != null) Destroy(_tempLink.gameObject);
            _tempLink = null; _hoverTarget = null;

            var source = _linkSource; _linkSource = null;
            if (source == null || target == null || target.Id == source.Id) return;

            // Capture the source side (the hotspot grabbed) and the exact drop point on the target border,
            // to pin both ends when the edge is created (asks #1 + #3).
            _pendingSrcSide = _linkSide;
            _pendingTgtAnchor = ProjectToBorder(target.Rt.anchoredPosition, target.Rt.sizeDelta, ScreenToLayer(screenPos));
            ShowTypePicker(source.Id, target.Id, screenPos);
        }

        private void ShowTypePicker(ElementId from, ElementId to, Vector2 screenPos)
        {
            CloseMenu();
            var items = new List<MenuItem>();
            foreach (var k in AllEdgeKinds)
                if (EdgeRules.CanConnect(_model, k, from, to).IsValid)
                {
                    var kind = k;
                    items.Add(new MenuItem(k.ToString(), true, () => Connect(from, to, kind)));
                }
            if (items.Count == 0) items.Add(new MenuItem("(no valid relationship here)", false, null));
            CreateMenu(screenPos, "Link type", items);
        }

        private void Connect(ElementId from, ElementId to, EdgeKind kind)
        {
            CloseMenu();
            _ctl.EnterConnect(CommitStyle.OneShot, kind);
            _ctl.BeginConnect(from);
            var edge = _ctl.CommitConnect(to);
            if (edge.IsValid)
            {
                _srcAnchor[edge] = new EndAnchor(_pendingSrcSide, 0.5f);
                _tgtAnchor[edge] = _pendingTgtAnchor;
                Flash($"linked: {kind}");
            }
            RebuildFromModel();
        }

        public void ShowEdgeMenu(UmlEdgeView edge, Vector2 screenPos)
        {
            if (!_model.TryGet(edge.Edge, out var e)) return;
            CloseMenu();
            var items = new List<MenuItem>();
            foreach (var k in AllEdgeKinds)
                if (EdgeRules.CanConnect(_model, k, e.From, e.To).IsValid)
                {
                    var kind = k; var edgeId = edge.Edge;
                    items.Add(new MenuItem(k.ToString() + (k == e.Kind ? "  ✓" : ""), true,
                        () => { _ctl.ReTypeEdge(edgeId, kind); CloseMenu(); RebuildFromModel(); }));
                }
            items.Add(MenuItem.Separator());
            var metaEdge = edge.Edge;
            items.Add(new MenuItem("Multiplicity / label…", true, () => ShowEdgeMetaEditor(metaEdge, screenPos)));
            bool isCurved = _curved.Contains(metaEdge);
            items.Add(new MenuItem(isCurved ? "Make orthogonal (straight)" : "Make curved (bezier)", true,
                () =>
                {
                    if (isCurved) _curved.Remove(metaEdge); else _curved.Add(metaEdge);
                    CloseMenu();
                    RebuildFromModel();
                }));
            var delEdge = edge.Edge;
            items.Add(new MenuItem("Delete link", true,
                () =>
                {
                    _ctl.DeleteEdge(delEdge);
                    DropEdgeViewState(delEdge);
                    if (_selectedEdge == delEdge) _selectedEdge = EdgeId.None;
                    CloseMenu();
                    RebuildFromModel();
                }));
            CreateMenu(screenPos, "Re-type / adorn / delete link", items);
        }

        // --- history ---

        private void Undo() { if (_ctl.Undo()) { Flash("↶ undo"); FixActiveAfterChange(); RebuildFromModel(); } }
        private void Redo() { if (_ctl.Redo()) { Flash("↷ redo"); FixActiveAfterChange(); RebuildFromModel(); } }
        private void DeleteSelected()
        {
            if (_selectedEdge.IsValid)
            {
                _ctl.DeleteEdge(_selectedEdge);
                DropEdgeViewState(_selectedEdge);
                _selectedEdge = EdgeId.None;
                RebuildFromModel();
                return;
            }
            if (!_selectedId.IsValid) return;
            _ctl.Delete(_selectedId);
            SetSelected(ElementId.None);
            FixActiveAfterChange();
            RebuildFromModel();
        }

        // --- view rebuild ---

        private void RebuildFromModel()
        {
            foreach (var nv in _nodes.Values) if (nv != null) Destroy(nv.gameObject);
            _nodes.Clear();
            foreach (var b in _edges) if (b.View != null) Destroy(b.View.gameObject);
            _edges.Clear();

            EnsureActivePackage();
            BuildTabBar();

            if (!_activePackage.IsValid)
            {
                Flash("No package yet — right-click the canvas (or +) to add one.");
                RefreshBendHandles();
                return;
            }

            // Classifier boxes = direct classifier children of the active package.
            int spread = 0;
            foreach (var el in _model.Elements)
            {
                if (el.Parent != _activePackage) continue;
                if (!KindInfo.IsClassifier(el.Kind) && el.Kind != ElementKind.Note) continue;
                if (!_pos.TryGetValue(el.Id, out var p))
                {
                    p = new Vector2(-360f + (spread % 4) * 240f, 120f - (spread / 4) * 200f);
                    _pos[el.Id] = p;
                }
                spread++;
                CreateNodeView(el, p);
            }

            // Relationship edges between currently-visible boxes.
            foreach (var edge in _model.Edges)
                if (_nodes.ContainsKey(edge.From) && _nodes.ContainsKey(edge.To))
                    CreateEdgeView(edge);

            if (_selectedId.IsValid && _nodes.TryGetValue(_selectedId, out var sel)) sel.SetSelected(true);

            // Re-apply edge selection highlight + bend handles to the freshly-created edge views.
            if (_selectedEdge.IsValid && !TryGetEdgeEndpoints(_selectedEdge, out _, out _)) _selectedEdge = EdgeId.None;
            SetEdgeHighlight(_selectedEdge, true);
            RefreshBendHandles();
        }

        private void CreateNodeView(ModelElement el, Vector2 pos)
        {
            // Members store their full UML signature as the name (e.g. "- balance : decimal",
            // "+ deposit(amount : decimal) : void"), rendered verbatim — Rose/Sparx convention.
            var attributes = new List<string>();
            var operations = new List<string>();
            foreach (var childId in el.ChildIds)
            {
                if (!_model.TryGet(childId, out var c)) continue;
                if (c.Kind == ElementKind.Field) attributes.Add(c.Name);
                else if (c.Kind == ElementKind.Function) operations.Add(c.Name);
            }

            var go = new GameObject("Box:" + el.Name, typeof(RectTransform));
            go.transform.SetParent(_nodeLayer, false);
            var nv = go.AddComponent<UmlNodeView>();
            ColorUtility.TryParseHtmlString(KindInfo.Hue(el.Kind), out var hue);
            _size.TryGetValue(el.Id, out var size);
            nv.Init(this, el.Id, el.Name, Stereotype(el), el.Kind, hue, _font, attributes, operations,
                el.Language, size);
            nv.Rt.anchoredPosition = pos;
            _nodes[el.Id] = nv;
        }

        private void CreateEdgeView(ModelEdge edge)
        {
            var (dashed, src, tgt) = EdgeVisual(edge.Kind);
            var go = new GameObject("Edge:" + edge.Kind, typeof(RectTransform));
            go.transform.SetParent(_edgeLayer, false);
            var ev = go.AddComponent<UmlEdgeView>();
            ev.Edge = edge.Id;
            // Midpoint label is the association name (not the kind — kind is conveyed by line/marker style).
            ev.Init(this, _font, EdgeColor, edge.Label, edge.SourceMultiplicity, edge.TargetMultiplicity,
                dashed, src, tgt);
            _edges.Add(new EdgeBinding { View = ev, From = edge.From, To = edge.To });
        }

        private static (bool dashed, EndMarker src, EndMarker tgt) EdgeVisual(EdgeKind k) => k switch
        {
            // Plain association = a line with multiplicities, no arrowhead (conventional class-diagram default).
            EdgeKind.Association => (false, EndMarker.None, EndMarker.None),
            EdgeKind.Dependency => (true, EndMarker.None, EndMarker.OpenArrow),
            EdgeKind.Generalization => (false, EndMarker.None, EndMarker.HollowTriangle),
            EdgeKind.Realization => (true, EndMarker.None, EndMarker.HollowTriangle),
            EdgeKind.Aggregation => (false, EndMarker.HollowDiamond, EndMarker.None),
            EdgeKind.Composition => (false, EndMarker.FilledDiamond, EndMarker.None),
            _ => (false, EndMarker.None, EndMarker.OpenArrow),
        };

        // --- orthogonal routing ---

        /// <summary>The orthogonal polyline for an edge: pinned endpoints + user bends if any, else an auto Z-route.</summary>
        private List<Vector2> RouteEdge(ElementId from, ElementId to, EdgeId edge)
        {
            var ctrl = ControlPolyline(from, to, edge, out bool fixedSrc, out bool fixedTgt);
            // Curved edges are a smooth spline through the same control points (bend handles still apply).
            if (_curved.Contains(edge)) return CurveThrough(ctrl);
            // Fully-auto edges (no pins, no bends) get the balanced two-bend Z; everything else is squared off.
            if (!fixedSrc && !fixedTgt && ctrl.Count == 2 && !_waypoints.ContainsKey(edge))
            {
                var f = _nodes[from]; var t = _nodes[to];
                return AutoOrthogonal(f.Rt.anchoredPosition, f.Rt.sizeDelta, t.Rt.anchoredPosition, t.Rt.sizeDelta);
            }
            return CleanColinear(Orthogonalize(ctrl));
        }

        /// <summary>A Catmull-Rom spline tessellated through the control points (smooth curve passing through each).</summary>
        private static List<Vector2> CurveThrough(List<Vector2> pts)
        {
            if (pts == null || pts.Count <= 2) return pts;
            const int seg = 14;
            var outp = new List<Vector2> { pts[0] };
            for (int i = 0; i < pts.Count - 1; i++)
            {
                Vector2 p0 = i > 0 ? pts[i - 1] : pts[i];
                Vector2 p1 = pts[i];
                Vector2 p2 = pts[i + 1];
                Vector2 p3 = i + 2 < pts.Count ? pts[i + 2] : pts[i + 1];
                for (int j = 1; j <= seg; j++)
                    outp.Add(CatmullRom(p0, p1, p2, p3, j / (float)seg));
            }
            return outp;
        }

        private static Vector2 CatmullRom(Vector2 p0, Vector2 p1, Vector2 p2, Vector2 p3, float t)
        {
            float t2 = t * t, t3 = t2 * t;
            return 0.5f * ((2f * p1) + (-p0 + p2) * t
                + (2f * p0 - 5f * p1 + 4f * p2 - p3) * t2
                + (-p0 + 3f * p1 - 3f * p2 + p3) * t3);
        }

        /// <summary>
        /// The control points an edge routes through: [A] (+ perpendicular stub if A is pinned) + bend points +
        /// (stub if B is pinned) + [B]. A/B are the pinned anchor points, or auto facing-side clips.
        /// </summary>
        private List<Vector2> ControlPolyline(ElementId from, ElementId to, EdgeId edge,
            out bool fixedSrc, out bool fixedTgt)
        {
            var f = _nodes[from]; var t = _nodes[to];
            Vector2 cf = f.Rt.anchoredPosition, ct = t.Rt.anchoredPosition;
            Vector2 sf = f.Rt.sizeDelta, st = t.Rt.sizeDelta;
            bool hasWps = _waypoints.TryGetValue(edge, out var wps) && wps.Count > 0;

            fixedSrc = _srcAnchor.TryGetValue(edge, out var sa);
            fixedTgt = _tgtAnchor.TryGetValue(edge, out var ta);

            Vector2 A = fixedSrc ? AnchorPoint(cf, sf, sa) : ClipToBox(cf, sf, hasWps ? wps[0] : ct);
            Vector2 B = fixedTgt ? AnchorPoint(ct, st, ta) : ClipToBox(ct, st, hasWps ? wps[wps.Count - 1] : cf);

            var ctrl = new List<Vector2> { A };
            if (fixedSrc) ctrl.Add(A + AnchorNormal(sa.Side) * StubLen);
            if (hasWps) ctrl.AddRange(wps);
            if (fixedTgt) ctrl.Add(B + AnchorNormal(ta.Side) * StubLen);
            ctrl.Add(B);
            return ctrl;
        }

        private static Vector2 AnchorPoint(Vector2 center, Vector2 size, EndAnchor a)
        {
            float hw = size.x * 0.5f, hh = size.y * 0.5f;
            return a.Side switch
            {
                BoxSide.Left => new Vector2(center.x - hw, center.y + (a.T - 0.5f) * size.y),
                BoxSide.Right => new Vector2(center.x + hw, center.y + (a.T - 0.5f) * size.y),
                BoxSide.Top => new Vector2(center.x + (a.T - 0.5f) * size.x, center.y + hh),
                _ => new Vector2(center.x + (a.T - 0.5f) * size.x, center.y - hh),
            };
        }

        private static Vector2 AnchorNormal(BoxSide side) => side switch
        {
            BoxSide.Left => new Vector2(-1f, 0f),
            BoxSide.Right => new Vector2(1f, 0f),
            BoxSide.Top => new Vector2(0f, 1f),
            _ => new Vector2(0f, -1f),
        };

        private static EndAnchor ProjectToBorder(Vector2 center, Vector2 size, Vector2 point)
        {
            float hw = size.x * 0.5f, hh = size.y * 0.5f;
            float lx = Mathf.Clamp(point.x - center.x, -hw, hw);
            float ly = Mathf.Clamp(point.y - center.y, -hh, hh);
            float dR = hw - lx, dL = lx + hw, dT = hh - ly, dB = ly + hh;
            float m = Mathf.Min(Mathf.Min(dL, dR), Mathf.Min(dT, dB));
            float tx = hw > 0f ? (lx + hw) / (2f * hw) : 0.5f;
            float ty = hh > 0f ? (ly + hh) / (2f * hh) : 0.5f;
            if (m == dL) return new EndAnchor(BoxSide.Left, ty);
            if (m == dR) return new EndAnchor(BoxSide.Right, ty);
            if (m == dT) return new EndAnchor(BoxSide.Top, tx);
            return new EndAnchor(BoxSide.Bottom, tx);
        }

        /// <summary>A two-bend orthogonal "Z" between two boxes, exiting the facing sides. Degenerate bends collapse.</summary>
        private static List<Vector2> AutoOrthogonal(Vector2 cf, Vector2 sf, Vector2 ct, Vector2 st)
        {
            float dx = ct.x - cf.x, dy = ct.y - cf.y;
            var pts = new List<Vector2>(4);
            if (Mathf.Abs(dx) >= Mathf.Abs(dy))
            {
                Vector2 a = ClipToBox(cf, sf, new Vector2(ct.x, cf.y));
                Vector2 b = ClipToBox(ct, st, new Vector2(cf.x, ct.y));
                float midX = (a.x + b.x) * 0.5f;
                pts.Add(a); pts.Add(new Vector2(midX, a.y)); pts.Add(new Vector2(midX, b.y)); pts.Add(b);
            }
            else
            {
                Vector2 a = ClipToBox(cf, sf, new Vector2(cf.x, ct.y));
                Vector2 b = ClipToBox(ct, st, new Vector2(ct.x, cf.y));
                float midY = (a.y + b.y) * 0.5f;
                pts.Add(a); pts.Add(new Vector2(a.x, midY)); pts.Add(new Vector2(b.x, midY)); pts.Add(b);
            }
            return CleanColinear(pts);
        }

        /// <summary>Insert right-angle elbows so every consecutive pair is axis-aligned (horizontal-first).</summary>
        private static List<Vector2> Orthogonalize(List<Vector2> pts)
        {
            var outp = new List<Vector2> { pts[0] };
            for (int i = 1; i < pts.Count; i++)
            {
                var p = outp[outp.Count - 1]; var q = pts[i];
                if (Mathf.Abs(p.x - q.x) > 0.5f && Mathf.Abs(p.y - q.y) > 0.5f)
                    outp.Add(new Vector2(q.x, p.y));
                outp.Add(q);
            }
            return outp;
        }

        /// <summary>Drop duplicate and colinear interior points so the polyline is minimal.</summary>
        private static List<Vector2> CleanColinear(List<Vector2> pts)
        {
            if (pts.Count <= 2) return pts;
            var outp = new List<Vector2> { pts[0] };
            for (int i = 1; i < pts.Count - 1; i++)
            {
                var a = outp[outp.Count - 1]; var b = pts[i]; var c = pts[i + 1];
                bool dup = (a - b).sqrMagnitude < 0.5f;
                bool colX = Mathf.Abs(a.x - b.x) < 0.5f && Mathf.Abs(b.x - c.x) < 0.5f;
                bool colY = Mathf.Abs(a.y - b.y) < 0.5f && Mathf.Abs(b.y - c.y) < 0.5f;
                if (dup || colX || colY) continue;
                outp.Add(b);
            }
            outp.Add(pts[pts.Count - 1]);
            return outp;
        }

        // --- edge selection + bend handles ---

        private static bool AltDown() => Input.GetKey(KeyCode.LeftAlt) || Input.GetKey(KeyCode.RightAlt);

        public void OnEdgePointerClick(UmlEdgeView view, PointerEventData e)
        {
            if (e.button == PointerEventData.InputButton.Right) { ShowEdgeMenu(view, e.position); return; }
            if (e.button != PointerEventData.InputButton.Left) return;

            if (CtrlOrCmd())
            {
                // Ctrl-click a line to add a bend point there; Ctrl+Alt-click to remove the nearest one.
                CloseMenu();
                SetSelected(ElementId.None);
                SetSelectedEdge(view.Edge);
                Vector2 p = ScreenToLayer(e.position);
                if (AltDown()) RemoveNearestVertex(view.Edge, p);
                else AddVertexAt(view.Edge, p);
                return;
            }

            CloseMenu();
            SetSelected(ElementId.None);
            SetSelectedEdge(view.Edge);
        }

        /// <summary>Ctrl-click on the line: insert a bend at the click, on whichever control segment is nearest.</summary>
        private void AddVertexAt(EdgeId edge, Vector2 layerPos)
        {
            if (!TryGetEdgeEndpoints(edge, out var from, out var to)) return;
            var ctrl = ControlPolyline(from, to, edge, out bool fixedSrc, out _);
            int best = 0; float bestD = float.MaxValue;
            for (int k = 0; k < ctrl.Count - 1; k++)
            {
                float d = DistToSegment(layerPos, ctrl[k], ctrl[k + 1]);
                if (d < bestD) { bestD = d; best = k; }
            }
            if (!_waypoints.TryGetValue(edge, out var wps)) { wps = new List<Vector2>(); _waypoints[edge] = wps; }
            int startWp = 1 + (fixedSrc ? 1 : 0);
            int insertAt = Mathf.Clamp(best - startWp + 1, 0, wps.Count);
            wps.Insert(insertAt, layerPos);
            RefreshBendHandles();
            Flash("added bend (Ctrl-click line) · Ctrl+Alt-click to remove");
        }

        /// <summary>Ctrl+Alt-click: remove the bend nearest the click (within reach).</summary>
        private void RemoveNearestVertex(EdgeId edge, Vector2 layerPos)
        {
            if (!_waypoints.TryGetValue(edge, out var wps) || wps.Count == 0) { Flash("no bend to remove"); return; }
            int best = -1; float bestD = 36f;
            for (int i = 0; i < wps.Count; i++)
            {
                float d = (wps[i] - layerPos).magnitude;
                if (d < bestD) { bestD = d; best = i; }
            }
            if (best < 0) { Flash("click closer to a bend to remove it"); return; }
            wps.RemoveAt(best);
            if (wps.Count == 0) _waypoints.Remove(edge);
            RefreshBendHandles();
            Flash("removed bend");
        }

        private static float DistToSegment(Vector2 p, Vector2 a, Vector2 b)
        {
            Vector2 ab = b - a;
            float len2 = ab.sqrMagnitude;
            if (len2 < 0.0001f) return (p - a).magnitude;
            float t = Mathf.Clamp01(Vector2.Dot(p - a, ab) / len2);
            return (p - (a + ab * t)).magnitude;
        }

        private void SetSelectedEdge(EdgeId edge)
        {
            if (_selectedEdge != edge)
            {
                SetEdgeHighlight(_selectedEdge, false);
                _selectedEdge = edge;
                SetEdgeHighlight(_selectedEdge, true);
            }
            RefreshBendHandles();
        }

        private void ClearSelectedEdge()
        {
            if (!_selectedEdge.IsValid) { RefreshBendHandles(); return; }
            SetEdgeHighlight(_selectedEdge, false);
            _selectedEdge = EdgeId.None;
            RefreshBendHandles();
        }

        private void SetEdgeHighlight(EdgeId edge, bool on)
        {
            if (!edge.IsValid) return;
            foreach (var b in _edges) if (b.View != null && b.View.Edge == edge) b.View.SetHighlighted(on);
        }

        private bool TryGetEdgeEndpoints(EdgeId edge, out ElementId from, out ElementId to)
        {
            foreach (var b in _edges)
                if (b.View != null && b.View.Edge == edge) { from = b.From; to = b.To; return true; }
            from = ElementId.None; to = ElementId.None; return false;
        }

        /// <summary>Forget all view-state (bends + endpoint pins) for a deleted edge.</summary>
        private void DropEdgeViewState(EdgeId edge)
        {
            _waypoints.Remove(edge);
            _srcAnchor.Remove(edge);
            _tgtAnchor.Remove(edge);
            _curved.Remove(edge);
        }

        private void RefreshBendHandles()
        {
            foreach (var h in _bendHandles) if (h != null) Destroy(h.gameObject);
            _bendHandles.Clear();
            if (!_selectedEdge.IsValid || !TryGetEdgeEndpoints(_selectedEdge, out var from, out var to)) return;
            if (!_nodes.ContainsKey(from) || !_nodes.ContainsKey(to)) return;

            var ctrl = ControlPolyline(from, to, _selectedEdge, out _, out _);
            var wps = _waypoints.TryGetValue(_selectedEdge, out var w) ? w : null;

            // Endpoint handles (orange) — drag to re-pin the attachment anywhere on the box border.
            var orange = new Color(0.95f, 0.62f, 0.18f, 1f);
            MakeEdgeHandle(UmlHandleKind.EndpointStart, 0, ctrl[0], 14f, orange);
            MakeEdgeHandle(UmlHandleKind.EndpointEnd, 0, ctrl[ctrl.Count - 1], 14f, orange);

            // Vertex handles (blue) — drag to move a bend; right-click (or Ctrl+Alt-click the line) to delete.
            // Adding bends is done by Ctrl-clicking the line itself (no per-segment add handles).
            if (wps != null)
                for (int i = 0; i < wps.Count; i++)
                    MakeEdgeHandle(UmlHandleKind.Vertex, i, wps[i], 13f, new Color(0.12f, 0.55f, 0.85f, 1f));
        }

        private void MakeEdgeHandle(UmlHandleKind kind, int index, Vector2 pos, float size, Color color)
        {
            var go = new GameObject("EdgeHandle:" + kind, typeof(RectTransform));
            go.transform.SetParent(_handleLayer, false);
            var handle = go.AddComponent<UmlEdgeHandle>();
            handle.Init(this, _selectedEdge, kind, index, size, color);
            handle.SetPosition(pos);
            _bendHandles.Add(handle);
        }

        private void PositionBendHandles()
        {
            if (!_selectedEdge.IsValid || _bendHandles.Count == 0) return;
            if (!TryGetEdgeEndpoints(_selectedEdge, out var from, out var to)) return;
            if (!_nodes.ContainsKey(from) || !_nodes.ContainsKey(to)) return;
            var ctrl = ControlPolyline(from, to, _selectedEdge, out _, out _);
            var wps = _waypoints.TryGetValue(_selectedEdge, out var w) ? w : null;
            foreach (var h in _bendHandles)
            {
                if (h == null) continue;
                switch (h.Kind)
                {
                    case UmlHandleKind.EndpointStart: h.SetPosition(ctrl[0]); break;
                    case UmlHandleKind.EndpointEnd: h.SetPosition(ctrl[ctrl.Count - 1]); break;
                    case UmlHandleKind.Vertex:
                        if (wps != null && h.Index < wps.Count) h.SetPosition(wps[h.Index]);
                        break;
                    case UmlHandleKind.Add:
                        if (h.Index < ctrl.Count - 1) h.SetPosition((ctrl[h.Index] + ctrl[h.Index + 1]) * 0.5f);
                        break;
                }
            }
        }

        /// <summary>Click an Add handle: insert a new bend at that control-segment midpoint (ask #2 "add points").</summary>
        public void AddVertex(EdgeId edge, int controlIndex)
        {
            if (_selectedEdge != edge || !TryGetEdgeEndpoints(edge, out var from, out var to)) return;
            var ctrl = ControlPolyline(from, to, edge, out bool fixedSrc, out _);
            if (controlIndex < 0 || controlIndex + 1 >= ctrl.Count) return;
            Vector2 mid = (ctrl[controlIndex] + ctrl[controlIndex + 1]) * 0.5f;

            if (!_waypoints.TryGetValue(edge, out var wps)) { wps = new List<Vector2>(); _waypoints[edge] = wps; }
            // Map control-segment index → waypoint index (the leading A + optional source stub aren't waypoints).
            int startWp = 1 + (fixedSrc ? 1 : 0);
            int insertAt = Mathf.Clamp(controlIndex - startWp + 1, 0, wps.Count);
            wps.Insert(insertAt, mid);
            RefreshBendHandles();
            Flash("added bend");
        }

        public void DeleteVertex(EdgeId edge, int index)
        {
            if (!_waypoints.TryGetValue(edge, out var wps) || index < 0 || index >= wps.Count) return;
            wps.RemoveAt(index);
            if (wps.Count == 0) _waypoints.Remove(edge);
            RefreshBendHandles();
            Flash("removed bend");
        }

        public void BeginEdgeHandleDrag(EdgeId edge, UmlHandleKind kind, int index)
        {
            _hEdge = edge; _hKind = kind; _hIndex = index;
        }

        public void DragEdgeHandle(Vector2 screenPos)
        {
            if (!_hEdge.IsValid || !TryGetEdgeEndpoints(_hEdge, out var from, out var to)) return;
            if (!_nodes.ContainsKey(from) || !_nodes.ContainsKey(to)) return;
            var f = _nodes[from]; var t = _nodes[to];
            Vector2 pos = ScreenToLayer(screenPos);

            switch (_hKind)
            {
                case UmlHandleKind.EndpointStart:
                    _srcAnchor[_hEdge] = ProjectToBorder(f.Rt.anchoredPosition, f.Rt.sizeDelta, pos);
                    break;
                case UmlHandleKind.EndpointEnd:
                    _tgtAnchor[_hEdge] = ProjectToBorder(t.Rt.anchoredPosition, t.Rt.sizeDelta, pos);
                    break;
                case UmlHandleKind.Vertex:
                    if (_waypoints.TryGetValue(_hEdge, out var wps) && _hIndex >= 0 && _hIndex < wps.Count)
                        wps[_hIndex] = SnapVertex(pos, wps, _hIndex, f, t);
                    break;
            }
        }

        public void EndEdgeHandleDrag()
        {
            if (_hKind == UmlHandleKind.Vertex) CleanWaypoints(_hEdge);
            _hEdge = EdgeId.None;
            RefreshBendHandles();
        }

        /// <summary>Snap a dragged bend to align (x or y) with a neighbor control point — keeps routes tidy.</summary>
        private Vector2 SnapVertex(Vector2 pos, List<Vector2> wps, int i, UmlNodeView f, UmlNodeView t)
        {
            const float th = 9f;
            Vector2 prev = i > 0 ? wps[i - 1] : f.Rt.anchoredPosition;
            Vector2 next = i < wps.Count - 1 ? wps[i + 1] : t.Rt.anchoredPosition;
            if (Mathf.Abs(pos.x - prev.x) < th) pos.x = prev.x;
            else if (Mathf.Abs(pos.x - next.x) < th) pos.x = next.x;
            if (Mathf.Abs(pos.y - prev.y) < th) pos.y = prev.y;
            else if (Mathf.Abs(pos.y - next.y) < th) pos.y = next.y;
            return pos;
        }

        /// <summary>Drop bends that are colinear with their neighbors (incl. the endpoints) after a move.</summary>
        private void CleanWaypoints(EdgeId edge)
        {
            if (!_waypoints.TryGetValue(edge, out var wps) || wps.Count == 0) return;
            if (!TryGetEdgeEndpoints(edge, out var from, out var to)) return;
            var ctrl = ControlPolyline(from, to, edge, out _, out _);
            var cleaned = CleanColinear(ctrl);
            // Keep only the interior points that survive as the new bend set (approximate by re-deriving from wps).
            var kept = new List<Vector2>();
            foreach (var wp in wps)
            {
                bool stillThere = false;
                foreach (var c in cleaned) if ((c - wp).sqrMagnitude < 0.5f) { stillThere = true; break; }
                if (stillThere) kept.Add(wp);
            }
            if (kept.Count == 0) _waypoints.Remove(edge);
            else _waypoints[edge] = kept;
        }

        private static string Stereotype(ModelElement el)
        {
            // A custom stereotype (Properties dialog) overrides the kind-derived one — Rose/Sparx behavior.
            if (!string.IsNullOrWhiteSpace(el.Stereotype))
                return "«" + el.Stereotype.Trim() + "»";
            return el.Kind switch
            {
                ElementKind.Interface => "«interface»",
                ElementKind.Enum => "«enumeration»",
                ElementKind.Struct => "«struct»",
                ElementKind.Class when el.IsAbstract => "«abstract»",
                _ => null,
            };
        }

        // --- tabs ---

        private void EnsureActivePackage()
        {
            if (_activePackage.IsValid && _model.Contains(_activePackage)) return;
            _activePackage = ElementId.None;
            foreach (var el in _model.Elements)
                if (el.Kind == ElementKind.Package) { _activePackage = el.Id; break; }
        }

        private void FixActiveAfterChange()
        {
            if (!_activePackage.IsValid || !_model.Contains(_activePackage)) _activePackage = ElementId.None;
        }

        private void BuildTabBar()
        {
            for (int i = _tabBar.childCount - 1; i >= 0; i--) Destroy(_tabBar.GetChild(i).gameObject);

            float x = 8f;
            foreach (var el in _model.Elements)
            {
                if (el.Kind != ElementKind.Package) continue;
                var pkgId = el.Id;
                bool active = pkgId == _activePackage;
                MakeTab(el.Name, x, 150f, active, () => { _activePackage = pkgId; SetSelected(ElementId.None); RebuildFromModel(); });
                x += 154f;
            }
            MakeTab("+", x, 40f, false, () =>
                PromptAndAdd(ElementId.None, ElementKind.Package, new Vector2(Screen.width * 0.5f, Screen.height * 0.5f)));
        }

        private void MakeTab(string label, float x, float w, bool active, System.Action onClick)
        {
            var go = new GameObject("Tab:" + label, typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(_tabBar, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0f, 0.5f);
            rt.pivot = new Vector2(0f, 0.5f);
            rt.sizeDelta = new Vector2(w, 30f);
            rt.anchoredPosition = new Vector2(x, 0f);
            var img = go.AddComponent<Image>();
            img.color = active ? new Color(0.20f, 0.42f, 0.52f, 1f) : new Color(0.16f, 0.18f, 0.22f, 1f);
            var btn = go.AddComponent<Button>();
            btn.targetGraphic = img;
            btn.onClick.AddListener(() => onClick());
            var t = MakeText(rt, label, new Vector2(10f, 0f), new Vector2(w - 14f, 30f), 16,
                active ? new Color(0.95f, 0.98f, 1f) : new Color(0.72f, 0.77f, 0.84f, 1f), TextAnchor.MiddleLeft);
            t.raycastTarget = false;
        }

        // --- helpers ---

        private void SetSelected(ElementId id)
        {
            if (_selectedId.IsValid && _nodes.TryGetValue(_selectedId, out var prev) && prev != null) prev.SetSelected(false);
            _selectedId = id;
            if (id.IsValid && _nodes.TryGetValue(id, out var nv) && nv != null) nv.SetSelected(true);
        }

        private bool AnyValidEdge(ElementId from, ElementId to)
        {
            foreach (var k in AllEdgeKinds) if (EdgeRules.CanConnect(_model, k, from, to).IsValid) return true;
            return false;
        }

        private int CountOf(ElementKind kind)
        {
            int n = 0;
            foreach (var e in _model.Elements) if (e.Kind == kind) n++;
            return n + 1;
        }

        private string PackageName(ElementId id) => _model.TryGet(id, out var e) ? e.Name : "package";

        /// <summary>Backdrop click on a modal property/member dialog cancels it (click-outside = dismiss).</summary>
        public void CancelModal() => CloseMenu();

        private static string Ellipsize(string s, int max)
        {
            if (string.IsNullOrEmpty(s) || s.Length <= max) return s;
            return s.Substring(0, max - 1) + "…";
        }

        private UmlNodeView NodeAt(Vector2 screenPos, UmlNodeView exclude)
        {
            UmlNodeView found = null;
            foreach (var nv in _nodes.Values)
            {
                if (nv == exclude) continue;
                if (RectTransformUtility.RectangleContainsScreenPoint(nv.Rt, screenPos, null)) found = nv;
            }
            return found;
        }

        private static Vector2 ClipToBox(Vector2 center, Vector2 size, Vector2 toward)
        {
            Vector2 dir = toward - center;
            if (dir.sqrMagnitude < 0.001f) return center;
            float hw = size.x * 0.5f, hh = size.y * 0.5f;
            float ax = Mathf.Abs(dir.x), ay = Mathf.Abs(dir.y);
            float t = (ax < 0.0001f) ? hh / ay : (ay < 0.0001f) ? hw / ax : Mathf.Min(hw / ax, hh / ay);
            return center + dir * t;
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

        // --- canvas / menu / prompt construction ---

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

            var bgGo = new GameObject("Background", typeof(RectTransform));
            var bgRt = (RectTransform)bgGo.transform;
            bgRt.SetParent(_root, false);
            Stretch(bgRt);
            bgGo.AddComponent<Image>().color = new Color(0.95f, 0.96f, 0.97f, 1f);
            bgGo.AddComponent<UmlBackground>().Canvas = this;

            _edgeLayer = NewLayer("EdgeLayer");
            _nodeLayer = NewLayer("NodeLayer");
            _handleLayer = NewLayer("HandleLayer"); // bend handles, above boxes

            // Tab bar (top strip).
            var tabGo = new GameObject("TabBar", typeof(RectTransform));
            _tabBar = (RectTransform)tabGo.transform;
            _tabBar.SetParent(_root, false);
            _tabBar.anchorMin = new Vector2(0f, 1f); _tabBar.anchorMax = new Vector2(1f, 1f);
            _tabBar.pivot = new Vector2(0f, 1f);
            _tabBar.sizeDelta = new Vector2(0f, 38f);
            _tabBar.anchoredPosition = new Vector2(0f, -2f);
            var tabBg = tabGo.AddComponent<Image>();
            tabBg.color = new Color(0.11f, 0.12f, 0.15f, 1f);
            tabBg.raycastTarget = false;

            // Hint line under the tabs.
            var hintGo = new GameObject("Hint", typeof(RectTransform));
            var hintRt = (RectTransform)hintGo.transform;
            hintRt.SetParent(_root, false);
            hintRt.anchorMin = new Vector2(0f, 1f); hintRt.anchorMax = new Vector2(1f, 1f);
            hintRt.pivot = new Vector2(0f, 1f);
            hintRt.sizeDelta = new Vector2(0f, 26f);
            hintRt.anchoredPosition = new Vector2(12f, -42f);
            _hint = hintGo.AddComponent<Text>();
            _hint.font = _font; _hint.fontSize = 17;
            _hint.color = new Color(0.34f, 0.38f, 0.45f, 1f);
            _hint.alignment = TextAnchor.MiddleLeft;
            _hint.supportRichText = false;
            _hint.raycastTarget = false;
            _hint.text = "Right-click canvas → add / paste · right-click box → edit element · drag empty space → pan · " +
                         "hover a box → drag a side hotspot to link · Ctrl-click a line → add bend (Ctrl+Alt → remove) · " +
                         "drag a box border to resize · Ctrl/Cmd C/V copy · wheel zoom · Ctrl/Cmd S save · Ctrl/Cmd Z undo";
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
            const float w = 250f, ih = 32f, hh = 26f, pad = 6f;
            float h = hh + pad + items.Count * ih + pad;
            var go = NewPanel("Menu", screenPos, new Vector2(w, h), new Color(0.12f, 0.14f, 0.17f, 0.98f));
            var rt = (RectTransform)go.transform;
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

        private void ShowNamePrompt(string title, string template, System.Action<string> onSubmit)
        {
            CloseMenu();

            // Dim modal backdrop (click outside = cancel).
            var backdrop = new GameObject("PromptBackdrop", typeof(RectTransform));
            var bdRt = (RectTransform)backdrop.transform;
            bdRt.SetParent(_root, false);
            Stretch(bdRt);
            backdrop.AddComponent<Image>().color = new Color(0f, 0f, 0f, 0.45f);
            backdrop.AddComponent<UmlModalBackdrop>().Canvas = this;
            _menu = backdrop;

            const float w = 460f, h = 168f;
            var panel = new GameObject("NamePrompt", typeof(RectTransform));
            var rt = (RectTransform)panel.transform;
            rt.SetParent(bdRt, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0.5f, 0.5f);
            rt.pivot = new Vector2(0.5f, 0.5f);
            rt.sizeDelta = new Vector2(w, h);
            rt.anchoredPosition = Vector2.zero;
            panel.AddComponent<Image>().color = new Color(0.14f, 0.16f, 0.20f, 1f);

            MakeText(rt, title, new Vector2(16f, -12f), new Vector2(w - 32f, 24f), 16,
                new Color(0.84f, 0.88f, 0.94f, 1f), TextAnchor.MiddleLeft).fontStyle = FontStyle.Bold;

            var inputGo = new GameObject("Input", typeof(RectTransform));
            var inRt = (RectTransform)inputGo.transform;
            inRt.SetParent(rt, false);
            inRt.anchorMin = inRt.anchorMax = new Vector2(0f, 1f);
            inRt.pivot = new Vector2(0f, 1f);
            inRt.sizeDelta = new Vector2(w - 32f, 38f);
            inRt.anchoredPosition = new Vector2(16f, -48f);
            inputGo.AddComponent<Image>().color = new Color(0.20f, 0.22f, 0.27f, 1f);
            var input = inputGo.AddComponent<InputField>();

            var textComp = MakeText(inRt, "", new Vector2(10f, 0f), new Vector2(w - 56f, 38f), 18,
                new Color(0.96f, 0.97f, 1f, 1f), TextAnchor.MiddleLeft);
            textComp.raycastTarget = true;
            var placeholder = MakeText(inRt, template, new Vector2(10f, 0f), new Vector2(w - 56f, 38f), 18,
                new Color(0.5f, 0.55f, 0.62f, 1f), TextAnchor.MiddleLeft);
            placeholder.fontStyle = FontStyle.Italic;

            input.textComponent = textComp;
            input.placeholder = placeholder;
            input.lineType = InputField.LineType.SingleLine;
            input.text = template; // prefill the editable template so the user tweaks rather than retypes

            void Submit()
            {
                var value = input.text;
                CloseMenu();
                onSubmit(string.IsNullOrWhiteSpace(value) ? template : value);
            }
            input.onSubmit.AddListener(_ => Submit());

            // OK button + Cancel.
            MakeButton(rt, "OK", new Vector2(w - 200f, -100f), new Vector2(84f, 34f),
                new Color(0.20f, 0.42f, 0.52f, 1f), Submit);
            MakeButton(rt, "Cancel", new Vector2(w - 108f, -100f), new Vector2(92f, 34f),
                new Color(0.22f, 0.24f, 0.29f, 1f), CloseMenu);

            MakeText(rt, "Convention: + public  - private  # protected  ~ package · types after ‘:’",
                new Vector2(16f, -140f), new Vector2(w - 32f, 18f), 12,
                new Color(0.5f, 0.55f, 0.62f, 1f), TextAnchor.MiddleLeft);

            if (EventSystem.current != null) EventSystem.current.SetSelectedGameObject(inputGo);
            input.ActivateInputField();
            input.MoveTextEnd(false);
        }

        private void MakeButton(RectTransform parent, string label, Vector2 topLeft, Vector2 size,
            Color color, System.Action onClick)
        {
            var go = new GameObject("Button:" + label, typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0f, 1f);
            rt.pivot = new Vector2(0f, 1f);
            rt.sizeDelta = size;
            rt.anchoredPosition = topLeft;
            var img = go.AddComponent<Image>();
            img.color = color;
            var btn = go.AddComponent<Button>();
            btn.targetGraphic = img;
            btn.onClick.AddListener(() => onClick());
            MakeText(rt, label, Vector2.zero, size, 16, new Color(0.95f, 0.97f, 1f), TextAnchor.MiddleCenter);
        }

        private GameObject NewPanel(string name, Vector2 screenPos, Vector2 size, Color color)
        {
            var go = new GameObject(name, typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(_root, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0f, 0f);
            rt.pivot = new Vector2(0f, 1f);
            rt.sizeDelta = size;
            rt.anchoredPosition = new Vector2(screenPos.x, screenPos.y) / ScaleFactor;
            go.AddComponent<Image>().color = color;
            return go;
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
            t.font = _font; t.text = text; t.fontSize = fontSize; t.color = color; t.alignment = align;
            t.supportRichText = false; t.raycastTarget = false;
            return t;
        }

        private readonly struct MenuItem
        {
            public readonly string Label;
            public readonly bool Enabled;
            public readonly System.Action Action;
            public readonly bool IsSeparator;
            public MenuItem(string label, bool enabled, System.Action action)
            { Label = label; Enabled = enabled; Action = action; IsSeparator = false; }
            private MenuItem(bool sep) { Label = null; Enabled = false; Action = null; IsSeparator = sep; }
            public static MenuItem Separator() => new MenuItem(true);
        }
    }

    /// <summary>Full-canvas backdrop: empty-space clicks (add menu / deselect) and click-drag to pan the diagram.</summary>
    public sealed class UmlBackground : MonoBehaviour, IPointerClickHandler, IBeginDragHandler, IDragHandler
    {
        public UmlCanvas Canvas;
        public void OnPointerClick(PointerEventData eventData) => Canvas.OnBackgroundClick(eventData);
        public void OnBeginDrag(PointerEventData e) => Canvas.BeginPan();
        public void OnDrag(PointerEventData e) => Canvas.PanBy(e.delta);
    }

    /// <summary>Dim modal backdrop behind a property/member dialog: a click on the dim area cancels the dialog.</summary>
    public sealed class UmlModalBackdrop : MonoBehaviour, IPointerClickHandler
    {
        public UmlCanvas Canvas;
        public void OnPointerClick(PointerEventData eventData) => Canvas.CancelModal();
    }
}
