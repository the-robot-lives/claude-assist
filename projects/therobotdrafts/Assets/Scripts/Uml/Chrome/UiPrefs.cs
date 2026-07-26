using System;
using UnityEngine;

namespace TheRobotDraft.Uml.Chrome
{
    /// <summary>
    /// User-tweakable chrome appearance: font family, font scale, and color theme.
    /// PlayerPrefs-backed, mirroring the <c>LlmSettings</c> / <c>DbSettings</c> shape used
    /// elsewhere in the app.
    /// <para>
    /// Font sizes stay authored as base values in <see cref="ChromeMetrics"/>; this multiplies
    /// them at text-construction time (<see cref="ScaleFont"/>) rather than mutating the
    /// constants, because the bar heights in ChromeMetrics were tuned against those base sizes.
    /// </para>
    /// </summary>
    public static class UiPrefs
    {
        private const string FontKey = "trd.ui.font";
        private const string ScaleKey = "trd.ui.fontScale";
        private const string ThemeKey = "trd.ui.theme";

        /// <summary>Sentinel meaning "Unity's built-in LegacyRuntime font".</summary>
        public const string DefaultFontName = "(built-in)";
        public const float DefaultFontScale = 1f;
        public const string DefaultTheme = "Nocturne";

        public const float MinFontScale = 0.75f;
        public const float MaxFontScale = 1.75f;

        /// <summary>OS font family name, or <see cref="DefaultFontName"/> for the built-in.</summary>
        public static string FontName { get; private set; } = DefaultFontName;

        /// <summary>Multiplier applied to every authored font size.</summary>
        public static float FontScale { get; private set; } = DefaultFontScale;

        /// <summary>Active theme name; see <see cref="ThemeNames"/>.</summary>
        public static string ThemeName { get; private set; } = DefaultTheme;

        /// <summary>Raised after prefs change and the theme has been applied.</summary>
        public static event Action Changed;

        /// <summary>The resolved font, or null to mean "use the built-in".</summary>
        public static Font ResolvedFont { get; private set; }

        public static readonly string[] ThemeNames =
        {
            "Nocturne",     // Concept D default
            "Graphite",     // neutral grey, no cyan cast
            "Midnight Ink", // deeper blue-black, indigo accent
            "Slate Light",  // light surfaces, dark text
        };

        /// <summary>Scale an authored size by the user's font preference (min 8pt, so nothing vanishes).</summary>
        public static int ScaleFont(int baseSize) =>
            Mathf.Max(8, Mathf.RoundToInt(baseSize * FontScale));

        /// <summary>Read prefs from disk and apply the stored theme + font. Safe to call repeatedly.</summary>
        public static void Load()
        {
            FontName = PlayerPrefs.GetString(FontKey, DefaultFontName);
            FontScale = Mathf.Clamp(PlayerPrefs.GetFloat(ScaleKey, DefaultFontScale),
                MinFontScale, MaxFontScale);
            ThemeName = PlayerPrefs.GetString(ThemeKey, DefaultTheme);
            ApplyTheme(ThemeName);
            ResolvedFont = ResolveFont(FontName);
        }

        /// <summary>Persist + apply. Raises <see cref="Changed"/> so the shell can rebuild.</summary>
        public static void Save(string fontName, float fontScale, string themeName)
        {
            FontName = string.IsNullOrWhiteSpace(fontName) ? DefaultFontName : fontName.Trim();
            FontScale = Mathf.Clamp(fontScale, MinFontScale, MaxFontScale);
            ThemeName = string.IsNullOrWhiteSpace(themeName) ? DefaultTheme : themeName.Trim();

            PlayerPrefs.SetString(FontKey, FontName);
            PlayerPrefs.SetFloat(ScaleKey, FontScale);
            PlayerPrefs.SetString(ThemeKey, ThemeName);
            PlayerPrefs.Save();

            ApplyTheme(ThemeName);
            ResolvedFont = ResolveFont(FontName);
            Changed?.Invoke();
        }

