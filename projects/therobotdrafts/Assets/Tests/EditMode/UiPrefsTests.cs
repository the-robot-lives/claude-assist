using NUnit.Framework;
using UnityEngine;
using TheRobotDraft.Uml.Chrome;

namespace TheRobotDraft.Tests.EditMode
{
    /// <summary>
    /// Guards the runtime-themable palette.
    /// <para>
    /// <see cref="ConceptDTheme"/> tokens used to be <c>static readonly</c> initialized from one
    /// another, and <see cref="MacOsControlKit"/> snapshotted 15 of them into its own
    /// <c>static readonly</c> fills. Both froze at static-init, so a theme change left every
    /// control wearing the startup palette. These tests pin the "derived tokens are live" contract
    /// that replaced it.
    /// </para>
    /// <para>
    /// The palette is global mutable state, so every test here restores defaults in TearDown —
    /// otherwise a mutation leaks into <c>MacOsControlKitTests.ConceptDTheme_MatchesDemoTokens</c>
    /// and the failure surfaces in an unrelated test, ordering-dependent.
    /// </para>
    /// </summary>
    public sealed class UiPrefsTests
    {
        [TearDown]
        public void RestorePalette() => ConceptDTheme.ResetToDefaults();

        [Test]
        public void DerivedTokens_FollowTheirBase()
        {
            ConceptDTheme.Bg3 = Color.magenta;
            Assert.AreEqual(Color.magenta, ConceptDTheme.Secondary,
                "Secondary is derived from Bg3 and must track it");

            ConceptDTheme.AccentDim = Color.green;
            Assert.AreEqual(Color.green, ConceptDTheme.Primary,
                "Primary is derived from AccentDim and must track it");

            ConceptDTheme.Bg = Color.blue;
            Assert.AreEqual(Color.blue, ConceptDTheme.Field,
                "Field is derived from Bg and must track it");
            Assert.AreEqual(Color.blue, ConceptDTheme.SegmentIdle,
                "SegmentIdle is derived from Bg and must track it");
        }

        [Test]
        public void ControlKitFills_FollowTheTheme()
        {
            // The exact regression: these were snapshots, so a theme swap never reached controls.
            ConceptDTheme.Bg3 = Color.magenta;
            Assert.AreEqual(ConceptDTheme.Secondary, MacOsControlKit.SecondaryFill,
                "SecondaryFill must read the live theme, not a static-init snapshot");

            ConceptDTheme.AccentDim = Color.green;
            Assert.AreEqual(ConceptDTheme.Primary, MacOsControlKit.PrimaryFill,
                "PrimaryFill must read the live theme");

            ConceptDTheme.Line = Color.red;
            Assert.AreEqual(Color.red, MacOsControlKit.SeparatorFill,
                "SeparatorFill must read the live theme");
        }

        [Test]
        public void SelectionRow_TracksAccentAndStaysTranslucent()
        {
            ConceptDTheme.AccentDim = new Color(0.1f, 0.2f, 0.3f, 1f);
            var row = ConceptDTheme.SelectionRow;
            Assert.AreEqual(0.1f, row.r, 0.001f);
            Assert.AreEqual(0.2f, row.g, 0.001f);
            Assert.AreEqual(0.3f, row.b, 0.001f);
            Assert.Less(row.a, 1f, "the selection row must stay translucent over the panel");
        }

        [Test]
        public void ResetToDefaults_RestoresTheDemoPalette()
        {
            ConceptDTheme.Accent = Color.magenta;
            ConceptDTheme.Bg = Color.magenta;
            ConceptDTheme.Text = Color.magenta;

            ConceptDTheme.ResetToDefaults();

            Assert.AreEqual(ConceptDTheme.Hex(0x37, 0xc8, 0xc3), ConceptDTheme.Accent);
            Assert.AreEqual(ConceptDTheme.Hex(0x14, 0x18, 0x1b), ConceptDTheme.Bg);
            Assert.AreEqual(ConceptDTheme.Hex(0xd7, 0xde, 0xe2), ConceptDTheme.Text);
        }

        [Test]
        public void ScaleFont_IsIdentityAtDefaultScale()
        {
            // Load() is not called here, so FontScale is the 1.0 default.
            Assert.AreEqual(UiPrefs.DefaultFontScale, UiPrefs.FontScale);
            Assert.AreEqual(13, UiPrefs.ScaleFont(13));
            Assert.AreEqual(ChromeMetrics.FontMenu, UiPrefs.ScaleFont(ChromeMetrics.FontMenu));
        }

        [Test]
        public void ScaleFont_NeverReturnsAnUnreadableSize()
        {
            // Even at the smallest allowed scale nothing may collapse to zero/negative.
            foreach (int baseSize in new[] { 8, 9, 11, 12, 13, 15, 16 })
                Assert.GreaterOrEqual(UiPrefs.ScaleFont(baseSize), 8,
                    "font sizes must stay legible at any scale");
        }

        [Test]
        public void FontScaleBounds_AreSaneAndBracketTheDefault()
        {
            Assert.Less(UiPrefs.MinFontScale, UiPrefs.DefaultFontScale);
            Assert.Greater(UiPrefs.MaxFontScale, UiPrefs.DefaultFontScale);
            Assert.Greater(UiPrefs.MinFontScale, 0f);
        }

        [Test]
        public void ThemeNames_AreNonEmptyAndContainTheDefault()
        {
            Assert.IsNotNull(UiPrefs.ThemeNames);
            Assert.Greater(UiPrefs.ThemeNames.Length, 1, "offer more than one theme");
            CollectionAssert.Contains(UiPrefs.ThemeNames, UiPrefs.DefaultTheme);
            foreach (var n in UiPrefs.ThemeNames)
                Assert.IsFalse(string.IsNullOrWhiteSpace(n));
        }

        [Test]
        public void AvailableFonts_AlwaysOffersTheBuiltIn()
        {
            var fonts = UiPrefs.AvailableFonts();
            Assert.IsNotNull(fonts);
            Assert.Greater(fonts.Length, 0);
            Assert.AreEqual(UiPrefs.DefaultFontName, fonts[0],
                "the built-in must be first so there is always a known-good choice");
        }
    }
}
