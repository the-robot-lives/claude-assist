using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Uml
{
    /// <summary>End decoration for a relationship line, in standard UML notation.</summary>
    public enum EndMarker { None, OpenArrow, HollowTriangle, HollowDiamond, FilledDiamond }

    /// <summary>
    /// A standard-UML relationship line between two class boxes: solid or dashed, with the correct end
    /// markers (open arrow, hollow inheritance triangle, hollow/filled aggregation-composition diamond) and a
    /// type label. Endpoints are clipped to the box borders by the canvas so the arrow touches the edge.
    /// Clicking re-types or deletes the link (§4.6).
    /// </summary>
    public sealed class UmlEdgeView : MonoBehaviour, IPointerClickHandler
    {
        public EdgeId Edge;
        public bool Interactive = true;

        private RectTransform _line;
        private Image _lineImg;
        private RectTransform _srcM, _tgtM;
        private RectTransform _midRt, _srcMultRt, _tgtMultRt;
        private System.Action<UmlEdgeView, Vector2> _onClick;

        private const float Thickness = 3f;
        private const float MarkerSize = 16f;

        public void Init(Font font, Color color, string midLabel, string sourceMult, string targetMult,
            bool dashed, EndMarker source, EndMarker target, System.Action<UmlEdgeView, Vector2> onClick)
        {
            var self = (RectTransform)transform;
            Stretch(self);
            _onClick = onClick;

            _line = NewChild("Line");
            _lineImg = _line.gameObject.AddComponent<Image>();
            _lineImg.color = color;
            _lineImg.raycastTarget = Interactive;
            if (dashed)
            {
                _lineImg.sprite = DashSprite();
                _lineImg.type = Image.Type.Tiled;
            }

            _srcM = BuildMarker("SrcMarker", source, color);
            _tgtM = BuildMarker("TgtMarker", target, color);

            // Midpoint association name / role label, and per-end multiplicities (e.g. "1", "0..*").
            _midRt = BuildText("Label", midLabel, font, new Color(0.18f, 0.20f, 0.26f, 1f), 15, 170f);
            _srcMultRt = BuildText("SrcMult", sourceMult, font, new Color(0.22f, 0.24f, 0.30f, 1f), 14, 56f);
            _tgtMultRt = BuildText("TgtMult", targetMult, font, new Color(0.22f, 0.24f, 0.30f, 1f), 14, 56f);
        }

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

        public void SetEndpoints(Vector2 a, Vector2 b)
        {
            Vector2 d = b - a;
            float len = d.magnitude;
            float ang = Mathf.Atan2(d.y, d.x) * Mathf.Rad2Deg;
            Vector2 dir = len > 0.001f ? d / len : Vector2.right;
            Vector2 perp = new Vector2(-dir.y, dir.x);

            _line.anchoredPosition = (a + b) * 0.5f;
            _line.sizeDelta = new Vector2(Mathf.Max(len, 1f), Thickness);
            _line.localEulerAngles = new Vector3(0f, 0f, ang);

            const float half = MarkerSize * 0.5f;
            if (_srcM != null)
            {
                // Seat the diamond just outside the source border; point its axis back toward the source.
                _srcM.anchoredPosition = a + dir * half;
                _srcM.localEulerAngles = new Vector3(0f, 0f, ang + 180f);
            }
            if (_tgtM != null)
            {
                // Seat the arrow/triangle so its apex touches the target border.
                _tgtM.anchoredPosition = b - dir * half;
                _tgtM.localEulerAngles = new Vector3(0f, 0f, ang);
            }

            if (_midRt != null) _midRt.anchoredPosition = (a + b) * 0.5f + perp * 14f;
            if (_srcMultRt != null) _srcMultRt.anchoredPosition = a + dir * 26f + perp * 12f;
            if (_tgtMultRt != null) _tgtMultRt.anchoredPosition = b - dir * 26f + perp * 12f;
        }

        public void OnPointerClick(PointerEventData eventData)
        {
            if (Interactive) _onClick?.Invoke(this, eventData.position);
        }

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
            var tex = new Texture2D(8, 1, TextureFormat.RGBA32, false) { wrapMode = TextureWrapMode.Repeat };
            for (int x = 0; x < 8; x++)
                tex.SetPixel(x, 0, x < 4 ? Color.white : new Color(1, 1, 1, 0));
            tex.Apply();
            _dash = Sprite.Create(tex, new Rect(0, 0, 8, 1), new Vector2(0.5f, 0.5f), 8f);
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

        // --- helpers ---

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
}
