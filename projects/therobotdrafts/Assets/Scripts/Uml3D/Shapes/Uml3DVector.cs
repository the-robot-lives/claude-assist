using System.Collections.Generic;
using UnityEngine;

namespace TheRobotDraft.Uml3D
{
    /// <summary>
    /// A tiny SVG-like 2-D vector scene that <b>volumetrizes</b> into a 3-D part hierarchy: you draw a flat picture
    /// out of filled, stroked primitives (rectangles, rounded rectangles, ellipses, polygons) positioned in the XY
    /// plane with an explicit Z, then <see cref="Volumetrize"/> extrudes each one along Z into a colored slab and
    /// instantiates it as its own GameObject (with its own material) plus a stroke-colored inverted-hull edge shell.
    ///
    /// This is the "design in 2-D, then give it depth" pipeline: a node's avatar (e.g. the actor robot) is authored
    /// as a small 2-D diagram — each shape its own fill so eyes/mouth/panels are real colored elements, not holes —
    /// and layered in Z (face details given a slightly larger Z so they sit proud of the head). Centered on the
    /// parent's origin; +Z faces the camera, +Y up.
    ///
    /// <b>Materials (Phase 2):</b> each shape can opt into richer looks via an optional <see cref="MatOpts"/> — a
    /// fill alpha &lt; 1 builds a transparent material, <c>metallic</c>/<c>smoothness</c> drive PBR shading, an
    /// <c>unlit</c> flag makes a part read as flat pure color, and a <c>gradientTo</c> color bakes a 2-color vertical
    /// ramp texture (with auto planar UVs) across the shape. All are additive: the defaults reproduce the original
    /// matte-lit fill exactly. Created materials are de-duplicated in an instance-level cache so identically-styled
    /// parts share one <see cref="Material"/> (the cache is per <see cref="Uml3DVector"/> so different nodes tint
    /// independently). After <see cref="Volumetrize"/>, <see cref="Parts"/> / <see cref="PartBaseColors"/> expose the
    /// per-shape fill renderers and the colors they were built with so a caller can re-tint / highlight them.
    /// </summary>
    public sealed class Uml3DVector
    {
        /// <summary>
        /// Optional richer-material settings for a shape. The default value (all zero / null) reproduces the original
        /// matte-lit look. Alpha is taken from the fill color's own alpha channel.
        /// </summary>
        public struct MatOpts
        {
            public float Metallic;     // 0..1 PBR metallic (0 = dielectric, the default matte look)
            public float Smoothness;   // 0..1 PBR smoothness/glossiness (0 = rough)
            public bool Unlit;         // true = build from URP/Unlit (flat, ignores scene lighting)
            public Color? GradientTo;  // when set, fill becomes a vertical Fill→GradientTo ramp texture

            public static readonly MatOpts None = default;
            public bool IsDefault => Metallic <= 0f && Smoothness <= 0f && !Unlit && !GradientTo.HasValue;
        }

        private struct Shape
        {
            public Vector2[] Outline; // centered on origin (XY) — outer contour (or polyline points)
            public IList<IList<Vector2>> Holes; // optional interior holes (null = none)
            public float Bevel;       // optional front chamfer (0 = flat cap)
            public Vector3 Center;    // placement (cx, cy, zCenter)
            public float Rot;         // in-plane rotation (degrees about Z) — "rectangles of different rotations"
            public float Depth;       // Z extrusion thickness
            public Color Fill;
            public Color Stroke;
            public bool Emissive;
            public string Name;
            public bool IsPolyline;   // true = stroked ribbon (no fill), built via AddPolyline
            public float PolyWidth;   // ribbon width (polyline only)
            public bool Closed;       // ribbon wraps last→first (polyline only)
            public MatOpts Mat;       // optional richer-material settings (alpha/metallic/smoothness/unlit/gradient)
        }

        private readonly List<Shape> _shapes = new();

        // Per-instance material cache (keyed by full parameter set) so identically-styled parts share one Material,
        // while different Uml3DVector instances (= different nodes) keep their own materials and tint independently.
        private readonly Dictionary<string, Material> _matCache = new();
        private readonly Dictionary<string, Texture2D> _gradCache = new();

