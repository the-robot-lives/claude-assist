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
        private Outline _outline;

        public const float DefaultWidth = 220f;
        private const float RowH = 18f;

        public void Init(UmlCanvas canvas, ElementId id, string name, string stereotype, ElementKind kind,
            Color hue, Font font, System.Collections.Generic.List<string> attributes,
            System.Collections.Generic.List<string> operations, Vector2 sizeOverride)
        {
            _canvas = canvas;
            Id = id;
            font_ = font;
            Rt = (RectTransform)transform;
            Rt.anchorMin = Rt.anchorMax = new Vector2(0.5f, 0.5f);
            Rt.pivot = new Vector2(0.5f, 0.5f);

            _bg = gameObject.AddComponent<Image>();
            _bg.color = new Color(0.15f, 0.17f, 0.21f, 1f);

            _outline = gameObject.AddComponent<Outline>();
            _outline.effectColor = new Color(0.30f, 0.85f, 0.95f, 1f);
            _outline.effectDistance = new Vector2(2.5f, 2.5f);
            _outline.enabled = false;

            float stereoH = string.IsNullOrEmpty(stereotype) ? 0f : 16f;
            float headerH = 30f + stereoH;
            float attrH = Mathf.Max(1, attributes.Count) * RowH + 6f;
            float opH = Mathf.Max(1, operations.Count) * RowH + 6f;
            float contentH = headerH + 2f + attrH + 2f + opH;

            float w = sizeOverride.x > 1f ? sizeOverride.x : DefaultWidth;
            float h = Mathf.Max(contentH, sizeOverride.y);
            Rt.sizeDelta = new Vector2(w, h);

            // Header: kind-hue tinted strip with stereotype + name.
            var header = Panel("Header", 0f, headerH, new Color(hue.r * 0.5f, hue.g * 0.5f, hue.b * 0.5f, 1f));
            float ty = -4f;
            if (stereoH > 0f)
            {
                Row(header, stereotype, ty, stereoH, 14, new Color(0.78f, 0.83f, 0.90f, 1f), TextAnchor.MiddleCenter);
                ty -= stereoH;
            }
            var nameRow = Row(header, name, ty, 28f, 18, new Color(0.96f, 0.97f, 1f, 1f), TextAnchor.MiddleCenter);
            nameRow.fontStyle = FontStyle.Bold;

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
                AffordanceTint.Valid => new Color(0.14f, 0.30f, 0.22f, 1f),
                AffordanceTint.Invalid => new Color(0.40f, 0.16f, 0.06f, 1f), // §5.1 vermillion-family
                _ => new Color(0.15f, 0.17f, 0.21f, 1f),
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
            Rt.anchoredPosition += e.delta / _canvas.ScaleFactor;
            _canvas.OnNodeMoved(Id, Rt.anchoredPosition);
        }

        // --- layout helpers ---

        private void AddRows(System.Collections.Generic.List<string> items, ref float y, float compartmentH)
        {
            if (items.Count == 0) { y -= compartmentH; return; }
            float top = y - 3f;
            foreach (var s in items)
            {
                Row(transform, s, top, RowH, 15, new Color(0.86f, 0.89f, 0.94f, 1f), TextAnchor.MiddleLeft);
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
            img.color = new Color(0.30f, 0.34f, 0.40f, 1f);
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

        public void OnDrag(PointerEventData e) => _node.ApplyResize(e.delta / _canvas.ScaleFactor);
    }
}
