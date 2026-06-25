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
        private Canvas _faceCanvas;         // world-space content on the +Z face
        private CanvasGroup _faceGroup;     // alpha fades with depth tint
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
            _faceHalfW = w * 0.5f; _faceHalfH = h * 0.5f;

            // The slab is a child so per-node LocalRotation can spin it (plus its face + collider) while the
            // node GameObject itself stays at the layer's world pose.
            var slabGo = new GameObject("Slab");
            _slab = slabGo.transform;
            _slab.SetParent(transform, false);

            var mf = slabGo.AddComponent<MeshFilter>();
            mf.sharedMesh = BuildBoxMesh(w, h, d);
            _slabRenderer = slabGo.AddComponent<MeshRenderer>();
            _slabMaterial = CreateMaterial(fill);
            _slabRenderer.sharedMaterial = _slabMaterial;

            _collider = slabGo.AddComponent<BoxCollider>();
            _collider.size = new Vector3(w, h, d);
            _collider.center = Vector3.zero;

            BuildFace(name, stereotype, kind, sizePx, w, h, d, attributes, operations);
            BuildSelectionBox(w, h, d);
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
            float w = Mathf.Max(20f, sizePx.x) * Uml3DConfig.WorldScale;
            float h = Mathf.Max(14f, sizePx.y) * Uml3DConfig.WorldScale;
            float d = _depth;
            _faceHalfW = w * 0.5f; _faceHalfH = h * 0.5f;

            if (_slab != null)
            {
                var mf = _slab.GetComponent<MeshFilter>();
                if (mf != null) mf.sharedMesh = BuildBoxMesh(w, h, d);
            }
            if (_collider != null) _collider.size = new Vector3(w, h, d);

            if (_faceCanvas != null) Destroy(_faceCanvas.gameObject);
            if (_selectionBox != null) Destroy(_selectionBox);
            BuildFace(_name, _stereotype, _kind, sizePx, w, h, d, _attrs, _ops);
            BuildSelectionBox(w, h, d);

            if (_selectionBox != null) _selectionBox.SetActive(_selected);
            if (_faceGroup != null) _faceGroup.alpha = Mathf.Lerp(1f, 0.35f, _depthT);
        }

        /// <summary>Accumulate a per-node spin (degrees) about the node's local right (pitch) and up (yaw) axes.</summary>
        public void AddLocalRotation(float dPitch, float dYaw)
        {
            _localPitch += dPitch;
            _localYaw += dYaw;
            LocalRotation = Quaternion.Euler(_localPitch, _localYaw, 0f);
            if (_slab != null) _slab.localRotation = LocalRotation;
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
            if (_slabMaterial == null) return;
            var gray = new Color(0.5f, 0.52f, 0.55f, 1f);
            Color c = Color.Lerp(_fill, gray, _depthT);
            _slabMaterial.color = c;
            if (_slabMaterial.HasProperty(BaseColorId)) _slabMaterial.SetColor(BaseColorId, c);
            // A subtle emissive lift when selected (works on Lit; harmless on Standard / ignored on unlit).
            if (_slabMaterial.HasProperty(EmissionColorId))
            {
                Color emis = _selected ? new Color(0.10f, 0.32f, 0.50f, 1f) : Color.black;
                _slabMaterial.SetColor(EmissionColorId, emis);
            }
        }

        // --- mesh / material / face construction ---

        private static readonly int BaseColorId = Shader.PropertyToID("_BaseColor");
        private static readonly int EmissionColorId = Shader.PropertyToID("_EmissionColor");

        /// <summary>A 24-vertex (per-face normals), 12-triangle box centered on the origin. Front face at +Z.</summary>
        private static Mesh BuildBoxMesh(float w, float h, float d)
        {
            float x = w * 0.5f, y = h * 0.5f, z = d * 0.5f;
            var v = new[]
            {
                // +Z (front)
                new Vector3(-x, -y, z), new Vector3(x, -y, z), new Vector3(x, y, z), new Vector3(-x, y, z),
                // -Z (back)
                new Vector3(x, -y, -z), new Vector3(-x, -y, -z), new Vector3(-x, y, -z), new Vector3(x, y, -z),
                // +X (right)
                new Vector3(x, -y, z), new Vector3(x, -y, -z), new Vector3(x, y, -z), new Vector3(x, y, z),
                // -X (left)
                new Vector3(-x, -y, -z), new Vector3(-x, -y, z), new Vector3(-x, y, z), new Vector3(-x, y, -z),
                // +Y (top)
                new Vector3(-x, y, z), new Vector3(x, y, z), new Vector3(x, y, -z), new Vector3(-x, y, -z),
                // -Y (bottom)
                new Vector3(-x, -y, -z), new Vector3(x, -y, -z), new Vector3(x, -y, z), new Vector3(-x, -y, z),
            };
            var n = new[]
            {
                Vector3.forward, Vector3.back, Vector3.right, Vector3.left, Vector3.up, Vector3.down,
            };
            var normals = new Vector3[24];
            for (int f = 0; f < 6; f++)
                for (int i = 0; i < 4; i++)
                    normals[f * 4 + i] = n[f];

            var tris = new int[36];
            for (int f = 0; f < 6; f++)
            {
                int b = f * 4, t = f * 6;
                tris[t] = b; tris[t + 1] = b + 1; tris[t + 2] = b + 2;
                tris[t + 3] = b; tris[t + 4] = b + 2; tris[t + 5] = b + 3;
            }

            var mesh = new Mesh { name = "UmlNodeSlab" };
            mesh.vertices = v;
            mesh.normals = normals;
            mesh.triangles = tris;
            mesh.RecalculateBounds();
            return mesh;
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

            var faceGo = new GameObject("Face", typeof(RectTransform));
            var faceRt = (RectTransform)faceGo.transform;
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
            faceRt.localPosition = new Vector3(0f, 0f, d * 0.5f + 0.004f);
            faceRt.localRotation = Quaternion.Euler(0f, 180f, 0f);

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