        // Per-shape fill renderers (and the colors they were built with), populated by Volumetrize so a caller can
        // re-tint / highlight them. Edge shells are not included — they carry the stroke color, not the fill.
        private readonly List<Renderer> _parts = new();
        private readonly List<Color> _partBaseColors = new();

        /// <summary>The fill-part renderers created by the last <see cref="Volumetrize"/> (one per non-polyline+polyline shape).</summary>
        public IReadOnlyList<Renderer> Parts => _parts;

        /// <summary>The fill colors the <see cref="Parts"/> were built with (parallel to <see cref="Parts"/>).</summary>
        public IReadOnlyList<Color> PartBaseColors => _partBaseColors;

        private static readonly int BaseColorId = Shader.PropertyToID("_BaseColor");
        private static readonly int EmissionColorId = Shader.PropertyToID("_EmissionColor");
        private static readonly int CullId = Shader.PropertyToID("_Cull");
        private static readonly int MetallicId = Shader.PropertyToID("_Metallic");
        private static readonly int SmoothnessId = Shader.PropertyToID("_Smoothness");
        private static readonly int GlossinessId = Shader.PropertyToID("_Glossiness");
        private static readonly int SurfaceId = Shader.PropertyToID("_Surface");
        private static readonly int BlendId = Shader.PropertyToID("_Blend");
        private static readonly int SrcBlendId = Shader.PropertyToID("_SrcBlend");
        private static readonly int DstBlendId = Shader.PropertyToID("_DstBlend");
        private static readonly int ZWriteId = Shader.PropertyToID("_ZWrite");
        private static readonly int ModeId = Shader.PropertyToID("_Mode");
        private static readonly int BaseMapId = Shader.PropertyToID("_BaseMap");
        private static readonly int MainTexId = Shader.PropertyToID("_MainTex");

        // --- 2-D primitives (an SVG-ish drawing surface) -----------------------------------------------------

        /// <summary>A filled rectangle centered at (cx,cy), extruded to <paramref name="depth"/> around <paramref name="z"/>.</summary>
        public void Rect(string name, float cx, float cy, float w, float h, float z, float depth, Color fill, Color stroke, float rot = 0f, bool emissive = false, float bevel = 0f, MatOpts mat = default)
            => Add(name, Uml3DMeshBuilder.RoundedRectOutline(w, h, 0.0001f, 1), cx, cy, z, depth, fill, stroke, rot, emissive, bevel, mat);

        /// <summary>A filled rounded rectangle (corner radius <paramref name="r"/>), optionally rotated about Z.</summary>
        public void RoundRect(string name, float cx, float cy, float w, float h, float r, float z, float depth, Color fill, Color stroke, float rot = 0f, bool emissive = false, float bevel = 0f, MatOpts mat = default)
            => Add(name, Uml3DMeshBuilder.RoundedRectOutline(w, h, r, 5), cx, cy, z, depth, fill, stroke, rot, emissive, bevel, mat);

        /// <summary>A filled ellipse.</summary>
        public void Ellipse(string name, float cx, float cy, float rx, float ry, float z, float depth, Color fill, Color stroke, float rot = 0f, bool emissive = false, MatOpts mat = default)
            => Add(name, Uml3DMeshBuilder.EllipseOutline(rx, ry, 28), cx, cy, z, depth, fill, stroke, rot, emissive, 0f, mat);

        /// <summary>A filled polygon (points given relative to (cx,cy)). Concave outlines are supported via ear-clipping.</summary>
        public void Poly(string name, Vector2[] centeredPoints, float cx, float cy, float z, float depth, Color fill, Color stroke, float rot = 0f, bool emissive = false, float bevel = 0f, MatOpts mat = default)
            => Add(name, centeredPoints, cx, cy, z, depth, fill, stroke, rot, emissive, bevel, mat);

