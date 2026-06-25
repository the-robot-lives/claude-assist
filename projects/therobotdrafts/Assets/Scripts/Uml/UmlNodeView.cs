using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// A visual UML element box (the 2D desktop stand-in for a bubble). Shows the kind hue (§2.1) as an accent
    /// bar plus the name and kind. The body drags to reposition; a connect handle on the right edge drags to
    /// start a relationship (authoring-ux.md §4.1 quick-handle). Left-click selects; right-click / ctrl-click
    /// opens the add/delete context menu.
    /// </summary>
    public sealed class UmlNodeView : MonoBehaviour,
        IPointerClickHandler, IBeginDragHandler, IDragHandler
    {
        public ElementId Id;
        public RectTransform Rt { get; private set; }

        private UmlCanvas _canvas;
        private Image _bg;
        private Image _selRim;
        private Text _nameText;

        public static readonly Vector2 Size = new Vector2(176f, 64f);

        public void Init(UmlCanvas canvas, ElementId id, string name, ElementKind kind, Color hue, Font font)
        {
            _canvas = canvas;
            Id = id;
            Rt = GetComponent<RectTransform>();
            Rt.anchorMin = Rt.anchorMax = new Vector2(0.5f, 0.5f);
            Rt.pivot = new Vector2(0.5f, 0.5f);
            Rt.sizeDelta = Size;

            // Selection rim (reserved UI channel §5.1: white→cyan), sits just behind the body.
            var rimGo = new GameObject("SelRim");
            _selRim = rimGo.AddComponent<Image>();
            var rimRt = rimGo.GetComponent<RectTransform>();
            rimRt.SetParent(transform, false);
            rimRt.anchorMin = Vector2.zero; rimRt.anchorMax = Vector2.one;
            rimRt.offsetMin = new Vector2(-3f, -3f); rimRt.offsetMax = new Vector2(3f, 3f);
            _selRim.color = new Color(0.30f, 0.85f, 0.95f, 1f);
            _selRim.raycastTarget = false;
            _selRim.enabled = false;

            _bg = gameObject.AddComponent<Image>();
            _bg.color = new Color(0.16f, 0.18f, 0.22f, 1f);

            // Kind accent bar (left edge), colored by the §2.1 kind hue.
            var bar = NewChild("Accent", transform);
            var barImg = bar.gameObject.AddComponent<Image>();
            barImg.color = hue;
            barImg.raycastTarget = false;
            bar.anchorMin = new Vector2(0f, 0f); bar.anchorMax = new Vector2(0f, 1f);
            bar.pivot = new Vector2(0f, 0.5f);
            bar.sizeDelta = new Vector2(8f, 0f);
            bar.anchoredPosition = Vector2.zero;

            // Name label.
            var nameGo = NewChild("Name", transform);
            _nameText = nameGo.gameObject.AddComponent<Text>();
            _nameText.font = font;
            _nameText.fontSize = 20;
            _nameText.color = new Color(0.93f, 0.95f, 0.99f, 1f);
            _nameText.alignment = TextAnchor.MiddleLeft;
            _nameText.supportRichText = false;
            _nameText.raycastTarget = false;
            nameGo.anchorMin = Vector2.zero; nameGo.anchorMax = Vector2.one;
            nameGo.offsetMin = new Vector2(18f, 22f); nameGo.offsetMax = new Vector2(-26f, -6f);

            // Kind sublabel.
            var kindGo = NewChild("Kind", transform);
            var kindText = kindGo.gameObject.AddComponent<Text>();
            kindText.font = font;
            kindText.fontSize = 14;
            kindText.color = new Color(0.60f, 0.66f, 0.76f, 1f);
            kindText.alignment = TextAnchor.LowerLeft;
            kindText.text = kind.ToString().ToLowerInvariant();
            kindText.supportRichText = false;
            kindText.raycastTarget = false;
            kindGo.anchorMin = Vector2.zero; kindGo.anchorMax = Vector2.one;
            kindGo.offsetMin = new Vector2(18f, 6f); kindGo.offsetMax = new Vector2(-26f, -34f);

            // Connect handle on the right edge (the §4.1 quick-handle).
            var handleGo = new GameObject("ConnectHandle");
            var handle = handleGo.AddComponent<UmlConnectHandle>();
            handle.Init(_canvas, this, hue);
        }

        public void SetName(string name) { if (_nameText != null) _nameText.text = name; }
        public void SetSelected(bool on) { if (_selRim != null) _selRim.enabled = on; }

        public void SetAffordance(AffordanceTint tint)
        {
            if (_bg == null) return;
            _bg.color = tint switch
            {
                AffordanceTint.Valid => new Color(0.14f, 0.30f, 0.22f, 1f),
                AffordanceTint.Invalid => new Color(0.40f, 0.16f, 0.06f, 1f), // §5.1 vermillion-family
                _ => new Color(0.16f, 0.18f, 0.22f, 1f),
            };
        }

        // --- interaction ---

        public void OnPointerClick(PointerEventData e)
        {
            bool context = e.button == PointerEventData.InputButton.Right
                           || (e.button == PointerEventData.InputButton.Left && UmlCanvas.CtrlOrCmd());
            if (context) _canvas.ShowNodeMenu(this, e.position);
            else if (e.button == PointerEventData.InputButton.Left) _canvas.Select(this);
        }

        public void OnBeginDrag(PointerEventData e) { /* body move begins; nothing to capture */ }

        public void OnDrag(PointerEventData e)
        {
            // Move the node (the demo harness owns 2D position; the real packer owns 3D, ADR-003).
            Rt.anchoredPosition += e.delta / _canvas.ScaleFactor;
            _canvas.OnNodeMoved(Id, Rt.anchoredPosition);
        }

        private static RectTransform NewChild(string name, Transform parent)
        {
            var go = new GameObject(name);
            var rt = go.AddComponent<RectTransform>();
            rt.SetParent(parent, false);
            return rt;
        }
    }

    public enum AffordanceTint { None, Valid, Invalid }

    /// <summary>
    /// The right-edge connect grip. Dragging it starts a relationship rubber-band from the owning node; on
    /// release the canvas resolves the target and opens the §4.2 type picker. Separate object so its drag
    /// takes priority over the node's body-move drag.
    /// </summary>
    public sealed class UmlConnectHandle : MonoBehaviour,
        IBeginDragHandler, IDragHandler, IEndDragHandler
    {
        private UmlCanvas _canvas;
        private UmlNodeView _node;

        public void Init(UmlCanvas canvas, UmlNodeView node, Color hue)
        {
            _canvas = canvas;
            _node = node;
            var rt = gameObject.AddComponent<RectTransform>();
            rt.SetParent(node.transform, false);
            rt.anchorMin = rt.anchorMax = new Vector2(1f, 0.5f);
            rt.pivot = new Vector2(0.5f, 0.5f);
            rt.sizeDelta = new Vector2(22f, 22f);
            rt.anchoredPosition = new Vector2(-2f, 0f);

            var img = gameObject.AddComponent<Image>();
            img.color = new Color(0.30f, 0.85f, 0.95f, 1f);
        }

        public void OnBeginDrag(PointerEventData e) => _canvas.BeginLink(_node, e.position);
        public void OnDrag(PointerEventData e) => _canvas.UpdateLink(e.position);
        public void OnEndDrag(PointerEventData e) => _canvas.EndLink(e.position);
    }
}
