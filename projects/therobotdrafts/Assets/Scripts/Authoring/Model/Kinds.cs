namespace TheRobotDraft.Authoring.Model
{
    /// <summary>
    /// The UML class/bubble-core element kinds for v1 (authoring-ux.md §3.1). These are the kinds the
    /// code→model reverse-engineering pipeline produces; the patterns generalize to other notations later.
    /// Order matches the creation-palette table; <see cref="ElementKind.Class"/> is the palette default.
    /// </summary>
    public enum ElementKind
    {
        Package,
        Class,
        Interface,
        Enum,
        Struct,
        Function,
        Field,

        /// <summary>External / library element — read-only (§5.3). Not a creation-palette slot.</summary>
        External,
    }

    /// <summary>
    /// The UML class-relationship edge kinds for v1 (authoring-ux.md §4, §4.2). <see cref="EdgeKind.Association"/>
    /// is the draw-then-type default.
    /// </summary>
    public enum EdgeKind
    {
        Association,
        Dependency,
        Generalization,
        Realization,
        Aggregation,
        Composition,
    }

    /// <summary>
    /// Static metadata about kinds. The hue strings are the §2.1 Okabe-Ito palette tokens; the renderer maps
    /// them to materials. Kept here (not in the renderer) so the authoring palette and the bubble show the
    /// same kind the same way without a translation step (§3.1, §5).
    /// </summary>
    public static class KindInfo
    {
        /// <summary>§2.1 kind hue, as a hex token. The reserved UI-state channel (§5.1) is deliberately not here.</summary>
        public static string Hue(ElementKind kind) => kind switch
        {
            ElementKind.Package => "#6E7B8B",
            ElementKind.Class => "#0072B2",
            ElementKind.Interface => "#56B4E9",
            ElementKind.Enum => "#E69F00",
            ElementKind.Struct => "#009E73",
            ElementKind.Function => "#2CA02C",
            ElementKind.Field => "#BCBD22",
            ElementKind.External => "#999999",
            _ => "#FFFFFF",
        };

        /// <summary>A classifier is a type-level element; edges in v1 connect classifiers, not members (§4.4).</summary>
        public static bool IsClassifier(ElementKind kind) => kind switch
        {
            ElementKind.Class or ElementKind.Interface or ElementKind.Enum or ElementKind.Struct
                or ElementKind.External => true,
            _ => false,
        };

        /// <summary>Members (fields/functions) are leaves: they contain nothing and are not edge endpoints (§4.4).</summary>
        public static bool IsMember(ElementKind kind) =>
            kind == ElementKind.Field || kind == ElementKind.Function;
    }
}
