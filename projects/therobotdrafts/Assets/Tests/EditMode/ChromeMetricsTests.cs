using NUnit.Framework;
using TheRobotDraft.Uml.Chrome;

namespace TheRobotDraft.Tests.EditMode
{
    /// <summary>
    /// Guards the shell's vertical layout budget.
    /// <para>
    /// These exist because of a real regression: the top clearance for the dock panels was
    /// spelled as a bare <c>-70f</c> in four separate files. When the context toolbar band was
    /// inserted only the icon rail's copy was updated, so the palette, inspector and browse-nav
    /// panels kept the stale number and drew 34px too high — covering the bottom of the diagram
    /// tab row. Nothing failed; the bug was only visible in a screenshot.
    /// </para>
    /// <para>
    /// The invariants below are what "no band overlaps its neighbour" means arithmetically. Add a
    /// band to <see cref="ChromeMetrics"/> without shifting the ones beneath it and these fail.
    /// </para>
    /// </summary>
    public sealed class ChromeMetricsTests
    {
        [Test]
        public void Bands_StackWithoutGapsOrOverlap()
        {
            Assert.AreEqual(ChromeMetrics.MenuBarHeight, ChromeMetrics.ContextToolbarTop,
                "context toolbar must start exactly at the menu bar's bottom edge");
            Assert.AreEqual(ChromeMetrics.ContextToolbarTop + ChromeMetrics.ContextToolbarHeight,
                ChromeMetrics.TabBarTop,
                "tab row must start exactly at the context toolbar's bottom edge");
            Assert.AreEqual(ChromeMetrics.TabBarTop + ChromeMetrics.TabBarHeight,
                ChromeMetrics.HintTop,
                "hint line must start exactly at the tab row's bottom edge");
        }

        [Test]
        public void DockTopInset_ClearsTheTabRow()
        {
            // The original defect, stated directly: a dock that starts above the tab row's bottom
            // edge draws over the diagram tabs.
            float tabRowBottom = ChromeMetrics.TabBarTop + ChromeMetrics.TabBarHeight;
            Assert.GreaterOrEqual(ChromeMetrics.DockTopInset, tabRowBottom,
                "dock panels must start at or below the tab row's bottom edge");
        }

        [Test]
        public void TopChromeSafeBand_CoversEveryTopBand()
        {
            // The canvas drop guard must reject anything landing under any top chrome band,
            // including the hint line that sits below the docks' inset.
            Assert.GreaterOrEqual(ChromeMetrics.TopChromeSafeBand,
                ChromeMetrics.HintTop + ChromeMetrics.HintHeight,
                "drop guard must cover the full hint line");
            Assert.GreaterOrEqual(ChromeMetrics.TopChromeSafeBand, ChromeMetrics.DockTopInset,
                "drop guard must cover at least as much as the dock inset");
        }

        [Test]
        public void BottomChromeSafeBand_CoversStatusStrip()
        {
            Assert.Greater(ChromeMetrics.BottomChromeSafeBand, ChromeMetrics.StatusStripHeight,
                "drop guard must clear the status strip plus a margin");
        }

        [Test]
        public void ChipsFitInsideTheirBands()
        {
            Assert.LessOrEqual(ChromeMetrics.MenuBarButtonHeight, ChromeMetrics.MenuBarHeight,
                "menu-bar buttons must fit inside the menu bar");
            Assert.LessOrEqual(ChromeMetrics.TabChipHeight, ChromeMetrics.TabBarHeight,
                "tab chips must fit inside the tab row");
        }

        [Test]
        public void ContextToolbarCenterY_CentresControlInBand()
        {
            const float h = 24f;
            float y = ChromeMetrics.ContextToolbarCenterY(h);
            float topSlack = y - ChromeMetrics.ContextToolbarTop;
            float bottomSlack =
                (ChromeMetrics.ContextToolbarTop + ChromeMetrics.ContextToolbarHeight) - (y + h);
            Assert.AreEqual(topSlack, bottomSlack, 0.001f,
                "a control placed by ContextToolbarCenterY must sit centred in the band");
            Assert.GreaterOrEqual(topSlack, 0f, "the control must not overhang the band");
        }

        [Test]
        public void CollapsedDockStillLeavesRoomForItsAffordance()
        {
            // The collapse chevron is drawn inside the collapsed width; if the width shrinks below
            // the affordance the panel becomes impossible to reopen by mouse.
            Assert.GreaterOrEqual(ChromeMetrics.CollapsedSidebarWidth, 20f,
                "a collapsed dock must stay wide enough to click its expand affordance");
            Assert.Less(ChromeMetrics.CollapsedSidebarWidth, ChromeMetrics.PaletteWidth,
                "collapsed width must actually be a collapse");
        }

        [Test]
        public void HorizontalDocks_LeaveAViewportAtTheDesignWidth()
        {
            // Concept D's app card caps at 1520 logical px; every dock expanded must still leave a
            // usable diagram viewport at that width.
            const float designWidth = 1520f;
            float docked = ChromeMetrics.RailWidth + ChromeMetrics.PaletteWidth
                + ChromeMetrics.InspectorWidth;
            Assert.Less(docked, designWidth * 0.5f,
                "docks must not consume half the design-width viewport");
        }
    }
}
