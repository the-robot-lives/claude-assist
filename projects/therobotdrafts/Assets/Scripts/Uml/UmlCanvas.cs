using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using TheRobotDraft.Authoring.Commands;
using TheRobotDraft.Authoring.Model;
using TheRobotDraft.Authoring.Rules;
using TheRobotDraft.Authoring.Seams;
using TheRobotDraft.Authoring.State;
using TheRobotDraft.Uml3D;

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
            EdgeKind.Transition, EdgeKind.Include, EdgeKind.Extend,
            EdgeKind.NoteLink, EdgeKind.DirectedAssociation,
            EdgeKind.MessageSync, EdgeKind.MessageAsync, EdgeKind.MessageReply, EdgeKind.Extension,
            EdgeKind.SketchConnector,
            EdgeKind.SysmlSatisfy, EdgeKind.SysmlVerify, EdgeKind.SysmlDeriveReqt,
            EdgeKind.SysmlRefine, EdgeKind.SysmlBinding, EdgeKind.SysmlItemFlow,
            EdgeKind.BpmnSequenceFlow, EdgeKind.BpmnMessageFlow,
            EdgeKind.DmnRequirement, EdgeKind.ArchiRelationship,
        };

        /// <summary>Sequence / communication participants a message may run between (lifelines, activations, objects).</summary>
        private static bool IsInteractionNode(ElementKind k) =>
            k == ElementKind.Lifeline || k == ElementKind.Activation || k == ElementKind.ObjectInstance
            || k == ElementKind.Actor;

        private static bool IsMessage(EdgeKind k) =>
            k == EdgeKind.MessageSync || k == EdgeKind.MessageAsync || k == EdgeKind.MessageReply;
        // Classifier kinds offered when adding into a package.
        private static readonly ElementKind[] ClassifierKinds =
        {
            ElementKind.Class, ElementKind.Interface, ElementKind.Enum, ElementKind.Struct,
        };

        private static readonly Color EdgeColor = new Color(0.28f, 0.30f, 0.36f, 1f);
        private static readonly Color EdgeSelectedColor = new Color(0.12f, 0.55f, 0.85f, 1f);
        private const float EdgePickPx = 14f; // screen-space pick radius for selecting a link

        private Canvas _canvas;
        private RectTransform _root, _nodeLayer, _edgeLayer, _tabBar;
        private Font _font;
        private Text _hint;

        // The 3-D diagram scene the editor now renders into (Stage 2). The overlay Canvas above keeps every HUD
        // element (palette / tabs / hint / menus / dialogs); the diagram itself — nodes, edges, picking, camera —
        // lives here. _scene3dNodeBindings tracks which model edge maps to which live UmlEdge3D so LateUpdate can
        // re-route each frame as nodes move / the camera orbits.
        private Uml3DScene _scene;
        private readonly List<Edge3DBinding> _scene3dEdges = new();

        private struct Edge3DBinding { public UmlEdge3D View; public EdgeId Id; public ElementId From, To; public bool Directed; public EdgeKind Kind; }

        // --- 3-D link route editing (selected edge only): interior waypoints, endpoint face attachments, handles ---
        //
        // Geometry is view-state (not the authoring model's job, mirroring ADR-003 for the flat renderer). Waypoints
        // are world-space interior points in route order; the per-end face dictionaries hold a NORMALIZED offset in
        // the node's local face plane (each axis ~[-0.5,0.5]; (0,0) = face center). All three are in-session only for
        // now (not persisted — see report). Handles are live 3-D spheres rebuilt when the selected edge changes and
        // repositioned every LateUpdate so they track the route as nodes move / the camera orbits.
        private readonly Dictionary<EdgeId, List<Vector3>> _waypoints3d = new();
        private readonly Dictionary<EdgeId, Vector2> _srcFace = new();
        private readonly Dictionary<EdgeId, Vector2> _tgtFace = new();
        private readonly List<UmlEdgeHandle3D> _edgeHandles3d = new();
        private EdgeId _handlesForEdge = EdgeId.None;   // which edge _edgeHandles3d currently belongs to

        // Active 3-D handle drag (set on mouse-down over a handle; consumed each move/up).
        private bool _draggingHandle;
        private EdgeId _handleEdge = EdgeId.None;
        private UmlEdgeHandle3D.HandleRole _handleRole;
        private int _handleIndex;
        private Vector3 _handlePlanePoint;              // a point on the drag plane (the handle's start world pos)
        private Vector3 _handlePlaneNormal;             // the drag plane's normal (camera forward at grab time)

        private static readonly Color HandleWaypointColor = new Color(0.95f, 0.85f, 0.20f, 1f);   // yellow
        private static readonly Color HandleMidpointColor = new Color(0.35f, 0.85f, 0.45f, 0.7f); // translucent green
        private static readonly Color HandleAnchorColor = new Color(0.95f, 0.55f, 0.15f, 1f);     // orange

        private AuthoringModel _model;
        private AuthoringController _ctl;
        private UndoStack _history;

        private readonly Dictionary<ElementId, UmlNodeView> _nodes = new();
        // Per-diagram node geometry — position, size, continuous world-Z offset (Ctrl/Cmd+Shift+drag), slab depth,
        // and orientation — scoped by the active package/page (see PlacementStore). Replaces the former flat
        // _pos/_size/_posZ/_nodeDepth/_nodeRot dictionaries so the same element can be placed (linked, not cloned)
        // in multiple diagrams with independent geometry.
        private readonly PlacementStore _placements = new();
        private readonly List<EdgeBinding> _edges = new();
        private ElementId _activePackage = ElementId.None;
        // Active z-layer (0 = base). The canvas shows ONLY elements on this layer (in addition to the usual
        // active-package + kind filtering); off-layer elements are not instantiated. Alt+scroll changes it.
        private int _activeLayer = 0;
        // Cross-layer connector views: short stubs + chevrons drawn for edges with one endpoint on _activeLayer
        // and the other on a different (hidden) layer. Rebuilt/destroyed alongside the node + edge views.
        private readonly List<UmlEdgeView> _layerStubs = new();
        private readonly List<UmlLayerMarker> _layerMarkers = new();
        // Selection is a set; _selectedId is the PRIMARY (last-clicked) member used by single-target code paths
        // (Ctrl+C copy, context menus, edge link affordances). Empty set ⇒ _selectedId is None.
        private ElementId _selectedId = ElementId.None;
        private readonly HashSet<ElementId> _selection = new();

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

        // Sequence/communication layout view-state: each message's vertical level (layer-local y) and its
        // sequence number, plus a cache of every edge's kind (so routing can pick the horizontal message path).
        private readonly Dictionary<EdgeId, float> _msgLevel = new();
        private readonly Dictionary<EdgeId, int> _msgNumber = new();
        private readonly Dictionary<EdgeId, EdgeKind> _edgeKinds = new();

        // Per-element visual style overrides (fill / border / text color, font, size).
        private readonly Dictionary<ElementId, NodeStyle> _styles = new();

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
            public bool IsAbstract, HasPos, HasSize, HasRot;
            public Vector2 Pos, Size;
            public Quaternion Rotation;
            public NodeStyle Style;
            public readonly List<ClipMember> Members = new();
        }

        private UmlNodeView _linkSource;
        private UmlEdgeView _tempLink;
        private UmlNodeView _hoverTarget;

        private GameObject _menu;

        // Diagram zoom (mouse wheel / Ctrl +/-/0). Scales the node+edge layers around the canvas center.
        private float _zoom = 1f;
        private const float MinZoom = 0.3f, MaxZoom = 3f;

        // 2-D mode keeps the same 3-D object renderer, but presents it as a flat canvas: every node/region/edge
        // is posed on z=0, saved rotations are ignored, and camera pitch/yaw/roll/free-fly controls are clamped off.
        private bool _mode2D;
        private Image _mode2DButtonBg;
        private Text _mode2DButtonText;
        private const float FlatNodeThickness = 0.02f;
        private const float FlatRouteZ = 0.03f;

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
            // Frame the diagram in the 3-D camera so it's in view on launch (Ctrl/Cmd+F re-frames at any time).
            _scene.FrameAll();

            // On macOS, expose File / Edit / View in the real application menu bar (routes back to RunMenuCommand).
            NativeMacMenu.Install(RunMenuCommand);
        }

        // Always autosave to the default slot on quit so the next launch restores the last state, even if the user
        // has a named file open (their explicit Ctrl/Cmd+S already wrote that file).
        private void OnApplicationQuit() => WriteDiagram(DiagramPath);

        /// <summary>Route a native menu-bar command (see <see cref="NativeMacMenu"/>) to the matching action.</summary>
        public void RunMenuCommand(int cmd)
        {
            switch (cmd)
            {
                case NativeMacMenu.New: NewDiagram(); break;
                case NativeMacMenu.Open: OpenDiagramFile(); break;
                case NativeMacMenu.Save: SaveDiagram(); break;
                case NativeMacMenu.SaveAs: SaveDiagramAs(); break;
                case NativeMacMenu.ExportCode:
                    ShowCodeGenWizard(new Vector2(Screen.width * 0.5f, Screen.height * 0.5f)); break;
                case NativeMacMenu.Undo: if (!GeoUndo()) Undo(); break;
                case NativeMacMenu.Redo: if (!GeoRedo()) Redo(); break;
                case NativeMacMenu.Copy: if (_selectedId.IsValid) CopyElement(_selectedId); break;
                case NativeMacMenu.Paste: PasteElement(); break;
                case NativeMacMenu.Delete: DeleteSelected(); break;
                case NativeMacMenu.FrameAll:
                    if (_mode2D) Apply2DModeCamera(true); else _scene.FrameAll();
                    Flash("framed diagram"); break;
                case NativeMacMenu.CycleNav: CycleNavMode(false); break;
                case NativeMacMenu.Toggle2D: Toggle2DMode(); break;
            }
        }

        /// <summary>Initial sample so the editor opens showing standard UML. Fully removable (undo / delete).</summary>
        private void SeedSample()
        {
            _ctl.EnterAddNode(ElementKind.Package);
            var pkg = _ctl.CommitAddNode(ElementId.None, "Domain");
            SetActivePackage(pkg);

            ElementId Add(ElementKind k, ElementId parent, string name)
            {
                _ctl.EnterAddNode(k);
                return _ctl.CommitAddNode(parent, name);
            }

            var order = Add(ElementKind.Class, pkg, "Order");
            _placements.SetPos(order, new Vector2(-250f, 30f));
            _ctl.SetMeta(order, "C#", null);
            Add(ElementKind.Field, order, "- id : Guid");
            Add(ElementKind.Field, order, "- total : decimal");
            Add(ElementKind.Function, order, "+ submit() : void");

            var payable = Add(ElementKind.Interface, pkg, "Payable");
            _placements.SetPos(payable, new Vector2(230f, 60f));
            _ctl.SetMeta(payable, "C#", null);
            Add(ElementKind.Function, payable, "+ amountDue() : decimal");

            var note = Add(ElementKind.Note, pkg, "Order is immutable once submitted;\npayment must clear first.");
            _placements.SetPos(note, new Vector2(250f, -150f));

            var customer = Add(ElementKind.Class, pkg, "Customer");
            _placements.SetPos(customer, new Vector2(-250f, -200f));
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
            SetActivePackage(ElementId.None); _selectedId = ElementId.None;
            _selectedEdge = EdgeId.None;
            _activeLayer = 0;
            _placements.Clear();
            _waypoints.Clear(); _srcAnchor.Clear(); _tgtAnchor.Clear(); _curved.Clear(); _styles.Clear();
            _msgLevel.Clear(); _msgNumber.Clear(); _edgeKinds.Clear();
            _waypoints3d.Clear(); _srcFace.Clear(); _tgtFace.Clear();
            _packageLink.Clear();
            _nodeImage.Clear(); _imageCache.Clear();
            _sourceFiles.Clear();
            _dbBaseline.Clear(); _dbActiveBaseline = null;
            _breakpoints.Clear();
            _selectedRegion = ElementId.None;
            _geoUndo.Clear(); _geoRedo.Clear();
            ExitResizeMode();
            ClearEdgeHandles3D();
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

        /// <summary>Delete the active diagram/page package and its view-state. Not undoable.</summary>
        public void DeleteCurrentDiagram()
        {
            CloseMenu();
            if (!_activePackage.IsValid || !_model.TryGet(_activePackage, out var active) || active.Kind != ElementKind.Package)
            {
                Flash("no diagram to delete");
                return;
            }

            var roots = new List<ElementId> { _activePackage };
            foreach (var kv in _packageLink)
                if (kv.Value == _activePackage && _model.Contains(kv.Key))
                    roots.Add(kv.Key);

            var removedElements = new HashSet<ElementId>();
            foreach (var root in roots)
                CollectElementSubtree(root, removedElements);

            var removedEdges = new HashSet<EdgeId>();
            foreach (var edge in _model.Edges)
                if (removedElements.Contains(edge.From) || removedElements.Contains(edge.To))
                    removedEdges.Add(edge.Id);

            string name = active.Name;
            foreach (var root in roots)
                if (_model.Contains(root))
                    _ctl.Delete(root);

            PruneDeletedViewState(removedElements, removedEdges);
            foreach (var root in roots) _placements.RemoveDiagram(root); // drop the deleted diagram's per-diagram geometry scope
            SetActivePackage(ElementId.None);
            EnsureActivePackage();
            _ctl.ClearHistory();  // deleting a whole diagram is a document-level action
            RebuildFromModel();
            Flash("deleted diagram " + name);
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

        // --- sequence / communication auto-layout ---

        /// <summary>
        /// Lay out the active package as a sequence diagram: participants (lifelines / objects / actors) spread
        /// left-to-right, their life lines stretched to fit, and every message stacked top-to-bottom in model
        /// order with an auto-assigned sequence number.
        /// </summary>
        public void AutoArrangeSequence()
        {
            CloseMenu();
            if (!_activePackage.IsValid) { Flash("no package to arrange"); return; }

            var parts = new List<ElementId>();
            foreach (var el in _model.Elements)
                if (el.Parent == _activePackage && IsInteractionNode(el.Kind)) parts.Add(el.Id);
            if (parts.Count == 0) { Flash("add lifelines first (Sequence palette), then auto-arrange"); return; }
            parts.Sort((a, b) => PosOf(a).x.CompareTo(PosOf(b).x));
            var partSet = new HashSet<ElementId>(parts);

            var msgs = new List<EdgeId>();
            foreach (var e in _model.Edges)
                if (IsMessage(e.Kind) && partSet.Contains(e.From) && partSet.Contains(e.To)) msgs.Add(e.Id);

            const float spacing = 200f, ytop = 320f, gap = 44f;
            int m = msgs.Count;
            float H = Mathf.Max(240f, 140f + Mathf.Max(0, m - 1) * gap);
            float startX = -((parts.Count - 1) * spacing) * 0.5f;

            for (int i = 0; i < parts.Count; i++)
            {
                var id = parts[i];
                float cx = startX + i * spacing;
                if (_model.TryGet(id, out var el) && el.Kind == ElementKind.Lifeline)
                {
                    float wKeep = _placements.TrySize(id, out var s) ? s.x : 132f;
                    _placements.SetSize(id, new Vector2(wKeep, H));
                    _placements.SetPos(id, new Vector2(cx, ytop - H * 0.5f)); // align all heads at the same top
                }
                else
                {
                    _placements.SetPos(id, new Vector2(cx, ytop - 30f));
                }
            }

            _msgLevel.Clear(); _msgNumber.Clear();
            float firstLevel = ytop - 70f;
            for (int k = 0; k < m; k++) { _msgLevel[msgs[k]] = firstLevel - k * gap; _msgNumber[msgs[k]] = k + 1; }

            SetSelected(ElementId.None);
            _selectedEdge = EdgeId.None;
            RebuildFromModel();
            Flash($"sequence arranged — {parts.Count} participants, {m} messages");
        }

        private Vector2 PosOf(ElementId id) => _placements.Pos(id);

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
            if (_placements.TryPos(id, out var p)) { clip.Pos = p; clip.HasPos = true; }
            if (_placements.TrySize(id, out var sz)) { clip.Size = sz; clip.HasSize = true; }
            if (_styles.TryGetValue(id, out var style)) clip.Style = style;
            // Orientation: the stored per-node rotation, else the live node's current spin.
            if (_placements.TryRot(id, out var rot)) { clip.Rotation = rot; clip.HasRot = true; }
            else if (_scene.TryGetNode(id, out var srcNode) && srcNode != null && srcNode.LocalRotation != Quaternion.identity)
                { clip.Rotation = srcNode.LocalRotation; clip.HasRot = true; }
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
            _placements.SetPos(nid, c.HasPos ? c.Pos + new Vector2(34f, -34f) : Vector2.zero);
            _ctl.SetZLayer(nid, _activeLayer); // paste onto the active layer
            if (c.Style.Has) _styles[nid] = c.Style;
            if (c.HasSize) _placements.SetSize(nid, c.Size);       // carry size
            if (c.HasRot) _placements.SetRot(nid, c.Rotation); // carry orientation (applied on rebuild)
            RebuildFromModel();
            SetSelected(nid);
            Flash("pasted (renamed)");
        }

        // --- copy multiple selected nodes as an image (PNG → OS clipboard) ---

        /// <summary>True only if every selected element is a plain diagram node (no boundaries / regions / packages).</summary>
        private bool AllSelectedAreCopyableNodes()
        {
            foreach (var id in _selection)
            {
                if (!_model.TryGet(id, out var el)) return false;
                if (el.Kind == ElementKind.Package || !KindInfo.IsDiagramNode(el.Kind)) return false;
                // Regions (boundary / frame / profile) wrap other nodes — exclude them from an image snapshot.
                if (_nodes.TryGetValue(id, out var nv) && nv != null && nv.IsBoundary) return false;
            }
            return true;
        }

        /// <summary>Snapshot the bounding box of the selected nodes to a PNG and hand it to the OS clipboard.</summary>
        public void CopySelectionAsPng()
        {
            CloseMenu();
            if (_selection.Count < 2) { Flash("select 2+ boxes to copy as PNG"); return; }
            StartCoroutine(CaptureSelectionPng());
        }

        /// <summary>Screen-space padding added around the selected nodes' projected bounds before cropping.</summary>
        private const float SelectionPngPaddingPx = 24f;

        private IEnumerator CaptureSelectionPng()
        {
            // Capture after the frame is fully drawn (the menu is already closed above). The overlay HUD draws
            // on the ScreenSpaceOverlay canvas, NOT through this camera, so the captured image is the clean
            // diagram without menus.
            yield return new WaitForEndOfFrame();

            var cam = _scene != null ? _scene.Camera : null;
            if (cam == null) { Flash("no scene camera to capture"); yield break; }

            int w = Mathf.Max(1, Screen.width), h = Mathf.Max(1, Screen.height);

            // Frame the crop around the selected nodes' world bounds (current camera pose, before any hiding).
            Bounds bounds = default;
            bool anyBounds = false;
            foreach (var id in _selection)
            {
                if (!_scene.TryGetNode(id, out var n) || n == null) continue;
                var col = n.GetComponentInChildren<Collider>();
                if (col == null) continue;
                if (!anyBounds) { bounds = col.bounds; anyBounds = true; } else bounds.Encapsulate(col.bounds);
            }
            Rect crop = anyBounds ? ProjectBoundsToScreenRect(bounds, w, h) : new Rect(0f, 0f, w, h);

            // Isolate the selection: hide every other node + all edges so occluding/occluded geometry never
            // bleeds into the snapshot, render off-screen against a transparent backdrop, then restore
            // visibility before this coroutine yields again (no frame is ever presented with nodes hidden).
            var hiddenNodes = new List<GameObject>();
            foreach (var kv in _scene.Nodes)
            {
                var n = kv.Value;
                if (n == null || _selection.Contains(kv.Key) || !n.gameObject.activeSelf) continue;
                n.gameObject.SetActive(false);
                hiddenNodes.Add(n.gameObject);
            }
            _scene.SetEdgesVisible(false);

            var rt = new RenderTexture(w, h, 24, RenderTextureFormat.ARGB32);
            var prevTarget = cam.targetTexture;
            var prevActive = RenderTexture.active;
            var prevClearFlags = cam.clearFlags;
            var prevBgColor = cam.backgroundColor;
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = new Color(0f, 0f, 0f, 0f); // transparent backdrop around the isolated selection
            cam.targetTexture = rt;
            cam.Render();

            RenderTexture.active = rt;
            var tex = new Texture2D(Mathf.Max(1, (int)crop.width), Mathf.Max(1, (int)crop.height), TextureFormat.RGBA32, false);
            tex.ReadPixels(crop, 0, 0);
            tex.Apply();

            cam.targetTexture = prevTarget;
            cam.clearFlags = prevClearFlags;
            cam.backgroundColor = prevBgColor;
            RenderTexture.active = prevActive;

            foreach (var go in hiddenNodes) if (go != null) go.SetActive(true);
            _scene.SetEdgesVisible(true);

            byte[] png = tex.EncodeToPNG();
            Destroy(tex);
            rt.Release();
            Destroy(rt);

            string status = UmlImageClipboard.SaveAndCopyToClipboard(png);
            Flash(status);
        }

        /// <summary>Project a world-space AABB's 8 corners to a padded, camera-clamped screen-space crop rect.
        /// Falls back to the full frame if every corner projects behind the camera.</summary>
        private Rect ProjectBoundsToScreenRect(Bounds b, int screenW, int screenH)
        {
            Vector3 min = b.min, max = b.max;
            float minX = float.MaxValue, minY = float.MaxValue, maxX = float.MinValue, maxY = float.MinValue;
            for (int i = 0; i < 8; i++)
            {
                var corner = new Vector3(
                    (i & 1) == 0 ? min.x : max.x,
                    (i & 2) == 0 ? min.y : max.y,
                    (i & 4) == 0 ? min.z : max.z);
                Vector3 sp = _scene.WorldToScreen(corner);
                if (sp.z <= 0f) continue; // behind the camera — ignore for framing
                minX = Mathf.Min(minX, sp.x); minY = Mathf.Min(minY, sp.y);
                maxX = Mathf.Max(maxX, sp.x); maxY = Mathf.Max(maxY, sp.y);
            }
            if (minX > maxX || minY > maxY) return new Rect(0f, 0f, screenW, screenH);
            minX = Mathf.Clamp(minX - SelectionPngPaddingPx, 0f, screenW);
            minY = Mathf.Clamp(minY - SelectionPngPaddingPx, 0f, screenH);
            maxX = Mathf.Clamp(maxX + SelectionPngPaddingPx, 0f, screenW);
            maxY = Mathf.Clamp(maxY + SelectionPngPaddingPx, 0f, screenH);
            return new Rect(minX, minY, Mathf.Max(1f, maxX - minX), Mathf.Max(1f, maxY - minY));
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

        // --- toolbar palette: create a node by dragging a palette item onto the canvas (click does not insert) ---

        private GameObject _paletteGhost;
        private ElementKind _paletteDragKind;

        public void CreateNodeFromPalette(ElementKind kind, Vector2 screenPos)
        {
            CloseMenu();
            bool isPackage = kind == ElementKind.Package;
            if (!isPackage && !_activePackage.IsValid) { Flash("add a package first (palette → Package)"); return; }

            _ctl.EnterAddNode(kind);
            var id = _ctl.CommitAddNode(isPackage ? ElementId.None : _activePackage, DefaultName(kind));
            if (!id.IsValid) { Flash("can't place " + kind + " here"); _ctl.EnterSelect(); return; }
            if (isPackage) SetActivePackage(id);
            else
            {
                var defaults = DefaultPropertyItems(kind);
                if (defaults.Length > 0) _ctl.SetPropertyItems(id, defaults);
                _placements.SetPos(id, ScreenToModelPx(screenPos)); _ctl.SetZLayer(id, _activeLayer);
            } // insert on the active layer
            _ctl.EnterSelect();
            RebuildFromModel();
            SetSelected(id);
            Flash("added " + kind);
        }

        private string DefaultName(ElementKind kind) => kind switch
        {
            ElementKind.Note => "note",
            ElementKind.Actor => "Actor",
            ElementKind.UseCase => "Use Case",
            ElementKind.State => "State",
            ElementKind.StateStart => "start",
            ElementKind.StateEnd => "end",
            ElementKind.Interface => "I" + CountOf(kind),
            ElementKind.Enum => "Enum" + CountOf(kind),
            ElementKind.Package => "Package" + CountOf(kind),
            ElementKind.Boundary => "System",
            ElementKind.Decision => "decision" + CountOf(kind),
            ElementKind.ForkJoin => "fork" + CountOf(kind),
            ElementKind.Junction => "junction" + CountOf(kind),
            ElementKind.History => "history",
            ElementKind.Terminate => "terminate",
            ElementKind.FlowFinal => "flow-final" + CountOf(kind),
            ElementKind.Activity => "Action",
            ElementKind.AsyncSend => "send signal",
            ElementKind.AsyncReceive => "receive event",
            ElementKind.Component => "Component" + CountOf(kind),
            ElementKind.Artifact => "artifact.bin",
            ElementKind.DeploymentNode => "Node" + CountOf(kind),
            ElementKind.ObjectInstance => "obj : Class",
            ElementKind.DataType => "DataType" + CountOf(kind),
            ElementKind.PrimitiveType => "Integer",
            ElementKind.PackageNode => "Package" + CountOf(kind),
            ElementKind.Part => "part : Type",
            ElementKind.Port => "p",
            ElementKind.Collaboration => "Collaboration",
            ElementKind.Lifeline => "obj : Class",
            ElementKind.Activation => "exec",
            ElementKind.Frame => "sd interaction",
            ElementKind.Metaclass => "Class",
            ElementKind.Stereotype => "Entity",
            ElementKind.Profile => "«profile» P",
            ElementKind.TimingLifeline => "obj : Class",
            ElementKind.CallActivity => "Activity",
            // Wireframe / UI — friendly defaults per widget instead of the "Kind1" fallback.
            ElementKind.Screen => "Screen" + CountOf(kind),
            ElementKind.Panel => "Panel" + CountOf(kind),
            ElementKind.UiWidget => "Widget" + CountOf(kind),
            ElementKind.Button => "Button",
            ElementKind.Label => "Label",
            ElementKind.Link => "link",
            ElementKind.TextField => "text input",
            ElementKind.TextArea => "textarea",
            ElementKind.Password => "password",
            ElementKind.Checkbox => "option",
            ElementKind.Radio => "option",
            ElementKind.Dropdown => "select",
            ElementKind.List => "List",
            ElementKind.Table => "Table",
            ElementKind.Tree => "Tree",
            ElementKind.Image => "image",
            ElementKind.Tabs => "Tabs",
            ElementKind.Menu => "Menu",
            ElementKind.Toolbar => "Toolbar",
            ElementKind.Breadcrumb => "breadcrumbs",
            ElementKind.Card => "Card" + CountOf(kind),
            ElementKind.Separator => "—",
            ElementKind.Progress => "progress",
            ElementKind.Slider => "slider",
            ElementKind.WhiteboardFrame => "Whiteboard",
            ElementKind.WhiteboardSticky => "sticky note",
            ElementKind.WhiteboardCard => "Idea card",
            ElementKind.WhiteboardText => "Text",
            ElementKind.WhiteboardCircle => "Circle",
            ElementKind.WhiteboardDiamond => "Decision",
            ElementKind.SysmlBlock => "Block" + CountOf(kind),
            ElementKind.SysmlValueType => "ValueType" + CountOf(kind),
            ElementKind.SysmlConstraintBlock => "Constraint" + CountOf(kind),
            ElementKind.SysmlRequirement => "REQ-" + CountOf(kind),
            ElementKind.SysmlProxyPort => "proxy",
            ElementKind.SysmlFullPort => "port",
            ElementKind.SysmlParameter => "parameter",
            ElementKind.BpmnEvent => "Event",
            ElementKind.BpmnActivity => "Activity",
            ElementKind.BpmnGateway => "Gateway",
            ElementKind.BpmnDataObject => "Data Object",
            ElementKind.BpmnDataStore => "Data Store",
            ElementKind.BpmnPool => "Pool",
            ElementKind.BpmnLane => "Lane",
            ElementKind.BpmnChoreographyTask => "Choreography",
            ElementKind.BpmnConversation => "Conversation",
            ElementKind.DmnDecision => "Decision",
            ElementKind.DmnInputData => "Input Data",
            ElementKind.DmnBusinessKnowledge => "Business Knowledge",
            ElementKind.DmnKnowledgeSource => "Knowledge Source",
            ElementKind.DmnDecisionService => "Decision Service",
            ElementKind.DmnTextAnnotation => "Annotation",
            ElementKind.ArchiBusinessActor => "Business Actor",
            ElementKind.ArchiBusinessProcess => "Business Process",
            ElementKind.ArchiApplicationComponent => "Application Component",
            ElementKind.ArchiApplicationService => "Application Service",
            ElementKind.ArchiDataObject => "Data Object",
            ElementKind.ArchiNode => "Node",
            ElementKind.ArchiDevice => "Device",
            ElementKind.ArchiSystemSoftware => "System Software",
            ElementKind.ArchiTechnologyService => "Technology Service",
            ElementKind.ArchiCapability => "Capability",
            ElementKind.ArchiOutcome => "Outcome",
            ElementKind.ArchiRequirement => "Requirement",
            ElementKind.ArchiPrinciple => "Principle",
            ElementKind.ArchiWorkPackage => "Work Package",
            ElementKind.ArchiDeliverable => "Deliverable",
            ElementKind.ArchiPlateau => "Plateau",
            ElementKind.ArchiGap => "Gap",
            ElementKind.BusinessCapability => "Capability",
            ElementKind.ValueStream => "Value Stream",
            ElementKind.ValueChainActivity => "Value Chain Activity",
            ElementKind.StrategyObjective => "Objective",
            ElementKind.BalancedScorecardPerspective => "Perspective",
            ElementKind.OrgUnit => "Org Unit",
            ElementKind.HeatMapItem => "Heat Item",
            ElementKind.DecisionTreeNode => "Decision",
            ElementKind.UafOperationalNode => "Operational Node",
            ElementKind.UafService => "Service",
            ElementKind.UafResource => "Resource",
            ElementKind.UafCapability => "Capability",
            ElementKind.TogafArchitectureBuildingBlock => "Architecture Building Block",
            ElementKind.TogafArchitecturePhase => "ADM Phase",
            ElementKind.ZachmanCell => "Zachman Cell",
            _ => kind.ToString() + CountOf(kind),
        };

        private static string[] DefaultPropertyItems(ElementKind kind) => kind switch
        {
            ElementKind.SysmlBlock => new[] { "parts=", "values=", "ports=" },
            ElementKind.SysmlValueType => new[] { "unit=", "quantityKind=" },
            ElementKind.SysmlConstraintBlock => new[] { "constraint=", "parameters=" },
            ElementKind.SysmlRequirement => new[] { "id=", "text=", "risk=medium", "status=proposed" },
            ElementKind.SysmlProxyPort => new[] { "direction=inout", "type=InterfaceBlock" },
            ElementKind.SysmlFullPort => new[] { "direction=inout", "type=Block" },
            ElementKind.SysmlParameter => new[] { "type=Real", "unit=" },
            ElementKind.BpmnEvent => new[] { "event=start", "trigger=message" },
            ElementKind.BpmnActivity => new[] { "task=user", "loop=false" },
            ElementKind.BpmnGateway => new[] { "gateway=exclusive" },
            ElementKind.BpmnDataObject => new[] { "state=", "collection=false" },
            ElementKind.BpmnDataStore => new[] { "store=persistent" },
            ElementKind.BpmnPool => new[] { "participant=", "process=" },
            ElementKind.BpmnLane => new[] { "role=" },
            ElementKind.BpmnChoreographyTask => new[] { "initiatingParticipant=", "respondingParticipant=" },
            ElementKind.BpmnConversation => new[] { "conversation=" },
            ElementKind.DmnDecision => new[] { "question=", "logic=decision table" },
            ElementKind.DmnInputData => new[] { "type=", "source=" },
            ElementKind.DmnBusinessKnowledge => new[] { "knowledgeModel=", "authority=" },
            ElementKind.DmnKnowledgeSource => new[] { "authority=", "reference=" },
            ElementKind.DmnDecisionService => new[] { "inputs=", "outputs=" },
            ElementKind.DmnTextAnnotation => new[] { "text=" },
            ElementKind.ArchiBusinessActor => new[] { "layer=business", "aspect=active structure" },
            ElementKind.ArchiBusinessProcess => new[] { "layer=business", "aspect=behavior" },
            ElementKind.ArchiApplicationComponent => new[] { "layer=application", "aspect=active structure" },
            ElementKind.ArchiApplicationService => new[] { "layer=application", "aspect=service" },
            ElementKind.ArchiDataObject => new[] { "layer=application", "aspect=passive structure" },
            ElementKind.ArchiNode => new[] { "layer=technology", "aspect=active structure" },
            ElementKind.ArchiDevice => new[] { "layer=technology", "aspect=device" },
            ElementKind.ArchiSystemSoftware => new[] { "layer=technology", "aspect=system software" },
            ElementKind.ArchiTechnologyService => new[] { "layer=technology", "aspect=service" },
            ElementKind.ArchiCapability => new[] { "layer=strategy", "maturity=" },
            ElementKind.ArchiOutcome => new[] { "layer=strategy", "measure=" },
            ElementKind.ArchiRequirement => new[] { "layer=motivation", "requirement=" },
            ElementKind.ArchiPrinciple => new[] { "layer=motivation", "principle=" },
            ElementKind.ArchiWorkPackage => new[] { "layer=implementation", "status=planned" },
            ElementKind.ArchiDeliverable => new[] { "layer=implementation", "version=" },
            ElementKind.ArchiPlateau => new[] { "layer=implementation", "date=" },
            ElementKind.ArchiGap => new[] { "layer=implementation", "from=", "to=" },
            ElementKind.BusinessCapability => new[] { "maturity=", "owner=", "criticality=" },
            ElementKind.ValueStream => new[] { "stage=", "outcome=" },
            ElementKind.ValueChainActivity => new[] { "primary=true", "owner=" },
            ElementKind.StrategyObjective => new[] { "measure=", "target=" },
            ElementKind.BalancedScorecardPerspective => new[] { "perspective=financial", "theme=" },
            ElementKind.OrgUnit => new[] { "role=", "headcount=" },
            ElementKind.HeatMapItem => new[] { "score=medium", "metric=" },
            ElementKind.DecisionTreeNode => new[] { "condition=", "outcome=" },
            ElementKind.UafOperationalNode => new[] { "view=operational", "role=" },
            ElementKind.UafService => new[] { "view=services", "interface=" },
            ElementKind.UafResource => new[] { "view=resources", "type=" },
            ElementKind.UafCapability => new[] { "view=capability", "phase=" },
            ElementKind.TogafArchitectureBuildingBlock => new[] { "domain=", "artifact=" },
            ElementKind.TogafArchitecturePhase => new[] { "phase=", "objective=" },
            ElementKind.ZachmanCell => new[] { "row=", "column=" },
            _ => System.Array.Empty<string>(),
        };

        public void BeginPaletteDrag(ElementKind kind, string label)
        {
            CloseMenu();
            _paletteDragKind = kind;
            if (_paletteGhost != null) Destroy(_paletteGhost);
            _paletteGhost = new GameObject("PaletteGhost", typeof(RectTransform));
            var rt = (RectTransform)_paletteGhost.transform;
            rt.SetParent(_root, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0f, 0f);
            rt.pivot = new Vector2(0.5f, 0.5f);
            rt.sizeDelta = new Vector2(120f, 28f);
            var img = _paletteGhost.AddComponent<Image>();
            img.color = new Color(0.20f, 0.45f, 0.65f, 0.85f);
            img.raycastTarget = false;
            var tgo = new GameObject("L", typeof(RectTransform));
            var trt = (RectTransform)tgo.transform;
            trt.SetParent(rt, false);
            trt.anchorMin = Vector2.zero; trt.anchorMax = Vector2.one;
            trt.offsetMin = Vector2.zero; trt.offsetMax = Vector2.zero;
            var tx = tgo.AddComponent<Text>();
            tx.font = _font; tx.text = label; tx.fontSize = 14; tx.alignment = TextAnchor.MiddleCenter;
            tx.color = new Color(0.96f, 0.98f, 1f, 1f); tx.raycastTarget = false;
        }

        public void UpdatePaletteDrag(Vector2 screenPos)
        {
            if (_paletteGhost != null)
                ((RectTransform)_paletteGhost.transform).anchoredPosition = screenPos / Mathf.Max(ScaleFactor, 0.0001f);
        }

        public void EndPaletteDrag(Vector2 screenPos)
        {
            if (_paletteGhost != null) { Destroy(_paletteGhost); _paletteGhost = null; }
            if (screenPos.x < (PaletteActiveWidth + 8f) * ScaleFactor) { Flash("drop onto the canvas to create"); return; }
            CreateNodeFromPalette(_paletteDragKind, screenPos);
        }

        private void Update()
        {
            // Track the one-frame screen-space mouse delta up front (before any early return) so camera orbit / pan
            // drags get a consistent per-frame movement regardless of which branch handles this frame.
            Vector2 mp = Input.mousePosition;
            _mouseDelta = mp - _lastMousePos;
            _lastMousePos = mp;

            // Watch any shadow source files opened in VS Code; a save there re-syncs the node from its code.
            PollShadowFiles();

            // Run any commands clicked in the native macOS menu bar (queued on the AppKit thread).
            NativeMacMenu.Drain();

            if (Input.GetKeyDown(KeyCode.Escape)) { CloseMenu(); return; }

            // Don't steal typing from the name prompt.
            if (EventSystem.current != null && EventSystem.current.currentSelectedGameObject != null
                && EventSystem.current.currentSelectedGameObject.GetComponent<InputField>() != null)
                return;

            bool ctrl = CtrlOrCmd();
            bool shift = Input.GetKey(KeyCode.LeftShift) || Input.GetKey(KeyCode.RightShift);
            if (ctrl && Input.GetKeyDown(KeyCode.S)) { if (shift) SaveDiagramAs(); else SaveDiagram(); return; }
            if (ctrl && Input.GetKeyDown(KeyCode.O)) { OpenDiagramFile(); return; }
            if (ctrl && Input.GetKeyDown(KeyCode.C)) { if (_selectedId.IsValid) CopyElement(_selectedId); return; }
            if (ctrl && Input.GetKeyDown(KeyCode.V))
            {
                // An image on the OS clipboard pastes as an Object node; otherwise fall through to element paste.
                var clipPng = UmlImageClipboard.TryReadClipboardPng();
                if (clipPng != null) PasteImageAsObjectNode(new Vector2(Screen.width * 0.5f, Screen.height * 0.5f));
                else PasteElement();
                return;
            }
            // Undo/redo: a move/resize (geometry) is undone first if any is pending, else the model edit history.
            if (ctrl && Input.GetKeyDown(KeyCode.Z)) { if (shift) { if (!GeoRedo()) Redo(); } else { if (!GeoUndo()) Undo(); } }
            else if (ctrl && Input.GetKeyDown(KeyCode.Y)) { if (!GeoRedo()) Redo(); }
            else if (Input.GetKeyDown(KeyCode.Delete) || Input.GetKeyDown(KeyCode.Backspace)) DeleteSelected();

            if (ctrl && (Input.GetKeyDown(KeyCode.F)))
            {
                if (_mode2D) Apply2DModeCamera(true);
                else _scene.FrameAll();
                Flash("framed diagram");
            }

            // N cycles the empty-space drag mode (orbit → pan → X → Y → Z); Shift+N reverses.
            if (!ctrl && Input.GetKeyDown(KeyCode.N)) CycleNavMode(shift);

            // Volumetric marquee depth (Shift-held only — see EndMarquee3D): Shift+D / Shift+"+"/"=" grow the
            // depth reach one step, Shift+"-" shrinks it, Shift+F collapses back to 0 (flat "square" select).
            if (shift)
            {
                if (Input.GetKeyDown(KeyCode.D)) AdjustMarqueeDepthReach(MarqueeDepthStepKey);
                if (Input.GetKeyDown(KeyCode.Equals) || Input.GetKeyDown(KeyCode.KeypadPlus)) AdjustMarqueeDepthReach(MarqueeDepthStepKey);
                if (Input.GetKeyDown(KeyCode.Minus) || Input.GetKeyDown(KeyCode.KeypadMinus)) AdjustMarqueeDepthReach(-MarqueeDepthStepKey);
                if (!ctrl && Input.GetKeyDown(KeyCode.F)) ResetMarqueeDepthReach();
            }

            // Mouse wheel dollies the 3-D camera; Shift+wheel instead grows/shrinks the volumetric marquee's depth
            // reach; Alt+wheel jumps the camera a fixed step along world Z (the replacement for the old up/down-a-
            // layer navigation — there is no active-layer "pane" anymore, the whole diagram is shown in depth at
            // once). The overlay UI does not zoom.
            float scroll = Input.mouseScrollDelta.y;
            if (Mathf.Abs(scroll) > 0.01f && !PointerOverUI())
            {
                if (shift) { AdjustMarqueeDepthReach(scroll > 0f ? MarqueeDepthStepScroll : -MarqueeDepthStepScroll); return; }
                if (!_mode2D && AltDown()) JumpCameraZ(scroll > 0f ? 1 : -1);
                else _scene.Dolly(scroll);
                if (_mode2D) Apply2DModeCamera(false);
                return;
            }

            // 6-DOF camera keys (gated by the InputField guard above so they never fire while typing): Q/E roll,
            // W/S fly forward/back, A/D strafe, R/F rise/descend. Held-key driven, scaled by Time.deltaTime.
            // Suppressed while Shift is held — D/F are reused above for the volumetric-marquee depth controls, and
            // free-flying the camera mid Shift-gesture (marquee drag or depth tweak) would fight both.
            if (!_mode2D && !shift) HandleCameraKeys(ctrl);

            HandleSceneMouse(ctrl, shift, AltDown());
        }

        // --- 3-D diagram pointer interaction (pick / select / orbit / dolly / pan / drag-move) ---
        //
        // Nodes are 3-D objects, not uGUI elements, so their pointer handling lives here (the EventSystem only drives
        // the 2-D overlay HUD). On mouse-down a scene raycast decides the gesture: a node hit under Ctrl/Cmd begins a
        // drag-move (Stage 3 adds per-node rotation / connect-by-drag); any other drag orbits the camera (Ctrl/Cmd on
        // empty space pans the pivot). A click (no drag) selects the picked node (Shift toggles), or clears / opens
        // the empty-space menu on a miss.

        private bool _scenePointerDown;     // a left-press began over the diagram (not the HUD)
        private bool _sceneDragging;        // the press has moved far enough to count as a drag
        private bool _draggingNode;         // the active drag is moving a node (Ctrl+press on a node)
        private bool _zMovingNode;          // the active drag slides a node along world Z (Ctrl+Shift+press on a node)
        private bool _rotatingNode;         // the active drag spins a node in place (Alt+press on a node)
        private bool _resizingNode;         // the active drag resizes a node (Ctrl+Alt+press on a node)
        private bool _connecting;           // the active drag is a connect-by-drag from a source node
        private bool _marqueeDrag;          // the active drag is a Shift+empty-space rubber-band selection
        private bool _panGesture;           // the active camera drag pans the pivot (Ctrl) vs. orbits
        private ElementId _dragNode = ElementId.None;
        private float _dragPlaneZ;          // world-Z of the node-drag plane (the dragged node's plane)
        private Vector3 _dragLastWorld;     // last projected world point, for per-frame deltas
        private Vector2 _pressScreenPos;
        private const float DragThresholdPx = 4f;

        // Volumetric marquee: extra depth (world units, behind the nearest match) swept by a Shift-marquee, on
        // top of its screen-space rect. Persists across drags — Shift+D / Shift+scroll / Shift+"+"/"-" grow or
        // shrink it, Shift+F resets it — so 0 always means the flat "square select" every other gesture keeps.
        private float _marqueeDepthReach;
        private const float MarqueeDepthEpsilon = 0.05f; // slack so the nearest match's own depth always counts
        private const float MarqueeDepthStepKey = 0.5f;
        private const float MarqueeDepthStepScroll = 0.25f;

        // Connect-by-drag (no modifier on a node): a temporary 3-D rubber-band edge from the source node's
        // center to the cursor's point on the source node's world-Z plane, plus the node currently hovered.
        private ElementId _connectSource = ElementId.None;
        private float _connectPlaneZ;
        private UmlEdge3D _connectRubber;
        private ElementId _connectHover = ElementId.None;
        private const float RotateDegPerPx = 0.3f;
        private static readonly Color ConnectColor = new Color(0.20f, 0.55f, 0.85f, 1f);

        // Per-second rates for the 6-DOF camera keys (roll in deg/s, fly/strafe/rise in MoveLocal units/s).
        private const float RollDegPerSec = 90f;
        private const float FlyUnitsPerSec = 1.2f;

        /// <summary>
        /// Drive the camera rig's roll + free-fly translation from held keys. Movement keys (WASD/RF) are
        /// suppressed while Ctrl/Cmd is held so they don't fight the editor shortcuts (Ctrl+S/C/V/Z/Y); roll
        /// (Q/E) has no shortcut conflict and is always live. Reached through <c>_scene.Rig</c> — no edit to
        /// Uml3DScene is needed since it already exposes the rig.
        /// </summary>
        private void HandleCameraKeys(bool ctrl)
        {
            var rig = _scene != null ? _scene.Rig : null;
            if (rig == null) return;
            float dt = Time.deltaTime;

            // Roll about the view axis: Q rolls one way, E the other.
            float roll = 0f;
            if (Input.GetKey(KeyCode.Q)) roll -= 1f;
            if (Input.GetKey(KeyCode.E)) roll += 1f;
            if (roll != 0f) rig.RollBy(roll * RollDegPerSec * dt);

            if (ctrl) return; // leave WASD/RF to the editor shortcuts while a modifier is down

            // Free-fly translation along the camera's own axes: x = strafe, y = rise, z = forward.
            Vector3 move = Vector3.zero;
            if (Input.GetKey(KeyCode.W)) move.z += 1f;
            if (Input.GetKey(KeyCode.S)) move.z -= 1f;
            if (Input.GetKey(KeyCode.D)) move.x += 1f;
            if (Input.GetKey(KeyCode.A)) move.x -= 1f;
            if (Input.GetKey(KeyCode.R)) move.y += 1f;
            if (Input.GetKey(KeyCode.F)) move.y -= 1f;
            if (move != Vector3.zero) rig.MoveLocal(move * (FlyUnitsPerSec * dt));
        }

        private void HandleSceneMouse(bool ctrl, bool shift, bool alt)
        {
            // Right-click: pick → node menu, else empty-space menu. (Handled on button-up via the press tracking
            // below would conflict with drag; right-click is a discrete action so resolve it immediately.)
            if (Input.GetMouseButtonDown(1) && !PointerOverUI())
            {
                Vector2 sp = Input.mousePosition;
                var hit = _scene.Raycast(sp);
                if (hit != null) ShowNodeMenu(hit.Id, sp);
                else
                {
                    var reg = PickRegion3D(sp);
                    if (reg != null) ShowRegionMenu(reg.Id, sp);
                    else
                    {
                        var eid = PickEdge3D(sp);
                        if (eid.IsValid) { Select3DEdge(eid); ShowEdgeMenu(eid, sp); }
                        else { ClearSelectedEdge(); ShowEmptyMenu(sp); }
                    }
                }
                return;
            }

            if (Input.GetMouseButtonDown(0))
            {
                if (PointerOverUI()) { _scenePointerDown = false; return; }

                // G + click on a node: center the camera on it, facing its front face at a fixed legible distance.
                if (Input.GetKey(KeyCode.G))
                {
                    var focusHit = _scene.Raycast(Input.mousePosition);
                    if (focusHit != null) { FocusOnNode(focusHit.Id); _scenePointerDown = false; return; }
                }

                // Route-edit handles on the selected link take priority over the node / edge / camera gestures: test
                // for a handle hit FIRST. A hit begins a handle drag (or, for Alt+click on a waypoint, deletes it).
                if (TryBeginEdgeHandleDrag3D(Input.mousePosition, alt))
                {
                    _scenePointerDown = false; // the handle owns this press; don't also start a scene gesture
                    return;
                }

                // Resize handles on a double-clicked node take priority too.
                if (_resizeModeNode.IsValid && TryBeginResizeDrag(Input.mousePosition))
                {
                    _scenePointerDown = false;
                    return;
                }

                _scenePointerDown = true;
                _sceneDragging = false;
                _draggingNode = _zMovingNode = _rotatingNode = _resizingNode = _connecting = _marqueeDrag = false;
                _draggingRegion = _resizingRegion = _regionPressed = false;
                _regionDrag = ElementId.None;
                _dragNode = _connectSource = _connectHover = ElementId.None;
                _pressScreenPos = Input.mousePosition;
                var hit = _scene.Raycast(_pressScreenPos);
                if (hit != null)
                {
                    // On a node: Ctrl/Cmd+Shift+drag → slide along world Z, Ctrl/Cmd+drag → move in XY, Ctrl/Cmd+CLICK
                    // → toggle resize handles, Alt+drag → rotate-in-place, no modifier → connect-by-drag / double-click
                    // → edit modal. (BeginGeoEdit is deferred to drag-start so a click pushes no undo step.)
                    if (!_mode2D && ctrl && shift)
                    {
                        _zMovingNode = true;
                        _dragNode = hit.Id;
                    }
                    else if (ctrl)
                    {
                        _draggingNode = true;
                        _dragNode = hit.Id;
                        _dragPlaneZ = hit.transform.position.z;
                        _dragLastWorld = ProjectToPlane(_pressScreenPos, _dragPlaneZ);
                    }
                    else if (!_mode2D && alt)
                    {
                        _rotatingNode = true;
                        _dragNode = hit.Id;
                    }
                    else
                    {
                        _connecting = true;
                        _connectSource = hit.Id;
                        _connectPlaneZ = hit.transform.position.z;
                    }
                    _panGesture = false;
                }
                else
                {
                    // No node hit: a region cube edge may be under the cursor — grab it for select / move / resize.
                    var reg = PickRegion3D(_pressScreenPos);
                    if (reg != null)
                    {
                        _regionPressed = true;
                        _regionDrag = reg.Id;
                        _marqueeDrag = false; _panGesture = false;
                        if (ctrl && alt) { _resizingRegion = true; }
                        else if (ctrl)
                        {
                            _draggingRegion = true;
                            _regionPlaneZ = reg.CurrentBounds.center.z;
                            _regionLastWorld = ProjectToPlane(_pressScreenPos, _regionPlaneZ);
                            CaptureRegionMembers(reg.Id);
                        }
                    }
                    else
                    {
                        // Empty space: Shift → marquee select, Ctrl/Cmd → pan pivot, plain → navigate.
                        _marqueeDrag = shift;
                        _panGesture = ctrl && !shift;
                    }
                }
                return;
            }

            // Active route-edit handle drag (owns the press; runs independently of the scene-gesture tracking).
            if (_draggingHandle)
            {
                if (Input.GetMouseButton(0)) { UpdateEdgeHandleDrag3D(Input.mousePosition); return; }
                if (Input.GetMouseButtonUp(0)) { EndEdgeHandleDrag3D(); return; }
                return;
            }

            // Active node-resize drag (owns the press).
            if (_resizing3d)
            {
                if (Input.GetMouseButton(0)) { DragResize3D(GetMouseDelta()); return; }
                if (Input.GetMouseButtonUp(0)) { _resizing3d = false; _resizeNode = ElementId.None; Flash("resized"); return; }
                return;
            }

            if (_scenePointerDown && Input.GetMouseButton(0))
            {
                Vector2 cur = Input.mousePosition;
                if (!_sceneDragging && ((Vector2)cur - _pressScreenPos).sqrMagnitude > DragThresholdPx * DragThresholdPx)
                {
                    _sceneDragging = true;
                    // Snapshot geometry once, when a move/resize drag actually starts (so a Ctrl+click that never
                    // drags doesn't push a no-op undo step).
                    if (_draggingNode || _zMovingNode || _draggingRegion || _resizingRegion) BeginGeoEdit();
                    if (!_draggingNode && !_zMovingNode && !_rotatingNode && !_resizingNode) CloseMenu();
                    if (_connecting) BeginConnectRubber();
                    else if (_marqueeDrag) BeginMarquee(_pressScreenPos);
                }
                if (_sceneDragging)
                {
                    if (_draggingNode) DragNode(cur);
                    else if (_zMovingNode) DragNodeZ(GetMouseDelta());
                    else if (_resizingNode) ResizeNode(GetMouseDelta());
                    else if (_rotatingNode) RotateNode(GetMouseDelta());
                    else if (_draggingRegion) DragRegion(cur);
                    else if (_resizingRegion) ResizeRegion(GetMouseDelta());
                    else if (_connecting) UpdateConnectRubber(cur);
                    else if (_marqueeDrag) UpdateMarquee(cur);
                    else if (_panGesture) _scene.PanPivot(GetMouseDelta()); // Ctrl/Cmd-drag always pans
                    else NavigateEmptyDrag(GetMouseDelta());                 // otherwise follow the Navigate mode
                }
                return;
            }

            if (_scenePointerDown && Input.GetMouseButtonUp(0))
            {
                bool wasDrag = _sceneDragging;
                bool wasNodeDrag = _draggingNode;
                bool wasZMove = _zMovingNode;
                bool wasRotate = _rotatingNode;
                bool wasResize = _resizingNode;
                bool wasConnect = _connecting;
                bool wasMarquee = _marqueeDrag;
                bool wasRegionDrag = _draggingRegion;
                bool wasRegionResize = _resizingRegion;
                bool wasRegionPress = _regionPressed;
                ElementId regId = _regionDrag;
                _scenePointerDown = false;
                _sceneDragging = false;
                _draggingNode = _zMovingNode = _rotatingNode = _resizingNode = _connecting = _marqueeDrag = false;
                _draggingRegion = _resizingRegion = _regionPressed = false;
                _regionDrag = ElementId.None;
                _dragNode = ElementId.None;

                // Region cube gestures resolve first (they own the press when an edge was grabbed).
                if (wasRegionDrag || wasRegionResize)
                {
                    if (wasDrag)
                    {
                        if (wasRegionResize) { RebuildFromModel(); Flash("region resized"); }
                        else Flash("region moved"); // move: cube + members already translated; no re-fit
                        return;
                    }
                    // Ctrl/Cmd(+Alt)+click on a region edge with no drag → toggle the cube resize handles.
                    CloseMenu();
                    SelectRegion(regId);
                    if (_resizeModeNode == regId && _resizeModeIsRegion) ExitResizeMode();
                    else EnterResizeMode(regId);
                    return;
                }
                if (wasRegionPress && !wasDrag)
                {
                    CloseMenu();
                    // Double-click a region edge opens its colour / opacity editor; a single click selects.
                    float rnow = Time.unscaledTime;
                    if (_lastNodeClick == regId && rnow - _lastNodeClickTime < DoubleClickSecs)
                    {
                        SelectRegion(regId);
                        ShowRegionColorEditor(regId, Input.mousePosition);
                        _lastNodeClick = ElementId.None;
                    }
                    else
                    {
                        if (_resizeModeNode.IsValid && _resizeModeNode != regId) ExitResizeMode();
                        SelectRegion(regId);
                        _lastNodeClick = regId;
                        _lastNodeClickTime = rnow;
                    }
                    return;
                }

                if (wasConnect && wasDrag) { EndConnectRubber(Input.mousePosition); return; }
                if (wasMarquee) { EndMarquee3D(Input.mousePosition); return; }
                if (wasDrag)
                {
                    if (wasNodeDrag) Flash("moved");
                    else if (wasZMove) Flash("moved along Z");
                    else if (wasResize) Flash("resized");
                    else if (wasRotate) Flash("rotated");
                    return;
                }

                // A click (no drag): node → select; else nearest link → select; else clear everything.
                var hit = _scene.Raycast(Input.mousePosition);
                CloseMenu();
                if (hit != null)
                {
                    ClearSelectedEdge();
                    if (shift) { ToggleSelection(hit.Id); _lastNodeClick = ElementId.None; }
                    else if (ctrl)
                    {
                        // Ctrl/Cmd+click on a linked folder node navigates to its package tab (a Ctrl/Cmd+drag still moves
                        // it — this branch is the no-drag case). Otherwise Ctrl/Cmd+click toggles the resize handles.
                        if (_packageLink.ContainsKey(hit.Id))
                        {
                            _lastNodeClick = ElementId.None;
                            GoToPackage(_packageLink[hit.Id]);
                        }
                        else
                        {
                            SetSelected(hit.Id);
                            if (_resizeModeNode == hit.Id && !_resizeModeIsRegion) ExitResizeMode();
                            else EnterResizeMode(hit.Id);
                            _lastNodeClick = ElementId.None;
                        }
                    }
                    else
                    {
                        // Double-click opens the node's edit modal; a single click just selects.
                        float now = Time.unscaledTime;
                        if (_lastNodeClick == hit.Id && now - _lastNodeClickTime < DoubleClickSecs)
                        {
                            SetSelected(hit.Id);
                            OpenNodeEditModal(hit.Id, Input.mousePosition);
                            _lastNodeClick = ElementId.None;
                        }
                        else
                        {
                            SetSelected(hit.Id);
                            if (_resizeModeNode.IsValid && _resizeModeNode != hit.Id) ExitResizeMode();
                            _lastNodeClick = hit.Id;
                            _lastNodeClickTime = now;
                        }
                    }
                }
                else
                {
                    if (_resizeModeNode.IsValid) ExitResizeMode();
                    _lastNodeClick = ElementId.None;
                    var eid = PickEdge3D(Input.mousePosition);
                    if (eid.IsValid) Select3DEdge(eid);
                    else { ClearSelectedEdge(); Select((UmlNodeView)null); }
                }
            }
        }

        // --- per-node rotation (Alt-drag) ---

        /// <summary>Spin the grabbed node (and any co-selected nodes) in place by a mouse delta. Δx → yaw, Δy →
        /// pitch; sign inverted so dragging feels like grabbing the box and turning it.</summary>
        private void RotateNode(Vector2 mouseDelta)
        {
            if (!_dragNode.IsValid) return;
            float dPitch = -mouseDelta.y * RotateDegPerPx;
            float dYaw = mouseDelta.x * RotateDegPerPx;
            if (_scene.TryGetNode(_dragNode, out var node) && node != null)
            { node.AddLocalRotation(dPitch, dYaw); _placements.SetRot(_dragNode, node.LocalRotation); }
            // Rotate the whole multi-selection together when the grabbed node is part of it.
            if (_selection.Count >= 2 && _selection.Contains(_dragNode))
                foreach (var id in _selection)
                    if (id != _dragNode && _scene.TryGetNode(id, out var n) && n != null)
                    { n.AddLocalRotation(dPitch, dYaw); _placements.SetRot(id, n.LocalRotation); }
        }

        // --- per-node world-Z move (Ctrl/Cmd+Shift-drag) ---

        /// <summary>World units the node slides along Z per pixel of vertical mouse travel.</summary>
        private const float ZMovePerPx = 0.01f;

        /// <summary>Slide the grabbed node (and any co-selected nodes) along world Z by the drag's vertical delta —
        /// dragging up pushes the node toward +Z (its front/content face), down toward −Z. Updates the per-node
        /// continuous Z offset and re-poses live.</summary>
        private void DragNodeZ(Vector2 mouseDelta)
        {
            if (!_dragNode.IsValid) return;
            float dz = mouseDelta.y * ZMovePerPx;
            if (Mathf.Abs(dz) < 1e-6f) return;
            ShiftNodeZ(_dragNode, dz);
            // Carry the rest of a multi-selection by the same Z delta.
            if (_selection.Count >= 2 && _selection.Contains(_dragNode))
                foreach (var id in _selection)
                    if (id != _dragNode) ShiftNodeZ(id, dz);
        }

        /// <summary>Add a Z delta to one node's stored offset and re-pose it (keeping its X/Y and rotation).</summary>
        private void ShiftNodeZ(ElementId id, float dz)
        {
            if (!_scene.TryGetNode(id, out var n) || n == null) return;
            _placements.SetPosZ(id, _placements.PosZ(id) + dz);
            Vector3 p = n.transform.position;
            n.SetWorldPose(new Vector3(p.x, p.y, p.z + dz), n.transform.rotation);
        }

        /// <summary>Resize the grabbed node by the drag delta (right widens, down grows height); rebuilds the slab
        /// + face live and stores the size override so it survives rebuilds and persists.</summary>
        private void ResizeNode(Vector2 mouseDelta)
        {
            if (!_dragNode.IsValid || !_scene.TryGetNode(_dragNode, out var node) || node == null) return;
            Vector2 sz = CurrentNodeSizePx(_dragNode);
            float k = 1f / Mathf.Max(ScaleFactor, 0.0001f);
            sz.x = Mathf.Max(60f, sz.x + mouseDelta.x * k);
            sz.y = Mathf.Max(40f, sz.y - mouseDelta.y * k);
            _placements.SetSize(_dragNode, sz);
            node.Resize(sz);
        }

        /// <summary>The node's current pixel size: the stored override if set, else the content-derived default.</summary>
        private Vector2 CurrentNodeSizePx(ElementId id)
        {
            if (_placements.TrySize(id, out var s)) return s;
            if (_model.TryGet(id, out var el))
            {
                MemberSignatures(el, out var attrs, out var ops);
                return NodeSizePx(el, attrs.Count, ops.Count);
            }
            return new Vector2(UmlNodeView.DefaultWidth, 120f);
        }

        // --- connect-by-drag (drag from a node onto another to draw a relationship) ---

        /// <summary>Spawn the temporary rubber-band edge for a connect drag.</summary>
        private void BeginConnectRubber()
        {
            if (_connectRubber == null) _connectRubber = _scene.AddEdge();
            _connectRubber.SetArrow(true);
            UpdateConnectRubber(_pressScreenPos);
        }

        /// <summary>Track the rubber band from the source center to the cursor (on the source's world-Z plane),
        /// tinting whichever node is hovered as a candidate target.</summary>
        private void UpdateConnectRubber(Vector2 screenPos)
        {
            if (_connectRubber == null || !_scene.TryGetNode(_connectSource, out var src) || src == null) return;
            var hit = _scene.Raycast(screenPos);
            ElementId hoverId = (hit != null && hit.Id != _connectSource) ? hit.Id : ElementId.None;
            if (hoverId != _connectHover)
            {
                // Restore the previous hover's depth tint, then highlight the new one.
                ClearConnectHover();
                _connectHover = hoverId;
                if (_connectHover.IsValid && _scene.TryGetNode(_connectHover, out var hn) && hn != null)
                    hn.SetSelected(true);
            }

            Vector3 end = hit != null && hit.Id != _connectSource
                ? hit.transform.position
                : ProjectToPlane(screenPos, _connectPlaneZ);
            _connectRubber.SetRoute(new[] { src.transform.position, end }, ConnectColor);
        }

        /// <summary>Finish a connect drag: over a different node → open the edge-kind picker; else cancel.</summary>
        private void EndConnectRubber(Vector2 screenPos)
        {
            var hit = _scene.Raycast(screenPos);
            ElementId source = _connectSource;
            ClearConnectHover();
            if (_connectRubber != null) { Destroy(_connectRubber.gameObject); _connectRubber = null; }
            _connectSource = ElementId.None;

            if (hit == null || hit.Id == source || !source.IsValid)
            {
                RefreshSelectionHighlights(); // clear any stray hover highlight
                return;
            }
            // Reuse the existing edge-kind picker → Connect path. The 2-D anchor pins it stores are ignored by the
            // 3-D edge router (which connects live world centers), so seed them with harmless defaults.
            _pendingSrcSide = BoxSide.Right;
            _pendingTgtAnchor = new EndAnchor(BoxSide.Left, 0.5f);
            ShowTypePicker(source, hit.Id, screenPos);
        }

        /// <summary>Reset the hovered candidate's highlight back to its selection state.</summary>
        private void ClearConnectHover()
        {
            if (_connectHover.IsValid && _scene.TryGetNode(_connectHover, out var hn) && hn != null)
                hn.SetSelected(_selection.Contains(_connectHover));
            _connectHover = ElementId.None;
        }

        // --- 3-D marquee selection (Shift-drag empty space) ---

        /// <summary>Finish a marquee: select nodes whose projected screen point falls inside the swept box AND
        /// whose depth is within <see cref="_marqueeDepthReach"/> of the nearest match — 0 reach (the default,
        /// "square select") keeps only the frontmost layer under the band; growing the reach (Shift+D / Shift+
        /// scroll / Shift+"+"/"-") extrudes it into a true volumetric select that also picks up nodes behind.</summary>
        private void EndMarquee3D(Vector2 screenPos)
        {
            if (_marquee != null) { Destroy(_marquee); _marquee = null; }
            Rect band = ScreenRect(_marqueeStart, screenPos);
            if (band.width < 3f && band.height < 3f) { Select(null); return; }

            var candidates = new List<(ElementId id, float depth)>();
            foreach (var kv in _scene.Nodes)
            {
                if (kv.Value == null) continue;
                Vector3 sp = _scene.WorldToScreen(kv.Value.transform.position);
                if (sp.z <= 0f) continue; // behind the camera
                if (band.Contains(new Vector2(sp.x, sp.y))) candidates.Add((kv.Key, sp.z));
            }

            var hits = new List<ElementId>();
            if (candidates.Count > 0)
            {
                float nearest = float.MaxValue;
                foreach (var c in candidates) nearest = Mathf.Min(nearest, c.depth);
                float maxDepth = nearest + MarqueeDepthEpsilon + _marqueeDepthReach;
                foreach (var c in candidates) if (c.depth <= maxDepth) hits.Add(c.id);
            }
            SetSelection(hits);
            string depthNote = _marqueeDepthReach > 0f ? $" (depth reach {_marqueeDepthReach:0.0})" : "";
            Flash(hits.Count == 0 ? "marquee — nothing selected" : $"marquee selected {hits.Count}{depthNote}");
        }

        /// <summary>Grow/shrink the volumetric marquee's depth reach by <paramref name="delta"/>, clamped at 0
        /// (the flat "square select" state).</summary>
        private void AdjustMarqueeDepthReach(float delta)
        {
            _marqueeDepthReach = Mathf.Max(0f, _marqueeDepthReach + delta);
            Flash(_marqueeDepthReach <= 0f ? "marquee depth: square (flat)" : $"marquee depth reach: {_marqueeDepthReach:0.0}");
        }

        /// <summary>Collapse the volumetric marquee back down to a flat "square select" (depth reach 0).</summary>
        private void ResetMarqueeDepthReach()
        {
            _marqueeDepthReach = 0f;
            Flash("marquee depth reset (square)");
        }

        private const float OrbitYawPerPx = 0.4f;
        private const float OrbitPitchPerPx = 0.4f;

        // --- empty-space drag navigation mode (chosen from the "Navigate" HUD menu) ---

        /// <summary>What a plain left-drag over empty space does. Orbit is the default; the other modes constrain the
        /// drag to sliding the camera pivot along one world axis (or panning in the view plane) for easier framing.</summary>
        private enum NavMode { Orbit, Pan, MoveX, MoveY, MoveZ }
        private NavMode _navMode = NavMode.Orbit;
        private readonly Dictionary<NavMode, Image> _navButtons = new(); // glyph chips in the floating nav bar
        /// <summary>World units the pivot slides per drag-pixel in an axis nav mode (scaled by camera distance).</summary>
        private const float AxisMovePerPx = 0.004f;

        /// <summary>Run the current empty-space drag according to <see cref="_navMode"/>.</summary>
        private void NavigateEmptyDrag(Vector2 d)
        {
            var rig = _scene != null ? _scene.Rig : null;
            if (_mode2D)
            {
                _scene.PanPivot(d);
                Apply2DModeCamera(false);
                return;
            }
            float k = AxisMovePerPx * (rig != null ? rig.Distance : 1f);
            switch (_navMode)
            {
                case NavMode.Pan: _scene.PanPivot(d); break;
                case NavMode.MoveX: if (rig != null) rig.Pivot += Vector3.right * (d.x * k); break;
                case NavMode.MoveY: if (rig != null) rig.Pivot += Vector3.up * (d.y * k); break;
                case NavMode.MoveZ: if (rig != null) rig.Pivot += Vector3.forward * (d.y * k); break;
                default: _scene.Orbit(d.x * OrbitYawPerPx, -d.y * OrbitPitchPerPx); break;
            }
        }

        private static string NavModeLabel(NavMode m) => m switch
        {
            NavMode.Pan => "Pan", NavMode.MoveX => "Move X", NavMode.MoveY => "Move Y", NavMode.MoveZ => "Move Z",
            _ => "Orbit",
        };

        /// <summary>
        /// A small hovering toolbar (top-right, floating over the diagram) of icon chips — one per drag mode
        /// (orbit / pan / X / Y / Z axis moves), each a procedurally-drawn sprite (<see cref="UmlNavIcons"/>).
        /// Clicking a chip sets <see cref="_navMode"/>; the active chip's background is highlighted.
        /// </summary>
        private void BuildNavBar()
        {
            var bar = new GameObject("NavBar", typeof(RectTransform));
            var brt = (RectTransform)bar.transform;
            brt.SetParent(_root, false);
            brt.anchorMin = brt.anchorMax = new Vector2(1f, 1f);
            brt.pivot = new Vector2(1f, 1f);
            brt.anchoredPosition = new Vector2(-8f, -72f);
            var bg = bar.AddComponent<Image>();
            bg.color = new Color(0.12f, 0.13f, 0.16f, 0.92f);

            var modes = new (NavMode m, Sprite icon)[]
            {
                (NavMode.Orbit, UmlNavIcons.Orbit), (NavMode.Pan, UmlNavIcons.Pan), (NavMode.MoveX, UmlNavIcons.AxisX),
                (NavMode.MoveY, UmlNavIcons.AxisY), (NavMode.MoveZ, UmlNavIcons.AxisZ),
            };
            const float sz = 34f, gap = 2f, pad = 4f;
            float x = pad;
            foreach (var it in modes) { MakeNavChip(brt, it.m, it.icon, x, sz); x += sz + gap; }
            brt.sizeDelta = new Vector2(x - gap + pad, sz + pad * 2f);
            RefreshNavButtons();
        }

        private void MakeNavChip(RectTransform parent, NavMode mode, Sprite icon, float x, float sz)
        {
            var go = new GameObject("Nav:" + NavModeLabel(mode), typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0f, 1f);
            rt.pivot = new Vector2(0f, 1f);
            rt.sizeDelta = new Vector2(sz, sz);
            rt.anchoredPosition = new Vector2(x, -4f);
            var img = go.AddComponent<Image>();          // chip background (tinted for active/inactive)
            var btn = go.AddComponent<Button>();
            btn.targetGraphic = img;
            btn.onClick.AddListener(() => SetNavMode(mode));
            _navButtons[mode] = img;

            // The icon image sits on top of the chip, inset, and is not itself a raycast target.
            var ico = new GameObject("Icon", typeof(RectTransform));
            var irt = (RectTransform)ico.transform;
            irt.SetParent(rt, false);
            irt.anchorMin = irt.anchorMax = new Vector2(0.5f, 0.5f);
            irt.pivot = new Vector2(0.5f, 0.5f);
            const float inset = 6f;
            irt.sizeDelta = new Vector2(sz - inset * 2f, sz - inset * 2f);
            irt.anchoredPosition = Vector2.zero;
            var im = ico.AddComponent<Image>();
            im.sprite = icon;
            im.color = new Color(0.95f, 0.97f, 1f, 1f);
            im.raycastTarget = false;
        }

        private void SetNavMode(NavMode m)
        {
            _navMode = m;
            RefreshNavButtons();
            Flash($"drag empty space → {NavModeLabel(m)}");
        }

        private static readonly NavMode[] NavCycle =
            { NavMode.Orbit, NavMode.Pan, NavMode.MoveX, NavMode.MoveY, NavMode.MoveZ };

        /// <summary>Cycle the empty-space drag mode (orbit → pan → X → Y → Z); <paramref name="back"/> reverses.</summary>
        private void CycleNavMode(bool back)
        {
            int i = System.Array.IndexOf(NavCycle, _navMode);
            if (i < 0) i = 0;
            int n = NavCycle.Length;
            SetNavMode(NavCycle[((i + (back ? -1 : 1)) % n + n) % n]);
        }

        /// <summary>Tint the active nav chip (blue) and the rest neutral.</summary>
        private void RefreshNavButtons()
        {
            foreach (var kv in _navButtons)
                if (kv.Value != null)
                    kv.Value.color = kv.Key == _navMode
                        ? new Color(0.20f, 0.55f, 0.85f, 1f)
                        : new Color(0.20f, 0.23f, 0.28f, 1f);
        }

        /// <summary>The per-frame screen-space mouse delta (Input has no UI delta outside the EventSystem). Computed
        /// once at the top of every Update; orbit / pan drags read it via GetMouseDelta.</summary>
        private Vector2 _lastMousePos;
        private Vector2 _mouseDelta;
        private Vector2 GetMouseDelta() => _mouseDelta;

        /// <summary>Intersect the camera ray through <paramref name="screenPos"/> with the world plane z = planeZ.</summary>
        private Vector3 ProjectToPlane(Vector2 screenPos, float planeZ)
        {
            Ray ray = _scene.ScreenPointToRay(screenPos);
            // Plane with normal +Z at the given z. Guard a near-parallel ray.
            float denom = ray.direction.z;
            if (Mathf.Abs(denom) < 1e-5f) return ray.origin;
            float t = (planeZ - ray.origin.z) / denom;
            return ray.origin + ray.direction * t;
        }

        /// <summary>Drag the picked node (and any co-selected nodes) across its world-Z plane, updating _pos (px).</summary>
        private void DragNode(Vector2 screenPos)
        {
            if (!_dragNode.IsValid || !_scene.TryGetNode(_dragNode, out var node) || node == null) return;
            Vector3 world = ProjectToPlane(screenPos, _dragPlaneZ);
            Vector3 worldDelta = world - _dragLastWorld;
            _dragLastWorld = world;
            if (worldDelta.sqrMagnitude < 1e-10f) return;

            MoveNode3D(_dragNode, worldDelta);
            // Carry the rest of a multi-selection by the same world delta.
            if (_selection.Count >= 2 && _selection.Contains(_dragNode))
                foreach (var id in _selection)
                    if (id != _dragNode) MoveNode3D(id, worldDelta);
        }

        /// <summary>Shift one node by a world-space delta and write the new position back to _pos (in px).</summary>
        private void MoveNode3D(ElementId id, Vector3 worldDelta)
        {
            if (!_scene.TryGetNode(id, out var n) || n == null) return;
            Vector3 p = n.transform.position + worldDelta;
            n.SetWorldPose(p, n.transform.rotation);
            _placements.SetPos(id, new Vector2(p.x / Uml3DConfig.WorldScale, p.y / Uml3DConfig.WorldScale));
        }

        /// <summary>True if the pointer is over a real overlay UI element (so the diagram should ignore the gesture).</summary>
        private static bool PointerOverUI() =>
            EventSystem.current != null && EventSystem.current.IsPointerOverGameObject();

        // --- pan (drag empty canvas to scroll the diagram) ---

        private Vector2 _pan;

        // Marquee (rubber-band) selection: a translucent screen-space rectangle drawn while dragging empty canvas.
        private GameObject _marquee;
        private Vector2 _marqueeStart; // screen-space anchor (the drag origin)

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

        // --- marquee (rubber-band) selection ---

        /// <summary>Begin a marquee at the drag origin: spawn a translucent rect on the root (screen space).</summary>
        public void BeginMarquee(Vector2 screenPos)
        {
            CloseMenu();
            ClearSelectedEdge();
            _marqueeStart = screenPos;
            if (_marquee != null) Destroy(_marquee);
            _marquee = new GameObject("Marquee", typeof(RectTransform));
            var rt = (RectTransform)_marquee.transform;
            rt.SetParent(_root, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0f, 0f);
            rt.pivot = new Vector2(0f, 0f);
            var img = _marquee.AddComponent<Image>();
            img.color = new Color(0.12f, 0.55f, 0.85f, 0.18f);
            img.raycastTarget = false;
            var outline = _marquee.AddComponent<Outline>();
            outline.effectColor = new Color(0.12f, 0.55f, 0.85f, 0.8f);
            outline.effectDistance = new Vector2(1f, 1f);
            UpdateMarquee(screenPos);
        }

        /// <summary>Resize the marquee rect to span from its anchor to the current pointer.</summary>
        public void UpdateMarquee(Vector2 screenPos)
        {
            if (_marquee == null) return;
            float scale = Mathf.Max(ScaleFactor, 0.0001f);
            Vector2 a = _marqueeStart / scale, b = screenPos / scale;
            Vector2 min = Vector2.Min(a, b), max = Vector2.Max(a, b);
            var rt = (RectTransform)_marquee.transform;
            rt.anchoredPosition = min;
            rt.sizeDelta = max - min;
        }

        /// <summary>Finish the marquee: select every node whose screen rect intersects the swept box.</summary>
        public void EndMarquee(Vector2 screenPos)
        {
            if (_marquee == null) return;
            Destroy(_marquee); _marquee = null;

            Rect band = ScreenRect(_marqueeStart, screenPos);
            // A trivially-small marquee (a click that registered as a tiny drag) just clears the selection.
            if (band.width < 3f && band.height < 3f) { Select(null); return; }

            var hits = new List<ElementId>();
            foreach (var kv in _nodes)
            {
                if (kv.Value == null) continue;
                if (band.Overlaps(NodeScreenRect(kv.Value.Rt), true)) hits.Add(kv.Key);
            }
            SetSelection(hits);
            Flash(hits.Count == 0 ? "marquee — nothing selected" : $"marquee selected {hits.Count}");
        }

        /// <summary>Axis-aligned screen-space rect between two pointer positions (origin bottom-left).</summary>
        private static Rect ScreenRect(Vector2 a, Vector2 b)
        {
            Vector2 min = Vector2.Min(a, b), max = Vector2.Max(a, b);
            return new Rect(min.x, min.y, max.x - min.x, max.y - min.y);
        }

        /// <summary>A node's bounding box in screen space (overlay canvas → camera null), origin bottom-left.</summary>
        private static Rect NodeScreenRect(RectTransform rt)
        {
            var corners = new Vector3[4];
            rt.GetWorldCorners(corners);
            float minX = float.MaxValue, minY = float.MaxValue, maxX = float.MinValue, maxY = float.MinValue;
            for (int i = 0; i < 4; i++)
            {
                Vector2 sp = RectTransformUtility.WorldToScreenPoint(null, corners[i]);
                minX = Mathf.Min(minX, sp.x); minY = Mathf.Min(minY, sp.y);
                maxX = Mathf.Max(maxX, sp.x); maxY = Mathf.Max(maxY, sp.y);
            }
            return new Rect(minX, minY, maxX - minX, maxY - minY);
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

        // --- camera Z navigation (Alt+scroll jumps the view a fixed amount along world Z) ---

        /// <summary>World-Z distance one Alt+scroll "jump" moves the camera. 250 model-px × WorldScale ≈ 2.5 units —
        /// roughly the depth between two stacked z-layers, so a jump steps cleanly between depth planes.</summary>
        private const float ZJumpStep = 250f * Uml3DConfig.WorldScale;

        /// <summary>Slide the camera pivot (and the camera with it) a fixed step along world +Z (dir &gt; 0) or −Z.</summary>
        private void JumpCameraZ(int dir)
        {
            var rig = _scene != null ? _scene.Rig : null;
            if (rig == null) return;
            rig.Pivot += new Vector3(0f, 0f, Mathf.Sign(dir) * ZJumpStep);
            Flash($"jumped {(dir > 0 ? "+" : "−")}{ZJumpStep:0.##}u along Z");
        }

        // --- z-layers (stacked planes; node menu to move elements between depth planes) ---

        /// <summary>Step the active z-layer by ±1 and rebuild so only that layer's nodes show. Clamps to the used
        /// range, but allows stepping one past each extreme so a node can be moved onto a fresh empty layer.</summary>
        private void ShiftActiveLayer(int delta)
        {
            LayerUsedRange(out int min, out int max);
            int next = delta > 0
                ? Mathf.Min(_activeLayer + delta, Mathf.Max(max, _activeLayer) + 1)
                : Mathf.Max(_activeLayer + delta, Mathf.Min(min, _activeLayer) - 1);
            if (next == _activeLayer) return;
            _activeLayer = next;
            RebuildFromModel();
            Flash($"layer {_activeLayer}");
        }

        /// <summary>Jump directly to a layer (used by the cross-layer chevron markers).</summary>
        public void GoToLayer(int layer)
        {
            if (layer == _activeLayer) return;
            _activeLayer = layer;
            RebuildFromModel();
            Flash($"layer {_activeLayer}");
        }

        /// <summary>The min/max ZLayer in use across the active package's diagram nodes (defaults to 0..0).</summary>
        private void LayerUsedRange(out int min, out int max)
        {
            min = 0; max = 0; bool any = false;
            foreach (var el in _model.Elements)
            {
                if (el.Parent != _activePackage || !KindInfo.IsDiagramNode(el.Kind)) continue;
                if (!any) { min = max = el.ZLayer; any = true; }
                else { if (el.ZLayer < min) min = el.ZLayer; if (el.ZLayer > max) max = el.ZLayer; }
            }
        }

        // A cross-layer stub binding: the visible endpoint's element, the side it exits, and the chevron marker,
        // so LateUpdate can re-seat the stub + glyph as that node is dragged.
        private struct LayerStubBinding { public UmlEdgeView Stub; public UmlLayerMarker Marker; public ElementId Visible; public Vector2 HiddenPos; }
        private readonly List<LayerStubBinding> _layerStubBindings = new();

        /// <summary>Destroy all cross-layer stub + chevron views and forget their bindings (called on each rebuild).</summary>
        private void LayerClearCrossLayerViews()
        {
            foreach (var s in _layerStubs) if (s != null) Destroy(s.gameObject);
            foreach (var m in _layerMarkers) if (m != null) Destroy(m.gameObject);
            _layerStubs.Clear();
            _layerMarkers.Clear();
            _layerStubBindings.Clear();
        }

        /// <summary>
        /// Build the cross-layer affordance for an edge with one endpoint visible on the active layer and the other
        /// culled on a different layer: a short stub from the visible node's border toward the hidden endpoint's
        /// stored position, capped with an up chevron (hidden layer is above) or down chevron (below). Clicking the
        /// chevron follows the relationship to that layer.
        /// </summary>
        private void LayerBuildCrossLayerStub(ModelEdge edge, bool fromVisible)
        {
            ElementId visibleId = fromVisible ? edge.From : edge.To;
            ElementId hiddenId = fromVisible ? edge.To : edge.From;
            if (!_nodes.TryGetValue(visibleId, out var nv) || nv == null) return;
            // The hidden endpoint must be a diagram node on a real layer with a known position to aim the stub.
            if (!_model.TryGet(hiddenId, out var hidden) || !KindInfo.IsDiagramNode(hidden.Kind)) return;
            if (!_placements.TryPos(hiddenId, out var hiddenPos)) return;

            bool up = hidden.ZLayer > _activeLayer;
            var color = up ? new Color(0.20f, 0.55f, 0.30f, 1f) : new Color(0.62f, 0.34f, 0.74f, 1f);

            var go = new GameObject("LayerStub:" + edge.Kind, typeof(RectTransform));
            go.transform.SetParent(_edgeLayer, false);
            var stub = go.AddComponent<UmlEdgeView>();
            stub.Edge = edge.Id;
            stub.Interactive = false; // off-layer: not selectable / re-typeable here
            var (dashed, _, _, _) = EdgeVisual(edge.Kind);
            stub.Init(this, _font, color, null, null, null, dashed, EndMarker.None, EndMarker.None);
            _layerStubs.Add(stub);

            var mgo = new GameObject("LayerMarker", typeof(RectTransform));
            mgo.transform.SetParent(_edgeLayer, false);
            var marker = mgo.AddComponent<UmlLayerMarker>();
            _layerMarkers.Add(marker);

            var bind = new LayerStubBinding { Stub = stub, Marker = marker, Visible = visibleId, HiddenPos = hiddenPos };
            _layerStubBindings.Add(bind);
            LayerSeatStub(bind, up, hidden.ZLayer, color, true);
        }

        /// <summary>Re-seat every cross-layer stub + chevron as its visible node moves (called each LateUpdate).</summary>
        private void LayerRerouteStubs()
        {
            foreach (var bind in _layerStubBindings)
            {
                if (bind.Stub == null || bind.Marker == null) continue;
                if (!_nodes.ContainsKey(bind.Visible)) continue;
                LayerSeatStub(bind, false, 0, default, false);
            }
        }

        /// <summary>
        /// Position one stub: clip to the visible node's border facing the hidden position, run a short fixed-length
        /// segment outward, and (on first build) place the chevron at the far end. <paramref name="initMarker"/>
        /// builds the chevron; subsequent calls only move it.
        /// </summary>
        private void LayerSeatStub(LayerStubBinding bind, bool up, int hiddenLayer, Color color, bool initMarker)
        {
            if (!_nodes.TryGetValue(bind.Visible, out var nv) || nv == null) return;
            Vector2 center = nv.Rt.anchoredPosition, size = nv.Rt.sizeDelta;
            Vector2 border = ClipToBox(center, size, bind.HiddenPos);
            Vector2 dir = (bind.HiddenPos - center);
            dir = dir.sqrMagnitude > 0.001f ? dir.normalized : Vector2.up;
            Vector2 far = border + dir * StubLen;
            bind.Stub.SetRoute(new List<Vector2> { border, far });

            if (initMarker)
                bind.Marker.Init(this, far + dir * 4f, up, color, hiddenLayer);
            else
                ((RectTransform)bind.Marker.transform).anchoredPosition = far + dir * 4f;
        }

        private void LateUpdate()
        {
            // Re-route every 3-D edge from its endpoints' live world positions so links track as nodes move /
            // the camera orbits.
            for (int i = 0; i < _scene3dEdges.Count; i++) RouteEdge3D(_scene3dEdges[i]);
            for (int i = 0; i < _scene3dStubBindings.Count; i++) RouteCrossLayerStub3D(_scene3dStubBindings[i]);
            // Build / track the selected link's route-edit handles AFTER routing so they sit on the freshly-routed
            // polyline (and rebuild when the selection changes / clears).
            SyncEdgeHandles3D();
            // Track the resize handles on a double-clicked node and update the cursor as the pointer hovers them.
            RepositionResizeHandles();
            UpdateResizeCursor();
        }

        // --- selection / movement / resize ---

        public void Select(UmlNodeView node) { CloseMenu(); ClearSelectedEdge(); SetSelected(node != null ? node.Id : ElementId.None); }
        public void OnNodeMoved(ElementId id, Vector2 pos) => _placements.SetPos(id, pos);
        public void OnNodeResized(ElementId id, Vector2 size) => _placements.SetSize(id, size);

        /// <summary>The nodes whose center currently lies within <paramref name="boundary"/>'s rect (its nested children).</summary>
        public List<ElementId> NodesInside(UmlNodeView boundary)
        {
            var result = new List<ElementId>();
            if (boundary == null) return result;
            Vector2 c = boundary.Rt.anchoredPosition;
            float hw = boundary.Rt.sizeDelta.x * 0.5f, hh = boundary.Rt.sizeDelta.y * 0.5f;
            foreach (var kv in _nodes)
            {
                if (kv.Key == boundary.Id || kv.Value == null) continue;
                Vector2 p = kv.Value.Rt.anchoredPosition;
                if (p.x >= c.x - hw && p.x <= c.x + hw && p.y >= c.y - hh && p.y <= c.y + hh)
                    result.Add(kv.Key);
            }
            return result;
        }

        /// <summary>Shift a captured set of nodes by a delta (used to carry a boundary's nested nodes with it).</summary>
        public void MoveNodesBy(List<ElementId> ids, Vector2 delta)
        {
            if (ids == null) return;
            foreach (var id in ids)
                if (_nodes.TryGetValue(id, out var nv) && nv != null)
                {
                    nv.Rt.anchoredPosition += delta;
                    _placements.SetPos(id, nv.Rt.anchoredPosition);
                }
        }

        /// <summary>
        /// Drag a multi-selected node: shift every OTHER selected node by the same layer delta so the whole
        /// selection travels together (the <paramref name="mover"/> itself is moved by its own drag handler).
        /// </summary>
        public void MoveSelectionBy(Vector2 layerDelta, ElementId mover)
        {
            if (_selection.Count < 2) return;
            foreach (var id in _selection)
            {
                if (id == mover) continue;
                if (_nodes.TryGetValue(id, out var nv) && nv != null)
                {
                    nv.Rt.anchoredPosition += layerDelta;
                    _placements.SetPos(id, nv.Rt.anchoredPosition);
                }
            }
        }

        // --- context menus ---

        public void ShowNodeMenu(ElementId id, Vector2 screenPos)
        {
            CloseMenu();
            // Right-clicking a node already in the multi-selection keeps the set (so "Copy selection as PNG" stays
            // available); right-clicking elsewhere selects just that node.
            if (_selection.Contains(id)) { _selectedId = id; RefreshSelectionHighlights(); }
            else SetSelected(id);
            if (!_model.TryGet(id, out var el)) return;

            if (el.Kind == ElementKind.Note)
            {
                var noteId = id; var noteParent = el.Parent;
                var noteItems = new List<MenuItem>
                {
                    new MenuItem("Edit text…", true, () => ShowNoteEditor(noteParent, noteId, screenPos)),
                    new MenuItem("Style…  (color · font)", true, () => ShowStyleEditor(noteId, screenPos)),
                    new MenuItem("Copy", true, () => CopyElement(noteId)),
                    MenuItem.Separator(),
                    new MenuItem("Delete", true,
                        () => { _ctl.Delete(noteId); SetSelected(ElementId.None); RebuildFromModel(); }),
                };
                CreateMenu(screenPos, "Note", noteItems);
                return;
            }

            // Streamlined top level: the common single actions; bulky groups (members, code) open submenus.
            var items = new List<MenuItem>();
            var pid = id;

            items.Add(new MenuItem("Edit element…  (fields · operations · properties)", true,
                () => ShowClassifierEditor(pid, screenPos)));

            bool canMembers = ContainmentRules.CanContain(el.Kind, ElementKind.Field).IsValid
                || ContainmentRules.CanContain(el.Kind, ElementKind.Function).IsValid;
            bool hasMembers = false;
            foreach (var c0 in el.ChildIds)
                if (_model.TryGet(c0, out var cm) && KindInfo.IsMember(cm.Kind)) { hasMembers = true; break; }
            if (canMembers || hasMembers)
                items.Add(new MenuItem("Members ▸   (attributes · operations)", true, () => ShowMembersMenu(pid, screenPos)));

            items.Add(new MenuItem("Style…  (color · font)", true, () => ShowStyleEditor(pid, screenPos)));
            items.Add(new MenuItem("💬  Comment / inline doc…", true, () => ShowCommentEditor(pid, screenPos)));
            items.Add(new MenuItem("🖼 Paste image into node", true, () => { CloseMenu(); AttachImageToNode(pid); }));
            if (_nodeImage.ContainsKey(pid))
            {
                items.Add(new MenuItem("🖼→◇ Import diagram from this image…", true,
                    () => ShowImageImportDialogForNode(pid, screenPos)));
                items.Add(new MenuItem("🗙 Remove image", true, () => { CloseMenu(); ClearNodeImage(pid); }));
            }

            if (KindInfo.IsDiagramNode(el.Kind) && el.Kind != ElementKind.Note)
            {
                items.Add(new MenuItem("⌁ Code ▸   (generate · view · VS Code · refactor)", true, () => ShowCodeMenu(pid, screenPos)));
                items.Add(new MenuItem("🔬 Trace / debug…   (bubble IDE · breakpoints)", true, () => ShowTraceView(pid)));
            }

            // Z-layer: shift this element forward (+Z, toward the camera) or back (−Z) by one depth plane.
            items.Add(MenuItem.Separator());
            var zEl = el;
            items.Add(new MenuItem("Move forward (+Z) ▲", true, () =>
            {
                _ctl.SetZLayer(pid, zEl.ZLayer + 1);
                CloseMenu(); RebuildFromModel();
                Flash($"moved to depth layer {zEl.ZLayer + 1}");
            }));
            items.Add(new MenuItem("Move back (−Z) ▼", true, () =>
            {
                _ctl.SetZLayer(pid, zEl.ZLayer - 1);
                CloseMenu(); RebuildFromModel();
                Flash($"moved to depth layer {zEl.ZLayer - 1}");
            }));

            items.Add(MenuItem.Separator());
            items.Add(new MenuItem("Copy  (Ctrl/Cmd+C)", true, () => CopyElement(pid)));
            if (_selection.Count >= 2 && AllSelectedAreCopyableNodes())
                items.Add(new MenuItem($"Copy selection as PNG  ({_selection.Count})", true, () => CopySelectionAsPng()));
            items.Add(new MenuItem("Delete", true,
                () => { _ctl.Delete(pid); SetSelected(ElementId.None); RebuildFromModel(); }));

            CreateMenu(screenPos, $"{el.Name} ({el.Kind})", items);
        }

        /// <summary>Open a node's edit modal (the note text editor for a Note, else the classifier editor).</summary>
        private void OpenNodeEditModal(ElementId id, Vector2 screenPos)
        {
            if (!_model.TryGet(id, out var el)) return;
            if (el.Kind == ElementKind.Note) ShowNoteEditor(el.Parent, id, screenPos);
            else ShowClassifierEditor(id, screenPos);
        }

        /// <summary>Submenu: add / edit a node's attributes and operations (keeps the main node menu short).</summary>
        private void ShowMembersMenu(ElementId id, Vector2 screenPos)
        {
            CloseMenu();
            if (!_model.TryGet(id, out var el)) return;
            var items = new List<MenuItem>();
            foreach (var k in new[] { ElementKind.Field, ElementKind.Function })
                if (ContainmentRules.CanContain(el.Kind, k).IsValid)
                {
                    var kind = k; var parent = id;
                    string verb = k == ElementKind.Field ? "＋ Attribute (field)…" : "＋ Operation (method)…";
                    items.Add(new MenuItem(verb, true, () => ShowMemberEditor(parent, kind, ElementId.None, screenPos)));
                }
            bool any = false;
            foreach (var childId in el.ChildIds)
            {
                if (!_model.TryGet(childId, out var c) || !KindInfo.IsMember(c.Kind)) continue;
                if (!any) { items.Add(MenuItem.Separator()); any = true; }
                var cid = childId; var ckind = c.Kind; var parent = id;
                items.Add(new MenuItem("✎  " + Ellipsize(c.Name, 30), true,
                    () => ShowMemberEditor(parent, ckind, cid, screenPos)));
                items.Add(new MenuItem("💬  comment…   " + Ellipsize(c.Name, 22), true,
                    () => ShowCommentEditor(cid, screenPos)));
            }
            if (items.Count == 0) items.Add(new MenuItem("(no members here)", false, null));
            CreateMenu(screenPos, "Members — " + Ellipsize(el.Name, 24), items);
        }

        /// <summary>Submenu: code generation / viewing / VS Code round-trip / refactor for a diagram node.</summary>
        private void ShowCodeMenu(ElementId id, Vector2 screenPos)
        {
            CloseMenu();
            if (!_model.TryGet(id, out var el)) return;
            var pid = id;
            bool hasCode = !string.IsNullOrEmpty(el.Code)
                || (!string.IsNullOrEmpty(el.SourceFile) && _sourceFiles.ContainsKey(el.SourceFile));
            var items = new List<MenuItem>
            {
                new MenuItem(hasCode ? "⌁ View code…" : "⌁ Generate code (LLM)…", true, () => GenerateCodeForElement(pid)),
            };
            if (_selection.Count >= 2)
                items.Add(new MenuItem("⌁ Generate code for selection…", true, () => GenerateCodeForSelection()));
            items.Add(new MenuItem("🖉 Edit code in VS Code", true, () => { CloseMenu(); EditCodeInVsCode(pid); }));
            if (System.IO.File.Exists(ShadowPathFor(pid)))
                items.Add(new MenuItem("⟳ Re-sync from code", true,
                    () => { CloseMenu(); ResyncNodeFromShadow(pid, ShadowPathFor(pid)); }));
            items.Add(new MenuItem("⚒ Refactor…  (rename · move · LLM)", true, () => ShowRefactorMenu(pid, screenPos)));
            CreateMenu(screenPos, "Code — " + Ellipsize(el.Name, 24), items);
        }

        public void ShowEmptyMenu(Vector2 screenPos)
        {
            CloseMenu();
            SetSelected(ElementId.None);

            var items = new List<MenuItem>
            {
                new MenuItem("Add ▸", true, () => ShowCanvasAddMenu(screenPos)),
                MenuItem.Separator(),
                new MenuItem("Layout ▸", _activePackage.IsValid, () => ShowCanvasLayoutMenu(screenPos)),
                MenuItem.Separator(),
                new MenuItem("Diagram ▸", true, () => ShowCanvasDiagramMenu(screenPos)),
                MenuItem.Separator(),
                new MenuItem("Generate ▸", true, () => ShowCanvasGenerateMenu(screenPos)),
                MenuItem.Separator(),
                new MenuItem("Export ▸   (code · PNG · 3D model)", true, () => ShowExportMenu(screenPos)),
                new MenuItem("Settings ▸   (LLM · vision · database)", true, () => ShowSettingsMenu(screenPos)),
            };

            CreateMenu(screenPos, _activePackage.IsValid ? PackageName(_activePackage) : "Canvas (no package yet)", items);
        }

        private void ShowCanvasAddMenu(Vector2 screenPos)
        {
            CloseMenu();
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

            if (_clipboard != null && _activePackage.IsValid)
                items.Add(new MenuItem("Paste  (Ctrl/Cmd+V)", true, () => PasteElement()));

            CreateMenu(screenPos, "Add", items);
        }

        private void ShowCanvasLayoutMenu(Vector2 screenPos)
        {
            CloseMenu();
            var items = new List<MenuItem>();
            items.Add(new MenuItem("Sequence: auto-arrange", true, () => AutoArrangeSequence()));
            items.Add(MenuItem.Separator());
            items.Add(new MenuItem("Auto-layout: Tidy grid", true, () => AutoLayout("grid")));
            items.Add(new MenuItem("Auto-layout: Force-directed", true, () => AutoLayout("force")));
            items.Add(new MenuItem("Auto-layout: By source / package", true, () => AutoLayout("source")));
            items.Add(new MenuItem("Auto-layout: Hierarchy", true, () => AutoLayout("hierarchy")));
            items.Add(new MenuItem("Auto-layout: AI-assisted…", true, () => AutoLayoutAI()));

            CreateMenu(screenPos, "Layout", items);
        }

        private void ShowCanvasDiagramMenu(Vector2 screenPos)
        {
            CloseMenu();
            var items = new List<MenuItem>();
            items.Add(new MenuItem("New (empty diagram)", true, () => NewDiagram()));
            items.Add(new MenuItem("Reset to sample", true, () => ResetToSample()));
            items.Add(MenuItem.Separator());
            items.Add(new MenuItem("Save  (Ctrl/Cmd+S)", true, () => { CloseMenu(); SaveDiagram(); }));
            items.Add(new MenuItem("Save As…  (Ctrl/Cmd+Shift+S)", true, () => SaveDiagramAs()));
            items.Add(new MenuItem("Open file…  (Ctrl/Cmd+O)", true, () => OpenDiagramFile()));
            items.Add(new MenuItem("Open Recent ▸", RecentFiles.HasRecent(), () => ShowRecentFilesMenu(screenPos)));
            items.Add(MenuItem.Separator());
            items.Add(new MenuItem("Delete diagram", _activePackage.IsValid, () => DeleteCurrentDiagram()));
            items.Add(new MenuItem("Delete project", true, () => DeleteProject()));
            items.Add(new MenuItem("Delete saved file", true, () => { CloseMenu(); DeleteSavedDiagram(); }));

            CreateMenu(screenPos, "Diagram", items);
        }

        /// <summary>A submenu of recently opened model files (MRU). Selecting one opens it directly.</summary>
        private void ShowRecentFilesMenu(Vector2 screenPos)
        {
            CloseMenu();
            var items = new List<MenuItem>();
            foreach (var p in RecentFiles.GetRecent())
            {
                var path = p;
                string label = System.IO.Path.GetFileName(path);
                string dir = ShortenDir(System.IO.Path.GetDirectoryName(path) ?? "");
                if (!string.IsNullOrEmpty(dir)) label += "   — " + dir;
                items.Add(new MenuItem(label, System.IO.File.Exists(path), () => { CloseMenu(); if (TryOpenPath(path)) { _currentDiagramPath = path; RecentFiles.AddRecent(path); if (_scene != null) _scene.FrameAll(); Flash("opened " + System.IO.Path.GetFileName(path)); } }));
            }
            items.Add(MenuItem.Separator());
            items.Add(new MenuItem("Clear Recent", true, () => { RecentFiles.Clear(); CloseMenu(); Flash("cleared recent"); }));
            CreateMenu(screenPos + new Vector2(220f, 0f), "Open Recent", items);
        }

        /// <summary>Compact a long directory path for a menu line: first segment, …, last two segments.</summary>
        private static string ShortenDir(string dir)
        {
            if (string.IsNullOrEmpty(dir)) return "";
            var segs = dir.Split(System.IO.Path.DirectorySeparatorChar, System.IO.Path.AltDirectorySeparatorChar);
            if (segs.Length <= 3) return dir;
            return segs[0] + System.IO.Path.DirectorySeparatorChar + "…" + System.IO.Path.DirectorySeparatorChar + string.Join(System.IO.Path.DirectorySeparatorChar.ToString(), segs[^2..]);
        }

        private void ShowCanvasGenerateMenu(Vector2 screenPos)
        {
            CloseMenu();
            var items = new List<MenuItem>();
            items.Add(new MenuItem("⌁ Import code → elements…", true, () => ShowImportCodeDialog(screenPos)));
            items.Add(new MenuItem("🖼 Import diagram from image…  (vision LLM)", true, () => ShowImageImportDialog(screenPos)));
            items.Add(new MenuItem("⌁ Generate code…  (wizard)", true, () => ShowCodeGenWizard(screenPos)));
            items.Add(MenuItem.Separator());
            items.Add(new MenuItem("⛁ Load DB schema → ERD…", true, () => ShowDbConnectDialog(screenPos)));
            items.Add(new MenuItem("⛁ Generate Liquibase changelog…", true, () => GenerateLiquibaseChangelog()));
            items.Add(MenuItem.Separator());
            items.Add(new MenuItem("⇄ Import PlantUML…", true, () => ImportPlantUml()));
            items.Add(new MenuItem("⇄ Import XMI…", true, () => ImportXmi()));
            items.Add(new MenuItem("⇄ Import Mermaid…", true, () => ImportMermaid()));
            items.Add(new MenuItem("⇄ Import EA project (.qea)…", true, () => ImportQea()));
            items.Add(MenuItem.Separator());
            items.Add(new MenuItem("⇄ Export PlantUML…", true, () => ExportPlantUml()));
            items.Add(new MenuItem("⇄ Export XMI…", true, () => ExportXmi()));
            items.Add(new MenuItem("⇄ Export Mermaid…", true, () => ExportMermaid()));
            items.Add(new MenuItem("⇄ Export EA project (.qea)…", true, () => ExportQea()));
            if (_selection.Count > 0)
            {
                items.Add(MenuItem.Separator());
                items.Add(new MenuItem("⇄ Export selection → PlantUML…", true, () => ExportSelectionPlantUml()));
                items.Add(new MenuItem("⇄ Export selection → XMI…", true, () => ExportSelectionXmi()));
                items.Add(new MenuItem("⇄ Export selection → Mermaid…", true, () => ExportSelectionMermaid()));
                items.Add(new MenuItem("⇄ Export selection → PNG…", true, () => ExportSelectionPng()));
            }

            CreateMenu(screenPos, "Generate", items);
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
            // A new Package also drops a linked folder node onto the current diagram (and navigates appropriately).
            if (kind == ElementKind.Package) { AddPackageWithNode(screenPos); return; }
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
                if (kind == ElementKind.Package) SetActivePackage(id);
                else { _placements.SetPos(id, ScreenToModelPx(screenPos)); _ctl.SetZLayer(id, _activeLayer); } // insert on the active layer
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
            foreach (var k in OrderedEdgeKindsFor(from, to))
            {
                var kind = k;
                items.Add(new MenuItem(EdgeDisplay(k), true, () => Connect(from, to, kind)));
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

        /// <summary>After flipping an edge's direction, swap its stored face anchors and reverse its waypoints so the
        /// 3-D routing still matches the new source→target order.</summary>
        private void ReverseEdgeViewState(EdgeId edge)
        {
            bool hasSrc = _srcFace.TryGetValue(edge, out var sf);
            bool hasTgt = _tgtFace.TryGetValue(edge, out var tf);
            if (hasTgt) _srcFace[edge] = tf; else _srcFace.Remove(edge);
            if (hasSrc) _tgtFace[edge] = sf; else _tgtFace.Remove(edge);
            if (_waypoints3d.TryGetValue(edge, out var w3)) w3.Reverse();
            if (_waypoints.TryGetValue(edge, out var w2)) w2.Reverse();
        }

        public void ShowEdgeMenu(EdgeId edgeId, Vector2 screenPos)
        {
            if (!_model.TryGet(edgeId, out var e)) return;
            CloseMenu();
            var items = new List<MenuItem>();
            foreach (var k in OrderedEdgeKindsFor(e.From, e.To))
            {
                var kind = k; var eid = edgeId;
                items.Add(new MenuItem(EdgeDisplay(k) + (k == e.Kind ? "  ✓" : ""), true,
                    () => { _ctl.ReTypeEdge(eid, kind); CloseMenu(); RebuildFromModel(); }));
            }
            items.Add(MenuItem.Separator());
            var metaEdge = edgeId;
            items.Add(new MenuItem("Multiplicity / label / constraint…", true, () => ShowEdgeMetaEditor(metaEdge, screenPos)));
            items.Add(new MenuItem("Flip direction  (↺ swap arrow)", true, () =>
            {
                _ctl.ReverseEdge(metaEdge);
                ReverseEdgeViewState(metaEdge);
                CloseMenu();
                RebuildFromModel();
            }));
            bool isCurved = _curved.Contains(metaEdge);
            items.Add(new MenuItem(isCurved ? "Make orthogonal (straight)" : "Make curved (bezier)", true,
                () =>
                {
                    if (isCurved) _curved.Remove(metaEdge); else _curved.Add(metaEdge);
                    CloseMenu();
                    RebuildFromModel();
                }));
            var delEdge = edgeId;
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
            if (_selectedRegion.IsValid)
            {
                _ctl.Delete(_selectedRegion);
                _selectedRegion = ElementId.None;
                FixActiveAfterChange();
                RebuildFromModel();
                return;
            }
            if (_selectedEdge.IsValid)
            {
                _ctl.DeleteEdge(_selectedEdge);
                DropEdgeViewState(_selectedEdge);
                _selectedEdge = EdgeId.None;
                RebuildFromModel();
                return;
            }
            if (_selection.Count == 0) return;
            // Delete every selected node (iterate a copy — the delete path mutates the model, not _selection).
            var doomed = new List<ElementId>(_selection);
            foreach (var id in doomed) { _ctl.Delete(id); _breakpoints.RemoveAllFor(id); }
            SetSelected(ElementId.None);
            FixActiveAfterChange();
            RebuildFromModel();
        }

        private void CollectElementSubtree(ElementId root, HashSet<ElementId> into)
        {
            if (!root.IsValid || !_model.TryGet(root, out var el) || !into.Add(root)) return;
            foreach (var child in el.ChildIds)
                CollectElementSubtree(child, into);
        }

        private void PruneDeletedViewState(HashSet<ElementId> removedElements, HashSet<EdgeId> removedEdges)
        {
            if (removedElements == null) removedElements = new HashSet<ElementId>();
            if (removedEdges == null) removedEdges = new HashSet<EdgeId>();

            foreach (var id in removedElements)
            {
                _placements.RemoveEverywhere(id); // clear geometry in every diagram the element appeared in
                _styles.Remove(id);
                _nodeImage.Remove(id);
                _imageCache.Remove(id);
                _breakpoints.RemoveAllFor(id);
                _selection.Remove(id);
                if (_selectedId == id) _selectedId = ElementId.None;
                if (_selectedRegion == id) _selectedRegion = ElementId.None;
            }

            foreach (var edge in removedEdges)
                DropEdgeViewState(edge);

            var deadLinks = new List<ElementId>();
            foreach (var kv in _packageLink)
                if (removedElements.Contains(kv.Key) || removedElements.Contains(kv.Value))
                    deadLinks.Add(kv.Key);
            foreach (var id in deadLinks) _packageLink.Remove(id);

            ClearEdgeHandles3D();
            ExitResizeMode();
            RefreshInspector();
        }

        // --- view rebuild ---

        private void RebuildFromModel()
        {
            // The diagram now lives in the 3-D scene; the 2-D node/edge view dictionaries (_nodes / _edges) are no
            // longer populated for it (the UmlNodeView/UmlEdgeView classes remain defined but are not instantiated).
            _scene.RemoveAllNodes();
            _scene.ClearEdges();          // destroys edge + stub GameObjects (both created via _scene.AddEdge)
            ClearEdgeHandles3D();         // route-edit handles reference edge bindings we're about to clear
            EndEdgeHandleDrag3D();        // abandon any in-flight handle drag across the rebuild
            _scene3dEdges.Clear();
            _scene3dStubs.Clear();
            _scene3dStubBindings.Clear();
            _edgeKinds.Clear();
            ClearRegions3D();
            ClearResizeHandles(); // handles reference nodes about to be destroyed; rebuilt below if still in resize mode

            EnsureActivePackage();
            BuildTabBar();
            _browseNav?.RebuildTree(); // C1: model-derived browse tree (all diagrams), independent of active package

            if (!_activePackage.IsValid)
            {
                Flash("No package yet — right-click the canvas (or +) to add one.");
                RefreshBendHandles();
                return;
            }

            // Classifier boxes = direct classifier children of the active package. In 3-D, each node's z-layer
            // places it at a different world-Z depth plane. In 2-D mode, z-layers and per-node z offsets are ignored
            // and every node is posed on the same front-facing plane. Region kinds (boundary / frame / profile) are
            // NOT drawn as slabs — they become dotted regions built below.
            int spread = 0;
            foreach (var el in _model.Elements)
            {
                if (el.Parent != _activePackage) continue;
                if (!KindInfo.IsDiagramNode(el.Kind)) continue;
                if (IsRegionKind(el.Kind)) continue; // drawn as a region cube, not a slab
                // Native membership = parented under the active diagram. Seed a placement in this diagram's scope
                // (spread-laid) the first time it's shown; keep it thereafter.
                var seed = new Vector2(-360f + (spread % 4) * 240f, 120f - (spread / 4) * 200f);
                var p = _placements.EnsureNative(el.Id, seed).Pos;
                spread++;
                CreateNode3D(el, p);
            }

            // Linked appearances: elements placed in THIS diagram whose parent lives elsewhere (drag-drop link — Track C
            // populates these). Natives (parent == active) were drawn above; regions become cubes; members are never nodes.
            foreach (var kv in _placements.InDiagram(_activePackage))
            {
                if (!_model.TryGet(kv.Key, out var lel)) continue;      // stale placement — element gone
                if (lel.Parent == _activePackage) continue;             // native — already drawn above
                if (!KindInfo.IsDiagramNode(lel.Kind) || IsRegionKind(lel.Kind)) continue;
                CreateNode3D(lel, kv.Value.Pos);
            }

            // Region cubes: a dotted wireframe cube grouping the nodes that fall inside each region's footprint.
            RebuildRegions3D();

            // Relationship edges. Both endpoints shown → a normal edge between their (possibly depth-separated)
            // world centers. Exactly one endpoint hidden (its peer sits above the active layer) → a short up-stub
            // off the visible node signaling "continues on a layer above". Both hidden → nothing.
            foreach (var edge in _model.Edges)
            {
                bool fromShown = _scene.TryGetNode(edge.From, out _);
                bool toShown = _scene.TryGetNode(edge.To, out _);
                if (fromShown && toShown) CreateEdge3D(edge);
                else if (fromShown ^ toShown) CreateCrossLayerStub3D(edge, fromVisible: fromShown);
            }

            // Re-apply the selection highlight to the whole set. Drop ids whose nodes no longer exist (deleted /
            // package switch / a load that reset _selectedId directly without touching the set).
            if (!_selectedId.IsValid) _selection.Clear();
            _selection.RemoveWhere(id => !_scene.TryGetNode(id, out _));
            if (_selectedId.IsValid && !_selection.Contains(_selectedId)) _selectedId = ElementId.None;
            RefreshSelectionHighlights();
            RefreshInspector();

            // Edge bend handles are 2-D affordances; with the diagram in 3-D they are DEFERRED (no handles drawn).
            _selectedEdge = EdgeId.None;
            RefreshBendHandles();

            // Restore the resize-handle overlay if a node is still in resize mode (it survived the rebuild).
            if (_resizeModeNode.IsValid)
            {
                bool ok = _resizeModeIsRegion ? _regionById.ContainsKey(_resizeModeNode) : _scene.TryGetNode(_resizeModeNode, out _);
                if (ok) BuildResizeHandles(_resizeModeNode);
                else ExitResizeMode();
            }

            if (_mode2D) Apply2DModeCamera(false);
        }

        /// <summary>The full UML signatures of an element's field / operation members (Rose/Sparx convention).</summary>
        private void MemberSignatures(ModelElement el, out List<string> attributes, out List<string> operations)
        {
            attributes = new List<string>();
            operations = new List<string>();
            foreach (var childId in el.ChildIds)
            {
                if (!_model.TryGet(childId, out var c)) continue;
                if (c.Kind == ElementKind.Field) attributes.Add(c.Name);
                else if (c.Kind == ElementKind.Function) operations.Add(c.Name);
            }
        }

        /// <summary>
        /// Item rows for wireframe widgets. New diagrams store these on the element; older diagrams may still use
        /// Field children for list rows/table columns, so append those for compatibility.
        /// </summary>
        private List<string> WidgetItems(ModelElement el)
        {
            var items = new List<string>();
            if (el == null) return items;
            foreach (var item in el.Items)
                if (!string.IsNullOrWhiteSpace(item))
                    items.Add(item);
            foreach (var childId in el.ChildIds)
                if (_model.TryGet(childId, out var c) && c.Kind == ElementKind.Field)
                    items.Add(c.Name);
            return items;
        }

        /// <summary>Editable property rows for EA-gallery notation nodes, falling back to sensible kind defaults.</summary>
        private List<string> EaPropertyRows(ModelElement el)
        {
            var rows = new List<string>();
            if (el == null) return rows;
            foreach (var item in el.Items)
                if (!string.IsNullOrWhiteSpace(item)) rows.Add(item);
            foreach (var childId in el.ChildIds)
                if (_model.TryGet(childId, out var c) && c.Kind == ElementKind.Field)
                    rows.Add(c.Name);
            if (rows.Count == 0) rows.AddRange(DefaultPropertyItems(el.Kind));
            return rows;
        }

        /// <summary>The slab fill / text colors for an element — kind-hue default, overridden by a per-element style
        /// (ported from <c>UmlNodeView.Init</c> so the 3-D slabs read like the flat boxes did).</summary>
        private void NodeColors(ModelElement el, out Color fill, out Color text)
        {
            ColorUtility.TryParseHtmlString(KindInfo.Hue(el.Kind), out var hue);
            bool note = el.Kind == ElementKind.Note || el.Kind == ElementKind.WhiteboardSticky;
            bool darkFill = el.Kind == ElementKind.Actor || el.Kind == ElementKind.StateStart
                || el.Kind == ElementKind.StateEnd || el.Kind == ElementKind.ForkJoin
                || el.Kind == ElementKind.Junction || el.Kind == ElementKind.Terminate
                || el.Kind == ElementKind.FlowFinal;
            bool eaNeutral = KindInfo.UsesEaNeutralNotation(el.Kind);
            Color defaultFill =
                note ? new Color(0.99f, 0.96f, 0.74f, 1f)
                : darkFill ? new Color(0.20f, 0.21f, 0.25f, 1f)
                : eaNeutral ? new Color(0.98f, 0.985f, 0.99f, 1f)
                : Color.Lerp(hue, Color.white, 0.88f);
            Color defaultText = note ? new Color(0.16f, 0.15f, 0.06f, 1f) : new Color(0.13f, 0.15f, 0.19f, 1f);

            var style = _styles.TryGetValue(el.Id, out var st) ? st : default;
            fill = style.Has ? style.Fill : defaultFill;
            text = style.Has ? style.Text : defaultText;
        }

        /// <summary>A reasonable pixel size for a node's slab when the user hasn't sized it: the default box width and
        /// a height that grows with the member count (mirrors the flat renderer's content-driven sizing).</summary>
        private Vector2 NodeSizePx(ModelElement el, int attrCount, int opCount)
        {
            if (_placements.TrySize(el.Id, out var s)) return s;
            // The actor / person robot wants a PORTRAIT footprint (a standing figure), not the wide class-box default.
            if (el.Kind == ElementKind.Actor || el.Kind == ElementKind.Person) return new Vector2(108f, 168f);
            var wb = WhiteboardDefaultSize(el.Kind);
            if (wb.HasValue) return wb.Value;
            // Wireframe widgets get compact, per-kind default footprints (a button is small, a table is wide).
            var wf = WidgetDefaultSize(el.Kind, KindInfo.IsWireframeWidget(el.Kind) ? WidgetItems(el).Count : attrCount);
            if (wf.HasValue) return wf.Value;
            float headerH = 30f + (string.IsNullOrEmpty(Stereotype(el)) ? 0f : 16f);
            float attrH = Mathf.Max(1, attrCount) * 18f + 6f;
            float opH = Mathf.Max(1, opCount) * 18f + 6f;
            return new Vector2(UmlNodeView.DefaultWidth, headerH + 2f + attrH + 2f + opH);
        }

        private static Vector2? WhiteboardDefaultSize(ElementKind kind) => kind switch
        {
            ElementKind.WhiteboardSticky => new Vector2(180f, 120f),
            ElementKind.WhiteboardCard => new Vector2(180f, 96f),
            ElementKind.WhiteboardText => new Vector2(160f, 44f),
            ElementKind.WhiteboardCircle => new Vector2(132f, 90f),
            ElementKind.WhiteboardDiamond => new Vector2(116f, 82f),
            ElementKind.WhiteboardTriangle => new Vector2(120f, 104f),
            ElementKind.WhiteboardRectangle => new Vector2(132f, 84f),
            ElementKind.WhiteboardCube => new Vector2(110f, 110f),
            ElementKind.WhiteboardSphere => new Vector2(108f, 108f),
            ElementKind.WhiteboardCylinder => new Vector2(100f, 120f),
            ElementKind.WhiteboardDecahedron => new Vector2(108f, 108f),
            ElementKind.WhiteboardBlob => new Vector2(116f, 104f),
            ElementKind.AsyncSend => new Vector2(160f, 60f),
            ElementKind.AsyncReceive => new Vector2(160f, 60f),
            ElementKind.SysmlProxyPort => new Vector2(24f, 24f),
            ElementKind.SysmlFullPort => new Vector2(24f, 24f),
            ElementKind.SysmlParameter => new Vector2(120f, 40f),
            ElementKind.SysmlRequirement => new Vector2(170f, 92f),
            ElementKind.SysmlConstraintBlock => new Vector2(180f, 86f),
            ElementKind.BpmnEvent => new Vector2(52f, 52f),
            ElementKind.BpmnActivity => new Vector2(170f, 72f),
            ElementKind.BpmnGateway => new Vector2(88f, 70f),
            ElementKind.BpmnDataObject => new Vector2(130f, 72f),
            ElementKind.BpmnDataStore => new Vector2(130f, 80f),
            ElementKind.BpmnPool => new Vector2(460f, 280f),
            ElementKind.BpmnLane => new Vector2(430f, 110f),
            ElementKind.BpmnConversation => new Vector2(116f, 76f),
            ElementKind.DmnDecision => new Vector2(150f, 86f),
            ElementKind.DmnInputData => new Vector2(150f, 70f),
            ElementKind.DmnDecisionService => new Vector2(180f, 100f),
            ElementKind.BalancedScorecardPerspective => new Vector2(360f, 180f),
            ElementKind.ZachmanCell => new Vector2(220f, 150f),
            _ => null,
        };

        /// <summary>A wireframe widget's default pixel footprint (null for non-widgets). Compact, control-shaped — a
        /// button isn't a full-width classifier box. Item-bearing widgets grow with their item count.</summary>
        private static Vector2? WidgetDefaultSize(ElementKind kind, int itemCount)
        {
            // Height for a vertical row-stack: rows × 18px + padding, with a 1–3 row floor.
            float rows(int n) => Mathf.Max(1, n) * 18f + 16f;
            switch (kind)
            {
                case ElementKind.UiWidget: return new Vector2(160f, 44f);
                case ElementKind.Button:   return new Vector2(120f, 44f);
                case ElementKind.Label:    return new Vector2(160f, 24f);
                case ElementKind.Link:     return new Vector2(160f, 24f);
                case ElementKind.TextField: return new Vector2(200f, 40f);
                case ElementKind.TextArea:  return new Vector2(200f, 80f);
                case ElementKind.Password:  return new Vector2(200f, 40f);
                case ElementKind.Checkbox:  return new Vector2(160f, 28f);
                case ElementKind.Radio:     return new Vector2(160f, 28f);
                case ElementKind.Dropdown:  return new Vector2(180f, 40f);
                case ElementKind.List:      return new Vector2(160f, rows(Mathf.Min(itemCount, 5)));
                case ElementKind.Table:     return new Vector2(280f, 80f + Mathf.Max(0, itemCount - 2) * 8f);
                case ElementKind.Tree:      return new Vector2(180f, rows(Mathf.Min(itemCount, 4)));
                case ElementKind.Image:     return new Vector2(180f, 120f);
                case ElementKind.Tabs:      return new Vector2(220f, 90f);
                case ElementKind.Menu:      return new Vector2(220f, 34f);
                case ElementKind.Toolbar:   return new Vector2(260f, 34f);
                case ElementKind.Breadcrumb:return new Vector2(240f, 26f);
                case ElementKind.Card:      return new Vector2(200f, 110f + Mathf.Max(0, itemCount) * 8f);
                case ElementKind.Separator: return new Vector2(220f, 12f);
                case ElementKind.Progress:  return new Vector2(200f, 40f);
                case ElementKind.Slider:    return new Vector2(200f, 40f);
                default: return null;
            }
        }

        private void CreateNode3D(ModelElement el, Vector2 pos)
        {
            MemberSignatures(el, out var attributes, out var operations);
            if (KindInfo.IsWireframeWidget(el.Kind))
                attributes = WidgetItems(el);
            else if (KindInfo.IsEaNotationNode(el.Kind))
            {
                attributes = EaPropertyRows(el);
                operations = new List<string>();
            }
            NodeColors(el, out var fill, out var text);
            Vector2 sizePx = CurrentNodeSizePx(el.Id); // honor a stored resize / pasted size, else the default
            var node = _scene.AddNode(el.Id, el.Name, Stereotype(el), el.Kind, fill, text,
                attributes, operations, sizePx);
            // Apply a per-node Z thickness override (set via the depth resize handle) before posing.
            if (_mode2D) node.SetThickness(FlatNodeThickness);
            else if (_placements.TryDepth(el.Id, out var th)) node.SetThickness(th);
            // World-Z = ZLayer × LayerGap: a higher layer sits further toward +Z (the front / camera side), a lower
            // layer recedes toward −Z. Every layer is drawn at full color (no active-layer graying anymore).
            float zOffset = _mode2D ? 0f : _placements.PosZ(el.Id);
            int zLayer = _mode2D ? 0 : el.ZLayer;
            node.SetWorldPose(Uml3DConfig.ModelToWorld(pos, zLayer) + new Vector3(0f, 0f, zOffset),
                Quaternion.identity);
            if (!_mode2D && _placements.TryRot(el.Id, out var localRot)) node.SetLocalRotation(localRot); // restore orientation
            node.SetDepthTint(0f);
            var img = LoadNodeImage(el.Id); // optional per-node picture rendered as a card on the face
            if (img != null) node.SetImage(img);
        }

        // --- region cubes (boundary / frame / profile drawn as a dotted cube grouping its member nodes) ---

        private readonly List<UmlRegion3D> _regions = new();
        private readonly Dictionary<ElementId, UmlRegion3D> _regionById = new();
        private ElementId _selectedRegion = ElementId.None;
        // World-space padding added around the member-node bounds so the cube doesn't clip its contents.
        private const float RegionPadding = 0.6f;
        // Default cube fill opacity for an un-styled region (the user can change it via the region colour editor).
        private const float DefaultRegionOpacity = 0.12f;
        // Default footprint (px) for a region that has no explicit size yet, and the cube's fixed world-Z depth.
        private static readonly Vector2 RegionDefaultSizePx = new Vector2(420f, 300f);
        private const float RegionDepthWorld = 2.5f;

        // Active region gesture (a cube grabbed by an edge): move (Ctrl/Cmd-drag) or resize (Ctrl/Cmd+Alt-drag).
        private bool _draggingRegion, _resizingRegion, _regionPressed;
        private ElementId _regionDrag = ElementId.None;
        private float _regionPlaneZ;
        private Vector3 _regionLastWorld;
        private readonly List<ElementId> _regionMembers = new();

        /// <summary>Boundary, interaction frame, profile and whiteboard frames are "regions" — grouping cubes, not slabs.</summary>
        private static bool IsRegionKind(ElementKind k) =>
            k == ElementKind.Boundary || k == ElementKind.Frame || k == ElementKind.Profile
            || k == ElementKind.WhiteboardFrame
            || KindInfo.IsEaRegion(k)
            || KindInfo.IsWireframeRegion(k); // Screen / Panel group their widgets and carry them when moved

        /// <summary>Destroy every live region cube.</summary>
        private void ClearRegions3D()
        {
            foreach (var r in _regions) if (r != null) Destroy(r.gameObject);
            _regions.Clear();
            _regionById.Clear();
        }

        /// <summary>The member node ids whose model-space position falls inside a region's px footprint.</summary>
        private List<ElementId> RegionMembers(ElementId regionId, Vector2 rp, Vector2 rSize)
        {
            var list = new List<ElementId>();
            float hw = rSize.x * 0.5f, hh = rSize.y * 0.5f;
            foreach (var kv in _scene.Nodes)
            {
                if (kv.Key == regionId || kv.Value == null) continue;
                if (!_placements.TryPos(kv.Key, out var mp)) continue;
                if (mp.x < rp.x - hw || mp.x > rp.x + hw || mp.y < rp.y - hh || mp.y > rp.y + hh) continue;
                list.Add(kv.Key);
            }
            return list;
        }

        /// <summary>
        /// The world box for a region — its EXPLICIT footprint (<c>_pos</c> centre + <c>_size</c> dims at a fixed
        /// depth), padded. The size is NEVER derived from member encapsulation: that made the cube re-size on every
        /// rebuild (style edits, undo) and absorb whatever nodes it overlapped after a move. An un-sized region is
        /// given a sensible default footprint once, baked into <c>_size</c> so it persists and stays put.
        /// </summary>
        private Bounds ComputeRegionBounds(ModelElement el)
        {
            if (!_placements.TryPos(el.Id, out var rp)) { rp = Vector2.zero; _placements.SetPos(el.Id, rp); }
            if (!_placements.TrySize(el.Id, out var s)) { s = RegionDefaultSizePx; _placements.SetSize(el.Id, s); }
            Vector3 center = Uml3DConfig.ModelToWorld(rp, _mode2D ? 0 : el.ZLayer);
            float depth = _mode2D ? FlatNodeThickness : RegionDepthWorld;
            Bounds b = new Bounds(center, new Vector3(s.x * Uml3DConfig.WorldScale, s.y * Uml3DConfig.WorldScale, depth));
            if (_mode2D) b.Expand(new Vector3(RegionPadding * 2f, RegionPadding * 2f, 0f));
            else b.Expand(RegionPadding * 2f);
            return b;
        }

        /// <summary>
        /// Build a dotted cube for each region element in the active package, fit around its member nodes. The cube
        /// edges are pickable (select / Ctrl-drag move / Ctrl+Alt-drag resize); the interior stays empty so clicks
        /// fall through to the member slabs.
        /// </summary>
        private void RebuildRegions3D()
        {
            var root = _scene != null && _scene.DiagramRoot != null ? _scene.DiagramRoot : transform;
            foreach (var el in _model.Elements)
            {
                if (el.Parent != _activePackage || !IsRegionKind(el.Kind)) continue;
                NodeColors(el, out var fill, out _);
                // The dotted edges use the region colour (opaque); the cube is filled with the same colour at the
                // chosen opacity (the fill colour's alpha, stored in the element style — default lightly translucent).
                float opacity = (_styles.TryGetValue(el.Id, out var st) && st.Has) ? st.Fill.a : DefaultRegionOpacity;
                var region = UmlRegion3D.Create(root, el.Id, el.Name, fill);
                region.SetBounds(ComputeRegionBounds(el));
                region.SetFill(new Color(fill.r, fill.g, fill.b, opacity));
                if (el.Id == _selectedRegion) region.SetHighlighted(true);
                _regions.Add(region);
                _regionById[el.Id] = region;
            }
            if (_selectedRegion.IsValid && !_regionById.ContainsKey(_selectedRegion)) _selectedRegion = ElementId.None;
        }

        /// <summary>Re-fit one region cube to its members' current bounds (called live during a region drag/resize).</summary>
        private void RefitRegion(ElementId id)
        {
            if (_regionById.TryGetValue(id, out var r) && r != null && _model.TryGet(id, out var el))
                r.SetBounds(ComputeRegionBounds(el));
        }

        /// <summary>Nearest region cube whose edge collider lies under the cursor, or null.</summary>
        private UmlRegion3D PickRegion3D(Vector2 screenPos)
        {
            if (_scene == null) return null;
            Ray ray = _scene.ScreenPointToRay(screenPos);
            var hits = Physics.RaycastAll(ray, 10000f);
            UmlRegion3D best = null; float bestD = float.MaxValue;
            foreach (var h in hits)
            {
                if (h.collider == null) continue;
                var r = h.collider.GetComponentInParent<UmlRegion3D>();
                if (r != null && h.distance < bestD) { bestD = h.distance; best = r; }
            }
            return best;
        }

        /// <summary>Drop the region selection highlight (called when a node / empty space is selected instead).</summary>
        private void ClearRegionSelection()
        {
            if (_selectedRegion.IsValid && _regionById.TryGetValue(_selectedRegion, out var r) && r != null)
                r.SetHighlighted(false);
            _selectedRegion = ElementId.None;
        }

        /// <summary>Select a region cube (clears any node / edge selection and highlights the cube).</summary>
        private void SelectRegion(ElementId id)
        {
            SetSelected(ElementId.None);   // clears node selection (and, via SetSelected, any prior region highlight)
            ClearSelectedEdge();
            _selectedRegion = id;
            if (id.IsValid && _regionById.TryGetValue(id, out var r) && r != null) r.SetHighlighted(true);
            if (id.IsValid && _model.TryGet(id, out var el)) Flash($"region “{el.Name}” — Ctrl-drag edge to move · Ctrl-click edge for resize handles · double-click for colour");
        }

        /// <summary>Right-click menu for a region cube: edit its colour / fill opacity, or delete it.</summary>
        public void ShowRegionMenu(ElementId id, Vector2 screenPos)
        {
            CloseMenu();
            SelectRegion(id);
            if (!_model.TryGet(id, out var el)) return;
            var rid = id;
            var items = new List<MenuItem>
            {
                new MenuItem("Color & fill opacity…", true, () => ShowRegionColorEditor(rid, screenPos)),
                new MenuItem("Resize handles  (Ctrl/Cmd+click an edge)", true, () => { CloseMenu(); SelectRegion(rid); EnterResizeMode(rid); }),
                MenuItem.Separator(),
                new MenuItem("Delete region", true, () =>
                {
                    _ctl.Delete(rid); _selectedRegion = ElementId.None;
                    FixActiveAfterChange(); CloseMenu(); RebuildFromModel();
                }),
            };
            CreateMenu(screenPos, $"Region — {Ellipsize(el.Name, 26)}", items);
        }

        /// <summary>Edit a region's colour and fill opacity with the HSV picker (its alpha slider = the fill opacity).</summary>
        private void ShowRegionColorEditor(ElementId id, Vector2 screenPos)
        {
            if (!_model.TryGet(id, out var el)) return;
            Color cur;
            if (_styles.TryGetValue(id, out var st) && st.Has) cur = st.Fill;
            else { NodeColors(el, out var fill, out _); cur = new Color(fill.r, fill.g, fill.b, DefaultRegionOpacity); }

            ShowColorPicker("Region fill & opacity", cur, c =>
            {
                BeginGeoEdit(); // make the colour / opacity change undoable (Ctrl/Cmd+Z)
                _styles.TryGetValue(id, out var prev);
                _styles[id] = new NodeStyle
                {
                    Has = true,
                    Fill = c, // rgb = cube + edge colour; alpha = fill opacity
                    Border = prev.Has ? prev.Border : new Color(0.42f, 0.45f, 0.51f, 1f),
                    Text = prev.Has ? prev.Text : new Color(0.13f, 0.15f, 0.19f, 1f),
                    FontName = prev.FontName,
                    FontSize = prev.FontSize,
                };
                RebuildFromModel();
                Flash("region colour & opacity set");
            });
        }

        /// <summary>Capture the member node set at the start of a region move so the group travels together.</summary>
        private void CaptureRegionMembers(ElementId id)
        {
            _regionMembers.Clear();
            if (!_model.TryGet(id, out var el)) return;
            if (!_placements.TryPos(id, out var rp)) rp = Vector2.zero;
            _regionMembers.AddRange(RegionMembers(id, rp, CurrentNodeSizePx(id)));
        }

        /// <summary>Move a grabbed region (and its captured members) across the region's world-Z plane.</summary>
        private void DragRegion(Vector2 screenPos)
        {
            if (!_regionDrag.IsValid) return;
            Vector3 world = ProjectToPlane(screenPos, _regionPlaneZ);
            Vector3 delta = world - _regionLastWorld;
            _regionLastWorld = world;
            if (delta.sqrMagnitude < 1e-10f) return;
            foreach (var id in _regionMembers) MoveNode3D(id, delta);
            if (_placements.TryPos(_regionDrag, out var rp))
                _placements.SetPos(_regionDrag, rp + new Vector2(delta.x / Uml3DConfig.WorldScale, delta.y / Uml3DConfig.WorldScale));
            // Translate the cube rigidly — keep its size constant. (Re-fitting here would re-run the spatial
            // member query and Encapsulate any node the footprint sweeps over, ballooning the cube unexpectedly.)
            if (_regionById.TryGetValue(_regionDrag, out var r) && r != null)
            {
                var b = r.CurrentBounds;
                b.center += new Vector3(delta.x, delta.y, 0f);
                r.SetBounds(b);
            }
        }

        /// <summary>Grow / shrink a grabbed region's footprint (right widens, down grows); members re-evaluate live.</summary>
        private void ResizeRegion(Vector2 mouseDelta)
        {
            if (!_regionDrag.IsValid) return;
            Vector2 sz = CurrentNodeSizePx(_regionDrag);
            float k = 1f / Mathf.Max(ScaleFactor, 0.0001f);
            sz.x = Mathf.Max(80f, sz.x + mouseDelta.x * k);
            sz.y = Mathf.Max(60f, sz.y - mouseDelta.y * k);
            _placements.SetSize(_regionDrag, sz);
            RefitRegion(_regionDrag);
        }

        // --- node resize mode (double-click a node → constrained resize handles) ---

        // Per-node Z thickness (world units). Absent ⇒ the default Uml3DConfig.NodeThickness. Persisted.

        private ElementId _resizeModeNode = ElementId.None;       // the node/region currently showing resize handles
        private bool _resizeModeIsRegion;                          // true ⇒ the resize target is a region cube
        private readonly List<UmlResizeHandle3D> _resizeHandles = new();
        private bool _resizing3d;                                  // a resize handle is being dragged
        private UmlResizeHandle3D.Role _resizeRole;
        private Vector2 _resizeDir;                                // the grabbed handle's face-local placement
        private ElementId _resizeNode = ElementId.None;
        private float _lastNodeClickTime;                          // double-click detection
        private ElementId _lastNodeClick = ElementId.None;
        private const float DoubleClickSecs = 0.35f;
        private const float ZThickPerPx = 0.004f;                  // world thickness change per pixel of vertical drag
        private const float ResizePxPerScreenPx = 2f;              // model-px size change per screen-px of outward drag

        private static readonly Color ResizeColW = new Color(0.90f, 0.30f, 0.30f, 1f); // X = red
        private static readonly Color ResizeColH = new Color(0.35f, 0.80f, 0.40f, 1f); // Y = green
        private static readonly Color ResizeColD = new Color(0.30f, 0.55f, 0.90f, 1f); // Z = blue
        private static readonly Color ResizeColA = new Color(0.95f, 0.62f, 0.18f, 1f); // all = orange

        /// <summary>Show the constrained resize handles on a node OR region (entered by double-clicking it).</summary>
        private void EnterResizeMode(ElementId id)
        {
            BuildResizeHandles(id);
            if (_resizeModeNode.IsValid)
                Flash("resize: drag a handle — corner ◣ all · side ▶ width(X) · top/bottom ▲ height(Y)"
                    + (_resizeModeIsRegion ? "" : " · center ◼ depth(Z)"));
        }

        // Handle layout in face-local {-1,0,1} units: 4 corners (Uniform), 4 edge-midpoints (Width on left/right,
        // Height on top/bottom), and (nodes only) a center Depth handle.
        private static readonly (UmlResizeHandle3D.Role role, Vector2 dir)[] ResizeLayout =
        {
            (UmlResizeHandle3D.Role.Uniform, new Vector2(-1f, -1f)),
            (UmlResizeHandle3D.Role.Uniform, new Vector2( 1f, -1f)),
            (UmlResizeHandle3D.Role.Uniform, new Vector2(-1f,  1f)),
            (UmlResizeHandle3D.Role.Uniform, new Vector2( 1f,  1f)),
            (UmlResizeHandle3D.Role.Width,   new Vector2(-1f,  0f)),
            (UmlResizeHandle3D.Role.Width,   new Vector2( 1f,  0f)),
            (UmlResizeHandle3D.Role.Height,  new Vector2( 0f, -1f)),
            (UmlResizeHandle3D.Role.Height,  new Vector2( 0f,  1f)),
        };

        private static Color ResizeColor(UmlResizeHandle3D.Role r) => r switch
        {
            UmlResizeHandle3D.Role.Width => ResizeColW,
            UmlResizeHandle3D.Role.Height => ResizeColH,
            UmlResizeHandle3D.Role.Depth => ResizeColD,
            _ => ResizeColA,
        };

        private void BuildResizeHandles(ElementId id)
        {
            ClearResizeHandles();
            _resizeModeNode = ElementId.None;
            if (!id.IsValid) return;
            bool isRegion = _regionById.ContainsKey(id);
            if (!isRegion && (_scene == null || !_scene.TryGetNode(id, out var n) || n == null)) return;
            _resizeModeNode = id;
            _resizeModeIsRegion = isRegion;
            var root = _scene != null && _scene.DiagramRoot != null ? _scene.DiagramRoot : transform;
            foreach (var (role, dir) in ResizeLayout)
                _resizeHandles.Add(UmlResizeHandle3D.Create(root, id, role, dir, ResizeColor(role)));
            // The depth (Z thickness) handle exists for 3-D nodes only — 2-D mode keeps every node flat.
            if (!isRegion && !_mode2D)
                _resizeHandles.Add(UmlResizeHandle3D.Create(root, id, UmlResizeHandle3D.Role.Depth, Vector2.zero, ResizeColD));
            RepositionResizeHandles();
        }

        /// <summary>Destroy the resize handles and reset the OS cursor.</summary>
        private void ClearResizeHandles()
        {
            foreach (var h in _resizeHandles) if (h != null) Destroy(h.gameObject);
            _resizeHandles.Clear();
            SetResizeCursor(null);
        }

        private void ExitResizeMode()
        {
            _resizeModeNode = ElementId.None;
            _resizeModeIsRegion = false;
            ClearResizeHandles();
        }

        /// <summary>The world frame of the current resize target (node face or region cube). False if it's gone.</summary>
        private bool ResizeFrame(out Vector3 c, out Vector3 right, out Vector3 up, out Vector3 fwd, out Vector2 he, out float front)
        {
            c = Vector3.zero; right = Vector3.right; up = Vector3.up; fwd = Vector3.forward; he = Vector2.zero; front = 0f;
            if (!_resizeModeNode.IsValid) return false;
            if (_resizeModeIsRegion)
            {
                if (!_regionById.TryGetValue(_resizeModeNode, out var r) || r == null) return false;
                var b = r.CurrentBounds;
                c = b.center; he = new Vector2(b.extents.x, b.extents.y); front = b.extents.z;
                return true;
            }
            if (_scene == null || !_scene.TryGetNode(_resizeModeNode, out var n) || n == null) return false;
            c = n.transform.position; right = n.FaceRight; up = n.FaceUp; fwd = n.FaceForward;
            he = n.FaceHalfExtents; front = n.CurrentDepth * 0.5f;
            return true;
        }

        /// <summary>Re-seat the resize handles on the target's face corners/edges (called each LateUpdate so they track).</summary>
        private void RepositionResizeHandles()
        {
            if (!_resizeModeNode.IsValid) return;
            if (!ResizeFrame(out var c, out var right, out var up, out var fwd, out var he, out var front)) { ExitResizeMode(); return; }
            foreach (var h in _resizeHandles)
            {
                if (h == null) continue;
                if (h.HandleRole == UmlResizeHandle3D.Role.Depth)
                    h.SetWorldPosition(c + fwd * (front + 0.14f));
                else
                    h.SetWorldPosition(c + right * (h.Dir.x * he.x) + up * (h.Dir.y * he.y) + fwd * front);
            }
        }

        /// <summary>On a left mouse-down in resize mode, begin a resize drag if a handle was hit (returns true to
        /// consume the press). Snapshots geometry first so the resize is undoable.</summary>
        private bool TryBeginResizeDrag(Vector2 screenPos)
        {
            if (!_resizeModeNode.IsValid || _resizeHandles.Count == 0) return false;
            Ray ray = _scene.ScreenPointToRay(screenPos);
            var hits = Physics.RaycastAll(ray, 10000f);
            UmlResizeHandle3D handle = null; float bestD = float.MaxValue;
            foreach (var h in hits)
            {
                if (h.collider == null) continue;
                var cand = h.collider.GetComponentInParent<UmlResizeHandle3D>();
                if (cand != null && h.distance < bestD) { bestD = h.distance; handle = cand; }
            }
            if (handle == null) return false;
            BeginGeoEdit();
            _resizing3d = true;
            _resizeRole = handle.HandleRole;
            _resizeDir = handle.Dir;
            _resizeNode = handle.Node;
            return true;
        }

        /// <summary>
        /// Drive an active resize from the mouse delta. Grow amount = the drag projected onto the handle's ON-SCREEN
        /// outward direction (so dragging a handle away from the center always enlarges, regardless of camera
        /// orientation or the +Z-face mirroring); depth uses vertical drag (up = thicker).
        /// </summary>
        private void DragResize3D(Vector2 mouseDelta)
        {
            if (!_resizeModeNode.IsValid) return;
            bool isRegion = _resizeModeIsRegion;
            UmlNode3D node = null;
            if (!isRegion && (!_scene.TryGetNode(_resizeNode, out node) || node == null)) return;
            if (!ResizeFrame(out var c, out var right, out var up, out var fwd, out var he, out _)) return;

            if (_resizeRole == UmlResizeHandle3D.Role.Depth && !isRegion)
            {
                float cur = _placements.TryDepth(_resizeNode, out var t) ? t : node.CurrentDepth;
                float th = Mathf.Max(0.04f, cur + mouseDelta.y * ZThickPerPx); // drag up ⇒ thicker
                _placements.SetDepth(_resizeNode, th); node.SetThickness(th);
                RepositionResizeHandles();
                return;
            }

            // Screen-space outward direction of the grabbed handle (center → handle), projected.
            Vector3 outWorld = right * (_resizeDir.x * Mathf.Max(0.001f, he.x)) + up * (_resizeDir.y * Mathf.Max(0.001f, he.y));
            Vector2 a = _scene.WorldToScreen(c);
            Vector2 b = _scene.WorldToScreen(c + outWorld);
            Vector2 outScreen = b - a;
            float grow = outScreen.sqrMagnitude > 1e-4f ? Vector2.Dot(mouseDelta, outScreen.normalized) : 0f;
            float delta = grow * ResizePxPerScreenPx / Mathf.Max(ScaleFactor, 0.0001f);

            Vector2 sz = CurrentNodeSizePx(_resizeNode);
            if (_resizeRole == UmlResizeHandle3D.Role.Width) sz.x = Mathf.Max(60f, sz.x + delta);
            else if (_resizeRole == UmlResizeHandle3D.Role.Height) sz.y = Mathf.Max(40f, sz.y + delta);
            else { sz.x = Mathf.Max(60f, sz.x + delta); sz.y = Mathf.Max(40f, sz.y + delta); } // Uniform corner
            _placements.SetSize(_resizeNode, sz);

            if (isRegion) RefitRegion(_resizeNode);
            else
            {
                node.Resize(sz);
                if (_resizeRole == UmlResizeHandle3D.Role.Uniform && !_mode2D)
                {
                    float cur = _placements.TryDepth(_resizeNode, out var t) ? t : node.CurrentDepth;
                    float th = Mathf.Max(0.04f, cur + delta * Uml3DConfig.WorldScale);
                    _placements.SetDepth(_resizeNode, th); node.SetThickness(th);
                }
            }
            RepositionResizeHandles();
        }

        /// <summary>Update the OS cursor to indicate which resize a hovered handle performs (called each frame).</summary>
        private UmlResizeHandle3D.Role? _cursorRole;
        private void UpdateResizeCursor()
        {
            if (!_resizeModeNode.IsValid || _resizing3d || PointerOverUI()) { if (!_resizing3d) SetResizeCursor(null); return; }
            Ray ray = _scene.ScreenPointToRay(Input.mousePosition);
            var hits = Physics.RaycastAll(ray, 10000f);
            UmlResizeHandle3D handle = null; float bestD = float.MaxValue;
            foreach (var h in hits)
            {
                if (h.collider == null) continue;
                var cand = h.collider.GetComponentInParent<UmlResizeHandle3D>();
                if (cand != null && h.distance < bestD) { bestD = h.distance; handle = cand; }
            }
            SetResizeCursor(handle != null ? handle.HandleRole : (UmlResizeHandle3D.Role?)null);
        }

        private void SetResizeCursor(UmlResizeHandle3D.Role? role)
        {
            if (_cursorRole == role) return;
            _cursorRole = role;
            Texture2D tex = role switch
            {
                UmlResizeHandle3D.Role.Width => UmlNavIcons.TexX,
                UmlResizeHandle3D.Role.Height => UmlNavIcons.TexY,
                UmlResizeHandle3D.Role.Depth => UmlNavIcons.TexZ,
                UmlResizeHandle3D.Role.Uniform => UmlNavIcons.TexZ,
                _ => null,
            };
            if (tex != null) Cursor.SetCursor(tex, new Vector2(tex.width * 0.5f, tex.height * 0.5f), CursorMode.Auto);
            else Cursor.SetCursor(null, Vector2.zero, CursorMode.Auto);
        }

        // --- geometry undo / redo (positions, sizes, Z offsets, thicknesses — view-state, separate from model undo) ---

        private sealed class GeoSnapshot
        {
            public PlacementStore Placements;                       // whole per-diagram geometry store (pos/size/Z/depth/rotation)
            public Dictionary<ElementId, NodeStyle> Styles;
        }

        private readonly List<GeoSnapshot> _geoUndo = new();
        private readonly List<GeoSnapshot> _geoRedo = new();
        private const int GeoUndoMax = 80;

        // Snapshot the whole placement store (all diagrams). Folding rotation into the store means undo now also covers
        // per-node orientation, which the former flat snapshot did not capture.
        private GeoSnapshot SnapshotGeo() => new GeoSnapshot
        {
            Placements = _placements.Clone(),
            Styles = new Dictionary<ElementId, NodeStyle>(_styles),
        };

        private void RestoreGeo(GeoSnapshot s)
        {
            _placements.RestoreFrom(s.Placements);
            _styles.Clear(); foreach (var kv in s.Styles) _styles[kv.Key] = kv.Value;
        }

        /// <summary>Snapshot the current geometry before a move/resize so it can be undone. Clears the redo stack.</summary>
        private void BeginGeoEdit()
        {
            _geoUndo.Add(SnapshotGeo());
            if (_geoUndo.Count > GeoUndoMax) _geoUndo.RemoveAt(0);
            _geoRedo.Clear();
        }

        private bool GeoUndo()
        {
            if (_geoUndo.Count == 0) return false;
            _geoRedo.Add(SnapshotGeo());
            var s = _geoUndo[_geoUndo.Count - 1];
            _geoUndo.RemoveAt(_geoUndo.Count - 1);
            RestoreGeo(s);
            RebuildFromModel();
            Flash("↶ undo move/resize");
            return true;
        }

        private bool GeoRedo()
        {
            if (_geoRedo.Count == 0) return false;
            _geoUndo.Add(SnapshotGeo());
            var s = _geoRedo[_geoRedo.Count - 1];
            _geoRedo.RemoveAt(_geoRedo.Count - 1);
            RestoreGeo(s);
            RebuildFromModel();
            Flash("↷ redo move/resize");
            return true;
        }

        // --- cross-layer up-stubs (an edge whose peer is hidden above the active layer) ---

        private readonly List<UmlEdge3D> _scene3dStubs = new();
        // The world-Y rise of a cross-layer stub off the visible node's top.
        private const float CrossLayerStubRise = 0.8f;
        private static readonly Color CrossLayerStubColor = new Color(0.42f, 0.72f, 0.45f, 1f);

        /// <summary>
        /// Draw a short stub rising off the visible endpoint of an edge whose other endpoint is hidden above the
        /// active layer — a "continues on a layer above" affordance. The stub re-seats each LateUpdate as the
        /// visible node moves (see <see cref="LateUpdate"/>).
        /// </summary>
        private void CreateCrossLayerStub3D(ModelEdge edge, bool fromVisible)
        {
            ElementId visibleId = fromVisible ? edge.From : edge.To;
            if (!_scene.TryGetNode(visibleId, out var vis) || vis == null) return;
            var stub = _scene.AddEdge();
            stub.SetArrow(true);
            _scene3dStubs.Add(stub);
            _scene3dStubBindings.Add(new Stub3DBinding { View = stub, Visible = visibleId });
            RouteCrossLayerStub3D(_scene3dStubBindings[_scene3dStubBindings.Count - 1]);
        }

        private struct Stub3DBinding { public UmlEdge3D View; public ElementId Visible; }
        private readonly List<Stub3DBinding> _scene3dStubBindings = new();

        /// <summary>Re-seat one cross-layer stub from the visible node's top straight up.</summary>
        private void RouteCrossLayerStub3D(Stub3DBinding b)
        {
            if (b.View == null) return;
            if (!_scene.TryGetNode(b.Visible, out var vis) || vis == null) return;
            Vector3 top = vis.transform.position;
            b.View.SetRoute(new[] { top, top + Vector3.up * CrossLayerStubRise }, CrossLayerStubColor);
            b.View.SetArrow(true);
        }

        private void CreateEdge3D(ModelEdge edge)
        {
            var (dashed, src, tgt, stereo) = EdgeVisual(edge.Kind);
            _edgeKinds[edge.Id] = edge.Kind;
            var e = _scene.AddEdge();
            // Directed when either end carries an arrowhead (most relationship kinds point at the target).
            bool directed = src != EndMarker.None || tgt != EndMarker.None;
            _scene3dEdges.Add(new Edge3DBinding { View = e, Id = edge.Id, From = edge.From, To = edge.To, Directed = directed, Kind = edge.Kind });
            RouteEdge3D(_scene3dEdges[_scene3dEdges.Count - 1]);
        }

        /// <summary>
        /// Route one 3-D edge: source endpoint → its interior waypoints (if any) → target endpoint. Each endpoint is
        /// the node center by default, or a movable point on the node face when a face attachment is stored (part 3).
        /// Dashed relationship kinds render with true dashes; the selected link draws in the highlight color and the
        /// two compose. Re-run every LateUpdate so the link tracks as nodes move / the camera orbits.
        /// </summary>
        private void RouteEdge3D(Edge3DBinding b)
        {
            if (b.View == null) return;
            if (!_scene.TryGetNode(b.From, out var from) || from == null) return;
            if (!_scene.TryGetNode(b.To, out var to) || to == null) return;

            var wps = _waypoints3d.TryGetValue(b.Id, out var w) ? w : null;
            // What each endpoint aims at (for border-clipping): the first/last waypoint if any, else the far node.
            Vector3 fromToward = (wps != null && wps.Count > 0) ? wps[0] : to.transform.position;
            Vector3 toToward = (wps != null && wps.Count > 0) ? wps[wps.Count - 1] : from.transform.position;

            // A dragged attachment point wins; otherwise clip to the node's border facing the link (its SIDE, not
            // the center) so relationships meet the box edges like conventional UML.
            Vector3 srcPt = _srcFace.TryGetValue(b.Id, out var sf) ? from.FacePointLocal(sf) : NodeBorderPoint(from, fromToward);
            Vector3 tgtPt = _tgtFace.TryGetValue(b.Id, out var tf) ? to.FacePointLocal(tf) : NodeBorderPoint(to, toToward);

            var pts = new List<Vector3>(2 + 4) { srcPt };
            if (wps != null) pts.AddRange(wps);
            pts.Add(tgtPt);
            if (_mode2D) FlattenRoute(pts);

            // Curved links (the "Make curved (bezier)" toggle, _curved set): sample a smooth spline through the
            // route so the LineRenderer draws a bezier-like curve instead of straight segments.
            if (_curved.Contains(b.Id)) pts = SmoothCurve(pts);

            Color col = (_selectedEdge.IsValid && b.Id == _selectedEdge) ? EdgeSelectedColor : EdgeColor;
            bool dashed = EdgeVisual(b.Kind).dashed;
            b.View.SetRoute(pts, col, dashed);
            b.View.SetArrow(b.Directed);
        }

        private static void FlattenRoute(List<Vector3> pts)
        {
            if (pts == null) return;
            for (int i = 0; i < pts.Count; i++) pts[i] = new Vector3(pts[i].x, pts[i].y, FlatRouteZ);
        }

        /// <summary>
        /// Sample a smooth Catmull-Rom spline through the route's control points (so a curved link renders as a
        /// bezier-like arc). A plain two-point link gets a perpendicular mid control so it visibly bows.
        /// </summary>
        private static List<Vector3> SmoothCurve(List<Vector3> ctrl)
        {
            if (ctrl == null || ctrl.Count < 2) return ctrl;

            List<Vector3> c = ctrl;
            if (ctrl.Count == 2)
            {
                Vector3 a = ctrl[0], z = ctrl[1];
                Vector3 d = z - a;
                float len = d.magnitude;
                if (len < 1e-4f) return ctrl;
                Vector3 n = Vector3.Cross(d / len, Vector3.up);
                if (n.sqrMagnitude < 1e-4f) n = Vector3.Cross(d / len, Vector3.right);
                Vector3 mid = (a + z) * 0.5f + n.normalized * (len * 0.18f); // gentle sideways bow
                c = new List<Vector3> { a, mid, z };
            }

            const int seg = 18;
            var outp = new List<Vector3>((c.Count - 1) * seg + 1);
            for (int i = 0; i < c.Count - 1; i++)
            {
                Vector3 p0 = c[Mathf.Max(0, i - 1)];
                Vector3 p1 = c[i];
                Vector3 p2 = c[i + 1];
                Vector3 p3 = c[Mathf.Min(c.Count - 1, i + 2)];
                for (int s = 0; s < seg; s++) outp.Add(CatmullRom(p0, p1, p2, p3, s / (float)seg));
            }
            outp.Add(c[c.Count - 1]);
            return outp;
        }

        private static Vector3 CatmullRom(Vector3 p0, Vector3 p1, Vector3 p2, Vector3 p3, float t)
        {
            float t2 = t * t, t3 = t2 * t;
            return 0.5f * ((2f * p1) + (-p0 + p2) * t
                + (2f * p0 - 5f * p1 + 4f * p2 - p3) * t2
                + (-p0 + 3f * p1 - 3f * p2 + p3) * t3);
        }

        /// <summary>
        /// The point on a node's face border in the direction of <paramref name="toward"/> — so links attach to the
        /// SIDE of a box rather than its center. Works in the node's own face basis, so it honors per-node rotation.
        /// </summary>
        private static Vector3 NodeBorderPoint(UmlNode3D node, Vector3 toward)
        {
            Vector3 c = node.transform.position;
            Vector3 dir = toward - c;
            Vector2 he = node.FaceHalfExtents; // world half-width / half-height of the face
            float ax = Vector3.Dot(dir, node.FaceRight);
            float ay = Vector3.Dot(dir, node.FaceUp);
            if (Mathf.Abs(ax) < 1e-4f && Mathf.Abs(ay) < 1e-4f) return node.FacePointLocal(Vector2.zero);
            // Scale the projected direction out to whichever border (left/right or top/bottom) it reaches first.
            float t = Mathf.Min(
                he.x > 1e-4f ? he.x / Mathf.Max(Mathf.Abs(ax), 1e-4f) : float.MaxValue,
                he.y > 1e-4f ? he.y / Mathf.Max(Mathf.Abs(ay), 1e-4f) : float.MaxValue);
            float bx = ax * t, by = ay * t;
            float fx = he.x > 1e-4f ? bx / (2f * he.x) : 0f; // normalize to FacePointLocal's [-0.5,0.5]
            float fy = he.y > 1e-4f ? by / (2f * he.y) : 0f;
            return node.FacePointLocal(new Vector2(fx, fy));
        }

        /// <summary>The link nearest <paramref name="screenPos"/> within <see cref="EdgePickPx"/>, by projecting each
        /// link's endpoint slabs to screen and measuring distance to the segment. EdgeId.None if none is close.</summary>
        private EdgeId PickEdge3D(Vector2 screenPos)
        {
            EdgeId best = EdgeId.None;
            float bestDist = EdgePickPx;
            foreach (var b in _scene3dEdges)
            {
                var route = CurrentRoutePoints(b.Id, out var ok);
                if (!ok) continue;

                for (int i = 0; i + 1 < route.Count; i++)
                {
                    Vector3 a = _scene.WorldToScreen(route[i]);
                    Vector3 c = _scene.WorldToScreen(route[i + 1]);
                    if (a.z <= 0f || c.z <= 0f) continue; // segment endpoint behind the camera
                    float d = DistPointToSegment(screenPos, a, c);
                    if (d < bestDist) { bestDist = d; best = b.Id; }
                }
            }
            return best;
        }

        /// <summary>Select a link (clears any node selection); the 3-D edge recolors on the next route pass and its
        /// route-edit handles are (re)built on the next LateUpdate via <see cref="SyncEdgeHandles3D"/>.</summary>
        private void Select3DEdge(EdgeId edge)
        {
            SetSelected(ElementId.None);
            _selectedEdge = edge;
        }

        // --- 3-D edge route-edit handles (waypoints / midpoints / endpoint anchors on the selected link) ---

        /// <summary>Find the live binding for an edge id (default struct if absent — caller checks View != null).</summary>
        private Edge3DBinding FindEdgeBinding(EdgeId id)
        {
            foreach (var b in _scene3dEdges) if (b.Id == id) return b;
            return default;
        }

        /// <summary>Destroy every live route-edit handle and forget which edge they belonged to.</summary>
        private void ClearEdgeHandles3D()
        {
            foreach (var h in _edgeHandles3d) if (h != null) Destroy(h.gameObject);
            _edgeHandles3d.Clear();
            _handlesForEdge = EdgeId.None;
        }

        /// <summary>
        /// Reconcile the live handle set with the current selection (called each LateUpdate). When the selected edge
        /// changes (or clears) the handles are rebuilt; otherwise they're just repositioned to track the live route.
        /// Suppressed mid-drag so a rebuild can't yank the handle out from under an active drag.
        /// </summary>
        private void SyncEdgeHandles3D()
        {
            if (_draggingHandle) { RepositionEdgeHandles3D(); return; }

            if (_selectedEdge != _handlesForEdge)
            {
                ClearEdgeHandles3D();
                if (_selectedEdge.IsValid) BuildEdgeHandles3D(_selectedEdge);
            }
            RepositionEdgeHandles3D();
        }

        /// <summary>
        /// Spawn the route-edit handles for one selected link: a yellow MOVE sphere at each interior waypoint, a
        /// translucent-green ADD sphere at each segment midpoint, and an orange endpoint anchor at each end. Their
        /// world positions are seated by the immediately-following <see cref="RepositionEdgeHandles3D"/>.
        /// </summary>
        private void BuildEdgeHandles3D(EdgeId edge)
        {
            var b = FindEdgeBinding(edge);
            if (b.View == null) return;
            var root = _scene != null && _scene.DiagramRoot != null ? _scene.DiagramRoot : transform;

            int wpCount = _waypoints3d.TryGetValue(edge, out var wps) ? wps.Count : 0;

            // Endpoint anchors (orange) — index unused for anchors.
            _edgeHandles3d.Add(UmlEdgeHandle3D.Create(root, edge, 0, UmlEdgeHandle3D.HandleRole.SrcAnchor, HandleAnchorColor));
            _edgeHandles3d.Add(UmlEdgeHandle3D.Create(root, edge, 0, UmlEdgeHandle3D.HandleRole.TgtAnchor, HandleAnchorColor));

            // Move handle per existing waypoint (yellow).
            for (int i = 0; i < wpCount; i++)
                _edgeHandles3d.Add(UmlEdgeHandle3D.Create(root, edge, i, UmlEdgeHandle3D.HandleRole.Waypoint, HandleWaypointColor));

            // Add handle per route segment midpoint (green). Segments = waypoints + 1.
            for (int seg = 0; seg <= wpCount; seg++)
                _edgeHandles3d.Add(UmlEdgeHandle3D.Create(root, edge, seg, UmlEdgeHandle3D.HandleRole.AddMidpoint, HandleMidpointColor));

            _handlesForEdge = edge;
        }

        /// <summary>Re-seat every live handle onto its current route point (endpoints, waypoints, segment midpoints).</summary>
        private void RepositionEdgeHandles3D()
        {
            if (_edgeHandles3d.Count == 0) return;
            var route = CurrentRoutePoints(_handlesForEdge, out var ok);
            if (!ok) { ClearEdgeHandles3D(); return; }

            foreach (var h in _edgeHandles3d)
            {
                if (h == null) continue;
                switch (h.Role)
                {
                    case UmlEdgeHandle3D.HandleRole.SrcAnchor:
                        h.SetWorldPosition(route[0]);
                        break;
                    case UmlEdgeHandle3D.HandleRole.TgtAnchor:
                        h.SetWorldPosition(route[route.Count - 1]);
                        break;
                    case UmlEdgeHandle3D.HandleRole.Waypoint:
                        // Waypoint i sits at route index i+1 (interior point, after the source endpoint).
                        if (h.Index + 1 <= route.Count - 2)
                            h.SetWorldPosition(route[h.Index + 1]);
                        break;
                    case UmlEdgeHandle3D.HandleRole.AddMidpoint:
                        if (h.Index + 1 < route.Count)
                            h.SetWorldPosition((route[h.Index] + route[h.Index + 1]) * 0.5f);
                        break;
                }
            }
        }

        /// <summary>
        /// The current world-space route polyline for an edge (source endpoint, interior waypoints, target endpoint),
        /// mirroring what <see cref="RouteEdge3D"/> draws. <paramref name="ok"/> is false if the edge or a node is gone.
        /// </summary>
        private List<Vector3> CurrentRoutePoints(EdgeId edge, out bool ok)
        {
            ok = false;
            var pts = new List<Vector3>();
            if (!edge.IsValid) return pts;
            var b = FindEdgeBinding(edge);
            if (b.View == null) return pts;
            if (!_scene.TryGetNode(b.From, out var from) || from == null) return pts;
            if (!_scene.TryGetNode(b.To, out var to) || to == null) return pts;

            Vector3 srcPt = _srcFace.TryGetValue(edge, out var sf) ? from.FacePointLocal(sf) : from.transform.position;
            Vector3 tgtPt = _tgtFace.TryGetValue(edge, out var tf) ? to.FacePointLocal(tf) : to.transform.position;
            pts.Add(srcPt);
            if (_waypoints3d.TryGetValue(edge, out var wps)) pts.AddRange(wps);
            pts.Add(tgtPt);
            if (_mode2D) FlattenRoute(pts);
            ok = true;
            return pts;
        }

        // --- 3-D edge handle dragging ---

        /// <summary>
        /// On a left mouse-down, test whether a route-edit handle was hit (a Physics raycast for an
        /// <see cref="UmlEdgeHandle3D"/>). If so, begin a handle drag and return true so the caller skips the node /
        /// edge / camera gestures. An Alt-click on a MOVE (waypoint) handle deletes that waypoint instead of dragging.
        /// </summary>
        private bool TryBeginEdgeHandleDrag3D(Vector2 screenPos, bool alt)
        {
            if (!_selectedEdge.IsValid || _edgeHandles3d.Count == 0) return false;
            Ray ray = _scene.ScreenPointToRay(screenPos);
            // RaycastAll + pick the NEAREST handle among all hits: a node slab may sit in front of a handle, so a
            // single Raycast could return the slab and miss the handle behind it. Handles always win the press.
            var hits = Physics.RaycastAll(ray, 10000f);
            UmlEdgeHandle3D handle = null;
            float bestDist = float.MaxValue;
            foreach (var h in hits)
            {
                if (h.collider == null) continue;
                var cand = h.collider.GetComponentInParent<UmlEdgeHandle3D>();
                if (cand != null && h.distance < bestDist) { bestDist = h.distance; handle = cand; }
            }
            if (handle == null) return false;

            // Alt-click on an existing waypoint deletes it (no drag).
            if (alt && handle.Role == UmlEdgeHandle3D.HandleRole.Waypoint)
            {
                DeleteWaypoint3D(handle.Edge, handle.Index);
                return true;
            }

            _draggingHandle = true;
            _handleEdge = handle.Edge;
            _handleRole = handle.Role;
            _handleIndex = handle.Index;

            // A MIDPOINT add-handle materializes a new waypoint at its segment, then drags as that waypoint.
            if (_handleRole == UmlEdgeHandle3D.HandleRole.AddMidpoint)
            {
                int newIndex = InsertWaypoint3D(_handleEdge, _handleIndex, handle.transform.position);
                _handleRole = UmlEdgeHandle3D.HandleRole.Waypoint;
                _handleIndex = newIndex;
                // Rebuild handles for the new waypoint count so the live set matches the edited route.
                ClearEdgeHandles3D();
                BuildEdgeHandles3D(_handleEdge);
            }

            // Drag on a plane through the grabbed point whose normal faces the camera, so the point tracks the cursor.
            _handlePlanePoint = handle.transform.position;
            var cam = _scene != null ? _scene.Camera : null;
            _handlePlaneNormal = cam != null ? cam.transform.forward : Vector3.forward;
            return true;
        }

        /// <summary>Drive the active handle drag from the cursor: move a waypoint along the screen-parallel plane, or
        /// slide an endpoint anchor across the node face. Re-routes live (handles reposition on the next LateUpdate).</summary>
        private void UpdateEdgeHandleDrag3D(Vector2 screenPos)
        {
            if (!_draggingHandle) return;
            switch (_handleRole)
            {
                case UmlEdgeHandle3D.HandleRole.Waypoint:
                {
                    Vector3 world = ProjectToCameraPlane(screenPos, _handlePlanePoint, _handlePlaneNormal);
                    if (_mode2D) world = new Vector3(world.x, world.y, FlatRouteZ);
                    if (_waypoints3d.TryGetValue(_handleEdge, out var wps) && _handleIndex >= 0 && _handleIndex < wps.Count)
                        wps[_handleIndex] = world;
                    break;
                }
                case UmlEdgeHandle3D.HandleRole.SrcAnchor:
                case UmlEdgeHandle3D.HandleRole.TgtAnchor:
                {
                    var b = FindEdgeBinding(_handleEdge);
                    if (b.View == null) break;
                    bool isSrc = _handleRole == UmlEdgeHandle3D.HandleRole.SrcAnchor;
                    ElementId nodeId = isSrc ? b.From : b.To;
                    if (!_scene.TryGetNode(nodeId, out var node) || node == null) break;
                    Vector2 norm = CursorToFaceOffset(node, screenPos);
                    if (isSrc) _srcFace[_handleEdge] = norm; else _tgtFace[_handleEdge] = norm;
                    break;
                }
            }
        }

        /// <summary>End an active handle drag.</summary>
        private void EndEdgeHandleDrag3D()
        {
            if (!_draggingHandle) return;
            _draggingHandle = false;
            _handleEdge = EdgeId.None;
        }

        /// <summary>Insert a new waypoint for an edge at the given segment index, returning its waypoint slot.</summary>
        private int InsertWaypoint3D(EdgeId edge, int segIndex, Vector3 world)
        {
            if (!_waypoints3d.TryGetValue(edge, out var list)) { list = new List<Vector3>(); _waypoints3d[edge] = list; }
            int idx = Mathf.Clamp(segIndex, 0, list.Count);
            if (_mode2D) world = new Vector3(world.x, world.y, FlatRouteZ);
            list.Insert(idx, world);
            return idx;
        }

        /// <summary>Delete an edge's waypoint at a slot and rebuild its handles for the new count.</summary>
        private void DeleteWaypoint3D(EdgeId edge, int index)
        {
            if (_waypoints3d.TryGetValue(edge, out var list) && index >= 0 && index < list.Count)
            {
                list.RemoveAt(index);
                if (list.Count == 0) _waypoints3d.Remove(edge);
            }
            if (_handlesForEdge == edge) { ClearEdgeHandles3D(); if (_selectedEdge.IsValid) BuildEdgeHandles3D(_selectedEdge); }
            Flash("removed bend point");
        }

        /// <summary>Intersect the camera ray through <paramref name="screenPos"/> with the plane through
        /// <paramref name="planePoint"/> with the given <paramref name="normal"/> (the screen-parallel drag plane).</summary>
        private Vector3 ProjectToCameraPlane(Vector2 screenPos, Vector3 planePoint, Vector3 normal)
        {
            Ray ray = _scene.ScreenPointToRay(screenPos);
            float denom = Vector3.Dot(ray.direction, normal);
            if (Mathf.Abs(denom) < 1e-6f) return planePoint;
            float t = Vector3.Dot(planePoint - ray.origin, normal) / denom;
            return ray.origin + ray.direction * t;
        }

        /// <summary>
        /// Project the cursor onto a node's +Z face plane and convert the hit to the node-local NORMALIZED face offset
        /// (each axis clamped to [-0.5,0.5]; (0,0) = face center) used by the face-attachment dictionaries.
        /// </summary>
        private Vector2 CursorToFaceOffset(UmlNode3D node, Vector2 screenPos)
        {
            Vector3 center = node.transform.position;
            Vector3 hit = ProjectToCameraPlane(screenPos, center, node.FaceForward);
            Vector3 rel = hit - center;
            Vector2 ext = node.FaceHalfExtents;
            float fx = ext.x > 1e-5f ? Vector3.Dot(rel, node.FaceRight) / (ext.x * 2f) : 0f;
            float fy = ext.y > 1e-5f ? Vector3.Dot(rel, node.FaceUp) / (ext.y * 2f) : 0f;
            return new Vector2(Mathf.Clamp(fx, -0.5f, 0.5f), Mathf.Clamp(fy, -0.5f, 0.5f));
        }

        private static float DistPointToSegment(Vector2 p, Vector2 a, Vector2 b)
        {
            Vector2 ab = b - a;
            float len2 = ab.sqrMagnitude;
            float t = len2 < 1e-6f ? 0f : Mathf.Clamp01(Vector2.Dot(p - a, ab) / len2);
            return Vector2.Distance(p, a + ab * t);
        }

        private static (bool dashed, EndMarker src, EndMarker tgt, string stereo) EdgeVisual(EdgeKind k) => k switch
        {
            // Plain association = a line with multiplicities, no arrowhead (conventional class-diagram default).
            EdgeKind.Association => (false, EndMarker.None, EndMarker.None, null),
            EdgeKind.Dependency => (true, EndMarker.None, EndMarker.OpenArrow, null),
            EdgeKind.Generalization => (false, EndMarker.None, EndMarker.HollowTriangle, null),
            EdgeKind.Realization => (true, EndMarker.None, EndMarker.HollowTriangle, null),
            EdgeKind.Aggregation => (false, EndMarker.HollowDiamond, EndMarker.None, null),
            EdgeKind.Composition => (false, EndMarker.FilledDiamond, EndMarker.None, null),
            // Behavioral / cross-diagram connectors — the directional "flow" arrows.
            EdgeKind.Transition => (false, EndMarker.None, EndMarker.OpenArrow, null),
            EdgeKind.DirectedAssociation => (false, EndMarker.None, EndMarker.OpenArrow, null),
            EdgeKind.Include => (true, EndMarker.None, EndMarker.OpenArrow, "«include»"),
            EdgeKind.Extend => (true, EndMarker.None, EndMarker.OpenArrow, "«extend»"),
            EdgeKind.NoteLink => (true, EndMarker.None, EndMarker.None, null),
            // Sequence / communication messages: sync = filled head, async = open stick, reply = dashed stick.
            EdgeKind.MessageSync => (false, EndMarker.None, EndMarker.OpenArrow, null),
            EdgeKind.MessageAsync => (false, EndMarker.None, EndMarker.StickArrow, null),
            EdgeKind.MessageReply => (true, EndMarker.None, EndMarker.StickArrow, null),
            // Profile extension: solid line, filled triangle pointing at the metaclass.
            EdgeKind.Extension => (false, EndMarker.None, EndMarker.OpenArrow, "«extension»"),
            // Usage: dashed line, open arrow at the consumed target, «consumes» stereotype.
            EdgeKind.Consumes => (true, EndMarker.None, EndMarker.OpenArrow, "«consumes»"),
            // Whiteboard sketch connector: lightweight freeform arrow without UML stereotype baggage.
            EdgeKind.SketchConnector => (false, EndMarker.None, EndMarker.StickArrow, null),
            EdgeKind.SysmlSatisfy => (true, EndMarker.None, EndMarker.OpenArrow, "«satisfy»"),
            EdgeKind.SysmlVerify => (true, EndMarker.None, EndMarker.OpenArrow, "«verify»"),
            EdgeKind.SysmlDeriveReqt => (true, EndMarker.None, EndMarker.OpenArrow, "«deriveReqt»"),
            EdgeKind.SysmlRefine => (true, EndMarker.None, EndMarker.OpenArrow, "«refine»"),
            EdgeKind.SysmlBinding => (false, EndMarker.None, EndMarker.None, null),
            EdgeKind.SysmlItemFlow => (false, EndMarker.None, EndMarker.OpenArrow, "«itemFlow»"),
            EdgeKind.BpmnSequenceFlow => (false, EndMarker.None, EndMarker.OpenArrow, null),
            EdgeKind.BpmnMessageFlow => (true, EndMarker.None, EndMarker.OpenArrow, null),
            EdgeKind.DmnRequirement => (false, EndMarker.None, EndMarker.OpenArrow, null),
            EdgeKind.ArchiRelationship => (false, EndMarker.None, EndMarker.OpenArrow, null),
            _ => (false, EndMarker.None, EndMarker.OpenArrow, null),
        };

        /// <summary>A friendly name for the link-type / re-type pickers (the bare enum reads poorly).</summary>
        private static string EdgeDisplay(EdgeKind k) => k switch
        {
            EdgeKind.Transition => "Transition  (flow →)",
            EdgeKind.DirectedAssociation => "Directed association  (→)",
            EdgeKind.Include => "«include»",
            EdgeKind.Extend => "«extend»",
            EdgeKind.NoteLink => "Note anchor  (comment)",
            EdgeKind.MessageSync => "Message — sync  (▶)",
            EdgeKind.MessageAsync => "Message — async  (>)",
            EdgeKind.MessageReply => "Reply / return  (⇠)",
            EdgeKind.Extension => "«extension»",
            EdgeKind.Consumes => "«consumes»  (uses →)",
            EdgeKind.SketchConnector => "Sketch connector  (whiteboard →)",
            EdgeKind.SysmlSatisfy => "SysML «satisfy»",
            EdgeKind.SysmlVerify => "SysML «verify»",
            EdgeKind.SysmlDeriveReqt => "SysML «deriveReqt»",
            EdgeKind.SysmlRefine => "SysML «refine»",
            EdgeKind.SysmlBinding => "SysML binding",
            EdgeKind.SysmlItemFlow => "SysML item flow",
            EdgeKind.BpmnSequenceFlow => "BPMN sequence flow",
            EdgeKind.BpmnMessageFlow => "BPMN message flow",
            EdgeKind.DmnRequirement => "DMN requirement",
            EdgeKind.ArchiRelationship => "ArchiMate relationship",
            _ => k.ToString(),
        };

        /// <summary>
        /// The valid relationship kinds for a pair of endpoints, ordered so the most appropriate one is first
        /// (so a state pair defaults to a Transition arrow, two use cases to «include», a note to a comment
        /// anchor, etc.) — this is what stops new links from defaulting to a directionless line.
        /// </summary>
        private List<EdgeKind> OrderedEdgeKindsFor(ElementId from, ElementId to)
        {
            _model.TryGet(from, out var f);
            _model.TryGet(to, out var t);
            var order = new List<EdgeKind>();
            void Add(EdgeKind k)
            {
                if (!order.Contains(k) && EdgeRules.CanConnect(_model, k, from, to).IsValid) order.Add(k);
            }

            bool note = (f != null && f.Kind == ElementKind.Note) || (t != null && t.Kind == ElementKind.Note);
            bool bothUseCase = f != null && t != null
                && f.Kind == ElementKind.UseCase && t.Kind == ElementKind.UseCase;
            bool behavioral = f != null && t != null
                && KindInfo.IsBehavioral(f.Kind) && KindInfo.IsBehavioral(t.Kind);
            bool messaging = f != null && t != null && IsInteractionNode(f.Kind) && IsInteractionNode(t.Kind);
            bool extension = f != null && t != null
                && f.Kind == ElementKind.Stereotype && t.Kind == ElementKind.Metaclass;
            bool whiteboard = f != null && t != null
                && (KindInfo.IsWhiteboardNode(f.Kind) || f.Kind == ElementKind.WhiteboardFrame)
                && (KindInfo.IsWhiteboardNode(t.Kind) || t.Kind == ElementKind.WhiteboardFrame);
            bool sysml = f != null && t != null && IsSysmlNode(f.Kind) && IsSysmlNode(t.Kind);
            bool bpmn = f != null && t != null && IsBpmnNode(f.Kind) && IsBpmnNode(t.Kind);
            bool dmn = f != null && t != null && IsDmnNode(f.Kind) && IsDmnNode(t.Kind);
            bool archi = f != null && t != null && IsArchiNode(f.Kind) && IsArchiNode(t.Kind);

            if (note) { Add(EdgeKind.NoteLink); Add(EdgeKind.Dependency); }
            if (whiteboard) Add(EdgeKind.SketchConnector);
            if (sysml)
            {
                Add(EdgeKind.SysmlSatisfy); Add(EdgeKind.SysmlVerify); Add(EdgeKind.SysmlDeriveReqt);
                Add(EdgeKind.SysmlRefine); Add(EdgeKind.SysmlBinding); Add(EdgeKind.SysmlItemFlow);
            }
            if (bpmn) { Add(EdgeKind.BpmnSequenceFlow); Add(EdgeKind.BpmnMessageFlow); }
            if (dmn) Add(EdgeKind.DmnRequirement);
            if (archi) Add(EdgeKind.ArchiRelationship);
            if (bothUseCase) { Add(EdgeKind.Include); Add(EdgeKind.Extend); Add(EdgeKind.Generalization); }
            if (behavioral) Add(EdgeKind.Transition);
            if (messaging) { Add(EdgeKind.MessageSync); Add(EdgeKind.MessageAsync); Add(EdgeKind.MessageReply); }
            if (extension) Add(EdgeKind.Extension);

            // Conventional fallback order for everything else.
            foreach (var k in new[]
            {
                EdgeKind.Association, EdgeKind.DirectedAssociation, EdgeKind.Transition, EdgeKind.Dependency,
                EdgeKind.Consumes, EdgeKind.SketchConnector,
                EdgeKind.SysmlSatisfy, EdgeKind.SysmlVerify, EdgeKind.SysmlDeriveReqt, EdgeKind.SysmlRefine,
                EdgeKind.SysmlBinding, EdgeKind.SysmlItemFlow,
                EdgeKind.BpmnSequenceFlow, EdgeKind.BpmnMessageFlow, EdgeKind.DmnRequirement,
                EdgeKind.ArchiRelationship,
                EdgeKind.Generalization, EdgeKind.Realization, EdgeKind.Aggregation, EdgeKind.Composition,
                EdgeKind.Include, EdgeKind.Extend, EdgeKind.NoteLink,
                EdgeKind.MessageSync, EdgeKind.MessageAsync, EdgeKind.MessageReply, EdgeKind.Extension,
            }) Add(k);
            return order;
        }

        private static bool IsSysmlNode(ElementKind k) => k switch
        {
            ElementKind.SysmlBlock or ElementKind.SysmlValueType or ElementKind.SysmlConstraintBlock
                or ElementKind.SysmlRequirement or ElementKind.SysmlProxyPort or ElementKind.SysmlFullPort
                or ElementKind.SysmlParameter => true,
            _ => false,
        };

        private static bool IsBpmnNode(ElementKind k) => k switch
        {
            ElementKind.BpmnEvent or ElementKind.BpmnActivity or ElementKind.BpmnGateway
                or ElementKind.BpmnDataObject or ElementKind.BpmnDataStore or ElementKind.BpmnPool
                or ElementKind.BpmnLane or ElementKind.BpmnChoreographyTask or ElementKind.BpmnConversation => true,
            _ => false,
        };

        private static bool IsDmnNode(ElementKind k) => k switch
        {
            ElementKind.DmnDecision or ElementKind.DmnInputData or ElementKind.DmnBusinessKnowledge
                or ElementKind.DmnKnowledgeSource or ElementKind.DmnDecisionService or ElementKind.DmnTextAnnotation => true,
            _ => false,
        };

        private static bool IsArchiNode(ElementKind k) => k switch
        {
            ElementKind.ArchiBusinessActor or ElementKind.ArchiBusinessProcess
                or ElementKind.ArchiApplicationComponent or ElementKind.ArchiApplicationService
                or ElementKind.ArchiDataObject or ElementKind.ArchiNode or ElementKind.ArchiDevice
                or ElementKind.ArchiSystemSoftware or ElementKind.ArchiTechnologyService
                or ElementKind.ArchiCapability or ElementKind.ArchiOutcome or ElementKind.ArchiRequirement
                or ElementKind.ArchiPrinciple or ElementKind.ArchiWorkPackage or ElementKind.ArchiDeliverable
                or ElementKind.ArchiPlateau or ElementKind.ArchiGap => true,
            _ => false,
        };

        // --- orthogonal routing ---

        /// <summary>The orthogonal polyline for an edge: pinned endpoints + user bends if any, else an auto Z-route.</summary>
        private List<Vector2> RouteEdge(ElementId from, ElementId to, EdgeId edge)
        {
            // Sequence / communication messages are horizontal arrows between the participants' centre lines,
            // stacked at their assigned vertical level (set by auto-arrange, else the lower of the two nodes).
            if (_edgeKinds.TryGetValue(edge, out var ek) && IsMessage(ek))
                return SequenceRoute(from, to, edge);

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

        /// <summary>A horizontal message arrow between two participants at the message's vertical level (self = loop).</summary>
        private List<Vector2> SequenceRoute(ElementId from, ElementId to, EdgeId edge)
        {
            var f = _nodes[from]; var t = _nodes[to];
            float xf = f.Rt.anchoredPosition.x, xt = t.Rt.anchoredPosition.x;
            float y = _msgLevel.TryGetValue(edge, out var lv)
                ? lv
                : Mathf.Min(f.Rt.anchoredPosition.y, t.Rt.anchoredPosition.y) - 10f;

            if (Mathf.Abs(xf - xt) < 3f)
            {
                // Self-message: a small rectangular loop hanging off the right of the life line.
                float x = xf;
                return new List<Vector2>
                {
                    new Vector2(x, y), new Vector2(x + 56f, y),
                    new Vector2(x + 56f, y - 24f), new Vector2(x, y - 24f),
                };
            }
            return new List<Vector2> { new Vector2(xf, y), new Vector2(xt, y) };
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
            if (e.button == PointerEventData.InputButton.Right) { ShowEdgeMenu(view.Edge, e.position); return; }
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
            _msgLevel.Remove(edge);
            _msgNumber.Remove(edge);
            _edgeKinds.Remove(edge);
            if (_selectedEdge == edge) _selectedEdge = EdgeId.None;
            // 3-D route-edit state for this link (waypoints + endpoint face attachments).
            _waypoints3d.Remove(edge);
            _srcFace.Remove(edge);
            _tgtFace.Remove(edge);
        }

        private void RefreshBendHandles()
        {
            foreach (var h in _bendHandles) if (h != null) Destroy(h.gameObject);
            _bendHandles.Clear();
            if (!_selectedEdge.IsValid || !TryGetEdgeEndpoints(_selectedEdge, out var from, out var to)) return;
            if (!_nodes.ContainsKey(from) || !_nodes.ContainsKey(to)) return;
            // Messages are auto-laid-out horizontally — no endpoint/bend handles to drag.
            if (_edgeKinds.TryGetValue(_selectedEdge, out var sk) && IsMessage(sk)) return;

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
                ElementKind.DataType => "«dataType»",
                ElementKind.PrimitiveType => "«primitive»",
                ElementKind.Component => "«component»",
                ElementKind.Artifact => "«artifact»",
                ElementKind.Metaclass => "«metaclass»",
                ElementKind.Stereotype => "«stereotype»",
                _ => null,
            };
        }

        // --- tabs ---

        /// <summary>The single chokepoint for changing the active diagram/page: sets <c>_activePackage</c> and keeps the
        /// placement store's active scope in sync, so per-diagram geometry always reads/writes the right diagram.</summary>
        private void SetActivePackage(ElementId id)
        {
            _activePackage = id;
            _placements.Active = id;
        }

        private void EnsureActivePackage()
        {
            if (_activePackage.IsValid && _model.Contains(_activePackage)) { _placements.Active = _activePackage; return; }
            SetActivePackage(ElementId.None);
            // Prefer a top-level package (a tab/diagram) so the bar always has a selected tab on bootstrap.
            foreach (var el in _model.Elements)
                if (el.Kind == ElementKind.Package && !el.Parent.IsValid) { SetActivePackage(el.Id); break; }
            if (_activePackage.IsValid) return;
            foreach (var el in _model.Elements)
                if (el.Kind == ElementKind.Package) { SetActivePackage(el.Id); break; }
        }

        private void FixActiveAfterChange()
        {
            if (!_activePackage.IsValid || !_model.Contains(_activePackage)) SetActivePackage(ElementId.None);
        }

        /// <summary>
        /// One tab per <b>top-level</b> package (a diagram). A package nested inside another package is a
        /// <b>page</b> of its diagram, reached through that tab's ▾ dropdown rather than a tab of its own. The
        /// active tab is the top-level ancestor of whatever page/diagram is currently open.
        /// </summary>
        private void BuildTabBar()
        {
            for (int i = _tabBar.childCount - 1; i >= 0; i--) Destroy(_tabBar.GetChild(i).gameObject);

            var activeRoot = TopLevelOf(_activePackage);
            float x = 8f;
            foreach (var el in _model.Elements)
            {
                if (el.Kind != ElementKind.Package || el.Parent.IsValid) continue; // top-level only
                var pkgId = el.Id;
                bool active = pkgId == activeRoot;
                bool hasPages = HasPages(pkgId);
                MakeTab(el.Name, x, 150f, active, hasPages,
                    () => GoToPackage(pkgId),
                    () => ShowPagesMenu(pkgId));
                x += 154f;
            }
            MakeTab("+", x, 40f, false, false,
                () => PromptAndAdd(ElementId.None, ElementKind.Package, new Vector2(Screen.width * 0.5f, Screen.height * 0.5f)),
                null);
        }

        /// <summary>The top-level package (tab) that owns <paramref name="id"/> — i.e. walk parents to the root.</summary>
        private ElementId TopLevelOf(ElementId id)
        {
            var cur = id;
            int guard = 0;
            while (cur.IsValid && _model.TryGet(cur, out var e) && e.Parent.IsValid)
            {
                cur = e.Parent;
                if (++guard > 100_000) break;
            }
            return cur;
        }

        /// <summary>True if <paramref name="pkgId"/> has at least one nested package (a page).</summary>
        private bool HasPages(ElementId pkgId)
        {
            foreach (var el in _model.Elements)
                if (el.Kind == ElementKind.Package && el.Parent == pkgId) return true;
            return false;
        }

        /// <summary>The diagram (top-level tab) itself, then each of its nested packages, depth-first — for the dropdown.</summary>
        private void CollectPages(ElementId pkgId, int depth, List<(ElementId id, int depth)> into)
        {
            into.Add((pkgId, depth));
            foreach (var el in _model.Elements)
                if (el.Kind == ElementKind.Package && el.Parent == pkgId)
                    CollectPages(el.Id, depth + 1, into);
        }

        /// <summary>Dropdown listing a diagram and its pages; selecting one opens it.</summary>
        private void ShowPagesMenu(ElementId pkgId)
        {
            var pages = new List<(ElementId id, int depth)>();
            CollectPages(pkgId, 0, pages);

            var items = new List<MenuItem>();
            foreach (var (id, depth) in pages)
            {
                var target = id;
                string indent = new string(' ', depth * 3);
                string mark = id == _activePackage ? "• " : (depth == 0 ? "▸ " : "· ");
                items.Add(new MenuItem(indent + mark + PackageName(id), true, () => GoToPackage(target)));
            }
            items.Add(MenuItem.Separator());
            items.Add(new MenuItem("＋ Add page here…", true,
                () => { SetActivePackage(pkgId); AddPackageWithNode(new Vector2(Screen.width * 0.5f, Screen.height * 0.5f)); }));

            // Anchor the menu just under this tab's row.
            CreateMenu(new Vector2(8f, Screen.height - 40f), PackageName(pkgId) + "  ▾ pages", items);
        }

        private void MakeTab(string label, float x, float w, bool active, bool hasPages,
            System.Action onClick, System.Action onCaret)
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

            // The caret occupies the right end of the tab when the diagram has pages; clicking it opens the dropdown.
            float caretW = onCaret != null ? 22f : 0f;
            var t = MakeText(rt, label, new Vector2(10f, 0f), new Vector2(w - 14f - caretW, 30f), 16,
                active ? new Color(0.95f, 0.98f, 1f) : new Color(0.72f, 0.77f, 0.84f, 1f), TextAnchor.MiddleLeft);
            t.raycastTarget = false;

            if (onCaret != null)
            {
                var cgo = new GameObject("Caret", typeof(RectTransform));
                var crt = (RectTransform)cgo.transform;
                crt.SetParent(rt, false);
                crt.anchorMin = crt.anchorMax = new Vector2(0f, 0.5f);
                crt.pivot = new Vector2(0f, 0.5f);
                crt.sizeDelta = new Vector2(caretW, 30f);
                crt.anchoredPosition = new Vector2(w - caretW, 0f);
                var cImg = cgo.AddComponent<Image>();
                cImg.color = hasPages ? new Color(1f, 1f, 1f, 0.06f) : new Color(1f, 1f, 1f, 0f);
                var cBtn = cgo.AddComponent<Button>();
                cBtn.targetGraphic = cImg;
                cBtn.onClick.AddListener(() => onCaret());
                var ct = MakeText(crt, "▾", new Vector2(2f, 0f), new Vector2(caretW - 2f, 30f), 14,
                    hasPages ? new Color(0.9f, 0.94f, 1f, 1f) : new Color(0.55f, 0.6f, 0.68f, 0.7f), TextAnchor.MiddleCenter);
                ct.raycastTarget = false;
            }
        }

        // --- helpers ---

        /// <summary>Single-select: replace the whole selection set with just <paramref name="id"/> (None ⇒ clear).</summary>
        private void SetSelected(ElementId id)
        {
            _selection.Clear();
            if (id.IsValid) _selection.Add(id);
            _selectedId = id;
            ClearRegionSelection();
            RefreshSelectionHighlights();
            RefreshInspector();
            _browseNav?.RefreshSelection(_selectedId);
        }

        /// <summary>Shift-click: add/remove a node from the multi-selection. The toggled node becomes primary.</summary>
        public void ToggleSelection(ElementId id)
        {
            CloseMenu();
            ClearSelectedEdge();
            if (!id.IsValid) return;
            if (!_selection.Remove(id))
            {
                _selection.Add(id);
                _selectedId = id;
            }
            else if (_selectedId == id)
            {
                // Removed the primary — promote any remaining member, else clear.
                _selectedId = ElementId.None;
                foreach (var sid in _selection) { _selectedId = sid; break; }
            }
            RefreshSelectionHighlights();
            RefreshInspector();
        }

        /// <summary>Replace the selection set wholesale (used by the marquee). Primary = the first valid id.</summary>
        public void SetSelection(IEnumerable<ElementId> ids)
        {
            _selection.Clear();
            _selectedId = ElementId.None;
            if (ids != null)
                foreach (var id in ids)
                    if (id.IsValid && _selection.Add(id) && !_selectedId.IsValid) _selectedId = id;
            RefreshSelectionHighlights();
            RefreshInspector();
        }

        public bool IsSelected(ElementId id) => _selection.Contains(id);

        /// <summary>A snapshot of the currently-selected element ids (read-only view).</summary>
        public IReadOnlyCollection<ElementId> SelectedIds => _selection;

        /// <summary>Re-apply the selection outline to every live 3-D node from the current selection set.</summary>
        private void RefreshSelectionHighlights()
        {
            if (_scene == null) return;
            foreach (var kv in _scene.Nodes)
                if (kv.Value != null) kv.Value.SetSelected(_selection.Contains(kv.Key));
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

        /// <summary>Project a screen point onto the active diagram plane (world z = 0) and convert to model pixels —
        /// used to place a new node where the pointer dropped it.</summary>
        private Vector2 ScreenToModelPx(Vector2 screenPos)
        {
            Vector3 world = ProjectToPlane(screenPos, 0f);
            return new Vector2(world.x / Uml3DConfig.WorldScale, world.y / Uml3DConfig.WorldScale);
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

            // The 3-D diagram scene lives on its own GameObject (not this overlay canvas). The overlay renders on
            // top of the scene camera, so every menu / dialog / palette draws above the slabs.
            var sceneGo = new GameObject("Uml3DScene");
            _scene = sceneGo.AddComponent<Uml3DScene>();
            _scene.Init();

            // The diagram backdrop is the 3-D scene camera's clear color now; the overlay's own background image is
            // kept only as a transparent, non-raycasting filler so the HUD has a root child. All diagram-area pointer
            // gestures (pick / select / orbit / dolly / pan / drag-move / empty-space menu) are arbitrated in Update
            // against the 3-D scene; clicks that land on real overlay UI are filtered via IsPointerOverGameObject.
            var bgGo = new GameObject("Background", typeof(RectTransform));
            var bgRt = (RectTransform)bgGo.transform;
            bgRt.SetParent(_root, false);
            Stretch(bgRt);
            var bgImg = bgGo.AddComponent<Image>();
            bgImg.color = new Color(0f, 0f, 0f, 0f);
            bgImg.raycastTarget = false;

            _edgeLayer = NewLayer("EdgeLayer");
            _nodeLayer = NewLayer("NodeLayer");
            _handleLayer = NewLayer("HandleLayer"); // bend handles, above boxes

            // In-app menu bar (File / Edit / Add / Generate / Layout / Export / Settings) — the tab bar sits below it.
            BuildMenuBar();

            // Tab bar (top strip, under the menu bar).
            var tabGo = new GameObject("TabBar", typeof(RectTransform));
            _tabBar = (RectTransform)tabGo.transform;
            _tabBar.SetParent(_root, false);
            _tabBar.anchorMin = new Vector2(0f, 1f); _tabBar.anchorMax = new Vector2(1f, 1f);
            _tabBar.pivot = new Vector2(0f, 1f);
            _tabBar.sizeDelta = new Vector2(0f, 38f);
            _tabBar.anchoredPosition = new Vector2(0f, -32f);
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
            hintRt.anchoredPosition = new Vector2(12f, -74f);
            _hint = hintGo.AddComponent<Text>();
            _hint.font = _font; _hint.fontSize = 17;
            _hint.color = new Color(0.34f, 0.38f, 0.45f, 1f);
            _hint.alignment = TextAnchor.MiddleLeft;
            _hint.supportRichText = false;
            _hint.raycastTarget = false;
            _hint.text = "Drag empty space → navigate (set mode top-right) · wheel → zoom · Alt+wheel → jump Z · Ctrl/Cmd+F → frame · " +
                         "2D switch → flat canvas / depth ignored · G+click box → center on it · click box → select · Shift-click → multi-select · Ctrl/Cmd-drag box → move · " +
                         "right-click box → edit element · right-click canvas → add / paste · " +
                         "Ctrl/Cmd C/V copy · Ctrl/Cmd S save · Ctrl/Cmd Z undo";

            // Help button (top-right): opens the controls / shortcuts reference.
            var helpGo = new GameObject("HelpButton", typeof(RectTransform));
            var helpRt = (RectTransform)helpGo.transform;
            helpRt.SetParent(_root, false);
            helpRt.anchorMin = helpRt.anchorMax = new Vector2(1f, 1f);
            helpRt.pivot = new Vector2(1f, 1f);
            helpRt.sizeDelta = new Vector2(64f, 28f);
            helpRt.anchoredPosition = new Vector2(-8f, -6f);
            var helpImg = helpGo.AddComponent<Image>();
            helpImg.color = new Color(0.20f, 0.42f, 0.52f, 1f);
            var helpBtn = helpGo.AddComponent<Button>();
            helpBtn.targetGraphic = helpImg;
            helpBtn.onClick.AddListener(() => ShowHelp());
            MakeText(helpRt, "? Help", new Vector2(0f, 0f), new Vector2(64f, 28f), 14,
                new Color(0.95f, 0.98f, 1f, 1f), TextAnchor.MiddleCenter).raycastTarget = false;

            // Camera controls (to the left of Help): manual location/direction form + a quick view reset.
            MakeHudButton("CameraButton", "Camera…", -78f, 84f, () => ShowCameraForm(Input.mousePosition));
            MakeHudButton("ResetViewButton", "⟲ Reset", -168f, 78f, () => CameraReset());
            Make2DModeSwitch(-254f);
            // Floating glyph toolbar: choose what an empty-space drag controls (orbit / pan / move along an axis).
            BuildNavBar();

            BuildPalette();
            BuildBrowseNav();
            BuildInspector();
        }

        /// <summary>A small top-right HUD button anchored from the right edge. Returns its caption Text.</summary>
        private Text MakeHudButton(string name, string label, float xFromRight, float width, System.Action onClick)
        {
            var go = new GameObject(name, typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(_root, false);
            rt.anchorMin = rt.anchorMax = new Vector2(1f, 1f);
            rt.pivot = new Vector2(1f, 1f);
            rt.sizeDelta = new Vector2(width, 28f);
            rt.anchoredPosition = new Vector2(xFromRight, -6f);
            var img = go.AddComponent<Image>();
            img.color = new Color(0.18f, 0.22f, 0.28f, 1f);
            var btn = go.AddComponent<Button>();
            btn.targetGraphic = img;
            btn.onClick.AddListener(() => onClick());
            var t = MakeText(rt, label, new Vector2(0f, 0f), new Vector2(width, 28f), 13,
                new Color(0.92f, 0.95f, 1f, 1f), TextAnchor.MiddleCenter);
            t.raycastTarget = false;
            return t;
        }

        private void Make2DModeSwitch(float xFromRight)
        {
            var go = new GameObject("Mode2DSwitch", typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(_root, false);
            rt.anchorMin = rt.anchorMax = new Vector2(1f, 1f);
            rt.pivot = new Vector2(1f, 1f);
            rt.sizeDelta = new Vector2(78f, 28f);
            rt.anchoredPosition = new Vector2(xFromRight, -6f);
            _mode2DButtonBg = go.AddComponent<Image>();
            var btn = go.AddComponent<Button>();
            btn.targetGraphic = _mode2DButtonBg;
            btn.onClick.AddListener(Toggle2DMode);
            _mode2DButtonText = MakeText(rt, "", new Vector2(0f, 0f), new Vector2(78f, 28f), 13,
                new Color(0.92f, 0.95f, 1f, 1f), TextAnchor.MiddleCenter);
            _mode2DButtonText.raycastTarget = false;
            Refresh2DModeSwitch();
        }

        private void Toggle2DMode()
        {
            CloseMenu();
            _mode2D = !_mode2D;
            Refresh2DModeSwitch();
            if (_mode2D)
            {
                _navMode = NavMode.Pan;
                RefreshNavButtons();
            }
            RebuildFromModel();
            if (_mode2D) Apply2DModeCamera(true);
            Flash(_mode2D ? "2D mode: flat nodes, centered camera, depth ignored" : "3D mode: depth, orbit and node rotation enabled");
        }

        private void Refresh2DModeSwitch()
        {
            if (_mode2DButtonBg != null)
                _mode2DButtonBg.color = _mode2D
                    ? new Color(0.20f, 0.55f, 0.85f, 1f)
                    : new Color(0.18f, 0.22f, 0.28f, 1f);
            if (_mode2DButtonText != null) _mode2DButtonText.text = _mode2D ? "2D On" : "2D Off";
        }

        private void Apply2DModeCamera(bool frame)
        {
            var rig = _scene != null ? _scene.Rig : null;
            if (rig == null) return;
            rig.Yaw = 0f;
            rig.Pitch = 0f;
            rig.Roll = 0f;
            if (frame) _scene.FrameAll();
            rig.Pivot = new Vector3(rig.Pivot.x, rig.Pivot.y, 0f);
            rig.Yaw = 0f;
            rig.Pitch = 0f;
            rig.Roll = 0f;
            rig.RefreshNow();
        }

        /// <summary>Reset the camera to the default angles and frame the whole diagram.</summary>
        private void CameraReset()
        {
            var rig = _scene != null ? _scene.Rig : null;
            if (_mode2D) Apply2DModeCamera(true);
            else
            {
                if (rig != null) { rig.Yaw = 0f; rig.Pitch = 18f; rig.Roll = 0f; }
                _scene?.FrameAll();
                rig?.RefreshNow();
            }
            Flash("camera reset");
        }

        /// <summary>Fixed world-space distance the camera sits from a node when centered (G+click) — independent of
        /// the node's size, so every focus settles at the same comfortable, predictable zoom.</summary>
        private const float FocusDistance = 8f;

        /// <summary>
        /// Center the camera on a node: pivot on its center, orient the rig so it looks straight at the node's front
        /// (+Z content) face — honoring any per-node rotation — and back off a fixed, legibility-fitted distance so
        /// the whole face is framed. Bound to G + click.
        /// </summary>
        private void FocusOnNode(ElementId id)
        {
            var rig = _scene != null ? _scene.Rig : null;
            if (rig == null || !_scene.TryGetNode(id, out var node) || node == null) return;

            if (_mode2D)
            {
                rig.Pivot = node.transform.position;
                rig.Distance = Mathf.Clamp(FocusDistance, UmlCameraRig.MinDistance, UmlCameraRig.MaxDistance);
                Apply2DModeCamera(false);
                SetSelected(id);
                Flash("centered on node (2D)");
                return;
            }

            // The rig sits at Pivot + Orientation()*(0,0,Distance) looking back at the pivot, so to view the node's
            // front face the rig's local +Z must equal the face's outward normal. Solve yaw/pitch for that normal.
            Vector3 d = node.FaceForward.normalized;
            rig.Pivot = node.transform.position;
            rig.Yaw = Mathf.Atan2(d.x, d.z) * Mathf.Rad2Deg;
            rig.Pitch = Mathf.Clamp(-Mathf.Asin(Mathf.Clamp(d.y, -1f, 1f)) * Mathf.Rad2Deg,
                UmlCameraRig.MinPitch, UmlCameraRig.MaxPitch);
            rig.Roll = 0f;

            // A fixed distance (not fitted to the node size) so every focus lands at the same predictable zoom.
            rig.Distance = Mathf.Clamp(FocusDistance, UmlCameraRig.MinDistance, UmlCameraRig.MaxDistance);

            SetSelected(id);
            Flash("centered on node (G+click)");
        }

        private static float ParseFloat(InputField f, float fallback) =>
            f != null && float.TryParse(f.text, out var v) ? v : fallback;

        /// <summary>Manual camera location / direction form: edit the orbit pivot, yaw/pitch/roll and distance.</summary>
        private void ShowCameraForm(Vector2 screenPos)
        {
            CloseMenu();
            var rig = _scene != null ? _scene.Rig : null;
            if (rig == null) { Flash("camera not ready"); return; }

            const float w = 384f, h = 318f;
            var panel = BeginModal(w, h, "Camera   —   location / direction");
            float y = -50f;

            FormLabel(panel, "Look-at point (pivot)   X / Y / Z", ref y, w);
            var px = MakeInput(panel, new Vector2(16f, y), 110f, rig.Pivot.x.ToString("0.###"), "x");
            var py = MakeInput(panel, new Vector2(134f, y), 110f, rig.Pivot.y.ToString("0.###"), "y");
            var pz = MakeInput(panel, new Vector2(252f, y), 110f, rig.Pivot.z.ToString("0.###"), "z");
            y -= 52f;

            FormLabel(panel, "View angles   Yaw / Pitch / Roll   (degrees)", ref y, w);
            var yaw = MakeInput(panel, new Vector2(16f, y), 110f, rig.Yaw.ToString("0.##"), "yaw");
            var pitch = MakeInput(panel, new Vector2(134f, y), 110f, rig.Pitch.ToString("0.##"), "pitch");
            var roll = MakeInput(panel, new Vector2(252f, y), 110f, rig.Roll.ToString("0.##"), "roll");
            y -= 52f;

            FormLabel(panel, "Distance from pivot", ref y, w);
            var dist = MakeInput(panel, new Vector2(16f, y), 160f, rig.Distance.ToString("0.###"), "distance");
            y -= 52f;

            void Apply()
            {
                rig.Pivot = new Vector3(ParseFloat(px, rig.Pivot.x), ParseFloat(py, rig.Pivot.y), ParseFloat(pz, rig.Pivot.z));
                rig.Yaw = ParseFloat(yaw, rig.Yaw);
                rig.Pitch = Mathf.Clamp(ParseFloat(pitch, rig.Pitch), UmlCameraRig.MinPitch, UmlCameraRig.MaxPitch);
                rig.Roll = ParseFloat(roll, rig.Roll);
                rig.Distance = Mathf.Clamp(ParseFloat(dist, rig.Distance), UmlCameraRig.MinDistance, UmlCameraRig.MaxDistance);
                if (_mode2D) Apply2DModeCamera(false);
                else rig.RefreshNow();
                Flash("camera updated");
            }

            float yBtn = -(h - 46f);
            MakeButton(panel, "Reset view", new Vector2(16f, yBtn), new Vector2(110f, 34f),
                new Color(0.40f, 0.30f, 0.16f, 1f), () => { CameraReset(); CloseMenu(); });
            MakeButton(panel, "Apply", new Vector2(w - 198f, yBtn), new Vector2(84f, 34f),
                new Color(0.20f, 0.42f, 0.52f, 1f), Apply); // applies live; leaves the form open to keep tweaking
            MakeButton(panel, "Close", new Vector2(w - 104f, yBtn), new Vector2(88f, 34f),
                new Color(0.22f, 0.24f, 0.29f, 1f), CloseMenu);
        }

        /// <summary>The controls / shortcuts reference, opened from the Help button.</summary>
        private void ShowHelp()
        {
            CloseMenu();
            const float w = 680f, h = 612f;
            var panel = BeginModal(w, h, "Controls & Shortcuts");
            string body = string.Join("\n", new[]
            {
                "CAMERA  (full 6 degrees of freedom)",
                "   2D switch (top-right) ....... flat front view; depth, orbit, roll and node rotation are ignored",
                "   Drag empty space ............ orbit  (pitch / yaw)",
                "   Ctrl/Cmd + drag empty ....... pan",
                "   Mouse wheel ................. zoom  (dolly in / out)",
                "   Q / E ....................... roll left / right",
                "   W / A / S / D ............... fly  forward / left / back / right",
                "   R / F ....................... fly  up / down",
                "   Ctrl/Cmd + F ................ frame the whole diagram",
                "   Alt + mouse wheel ........... jump the view a fixed step along Z",
                "   Navigate bar (top-right) .... icon chips set what an empty-space drag does (orbit · pan · X · Y · Z)",
                "   N  /  Shift+N ............... cycle that drag mode forward / back",
                "   G + click a node ............ center the camera on it, facing its front",
                "",
                "NODES",
                "   Click ....................... select        Shift + click = add / remove",
                "   Shift + drag empty space .... marquee multi-select",
                "   Drag a node ................. draw a relationship (connect-by-drag)",
                "   Ctrl/Cmd + drag ............. move  (in the layer plane)",
                "   Ctrl/Cmd + Shift + drag ..... move along Z  (depth; disabled in 2D mode)",
                "   Double-click ................ open the edit modal (fields · operations · properties)",
                "   Ctrl/Cmd + click ............ toggle resize handles → drag one (corner=all · side=width X · top=height Y · center=depth Z)",
                "   Alt + drag .................. rotate  (pitch / yaw) in place; disabled in 2D mode",
                "   Ctrl/Cmd + Z / Y ............ undo / redo a move or resize too",
                "   Right-click ................. menu: edit, style, generate code, depth (Z), delete",
                "",
                "REGION CUBES  (boundary / frame / profile — a dotted cube grouping the nodes inside)",
                "   Click a cube edge ........... select        Double-click = colour / opacity        Right-click = menu",
                "   Ctrl/Cmd + click an edge .... toggle resize handles (corners = all · sides = width/height)",
                "   Ctrl/Cmd + drag an edge ..... move the region + its members",
                "",
                "LINKS / ARROWS",
                "   Click a link ................ select        Right-click = link menu",
                "   Link menu ................... re-type, multiplicity / label, curved / straight, delete",
                "   Drag green mid-handle ....... add a break point",
                "   Drag yellow handle .......... move a break point      Alt + click = delete it",
                "   Drag orange end-handle ...... move the attachment point on a node",
                "",
                "EDIT  /  FILE",
                "   Ctrl/Cmd + C / V ............ copy / paste      Ctrl/Cmd + Z / Y = undo / redo",
                "   Ctrl/Cmd + S ................ save     Ctrl/Cmd+Shift+S = save as…     Ctrl/Cmd+O = open file…",
                "   Delete ...................... delete selection",
                "   Right-click canvas .......... add · paste · import code · LLM settings · arrange",
            });
            MakeText(panel, body, new Vector2(22f, -44f), new Vector2(w - 44f, h - 104f), 14,
                new Color(0.84f, 0.89f, 0.96f, 1f), TextAnchor.UpperLeft);
            float yBtn = -(h - 46f);
            MakeButton(panel, "Close", new Vector2(w - 104f, yBtn), new Vector2(88f, 34f),
                new Color(0.22f, 0.24f, 0.29f, 1f), CloseMenu);
        }

        // --- toolbar palette UI ---

        private const float PaletteWidth = 168f;
        private const float CollapsedSidebarWidth = 28f;

        private RectTransform _palette;
        private RectTransform _paletteBody;
        private RectTransform _paletteContent;
        private Text _paletteToggleText;
        private readonly HashSet<string> _paletteCollapsed = new();
        private string _paletteSearch = "";
        private bool _paletteDefaultsCollapsed;
        private bool _paletteSidebarCollapsed;

        private float PaletteActiveWidth => _paletteSidebarCollapsed ? CollapsedSidebarWidth : PaletteWidth;

        private static (string title, (ElementKind kind, string label)[] items)[] PaletteSections() => new[]
        {
            ("Class", new[]
            {
                (ElementKind.Class, "Class"), (ElementKind.Interface, "Interface"),
                (ElementKind.Enum, "Enum"), (ElementKind.Struct, "Struct"),
                (ElementKind.DataType, "Data Type"), (ElementKind.PrimitiveType, "Primitive"),
                (ElementKind.Package, "Package"), (ElementKind.Note, "Note"),
            }),
            ("Object", new[] { (ElementKind.ObjectInstance, "Object") }),

            // --- additional software-development graph types, ordered most-useful → least ---
            ("Data Model (ERD)", new[]
            {
                (ElementKind.EntityTable, "Table / Entity"), (ElementKind.Note, "Note"),
            }),
            ("C4 Model", new[]
            {
                (ElementKind.Person, "Person"), (ElementKind.SoftwareSystem, "Software System"),
                (ElementKind.Container, "Container"), (ElementKind.Component, "Component"),
            }),
            ("Flowchart", new[]
            {
                (ElementKind.FlowTerminator, "Start / End"), (ElementKind.FlowProcess, "Process"),
                (ElementKind.Decision, "◇ Decision"), (ElementKind.FlowIO, "Input / Output"),
                (ElementKind.FlowDocument, "Document"),
            }),
            ("Data Flow (DFD)", new[]
            {
                (ElementKind.FlowProcess, "Process"), (ElementKind.DataStore, "Data Store"),
                (ElementKind.ExternalEntity, "External Entity"),
            }),
            ("Infrastructure", new[]
            {
                (ElementKind.Server, "Server / Host"), (ElementKind.Database, "Database"),
                (ElementKind.Cloud, "Cloud / Service"), (ElementKind.Client, "Client / Device"),
                (ElementKind.Firewall, "Firewall"),
            }),
            ("Mind Map", new[] { (ElementKind.MindNode, "Topic") }),
            ("Whiteboard", new[]
            {
                (ElementKind.WhiteboardFrame, "Frame"),
                (ElementKind.WhiteboardSticky, "Sticky Note"),
                (ElementKind.WhiteboardCard, "Card"),
                (ElementKind.WhiteboardText, "Text"),
                (ElementKind.WhiteboardCircle, "Circle / Bubble"),
                (ElementKind.WhiteboardDiamond, "Diamond"),
                (ElementKind.WhiteboardTriangle, "Triangle"),
                (ElementKind.WhiteboardRectangle, "Rectangle"),
                (ElementKind.WhiteboardCube, "Cube"),
                (ElementKind.WhiteboardSphere, "Sphere"),
                (ElementKind.WhiteboardCylinder, "Cylinder"),
                (ElementKind.WhiteboardDecahedron, "Decahedron"),
                (ElementKind.WhiteboardBlob, "Blob"),
                (ElementKind.Cloud, "Cloud"),
                (ElementKind.AsyncSend, "Async Send"),
                (ElementKind.AsyncReceive, "Async Receive"),
                (ElementKind.Note, "UML Note"),
                (ElementKind.Actor, "Actor"),
            }),
            ("Wireframe / UI", new[]
            {
                (ElementKind.Screen, "Screen"), (ElementKind.Panel, "Panel"),
                (ElementKind.Button, "Button"), (ElementKind.Label, "Label"), (ElementKind.Link, "Link"),
                (ElementKind.TextField, "Text Field"), (ElementKind.TextArea, "Text Area"),
                (ElementKind.Password, "Password"), (ElementKind.Checkbox, "Checkbox"),
                (ElementKind.Radio, "Radio"), (ElementKind.Dropdown, "Dropdown"),
                (ElementKind.List, "List"), (ElementKind.Table, "Table"), (ElementKind.Tree, "Tree"),
                (ElementKind.Image, "Image"), (ElementKind.Tabs, "Tabs"), (ElementKind.Menu, "Menu"),
                (ElementKind.Toolbar, "Toolbar"), (ElementKind.Breadcrumb, "Breadcrumb"),
                (ElementKind.Card, "Card"), (ElementKind.Separator, "Separator"),
                (ElementKind.Progress, "Progress"), (ElementKind.Slider, "Slider"),
                (ElementKind.UiWidget, "Widget (generic)"),
            }),
            ("Project (Gantt / Kanban)", new[]
            {
                (ElementKind.Task, "Task"), (ElementKind.KanbanColumn, "Column"),
            }),

            ("SysML", new[]
            {
                (ElementKind.SysmlBlock, "Block"), (ElementKind.SysmlValueType, "Value Type"),
                (ElementKind.SysmlConstraintBlock, "Constraint Block"), (ElementKind.SysmlRequirement, "Requirement"),
                (ElementKind.SysmlProxyPort, "Proxy Port"), (ElementKind.SysmlFullPort, "Full Port"),
                (ElementKind.SysmlParameter, "Parameter"), (ElementKind.Activity, "Activity"),
                (ElementKind.State, "State"), (ElementKind.UseCase, "Use Case"),
            }),
            ("BPMN", new[]
            {
                (ElementKind.BpmnPool, "Pool"), (ElementKind.BpmnLane, "Lane"),
                (ElementKind.BpmnEvent, "Event"), (ElementKind.BpmnActivity, "Activity"),
                (ElementKind.BpmnGateway, "Gateway"), (ElementKind.BpmnDataObject, "Data Object"),
                (ElementKind.BpmnDataStore, "Data Store"),
                (ElementKind.BpmnChoreographyTask, "Choreography"),
                (ElementKind.BpmnConversation, "Conversation"),
            }),
            ("DMN", new[]
            {
                (ElementKind.DmnDecision, "Decision"), (ElementKind.DmnInputData, "Input Data"),
                (ElementKind.DmnBusinessKnowledge, "Business Knowledge"),
                (ElementKind.DmnKnowledgeSource, "Knowledge Source"),
                (ElementKind.DmnDecisionService, "Decision Service"),
                (ElementKind.DmnTextAnnotation, "Annotation"),
            }),
            ("ArchiMate", new[]
            {
                (ElementKind.ArchiBusinessActor, "Business Actor"),
                (ElementKind.ArchiBusinessProcess, "Business Process"),
                (ElementKind.ArchiApplicationComponent, "App Component"),
                (ElementKind.ArchiApplicationService, "App Service"),
                (ElementKind.ArchiDataObject, "Data Object"),
                (ElementKind.ArchiNode, "Node"), (ElementKind.ArchiDevice, "Device"),
                (ElementKind.ArchiSystemSoftware, "System Software"),
                (ElementKind.ArchiTechnologyService, "Tech Service"),
                (ElementKind.ArchiCapability, "Capability"), (ElementKind.ArchiOutcome, "Outcome"),
                (ElementKind.ArchiRequirement, "Requirement"), (ElementKind.ArchiPrinciple, "Principle"),
                (ElementKind.ArchiWorkPackage, "Work Package"),
                (ElementKind.ArchiDeliverable, "Deliverable"),
                (ElementKind.ArchiPlateau, "Plateau"), (ElementKind.ArchiGap, "Gap"),
            }),
            ("Business Strategy", new[]
            {
                (ElementKind.BusinessCapability, "Capability"),
                (ElementKind.ValueStream, "Value Stream"),
                (ElementKind.ValueChainActivity, "Value Chain"),
                (ElementKind.StrategyObjective, "Objective"),
                (ElementKind.BalancedScorecardPerspective, "Scorecard Perspective"),
                (ElementKind.OrgUnit, "Org Unit"), (ElementKind.HeatMapItem, "Heat Map Item"),
                (ElementKind.DecisionTreeNode, "Decision Tree Node"),
            }),
            ("Enterprise Frameworks", new[]
            {
                (ElementKind.UafOperationalNode, "UAF Operational Node"),
                (ElementKind.UafService, "UAF Service"), (ElementKind.UafResource, "UAF Resource"),
                (ElementKind.UafCapability, "UAF Capability"),
                (ElementKind.TogafArchitectureBuildingBlock, "TOGAF ABB"),
                (ElementKind.TogafArchitecturePhase, "TOGAF ADM Phase"),
                (ElementKind.ZachmanCell, "Zachman Cell"),
            }),

            ("Use Case", new[]
            {
                (ElementKind.Actor, "Actor"), (ElementKind.UseCase, "Use Case"),
                (ElementKind.Boundary, "System Boundary"),
            }),
            ("State Machine", new[]
            {
                (ElementKind.StateStart, "● Initial"), (ElementKind.State, "State"),
                (ElementKind.Decision, "◇ Decision"), (ElementKind.ForkJoin, "▬ Fork / Join"),
                (ElementKind.AsyncSend, "Send Signal"), (ElementKind.AsyncReceive, "Receive Event"),
                (ElementKind.Junction, "• Junction"), (ElementKind.History, "Ⓗ History"),
                (ElementKind.Terminate, "✕ Terminate"), (ElementKind.StateEnd, "◉ Final"),
            }),
            ("Activity", new[]
            {
                (ElementKind.StateStart, "● Initial"), (ElementKind.Activity, "Action"),
                (ElementKind.CallActivity, "Activity"), (ElementKind.Decision, "◇ Decision / Merge"),
                (ElementKind.AsyncSend, "Send Signal"), (ElementKind.AsyncReceive, "Receive Event"),
                (ElementKind.ForkJoin, "▬ Fork / Join"), (ElementKind.FlowFinal, "⊗ Flow Final"),
                (ElementKind.StateEnd, "◉ Activity Final"),
            }),
            ("Component", new[]
            {
                (ElementKind.Component, "Component"), (ElementKind.Interface, "Interface"),
            }),
            ("Deployment", new[]
            {
                (ElementKind.DeploymentNode, "Node / Device"), (ElementKind.Artifact, "Artifact"),
                (ElementKind.Component, "Component"),
            }),
            ("Package", new[]
            {
                (ElementKind.PackageNode, "Package"), (ElementKind.Note, "Note"),
            }),
            ("Composite Structure", new[]
            {
                (ElementKind.Part, "Part"), (ElementKind.Port, "Port"),
                (ElementKind.Collaboration, "Collaboration"), (ElementKind.Interface, "Interface"),
            }),
            ("Sequence", new[]
            {
                (ElementKind.Lifeline, "Lifeline"), (ElementKind.Activation, "Activation"),
                (ElementKind.Actor, "Actor"), (ElementKind.Frame, "Fragment (alt/opt/loop)"),
            }),
            ("Communication", new[]
            {
                (ElementKind.ObjectInstance, "Object"), (ElementKind.Actor, "Actor"),
                (ElementKind.Frame, "Frame"),
            }),
            ("Interaction Overview", new[]
            {
                (ElementKind.StateStart, "● Initial"), (ElementKind.Frame, "Interaction Frame"),
                (ElementKind.Decision, "◇ Decision"), (ElementKind.ForkJoin, "▬ Fork / Join"),
                (ElementKind.AsyncSend, "Send Signal"), (ElementKind.AsyncReceive, "Receive Event"),
                (ElementKind.StateEnd, "◉ Final"),
            }),
            ("Profile", new[]
            {
                (ElementKind.Metaclass, "Metaclass"), (ElementKind.Stereotype, "Stereotype"),
                (ElementKind.Profile, "Profile"),
            }),
            ("Timing", new[] { (ElementKind.TimingLifeline, "Timing Lifeline") }),
        };

        private void BuildPalette()
        {
            const float width = PaletteWidth;
            const float searchH = 30f;

            // Container pinned to the left edge. A fixed search box sits at the top; the diagram-family sections
            // scroll below it. Sections are collapsed by default (the long family list stays compact) — type in
            // the search box, or click a ▸ header, to reveal kinds.
            var container = new GameObject("Palette", typeof(RectTransform));
            _palette = (RectTransform)container.transform;
            _palette.SetParent(_root, false);
            _palette.anchorMin = new Vector2(0f, 0f); _palette.anchorMax = new Vector2(0f, 1f);
            _palette.pivot = new Vector2(0f, 1f);
            _palette.offsetMin = new Vector2(0f, 8f);      // left = 0, bottom = 8
            _palette.offsetMax = new Vector2(width, -70f); // right = width, top = -70 (clears the tabs + hint line)
            container.AddComponent<Image>().color = new Color(0.12f, 0.13f, 0.16f, 0.97f);

            var bodyGo = new GameObject("Body", typeof(RectTransform));
            _paletteBody = (RectTransform)bodyGo.transform;
            _paletteBody.SetParent(_palette, false);
            _paletteBody.anchorMin = Vector2.zero; _paletteBody.anchorMax = Vector2.one;
            _paletteBody.offsetMin = Vector2.zero; _paletteBody.offsetMax = Vector2.zero;

            // Fixed search/filter box at the very top (not part of the scrolled content).
            var search = MakeInput(_paletteBody, new Vector2(6f, -6f), width - 12f, _paletteSearch, "search nodes…");
            ((RectTransform)search.transform).sizeDelta = new Vector2(width - 12f, searchH);
            search.onValueChanged.AddListener(v => { _paletteSearch = v ?? ""; RebuildPaletteContent(); });

            // Scrolling viewport below the search box; it masks the content.
            var viewport = new GameObject("Viewport", typeof(RectTransform));
            var vrt = (RectTransform)viewport.transform;
            vrt.SetParent(_paletteBody, false);
            vrt.anchorMin = new Vector2(0f, 0f); vrt.anchorMax = new Vector2(1f, 1f);
            vrt.pivot = new Vector2(0f, 1f);
            vrt.offsetMin = Vector2.zero;
            vrt.offsetMax = new Vector2(0f, -(searchH + 10f)); // clear the search box
            viewport.AddComponent<RectMask2D>();

            var scroll = container.AddComponent<ScrollRect>();
            scroll.horizontal = false; scroll.vertical = true;
            scroll.movementType = ScrollRect.MovementType.Clamped;
            scroll.scrollSensitivity = 26f;

            var content = new GameObject("Content", typeof(RectTransform));
            _paletteContent = (RectTransform)content.transform;
            _paletteContent.SetParent(vrt, false);
            _paletteContent.anchorMin = new Vector2(0f, 1f); _paletteContent.anchorMax = new Vector2(1f, 1f);
            _paletteContent.pivot = new Vector2(0.5f, 1f);
            _paletteContent.anchoredPosition = Vector2.zero;
            scroll.viewport = vrt;
            scroll.content = _paletteContent;

            // Collapse every section by default except the most-used "Class" group (done once).
            if (!_paletteDefaultsCollapsed)
            {
                foreach (var sec in PaletteSections())
                    if (sec.title != "Class") _paletteCollapsed.Add(sec.title);
                _paletteDefaultsCollapsed = true;
            }

            BuildPaletteToggle();
            ApplyPaletteCollapse();
            RebuildPaletteContent();
        }

        private void BuildPaletteToggle()
        {
            var go = new GameObject("PaletteCollapse", typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(_palette, false);
            rt.anchorMin = rt.anchorMax = new Vector2(1f, 1f);
            rt.pivot = new Vector2(1f, 1f);
            rt.sizeDelta = new Vector2(CollapsedSidebarWidth, 44f);
            rt.anchoredPosition = Vector2.zero;
            var img = go.AddComponent<Image>();
            img.color = new Color(0.18f, 0.22f, 0.28f, 1f);
            var btn = go.AddComponent<Button>();
            btn.targetGraphic = img;
            btn.onClick.AddListener(() =>
            {
                _paletteSidebarCollapsed = !_paletteSidebarCollapsed;
                ApplyPaletteCollapse();
                Flash(_paletteSidebarCollapsed ? "left toolbar collapsed" : "left toolbar expanded");
            });
            _paletteToggleText = MakeText(rt, "", Vector2.zero, rt.sizeDelta, 18,
                new Color(0.92f, 0.95f, 1f, 1f), TextAnchor.MiddleCenter);
            _paletteToggleText.raycastTarget = false;
        }

        private void ApplyPaletteCollapse()
        {
            if (_palette == null) return;
            _palette.offsetMax = new Vector2(PaletteActiveWidth, -70f);
            if (_paletteBody != null) _paletteBody.gameObject.SetActive(!_paletteSidebarCollapsed);
            if (_paletteToggleText != null) _paletteToggleText.text = _paletteSidebarCollapsed ? ">" : "<";
        }

        /// <summary>(Re)populate the palette body, honoring each section's collapsed state.</summary>
        private void RebuildPaletteContent()
        {
            if (_paletteContent == null) return;
            for (int i = _paletteContent.childCount - 1; i >= 0; i--) Destroy(_paletteContent.GetChild(i).gameObject);

            const float width = PaletteWidth;
            float y = -8f;

            string q = (_paletteSearch ?? "").Trim();
            if (q.Length > 0)
            {
                // Active filter: flat list of every matching kind across all sections (ignores collapse), so a
                // search always finds a node. Matches on the item label, the kind name, or the section title.
                var seen = new HashSet<string>();
                int matches = 0;
                foreach (var sec in PaletteSections())
                    foreach (var it in sec.items)
                    {
                        bool hit = it.label.IndexOf(q, System.StringComparison.OrdinalIgnoreCase) >= 0
                                   || it.kind.ToString().IndexOf(q, System.StringComparison.OrdinalIgnoreCase) >= 0
                                   || sec.title.IndexOf(q, System.StringComparison.OrdinalIgnoreCase) >= 0;
                        if (!hit) continue;
                        if (!seen.Add(it.kind + "|" + it.label)) continue; // dedupe kinds listed in several sections
                        MakePaletteItem(_paletteContent, it.kind, it.label, y, width - 16f); y -= 26f;
                        matches++;
                    }
                if (matches == 0)
                {
                    MakeText(_paletteContent, "no nodes match", new Vector2(8f, y), new Vector2(width - 16f, 22f),
                        13, new Color(0.55f, 0.60f, 0.68f, 1f), TextAnchor.MiddleLeft).raycastTarget = false;
                    y -= 26f;
                }
                _paletteContent.sizeDelta = new Vector2(0f, -y + 4f);
                return;
            }

            foreach (var sec in PaletteSections())
            {
                bool collapsed = _paletteCollapsed.Contains(sec.title);
                MakePaletteHeader(_paletteContent, sec.title, collapsed, y, width - 12f);
                y -= 22f;
                if (!collapsed)
                    foreach (var it in sec.items) { MakePaletteItem(_paletteContent, it.kind, it.label, y, width - 16f); y -= 26f; }
                y -= 6f;
            }
            _paletteContent.sizeDelta = new Vector2(0f, -y + 4f);
        }

        private void MakePaletteHeader(RectTransform parent, string title, bool collapsed, float y, float width)
        {
            var go = new GameObject("Header:" + title, typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0f, 1f);
            rt.pivot = new Vector2(0f, 1f);
            rt.sizeDelta = new Vector2(width, 20f);
            rt.anchoredPosition = new Vector2(6f, y);
            var img = go.AddComponent<Image>();
            img.color = new Color(0.17f, 0.19f, 0.24f, 1f);
            var btn = go.AddComponent<Button>();
            btn.targetGraphic = img;
            btn.onClick.AddListener(() =>
            {
                if (!_paletteCollapsed.Remove(title)) _paletteCollapsed.Add(title);
                RebuildPaletteContent();
            });
            var t = MakeText(rt, (collapsed ? "▸  " : "▾  ") + title.ToUpper(), new Vector2(6f, 0f),
                new Vector2(width - 10f, 20f), 12, new Color(0.62f, 0.69f, 0.79f, 1f), TextAnchor.MiddleLeft);
            t.fontStyle = FontStyle.Bold; t.raycastTarget = false;
        }

        private void MakePaletteItem(RectTransform parent, ElementKind kind, string label, float y, float width)
        {
            var go = new GameObject("Item:" + label, typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0f, 1f);
            rt.pivot = new Vector2(0f, 1f);
            rt.sizeDelta = new Vector2(width, 23f);
            rt.anchoredPosition = new Vector2(6f, y);
            go.AddComponent<Image>().color = new Color(0.20f, 0.23f, 0.28f, 1f);
            var item = go.AddComponent<UmlPaletteItem>();
            item.Canvas = this; item.Kind = kind; item.Label = label;
            MakeText(rt, label, new Vector2(8f, 0f), new Vector2(width - 12f, 23f), 14,
                new Color(0.90f, 0.93f, 0.98f, 1f), TextAnchor.MiddleLeft);
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
            const float w = 280f, ih = 32f, sh = 10f, hh = 26f, pad = 6f;
            float bodyH = 0f;
            foreach (var item in items) bodyH += item.IsSeparator ? sh : ih;
            float h = hh + pad + bodyH + pad;
            var go = NewPanel("Menu", screenPos, new Vector2(w, h), new Color(0.12f, 0.14f, 0.17f, 0.98f));
            var rt = (RectTransform)go.transform;
            _menu = go;

            var head = MakeText(rt, header, new Vector2(10f, -4f), new Vector2(w - 20f, hh), 15,
                new Color(0.55f, 0.61f, 0.71f, 1f), TextAnchor.MiddleLeft);
            head.fontStyle = FontStyle.Bold;

            float y = -(hh + pad);
            foreach (var item in items)
            {
                if (item.IsSeparator)
                {
                    MakeMenuSeparator(rt, new Vector2(10f, y - sh * 0.5f), w - 20f);
                    y -= sh;
                    continue;
                }
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
            rt.anchoredPosition = ClampPanelTopLeft(new Vector2(screenPos.x, screenPos.y) / ScaleFactor, size);
            go.AddComponent<Image>().color = color;
            return go;
        }

        private Vector2 ClampPanelTopLeft(Vector2 topLeft, Vector2 size)
        {
            const float margin = 8f;
            float canvasW = Screen.width / ScaleFactor;
            float canvasH = Screen.height / ScaleFactor;
            if (_root != null && _root.rect.width > 1f && _root.rect.height > 1f)
            {
                canvasW = _root.rect.width;
                canvasH = _root.rect.height;
            }

            float minX = margin;
            float maxX = Mathf.Max(margin, canvasW - size.x - margin);
            float minY = size.y + margin;
            float maxY = canvasH - margin;
            if (minY > maxY) minY = maxY = Mathf.Max(margin, canvasH - margin);

            return new Vector2(Mathf.Clamp(topLeft.x, minX, maxX), Mathf.Clamp(topLeft.y, minY, maxY));
        }

        private void MakeMenuSeparator(RectTransform parent, Vector2 topLeft, float width)
        {
            var go = new GameObject("Separator", typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0f, 1f);
            rt.pivot = new Vector2(0f, 0.5f);
            rt.sizeDelta = new Vector2(width, 1f);
            rt.anchoredPosition = topLeft;
            go.AddComponent<Image>().color = new Color(0.28f, 0.31f, 0.38f, 1f);
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

    /// <summary>
    /// Full-canvas backdrop: empty-space clicks (add menu / deselect). A plain drag rubber-band-selects nodes;
    /// a Ctrl/Cmd-drag pans the diagram instead. The mode is latched at drag-start so a modifier released
    /// mid-drag doesn't switch gestures.
    /// </summary>
    public sealed class UmlBackground : MonoBehaviour,
        IPointerClickHandler, IBeginDragHandler, IDragHandler, IEndDragHandler
    {
        public UmlCanvas Canvas;
        private bool _panning; // latched at OnBeginDrag: true ⇒ pan, false ⇒ marquee

        public void OnPointerClick(PointerEventData eventData) => Canvas.OnBackgroundClick(eventData);

        public void OnBeginDrag(PointerEventData e)
        {
            _panning = UmlCanvas.CtrlOrCmd();
            if (_panning) Canvas.BeginPan();
            else Canvas.BeginMarquee(e.position);
        }

        public void OnDrag(PointerEventData e)
        {
            if (_panning) Canvas.PanBy(e.delta);
            else Canvas.UpdateMarquee(e.position);
        }

        public void OnEndDrag(PointerEventData e)
        {
            if (!_panning) Canvas.EndMarquee(e.position);
        }
    }

    /// <summary>Dim modal backdrop behind a property/member dialog: a click on the dim area cancels the dialog.</summary>
    /// <summary>
    /// The dim backdrop behind a modal property dialog. It exists only to BLOCK pointer events from reaching the
    /// canvas/nodes underneath — it intentionally does NOT dismiss the dialog on click. Property dialogs close
    /// only via their explicit OK / Cancel buttons (a stray click outside must not discard in-progress edits).
    /// </summary>
    public sealed class UmlModalBackdrop : MonoBehaviour, IPointerClickHandler
    {
        public UmlCanvas Canvas;
        // Swallow the click (so it doesn't fall through to the diagram) without closing the dialog.
        public void OnPointerClick(PointerEventData eventData) { }
    }

    /// <summary>A toolbar palette entry: drag it onto the canvas to drop a new node of its kind.</summary>
    // Palette items insert ONLY via drag-and-drop onto the canvas — a plain click does nothing (no
    // IPointerClickHandler), so clicking a kind in the rail never spawns a node at screen center.
    public sealed class UmlPaletteItem : MonoBehaviour,
        IBeginDragHandler, IDragHandler, IEndDragHandler
    {
        public UmlCanvas Canvas;
        public ElementKind Kind;
        public string Label;

        public void OnBeginDrag(PointerEventData e) => Canvas.BeginPaletteDrag(Kind, Label);
        public void OnDrag(PointerEventData e) => Canvas.UpdatePaletteDrag(e.position);
        public void OnEndDrag(PointerEventData e) => Canvas.EndPaletteDrag(e.position);
    }
}
