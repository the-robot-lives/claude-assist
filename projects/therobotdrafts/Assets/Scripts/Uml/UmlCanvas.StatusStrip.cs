using UnityEngine;
using UnityEngine.UI;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// The bottom status strip (nav-redesign IA v2): tool-mode echo · active-diagram breadcrumb ·
    /// selection summary · save-slot hint. Text-first by design — mode/state is never encoded by
    /// color alone. Refreshed by cheap polling (4 Hz) rather than invasive hooks into every verb.
    /// </summary>
    public sealed partial class UmlCanvas
    {
        private Text _statusLeft;
        private Text _statusCenter;
        private Text _statusRight;
        private float _statusNextRefresh;

        internal const float StatusStripHeight = 24f;

        private void BuildStatusStrip()
        {
            var barGo = new GameObject("StatusStrip", typeof(RectTransform));
            var bar = (RectTransform)barGo.transform;
            bar.SetParent(_root, false);
            bar.anchorMin = new Vector2(0f, 0f); bar.anchorMax = new Vector2(1f, 0f);
            bar.pivot = new Vector2(0f, 0f);
            bar.sizeDelta = new Vector2(0f, StatusStripHeight);
            bar.anchoredPosition = Vector2.zero;
            var bg = barGo.AddComponent<Image>();
            bg.color = new Color(0.075f, 0.085f, 0.105f, 0.97f);
            bg.raycastTarget = false;

            _statusLeft = MakeText(bar, "SELECT", new Vector2(178f, 0f), new Vector2(360f, StatusStripHeight), 12,
                ToolAccent, TextAnchor.MiddleLeft);
            var lRt = (RectTransform)_statusLeft.transform;
            lRt.anchorMin = new Vector2(0f, 1f); lRt.anchorMax = new Vector2(0f, 1f);

            _statusCenter = MakeText(bar, "", Vector2.zero, new Vector2(700f, StatusStripHeight), 12,
                new Color(0.55f, 0.61f, 0.69f, 1f), TextAnchor.MiddleCenter);
            var cRt = (RectTransform)_statusCenter.transform;
            cRt.anchorMin = cRt.anchorMax = new Vector2(0.5f, 1f);
            cRt.pivot = new Vector2(0.5f, 1f);
            cRt.anchoredPosition = Vector2.zero;

            _statusRight = MakeText(bar, "", Vector2.zero, new Vector2(420f, StatusStripHeight), 12,
                new Color(0.45f, 0.5f, 0.58f, 1f), TextAnchor.MiddleRight);
            var rRt = (RectTransform)_statusRight.transform;
            rRt.anchorMin = rRt.anchorMax = new Vector2(1f, 1f);
            rRt.pivot = new Vector2(1f, 1f);
            rRt.anchoredPosition = new Vector2(-12f, 0f);
        }

        /// <summary>Poll-refresh the strip (called from <c>Update</c>; ~4 Hz is plenty).</summary>
        private void RefreshStatusStrip()
        {
            if (_statusLeft == null || Time.unscaledTime < _statusNextRefresh) return;
            _statusNextRefresh = Time.unscaledTime + 0.25f;

            _statusLeft.text = _toolMode switch
            {
                ToolMode.Connect => _toolConnectSource.IsValid
                    ? "CONNECT · " + RelLabel(_toolConnectKind).ToUpperInvariant() + " — pick target"
                    : "CONNECT · " + RelLabel(_toolConnectKind).ToUpperInvariant(),
                ToolMode.Place => "PLACE · " + _toolPlaceKind.ToString().ToUpperInvariant(),
                _ => "SELECT",
            };
            _statusLeft.color = _toolMode == ToolMode.Connect ? ToolAccentWarm : ToolAccent;

            string crumb = _activePackage.IsValid ? PackagePath(_activePackage) : "no diagram";
            string sel = "";
            if (_selection.Count > 1) sel = "  ·  " + _selection.Count + " selected";
            else if (_selectedId.IsValid && _model != null && _model.TryGet(_selectedId, out var e))
                sel = "  ·  " + e.Name;
            _statusCenter.text = crumb + sel;

            _statusRight.text = _mode2D ? "2D view" : "3D view";
        }

        /// <summary>Breadcrumb path root ▸ … ▸ active package.</summary>
        private string PackagePath(Authoring.Model.ElementId id)
        {
            var parts = new System.Collections.Generic.List<string>();
            var cur = id;
            int guard = 0;
            while (cur.IsValid && _model.TryGet(cur, out var e))
            {
                parts.Add(e.Name);
                cur = e.Parent;
                if (++guard > 64) break;
            }
            parts.Reverse();
            return string.Join(" ▸ ", parts);
        }
    }
}
