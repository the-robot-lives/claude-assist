using System.Collections.Generic;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Authoring.State
{
    /// <summary>
    /// Resolves the EFFECTIVE aspect set for a node or edge by merging the four sparse scope layers in precedence
    /// order, then overlaying any aspect instances already authored on the element. The result is a flat, ready-to-
    /// consume view (<see cref="EffectiveAspect"/>) carrying each aspect's def version, its resolved field values
    /// (def default + instance override), and its resolved <see cref="EmitFlags"/> — what code-gen, the meta sidecar,
    /// and the inspector all read.
    ///
    /// <para>The scope ladder (lowest → highest precedence, matching <see cref="SystemAspects"/>):
    /// <list type="number">
    /// <item><term>Global</term><description>every node gets these (Scope=Global).</description></item>
    /// <item><term>ElementType</term><description>def whose Scope=ElementType matches the node's <see cref="ElementKind"/>.</description></item>
    /// <item><term>ElementType+Graph</term><description>def whose Scope=ElementTypeAndGraph matches kind AND the graph type.</description></item>
    /// <item><term>Stereotype bundle</term><description>aspects registered via <see cref="AspectRegistry.SetBundle"/> for the node's stereotype.</description></item>
    /// </list>
    /// Each layer contributes a SHALLOW aspect: only the def name is attached; no field values are copied until the
    /// user edits one (per the design's sparse-shallow rule). Explicitly-authored instances on the element then win
    /// over every layer.</para>
    ///
    /// <para>Graph type for an element is derived from the host diagram when known; callers pass it (or
    /// <see cref="GraphType.Unspecified"/>) so the resolver stays free of canvas/diagram dependencies.</para>
    /// </summary>
    public static class AspectAttachment
    {
        /// <summary>One resolved aspect: the def it resolved against, the instance (may be null = pure scope default),
        /// the resolved field values, and the resolved emit flags.</summary>
        public sealed class EffectiveAspect
        {
            /// <summary>The definition the instance resolved against (system baseline or user version). Null if the def vanished.</summary>
            public AspectDef Def;
            /// <summary>The authored instance, if any (carries the def version it was authored against + overrides). Null = scope-attached only.</summary>
            public AspectInstance Instance;
            /// <summary>Effective per-field values: instance override if present, else def default. Empty when no fields.</summary>
            public readonly Dictionary<string, string> Values = new();
            /// <summary>Effective emit flags after applying the instance override to the def defaults (respecting locks).</summary>
            public EmitFlags Emit;
            /// <summary>True when this aspect came purely from a scope layer (never authored on the element).</summary>
            public bool FromScope;
        }

        /// <summary>Resolve the effective aspect list for an ELEMENT. Layers: global → element-type → element-type+graph
        /// → stereotype-bundle, then the element's own authored aspects overlay all of them. Stable order: scope order,
        /// then authored-appended; duplicates collapse to the highest-precedence source.</summary>
        public static List<EffectiveAspect> ResolveElement(ModelElement el, GraphType graph)
        {
            var byName = new Dictionary<string, EffectiveAspect>();
            var order = new List<string>();

            void AddLayer(AspectDef def, bool fromScope)
            {
                if (def == null || string.IsNullOrEmpty(def.Name)) return;
                if (byName.ContainsKey(def.Name)) return; // first (lowest) layer wins precedence ordering; authored overrides later replace the entry
                var ea = new EffectiveAspect { Def = def, FromScope = fromScope };
                FillDefaults(ea);
                byName[def.Name] = ea;
                order.Add(def.Name);
            }

            // layer 1: global (every node)
            foreach (var d in AspectRegistry.LoadAll())
                if (d.Scope == AspectScope.Global) AddLayer(d, true);
            // layer 2: element-type
            if (el != null)
            {
                foreach (var d in AspectRegistry.LoadAll())
                    if (d.Scope == AspectScope.ElementType && d.ElementType == el.Kind) AddLayer(d, true);
                // layer 3: element-type + graph
                foreach (var d in AspectRegistry.LoadAll())
                    if (d.Scope == AspectScope.ElementTypeAndGraph && d.ElementType == el.Kind && d.GraphType == graph) AddLayer(d, true);
                // layer 4: stereotype bundle (shallow)
                if (!string.IsNullOrEmpty(el.Stereotype))
                    foreach (var name in AspectRegistry.BundleFor(el.Stereotype))
                    {
                        var d = AspectRegistry.Get(name);
                        if (d != null) AddLayer(d, true);
                    }
            }
            // overlay: authored instances (these win — they carry real edits + emit overrides)
            if (el != null && el.AspectSet != null)
            {
                foreach (var inst in el.AspectSet.Aspects)
                {
                    if (inst == null || string.IsNullOrEmpty(inst.DefName)) continue;
                    var def = AspectRegistry.Get(inst.DefName) ?? FindInLayers(byName, inst.DefName);
                    var ea = new EffectiveAspect { Def = def, Instance = AspectResolution.Clone(inst), FromScope = false };
                    if (def != null)
                    {
                        // resolve each field to its effective value, then re-seal locked defaults the override may have tried to break
                        foreach (var f in def.Fields)
                        {
                            if (f == null) continue;
                            string val = AspectResolution.EffectiveValue(def, inst, f.Name);
                            if (!AspectResolution.IsFieldEditable(def, f.Name)) val = AspectResolution.FieldDefault(def, f.Name);
                            ea.Values[f.Name] = val ?? "";
                        }
                        ea.Emit = AspectResolution.EffectiveEmit(def, inst);
                    }
                    else
                    {
                        ea.Emit = inst.EmitOverride ?? default;
                    }
                    if (!byName.ContainsKey(inst.DefName)) order.Add(inst.DefName);
                    byName[inst.DefName] = ea;
                }
            }
            var out_ = new List<EffectiveAspect>(order.Count);
            foreach (var name in order) out_.Add(byName[name]);
            return out_;
        }

        /// <summary>Resolve the effective aspect list for an EDGE. Edges carry no kind/graph scopes in the baseline, so
        /// only the global layer + the edge's own authored aspects apply. Same overlay semantics as elements.</summary>
        public static List<EffectiveAspect> ResolveEdge(ModelEdge edge)
        {
            var byName = new Dictionary<string, EffectiveAspect>();
            var order = new List<string>();
            foreach (var d in AspectRegistry.LoadAll())
                if (d.Scope == AspectScope.Global && !byName.ContainsKey(d.Name))
                {
                    var ea = new EffectiveAspect { Def = d, FromScope = true };
                    FillDefaults(ea);
                    byName[d.Name] = ea;
                    order.Add(d.Name);
                }
            if (edge != null && edge.AspectSet != null)
            {
                foreach (var inst in edge.AspectSet.Aspects)
                {
                    if (inst == null || string.IsNullOrEmpty(inst.DefName)) continue;
                    var def = AspectRegistry.Get(inst.DefName);
                    var ea = new EffectiveAspect { Def = def, Instance = AspectResolution.Clone(inst), FromScope = false };
                    if (def != null)
                    {
                        foreach (var f in def.Fields)
                        {
                            if (f == null) continue;
                            string val = AspectResolution.EffectiveValue(def, inst, f.Name);
                            if (!AspectResolution.IsFieldEditable(def, f.Name)) val = AspectResolution.FieldDefault(def, f.Name);
                            ea.Values[f.Name] = val ?? "";
                        }
                        ea.Emit = AspectResolution.EffectiveEmit(def, inst);
                    }
                    else
                    {
                        ea.Emit = inst.EmitOverride ?? default;
                    }
                    if (!byName.ContainsKey(inst.DefName)) order.Add(inst.DefName);
                    byName[inst.DefName] = ea;
                }
            }
            var out_ = new List<EffectiveAspect>(order.Count);
            foreach (var name in order) out_.Add(byName[name]);
            return out_;
        }

        /// <summary>Collect the authored freeform key-values on an element (sparse — exactly what the user typed).</summary>
        public static List<FreeformEntry> FreeformElement(ModelElement el) =>
            el?.AspectSet?.Freeform == null ? new List<FreeformEntry>() : new List<FreeformEntry>(el.AspectSet.Freeform);

        /// <summary>Collect the authored freeform key-values on an edge.</summary>
        public static List<FreeformEntry> FreeformEdge(ModelEdge edge) =>
            edge?.AspectSet?.Freeform == null ? new List<FreeformEntry>() : new List<FreeformEntry>(edge.AspectSet.Freeform);

        /// <summary>
        /// Auto-attach (shallow) any scope aspects the element is MISSING, writing back onto the element's aspect set
        /// as empty instances. Used when a stereotype is applied or a new element is created so the inspector shows the
        /// bundle immediately without copying any field values. No-op for aspects already present.
        /// </summary>
        public static void EnsureScoped(ModelElement el, GraphType graph)
        {
            if (el == null || el.AspectSet == null) return;
            var present = new HashSet<string>();
            foreach (var a in el.AspectSet.Aspects) if (a != null && !string.IsNullOrEmpty(a.DefName)) present.Add(a.DefName);
            foreach (var ea in ResolveElement(el, graph))
            {
                if (ea.Def == null || !ea.FromScope) continue;
                if (present.Contains(ea.Def.Name)) continue;
                var d = ea.Def;
                el.AspectSet.Aspects.Add(new AspectInstance
                {
                    DefName = d.Name,
                    DefVersion = d.Version,
                    Overrides = new Dictionary<string, string>(),
                });
            }
        }

        private static void FillDefaults(EffectiveAspect ea)
        {
            if (ea.Def?.Fields == null) return;
            foreach (var f in ea.Def.Fields)
                if (f != null) ea.Values[f.Name] = f.Default ?? "";
            ea.Emit = ea.Def.Emit;
        }

        private static AspectDef FindInLayers(Dictionary<string, EffectiveAspect> byName, string name) =>
            byName.TryGetValue(name, out var ea) ? ea.Def : null;
    }
}
