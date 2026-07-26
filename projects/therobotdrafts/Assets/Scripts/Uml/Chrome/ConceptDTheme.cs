using UnityEngine;

namespace TheRobotDraft.Uml.Chrome
{
    /// <summary>
    /// Concept D (nav-redesign demo) visual tokens — single source of truth for the
    /// Nocturne shell that the HTML prototype at <c>design/nav-redesign/demo/index.html</c>
    /// defines. Keep Unity chrome in lockstep with those CSS custom properties.
    /// <para>
    /// Base tokens are settable so Preferences can swap the palette at runtime; derived tokens
    /// are computed properties, NOT snapshots, so they follow their base. (They used to be
    /// <c>static readonly</c> initialized from each other, which froze the whole palette at
    /// static-init time.) The procedural sprites in <see cref="MacOsControlKit"/> are grayscale
    /// and tinted through <c>Image.color</c>, so a palette swap needs no re-rasterization.
    /// </para>
    /// </summary>
    public static class ConceptDTheme
    {
        // --- surfaces (demo :root) ---
        /// <summary>#14181b app chrome base.</summary>
        public static Color Bg { get; set; } = Hex(0x14, 0x18, 0x1b);
        /// <summary>#1a1f23 title/context/status bars.</summary>
        public static Color Bg2 { get; set; } = Hex(0x1a, 0x1f, 0x23);
        /// <summary>#20262b hover / elevated chip.</summary>
        public static Color Bg3 { get; set; } = Hex(0x20, 0x26, 0x2b);
        /// <summary>#171c20 dock panels (browser, inspector, palette).</summary>
        public static Color Panel { get; set; } = Hex(0x17, 0x1c, 0x20);
        /// <summary>#2a3238 hairline / rule.</summary>
        public static Color Line { get; set; } = Hex(0x2a, 0x32, 0x38);
        /// <summary>#333c43 control border.</summary>
        public static Color Line2 { get; set; } = Hex(0x33, 0x3c, 0x43);

        // --- type ---
        /// <summary>#d7dee2 primary text.</summary>
        public static Color Text { get; set; } = Hex(0xd7, 0xde, 0xe2);
        /// <summary>#8a969e secondary / dim labels.</summary>
        public static Color TextDim { get; set; } = Hex(0x8a, 0x96, 0x9e);
        /// <summary>#5b666d faint / section caps.</summary>
        public static Color TextFaint { get; set; } = Hex(0x5b, 0x66, 0x6d);

        // --- accents (IA: cyan for mode; warm for selection/connect; vermillion danger only) ---
        /// <summary>#37c8c3 primary cyan-teal accent.</summary>
        public static Color Accent { get; set; } = Hex(0x37, 0xc8, 0xc3);
        /// <summary>#2a807d accent hover / menu highlight base.</summary>
        public static Color AccentDim { get; set; } = Hex(0x2a, 0x80, 0x7d);
        /// <summary>#062a29 text on solid accent chip.</summary>
        public static Color AccentOn { get; set; } = Hex(0x06, 0x2a, 0x29);
        /// <summary>#ffd9a0 warm selection / Connect mode.</summary>
        public static Color Warm { get; set; } = Hex(0xff, 0xd9, 0xa0);
        /// <summary>#3a2c12 text on warm chip.</summary>
        public static Color WarmOn { get; set; } = Hex(0x3a, 0x2c, 0x12);
        /// <summary>#e06c60 danger only (never decorative).</summary>
        public static Color Danger { get; set; } = Hex(0xe0, 0x6c, 0x60);

        // --- derived form fills (computed, so they track the base tokens above) ---
        /// <summary>Modal dialog surface (slightly above panel).</summary>
        public static Color Dialog { get; set; } = Hex(0x1c, 0x22, 0x26);
        /// <summary>Popover / dropdown glass (#1d2327 @ ~93%).</summary>
        public static Color Popover { get; set; } =
            new Color(0x1d / 255f, 0x23 / 255f, 0x27 / 255f, 0.93f);
        /// <summary>Recessed field well (demo .field input bg = --bg).</summary>
        public static Color Field => Bg;
        /// <summary>Secondary push (idle segment / cancel).</summary>
        public static Color Secondary => Bg3;
        /// <summary>Primary filled control (accent-dim for softer push than solid accent).</summary>
        public static Color Primary => AccentDim;
        /// <summary>Menu row idle.</summary>
        public static Color MenuRow { get; set; } = Hex(0x1a, 0x20, 0x24);
        /// <summary>Scroll well / code viewport.</summary>
        public static Color ScrollWell { get; set; } = Hex(0x12, 0x16, 0x19);
        /// <summary>Modal scrim.</summary>
        public static Color Backdrop { get; set; } = new Color(0.02f, 0.03f, 0.04f, 0.45f);
        /// <summary>Selected tree/list row.</summary>
        public static Color SelectionRow =>
            new Color(AccentDim.r, AccentDim.g, AccentDim.b, 0.55f);
        /// <summary>Segment idle cell inside mode control.</summary>
        public static Color SegmentIdle => Bg;
        /// <summary>Progress track.</summary>
        public static Color ProgressTrack => Line2;
        /// <summary>Checkbox unchecked.</summary>
        public static Color Checkbox => Line2;
        /// <summary>Checkbox checked (accent-dim green-teal).</summary>
        public static Color CheckboxOn { get; set; } = Hex(0x2a, 0x80, 0x6a);

        public static Color Hex(byte r, byte g, byte b, byte a = 255) =>
            new Color(r / 255f, g / 255f, b / 255f, a / 255f);

        /// <summary>
        /// Restore every settable token to the Concept D demo value. Preferences calls this before
        /// applying a palette so a partial palette can never inherit stale tokens from the last one.
        /// </summary>
        public static void ResetToDefaults()
        {
            Bg = Hex(0x14, 0x18, 0x1b);
            Bg2 = Hex(0x1a, 0x1f, 0x23);
            Bg3 = Hex(0x20, 0x26, 0x2b);
            Panel = Hex(0x17, 0x1c, 0x20);
            Line = Hex(0x2a, 0x32, 0x38);
            Line2 = Hex(0x33, 0x3c, 0x43);
            Text = Hex(0xd7, 0xde, 0xe2);
            TextDim = Hex(0x8a, 0x96, 0x9e);
            TextFaint = Hex(0x5b, 0x66, 0x6d);
            Accent = Hex(0x37, 0xc8, 0xc3);
            AccentDim = Hex(0x2a, 0x80, 0x7d);
            AccentOn = Hex(0x06, 0x2a, 0x29);
            Warm = Hex(0xff, 0xd9, 0xa0);
            WarmOn = Hex(0x3a, 0x2c, 0x12);
            Danger = Hex(0xe0, 0x6c, 0x60);
            Dialog = Hex(0x1c, 0x22, 0x26);
            Popover = new Color(0x1d / 255f, 0x23 / 255f, 0x27 / 255f, 0.93f);
            MenuRow = Hex(0x1a, 0x20, 0x24);
            ScrollWell = Hex(0x12, 0x16, 0x19);
            Backdrop = new Color(0.02f, 0.03f, 0.04f, 0.45f);
            CheckboxOn = Hex(0x2a, 0x80, 0x6a);
        }
    }
}
