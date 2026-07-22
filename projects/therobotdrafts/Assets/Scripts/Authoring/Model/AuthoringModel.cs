using System;
using System.Collections.Generic;

namespace TheRobotDraft.Authoring.Model
{
    /// <summary>One element (node) in the unified model: a kind, a name, a containment parent, and modifiers.</summary>
    public sealed class ModelElement
    {
        public ElementId Id { get; }
        public ElementKind Kind { get; internal set; }
        public string Name { get; internal set; }
        public ElementId Parent { get; internal set; }

        /// <summary>UML <c>abstract</c> is a modifier, not a kind (§3.1) — outline/wireframe glyph.</summary>
        public bool IsAbstract { get; internal set; }

        /// <summary>
        /// Implementation language for a classifier (e.g. "C#", "Java", "C++", "TypeScript") — Rational Rose /
        /// Sparx EA track this per type so generated code and type semantics follow the right grammar.
        /// Null/empty = unspecified. Members ignore it.
        /// </summary>
        public string Language { get; internal set; }

        /// <summary>
        /// Custom UML stereotype override (e.g. "entity", "service", "controller"). When set it replaces the
        /// kind-derived «interface»/«enumeration» guillemet label. Null/empty = use the derived stereotype.
        /// </summary>
        public string Stereotype { get; internal set; }

        /// <summary>Free-text UML/product description of this element. Null/empty = none.</summary>
        public string Description { get; internal set; }

        /// <summary>
        /// Source-code documentation for this element. Distinct from <see cref="Description"/>: this is imported from
        /// doc-comments and emitted back above generated types, fields, operations, and properties. Null/empty = none.
        /// </summary>
        public string CodeDoc { get; internal set; }

        /// <summary>
        /// The element's saved source code — the approved output of "Generate code", and the round-trip
        /// counterpart to code→elements (the module/class body lives on the node). Null/empty = none.
        /// </summary>
        public string Code { get; internal set; }

        /// <summary>
        /// The source file this element was imported from (relative or absolute path) — set by folder import and
        /// used to drive surgical overlay regeneration back into the same file. Null/empty = none.
        /// </summary>
        public string SourceFile { get; internal set; }

        /// <summary>Stable UUIDv5 identity for documentation deep links. Null only for legacy/corrupt data.</summary>
        public string DeepLinkUuid { get; internal set; }

        /// <summary>Four-codepoint Unicode token derived from <see cref="DeepLinkUuid"/> for compact doc pointers.</summary>
        public string DeepLinkCode { get; internal set; }

        /// <summary>Whether generated source should embed this element's deep-link declaration in its doc comment.</summary>
        public bool EmbedDeepLinkCode { get; internal set; }

        /// <summary>
        /// The diagram Z-layer this element lives on (0 = base). The canvas shows one active layer; elements on
        /// other layers are hidden, with cross-layer relationships shown as up/down connector stubs.
        /// </summary>
        public int ZLayer { get; internal set; }

        /// <summary>
        /// Kind-specific value list: dropdown options, list rows, table columns, tabs, menu entries, etc. These are
        /// owned by the element itself, not modeled as Field/Function members.
        /// </summary>
        internal readonly List<string> PropertyItems = new();

        // Typed, sparse aspect attachments + freeform entries (see Aspects.cs). Sparse: instances store only
        // overridden field values; defaults + key list live on the registry AspectDef.
        internal readonly AspectSet Aspects = new();

        internal readonly List<ElementId> Children = new();

        internal ModelElement(ElementId id, ElementKind kind, string name, ElementId parent)
        {
            Id = id;
            Kind = kind;
            Name = name;
            Parent = parent;
            DeepLinkUuid = DeepLinkIdentity.Uuid5ForElement(id, kind, name, parent);
            DeepLinkCode = DeepLinkIdentity.EncodeToken(DeepLinkUuid);
            EmbedDeepLinkCode = DeepLinkIdentity.DefaultEmbed(kind);
        }

        public IReadOnlyList<ElementId> ChildIds => Children;
        public IReadOnlyList<string> Items => PropertyItems;
        public AspectSet AspectSet => Aspects;
    }

    /// <summary>One relationship (edge) in the unified model. Direction is from→to (§4.2).</summary>
    public sealed class ModelEdge
    {
        public EdgeId Id { get; }
        public EdgeKind Kind { get; internal set; }
        public ElementId From { get; internal set; }
        public ElementId To { get; internal set; }

