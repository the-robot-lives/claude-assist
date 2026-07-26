using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using TheRobotDraft.Uml.Chrome;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// Appearance preferences (IA v2: "Settings… ⌘, … themes"): UI font family, font size and
    /// color theme, persisted through <see cref="UiPrefs"/> and applied by rebuilding the shell
    /// chrome in place.
    /// </summary>
    public sealed partial class UmlCanvas
    {
        /// <summary>Font-scale presets, shown as percentages.</summary>
        private static readonly (string label, float scale)[] FontScalePresets =
        {
            ("75%  (compact)", 0.75f),
            ("90%", 0.90f),
            ("100%  (default)", 1.00f),
            ("110%", 1.10f),
            ("125%", 1.25f),
            ("150%", 1.50f),
            ("175%  (large)", 1.75f),
        };

        private static string FontScaleLabel(float scale)
        {
            string best = FontScalePresets[2].label;
            float bestDelta = float.MaxValue;
            foreach (var p in FontScalePresets)
            {
                float d = Mathf.Abs(p.scale - scale);
                if (d < bestDelta) { bestDelta = d; best = p.label; }
            }
            return best;
        }

        private static float FontScaleFor(string label)
        {
            foreach (var p in FontScalePresets)
                if (p.label == label) return p.scale;
            return UiPrefs.DefaultFontScale;
        }

        /// <summary>Preferences dialog — font family, size and theme. Applies live on Save.</summary>
        public void ShowPreferences(Vector2 screenPos)
        {
            CloseMenu();

            const float w = 520f, h = 300f;
            var panel = BeginModal(w, h, "Preferences   —   Appearance");

            float y = -50f;

            // Font family. The OS list can run to hundreds of entries; the built-in sentinel is
            // first so there is always a known-good choice at the top.
            FormLabel(panel, "UI font", ref y, w);
            var fonts = new List<string>(UiPrefs.AvailableFonts());
            string currentFont = fonts.Contains(UiPrefs.FontName)
                ? UiPrefs.FontName
                : UiPrefs.DefaultFontName;
            var fontDd = MakeDropdown(panel, new Vector2(16f, y), w - 32f, fonts, currentFont, _ => { });
            y -= 42f;

            FormLabel(panel, "Font size", ref y, w);
            var scaleNames = new List<string>();
            foreach (var p in FontScalePresets) scaleNames.Add(p.label);
            var scaleDd = MakeDropdown(panel, new Vector2(16f, y), w - 32f, scaleNames,
                FontScaleLabel(UiPrefs.FontScale), _ => { });
            y -= 42f;

            FormLabel(panel, "Color theme", ref y, w);
            var themes = new List<string>(UiPrefs.ThemeNames);
            var themeDd = MakeDropdown(panel, new Vector2(16f, y), w - 32f, themes,
                themes.Contains(UiPrefs.ThemeName) ? UiPrefs.ThemeName : UiPrefs.DefaultTheme,
                _ => { });
            y -= 46f;

            var status = MakeText(panel, "Changes apply immediately — the diagram is left untouched.",
                new Vector2(16f, y), new Vector2(w - 32f, 18f), ChromeMetrics.FontRow,
                LabelColor, TextAnchor.MiddleLeft);

            void Submit()
            {
                UiPrefs.Save(fontDd.Get(), FontScaleFor(scaleDd.Get()), themeDd.Get());
                CloseMenu();
                RebuildShellChrome();
                Flash("preferences saved — " + UiPrefs.ThemeName + " · " +
                      Mathf.RoundToInt(UiPrefs.FontScale * 100f) + "%");
            }

            void RestoreDefaults()
            {
                UiPrefs.ResetToDefaults();
                CloseMenu();
                RebuildShellChrome();
                Flash("preferences reset to defaults");
            }

            float yBtn = -(h - 46f);
            MakeButton(panel, "Restore Defaults", new Vector2(16f, yBtn), new Vector2(150f, 34f),
                ConceptDTheme.Secondary, RestoreDefaults);
            MakeButton(panel, "Apply", new Vector2(w - 198f, yBtn), new Vector2(84f, 34f),
                ConceptDTheme.Primary, Submit);
            MakeButton(panel, "Cancel", new Vector2(w - 104f, yBtn), new Vector2(88f, 34f),
                ConceptDTheme.Secondary, CloseMenu);

            if (status != null) status.raycastTarget = false;
        }

        /// <summary>
        /// Tear the chrome down and rebuild it against the current <see cref="UiPrefs"/> font and
        /// theme palette.
        /// <para>
        /// Only chrome is destroyed: the node / edge / handle layers and the transparent
        /// background filler are skipped, so every diagram view survives and selection, camera
        /// pose and the active package need no save/restore. Children are detached before being
        /// destroyed because Unity defers <c>Destroy</c> to end-of-frame — without detaching, the
        /// old and new chrome would both be live (and both raycast) for one frame.
        /// </para>
        /// </summary>
        internal void RebuildShellChrome()
        {
            if (_root == null) return;

            _font = UiPrefs.ResolvedFont ?? _font;

            for (int i = _root.childCount - 1; i >= 0; i--)
            {
                var child = _root.GetChild(i);
                if (child == _edgeLayer || child == _nodeLayer || child == _handleLayer) continue;
                if (child.name == "Background") continue;
                child.SetParent(null, false);
                Destroy(child.gameObject);
            }

            // Drop references into the tree we just destroyed.
            _menu = null;
            _browseNav = null;
            _browseNavHost = null;
            _paletteViewport = null;
            _paletteTabButtons.Clear();
            _paletteTabTexts.Clear();
            _paletteSearchGo = null;
            UiTooltip.ResetCache();

            BuildShellChrome();

            // Re-run the passes that normally populate chrome after the initial build.
            BuildTabBar();
            RefreshInspector();
            RefreshSelectionHighlights();
            _browseNav?.RefreshSelection(_selectedId);
        }
    }
}