        /// <summary>
        /// A filled concave polygon with optional interior <paramref name="holes"/> (each contour's points are
        /// relative to (cx,cy)). Built via <see cref="Uml3DMeshBuilder.AddPrism"/>.
        /// </summary>
        public void Path(string name, IList<Vector2> outer, IList<IList<Vector2>> holes, float cx, float cy, float z, float depth, Color fill, Color stroke, float rot = 0f, bool emissive = false, float bevel = 0f, MatOpts mat = default)
        {
            var arr = new Vector2[outer.Count];
            for (int i = 0; i < outer.Count; i++) arr[i] = outer[i];
            _shapes.Add(new Shape
            {
                Name = name, Outline = arr, Holes = holes, Bevel = bevel,
                Center = new Vector3(cx, cy, z), Rot = rot, Depth = Mathf.Max(0.01f, depth),
                Fill = fill, Stroke = stroke, Emissive = emissive, Mat = mat,
            });
        }

        /// <summary>
        /// An open (or <paramref name="closed"/>) stroked path with no fill — a flat ribbon of <paramref name="width"/>
        /// following <paramref name="points"/> (relative to (cx,cy)). The stroke color doubles as the fill. Built via
        /// <see cref="Uml3DMeshBuilder.AddPolyline"/>.
        /// </summary>
        public void Polyline(string name, IList<Vector2> points, float width, float cx, float cy, float z, float depth, Color stroke, bool closed = false, float rot = 0f, MatOpts mat = default)
        {
            var arr = new Vector2[points.Count];
            for (int i = 0; i < points.Count; i++) arr[i] = points[i];
            _shapes.Add(new Shape
            {
                Name = name, Outline = arr, Center = new Vector3(cx, cy, z), Rot = rot, Depth = Mathf.Max(0.01f, depth),
                Fill = stroke, Stroke = stroke, Emissive = false,
                IsPolyline = true, PolyWidth = Mathf.Max(0.001f, width), Closed = closed, Mat = mat,
            });
        }

        private void Add(string name, Vector2[] outline, float cx, float cy, float z, float depth, Color fill, Color stroke, float rot, bool emissive, float bevel, MatOpts mat)
            => _shapes.Add(new Shape
            {
                Name = name, Outline = outline, Bevel = bevel, Center = new Vector3(cx, cy, z), Rot = rot, Depth = Mathf.Max(0.01f, depth),
                Fill = fill, Stroke = stroke, Emissive = emissive, Mat = mat,
            });

        // --- volumetrize -------------------------------------------------------------------------------------

        /// <summary>Extrude every shape into a colored slab part (+ stroke edge shell) under <paramref name="parent"/>.</summary>
        public void Volumetrize(Transform parent)
        {
            _parts.Clear();
            _partBaseColors.Clear();

            foreach (var s in _shapes)
            {
                var b = new Uml3DMeshBuilder();
                if (s.IsPolyline)
                    b.AddPolyline(s.Outline, s.PolyWidth, 0f, s.Depth, s.Closed);
                else
                    b.AddPrism(s.Outline, s.Holes, s.Depth * 0.5f, -s.Depth * 0.5f, s.Bevel);
                var mesh = b.ToMesh(s.Name);

                // Gradient: bake planar UVs over the shape's XY bounding box so the ramp texture runs bottom→top.
                if (s.Mat.GradientTo.HasValue) AddPlanarUVs(mesh);

                var go = new GameObject(s.Name);
                var t = go.transform;
                t.SetParent(parent, false);
                t.localPosition = s.Center;
                if (Mathf.Abs(s.Rot) > 1e-3f) t.localRotation = Quaternion.Euler(0f, 0f, s.Rot);
                go.AddComponent<MeshFilter>().sharedMesh = mesh;
                var r = go.AddComponent<MeshRenderer>();
                r.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
                r.receiveShadows = false;
                r.sharedMaterial = FillMaterial(s.Fill, s.Emissive, s.Mat);

                _parts.Add(r);
                _partBaseColors.Add(s.Fill);

                float edgeScale = EdgeScale(s.Outline, s.Depth);
                if (edgeScale > 1.0001f)
                {
                    var eo = new GameObject("Edge");
                    var et = eo.transform;
                    et.SetParent(t, false);
                    et.localScale = Vector3.one * edgeScale;
                    eo.AddComponent<MeshFilter>().sharedMesh = mesh;
                    var er = eo.AddComponent<MeshRenderer>();
                    er.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
                    er.receiveShadows = false;
                    er.sharedMaterial = BorderMaterial(s.Stroke);
                }
            }
        }

