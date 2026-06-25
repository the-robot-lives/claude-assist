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

        /// <summary>A free-text UML note / comment (dog-eared box). Holds no members; attaches via a dashed link.</summary>
        Note,

        // --- use-case diagram ---
        Actor,
        UseCase,

        // --- state-machine diagram ---
        State,
        StateStart,
        StateEnd,

        /// <summary>External / library element — read-only (§5.3). Not a creation-palette slot.</summary>
        External,

        // --- additions (appended so saved-diagram kind ordinals stay stable) ---

        // class / object diagrams
        /// <summary>A «dataType» classifier (value type with attributes/operations).</summary>
        DataType,
        /// <summary>A «primitive» type leaf (Integer, String, …).</summary>
        PrimitiveType,
        /// <summary>An object-diagram instance specification ("name : Class", underlined; slots in the body).</summary>
        ObjectInstance,

        // use-case diagram
        /// <summary>A use-case system boundary / subject — a titled frame that visually groups use cases.</summary>
        Boundary,

        // state-machine + activity control nodes
        /// <summary>A decision / choice / merge pseudostate (diamond). Guards on the outgoing transitions.</summary>
        Decision,
        /// <summary>A fork / join bar — splits one flow into concurrent flows, or synchronizes them back.</summary>
        ForkJoin,
        /// <summary>A junction pseudostate (small filled dot) chaining transition segments.</summary>
        Junction,
        /// <summary>A (shallow) history pseudostate — the circled H.</summary>
        History,
        /// <summary>A terminate pseudostate — the crossed circle that ends the whole machine.</summary>
        Terminate,

        // activity diagram
        /// <summary>An activity action node (rounded "pill"), the verb of an activity diagram.</summary>
        Activity,
        /// <summary>An activity flow-final node — a circled ✕ that consumes a single incoming token.</summary>
        FlowFinal,

        // component / deployment diagrams
        /// <summary>A «component» classifier (rectangle with the two-tab component icon).</summary>
        Component,
        /// <summary>An «artifact» (a physical file/document, dog-eared rectangle).</summary>
        Artifact,
        /// <summary>A deployment node / device — drawn as a 3-D box.</summary>
        DeploymentNode,

        // package diagram
        /// <summary>A package shown as a node (folder/tabbed rectangle) inside a package diagram.</summary>
        PackageNode,

        // composite-structure diagram
        /// <summary>An internal part of a composite structure (a typed role rectangle).</summary>
        Part,
        /// <summary>A port — the small square interaction point on a part / component border.</summary>
        Port,
        /// <summary>A collaboration — the dashed ellipse naming a structural pattern of roles.</summary>
        Collaboration,

        // sequence / communication / interaction-overview diagrams
        /// <summary>A sequence-diagram lifeline: a head (object) box with a dashed life line dropping below it.</summary>
        Lifeline,
        /// <summary>An execution / activation bar sitting on a lifeline.</summary>
        Activation,
        /// <summary>An interaction frame / combined fragment (sd, alt, opt, loop, par) — a labeled region.</summary>
        Frame,

        // profile diagram
        /// <summary>A «metaclass» — an element of the reference metamodel that a stereotype extends.</summary>
        Metaclass,
        /// <summary>A «stereotype» definition (a profile-diagram classifier).</summary>
        Stereotype,
        /// <summary>A «profile» — the package/region that groups stereotype definitions.</summary>
        Profile,

        // timing diagram
        /// <summary>A timing-diagram lifeline: a participant's state plotted as a waveform over a time axis.</summary>
        TimingLifeline,

        /// <summary>A call-behavior activity node (rounded rect with the rake icon) — distinct from an atomic action.</summary>
        CallActivity,
    }

    /// <summary>
    /// The UML relationship edge kinds. The first six are class-diagram relationships; the rest carry the
    /// behavioral / cross-diagram connectors (state &amp; activity flow, use-case include/extend, note anchors,
    /// directed associations) so every node type gets a relationship that shows the correct direction (§4.2).
    /// Appended so saved-diagram edge ordinals stay stable.
    /// </summary>
    public enum EdgeKind
    {
        Association,
        Dependency,
        Generalization,
        Realization,
        Aggregation,
        Composition,

        /// <summary>A state-machine / activity flow (solid line, open arrow) — the "information flow" connector.</summary>
        Transition,
        /// <summary>A use-case «include» (dashed, open arrow): the base use case always pulls in the included one.</summary>
        Include,
        /// <summary>A use-case «extend» (dashed, open arrow): the extension optionally augments the base.</summary>
        Extend,
        /// <summary>A note / comment anchor (dashed line, no arrowhead) tying a note to the element it annotates.</summary>
        NoteLink,
        /// <summary>A navigable / directed association (solid line, open arrow) — class-diagram information flow.</summary>
        DirectedAssociation,

        /// <summary>A synchronous sequence message (solid line, filled arrowhead) — a blocking call.</summary>
        MessageSync,
        /// <summary>An asynchronous sequence message (solid line, open stick arrowhead) — a signal / non-blocking send.</summary>
        MessageAsync,
        /// <summary>A reply / return message (dashed line, open stick arrowhead).</summary>
        MessageReply,

        /// <summary>A profile «extension» — a stereotype extends a metaclass (solid line, filled triangle head).</summary>
        Extension,
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
            ElementKind.Note => "#F2E2A0",
            ElementKind.Actor => "#6B5B95",
            ElementKind.UseCase => "#4E9BC4",
            ElementKind.State => "#5AB28A",
            ElementKind.StateStart => "#2A2D34",
            ElementKind.StateEnd => "#2A2D34",
            ElementKind.External => "#999999",

            ElementKind.DataType => "#7FA6B0",
            ElementKind.PrimitiveType => "#9AA7B0",
            ElementKind.ObjectInstance => "#0072B2",
            ElementKind.Boundary => "#8893A0",
            ElementKind.Decision => "#E69F00",
            ElementKind.ForkJoin => "#2A2D34",
            ElementKind.Junction => "#2A2D34",
            ElementKind.History => "#5AB28A",
            ElementKind.Terminate => "#2A2D34",
            ElementKind.Activity => "#4FA3A0",
            ElementKind.FlowFinal => "#2A2D34",
            ElementKind.Component => "#5B8AC4",
            ElementKind.Artifact => "#B0A878",
            ElementKind.DeploymentNode => "#6E7B8B",
            ElementKind.PackageNode => "#6E7B8B",
            ElementKind.Part => "#7E8AA2",
            ElementKind.Port => "#C7CDD6",
            ElementKind.Collaboration => "#B9A6C8",
            ElementKind.Lifeline => "#5B8AC4",
            ElementKind.Activation => "#DDE3EA",
            ElementKind.Frame => "#8893A0",
            ElementKind.Metaclass => "#8FA8B8",
            ElementKind.Stereotype => "#C8A2C8",
            ElementKind.Profile => "#8893A0",
            ElementKind.TimingLifeline => "#5B8AC4",
            ElementKind.CallActivity => "#4FA3A0",
            _ => "#FFFFFF",
        };

        /// <summary>A classifier is a type-level element; edges in v1 connect classifiers, not members (§4.4).</summary>
        public static bool IsClassifier(ElementKind kind) => kind switch
        {
            ElementKind.Class or ElementKind.Interface or ElementKind.Enum or ElementKind.Struct
                or ElementKind.External or ElementKind.DataType or ElementKind.ObjectInstance
                or ElementKind.Component => true,
            _ => false,
        };

        /// <summary>Members (fields/functions) are leaves: they contain nothing and are not edge endpoints (§4.4).</summary>
        public static bool IsMember(ElementKind kind) =>
            kind == ElementKind.Field || kind == ElementKind.Function;

        /// <summary>
        /// A behavioral control node (state-machine / activity vocabulary). These connect with the directional
        /// <see cref="EdgeKind.Transition"/> "flow" arrow rather than a class-diagram association.
        /// </summary>
        public static bool IsBehavioral(ElementKind kind) => kind switch
        {
            ElementKind.State or ElementKind.Activity or ElementKind.CallActivity or ElementKind.StateStart
                or ElementKind.StateEnd or ElementKind.Decision or ElementKind.ForkJoin or ElementKind.Junction
                or ElementKind.History or ElementKind.Terminate or ElementKind.FlowFinal => true,
            _ => false,
        };

        /// <summary>
        /// A free-standing diagram node drawn as its own shape on the canvas. Everything except packages (which
        /// are tabs) and members (which render inside their owner's compartments) is a diagram node.
        /// </summary>
        public static bool IsDiagramNode(ElementKind kind) =>
            kind != ElementKind.Package && !IsMember(kind);

        /// <summary>Any node that a relationship line may attach to (diagram nodes + packages).</summary>
        public static bool IsConnectable(ElementKind kind) =>
            IsDiagramNode(kind) || kind == ElementKind.Package;
    }
}