        /// <summary>Association name / role label drawn at the relationship's midpoint (e.g. "line item"). Null = none.</summary>
        public string Label { get; internal set; }

        /// <summary>UML multiplicity at the <see cref="From"/> end (e.g. "1", "0..*", "1..*"). Null = unspecified.</summary>
        public string SourceMultiplicity { get; internal set; }

        /// <summary>UML multiplicity at the <see cref="To"/> end (e.g. "1", "0..*", "1..*"). Null = unspecified.</summary>
        public string TargetMultiplicity { get; internal set; }

        /// <summary>A constraint on the relationship, drawn in braces (e.g. "{ordered}", "{xor}", a guard). Null = none.</summary>
        public string Constraint { get; internal set; }

        // Typed, sparse aspect attachments + freeform entries for the link (see Aspects.cs).
        internal readonly AspectSet Aspects = new();

        /// <summary>Stable UUIDv5 identity for the edge (documentation pointers + aspect sidecar keys). Null until computed.</summary>
        public string DeepLinkUuid { get; internal set; }

        /// <summary>Compact Unicode token (⟦code⟧) derived from <see cref="DeepLinkUuid"/>; the aspect sidecar key.</summary>
        public string DeepLinkCode { get; internal set; }

        internal ModelEdge(EdgeId id, EdgeKind kind, ElementId from, ElementId to)
        {
            Id = id;
            Kind = kind;
            From = from;
            To = to;
            DeepLinkUuid = DeepLinkIdentity.Uuid5ForEdge(id, kind, from, to, null);
            try { DeepLinkCode = DeepLinkIdentity.EncodeToken(DeepLinkUuid); }
            catch { DeepLinkCode = null; }
        }

        public AspectSet AspectSet => Aspects;
    }

    /// <summary>
    /// The in-memory unified model that authoring verbs mutate (authoring-ux.md §0.2: every verb is a model
    /// edit; all views are re-derived from this). This type owns the containment <em>tree</em> and the edge
    /// list and enforces structural integrity (a node has exactly one parent; ids are unique). It does
    /// <em>not</em> own geometry — positions/radii are the packer's job (ADR-003) and live behind
    /// <see cref="Seams.IPacker"/>. Mutators are deliberately low-level and reversible so the command layer
    /// (§0.2 "each is a single undo step") can compose and unwind them precisely.
    /// </summary>
    public sealed class AuthoringModel
    {
        private readonly Dictionary<ElementId, ModelElement> _elements = new();
        private readonly Dictionary<EdgeId, ModelEdge> _edges = new();

        public IReadOnlyCollection<ModelElement> Elements => _elements.Values;
        public IReadOnlyCollection<ModelEdge> Edges => _edges.Values;

        public bool TryGet(ElementId id, out ModelElement element) => _elements.TryGetValue(id, out element);
        public bool TryGet(EdgeId id, out ModelEdge edge) => _edges.TryGetValue(id, out edge);
        public bool Contains(ElementId id) => _elements.ContainsKey(id);

        public ModelElement Get(ElementId id) =>
            _elements.TryGetValue(id, out var e) ? e : throw new KeyNotFoundException($"element {id}");

        public ModelEdge Get(EdgeId id) =>
            _edges.TryGetValue(id, out var e) ? e : throw new KeyNotFoundException($"edge {id}");

        // --- element mutators (called only by commands) ---

        internal ModelElement AddElement(ElementId id, ElementKind kind, string name, ElementId parent,
            bool isAbstract)
        {
            if (_elements.ContainsKey(id))
                throw new InvalidOperationException($"element {id} already exists");
            if (parent.IsValid && !_elements.ContainsKey(parent))
                throw new InvalidOperationException($"parent {parent} does not exist");

            var element = new ModelElement(id, kind, name, parent) { IsAbstract = isAbstract };
            _elements.Add(id, element);
            if (parent.IsValid)
                _elements[parent].Children.Add(id);
            return element;
        }

        internal void RemoveElement(ElementId id)
        {
            if (!_elements.TryGetValue(id, out var element)) return;
            if (element.Parent.IsValid && _elements.TryGetValue(element.Parent, out var parent))
                parent.Children.Remove(id);
            _elements.Remove(id);
        }

