using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Uml
{
    /// <summary>End decoration for a relationship line, in standard UML notation.</summary>
    public enum EndMarker { None, OpenArrow, HollowTriangle, HollowDiamond, FilledDiamond }

    /// <summary>
    /// A standard-UML relationship drawn as an orthogonal (right-angle) polyline between two class boxes:
    /// solid or dashed, with the correct end markers (open arrow, hollow inheritance triangle, hollow/filled
    /// aggregation-composition diamond), a midpoint association label, and per-end multiplicities. The route is
    /// a list of points the canvas computes (auto-routed or via user bend handles); this view just draws one
    /// segment rect per leg and seats the markers/labels along the first and last legs. Left-click selects
    /// (the canvas shows bend handles); right-click / ctrl-click re-types, adorns, or deletes (§4.6).
    /// </summary>
    public sealed class UmlEdgeView : MonoBehaviour, IPointerClickHandler
    {
        public EdgeId Edge;
        public bool Interactive = true;

        private UmlCanvas _canvas;
        private readonly List<RectTransform> _segments = new();
        private readonly List<Image> _segImgs = new();
        private RectTransform _srcM, _tgtM;
        private RectTransform _midRt, _srcMultRt, _tgtMultRt;
        private Color _color;
        private bool _dashed;

        private const float Thickness = 3f;
        private const float MarkerSize = 16f;

        public void Init(UmlCanvas canvas, Font font, Color color, string midLabel, string sourceMult,
            string targetMult, bool dashed, EndMarker source, EndMarker target)
        {
            _canvas = canvas;
            _color = color;
            _dashed = dashed;
            Stretch((RectTransform)transform);

            _srcM = BuildMarker("SrcMarker", source, color);
            _tgtM = BuildMarker("TgtMarker", target, color);

            // Midpoint association name / role label, and per-end multiplicities (e.g. "1", "0..*").
            _midRt = BuildText("Label", midLabel, font, new Color(0.18f, 0.20f, 0.26f, 1f), 15, 170f);
            _srcMultRt = BuildText("SrcMult", sourceMult, font, new Color(0.22f, 0.24f, 0.30f, 1f), 14, 56f);
            _tgtMultRt = BuildText("TgtMult", targetMult, font, new Color(0.22f, 0.24f, 0.30f, 1f), 14, 56f);
        }

        /// <summary>Draw the relationship along an orthogonal polyline of at least two points.</summary>
        public void SetRoute(IReadOnlyList<Vector2> pts)
        {
            if (pts == null || pts.Count < 2) return;
            int segCount = pts.Count - 1;
            EnsureSegments(segCount);
            for (int i = 0; i < _segments.Count; i++)
            {
                bool used = i < segCount;
                if (_segments[i].gameObject.activeSelf != used) _segments[i].gameObject.SetActive(used);
                if (used) PlaceSeg(_segments[i], pts[i], pts[i + 1]);
            }

            Vector2 a = pts[0], a1 = pts[1];
            Vector2 b = pts[pts.Count - 1], b0 = pts[pts.Count - 2];
            Vector2 dirA = Norm(a1 - a), dirB = Norm(b - b0);
            const float half = MarkerSize * 0.5f;
            if (_srcM != null)
            {
                _srcM.anchoredPosition = a + dirA * half;
                _srcM.localEulerAngles = new Vector3(0f, 0f, Ang(dirA) + 180f);
            }
            if (_tgtM != null)
            {
                _tgtM.anchoredPosition = b - dirB * half;
                _tgtM.localEulerAngles = new Vector3(0f, 0f, Ang(dirB));
            }

            Vector2 perpA = new Vector2(-dirA.y, dirA.x), perpB = new Vector2(-dirB.y, dirB.x);
            if (_srcMultRt != null) _srcMultRt.anchoredPosition = a + dirA * 26f + perpA * 12f;
            if (_tgtMultRt != null) _tgtMultRt.anchoredPosition = b - dirB * 26f + perpB * 12f;
            if (_midRt != null)
            {
                int k = segCount / 2;
                Vector2 p = pts[k], q = pts[k + 1];
                Vector2 dir = Norm(q - p), perp = new Vector2(-dir.y, dir.x);
                _midRt.anchoredPosition = (p + q) * 0.5f + perp * 14f;
            }
        }

        /// <summary>Tint the line when the edge is the selection (its bend handles are live).</summary>
        public void SetHighlighted(bool on)
        {
            var c = on ? new Color(0.12f, 0.55f, 0.85f, 1f) : _color;
            foreach (var img in _segImgs) if (img != null) img.color = c;
        }

        public void OnPointerClick(PointerEventData eventData)
        {
            if (Interactive && _canvas != null) _canvas.OnEdgePointerClick(this, eventData);
        }

        // --- segments ---

        private void EnsureSegments(int count)
        {
            while (_segments.Count < count)
            {
                var rt = NewChild("Seg");
                var img = rt.gameObject.AddComponent<Image>();
                img.color = _color;
                img.raycastTarget = Interactive;
                if (_dashed) { img.sprite = DashSprite(); img.type = Image.Type.Tiled; }
                _segments.Add(rt);
                _segImgs.Add(img);
            }
        }

        private void PlaceSeg(RectTransform seg, Vector2 p, Vector2 q)
        {
            Vector2 d = q - p;
            float len = d.magnitude;
            seg.anchoredPosition = (p + q) * 0.5f;
            seg.sizeDelta = new Vector2(Mathf.Max(len, 1f), Thickness);
            seg.localEulerAngles = new Vector3(0f, 0f, Mathf.Atan2(d.y, d.x) * Mathf.Rad2Deg);
        }

        private static Vector2 Norm(Vector2 v) { float m = v.magnitude; return m > 0.001f ? v / m : Vector2.right; }
        private static float Ang(Vector2 d) => Mathf.Atan2(d.y, d.x) * Mathf.Rad2Deg;

        // --- markers ---

        private RectTransform BuildMarker(string name, EndMarker marker, Color color)
        {
            if (marker == EndMarker.None) return null;
            var rt = NewChild(name);
            rt.sizeDelta = new Vector2(MarkerSize, MarkerSize);
            var img = rt.gameObject.AddComponent<Image>();
            img.raycastTarget = false;

            switch (marker)
            {
                case EndMarker.OpenArrow:
                    img.sprite = TriangleSprite(); img.color = color; break;
                case EndMarker.HollowTriangle:
                    img.sprite = TriangleSprite(); img.color = new Color(0.95f, 0.96f, 0.97f, 1f);
                    AddOutline(rt.gameObject, color); break;
                case EndMarker.FilledDiamond:
                    img.sprite = DiamondSprite(); img.color = color; break;
                case EndMarker.HollowDiamond:
                    img.sprite = DiamondSprite(); img.color = new Color(0.95f, 0.96f, 0.97f, 1f);
                    AddOutline(rt.gameObject, color); break;
            }
            return rt;
        }

        private static void AddOutline(GameObject go, Color color)
        {
            var o = go.AddComponent<Outline>();
            o.effectColor = color;
            o.effectDistance = new Vector2(1.4f, 1.4f);
        }

        // --- procedural sprites (reliable across fonts; no glyph dependency) ---

        private static Sprite _dash, _triangle, _diamond;

        private static Sprite DashSprite()
        {
            if (_dash != null) return _dash;
            // 6px period (3 on / 3 off) at 100 ppu → fine dashes (the old 8ppu sprite tiled ~100px: far too coarse).
            var tex = new Texture2D(6, 1, TextureFormat.RGBA32, false)
                { wrapMode = TextureWrapMode.Repeat, filterMode = FilterMode.Point };
            for (int x = 0; x < 6; x++)
                tex.SetPixel(x, 0, x < 3 ? Color.white : new Color(1, 1, 1, 0));
            tex.Apply();
            _dash = Sprite.Create(tex, new Rect(0, 0, 6, 1), new Vector2(0.5f, 0.5f), 100f);
            return _dash;
        }

        private static Sprite TriangleSprite()
        {
            if (_triangle != null) return _triangle;
            const int n = 16;
            var tex = new Texture2D(n, n, TextureFormat.RGBA32, false);
            for (int y = 0; y < n; y++)
                for (int x = 0; x < n; x++)
                {
                    // Triangle pointing +x: apex at right-center, base on the left edge.
                    float edge = n * (1f - Mathf.Abs(y - n / 2f) / (n / 2f));
                    tex.SetPixel(x, y, x <= edge ? Color.white : new Color(1, 1, 1, 0));
                }
            tex.Apply();
            _triangle = Sprite.Create(tex, new Rect(0, 0, n, n), new Vector2(0.5f, 0.5f), n);
            return _triangle;
        }

        private static Sprite DiamondSprite()
        {
            if (_diamond != null) return _diamond;
            const int n = 16;
            var tex = new Texture2D(n, n, TextureFormat.RGBA32, false);
            for (int y = 0; y < n; y++)
                for (int x = 0; x < n; x++)
                {
                    float m = Mathf.Abs(x - n / 2f) / (n / 2f) + Mathf.Abs(y - n / 2f) / (n / 2f);
                    tex.SetPixel(x, y, m <= 1f ? Color.white : new Color(1, 1, 1, 0));
                }
            tex.Apply();
            _diamond = Sprite.Create(tex, new Rect(0, 0, n, n), new Vector2(0.5f, 0.5f), n);
            return _diamond;
        }

        // --- text + helpers ---

        private RectTransform BuildText(string name, string text, Font font, Color color, int size, float width)
        {
            if (string.IsNullOrEmpty(text)) return null;
            var rt = NewChild(name);
            rt.sizeDelta = new Vector2(width, 22f);
            var t = rt.gameObject.AddComponent<Text>();
            t.font = font;
            t.text = text;
            t.fontSize = size;
            t.alignment = TextAnchor.MiddleCenter;
            t.color = color;
            t.supportRichText = false;
            t.horizontalOverflow = HorizontalWrapMode.Overflow;
            t.verticalOverflow = VerticalWrapMode.Overflow;
            t.raycastTarget = false;
            return rt;
        }

        private RectTransform NewChild(string name)
        {
            var go = new GameObject(name, typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(transform, false);
            rt.anchorMin = rt.anchorMax = new Vector2(0.5f, 0.5f);
            rt.pivot = new Vector2(0.5f, 0.5f);
            return rt;
        }

        private static void Stretch(RectTransform rt)
        {
            rt.anchorMin = Vector2.zero; rt.anchorMax = Vector2.one;
            rt.offsetMin = Vector2.zero; rt.offsetMax = Vector2.zero;
        }
    }

    /// <summary>What an edge handle controls: a pinned endpoint, a movable bend, or an "insert bend here" spot.</summary>
    public enum UmlHandleKind { EndpointStart, EndpointEnd, Vertex, Add }

    /// <summary>
    /// A handle on the selected relationship. Endpoint handles re-pin where the line meets a box (drag anywhere on
    /// its border); Vertex handles move a bend (drag) or delete it (right-click); Add handles insert a new bend at
    /// a segment midpoint (click). The canvas owns the geometry; this relays the gesture.
    /// </summary>
    public sealed class UmlEdgeHandle : MonoBehaviour,
        IBeginDragHandler, IDragHandler, IEndDragHandler, IPointerClickHandler
    {
        private UmlCanvas _canvas;
        private EdgeId _edge;
        public UmlHandleKind Kind { get; private set; }
        public int Index { get; private set; }

        public void Init(UmlCanvas canvas, EdgeId edge, UmlHandleKind kind, int index, float size, Color color)
        {
            _canvas = canvas; _edge = edge; Kind = kind; Index = index;
            var rt = (RectTransform)transform;
            rt.anchorMin = rt.anchorMax = new Vector2(0.5f, 0.5f);
            rt.pivot = new Vector2(0.5f, 0.5f);
            rt.sizeDelta = new Vector2(size, size);
            gameObject.AddComponent<Image>().color = color;
        }

        public void SetPosition(Vector2 p) => ((RectTransform)transform).anchoredPosition = p;

        private bool Draggable => Kind != UmlHandleKind.Add;

        public void OnBeginDrag(PointerEventData e)
        {
            if (Draggable) _canvas.BeginEdgeHandleDrag(_edge, Kind, Index);
        }

        public void OnDrag(PointerEventData e)
        {
            if (Draggable) _canvas.DragEdgeHandle(e.position);
        }

        public void OnEndDrag(PointerEventData e)
        {
            if (Draggable) _canvas.EndEdgeHandleDrag();
        }

        public void OnPointerClick(PointerEventData e)
        {
            if (Kind == UmlHandleKind.Add) _canvas.AddVertex(_edge, Index);
            else if (Kind == UmlHandleKind.Vertex && e.button == PointerEventData.InputButton.Right)
                _canvas.DeleteVertex(_edge, Index);
        }
    }
}
