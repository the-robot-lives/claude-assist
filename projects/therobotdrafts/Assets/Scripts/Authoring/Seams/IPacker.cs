using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Authoring.Seams
{
    /// <summary>
    /// The packer owns position, not the user (ADR-003; authoring-ux.md §0.1). The authoring layer never sets
    /// an xyz — it tells the packer "this element is now a child of that parent" and the packer assigns the
    /// position and gently re-packs the affected subtree (siblings preserved, no pop). This is the single most
    /// important authoring invariant: there is no free-position gesture because there is no free space.
    ///
    /// Implemented by the layout engine (rendering-and-vr.md §2.1, off the frame loop). The returned
    /// <see cref="RepackResult"/> lets the renderer drive the comfort-bounded cross-fade (feasibility A1:
    /// animate the affected subtree only, ease ≤300ms, alpha-fade nodes that move &gt; ~10°).
    /// </summary>
    public interface IPacker
    {
        /// <summary>An element entered the tree (or moved parents); position it and re-pack. Returns ripple extent.</summary>
        RepackResult OnInserted(ElementId element, ElementId parent);

        /// <summary>An element left the tree; re-pack the former parent's subtree to close the gap.</summary>
        RepackResult OnRemoved(ElementId formerParent);

        /// <summary>Current packed center of an element (for placing the rubber-band / label HUD). Zero if unknown.</summary>
        Float3 PositionOf(ElementId element);
    }

    /// <summary>
    /// What a re-pack disturbed, so the renderer can bound the animation per feasibility A1. Layout cost itself
    /// is off the frame loop; only this animation touches the frame.
    /// </summary>
    public readonly struct RepackResult
    {
        /// <summary>How many elements changed position (the cross-fade set).</summary>
        public readonly int MovedCount;

        /// <summary>The largest displacement of any moved element, in world units (clamp/alpha-fade threshold input).</summary>
        public readonly float MaxDisplacement;

        public RepackResult(int movedCount, float maxDisplacement)
        {
            MovedCount = movedCount;
            MaxDisplacement = maxDisplacement;
        }

        public static readonly RepackResult None = new RepackResult(0, 0f);
    }

    /// <summary>
    /// A no-op packer for headless tests and the pre-renderer bring-up: it accepts every placement and reports
    /// an empty ripple. Lets the command-model core run without the layout engine present.
    /// </summary>
    public sealed class NullPacker : IPacker
    {
        public RepackResult OnInserted(ElementId element, ElementId parent) => RepackResult.None;
        public RepackResult OnRemoved(ElementId formerParent) => RepackResult.None;
        public Float3 PositionOf(ElementId element) => Float3.Zero;
    }
}
