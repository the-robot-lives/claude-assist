using System.Collections.Generic;
using UnityEngine;

namespace TheRobotDraft.Uml3D
{
    /// <summary>
    /// A relationship drawn in 3-D as a world-space polyline (a <see cref="LineRenderer"/>) following a route the
    /// integration layer computes. The 3-D counterpart of <c>UmlEdgeView</c>'s segment chain: <see cref="SetRoute"/>
    /// feeds it the world points and a color; <see cref="SetArrow"/> toggles a small cone arrowhead at the last
    /// point, oriented along the final segment. Dashed relationship kinds (dependency, realization, «include»/«extend»,
    /// note anchors, reply messages) draw with true dashes via a tiled 1-px dash texture on the line material; the
    /// tiling is scaled to the route's total world length so dash density is uniform regardless of length.
    /// </summary>
    public sealed class UmlEdge3D : MonoBehaviour
    {
        private LineRenderer _line;
        private Material _lineMaterial;
        private Transform _arrow;          // cone mesh at the target end
        private MeshRenderer _arrowRenderer;
        private Material _arrowMaterial;
        private Vector3 _lastPoint, _lastDir = Vector3.forward;
        private Color _color = Color.gray;
        private bool _dashed;              // whether the current route renders with the tiled dash texture

        private const float LineWidth = 0.03f;
        private const float ArrowLength = 0.22f;
        private const float ArrowRadius = 0.09f;
        // World-space length of one dash+gap cycle; the dash texture is tiled once per this many world units.
        private const float DashPeriod = 0.18f;

        // A shared 1-px-tall horizontal dash strip (opaque run + transparent gap), tiled along the line.
        private static Texture2D _dashTex;
        private static readonly int MainTexId = Shader.PropertyToID("_MainTex");
        private static readonly int BaseMapId = Shader.PropertyToID("_BaseMap");

        private void EnsureLine()
        {
            if (_line != null) return;
            _line = gameObject.GetComponent<LineRenderer>();
            if (_line == null) _line = gameObject.AddComponent<LineRenderer>();
            _line.useWorldSpace = true;
            _line.widthMultiplier = LineWidth;
            _line.numCornerVertices = 2;
            _line.numCapVertices = 2;
            _line.alignment = LineAlignment.View;
            _line.textureMode = LineTextureMode.Tile;
            _lineMaterial = MakeMaterial(_color);
            _line.sharedMaterial = _lineMaterial;
        }

        /// <summary>Lay the relationship along <paramref name="worldPoints"/> (≥2 points), recolor it (solid).</summary>
        public void SetRoute(IReadOnlyList<Vector3> worldPoints, Color color) => SetRoute(worldPoints, color, false);

        /// <summary>
        /// Lay the relationship along <paramref name="worldPoints"/> (≥2 points) and recolor it. When
        /// <paramref name="dashed"/> is true the line draws with a tiled dash texture whose density is normalized to
        /// the route's total world length (so dashes look uniform regardless of how long the run is); when false it
        /// reverts to a solid line. Dashing composes with the highlight color passed for a selected edge.
        /// </summary>
        public void SetRoute(IReadOnlyList<Vector3> worldPoints, Color color, bool dashed)
        {
            EnsureLine();
            _color = color;
            if (_lineMaterial != null) _lineMaterial.color = color;
            _line.startColor = _line.endColor = color;

            if (worldPoints == null || worldPoints.Count < 2)
            {
                _line.positionCount = 0;
                if (_arrow != null) _arrow.gameObject.SetActive(false);
                return;
            }

            _line.positionCount = worldPoints.Count;
            float length = 0f;
            for (int i = 0; i < worldPoints.Count; i++)
            {
                _line.SetPosition(i, worldPoints[i]);
                if (i > 0) length += Vector3.Distance(worldPoints[i - 1], worldPoints[i]);
            }

            ApplyDash(dashed, length);

            _lastPoint = worldPoints[worldPoints.Count - 1];
            Vector3 prev = worldPoints[worldPoints.Count - 2];
            Vector3 dir = _lastPoint - prev;
            _lastDir = dir.sqrMagnitude > 1e-6f ? dir.normalized : Vector3.forward;
            UpdateArrowTransform();
        }

        /// <summary>
        /// Bind (or clear) the dash texture on the line material and scale its tiling so one dash period spans
        /// <see cref="DashPeriod"/> world units. Falls back gracefully to a solid line if the chosen shader has no
        /// texture slot. Re-tints the material's color each call so dashes inherit the (possibly highlight) color.
        /// </summary>
        private void ApplyDash(bool dashed, float worldLength)
        {
            _dashed = dashed;
            if (_lineMaterial == null) return;

            int texProp = _lineMaterial.HasProperty(BaseMapId) ? BaseMapId
                : _lineMaterial.HasProperty(MainTexId) ? MainTexId : 0;
            if (texProp == 0) return; // shader can't carry a texture → leave the solid line as-is

            if (!dashed)
            {
                _lineMaterial.SetTexture(texProp, null);
                _lineMaterial.mainTextureScale = Vector2.one;
                return;
            }

            _lineMaterial.SetTexture(texProp, GetDashTexture());
            float tiles = Mathf.Max(1f, worldLength / Mathf.Max(0.0001f, DashPeriod));
            // SetTextureScale targets the same property; mainTextureScale maps to _MainTex, so set both to be safe.
            _lineMaterial.SetTextureScale(texProp, new Vector2(tiles, 1f));
            _lineMaterial.mainTextureScale = new Vector2(tiles, 1f);
        }

