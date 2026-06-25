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
        IPointerClickHandler, IBeginDragHandler, IDragHandler
    {
        public ElementId Id;
        public RectTransform Rt { get; private set; }

        private UmlCanvas _canvas;
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

            // Right-edge connect handle (§4.1 quick-handle).
            var handleGo = new GameObject("ConnectHandle", typeof(RectTransform));
            handleGo.AddComponent<UmlConnectHandle>().Init(_canvas, this);

            // Bottom-right resize grip.
            var gripGo = new GameObject("ResizeGrip", typeof(RectTransform));
            gripGo.AddComponent<UmlResizeHandle>().Init(_canvas, this);
        }

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

        public void ApplyResize(Vector2 delta)
        {
            var s = Rt.sizeDelta + new Vector2(delta.x, -delta.y);
            s.x = Mathf.Max(140f, s.x);
            s.y = Mathf.Max(70f, s.y);
            Rt.sizeDelta = s;
            _canvas.OnNodeResized(Id, s);
        }

        // --- interaction ---

        public void OnPointerClick(PointerEventData e)
        {
            bool context = e.button == PointerEventData.InputButton.Right
                           || (e.button == PointerEventData.InputButton.Left && UmlCanvas.CtrlOrCmd());
            if (context) _canvas.ShowNodeMenu(this, e.position);
            else if (e.button == PointerEventData.InputButton.Left) _canvas.Select(this);
        }

        public void OnBeginDrag(PointerEventData e) { }

        public void OnDrag(PointerEventData e)
        {
            // Divide by canvas scale AND diagram zoom so the box tracks the cursor at any zoom level.
            Rt.anchoredPosition += e.delta / (_canvas.ScaleFactor * _canvas.Zoom);
            _canvas.OnNodeMoved(Id, Rt.anchoredPosition);
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

    /// <summary>Right-edge grip: drag to start a relationship (its drag takes priority over body-move).</summary>
    public sealed class UmlConnectHandle : MonoBehaviour,
        IBeginDragHandler, IDragHandler, IEndDragHandler
    {
        private UmlCanvas _canvas;
        private UmlNodeView _node;

        public void Init(UmlCanvas canvas, UmlNodeView node)
        {
            _canvas = canvas; _node = node;
            var rt = (RectTransform)transform;
            rt.SetParent(node.transform, false);
            rt.anchorMin = rt.anchorMax = new Vector2(1f, 0.5f);
            rt.pivot = new Vector2(0.5f, 0.5f);
            rt.sizeDelta = new Vector2(20f, 20f);
            rt.anchoredPosition = new Vector2(-2f, 0f);
            gameObject.AddComponent<Image>().color = new Color(0.30f, 0.85f, 0.95f, 1f);
        }

        public void OnBeginDrag(PointerEventData e) => _canvas.BeginLink(_node, e.position);
        public void OnDrag(PointerEventData e) => _canvas.UpdateLink(e.position);
        public void OnEndDrag(PointerEventData e) => _canvas.EndLink(e.position);
    }

    /// <summary>Bottom-right grip: drag to resize the box.</summary>
    public sealed class UmlResizeHandle : MonoBehaviour, IDragHandler
    {
        private UmlCanvas _canvas;
        private UmlNodeView _node;

        public void Init(UmlCanvas canvas, UmlNodeView node)
        {
            _canvas = canvas; _node = node;
            var rt = (RectTransform)transform;
            rt.SetParent(node.transform, false);
            rt.anchorMin = rt.anchorMax = new Vector2(1f, 0f);
            rt.pivot = new Vector2(1f, 0f);
            rt.sizeDelta = new Vector2(16f, 16f);
            rt.anchoredPosition = Vector2.zero;
            gameObject.AddComponent<Image>().color = new Color(0.45f, 0.50f, 0.58f, 1f);
        }

        public void OnDrag(PointerEventData e) => _node.ApplyResize(e.delta / (_canvas.ScaleFactor * _canvas.Zoom));
    }
}
