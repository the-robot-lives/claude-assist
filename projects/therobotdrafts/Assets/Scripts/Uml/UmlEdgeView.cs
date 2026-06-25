using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// A visual relationship line between two node centers, with an arrow tick + type label. Clicking it asks
    /// the canvas to re-type the edge (authoring-ux.md §4.6). Containment connectors reuse this view with a
    /// muted style and no label.
    /// </summary>
    public sealed class UmlEdgeView : MonoBehaviour, IPointerClickHandler
    {
        public EdgeId Edge;
        public bool IsContainment;

        private RectTransform _rt;
        private RectTransform _label;
        private Text _labelText;
        private System.Action<UmlEdgeView, Vector2> _onClick;

        private const float Thickness = 4f;

        public void Init(Font font, Color color, string label, System.Action<UmlEdgeView, Vector2> onClick)
        {
            _rt = GetComponent<RectTransform>();
            _rt.anchorMin = _rt.anchorMax = new Vector2(0.5f, 0.5f);
            _rt.pivot = new Vector2(0.5f, 0.5f);

            var img = gameObject.GetComponent<Image>() ?? gameObject.AddComponent<Image>();
            img.color = color;
            img.raycastTarget = !IsContainment; // containment lines are not clickable
            _onClick = onClick;

            if (!string.IsNullOrEmpty(label))
            {
                var labelGo = new GameObject("Label");
                _label = labelGo.AddComponent<RectTransform>();
                _label.SetParent(transform, false);
                _label.anchorMin = _label.anchorMax = new Vector2(0.5f, 0.5f);
                _label.pivot = new Vector2(0.5f, 0.5f);
                _label.sizeDelta = new Vector2(180f, 26f);
                _label.localPosition = new Vector3(0f, 14f, 0f);

                _labelText = labelGo.AddComponent<Text>();
                _labelText.font = font;
                _labelText.text = label;
                _labelText.fontSize = 16;
                _labelText.alignment = TextAnchor.MiddleCenter;
                _labelText.color = color;
                _labelText.supportRichText = false;
                _labelText.horizontalOverflow = HorizontalWrapMode.Overflow;
                _labelText.verticalOverflow = VerticalWrapMode.Overflow;
                _labelText.raycastTarget = false;
            }
        }

        /// <summary>Position/size/rotate the line so it spans <paramref name="a"/>→<paramref name="b"/> (layer-local coords).</summary>
        public void SetEndpoints(Vector2 a, Vector2 b)
        {
            if (_rt == null) _rt = GetComponent<RectTransform>();
            Vector2 d = b - a;
            float len = d.magnitude;
            float ang = Mathf.Atan2(d.y, d.x) * Mathf.Rad2Deg;

            _rt.anchoredPosition = (a + b) * 0.5f;
            _rt.sizeDelta = new Vector2(Mathf.Max(len, 1f), Thickness);
            _rt.localEulerAngles = new Vector3(0f, 0f, ang);

            if (_label != null)
                _label.localEulerAngles = new Vector3(0f, 0f, -ang); // keep text upright
        }

        public void OnPointerClick(PointerEventData eventData)
        {
            if (IsContainment) return;
            _onClick?.Invoke(this, eventData.position);
        }
    }
}
