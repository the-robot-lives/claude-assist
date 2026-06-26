using UnityEngine;
using UnityEngine.UI;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Uml3D
{
    /// <summary>
    /// A "region" (use-case system boundary, interaction frame or profile) drawn in 3-D as a hollow cube whose
    /// 12 edges are tight dotted lines — the spatial group that visually encloses the member nodes nested inside it
    /// (replacing the old flat region BOX). The integration layer computes the world-space bounds that contain the
    /// region's members and calls <see cref="SetBounds"/>; the cube re-fits to those bounds and a floating label
    /// names it at the top-front edge.
    ///
    /// Each edge carries a thin <see cref="BoxCollider"/> so the wireframe itself is pickable (select / move /
    /// resize the region by grabbing an edge) while the cube interior stays empty — clicks there fall through to
    /// the member node slabs. A <see cref="UmlRegion3D"/> maps back from a collider via <c>GetComponentInParent</c>.
    /// </summary>
    public sealed class UmlRegion3D : MonoBehaviour
    {
        /// <summary>The model element this region renders.</summary>
        public ElementId Id;

        /// <summary>The world-space box the cube currently spans (its members' padded bounds).</summary>
        public Bounds CurrentBounds { get; private set; }

        private readonly LineRenderer[] _edges = new LineRenderer[12];
        private readonly BoxCollider[] _edgeColliders = new BoxCollider[12];
        private Canvas _labelCanvas;
        private Text _labelText;
        private Transform _fill;        // a semi-translucent box filling the cube volume
        private Material _fillMat;
        private Color _color = new Color(0.45f, 0.50f, 0.62f, 1f);
        private bool _selected;

        private static Font _font;
        private static Texture2D _dotTex;
        private static readonly int MainTexId = Shader.PropertyToID("_MainTex");
        private static readonly int BaseMapId = Shader.PropertyToID("_BaseMap");
        private static readonly int BaseColorId = Shader.PropertyToID("_BaseColor");

        private const float LineWidth = 0.022f;
        private const float SelectedLineWidth = 0.04f;
        // World-space length of one dot+gap cycle along each cube edge (small ⇒ close dots).
        private const float DotPeriod = 0.04f;
        // Thickness of the invisible pick collider straddling each edge.
        private const float EdgePick = 0.13f;

        private static readonly Color SelColor = new Color(0.12f, 0.55f, 0.85f, 1f);

        /// <summary>Create a region cube parented under <paramref name="parent"/> for the given element.</summary>
        public static UmlRegion3D Create(Transform parent, ElementId id, string name, Color color)
        {
            var go = new GameObject("Region:" + (id.Value ?? "?"));
            go.transform.SetParent(parent, false);
            var region = go.AddComponent<UmlRegion3D>();
            region.Id = id;
            region._color = new Color(color.r, color.g, color.b, 1f);
            region.Build(name);
            return region;
        }

        private void Build(string name)
        {
            for (int i = 0; i < 12; i++)
            {
                var ego = new GameObject("Edge" + i);
                ego.transform.SetParent(transform, false);
                var lr = ego.AddComponent<LineRenderer>();
                lr.useWorldSpace = true; // drawn in world space; the GameObject transform only carries the collider
                lr.widthMultiplier = LineWidth;
                lr.numCapVertices = 1;
                lr.alignment = LineAlignment.View;
                lr.textureMode = LineTextureMode.Tile;
                lr.positionCount = 2;
                lr.sharedMaterial = MakeDotMaterial(_color);
                _edges[i] = lr;
                _edgeColliders[i] = ego.AddComponent<BoxCollider>();
            }
            BuildFill();
            BuildLabel(name);
        }

        /// <summary>A semi-translucent box that fills the cube volume; tinted + faded by <see cref="SetFill"/>.</summary>
        private void BuildFill()
        {
            var go = GameObject.CreatePrimitive(PrimitiveType.Cube);
            go.name = "Fill";
            var col = go.GetComponent<Collider>();
            if (col != null) Destroy(col); // visual only — never intercept picking of members / edges
            go.transform.SetParent(transform, false);
            _fill = go.transform;
            _fillMat = MakeFillMaterial(new Color(_color.r, _color.g, _color.b, 0.12f));
            go.GetComponent<MeshRenderer>().sharedMaterial = _fillMat;
            go.SetActive(false); // shown once SetFill gives it a visible alpha
        }

        /// <summary>Set the translucent fill colour (alpha = opacity). Alpha ≈ 0 hides the fill entirely.</summary>
        public void SetFill(Color rgba)
        {
            if (_fillMat == null || _fill == null) return;
            _fillMat.color = rgba;
            if (_fillMat.HasProperty(BaseColorId)) _fillMat.SetColor(BaseColorId, rgba);
            _fill.gameObject.SetActive(rgba.a > 0.004f);
        }

        /// <summary>
        /// Fit the cube to an axis-aligned world bounding box (typically the encapsulated member nodes, padded). The
        /// 12 cube edges are re-seated to the box corners with dotting normalized to each edge's length, their pick
        /// colliders re-aligned, and the label floated just above the top-front edge.
        /// </summary>
        public void SetBounds(Bounds b)
        {
            CurrentBounds = b;
            Vector3 c = b.center, e = b.extents;
            Vector3 p000 = c + new Vector3(-e.x, -e.y, -e.z);
            Vector3 p100 = c + new Vector3(e.x, -e.y, -e.z);
            Vector3 p110 = c + new Vector3(e.x, e.y, -e.z);
            Vector3 p010 = c + new Vector3(-e.x, e.y, -e.z);
            Vector3 p001 = c + new Vector3(-e.x, -e.y, e.z);
            Vector3 p101 = c + new Vector3(e.x, -e.y, e.z);
            Vector3 p111 = c + new Vector3(e.x, e.y, e.z);
            Vector3 p011 = c + new Vector3(-e.x, e.y, e.z);

            // Bottom loop, top loop, then the four vertical pillars.
            Seg(0, p000, p100); Seg(1, p100, p101); Seg(2, p101, p001); Seg(3, p001, p000);
            Seg(4, p010, p110); Seg(5, p110, p111); Seg(6, p111, p011); Seg(7, p011, p010);
            Seg(8, p000, p010); Seg(9, p100, p110); Seg(10, p101, p111); Seg(11, p001, p011);

            if (_fill != null)
            {
                _fill.position = b.center;
                _fill.localScale = b.size;
            }

            if (_labelCanvas != null)
                _labelCanvas.transform.position = (p011 + p111) * 0.5f + Vector3.up * 0.12f;
        }

        private void Seg(int i, Vector3 a, Vector3 b)
        {
            var lr = _edges[i];
            if (lr == null) return;
            lr.SetPosition(0, a);
            lr.SetPosition(1, b);

            float len = Vector3.Distance(a, b);
            float tiles = Mathf.Max(1f, len / DotPeriod);
            var mat = lr.sharedMaterial;
            if (mat != null)
            {
                if (mat.HasProperty(MainTexId)) mat.SetTextureScale(MainTexId, new Vector2(tiles, 1f));
                if (mat.HasProperty(BaseMapId)) mat.SetTextureScale(BaseMapId, new Vector2(tiles, 1f));
            }

            // Re-seat the pick collider straddling the edge (transform only drives the collider, not the line).
            var bc = _edgeColliders[i];
            if (bc != null)
            {
                Vector3 dir = b - a;
                bc.transform.position = (a + b) * 0.5f;
                if (dir.sqrMagnitude > 1e-6f) bc.transform.rotation = Quaternion.LookRotation(dir.normalized);
                bc.center = Vector3.zero;
                bc.size = new Vector3(EdgePick, EdgePick, Mathf.Max(EdgePick, len));
            }
        }

        /// <summary>Highlight the cube when its region is selected (brighter, thicker edges + brighter label).</summary>
        public void SetHighlighted(bool on)
        {
            _selected = on;
            Color c = on ? SelColor : _color;
            float w = on ? SelectedLineWidth : LineWidth;
            foreach (var lr in _edges)
            {
                if (lr == null) continue;
                lr.startColor = lr.endColor = c;
                lr.widthMultiplier = w;
                if (lr.sharedMaterial != null)
                {
                    lr.sharedMaterial.color = c;
                    if (lr.sharedMaterial.HasProperty(BaseColorId)) lr.sharedMaterial.SetColor(BaseColorId, c);
                }
            }
            if (_labelText != null) _labelText.color = on ? SelColor : _color;
        }

        private void BuildLabel(string name)
        {
            if (_font == null) _font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            var go = new GameObject("RegionLabel", typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(transform, false);
            _labelCanvas = go.AddComponent<Canvas>();
            _labelCanvas.renderMode = RenderMode.WorldSpace;
            rt.sizeDelta = new Vector2(420f, 40f);
            rt.localScale = Vector3.one * Uml3DConfig.WorldScale;
            rt.localRotation = Quaternion.Euler(0f, 180f, 0f);

            _labelText = go.AddComponent<Text>();
            _labelText.font = _font;
            _labelText.text = "«region» " + name;
            _labelText.fontSize = 22;
            _labelText.fontStyle = FontStyle.Bold;
            _labelText.alignment = TextAnchor.MiddleCenter;
            _labelText.color = _color;
            _labelText.horizontalOverflow = HorizontalWrapMode.Overflow;
            _labelText.verticalOverflow = VerticalWrapMode.Overflow;
            _labelText.raycastTarget = false;
        }

        /// <summary>A transparent, double-sided unlit material for the fill box (URP Unlit transparent, with fallbacks).</summary>
        private static Material MakeFillMaterial(Color color)
        {
            Shader sh = Shader.Find("Universal Render Pipeline/Unlit");
            Material m;
            if (sh != null)
            {
                m = new Material(sh);
                m.SetFloat("_Surface", 1f);                 // 0 = opaque, 1 = transparent
                if (m.HasProperty("_Blend")) m.SetFloat("_Blend", 0f); // alpha blend
                m.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                m.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                m.SetInt("_ZWrite", 0);
                if (m.HasProperty("_Cull")) m.SetInt("_Cull", 0); // double-sided so it reads from inside too
                m.EnableKeyword("_SURFACE_TYPE_TRANSPARENT");
                m.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
            }
            else
            {
                sh = Shader.Find("Sprites/Default") ?? Shader.Find("Unlit/Transparent") ?? Shader.Find("Unlit/Color");
                m = new Material(sh) { renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent };
            }
            m.color = color;
            if (m.HasProperty(BaseColorId)) m.SetColor(BaseColorId, color);
            return m;
        }

        /// <summary>A line material that tiles a 1-px dot strip, giving tight dotted edges.</summary>
        private static Material MakeDotMaterial(Color color)
        {
            Shader sh = Shader.Find("Sprites/Default");
            if (sh == null) sh = Shader.Find("Unlit/Transparent");
            if (sh == null) sh = Shader.Find("Universal Render Pipeline/Unlit");
            Material m = sh != null ? new Material(sh) : new Material(Shader.Find("Unlit/Color"));
            m.color = color;
            if (m.HasProperty(BaseColorId)) m.SetColor(BaseColorId, color);

            var tex = DotTexture();
            if (m.HasProperty(MainTexId)) m.SetTexture(MainTexId, tex);
            if (m.HasProperty(BaseMapId)) m.SetTexture(BaseMapId, tex);
            return m;
        }

        /// <summary>A shared 2×1 strip — one opaque dot, one transparent gap — tiled to make tight, even dots.</summary>
        private static Texture2D DotTexture()
        {
            if (_dotTex != null) return _dotTex;
            _dotTex = new Texture2D(2, 1, TextureFormat.RGBA32, false)
                { wrapMode = TextureWrapMode.Repeat, filterMode = FilterMode.Point };
            _dotTex.SetPixels32(new[] { new Color32(255, 255, 255, 255), new Color32(255, 255, 255, 0) });
            _dotTex.Apply();
            return _dotTex;
        }
    }
}
