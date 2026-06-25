namespace TheRobotDraft.Authoring.State
{
    /// <summary>
    /// The reserved UI-state channel (authoring-ux.md §5.1 "the critical call"). Authoring feedback must NOT
    /// reuse kind hues — a green "valid" glow would read as <em>function</em>. This enum is the state; the
    /// renderer maps it to the reserved achromatic + vermillion channel and the shape cue (every state is
    /// encoded ≥2× per §5.2, never color alone). Identical in desktop and VR (§6).
    /// </summary>
    public enum AffordanceState
    {
        /// <summary>Nothing special — resting kind appearance.</summary>
        None,

        /// <summary>selected / active mode: white→cyan rim, bright solid outline.</summary>
        Selected,

        /// <summary>valid drop/connect target: white rim + thicken, snap-pulse + ✓ ghost.</summary>
        ValidTarget,

        /// <summary>invalid target: #D55E00 vermillion dashed rim + ✕, no snap. Carries a hover reason.</summary>
        InvalidTarget,

        /// <summary>in-progress rubber-band: neutral white dashed until type chosen.</summary>
        InProgress,
    }
}
