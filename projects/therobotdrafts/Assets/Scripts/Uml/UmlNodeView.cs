using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// A standard-UML classifier box (class / interface / enum / struct) with three compartments —
    /// stereotype+name, attributes (fields), operations (methods) — so members render <em>inside</em> the box,
    /// not as separate nodes. The body drags to move, the right-edge handle drags to draw a relationship
    /// (§4.1), and the bottom-right grip drags to resize. Left-click selects; right-click / ctrl-click opens
    /// the add-member / delete menu (§3.1).
    /// </summary>
    public sealed class UmlNodeView : MonoBehaviour,
        IPointerClickHandler, IBeginDragHandler, IDragHandler,
        IPointerEnterHandler, IPointerExitHandler
    {
        public ElementId Id;
        public RectTransform Rt { get; private set; }

        private UmlCanvas _canvas;
        private CanvasGroup _hotspots; // the four connect handles, revealed on hover
        private Image _bg;
        private Outline _outline;   // selection highlight (toggled)
        private Outline _border;    // permanent thin box border (conventional UML look)
        private Color _baseColor;   // resting body fill, restored after affordance tinting

        public const float DefaultWidth = 220f;
        private const float RowH = 18f;

        public void Init(UmlCanvas canvas, ElementId id, string name, string stereotype, ElementKind kind,
            Color hue, Font font, System.Collections.Generic.List<string> attributes,
            System.Collections.Generic.List<string> operations, string language, Vector2 sizeOverride)
        {
            _canvas = canvas;
            Id = id;
            font_ = font;
            Rt = (RectTransform)transform;
            Rt.anchorMin = Rt.anchorMax = new Vector2(0.5f, 0.5f);
            Rt.pivot = new Vector2(0.5f, 0.5f);

            // Conventional UML look (Rose / Sparx / Visual Paradigm): white-ish body faintly tinted by the
            // kind hue, a thin solid border, and a stronger pastel header band.
            _baseColor = Color.Lerp(hue, Color.white, 0.88f);
            _bg = gameObject.AddComponent<Image>();
            _bg.color = _baseColor;

            // Permanent thin border.
            _border = gameObject.AddComponent<Outline>();
            _border.effectColor = Color.Lerp(hue, new Color(0.25f, 0.27f, 0.32f, 1f), 0.55f);
            _border.effectDistance = new Vector2(1f, 1f);

            // Selection highlight (toggled on top of the border).
            _outline = gameObject.AddComponent<Outline>();
            _outline.effectColor = new Color(0.12f, 0.55f, 0.85f, 1f);
            _outline.effectDistance = new Vector2(2.5f, 2.5f);
            _outline.enabled = false;

            if (kind == ElementKind.Note)
            {
                BuildNote(name, sizeOverride);
            }
            else
            {
                float stereoH = string.IsNullOrEmpty(stereotype) ? 0f : 16f;
                float langH = string.IsNullOrEmpty(language) ? 0f : 14f;
                float headerH = 30f + stereoH + langH;
                float attrH = Mathf.Max(1, attributes.Count) * RowH + 6f;
                float opH = Mathf.Max(1, operations.Count) * RowH + 6f;
                float contentH = headerH + 2f + attrH + 2f + opH;

                float w = sizeOverride.x > 1f ? sizeOverride.x : DefaultWidth;
                float h = Mathf.Max(contentH, sizeOverride.y);
                Rt.sizeDelta = new Vector2(w, h);

                // Header: stronger pastel of the kind hue, with stereotype + bold black name (conventional UML).
                var header = Panel("Header", 0f, headerH, Color.Lerp(hue, Color.white, 0.52f));
                var nameColor = new Color(0.11f, 0.12f, 0.15f, 1f);
                var subColor = new Color(0.30f, 0.32f, 0.38f, 1f);
                float ty = -4f;
                if (stereoH > 0f)
                {
                    Row(header, stereotype, ty, stereoH, 14, subColor, TextAnchor.MiddleCenter);
                    ty -= stereoH;
                }
                var nameRow = Row(header, name, ty, 28f, 18, nameColor, TextAnchor.MiddleCenter);
                nameRow.fontStyle = FontStyle.Bold;
                ty -= 28f;
                if (langH > 0f)
                    Row(header, "{" + language + "}", ty, langH, 12, subColor, TextAnchor.MiddleCenter);

                float y = -headerH;
                Divider(y); y -= 2f;

                // Attributes compartment (fields).
                float ay = y;
                AddRows(attributes, ref ay, attrH);
                y -= attrH;
                Divider(y); y -= 2f;

                // Operations compartment (methods).
                AddRows(operations, ref y, opH);
            }

            // Four connect hotspots (§4.1 quick-handle), one per side — revealed on hover (CanvasGroup), and the
            // link leaves from the side you grab.
            var hotGo = new GameObject("Hotspots", typeof(RectTransform));
            var hotRt = (RectTransform)hotGo.transform;
            hotRt.SetParent(transform, false);
            hotRt.anchorMin = Vector2.zero; hotRt.anchorMax = Vector2.one;
            hotRt.offsetMin = Vector2.zero; hotRt.offsetMax = Vector2.zero;
            _hotspots = hotGo.AddComponent<CanvasGroup>();
            _hotspots.alpha = 0f;
            _hotspots.blocksRaycasts = false;
            foreach (BoxSide side in new[] { BoxSide.Left, BoxSide.Right, BoxSide.Top, BoxSide.Bottom })
            {
                var handleGo = new GameObject("ConnectHandle:" + side, typeof(RectTransform));
                handleGo.AddComponent<UmlConnectHandle>().Init(_canvas, this, side, hotRt);
            }
            // Resize is done by grabbing the box border (see OnBeginDrag) — no separate grip.
        }

        public void OnPointerEnter(PointerEventData e)
        {
            if (_hotspots != null) { _hotspots.alpha = 1f; _hotspots.blocksRaycasts = true; }
        }

        public void OnPointerExit(PointerEventData e)
        {
            if (_hotspots != null) { _hotspots.alpha = 0f; _hotspots.blocksRaycasts = false; }
        }

        public const float BorderGrab = 9f; // px from the edge that begins a resize instead of a move

        public void SetSelected(bool on) { if (_outline != null) _outline.enabled = on; }

        public void SetAffordance(AffordanceTint tint)
        {
            if (_bg == null) return;
            _bg.color = tint switch
            {
                AffordanceTint.Valid => new Color(0.80f, 0.93f, 0.82f, 1f),
                AffordanceTint.Invalid => new Color(0.97f, 0.82f, 0.78f, 1f), // §5.1 vermillion-family (light)
                _ => _baseColor,
            };
        }

        // --- interaction ---

        private bool _resizeL, _resizeR, _resizeT, _resizeB;

        public void OnPointerClick(PointerEventData e)
        {
            bool context = e.button == PointerEventData.InputButton.Right
                           || (e.button == PointerEventData.InputButton.Left && UmlCanvas.CtrlOrCmd());
            if (context) _canvas.ShowNodeMenu(this, e.position);
            else if (e.button == PointerEventData.InputButton.Left) _canvas.Select(this);
        }

        public void OnBeginDrag(PointerEventData e)
        {
            // Grabbing within BorderGrab px of an edge starts a resize on those edges; otherwise it's a move.
            _resizeL = _resizeR = _resizeT = _resizeB = false;
            if (RectTransformUtility.ScreenPointToLocalPointInRectangle(Rt, e.position, e.pressEventCamera, out var lp))
            {
                float hw = Rt.sizeDelta.x * 0.5f, hh = Rt.sizeDelta.y * 0.5f;
                _resizeR = lp.x > hw - BorderGrab;
                _resizeL = lp.x < -hw + BorderGrab;
                _resizeT = lp.y > hh - BorderGrab;
                _resizeB = lp.y < -hh + BorderGrab;
            }
        }

        public void OnDrag(PointerEventData e)
        {
            // Divide by canvas scale AND diagram zoom so geometry tracks the cursor at any zoom level.
            Vector2 d = e.delta / (_canvas.ScaleFactor * _canvas.Zoom);
            if (_resizeL || _resizeR || _resizeT || _resizeB) { ResizeBy(d); return; }
            Rt.anchoredPosition += d;
            _canvas.OnNodeMoved(Id, Rt.anchoredPosition);
        }

        private void ResizeBy(Vector2 d)
        {
            Vector2 size = Rt.sizeDelta, pos = Rt.anchoredPosition;
            if (_resizeR) { size.x += d.x; pos.x += d.x * 0.5f; }
            if (_resizeL) { size.x -= d.x; pos.x += d.x * 0.5f; }
            if (_resizeT) { size.y += d.y; pos.y += d.y * 0.5f; }
            if (_resizeB) { size.y -= d.y; pos.y += d.y * 0.5f; }
            size.x = Mathf.Max(140f, size.x);
            size.y = Mathf.Max(70f, size.y);
            Rt.sizeDelta = size;
            Rt.anchoredPosition = pos;
            _canvas.OnNodeResized(Id, size);
            _canvas.OnNodeMoved(Id, pos);
        }

        // --- layout helpers ---

        private void AddRows(System.Collections.Generic.List<string> items, ref float y, float compartmentH)
        {
            if (items.Count == 0) { y -= compartmentH; return; }
            float top = y - 3f;
            foreach (var s in items)
            {
                Row(transform, s, top, RowH, 15, new Color(0.13f, 0.15f, 0.19f, 1f), TextAnchor.MiddleLeft);
                top -= RowH;
            }
            y -= compartmentH;
        }

        private RectTransform Panel(string name, float topY, float height, Color color)
        {
            var rt = NewChild(name, transform);
            rt.anchorMin = new Vector2(0f, 1f); rt.anchorMax = new Vector2(1f, 1f);
            rt.pivot = new Vector2(0.5f, 1f);
            rt.sizeDelta = new Vector2(0f, height);
            rt.anchoredPosition = new Vector2(0f, topY);
            var img = rt.gameObject.AddComponent<Image>();
            img.color = color;
            img.raycastTarget = false;
            return rt;
        }

        private void Divider(float y)
        {
            var rt = NewChild("Divider", transform);
            rt.anchorMin = new Vector2(0f, 1f); rt.anchorMax = new Vector2(1f, 1f);
            rt.pivot = new Vector2(0.5f, 1f);
            rt.sizeDelta = new Vector2(0f, 2f);
            rt.anchoredPosition = new Vector2(0f, y);
            var img = rt.gameObject.AddComponent<Image>();
            img.color = new Color(0.66f, 0.68f, 0.73f, 1f);
            img.raycastTarget = false;
        }

        private Text Row(Transform parent, string text, float topY, float height, int fontSize,
            Color color, TextAnchor align)
        {
            var rt = NewChild("Row", parent);
            rt.anchorMin = new Vector2(0f, 1f); rt.anchorMax = new Vector2(1f, 1f);
            rt.pivot = new Vector2(0.5f, 1f);
            rt.sizeDelta = new Vector2(-20f, height);
            rt.anchoredPosition = new Vector2(0f, topY);
            var t = rt.gameObject.AddComponent<Text>();
            t.font = font_ ?? (font_ = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf"));
            t.text = text;
            t.fontSize = fontSize;
            t.color = color;
            t.alignment = align;
            t.supportRichText = false;
            t.raycastTarget = false;
            t.horizontalOverflow = HorizontalWrapMode.Overflow;
            t.verticalOverflow = VerticalWrapMode.Overflow;
            return t;
        }

        // --- note (comment) rendering ---

        private void BuildNote(string text, Vector2 sizeOverride)
        {
            var noteBody = new Color(0.99f, 0.96f, 0.74f, 1f);
            _baseColor = noteBody;
            if (_bg != null) _bg.color = noteBody;
            if (_border != null) _border.effectColor = new Color(0.78f, 0.70f, 0.40f, 1f);

            float w = sizeOverride.x > 1f ? sizeOverride.x : 220f;
            float h = sizeOverride.y > 1f ? sizeOverride.y : 96f;
            Rt.sizeDelta = new Vector2(w, h);

            // Dog-eared (folded) top-right corner.
            const float fold = 16f;
            var foldRt = NewChild("Fold", transform);
            foldRt.anchorMin = foldRt.anchorMax = new Vector2(1f, 1f);
            foldRt.pivot = new Vector2(1f, 1f);
            foldRt.sizeDelta = new Vector2(fold, fold);
            foldRt.anchoredPosition = Vector2.zero;
            var foldImg = foldRt.gameObject.AddComponent<Image>();
            foldImg.sprite = CornerFoldSprite();
            foldImg.color = new Color(0.90f, 0.84f, 0.55f, 1f);
            foldImg.raycastTarget = false;

            // Free wrapped text filling the box (with padding).
            var bodyRt = NewChild("NoteText", transform);
            bodyRt.anchorMin = Vector2.zero; bodyRt.anchorMax = Vector2.one;
            bodyRt.offsetMin = new Vector2(8f, 6f); bodyRt.offsetMax = new Vector2(-8f, -6f);
            var t = bodyRt.gameObject.AddComponent<Text>();
            t.font = font_ ?? (font_ = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf"));
            t.text = text;
            t.fontSize = 15;
            t.color = new Color(0.16f, 0.15f, 0.06f, 1f);
            t.alignment = TextAnchor.UpperLeft;
            t.supportRichText = false;
            t.raycastTarget = false;
            t.horizontalOverflow = HorizontalWrapMode.Wrap;
            t.verticalOverflow = VerticalWrapMode.Overflow;
        }

        private static Sprite _foldSprite;
        private static Sprite CornerFoldSprite()
        {
            if (_foldSprite != null) return _foldSprite;
            const int n = 16;
            var tex = new Texture2D(n, n, TextureFormat.RGBA32, false) { filterMode = FilterMode.Point };
            for (int y = 0; y < n; y++)
                for (int x = 0; x < n; x++)
                    tex.SetPixel(x, y, (x + y) <= n ? Color.white : new Color(1, 1, 1, 0));
            tex.Apply();
            _foldSprite = Sprite.Create(tex, new Rect(0, 0, n, n), new Vector2(0.5f, 0.5f), n);
            return _foldSprite;
        }

        private Font font_;

        private static RectTransform NewChild(string name, Transform parent)
        {
            var go = new GameObject(name, typeof(RectTransform));
            var rt = (RectTransform)go.transform;
            rt.SetParent(parent, false);
            return rt;
        }
    }

    public enum AffordanceTint { None, Valid, Invalid }

    /// <summary>The four box sides a relationship can attach to / leave from.</summary>
    public enum BoxSide { Left, Right, Top, Bottom }

    /// <summary>A per-side connect hotspot: drag from it to start a relationship that leaves from that side.</summary>
    public sealed class UmlConnectHandle : MonoBehaviour,
        IBeginDragHandler, IDragHandler, IEndDragHandler
    {
        private UmlCanvas _canvas;
        private UmlNodeView _node;
        private BoxSide _side;

        public void Init(UmlCanvas canvas, UmlNodeView node, BoxSide side, Transform parent)
        {
            _canvas = canvas; _node = node; _side = side;
            var rt = (RectTransform)transform;
            rt.SetParent(parent, false);
            rt.pivot = new Vector2(0.5f, 0.5f);
            rt.sizeDelta = new Vector2(15f, 15f);
            switch (side)
            {
                case BoxSide.Left:   rt.anchorMin = rt.anchorMax = new Vector2(0f, 0.5f); rt.anchoredPosition = new Vector2(2f, 0f); break;
                case BoxSide.Right:  rt.anchorMin = rt.anchorMax = new Vector2(1f, 0.5f); rt.anchoredPosition = new Vector2(-2f, 0f); break;
                case BoxSide.Top:    rt.anchorMin = rt.anchorMax = new Vector2(0.5f, 1f); rt.anchoredPosition = new Vector2(0f, -2f); break;
                default:             rt.anchorMin = rt.anchorMax = new Vector2(0.5f, 0f); rt.anchoredPosition = new Vector2(0f, 2f); break;
            }
            gameObject.AddComponent<Image>().color = new Color(0.30f, 0.85f, 0.95f, 1f);
        }

        public void OnBeginDrag(PointerEventData e) => _canvas.BeginLink(_node, _side, e.position);
        public void OnDrag(PointerEventData e) => _canvas.UpdateLink(e.position);
        public void OnEndDrag(PointerEventData e) => _canvas.EndLink(e.position);
    }
}
