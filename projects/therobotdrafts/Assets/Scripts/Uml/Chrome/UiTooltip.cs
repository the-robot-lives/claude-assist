using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace TheRobotDraft.Uml.Chrome
{
    /// <summary>
    /// Lightweight hover tooltip for code-built chrome. One shared floating label under the root canvas.
    /// </summary>
    public sealed class UiTooltip : MonoBehaviour, IPointerEnterHandler, IPointerExitHandler
    {
        public string Text;
        public Font Font;
        public float Delay = 0.35f;

        private static RectTransform _tipRt;
        private static Text _tipText;
        private static Image _tipBg;
        private static Canvas _canvas;
        private static float _showAt;
        private static string _pending;
        private static UiTooltip _owner;

        public static void Bind(GameObject target, string text, Font font)
        {
            if (target == null || string.IsNullOrEmpty(text)) return;
            var tip = target.GetComponent<UiTooltip>();
            if (tip == null) tip = target.AddComponent<UiTooltip>();
            tip.Text = text;
            tip.Font = font;
        }

        public void OnPointerEnter(PointerEventData eventData)
        {
            _owner = this;
            _pending = Text;
            _showAt = Time.unscaledTime + Delay;
            EnsureTip();
            HideImmediate();
        }

        public void OnPointerExit(PointerEventData eventData)
        {
            if (_owner == this)
            {
                _owner = null;
                _pending = null;
                HideImmediate();
            }
        }

        private void Update()
        {
            if (_owner != this || string.IsNullOrEmpty(_pending)) return;
            if (Time.unscaledTime < _showAt) return;
            Show(_pending, Input.mousePosition);
            _pending = null;
        }

        private void OnDisable()
        {
            if (_owner == this) { _owner = null; HideImmediate(); }
        }

        private static void EnsureTip()
        {
            if (_tipRt != null) return;
            var canvas = Object.FindObjectOfType<Canvas>();
            if (canvas == null) return;
            _canvas = canvas;
            var go = new GameObject("UiTooltip", typeof(RectTransform));
            _tipRt = (RectTransform)go.transform;
            _tipRt.SetParent(canvas.transform, false);
            _tipRt.anchorMin = _tipRt.anchorMax = new Vector2(0f, 0f);
            _tipRt.pivot = new Vector2(0f, 1f);
            _tipRt.sizeDelta = new Vector2(220f, 28f);
            _tipBg = go.AddComponent<Image>();
            MacOsControlKit.ApplyPopover(_tipBg);
            var tgo = new GameObject("T", typeof(RectTransform));
            var trt = (RectTransform)tgo.transform;
            trt.SetParent(_tipRt, false);
            trt.anchorMin = Vector2.zero;
            trt.anchorMax = Vector2.one;
            trt.offsetMin = new Vector2(8f, 4f);
            trt.offsetMax = new Vector2(-8f, -4f);
            _tipText = tgo.AddComponent<Text>();
            _tipText.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            _tipText.fontSize = 12;
            _tipText.color = ConceptDTheme.Text;
            _tipText.alignment = TextAnchor.MiddleLeft;
            _tipText.raycastTarget = false;
            _tipText.supportRichText = false;
            _tipBg.raycastTarget = false;
            HideImmediate();
        }

        private static void Show(string text, Vector2 screenPos)
        {
            EnsureTip();
            if (_tipRt == null || _tipText == null) return;
            if (_owner != null && _owner.Font != null) _tipText.font = _owner.Font;
            _tipText.text = text;
            float scale = _canvas != null ? Mathf.Max(_canvas.scaleFactor, 0.0001f) : 1f;
            float w = Mathf.Clamp(text.Length * 7.2f + 20f, 80f, 360f);
            _tipRt.sizeDelta = new Vector2(w, 26f);
            var pos = screenPos / scale + new Vector2(12f, -8f);
            // Keep on-screen.
            float maxX = Screen.width / scale - w - 8f;
            float maxY = Screen.height / scale - 8f;
            pos.x = Mathf.Clamp(pos.x, 8f, Mathf.Max(8f, maxX));
            pos.y = Mathf.Clamp(pos.y, 30f, Mathf.Max(30f, maxY));
            _tipRt.anchoredPosition = pos;
            _tipRt.SetAsLastSibling();
            _tipRt.gameObject.SetActive(true);
        }

        private static void HideImmediate()
        {
            if (_tipRt != null) _tipRt.gameObject.SetActive(false);
        }
    }
}