        /// <summary>Restore shipped defaults (and persist that choice).</summary>
        public static void ResetToDefaults() =>
            Save(DefaultFontName, DefaultFontScale, DefaultTheme);

        /// <summary>Installed OS font families, with the built-in sentinel first.</summary>
        public static string[] AvailableFonts()
        {
            string[] os;
            try { os = Font.GetOSInstalledFontNames() ?? new string[0]; }
            catch { os = new string[0]; } // not supported on every platform
            Array.Sort(os, StringComparer.OrdinalIgnoreCase);

            var all = new string[os.Length + 1];
            all[0] = DefaultFontName;
            Array.Copy(os, 0, all, 1, os.Length);
            return all;
        }

        private static Font ResolveFont(string name)
        {
            if (string.IsNullOrEmpty(name) || name == DefaultFontName) return BuiltinFont();
            try
            {
                var f = Font.CreateDynamicFontFromOSFont(name, 16);
                if (f != null) return f;
            }
            catch { /* fall through to the built-in */ }
            return BuiltinFont();
        }

        private static Font BuiltinFont() =>
            Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");

        /// <summary>
        /// Push a named palette into <see cref="ConceptDTheme"/>. Always resets first so a palette
        /// that sets fewer tokens can't inherit leftovers from the previous one.
        /// </summary>
        private static void ApplyTheme(string name)
        {
            ConceptDTheme.ResetToDefaults();
            switch (name)
            {
                case "Graphite":
                    ConceptDTheme.Bg = ConceptDTheme.Hex(0x16, 0x17, 0x18);
                    ConceptDTheme.Bg2 = ConceptDTheme.Hex(0x1d, 0x1e, 0x20);
                    ConceptDTheme.Bg3 = ConceptDTheme.Hex(0x26, 0x28, 0x2a);
                    ConceptDTheme.Panel = ConceptDTheme.Hex(0x1a, 0x1b, 0x1d);
                    ConceptDTheme.Line = ConceptDTheme.Hex(0x30, 0x32, 0x35);
                    ConceptDTheme.Line2 = ConceptDTheme.Hex(0x3c, 0x3f, 0x42);
                    ConceptDTheme.Text = ConceptDTheme.Hex(0xe2, 0xe4, 0xe6);
                    ConceptDTheme.TextDim = ConceptDTheme.Hex(0x9a, 0x9e, 0xa3);
                    ConceptDTheme.TextFaint = ConceptDTheme.Hex(0x67, 0x6b, 0x70);
                    ConceptDTheme.Accent = ConceptDTheme.Hex(0xc8, 0xcc, 0xd0);
                    ConceptDTheme.AccentDim = ConceptDTheme.Hex(0x5e, 0x63, 0x69);
                    ConceptDTheme.AccentOn = ConceptDTheme.Hex(0x16, 0x17, 0x18);
                    ConceptDTheme.Dialog = ConceptDTheme.Hex(0x20, 0x22, 0x24);
                    ConceptDTheme.MenuRow = ConceptDTheme.Hex(0x1f, 0x21, 0x23);
                    ConceptDTheme.ScrollWell = ConceptDTheme.Hex(0x13, 0x14, 0x15);
                    ConceptDTheme.CheckboxOn = ConceptDTheme.Hex(0x6a, 0x70, 0x76);
                    break;

                case "Midnight Ink":
                    ConceptDTheme.Bg = ConceptDTheme.Hex(0x0e, 0x11, 0x1c);
                    ConceptDTheme.Bg2 = ConceptDTheme.Hex(0x14, 0x18, 0x27);
                    ConceptDTheme.Bg3 = ConceptDTheme.Hex(0x1d, 0x22, 0x35);
                    ConceptDTheme.Panel = ConceptDTheme.Hex(0x11, 0x15, 0x22);
                    ConceptDTheme.Line = ConceptDTheme.Hex(0x25, 0x2c, 0x42);
                    ConceptDTheme.Line2 = ConceptDTheme.Hex(0x32, 0x3a, 0x55);
                    ConceptDTheme.Text = ConceptDTheme.Hex(0xdc, 0xe1, 0xf0);
                    ConceptDTheme.TextDim = ConceptDTheme.Hex(0x8d, 0x96, 0xb2);
                    ConceptDTheme.TextFaint = ConceptDTheme.Hex(0x5c, 0x65, 0x82);
                    ConceptDTheme.Accent = ConceptDTheme.Hex(0x8b, 0x9c, 0xff);
                    ConceptDTheme.AccentDim = ConceptDTheme.Hex(0x45, 0x4f, 0x9c);
                    ConceptDTheme.AccentOn = ConceptDTheme.Hex(0x0b, 0x0e, 0x1e);
                    ConceptDTheme.Warm = ConceptDTheme.Hex(0xff, 0xc8, 0x8a);
                    ConceptDTheme.Dialog = ConceptDTheme.Hex(0x18, 0x1d, 0x2e);
                    ConceptDTheme.MenuRow = ConceptDTheme.Hex(0x16, 0x1b, 0x2a);
                    ConceptDTheme.ScrollWell = ConceptDTheme.Hex(0x0b, 0x0e, 0x18);
                    ConceptDTheme.CheckboxOn = ConceptDTheme.Hex(0x45, 0x4f, 0x9c);
                    break;

                case "Slate Light":
                    ConceptDTheme.Bg = ConceptDTheme.Hex(0xec, 0xee, 0xf1);
                    ConceptDTheme.Bg2 = ConceptDTheme.Hex(0xe9, 0xeb, 0xef);
                    ConceptDTheme.Bg3 = ConceptDTheme.Hex(0xdc, 0xe0, 0xe6);
                    ConceptDTheme.Panel = ConceptDTheme.Hex(0xf4, 0xf6, 0xf8);
                    ConceptDTheme.Line = ConceptDTheme.Hex(0xc9, 0xcf, 0xd6);
                    ConceptDTheme.Line2 = ConceptDTheme.Hex(0xb3, 0xbb, 0xc4);
                    ConceptDTheme.Text = ConceptDTheme.Hex(0x1c, 0x22, 0x28);
                    ConceptDTheme.TextDim = ConceptDTheme.Hex(0x53, 0x5d, 0x68);
                    ConceptDTheme.TextFaint = ConceptDTheme.Hex(0x7d, 0x87, 0x93);
                    ConceptDTheme.Accent = ConceptDTheme.Hex(0x0f, 0x8d, 0x8a);
                    ConceptDTheme.AccentDim = ConceptDTheme.Hex(0x7e, 0xd0, 0xcd);
                    ConceptDTheme.AccentOn = ConceptDTheme.Hex(0xff, 0xff, 0xff);
                    ConceptDTheme.Warm = ConceptDTheme.Hex(0xb8, 0x72, 0x12);
                    ConceptDTheme.WarmOn = ConceptDTheme.Hex(0xff, 0xff, 0xff);
                    ConceptDTheme.Dialog = ConceptDTheme.Hex(0xff, 0xff, 0xff);
                    ConceptDTheme.Popover = new Color(1f, 1f, 1f, 0.96f);
                    ConceptDTheme.MenuRow = ConceptDTheme.Hex(0xf7, 0xf8, 0xfa);
                    ConceptDTheme.ScrollWell = ConceptDTheme.Hex(0xe4, 0xe7, 0xeb);
                    ConceptDTheme.Backdrop = new Color(0.1f, 0.12f, 0.15f, 0.35f);
                    ConceptDTheme.CheckboxOn = ConceptDTheme.Hex(0x0f, 0x8d, 0x8a);
                    break;

                default: // "Nocturne" — ResetToDefaults already installed it
                    break;
            }
        }
    }
}
