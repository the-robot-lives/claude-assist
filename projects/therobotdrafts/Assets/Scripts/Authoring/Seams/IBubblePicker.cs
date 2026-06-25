using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Authoring.Seams
{
    /// <summary>The element a ray resolved to, plus the surface point and whether an assist was applied.</summary>
    public readonly struct PickResult
    {
        /// <summary>The resolved element, or <see cref="ElementId.None"/> for a miss (empty space).</summary>
        public readonly ElementId Element;

        /// <summary>The world point on (or snapped to) the picked bubble; meaningful only when <see cref="Hit"/>.</summary>
        public readonly Float3 Point;

        /// <summary>True if an angular magnetic assist (feasibility C1) moved the result off the raw ray hit.</summary>
        public readonly bool Assisted;

        public PickResult(ElementId element, Float3 point, bool assisted)
        {
            Element = element;
            Point = point;
            Assisted = assisted;
        }

        public bool Hit => Element.IsValid;
        public static readonly PickResult Miss = new PickResult(ElementId.None, Float3.Zero, false);
    }

    /// <summary>
    /// Resolves a pick ray to a model element. Implemented by the render/layout side over the BVH
    /// (rendering-and-vr.md §3.5: "BVH is the picking companion for VR controller rays", O(log n)).
    ///
    /// The authoring layer depends only on this seam, never on the renderer — so the command-model core
    /// (modes, validity, undo) is testable with a fake picker and the real BVH drops in unchanged.
    ///
    /// Feasibility note (ticket 31036022, §7 C1): the riskiest VR interaction is picking a small, deep child
    /// bubble. Mitigations live behind this seam: the implementer applies an <em>angular</em> magnetic assist
    /// (snap to the nearest <em>valid</em> endpoint within an angular radius) and one-euro ray smoothing, and
    /// flags assisted picks via <see cref="PickResult.Assisted"/> so the UI can show the dwell-to-confirm
    /// candidate highlight before commit. The <paramref name="validOnly"/> predicate lets the picker bias the
    /// assist toward legal targets so it never snaps to an illegal one.
    /// </summary>
    public interface IBubblePicker
    {
        /// <summary>Raw or assisted pick of the bubble under <paramref name="ray"/>.</summary>
        PickResult Pick(Ray3 ray);

        /// <summary>
        /// Pick biased toward elements that satisfy <paramref name="isValidTarget"/> (kind-aware assist, C1).
        /// Implementations should prefer a valid target within the assist radius over a closer invalid one.
        /// </summary>
        PickResult PickValid(Ray3 ray, System.Func<ElementId, bool> isValidTarget);
    }
}
