using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Authoring.Rules
{
    /// <summary>
    /// The result of a legality check. Carries a human reason so the UI can show the §B invalid affordance
    /// (vermillion dashed rim + ✕) with a hover reason "at point-of-use rather than as a failed drop"
    /// (authoring-ux.md §3.1). A rule that is satisfied returns <see cref="Valid"/>; the reason is empty.
    /// </summary>
    public readonly struct Validity
    {
        public readonly bool IsValid;
        public readonly string Reason;

        private Validity(bool valid, string reason)
        {
            IsValid = valid;
            Reason = reason;
        }

        public static readonly Validity Valid = new Validity(true, null);
        public static Validity Invalid(string reason) => new Validity(false, reason);
    }

    /// <summary>
    /// Containment legality (authoring-ux.md §3.1 "containment-filtered"). Answers "may a child of
    /// <c>kind</c> live directly inside <c>parentKind</c>?" — the rule the creation palette dims an illegal
    /// chip on, and that add-node enforces. UML class/bubble core only for v1.
    /// </summary>
    public static class ContainmentRules
    {
        public static Validity CanContain(ElementKind parentKind, ElementKind childKind)
        {
            // External elements are read-only — nothing is authored inside them (§5.3).
            if (parentKind == ElementKind.External)
                return Validity.Invalid("external/library elements are read-only");

            // Members are leaves: they contain nothing.
            if (KindInfo.IsMember(parentKind))
                return Validity.Invalid($"a {parentKind} cannot contain other elements");

            bool ok = parentKind switch
            {
                // A package groups any diagram node and sub-packages — never raw members (the spec's worked
                // example: a Field directly under a Package is illegal).
                ElementKind.Package => childKind == ElementKind.Package || KindInfo.IsDiagramNode(childKind),

                // Classifiers hold members and (language-permitting) nested types.
                ElementKind.Class or ElementKind.Struct => childKind is ElementKind.Field or ElementKind.Function
                    or ElementKind.Class or ElementKind.Interface or ElementKind.Enum or ElementKind.Struct,

                ElementKind.Interface => childKind is ElementKind.Function or ElementKind.Field
                    or ElementKind.Interface or ElementKind.Enum,

                ElementKind.Enum => childKind is ElementKind.Field or ElementKind.Function,

                // A «dataType» carries attributes/operations; an object instance carries slot values (fields).
                ElementKind.DataType => childKind is ElementKind.Field or ElementKind.Function,
                ElementKind.ObjectInstance => childKind == ElementKind.Field,

                _ => false,
            };

            return ok
                ? Validity.Valid
                : Validity.Invalid($"a {childKind} is not allowed directly inside a {parentKind}");
        }
    }

    /// <summary>
    /// Edge legality, kind-aware and "felt during the drag" (authoring-ux.md §4.4). Edges in v1 connect
    /// classifiers (and packages, for dependency), never members. Self-edges, generalization typing, and
    /// generalization cycles are checked here so the §B invalid affordance fires before the drop.
    /// </summary>
    public static class EdgeRules
    {
        /// <param name="model">needed for the would-create-cycle generalization check.</param>
        public static Validity CanConnect(AuthoringModel model, EdgeKind kind, ElementId fromId, ElementId toId)
        {
            if (!model.TryGet(fromId, out var from) || !model.TryGet(toId, out var to))
                return Validity.Invalid("endpoint does not exist");

            // Members are never edge endpoints in v1 (§4.4: "a Field/Function as a generalization endpoint → invalid").
            if (KindInfo.IsMember(from.Kind) || KindInfo.IsMember(to.Kind))
                return Validity.Invalid("relationships connect types, not fields or methods");

            bool selfEdge = fromId == toId;

            switch (kind)
            {
                case EdgeKind.Generalization:
                    if (selfEdge)
                        return Validity.Invalid("a type cannot generalize itself");
                    // class→class or interface→interface only (§4.4).
                    bool genOk = (from.Kind == ElementKind.Class && to.Kind == ElementKind.Class)
                                 || (from.Kind == ElementKind.Interface && to.Kind == ElementKind.Interface);
                    if (!genOk)
                        return Validity.Invalid("generalization is class→class or interface→interface only");
                    // would-create-cycle: target must not already (transitively) generalize the source.
                    if (CreatesGeneralizationCycle(model, fromId, toId))
                        return Validity.Invalid("would create an inheritance cycle");
                    return Validity.Valid;

                case EdgeKind.Realization:
                    if (selfEdge) return Validity.Invalid("a type cannot realize itself");
                    // class/struct → interface (§4.4: realization: class→interface).
                    bool realOk = (from.Kind is ElementKind.Class or ElementKind.Struct)
                                  && to.Kind == ElementKind.Interface;
                    return realOk
                        ? Validity.Valid
                        : Validity.Invalid("realization is class→interface");

                case EdgeKind.Aggregation:
                case EdgeKind.Composition:
                    if (selfEdge)
                        return Validity.Invalid("self aggregation/composition is not permitted");
                    // whole/part among classifiers (not packages).
                    return (KindInfo.IsClassifier(from.Kind) && KindInfo.IsClassifier(to.Kind))
                        ? Validity.Valid
                        : Validity.Invalid($"{kind} connects types, not packages");

                case EdgeKind.Association:
                    // Associations/transitions connect any diagram nodes (types, actors, use cases, states).
                    return (KindInfo.IsConnectable(from.Kind) && KindInfo.IsConnectable(to.Kind))
                        ? Validity.Valid
                        : Validity.Invalid("association connects diagram nodes");

                case EdgeKind.Dependency:
                    // loosest: any classifier or package → any classifier or package, and notes attach this way
                    // too (a note→element comment link is a dashed line). (§4.5: package-level dependency is legal.)
                    return KindInfo.IsConnectable(from.Kind) && KindInfo.IsConnectable(to.Kind)
                        ? Validity.Valid
                        : Validity.Invalid("dependency connects diagram nodes or packages");

                case EdgeKind.Transition:
                    // State-machine / activity flow. Self-transitions are legal (a state may loop on itself).
                    return KindInfo.IsConnectable(from.Kind) && KindInfo.IsConnectable(to.Kind)
                        ? Validity.Valid
                        : Validity.Invalid("a transition connects diagram nodes");

                case EdgeKind.DirectedAssociation:
                    return KindInfo.IsConnectable(from.Kind) && KindInfo.IsConnectable(to.Kind)
                        ? Validity.Valid
                        : Validity.Invalid("a directed association connects diagram nodes");

                case EdgeKind.Include:
                case EdgeKind.Extend:
                    if (selfEdge) return Validity.Invalid("«include»/«extend» connect two use cases");
                    return (from.Kind == ElementKind.UseCase && to.Kind == ElementKind.UseCase)
                        ? Validity.Valid
                        : Validity.Invalid("«include»/«extend» connect use cases");

                case EdgeKind.NoteLink:
                    // A comment anchor: one end is a note, the other is whatever it annotates.
                    return (from.Kind == ElementKind.Note || to.Kind == ElementKind.Note)
                        ? Validity.Valid
                        : Validity.Invalid("a note anchor must touch a note");

                case EdgeKind.MessageSync:
                case EdgeKind.MessageAsync:
                case EdgeKind.MessageReply:
                    // Sequence / communication messages between lifelines, activations and objects (self-calls ok).
                    return KindInfo.IsConnectable(from.Kind) && KindInfo.IsConnectable(to.Kind)
                        ? Validity.Valid
                        : Validity.Invalid("a message connects lifelines / objects");

                case EdgeKind.Extension:
                    if (selfEdge) return Validity.Invalid("an extension links a stereotype to a metaclass");
                    return (from.Kind == ElementKind.Stereotype && to.Kind == ElementKind.Metaclass)
                        ? Validity.Valid
                        : Validity.Invalid("«extension» links a stereotype → metaclass");

                default:
                    return Validity.Invalid("unknown relationship");
            }
        }

        /// <summary>True if adding <c>from --generalizes--&gt; to</c> would close a cycle (to already reaches from).</summary>
        private static bool CreatesGeneralizationCycle(AuthoringModel model, ElementId fromId, ElementId toId)
        {
            // Walk supertypes of `to` along existing generalization edges; if we reach `from`, it's a cycle.
            var stack = new System.Collections.Generic.Stack<ElementId>();
            var seen = new System.Collections.Generic.HashSet<ElementId>();
            stack.Push(toId);
            while (stack.Count > 0)
            {
                var cur = stack.Pop();
                if (cur == fromId) return true;
                if (!seen.Add(cur)) continue;
                foreach (var edge in model.Edges)
                    if (edge.Kind == EdgeKind.Generalization && edge.From == cur)
                        stack.Push(edge.To);
            }
            return false;
        }
    }
}
