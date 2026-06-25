using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// The "this relationship continues on another z-layer" glyph: a small chevron (▲ above / ▼ below) seated at
    /// the far end of a cross-layer stub, where the off-layer endpoint has been culled (UmlCanvas Z-layer view).
    /// Drawn as a procedural triangle Image tinted the link color so it reads as part of the line. Clicking it
    /// jumps the canvas to the layer the hidden endpoint lives on, so the user can "follow" the connector.
    /// </summary>
    public sealed class UmlLayerMarker : MonoBehaviour, IPointerClickHandler
    {
        private UmlCanvas _canvas;
        private int _targetLayer;

        private const float Size = 18f;

        /// <summary>
        /// Build the chevron at <paramref name="pos"/> pointing up (<paramref name="up"/> = the other endpoint is
        /// on a higher layer) or down, tinted <paramref name="color"/>. Clicking jumps to <paramref name="targetLayer"/>.
        /// </summary>
        public void Init(UmlCanvas canvas, Vector2 pos, bool up, Color color, int targetLayer)
        {
            _canvas = canvas;
            _targetLayer = targetLayer;

            var rt = (RectTransform)transform;
            rt.anchorMin = rt.anchorMax = new Vector2(0.5f, 0.5f);
            rt.pivot = new Vector2(0.5f, 0.5f);
            rt.sizeDelta = new Vector2(Size, Size);
            rt.anchoredPosition = pos;
            // The base triangle sprite points +x (apex right); rotate so the apex points up (90°) or down (-90°).
            rt.localEulerAngles = new Vector3(0f, 0f, up ? 90f : -90f);

            var img = gameObject.AddComponent<Image>();
            img.sprite = ChevronSprite();
            img.color = color;
            img.raycastTarget = true; // clickable: jump to the off-layer endpoint's layer
        }

        public void OnPointerClick(PointerEventData e)
        {
            if (_canvas != null) _canvas.GoToLayer(_targetLayer);
        }

        // --- procedural chevron (a filled triangle apex; reused tinted as ▲ / ▼ via rotation) ---

        private static Sprite _chevron;

        private static Sprite ChevronSprite()
        {
            if (_chevron != null) return _chevron;
            const int n = 16;
            var tex = new Texture2D(n, n, TextureFormat.RGBA32, false);
            for (int y = 0; y < n; y++)
                for (int x = 0; x < n; x++)
                {
                    // Triangle pointing +x: apex at right-center, base on the left edge (matches UmlEdgeView).
                    float edge = n * (1f - Mathf.Abs(y - n / 2f) / (n / 2f));
                    tex.SetPixel(x, y, x <= edge ? Color.white : new Color(1, 1, 1, 0));
                }
            tex.Apply();
            _chevron = Sprite.Create(tex, new Rect(0, 0, n, n), new Vector2(0.5f, 0.5f), n);
            return _chevron;
        }
    }
}