        /// <summary>Uniform scale yielding a roughly constant ~0.012u stroke rim regardless of shape size.</summary>
        private static float EdgeScale(Vector2[] outline, float depth)
        {
            float ext = 0.02f;
            foreach (var p in outline) ext = Mathf.Max(ext, Mathf.Max(Mathf.Abs(p.x), Mathf.Abs(p.y)) * 2f);
            float m = Mathf.Max(ext, depth);
            return 1f + 0.024f / Mathf.Max(0.02f, m);
        }

        /// <summary>Assign planar UVs over the mesh's XY bounding box (u = x, v = y, both normalized 0..1).</summary>
        private static void AddPlanarUVs(Mesh mesh)
        {
            var verts = mesh.vertices;
            if (verts.Length == 0) return;
            float minX = float.MaxValue, minY = float.MaxValue, maxX = float.MinValue, maxY = float.MinValue;
            for (int i = 0; i < verts.Length; i++)
            {
                var v = verts[i];
                if (v.x < minX) minX = v.x; if (v.x > maxX) maxX = v.x;
                if (v.y < minY) minY = v.y; if (v.y > maxY) maxY = v.y;
            }
            float dx = Mathf.Max(1e-5f, maxX - minX), dy = Mathf.Max(1e-5f, maxY - minY);
            var uv = new Vector2[verts.Length];
            for (int i = 0; i < verts.Length; i++)
                uv[i] = new Vector2((verts[i].x - minX) / dx, (verts[i].y - minY) / dy);
            mesh.uv = uv;
        }

        // --- materials ---------------------------------------------------------------------------------------

        /// <summary>
        /// Build (or fetch from the per-instance cache) the lit/unlit fill material for a shape, honoring the
        /// optional <see cref="MatOpts"/>: alpha &lt; 1 → transparent surface, metallic/smoothness → PBR, the unlit
        /// flag → flat URP/Unlit, and a gradient → a baked vertical ramp texture as the base map. With the default
        /// <see cref="MatOpts"/> and an opaque fill this reproduces the original matte-lit material exactly.
        /// </summary>
        private Material FillMaterial(Color color, bool emissive, MatOpts mat)
        {
            bool transparent = color.a < 0.999f;
            string key = $"fill|{Hex(color)}|e{(emissive ? 1 : 0)}|m{mat.Metallic:0.###}|s{mat.Smoothness:0.###}"
                       + $"|u{(mat.Unlit ? 1 : 0)}|g{(mat.GradientTo.HasValue ? Hex(mat.GradientTo.Value) : "_")}";
            if (_matCache.TryGetValue(key, out var cached)) return cached;

            Shader sh = mat.Unlit
                ? (Shader.Find("Universal Render Pipeline/Unlit") ?? Shader.Find("Unlit/Color") ?? Shader.Find("Sprites/Default"))
                : (Shader.Find("Universal Render Pipeline/Lit") ?? Shader.Find("Standard") ?? Shader.Find("Sprites/Default"));
            var m = new Material(sh) { color = color };
            if (m.HasProperty(BaseColorId)) m.SetColor(BaseColorId, color);

            if (!mat.Unlit)
            {
                if (mat.Metallic > 0f && m.HasProperty(MetallicId)) m.SetFloat(MetallicId, Mathf.Clamp01(mat.Metallic));
                if (mat.Smoothness > 0f)
                {
                    if (m.HasProperty(SmoothnessId)) m.SetFloat(SmoothnessId, Mathf.Clamp01(mat.Smoothness));
                    if (m.HasProperty(GlossinessId)) m.SetFloat(GlossinessId, Mathf.Clamp01(mat.Smoothness)); // Standard fallback
                }
                if (emissive && m.HasProperty(EmissionColorId))
                {
                    m.EnableKeyword("_EMISSION");
                    m.SetColor(EmissionColorId, color * 0.85f);
                }
            }

            if (mat.GradientTo.HasValue)
            {
                var tex = GradientTexture(color, mat.GradientTo.Value);
                if (m.HasProperty(BaseMapId)) m.SetTexture(BaseMapId, tex);
                if (m.HasProperty(MainTexId)) m.SetTexture(MainTexId, tex);
                // Let the ramp drive the color: a white tint shows the texture as-authored (alpha kept for transparency).
                Color tint = new Color(1f, 1f, 1f, color.a);
                m.color = tint;
                if (m.HasProperty(BaseColorId)) m.SetColor(BaseColorId, tint);
            }

            if (transparent) MakeTransparent(m);

            _matCache[key] = m;
            return m;
        }