        internal void Reparent(ElementId id, ElementId newParent)
        {
            var element = _elements[id];
            if (element.Parent.IsValid && _elements.TryGetValue(element.Parent, out var old))
                old.Children.Remove(id);
            element.Parent = newParent;
            if (newParent.IsValid)
                _elements[newParent].Children.Add(id);
        }

        internal void Rename(ElementId id, string name) => _elements[id].Name = name;
        internal void SetKind(ElementId id, ElementKind kind) => _elements[id].Kind = kind;
        internal void SetAbstract(ElementId id, bool isAbstract) => _elements[id].IsAbstract = isAbstract;
        internal void SetLanguage(ElementId id, string language) => _elements[id].Language = language;
        internal void SetStereotype(ElementId id, string stereotype) => _elements[id].Stereotype = stereotype;
        internal void SetDescription(ElementId id, string description) => _elements[id].Description = description;
        internal void SetCodeDoc(ElementId id, string codeDoc) => _elements[id].CodeDoc = codeDoc;
        internal void SetDeepLink(ElementId id, string uuid, string code)
        {
            var element = _elements[id];
            if (!string.IsNullOrWhiteSpace(uuid))
            {
                element.DeepLinkUuid = uuid.Trim().ToLowerInvariant();
                if (!string.IsNullOrWhiteSpace(code)) element.DeepLinkCode = code.Trim();
                else
                {
                    try { element.DeepLinkCode = DeepLinkIdentity.EncodeToken(element.DeepLinkUuid); }
                    catch { element.DeepLinkCode = null; }
                }
            }
            else if (!string.IsNullOrWhiteSpace(code))
            {
                element.DeepLinkCode = code.Trim();
            }
        }
        internal void SetEmbedDeepLinkCode(ElementId id, bool embed) => _elements[id].EmbedDeepLinkCode = embed;
        internal void SetPropertyItems(ElementId id, IEnumerable<string> items)
        {
            var list = _elements[id].PropertyItems;
            list.Clear();
            if (items == null) return;
            foreach (var item in items)
            {
                if (string.IsNullOrWhiteSpace(item)) continue;
                list.Add(item.Trim());
            }
        }

        // --- aspect mutators (sparse: instances carry only overridden field values) ---
        // Keys (def names, field names, freeform keys) must be non-empty + whitespace-free (AspectResolution.IsValidKey);
        // invalid keys are dropped on set rather than stored, so they can never reach .trd-yaml serialization.

        /// <summary>Replace an element's full aspect set (typed instances + freeform entries).</summary>
        internal void SetElementAspects(ElementId id, IEnumerable<AspectInstance> aspects, IEnumerable<FreeformEntry> freeform)
        {
            var set = _elements[id].Aspects;
            set.Aspects.Clear();
            set.Freeform.Clear();
            if (aspects != null) foreach (var a in aspects) if (a != null && AspectResolution.IsValidKey(a.DefName)) set.Aspects.Add(CleanInstance(a));
            if (freeform != null) foreach (var f in freeform) if (f != null && AspectResolution.IsValidKey(f.Key)) set.Freeform.Add(f);
        }

        /// <summary>Drop any override keys that are not valid (non-empty, whitespace-free) — defensive scrub.</summary>
        private static AspectInstance CleanInstance(AspectInstance a)
        {
            if (a.Overrides == null) return a;
            var bad = new List<string>();
            foreach (var k in a.Overrides.Keys) if (!AspectResolution.IsValidKey(k)) bad.Add(k);
            foreach (var k in bad) a.Overrides.Remove(k);
            return a;
        }

        /// <summary>
        /// Sparse single-field edit: set or clear one overridden value on an element's aspect instance. If the
        /// instance does not yet exist it is added (referencing <paramref name="defName"/>/<paramref name="defVersion"/>).
        /// Pass a null/empty value to drop the override (revert to the def default).
        /// </summary>
        internal void EditAspectOverride(ElementId id, string defName, int defVersion, string field, string value)
        {
            if (!AspectResolution.IsValidKey(field)) return; // whitespace/empty keys never stored
            var set = _elements[id].Aspects;
            var inst = FindOrAdd(set, defName, defVersion);
            if (string.IsNullOrEmpty(value)) inst.Overrides.Remove(field);
            else inst.Overrides[field] = value;
        }

