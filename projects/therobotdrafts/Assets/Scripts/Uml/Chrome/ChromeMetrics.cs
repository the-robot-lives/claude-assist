namespace TheRobotDraft.Uml.Chrome
{
    /// <summary>
    /// Single source of truth for the shell's layout budget — the Unity counterpart of the
    /// Concept D demo's <c>grid-template-rows: 38px 40px 1fr 26px</c> plus its body column track
    /// list (rail / browser / viewport / inspector). See
    /// <c>design/nav-redesign/demo/index.html</c>.
    /// <para>
    /// Every bar and dock derives its position from the constants here rather than carrying its
    /// own literal. Before this existed the top clearance was spelled out as a bare <c>-70f</c>
    /// in four places; when the context toolbar was inserted only the icon rail was updated, so
    /// the palette, inspector and browse-nav panels drew 34px too high and covered the bottom of
    /// the diagram tab row. Add a band here and shift the ones below it — never re-derive an
    /// offset at the call site.
    /// </para>
    /// </summary>
    public static class ChromeMetrics
    {
        // ---------------------------------------------------------------- vertical bands
        // Demo app shell: titlebar 38 / context toolbar 40 / body 1fr / status strip 26.

        /// <summary>Menu bar strip (demo <c>.titlebar</c>, 38px).</summary>
        public const float MenuBarHeight = 38f;

        /// <summary>Menu-bar button height, centred in the bar (demo <c>.mb</c> 5px pad + 13px line).</summary>
        public const float MenuBarButtonHeight = 26f;

        /// <summary>Context toolbar: breadcrumb + Select|Connect|Place segmented control (demo <c>.ctxbar</c>, 40px).</summary>
        public const float ContextToolbarHeight = 40f;

        /// <summary>Diagram tab row. TRD-specific (the demo has no multi-diagram tabs).</summary>
        public const float TabBarHeight = 38f;

        /// <summary>Diagram tab chip height inside <see cref="TabBarHeight"/>.</summary>
        public const float TabChipHeight = 26f;

        /// <summary>The one-line affordance hint under the tab row (demo <c>.hint</c> pill).</summary>
        public const float HintHeight = 26f;

        /// <summary>Bottom status strip (demo grid row 4, 26px).</summary>
        public const float StatusStripHeight = 26f;

        /// <summary>Hairline breathing room between stacked chrome bands.</summary>
        public const float BandGutter = 2f;

        /// <summary>Margin between a dock panel and the window edge it does not touch.</summary>
        public const float EdgeGutter = 8f;

        // ---------------------------------------------------------------- derived Y offsets
        // All measured downward from the top of the canvas, so a RectTransform anchored to the
        // top edge uses -Value as its anchoredPosition.y / offsetMax.y.

        /// <summary>Top of the context toolbar — directly under the menu bar.</summary>
        public const float ContextToolbarTop = MenuBarHeight;

        /// <summary>Top of the diagram tab row.</summary>
        public const float TabBarTop = ContextToolbarTop + ContextToolbarHeight;

        /// <summary>Top of the hint line.</summary>
        public const float HintTop = TabBarTop + TabBarHeight;

        /// <summary>
        /// Top inset shared by every full-height dock (icon rail, palette, inspector, browse-nav).
        /// Sits just below the tab row; the hint line shares this band but is inset horizontally
        /// past the docks, so the two never collide.
        /// </summary>
        public const float DockTopInset = HintTop + BandGutter;

        /// <summary>
        /// Total top chrome to keep clear of canvas drops — the dock inset plus the full hint
        /// line and a margin, so a drag released against the chrome is rejected rather than
        /// landing a node underneath a bar.
        /// </summary>
        public const float TopChromeSafeBand = HintTop + HintHeight + EdgeGutter;

        /// <summary>Total bottom chrome to keep clear of canvas drops.</summary>
        public const float BottomChromeSafeBand = StatusStripHeight + EdgeGutter;

        /// <summary>
        /// Distance from the canvas top that vertically centres a control of
        /// <paramref name="height"/> inside the context toolbar band. Callers negate it for a
        /// top-anchored <c>anchoredPosition.y</c>.
        /// </summary>
        public static float ContextToolbarCenterY(float height) =>
            ContextToolbarTop + (ContextToolbarHeight - height) * 0.5f;

        // ---------------------------------------------------------------- horizontal tracks
        // Demo body row: grid-template-columns: auto auto auto 1fr auto.

        /// <summary>Icon rail on the far-left edge (demo <c>.rail</c>, 44px).</summary>
        public const float RailWidth = 44f;

        /// <summary>Left browser/palette panel, expanded (demo <c>.browser</c>, 240px).</summary>
        public const float PaletteWidth = 240f;

        /// <summary>Right inspector panel (demo <c>.inspector</c>, 272px).</summary>
        public const float InspectorWidth = 272f;

        /// <summary>Width a collapsed dock keeps for its expand affordance (demo <c>.icon-btn</c> 26px).</summary>
        public const float CollapsedSidebarWidth = 26f;

        // ---------------------------------------------------------------- type scale
        // Demo body font-size is 13px; everything below is a literal from its stylesheet.

        /// <summary>Menu-bar labels and dropdown rows.</summary>
        public const int FontMenu = 13;

        /// <summary>Breadcrumb, mode buttons, tab chips (demo <c>.crumb</c> / <c>.mode-btn</c>, 12px).</summary>
        public const int FontControl = 12;

        /// <summary>Tree and list rows (demo <c>.tree div</c>, 12.5px).</summary>
        public const int FontRow = 12;

        /// <summary>Status strip and hint line (demo 11px / 11.5px).</summary>
        public const int FontStatus = 11;

        /// <summary>Uppercase section captions (demo <c>.isec h3</c>, 11px + letter-spacing).</summary>
        public const int FontSectionCap = 11;

        /// <summary>Icon-rail glyphs (demo <c>.rail .icon-btn</c>, 15px).</summary>
        public const int FontRailGlyph = 15;
    }
}