        /// <summary>The shared dash strip: 8 px wide (5 opaque + 3 transparent), 1 px tall, repeating, point-filtered.</summary>
        private static Texture2D GetDashTexture()
        {
            if (_dashTex != null) return _dashTex;
            _dashTex = new Texture2D(8, 1, TextureFormat.RGBA32, false)
            {
                name = "EdgeDash",
                wrapMode = TextureWrapMode.Repeat,
                filterMode = FilterMode.Point,
            };
            var px = new Color32[8];
            for (int i = 0; i < 8; i++) px[i] = i < 5 ? new Color32(255, 255, 255, 255) : new Color32(255, 255, 255, 0);
            _dashTex.SetPixels32(px);
            _dashTex.Apply(false, false);
            return _dashTex;
        }

        /// <summary>Show or hide the cone arrowhead at the target end of the route.</summary>
        public void SetArrow(bool on)
        {
            if (on) EnsureArrow();
            if (_arrow != null) _arrow.gameObject.SetActive(on);
            if (on) UpdateArrowTransform();
        }

        private void EnsureArrow()
        {
            if (_arrow != null) return;
            var go = new GameObject("Arrowhead");
            _arrow = go.transform;
            _arrow.SetParent(transform, false);
            var mf = go.AddComponent<MeshFilter>();
            mf.sharedMesh = BuildConeMesh(ArrowRadius, ArrowLength, 12);
            _arrowRenderer = go.AddComponent<MeshRenderer>();
            _arrowMaterial = MakeMaterial(_color);
            _arrowRenderer.sharedMaterial = _arrowMaterial;
        }

        private void UpdateArrowTransform()
        {
            if (_arrow == null) return;
            if (_arrowMaterial != null) _arrowMaterial.color = _color;
            // The cone tip points along +Y in local space (see BuildConeMesh); seat the tip at the last point.
            _arrow.position = _lastPoint - _lastDir * ArrowLength;
            _arrow.rotation = Quaternion.FromToRotation(Vector3.up, _lastDir);
        }

        private static Material MakeMaterial(Color color)
        {
            Shader sh = Shader.Find("Universal Render Pipeline/Unlit");
            if (sh == null) sh = Shader.Find("Sprites/Default");
            if (sh == null) sh = Shader.Find("Unlit/Transparent");
            if (sh == null) sh = Shader.Find("Unlit/Color");
            if (sh == null) sh = Shader.Find("Standard");
            var m = new Material(sh);
            m.color = color;
            if (m.HasProperty(BaseColorId)) m.SetColor(BaseColorId, color);
            EnableAlpha(m);
            return m;
        }

        /// <summary>
        /// Put the material into an alpha-blended transparent mode so the dash texture's transparent gaps actually
        /// read as gaps (not opaque). Tuned for URP/Lit-style shaders; harmless on shaders that lack the keywords.
        /// </summary>
        private static void EnableAlpha(Material m)
        {
            if (m.HasProperty("_Surface")) m.SetFloat("_Surface", 1f);   // 0 = opaque, 1 = transparent (URP)
            if (m.HasProperty("_Blend")) m.SetFloat("_Blend", 0f);       // 0 = alpha blend
            if (m.HasProperty("_SrcBlend")) m.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
            if (m.HasProperty("_DstBlend")) m.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
            if (m.HasProperty("_ZWrite")) m.SetFloat("_ZWrite", 0f);
            m.EnableKeyword("_SURFACE_TYPE_TRANSPARENT");
            m.EnableKeyword("_ALPHABLEND_ON");
            m.renderQueue = (int)UnityEngine.Rendering.RenderQueue.Transparent;
        }

        private static readonly int BaseColorId = Shader.PropertyToID("_BaseColor");

        /// <summary>A simple cone: a base ring fanned to a single apex at +Y, plus a base fan. Tip at local +Y.</summary>
        private static Mesh BuildConeMesh(float radius, float length, int segs)
        {
            var verts = new List<Vector3>(segs + 2);
            var tris = new List<int>(segs * 6);
            int apex = 0;
            verts.Add(new Vector3(0f, length, 0f));        // 0: apex (tip)
            int baseCenter = 1;
            verts.Add(Vector3.zero);                        // 1: base center
            int ringStart = 2;
            for (int i = 0; i < segs; i++)
            {
                float a = i / (float)segs * Mathf.PI * 2f;
                verts.Add(new Vector3(Mathf.Cos(a) * radius, 0f, Mathf.Sin(a) * radius));
            }
            for (int i = 0; i < segs; i++)
            {
                int cur = ringStart + i;
                int next = ringStart + (i + 1) % segs;
                // Side.
                tris.Add(apex); tris.Add(next); tris.Add(cur);
                // Base.
                tris.Add(baseCenter); tris.Add(cur); tris.Add(next);
            }
            var mesh = new Mesh { name = "EdgeArrow" };
            mesh.SetVertices(verts);
            mesh.SetTriangles(tris, 0);
            mesh.RecalculateNormals();
            mesh.RecalculateBounds();
            return mesh;
        }
    }
}