        /// <summary>Configure a URP/Lit (or Standard) material for alpha-blended transparent rendering.</summary>
        private static void MakeTransparent(Material m)
        {
            if (m.HasProperty(SurfaceId)) m.SetFloat(SurfaceId, 1f); // URP: 0=Opaque, 1=Transparent
            if (m.HasProperty(BlendId)) m.SetFloat(BlendId, 0f);     // URP: 0=Alpha
            if (m.HasProperty(SrcBlendId)) m.SetFloat(SrcBlendId, (float)UnityEngine.Rendering.BlendMode.SrcAlpha);
            if (m.HasProperty(DstBlendId)) m.SetFloat(DstBlendId, (float)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
            if (m.HasProperty(ZWriteId)) m.SetFloat(ZWriteId, 0f);
            if (m.HasProperty(ModeId)) m.SetFloat(ModeId, 3f);       // Standard: 3=Transparent
            m.EnableKeyword("_SURFACE_TYPE_TRANSPARENT");
            m.DisableKeyword("_ALPHATEST_ON");
            m.EnableKeyword("_ALPHABLEND_ON");
            m.DisableKeyword("_ALPHAPREMULTIPLY_ON");
            m.SetOverrideTag("RenderType", "Transparent");
            m.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
        }

        /// <summary>A cached 2×64 vertical ramp texture from <paramref name="bottom"/> to <paramref name="top"/>.</summary>
        private Texture2D GradientTexture(Color bottom, Color top)
        {
            string key = $"{Hex(bottom)}->{Hex(top)}";
            if (_gradCache.TryGetValue(key, out var cached)) return cached;
            const int h = 64, w = 2;
            var tex = new Texture2D(w, h, TextureFormat.RGBA32, false) { wrapMode = TextureWrapMode.Clamp, filterMode = FilterMode.Bilinear };
            var px = new Color[w * h];
            for (int y = 0; y < h; y++)
            {
                Color c = Color.Lerp(bottom, top, y / (float)(h - 1));
                for (int x = 0; x < w; x++) px[y * w + x] = c;
            }
            tex.SetPixels(px);
            tex.Apply(false);
            _gradCache[key] = tex;
            return tex;
        }

        private Material BorderMaterial(Color color)
        {
            string key = $"border|{Hex(color)}";
            if (_matCache.TryGetValue(key, out var cached)) return cached;

            Shader sh = Shader.Find("Universal Render Pipeline/Unlit");
            if (sh == null) sh = Shader.Find("Unlit/Color");
            if (sh == null) sh = Shader.Find("Sprites/Default");
            var m = new Material(sh) { color = color };
            if (m.HasProperty(BaseColorId)) m.SetColor(BaseColorId, color);
            if (m.HasProperty(CullId)) m.SetFloat(CullId, 1f); // render back faces → rim shows around the silhouette
            m.renderQueue = 1999;
            _matCache[key] = m;
            return m;
        }

        private static string Hex(Color c)
            => $"{(int)(c.r * 255):X2}{(int)(c.g * 255):X2}{(int)(c.b * 255):X2}{(int)(c.a * 255):X2}";
    }
}
