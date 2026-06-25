namespace TheRobotDraft.Authoring.State
{
    /// <summary>
    /// The command surface's home-and-modes (authoring-ux.md §1). Select is home and is never owned by the
    /// authoring surface as a "mode" you can be trapped in; Add/Connect are the only spring-loaded modes.
    /// delete/undo/redo/project are instantaneous and do not appear here (they never become a mode).
    /// </summary>
    public enum AuthoringMode
    {
        /// <summary>Home state (§1). Direct-manipulation (select/drill/focus) lives here; the surface never owns it as a mode.</summary>
        Select,

        /// <summary>Spring-loaded add-node mode (§3): pick the parent, packer places.</summary>
        AddNode,

        /// <summary>Spring-loaded connect mode (§4): draw source→target, type after.</summary>
        Connect,
    }

    /// <summary>
    /// Spring-loaded behaviour (§1): tap = place/draw one then auto-return to Select; hold/lock = sticky until
    /// cancel. Default is OneShot — a mode that silently eats your next click is the most common way diagram
    /// tools confuse people.
    /// </summary>
    public enum CommitStyle
    {
        OneShot,
        Sticky,
    }
}