        /// <summary>Set the per-instance emit-flag override on an element's aspect (null = revert to def defaults).</summary>
        internal void SetElementAspectEmit(ElementId id, string defName, int defVersion, EmitFlags? emitOverride)
        {
            var inst = FindOrAdd(_elements[id].Aspects, defName, defVersion);
            inst.EmitOverride = emitOverride;
        }
        internal void SetCode(ElementId id, string code) => _elements[id].Code = code;
        internal void SetSourceFile(ElementId id, string sourceFile) => _elements[id].SourceFile = sourceFile;
        internal void SetZLayer(ElementId id, int z) => _elements[id].ZLayer = z;

        // --- edge mutators ---

        internal ModelEdge AddEdge(EdgeId id, EdgeKind kind, ElementId from, ElementId to)
        {
            if (_edges.ContainsKey(id))
                throw new InvalidOperationException($"edge {id} already exists");
            var edge = new ModelEdge(id, kind, from, to);
            _edges.Add(id, edge);
            return edge;
        }

        internal void RemoveEdge(EdgeId id) => _edges.Remove(id);
        internal void SetEdgeType(EdgeId id, EdgeKind kind) => _edges[id].Kind = kind;
        internal void SetEdgeLabel(EdgeId id, string label) => _edges[id].Label = label;
        internal void SetEdgeMultiplicity(EdgeId id, string source, string target)
        {
            var edge = _edges[id];
            edge.SourceMultiplicity = source;
            edge.TargetMultiplicity = target;
        }
        internal void SetEdgeConstraint(EdgeId id, string constraint) => _edges[id].Constraint = constraint;

        // --- edge aspect mutators (mirror the element ones) ---

        internal void SetEdgeAspects(EdgeId id, IEnumerable<AspectInstance> aspects, IEnumerable<FreeformEntry> freeform)
        {
            var set = _edges[id].Aspects;
            set.Aspects.Clear();
            set.Freeform.Clear();
            if (aspects != null) foreach (var a in aspects) if (a != null && AspectResolution.IsValidKey(a.DefName)) set.Aspects.Add(CleanInstance(a));
            if (freeform != null) foreach (var f in freeform) if (f != null && AspectResolution.IsValidKey(f.Key)) set.Freeform.Add(f);
        }

        internal void EditEdgeAspectOverride(EdgeId id, string defName, int defVersion, string field, string value)
        {
            if (!AspectResolution.IsValidKey(field)) return;
            var set = _edges[id].Aspects;
            var inst = FindOrAdd(set, defName, defVersion);
            if (string.IsNullOrEmpty(value)) inst.Overrides.Remove(field);
            else inst.Overrides[field] = value;
        }

        internal void SetEdgeAspectEmit(EdgeId id, string defName, int defVersion, EmitFlags? emitOverride)
        {
            var inst = FindOrAdd(_edges[id].Aspects, defName, defVersion);
            inst.EmitOverride = emitOverride;
        }

        private static AspectInstance FindOrAdd(AspectSet set, string defName, int defVersion)
        {
            foreach (var a in set.Aspects)
                if (a != null && a.DefName == defName) return a;
            var inst = new AspectInstance { DefName = defName, DefVersion = defVersion };
            set.Aspects.Add(inst);
            return inst;
        }
        internal void SetEdgeEndpoints(EdgeId id, ElementId from, ElementId to)
        {
            var edge = _edges[id];
            edge.From = from;
            edge.To = to;
        }
        /// <summary>Swap an edge's endpoints (and the end-anchored multiplicities) — flips the arrow direction.</summary>
        internal void ReverseEdge(EdgeId id)
        {
            var edge = _edges[id];
            (edge.From, edge.To) = (edge.To, edge.From);
            (edge.SourceMultiplicity, edge.TargetMultiplicity) = (edge.TargetMultiplicity, edge.SourceMultiplicity);
        }

        /// <summary>True if <paramref name="ancestor"/> contains <paramref name="node"/> transitively (cycle/containment checks).</summary>
        public bool IsAncestorOf(ElementId ancestor, ElementId node)
        {
            var cur = node;
            var guard = 0;
            while (cur.IsValid && _elements.TryGetValue(cur, out var e))
            {
                if (e.Parent == ancestor) return true;
                cur = e.Parent;
                if (++guard > 100_000) break; // defensive: malformed tree
            }
            return false;
        }
    }
}
