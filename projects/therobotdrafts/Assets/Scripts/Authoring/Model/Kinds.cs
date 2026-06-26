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

        // ============================================================================================
        // Additional software-development graph types (appended; saved-diagram kind ordinals stay stable).
        // Ordered most-useful → least-useful for software work. These render as labelled bubbles via the
        // shared slab renderer; they need only a hue + (for table-like kinds) containment.
        // ============================================================================================

        // --- data model / ERD ---
        /// <summary>An entity / database table — a classifier whose columns are Field members.</summary>
        EntityTable,

        // --- C4 model (software architecture) ---
        /// <summary>A C4 person / user actor.</summary>
        Person,
        /// <summary>A C4 software system (the highest-level box).</summary>
        SoftwareSystem,
        /// <summary>A C4 container — a deployable/runnable unit (app, service, database) inside a system.</summary>
        Container,

        // --- flowchart ---
        /// <summary>A flowchart process step (rectangle).</summary>
        FlowProcess,
        /// <summary>A flowchart terminator — start / end (stadium).</summary>
        FlowTerminator,
        /// <summary>A flowchart input / output node (parallelogram).</summary>
        FlowIO,
        /// <summary>A flowchart document node (wavy-bottom rectangle).</summary>
        FlowDocument,

        // --- data flow diagram (DFD) ---
        /// <summary>A DFD data store (open-ended rectangle).</summary>
        DataStore,
        /// <summary>A DFD external entity / source-sink (square).</summary>
        ExternalEntity,

        // --- infrastructure / network / cloud ---
        /// <summary>A server / host node.</summary>
        Server,
        /// <summary>A database server (cylinder) — the infra store, distinct from an ERD table.</summary>
        Database,
        /// <summary>A cloud / managed-service boundary.</summary>
        Cloud,
        /// <summary>A client device / workstation.</summary>
        Client,
        /// <summary>A firewall / security appliance.</summary>
        Firewall,

        // --- mind map ---
        /// <summary>A mind-map topic / idea node.</summary>
        MindNode,

        // --- wireframe / UI mockup ---
        /// <summary>A screen / page container in a UI wireframe; a region that groups its widgets.</summary>
        Screen,
        /// <summary>A generic UI widget (button, input, label, …) inside a screen — the un-typed fallback.</summary>
        UiWidget,
        /// <summary>A layout / grouping region inside a screen (or nested); carries its child widgets when moved.</summary>
        Panel,

        // Concrete wireframe widgets (PlantUML-`salt` parity). All are leaves — they contain nothing.
        /// <summary>A wireframe push button.</summary>
        Button,
        /// <summary>A non-interactive text label.</summary>
        Label,
        /// <summary>A hyperlink (underlined text).</summary>
        Link,
        /// <summary>A single-line text input.</summary>
        TextField,
        /// <summary>A multi-line text input.</summary>
        TextArea,
        /// <summary>A masked password input.</summary>
        Password,
        /// <summary>A toggle checkbox.</summary>
        Checkbox,
        /// <summary>A radio button.</summary>
        Radio,
        /// <summary>A select / dropdown.</summary>
        Dropdown,
        /// <summary>A list box of items.</summary>
        List,
        /// <summary>A data table (columns from its Field children).</summary>
        Table,
        /// <summary>A tree / outline view.</summary>
        Tree,
        /// <summary>An image / picture placeholder.</summary>
        Image,
        /// <summary>A tab strip with a body region.</summary>
        Tabs,
        /// <summary>A menu / menubar.</summary>
        Menu,
        /// <summary>A card container.</summary>
        Card,
        /// <summary>A horizontal / vertical rule.</summary>
        Separator,
        /// <summary>A progress bar.</summary>
        Progress,
        /// <summary>A slider / range control.</summary>
        Slider,
        /// <summary>A breadcrumb trail.</summary>
        Breadcrumb,
        /// <summary>A toolbar / action bar.</summary>
        Toolbar,

        // --- project (Gantt / Kanban) ---
        /// <summary>A project task / work item (Gantt bar or Kanban card).</summary>
        Task,
        /// <summary>A Kanban column / lane (To Do, Doing, Done).</summary>
        KanbanColumn,
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

        /// <summary>A «consumes» usage link (dashed, open arrow): the source class/module uses/depends on the
        /// target — what code import emits when one type references another. Directed source→target.</summary>
        Consumes,
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

            // --- additional software-development graph types ---
            ElementKind.EntityTable => "#2C7FB8",
            ElementKind.Person => "#7B6FB0",
            ElementKind.SoftwareSystem => "#1F6FB2",
            ElementKind.Container => "#438DD5",
            ElementKind.FlowProcess => "#5B8AC4",
            ElementKind.FlowTerminator => "#5AB28A",
            ElementKind.FlowIO => "#E69F00",
            ElementKind.FlowDocument => "#B0A878",
            ElementKind.DataStore => "#7FA6B0",
            ElementKind.ExternalEntity => "#8893A0",
            ElementKind.Server => "#6E7B8B",
            ElementKind.Database => "#4F86C6",
            ElementKind.Cloud => "#56B4E9",
            ElementKind.Client => "#9AA7B0",
            ElementKind.Firewall => "#C44E52",
            ElementKind.MindNode => "#4FA3A0",
            ElementKind.Screen => "#8893A0",
            ElementKind.UiWidget => "#C7CDD6",
            ElementKind.Panel => "#7E8AA2",
            // Wireframe widgets: a neutral lo-fi family with a few semantic accents (overridable by a theme).
            ElementKind.Button => "#4FA3A0",
            ElementKind.Label => "#9AA7B0",
            ElementKind.Link => "#0284C7",
            ElementKind.TextField => "#7FA6B0",
            ElementKind.TextArea => "#7FA6B0",
            ElementKind.Password => "#7FA6B0",
            ElementKind.Checkbox => "#9AA7B0",
            ElementKind.Radio => "#9AA7B0",
            ElementKind.Dropdown => "#7FA6B0",
            ElementKind.List => "#9AA7B0",
            ElementKind.Table => "#7FA6B0",
            ElementKind.Tree => "#9AA7B0",
            ElementKind.Image => "#B0A878",
            ElementKind.Tabs => "#9AA7B0",
            ElementKind.Menu => "#9AA7B0",
            ElementKind.Card => "#C7CDD6",
            ElementKind.Separator => "#C7CDD6",
            ElementKind.Progress => "#5AB28A",
            ElementKind.Slider => "#9AA7B0",
            ElementKind.Breadcrumb => "#9AA7B0",
            ElementKind.Toolbar => "#9AA7B0",
            ElementKind.Task => "#2CA02C",
            ElementKind.KanbanColumn => "#7E8AA2",

            _ => "#FFFFFF",
        };

        /// <summary>A classifier is a type-level element; edges in v1 connect classifiers, not members (§4.4).</summary>
        public static bool IsClassifier(ElementKind kind) => kind switch
        {
            ElementKind.Class or ElementKind.Interface or ElementKind.Enum or ElementKind.Struct
                or ElementKind.External or ElementKind.DataType or ElementKind.ObjectInstance
                or ElementKind.Component or ElementKind.EntityTable => true,
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

        /// <summary>
        /// A wireframe container that groups widgets and carries them when moved (a "region"). Screen is the
        /// top-level page; Panel is a nested layout group. Rendered as a region cube, not a slab.
        /// </summary>
        public static bool IsWireframeRegion(ElementKind kind) =>
            kind == ElementKind.Screen || kind == ElementKind.Panel;

        /// <summary>
        /// A concrete wireframe widget (button, input, table, …) or the generic <see cref="ElementKind.UiWidget"/>
        /// fallback. These are leaves — they contain nothing — and render as distinct lo-fi glyphs inside a
        /// Screen/Panel. PlantUML-`salt` vocabulary.
        /// </summary>
        public static bool IsWireframeWidget(ElementKind kind) => kind switch
        {
            ElementKind.UiWidget or ElementKind.Button or ElementKind.Label or ElementKind.Link
                or ElementKind.TextField or ElementKind.TextArea or ElementKind.Password
                or ElementKind.Checkbox or ElementKind.Radio or ElementKind.Dropdown or ElementKind.List
                or ElementKind.Table or ElementKind.Tree or ElementKind.Image or ElementKind.Tabs
                or ElementKind.Menu or ElementKind.Card or ElementKind.Separator or ElementKind.Progress
                or ElementKind.Slider or ElementKind.Breadcrumb or ElementKind.Toolbar => true,
            _ => false,
        };
    }
}
