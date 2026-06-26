using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Uml3D
{
    /// <summary>
    /// A real 3-D UML node: a procedurally-built box slab (a 12-triangle cuboid) whose front (+Z) face carries a
    /// world-space uGUI canvas reproducing the classifier compartments — stereotype, bold name, an attributes
    /// block, a divider, then an operations block — a faithful-enough port of <c>UmlNodeView</c>'s layout. The
    /// slab is lit (URP/Lit, with Standard and unlit fallbacks) and tinted with the node fill color; a
    /// <see cref="BoxCollider"/> matching the slab makes it pickable via <see cref="Physics"/> raycasts.
    ///
    /// The integration layer drives it imperatively: <see cref="Init"/> to build, <see cref="SetWorldPose"/> to
    /// place it on its layer, <see cref="AddLocalRotation"/> to spin the individual node, <see cref="SetSelected"/>
    /// for the selection highlight, and <see cref="SetDepthTint"/> to gray out below-layer nodes. A
    /// collider hit maps back to this component via <c>GetComponentInParent&lt;UmlNode3D&gt;</c>.
    /// </summary>
    public sealed class UmlNode3D : MonoBehaviour
    {
        /// <summary>The model element this node renders. Mirrors <c>UmlNodeView.Id</c>.</summary>
        public ElementId Id;

        /// <summary>The local (per-node) rotation applied on top of the world pose set by the layer.</summary>
        public Quaternion LocalRotation { get; private set; } = Quaternion.identity;

        private Transform _slab;            // the lit box mesh + collider (rotates with LocalRotation)
        private MeshRenderer _slabRenderer;
        private Material _slabMaterial;     // runtime instance; tinted for fill / depth / selection
        private BoxCollider _collider;
        private GameObject _outline;        // inverted-hull silhouette border (always-on, in a darker fill tone)
        private Material _outlineMaterial;
        private GameObject _robot;          // for Actor/Person: the multi-part colored robot (replaces the slab mesh)
        private IReadOnlyList<Renderer> _robotRenderers; // the robot's per-part fill renderers (for depth/selection tint)
        private IReadOnlyList<Color> _robotBaseColors;   // the colors those parts were built with (re-tinted from base)
        private Color[] _robotBaseEmission;              // each part's as-built emission (so the selection lift adds on top)
        private Canvas _faceCanvas;         // world-space content on the +Z face
        private RectTransform _faceRt;      // the face canvas's RectTransform (image card attaches here)
        private CanvasGroup _faceGroup;     // alpha fades with depth tint
        private Texture2D _faceImage;       // optional per-node picture rendered as a card on the face
        private GameObject _selectionBox;   // wireframe-ish highlight border, toggled on selection

        private Vector3 _basePos = Vector3.zero;   // world pose set by the layer (before LocalRotation)
        private Quaternion _baseRot = Quaternion.identity;

        private Color _fill = Color.white;          // resting slab tint
        private Color _text = new Color(0.13f, 0.15f, 0.19f, 1f);
        private float _localPitch, _localYaw;       // accumulated per-node rotation (degrees)
        private float _depthT;                      // 0 = active/full-color, 1 = fully grayed (below layer)

        // World-space half-extents of the slab's +Z face, retained from Init/Resize so edges can attach to a point
        // on the face (see FacePointLocal). x = half-width, y = half-height (already × Uml3DConfig.WorldScale).
        private float _faceHalfW, _faceHalfH;

        // Build inputs retained so Resize can rebuild the mesh + face at a new size.
        private string _name, _stereotype;
        private ElementKind _kind;
        private List<string> _attrs, _ops;
        private float _depth;
        private Vector2 _sizePx;   // last pixel size, retained so SetThickness can rebuild at the current footprint

        private const float RowH = 18f;             // matches UmlNodeView's compartment row height (px)
        private const float HeaderH = 30f;
        private const int NameSize = 18;
        private const int MemberSize = 15;
        private static Font _font;

        /// <summary>
        /// Build the slab, face content and collider. <paramref name="sizePx"/> is the node's UI-pixel size
        /// (as the flat renderer computed it); it is scaled by <see cref="Uml3DConfig.WorldScale"/> for the mesh.
        /// </summary>
        public void Init(ElementId id, string name, string stereotype, ElementKind kind, Color fill, Color text,
            List<string> attributes, List<string> operations, Vector2 sizePx)
        {
            Id = id;
            _fill = fill;
            _text = text;
            _name = name; _stereotype = stereotype; _kind = kind; _attrs = attributes; _ops = operations;

            float w = Mathf.Max(20f, sizePx.x) * Uml3DConfig.WorldScale;
            float h = Mathf.Max(14f, sizePx.y) * Uml3DConfig.WorldScale;
            float d = Uml3DConfig.NodeThickness;
            _depth = d;
            _sizePx = sizePx;
            _faceHalfW = w * 0.5f; _faceHalfH = h * 0.5f;

            // The slab is a child so per-node LocalRotation can spin it (plus its face + collider) while the
            // node GameObject itself stays at the layer's world pose.
            var slabGo = new GameObject("Slab");
            _slab = slabGo.transform;
            _slab.SetParent(transform, false);

            var mf = slabGo.AddComponent<MeshFilter>();
            _slabRenderer = slabGo.AddComponent<MeshRenderer>();
            _slabMaterial = CreateMaterial(fill);
            _slabRenderer.sharedMaterial = _slabMaterial;

            _collider = slabGo.AddComponent<BoxCollider>();
            _collider.size = new Vector3(w, h, d);
            _collider.center = Vector3.zero;

            BuildBody(mf, w, h, d);
            BuildFace(name, stereotype, kind, sizePx, w, h, d, attributes, operations);
            BuildSelectionBox(w, h, d);
        }

        /// <summary>
        /// Populate the slab's visual: most kinds get the single tinted shape mesh (+ a silhouette border); the
        /// actor / person get a multi-part colored ROBOT built by <see cref="Uml3DRobot"/> instead (so the plain
        /// slab renderer is hidden and the shape mesh left empty — the collider/cage/face still use w×h×d).
        /// </summary>
        private void BuildBody(MeshFilter mf, float w, float h, float d)
        {
            if (_robot != null) { Destroy(_robot); _robot = null; }
            _robotRenderers = null;
            _robotBaseColors = null;
            _robotBaseEmission = null;
            bool robot = _kind == ElementKind.Actor || _kind == ElementKind.Person;
            if (robot)
            {
                mf.sharedMesh = new Mesh { name = "RobotPlaceholder" };
                _slabRenderer.enabled = false;
                if (_outline != null) { Destroy(_outline); _outline = null; }
                var handle = Uml3DRobot.Build(_slab, w, h, d, _fill);
                _robot = handle.Root;
                _robotRenderers = handle.Parts;
                _robotBaseColors = handle.BaseColors;
                // Capture each part's as-built emission so the selection lift adds onto (not replaces) glowing parts.
                _robotBaseEmission = new Color[_robotRenderers.Count];
                for (int i = 0; i < _robotRenderers.Count; i++)
                {
                    var pm = _robotRenderers[i] != null ? _robotRenderers[i].sharedMaterial : null;
                    _robotBaseEmission[i] = (pm != null && pm.HasProperty(EmissionColorId))
                        ? pm.GetColor(EmissionColorId) : Color.black;
                }
                ApplyTint(); // seed the robot parts with the current depth gray / selection state
            }
            else
            {
                _slabRenderer.enabled = true;
                mf.sharedMesh = Uml3DNodeShape.Build(_kind, w, h, d);
                BuildOutline(mf.sharedMesh, w, h);
            }
        }

        // --- public API for the integration layer ---

        /// <summary>The slab transform whose +Z face carries the content. Falls back to this node's transform if the
        /// slab hasn't been built yet (so the face accessors are safe to call at any time).</summary>
        private Transform FaceTransform => _slab != null ? _slab : transform;

        /// <summary>World-space right axis of the +Z content face (accounts for the per-node local rotation).</summary>
        public Vector3 FaceRight => FaceTransform.right;

        /// <summary>World-space up axis of the +Z content face (accounts for the per-node local rotation).</summary>
        public Vector3 FaceUp => FaceTransform.up;

        /// <summary>World-space outward normal of the +Z content face (the face the camera reads).</summary>
        public Vector3 FaceForward => FaceTransform.forward;

        /// <summary>World half-extents of the slab's +Z face (x = half-width, y = half-height).</summary>
        public Vector2 FaceHalfExtents => new Vector2(_faceHalfW, _faceHalfH);

        /// <summary>The slab's current Z thickness (world units).</summary>
        public float CurrentDepth => _depth;

        /// <summary>Set the slab's Z thickness (world units) and rebuild the mesh / collider / face at the current size.</summary>
        public void SetThickness(float worldDepth)
        {
            _depth = Mathf.Max(0.02f, worldDepth);
            Resize(_sizePx); // rebuilds the box mesh + collider + face + selection cage using the new _depth
        }

        /// <summary>
        /// Map a normalized face offset (each axis in roughly [-0.5,0.5]; (0,0) = face center) to a world point sitting
        /// just in front of the +Z face. Used to attach a link endpoint to a draggable spot on the node face. The
        /// offset is clamped to the face so an endpoint can never drift off the slab.
        /// </summary>
        public Vector3 FacePointLocal(Vector2 norm)
        {
            float fx = Mathf.Clamp(norm.x, -0.5f, 0.5f);
            float fy = Mathf.Clamp(norm.y, -0.5f, 0.5f);
            Vector3 center = transform.position;
            // Seat a hair in front of the face (matching the content canvas inset) so the attachment reads as on the
            // front surface rather than buried in the slab.
            return center
                + FaceRight * (fx * (_faceHalfW * 2f))
                + FaceUp * (fy * (_faceHalfH * 2f))
                + FaceForward * (_depth * 0.5f);
        }

        /// <summary>Place this node at its layer's world pose; <see cref="LocalRotation"/> is applied on top.</summary>
        public void SetWorldPose(Vector3 pos, Quaternion rot)
        {
            _basePos = pos;
            _baseRot = rot;
            transform.SetPositionAndRotation(pos, rot);
        }

        /// <summary>
        /// Rebuild the slab mesh, collider and face content at a new pixel size (interactive resize). Preserves
        /// the current selection, depth tint and per-node rotation.
        /// </summary>
        public void Resize(Vector2 sizePx)
        {
            _sizePx = sizePx;
            float w = Mathf.Max(20f, sizePx.x) * Uml3DConfig.WorldScale;
            float h = Mathf.Max(14f, sizePx.y) * Uml3DConfig.WorldScale;
            float d = _depth;
            _faceHalfW = w * 0.5f; _faceHalfH = h * 0.5f;

            if (_slab != null)
            {
                var mf = _slab.GetComponent<MeshFilter>();
                if (mf != null) BuildBody(mf, w, h, d);
            }
            if (_collider != null) _collider.size = new Vector3(w, h, d);

            if (_faceCanvas != null) Destroy(_faceCanvas.gameObject);
            if (_selectionBox != null) Destroy(_selectionBox);
            BuildFace(_name, _stereotype, _kind, sizePx, w, h, d, _attrs, _ops);
            BuildSelectionBox(w, h, d);

            if (_selectionBox != null) _selectionBox.SetActive(_selected);
            if (_faceGroup != null) _faceGroup.alpha = Mathf.Lerp(1f, 0.35f, _depthT);
            _faceImageCard = null; // the old card was destroyed with the rebuilt face canvas
            ApplyFaceImage();      // re-attach the picture (if any) to the freshly rebuilt face
        }

        /// <summary>Accumulate a per-node spin (degrees) about the node's local right (pitch) and up (yaw) axes.</summary>
        public void AddLocalRotation(float dPitch, float dYaw)
        {
            _localPitch += dPitch;
            _localYaw += dYaw;
            LocalRotation = Quaternion.Euler(_localPitch, _localYaw, 0f);
            if (_slab != null) _slab.localRotation = LocalRotation;
        }

        /// <summary>Set the per-node spin directly (used to restore orientation on rebuild / paste).</summary>
        public void SetLocalRotation(Quaternion q)
        {
            var e = q.eulerAngles;
            _localPitch = e.x;
            _localYaw = e.y;
            LocalRotation = q;
            if (_slab != null) _slab.localRotation = q;
        }

        /// <summary>
        /// Attach (or replace) a picture rendered as a card on the +Z face. The image fills the face with a small
        /// inset and occupies the top portion, leaving the bold name visible as a caption beneath it. No-op for
        /// marker kinds that carry no face canvas. Robust to being called any time after <see cref="BuildFace"/>;
        /// the card is re-applied automatically across <see cref="Resize"/> rebuilds.
        /// </summary>
        public void SetImage(Texture2D tex)
        {
            _faceImage = tex;
            ApplyFaceImage();
        }

        // The card host (a child of the face canvas), kept so it can be replaced/cleared without a full rebuild.
        private GameObject _faceImageCard;

        private void ApplyFaceImage()
        {
            if (_faceImageCard != null) { Destroy(_faceImageCard); _faceImageCard = null; }
            if (_faceImage == null || _faceRt == null) return; // no picture, or a marker kind with no face canvas

            float pxW = _faceRt.sizeDelta.x, pxH = _faceRt.sizeDelta.y;
            // Reserve a caption band at the bottom for the node name; the picture occupies the top ~82% of the face.
            const float inset = 4f;
            float captionH = Mathf.Clamp(pxH * 0.18f, 16f, 40f);
            float imgW = Mathf.Max(1f, pxW - inset * 2f);
            float imgH = Mathf.Max(1f, pxH - captionH - inset * 2f);

            var go = new GameObject("FaceImage", typeof(RectTransform));
            _faceImageCard = go;
            var rt = (RectTransform)go.transform;
            rt.SetParent(_faceRt, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0.5f, 0.5f);
            rt.pivot = new Vector2(0.5f, 0.5f);
            rt.sizeDelta = new Vector2(imgW, imgH);
            // Center vertically within the area above the caption band (top of face minus half the caption).
            rt.anchoredPosition = new Vector2(0f, captionH * 0.5f);
            var raw = go.AddComponent<RawImage>();
            raw.texture = _faceImage;
            raw.raycastTarget = false;
            // Draw above the fill/border panel but below the text rows (the bold name caption stays readable).
            // The name Row was added after the panel, so place the card just behind it by ordering it right after
            // the panel siblings; using SetAsFirstSibling()+offset keeps it over the panel yet under the labels.
            int idx = Mathf.Min(2, _faceRt.childCount - 1);
            rt.SetSiblingIndex(Mathf.Max(0, idx));
        }

        /// <summary>Toggle the selection highlight (a tinted border box around the slab plus an emissive lift).</summary>
        public void SetSelected(bool on)
        {
            _selected = on;
            if (_selectionBox != null) _selectionBox.SetActive(on);
            ApplyTint();
        }

        /// <summary>
        /// Depth graying for the bubble-view: <paramref name="t"/>=0 keeps full color (active layer); as t→1 the
        /// slab fades toward gray and the face content dims. Clamped to [0,1].
        /// </summary>
        public void SetDepthTint(float t)
        {
            _depthT = Mathf.Clamp01(t);
            ApplyTint();
            if (_faceGroup != null) _faceGroup.alpha = Mathf.Lerp(1f, 0.35f, _depthT);
        }

        private bool _selected;

        private void ApplyTint()
        {
            var gray = new Color(0.5f, 0.52f, 0.55f, 1f);
            Color lift = _selected ? new Color(0.10f, 0.32f, 0.50f, 1f) : Color.black;

            if (_slabMaterial != null)
            {
                Color c = Color.Lerp(_fill, gray, _depthT);
                _slabMaterial.color = c;
                if (_slabMaterial.HasProperty(BaseColorId)) _slabMaterial.SetColor(BaseColorId, c);
                // A subtle emissive lift when selected (works on Lit; harmless on Standard / ignored on unlit).
                if (_slabMaterial.HasProperty(EmissionColorId))
                    _slabMaterial.SetColor(EmissionColorId, lift);
            }

            // Actor / Person: also gray + highlight every robot part, recomputing from each part's stored base color
            // (and base emission) so repeated calls never compound. Parts with identical looks share one material
            // (per this node's Uml3DVector cache) so writing through the shared material here stays node-isolated.
            if (_robot != null && _robotRenderers != null && _robotBaseColors != null)
            {
                int n = Mathf.Min(_robotRenderers.Count, _robotBaseColors.Count);
                for (int i = 0; i < n; i++)
                {
                    var r = _robotRenderers[i];
                    var m = r != null ? r.sharedMaterial : null;
                    if (m == null) continue;
                    Color baseCol = _robotBaseColors[i];
                    Color c = Color.Lerp(baseCol, gray, _depthT);
                    c.a = baseCol.a; // preserve transparency
                    m.color = c;
                    if (m.HasProperty(BaseColorId)) m.SetColor(BaseColorId, c);
                    if (m.HasProperty(EmissionColorId))
                    {
                        Color baseEmis = (_robotBaseEmission != null && i < _robotBaseEmission.Length)
                            ? _robotBaseEmission[i] : Color.black;
                        m.SetColor(EmissionColorId, baseEmis + lift);
                    }
                }
            }
        }

        // --- mesh / material / face construction ---

        private static readonly int BaseColorId = Shader.PropertyToID("_BaseColor");
        private static readonly int EmissionColorId = Shader.PropertyToID("_EmissionColor");
        private static readonly int CullId = Shader.PropertyToID("_Cull");

        /// <summary>
        /// Build (or rebuild) the always-on silhouette border: a child carrying the same shape mesh, slightly
        /// inflated and rendered with FRONT-face culling in a darker tone of the fill, so only the back-faces peek
        /// out around the rim as a colored edge. Works for every kind (box, ovoid, cylinder, actor, …) without a
        /// per-shape outline path. Drawn just before opaque geometry so the node body covers the interior.
        /// </summary>
        private void BuildOutline(Mesh mesh, float w, float h)
        {
            if (_outline != null) Destroy(_outline);
            if (mesh == null) return;

            _outline = new GameObject("Outline");
            _outline.transform.SetParent(_slab, false);
            _outline.AddComponent<MeshFilter>().sharedMesh = mesh;
            var r = _outline.AddComponent<MeshRenderer>();
            r.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            r.receiveShadows = false;
            _outlineMaterial = CreateOutlineMaterial(BorderColor(_fill));
            r.sharedMaterial = _outlineMaterial;

            // A constant-ish world border (~0.025u) regardless of node size: scale by the larger span so wide
            // nodes don't get a runaway rim.
            float span = Mathf.Max(0.1f, Mathf.Max(w, h));
            _outline.transform.localScale = Vector3.one * (1f + 0.05f / span);
        }

        /// <summary>A darker tone of the node fill, used for the silhouette border so each kind keeps its hue.</summary>
        private static Color BorderColor(Color fill)
        {
            Color c = Color.Lerp(fill, Color.black, 0.55f);
            c.a = 1f;
            return c;
        }

        /// <summary>An unlit, front-culled material for the inverted-hull border (URP Unlit, plain Unlit fallback).</summary>
        private static Material CreateOutlineMaterial(Color color)
        {
            Shader sh = Shader.Find("Universal Render Pipeline/Unlit");
            if (sh == null) sh = Shader.Find("Unlit/Color");
            if (sh == null) sh = Shader.Find("Sprites/Default");
            var m = new Material(sh) { color = color };
            if (m.HasProperty(BaseColorId)) m.SetColor(BaseColorId, color);
            if (m.HasProperty(CullId)) m.SetFloat(CullId, 1f); // 1 = Front → render back faces only
            m.renderQueue = 1999;                              // just before opaque geometry (2000)
            return m;
        }

        /// <summary>Build a lit material, falling back through Standard then an unlit color shader if URP is absent.</summary>
        private static Material CreateMaterial(Color color)
        {
            Shader sh = Shader.Find("Universal Render Pipeline/Lit");
            if (sh == null) sh = Shader.Find("Standard");
            if (sh == null) sh = Shader.Find("Sprites/Default");
            Material m = sh != null ? new Material(sh) : new Material(Shader.Find("Unlit/Color"));
            m.color = color;
            if (m.HasProperty(BaseColorId)) m.SetColor(BaseColorId, color);
            return m;
        }

        /// <summary>
        /// A world-space canvas on the +Z face reproducing the compartment layout. The canvas uses the node's
        /// pixel size for its <c>sizeDelta</c> and is scaled by <see cref="Uml3DConfig.WorldScale"/> so its text
        /// lands exactly on the slab face; it sits a hair in front of the face to avoid z-fighting.
        /// </summary>
        private void BuildFace(string name, string stereotype, ElementKind kind, Vector2 sizePx,
            float w, float h, float d, List<string> attributes, List<string> operations)
        {
            if (_font == null) _font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");

            var style = Uml3DNodeShape.Face(kind);
            // Markers / control nodes (start, final, junction, fork, decision, flow-final, terminate, …) carry no
            // text — the silhouette is the meaning. Leave the face canvas unbuilt; everything that reads it is
            // null-guarded.
            if (style == Uml3DNodeShape.FaceStyle.None)
            {
                _faceCanvas = null;
                _faceGroup = null;
                _faceRt = null;
                return;
            }

            var faceGo = new GameObject("Face", typeof(RectTransform));
            var faceRt = (RectTransform)faceGo.transform;
            _faceRt = faceRt;
            faceRt.SetParent(_slab, false);
            _faceCanvas = faceGo.AddComponent<Canvas>();
            _faceCanvas.renderMode = RenderMode.WorldSpace;
            faceGo.AddComponent<GraphicRaycaster>().enabled = false; // picking is via the physics collider
            _faceGroup = faceGo.AddComponent<CanvasGroup>();
            _faceGroup.interactable = false;
            _faceGroup.blocksRaycasts = false;
            // Clip compartment content to the node face so long names/signatures don't spill past a small node.
            faceGo.AddComponent<RectMask2D>();

            float pxW = Mathf.Max(20f, sizePx.x), pxH = Mathf.Max(14f, sizePx.y);
            faceRt.sizeDelta = new Vector2(pxW, pxH);
            faceRt.pivot = new Vector2(0.5f, 0.5f);
            faceRt.localScale = Vector3.one * Uml3DConfig.WorldScale;
            // Just in front of the +Z face (nudged a hair further out so the opaque panel can't z-fight the slab).
            // Flipped 180° about Y so the canvas's READABLE side faces +Z (the camera): a uGUI world-space canvas
            // is legible from its −Z side, so an identity-rotated face shows its mirrored back to a +Z camera.
            // Shapes that bulge toward the camera (mind-node ovoid, database drum) seat the label on their dome.
            float faceFrontZ = kind switch
            {
                ElementKind.MindNode => Uml3DShape_MindNode.FrontPoleZ(w, h, d),
                ElementKind.Database => Uml3DShape_Cylinder.FrontPoleZ(w, h, d),
                _ => d * 0.5f,
            };
            faceRt.localPosition = new Vector3(0f, 0f, faceFrontZ + 0.004f);
            faceRt.localRotation = Quaternion.Euler(0f, 180f, 0f);

            // Wireframe widgets: draw the concrete UI control glyph (button, field, table, …) on an opaque card.
            // The glyph composes from lo-fi uGUI primitives; Field members become the widget's items (table columns,
            // list entries, …). The slab fill is the kind hue (or a styleguide theme color via ThemeApplier).
            if (style == Uml3DNodeShape.FaceStyle.WireframeWidget)
            {
                BuildFacePanel(faceRt, pxW, pxH);
                WireframeGlyph.Build(kind, name, attributes, faceRt,
                    WireframeGlyph.FromHue(_fill), _font);
                return;
            }

            if (style == Uml3DNodeShape.FaceStyle.EaNotation)
            {
                BuildEaNotationFace(faceRt, kind, name, stereotype, attributes, pxW, pxH);
                return;
            }

            // Non-rectangular silhouettes (use case, state, activity, actor, package, cloud, cylinder, note, …)
            // get a single centered label rather than a compartment card: a full-face opaque panel would poke
            // outside the shape's outline. The history pseudostate gets its circled-H glyph the same way.
            if (style != Uml3DNodeShape.FaceStyle.Compartments)
            {
                string label = style == Uml3DNodeShape.FaceStyle.GlyphH ? "H" : name;
                // The actor / person silhouette fills the face and reserves a band at the bottom for its name
                // (UML writes the actor's name beneath the figure), so anchor the label low for those kinds.
                bool nameAtBottom = kind == ElementKind.Actor || kind == ElementKind.Person;
                BuildLabelFace(faceRt, label,
                    style == Uml3DNodeShape.FaceStyle.GlyphH ? null : stereotype, pxW, pxH, nameAtBottom);
                return;
            }

            // Opaque, full-face background panel drawn behind every row. uGUI renders unlit, so this panel plus the
            // text rows are always full-bright regardless of scene lighting, guaranteeing the (dark) member text has
            // contrast. Use the node fill; if it's very dark, lighten toward white so the dark text stays legible.
            BuildFacePanel(faceRt, pxW, pxH);

            Color nameColor = _text;
            Color subColor = Color.Lerp(_text, _fill, 0.35f);
            float stereoH = string.IsNullOrEmpty(stereotype) ? 0f : 16f;

            bool hasAttrs = attributes != null && attributes.Count > 0;
            bool hasOps = operations != null && operations.Count > 0;
            bool hasMembers = hasAttrs || hasOps;

            // Header: optional stereotype, then the bold name. When the node has no member compartments (use case,
            // state, junction, decision, fork, actor, …) the header block is centered on the face with no dividers;
            // with members it sits at the top and the compartments stack below it.
            float headerBlockH = (stereoH > 0f ? stereoH : 0f) + 28f;
            float ty = hasMembers
                ? pxH * 0.5f - 4f          // top edge, working downward (canvas center is origin)
                : headerBlockH * 0.5f;     // top of a vertically-centered header block
            if (stereoH > 0f)
            {
                Row(faceRt, stereotype, ty, stereoH, 14, subColor, TextAnchor.MiddleCenter, false);
                ty -= stereoH;
            }
            Row(faceRt, name, ty, 28f, NameSize, nameColor, TextAnchor.MiddleCenter, true);
            ty -= 28f;

            // Header divider only when at least one compartment below it is non-empty.
            if (hasMembers)
            {
                Divider(faceRt, ty, pxW);
                ty -= 4f;
            }

            // Attributes compartment — only drawn when it actually has rows.
            if (hasAttrs)
            {
                foreach (var a in attributes) { Row(faceRt, a, ty, RowH, MemberSize, _text, TextAnchor.MiddleLeft, false); ty -= RowH; }
                // Divider between attributes and operations only when operations follow.
                if (hasOps)
                {
                    ty -= 4f;
                    Divider(faceRt, ty, pxW);
                    ty -= 4f;
                }
            }

            // Operations compartment — only drawn when it actually has rows.
            if (hasOps)
                foreach (var o in operations) { Row(faceRt, o, ty, RowH, MemberSize, _text, TextAnchor.MiddleLeft, false); ty -= RowH; }
        }

        private void BuildEaNotationFace(RectTransform parent, ElementKind kind, string name, string stereotype,
            List<string> rows, float pxW, float pxH)
        {
            // BPMN/DMN non-rectangular glyphs keep their silhouette clean and use marker text instead of a card.
            if (kind == ElementKind.BpmnEvent)
            {
                string evt = Prop(rows, "event", "start");
                string trigger = Prop(rows, "trigger", "message");
                string marker = trigger.ToLowerInvariant() switch
                {
                    "timer" => "T",
                    "signal" => "△",
                    "error" => "!",
                    "terminate" => "X",
                    _ => "✉",
                };
                Label(parent, marker, Vector2.zero, Mathf.Min(pxW, pxH) * 0.72f, 28f, 21,
                    new Color(0.10f, 0.12f, 0.16f, 1f), new Color(1f, 1f, 1f, 0.7f), true);
                Label(parent, evt, new Vector2(0f, -pxH * 0.32f), pxW - 8f, 18f, 10,
                    new Color(0.10f, 0.12f, 0.16f, 1f), new Color(1f, 1f, 1f, 0.7f), false);
                return;
            }
            if (kind == ElementKind.BpmnGateway)
            {
                string gateway = Prop(rows, "gateway", "exclusive").ToLowerInvariant();
                string marker = gateway.Contains("parallel") ? "+" : gateway.Contains("inclusive") ? "O" : "X";
                Label(parent, marker, Vector2.zero, pxW - 10f, pxH - 10f, 24,
                    new Color(0.10f, 0.12f, 0.16f, 1f), new Color(1f, 1f, 1f, 0.7f), true);
                return;
            }
            if (kind == ElementKind.DmnDecision || kind == ElementKind.DecisionTreeNode)
            {
                Label(parent, name, new Vector2(0f, 8f), pxW - 14f, 30f, NameSize,
                    new Color(0.10f, 0.12f, 0.16f, 1f), new Color(1f, 1f, 1f, 0.7f), true);
                string sub = kind == ElementKind.DmnDecision ? Prop(rows, "logic", "decision") : Prop(rows, "condition", "condition");
                Label(parent, sub, new Vector2(0f, -16f), pxW - 18f, 18f, 11,
                    new Color(0.22f, 0.24f, 0.28f, 1f), new Color(1f, 1f, 1f, 0.7f), false);
                return;
            }
            if (kind == ElementKind.BpmnConversation)
            {
                Label(parent, "conversation", new Vector2(0f, 15f), pxW - 10f, 18f, 11,
                    new Color(0.22f, 0.24f, 0.28f, 1f), new Color(1f, 1f, 1f, 0.7f), false);
                Label(parent, name, new Vector2(0f, -4f), pxW - 12f, 30f, 15,
                    new Color(0.10f, 0.12f, 0.16f, 1f), new Color(1f, 1f, 1f, 0.7f), true);
                return;
            }
            if (kind == ElementKind.SysmlProxyPort || kind == ElementKind.SysmlFullPort || kind == ElementKind.SysmlParameter)
            {
                string dir = Prop(rows, "direction", kind == ElementKind.SysmlParameter ? "param" : "inout");
                Label(parent, dir, Vector2.zero, pxW - 4f, pxH - 4f, 9,
                    new Color(0.10f, 0.12f, 0.16f, 1f), new Color(1f, 1f, 1f, 0.7f), true);
                return;
            }

            BuildFacePanel(parent, pxW, pxH);
            Color band = BandColor(kind);
            Rect(parent, "NotationBand", new Vector2(0f, pxH * 0.5f - 12f), new Vector2(pxW - 4f, 22f), band);
            Rect(parent, "KindChip", new Vector2(-pxW * 0.5f + 18f, pxH * 0.5f - 12f), new Vector2(24f, 14f), Color.Lerp(band, Color.white, 0.35f));

            Color bandText = Luminance(band) < 0.45f ? Color.white : new Color(0.10f, 0.12f, 0.16f, 1f);
            Row(parent, NotationTitle(kind, stereotype), pxH * 0.5f - 3f, 17f, 11, bandText, TextAnchor.MiddleCenter, false);
            float y = pxH * 0.5f - 28f;
            Row(parent, name, y, 25f, NameSize, _text, TextAnchor.MiddleCenter, true);
            y -= 28f;
            Divider(parent, y, pxW);
            y -= 5f;

            var visible = rows ?? new List<string>();
            int maxRows = Mathf.Max(1, Mathf.FloorToInt((pxH - 70f) / RowH));
            for (int i = 0; i < visible.Count && i < maxRows; i++)
            {
                Row(parent, FormatPropertyRow(visible[i]), y, RowH, 12, _text, TextAnchor.MiddleLeft, false);
                y -= RowH;
            }
        }

        private static string Prop(List<string> rows, string key, string fallback)
        {
            if (rows == null) return fallback;
            string prefix = key + "=";
            foreach (var raw in rows)
            {
                if (string.IsNullOrWhiteSpace(raw)) continue;
                var row = raw.Trim();
                if (row.StartsWith(prefix, System.StringComparison.OrdinalIgnoreCase))
                {
                    var v = row.Substring(prefix.Length).Trim();
                    return string.IsNullOrEmpty(v) ? fallback : v;
                }
            }
            return fallback;
        }

        private static string FormatPropertyRow(string row)
        {
            if (string.IsNullOrWhiteSpace(row)) return "";
            int idx = row.IndexOf('=');
            if (idx <= 0) return row.Trim();
            string key = row.Substring(0, idx).Trim();
            string value = row.Substring(idx + 1).Trim();
            return string.IsNullOrEmpty(value) ? key + ":" : key + ": " + value;
        }

        private static string NotationTitle(ElementKind kind, string customStereo)
        {
            if (!string.IsNullOrWhiteSpace(customStereo)) return "«" + customStereo.Trim() + "»";
            return kind switch
            {
                ElementKind.SysmlBlock => "«block»",
                ElementKind.SysmlValueType => "«valueType»",
                ElementKind.SysmlConstraintBlock => "«constraintBlock»",
                ElementKind.SysmlRequirement => "«requirement»",
                ElementKind.BpmnActivity => "BPMN task",
                ElementKind.BpmnDataObject => "BPMN data object",
                ElementKind.BpmnDataStore => "BPMN data store",
                ElementKind.BpmnPool => "BPMN pool",
                ElementKind.BpmnLane => "BPMN lane",
                ElementKind.BpmnChoreographyTask => "BPMN choreography",
                ElementKind.DmnInputData => "DMN input data",
                ElementKind.DmnBusinessKnowledge => "DMN knowledge",
                ElementKind.DmnKnowledgeSource => "DMN source",
                ElementKind.DmnDecisionService => "DMN service",
                ElementKind.DmnTextAnnotation => "DMN annotation",
                ElementKind.TogafArchitectureBuildingBlock => "TOGAF ABB",
                ElementKind.TogafArchitecturePhase => "TOGAF ADM",
                ElementKind.ZachmanCell => "Zachman cell",
                ElementKind.UafOperationalNode or ElementKind.UafService or ElementKind.UafResource or ElementKind.UafCapability => "UAF",
                _ when kind.ToString().StartsWith("Archi") => "ArchiMate",
                _ => kind.ToString(),
            };
        }

        private static Color BandColor(ElementKind kind) => kind switch
        {
            ElementKind.SysmlBlock or ElementKind.SysmlValueType or ElementKind.SysmlConstraintBlock
                or ElementKind.SysmlRequirement or ElementKind.SysmlParameter => new Color(0.22f, 0.45f, 0.65f, 1f),
            ElementKind.BpmnActivity or ElementKind.BpmnDataObject or ElementKind.BpmnDataStore
                or ElementKind.BpmnPool or ElementKind.BpmnLane or ElementKind.BpmnChoreographyTask => new Color(0.20f, 0.55f, 0.74f, 1f),
            ElementKind.DmnInputData or ElementKind.DmnBusinessKnowledge or ElementKind.DmnKnowledgeSource
                or ElementKind.DmnDecisionService or ElementKind.DmnTextAnnotation => new Color(0.84f, 0.52f, 0.16f, 1f),
            ElementKind.ArchiBusinessActor or ElementKind.ArchiBusinessProcess => new Color(0.88f, 0.68f, 0.20f, 1f),
            ElementKind.ArchiApplicationComponent or ElementKind.ArchiApplicationService or ElementKind.ArchiDataObject => new Color(0.23f, 0.55f, 0.78f, 1f),
            ElementKind.ArchiNode or ElementKind.ArchiDevice or ElementKind.ArchiSystemSoftware or ElementKind.ArchiTechnologyService => new Color(0.26f, 0.62f, 0.42f, 1f),
            ElementKind.ArchiCapability or ElementKind.ArchiOutcome or ElementKind.ArchiRequirement or ElementKind.ArchiPrinciple => new Color(0.50f, 0.40f, 0.70f, 1f),
            ElementKind.ArchiWorkPackage or ElementKind.ArchiDeliverable or ElementKind.ArchiPlateau or ElementKind.ArchiGap => new Color(0.80f, 0.42f, 0.16f, 1f),
            ElementKind.HeatMapItem => new Color(0.78f, 0.20f, 0.18f, 1f),
            _ => new Color(0.38f, 0.43f, 0.50f, 1f),
        };

        private static float Luminance(Color c) => 0.2126f * c.r + 0.7152f * c.g + 0.0722f * c.b;

        private static void Rect(RectTransform parent, string name, Vector2 center, Vector2 size, Color color)
        {
            var go = new GameObject(name, typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0.5f, 0.5f);
            rt.pivot = new Vector2(0.5f, 0.5f);
            rt.sizeDelta = size;
            rt.anchoredPosition = center;
            var img = go.AddComponent<Image>();
            img.color = color;
            img.raycastTarget = false;
        }

        /// <summary>
        /// An opaque full-face background card (panel + thin darker border) added as the FIRST children of the face
        /// canvas so it draws behind the stereotype/name/dividers/members. The panel covers the whole face
        /// (<c>sizeDelta == sizePx</c>); subsequent rows are siblings added after it, so canvas sibling order keeps
        /// the text on top.
        /// </summary>
        private void BuildFacePanel(RectTransform parent, float pxW, float pxH)
        {
            // Lighten the fill toward white when it's too dark for the dark member text to read against.
            Color panelColor = _fill;
            float lum = 0.2126f * panelColor.r + 0.7152f * panelColor.g + 0.0722f * panelColor.b;
            if (lum < 0.55f) panelColor = Color.Lerp(panelColor, Color.white, 0.55f);
            panelColor.a = 1f;

            // Border: a slightly larger panel in a darker tone, placed first (drawn furthest back).
            var borderGo = new GameObject("FaceBorder", typeof(RectTransform));
            var borderRt = (RectTransform)borderGo.transform;
            borderRt.SetParent(parent, false);
            borderRt.anchorMin = new Vector2(0.5f, 0.5f);
            borderRt.anchorMax = new Vector2(0.5f, 0.5f);
            borderRt.pivot = new Vector2(0.5f, 0.5f);
            borderRt.sizeDelta = new Vector2(pxW, pxH);
            borderRt.anchoredPosition = Vector2.zero;
            var borderImg = borderGo.AddComponent<Image>();
            borderImg.color = new Color(0.30f, 0.32f, 0.37f, 1f);
            borderImg.raycastTarget = false;
            borderRt.SetAsFirstSibling();

            // Fill panel: inset by the border thickness, drawn just after the border.
            const float border = 2f;
            var panelGo = new GameObject("FacePanel", typeof(RectTransform));
            var panelRt = (RectTransform)panelGo.transform;
            panelRt.SetParent(parent, false);
            panelRt.anchorMin = new Vector2(0.5f, 0.5f);
            panelRt.anchorMax = new Vector2(0.5f, 0.5f);
            panelRt.pivot = new Vector2(0.5f, 0.5f);
            panelRt.sizeDelta = new Vector2(Mathf.Max(0f, pxW - border * 2f), Mathf.Max(0f, pxH - border * 2f));
            panelRt.anchoredPosition = Vector2.zero;
            var panelImg = panelGo.AddComponent<Image>();
            panelImg.color = panelColor;
            panelImg.raycastTarget = false;
            // Sit immediately above the border but below the text rows added afterward.
            panelRt.SetSiblingIndex(1);
        }

        /// <summary>
        /// A centered name (and optional stereotype above it) for non-rectangular silhouettes — no opaque card, so
        /// the text floats on the shape's front face. The color is chosen to contrast the lit, fill-tinted mesh and
        /// an <see cref="Outline"/> is added so the label stays legible over a mid-tone surface.
        /// </summary>
        private void BuildLabelFace(RectTransform parent, string name, string stereotype, float pxW, float pxH,
            bool atBottom = false)
        {
            float lum = 0.2126f * _fill.r + 0.7152f * _fill.g + 0.0722f * _fill.b;
            Color textCol = lum < 0.5f ? new Color(0.97f, 0.98f, 1f, 1f) : new Color(0.10f, 0.12f, 0.16f, 1f);
            Color outline = lum < 0.5f ? new Color(0f, 0f, 0f, 0.65f) : new Color(1f, 1f, 1f, 0.7f);

            bool hasStereo = !string.IsNullOrEmpty(name) && !string.IsNullOrEmpty(stereotype);
            // Bottom-anchored (actor/person): the name sits in the reserved band beneath the figure. Otherwise the
            // label block is centered on the face, nudged down a touch when a stereotype rides above it.
            float nameY = atBottom ? (-pxH * 0.5f + 15f) : (hasStereo ? 9f : 0f);
            float nameH = atBottom ? 28f : Mathf.Max(20f, pxH - 12f);
            if (hasStereo)
                Label(parent, stereotype, new Vector2(0f, nameY + (atBottom ? 18f : 16f)), pxW - 8f, 22f, 13,
                    textCol, outline, false);
            Label(parent, name, new Vector2(0f, nameY), pxW - 8f, nameH, NameSize, textCol, outline, true);
        }

        /// <summary>One centered, outlined label inside the face canvas (used by <see cref="BuildLabelFace"/>).</summary>
        private void Label(RectTransform parent, string text, Vector2 center, float width, float height, int size,
            Color color, Color outline, bool bold)
        {
            var go = new GameObject("Label", typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0.5f, 0.5f);
            rt.pivot = new Vector2(0.5f, 0.5f);
            rt.sizeDelta = new Vector2(width, height);
            rt.anchoredPosition = center;
            var t = go.AddComponent<Text>();
            t.font = _font;
            t.text = text;
            t.fontSize = size;
            t.color = color;
            t.fontStyle = bold ? FontStyle.Bold : FontStyle.Normal;
            t.alignment = TextAnchor.MiddleCenter;
            t.supportRichText = false;
            t.raycastTarget = false;
            t.horizontalOverflow = HorizontalWrapMode.Wrap;
            t.verticalOverflow = VerticalWrapMode.Truncate;
            var o = go.AddComponent<Outline>();
            o.effectColor = outline;
            o.effectDistance = new Vector2(1.2f, 1.2f);
        }

        /// <summary>One text row laid out from the canvas center, top-anchored at <paramref name="topY"/> (px).</summary>
        private void Row(RectTransform parent, string text, float topY, float height, int fontSize, Color color,
            TextAnchor align, bool bold)
        {
            var go = new GameObject("Row", typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            rt.anchorMin = new Vector2(0.5f, 0.5f);
            rt.anchorMax = new Vector2(0.5f, 0.5f);
            rt.pivot = new Vector2(0.5f, 1f);
            rt.sizeDelta = new Vector2(parent.sizeDelta.x - 20f, height);
            rt.anchoredPosition = new Vector2(0f, topY);
            var t = go.AddComponent<Text>();
            t.font = _font;
            t.text = text;
            t.fontSize = fontSize;
            t.color = color;
            t.alignment = align;
            t.fontStyle = bold ? FontStyle.Bold : FontStyle.Normal;
            t.supportRichText = false;
            t.raycastTarget = false;
            // Wrap within the row width and truncate vertically; the face RectMask2D hard-clips anything that still
            // exceeds the node bounds, so text never spills outside a too-small node.
            t.horizontalOverflow = HorizontalWrapMode.Wrap;
            t.verticalOverflow = VerticalWrapMode.Truncate;
        }

        private void Divider(RectTransform parent, float topY, float pxW)
        {
            var go = new GameObject("Divider", typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            rt.anchorMin = new Vector2(0.5f, 0.5f);
            rt.anchorMax = new Vector2(0.5f, 0.5f);
            rt.pivot = new Vector2(0.5f, 1f);
            rt.sizeDelta = new Vector2(pxW, 2f);
            rt.anchoredPosition = new Vector2(0f, topY);
            var img = go.AddComponent<Image>();
            img.color = new Color(0.66f, 0.68f, 0.73f, 1f);
            img.raycastTarget = false;
        }

        /// <summary>
        /// A thin highlight border: a slightly larger box rendered as a wireframe-ish line cage via a
        /// <see cref="LineRenderer"/>. Hidden until <see cref="SetSelected"/>(true).
        /// </summary>
        private void BuildSelectionBox(float w, float h, float d)
        {
            _selectionBox = new GameObject("Selection");
            _selectionBox.transform.SetParent(_slab, false);
            float x = w * 0.5f + 0.02f, y = h * 0.5f + 0.02f, z = d * 0.5f + 0.02f;
            var lr = _selectionBox.AddComponent<LineRenderer>();
            lr.useWorldSpace = false;
            lr.loop = false;
            lr.widthMultiplier = 0.02f;
            lr.material = CreateMaterial(new Color(0.12f, 0.55f, 0.85f, 1f));
            lr.startColor = lr.endColor = new Color(0.12f, 0.55f, 0.85f, 1f);
            // Front face loop, then a hop to the back face loop (a single continuous polyline traces the cage).
            var pts = new[]
            {
                new Vector3(-x, -y, z), new Vector3(x, -y, z), new Vector3(x, y, z), new Vector3(-x, y, z), new Vector3(-x, -y, z),
                new Vector3(-x, -y, -z), new Vector3(x, -y, -z), new Vector3(x, y, -z), new Vector3(-x, y, -z), new Vector3(-x, -y, -z),
            };
            lr.positionCount = pts.Length;
            lr.SetPositions(pts);
            _selectionBox.SetActive(false);
        }
    }
}
