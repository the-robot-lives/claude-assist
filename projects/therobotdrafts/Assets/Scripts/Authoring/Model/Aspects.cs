using System.Collections.Generic;

namespace TheRobotDraft.Authoring.Model
{
    // Aspects: reusable, typed key-value metadata attached to nodes (ModelElement) and links
    // (ModelEdge). Two kinds: registry-typed aspects (an AspectInstance references an AspectDef by
    // name+version and stores ONLY overridden field values — defaults + the key list live on the def)
    // and freeform {key,value} entries. See docs/specs and the aspect plan.

    /// <summary>Field value type for a typed aspect field.</summary>
    public enum AspectFieldType { String, Int, Float, Bool, Enum, Options }

    /// <summary>
    /// The predefined-scope ladder for an aspect definition: how broadly it auto-attaches.
    /// Global = all nodes; ElementType = all nodes of one ElementKind; ElementTypeAndGraph = nodes of
    /// one ElementKind within one GraphType. User-authored aspects may also attach ad-hoc or via a
    /// stereotype bundle (see AspectAttachment).
    /// </summary>
    public enum AspectScope { AdHoc, Global, ElementType, ElementTypeAndGraph }

    /// <summary>
    /// Coarse graph/diagram type axis for ElementTypeAndGraph scoping. There is no DiagramType concept
    /// in the model today; this lightweight enum is the aspect-scope axis only (not a node kind).
    /// </summary>
    public enum GraphType
    {
        Unspecified,
        Class, Erd, State, Sequence, Activity, Component, Deployment,
        UseCase, MindMap, Bpmn, Whiteboard, SysML
    }

    /// <summary>
    /// Independent emit-target flags — an aspect may target several at once. Lives on the AspectDef as the
    /// default; an instance may override individual flags unless the matching EmitLocks bit is set.
    /// Annotate = native attribute/decorator/module-attr; DocTag = doc-comment tag; Comment = plain comment;
    /// Meta = write to the .trd.{file}.meta.yaml sidecar.
    /// </summary>
    public struct EmitFlags
    {
        public bool Annotate;
        public bool DocTag;
        public bool Comment;
        public bool Meta;

        public EmitFlags(bool annotate, bool docTag, bool comment, bool meta)
        { Annotate = annotate; DocTag = docTag; Comment = comment; Meta = meta; }

        public bool IsAny => Annotate || DocTag || Comment || Meta;
        public bool IsNone => !IsAny;

        public static readonly EmitFlags None = default;
    }

    /// <summary>Per-flag lock bits — when set, the instance may NOT override that emit flag.</summary>
    public struct EmitLocks
    {
        public bool Annotate;
        public bool DocTag;
        public bool Comment;
        public bool Meta;

        public EmitLocks(bool annotate, bool docTag, bool comment, bool meta)
        { Annotate = annotate; DocTag = docTag; Comment = comment; Meta = meta; }

        public static readonly EmitLocks None = default;
    }

    /// <summary>
    /// One typed field in an aspect definition. <see cref="Default"/> is the preset value (string-encoded,
    /// like IxElement.Tags); <see cref="Locked"/> marks it non-overridable on instances.
    /// <see cref="Restriction"/> is a single encoded constraint string (enum/options comma-list,
    /// "min..max", regex) kept flat for JSON compatibility.
    /// </summary>
    public sealed class AspectFieldDef
    {
        public string Name;
        public AspectFieldType Type;
        public string Restriction;
        public string Default;
        public bool Locked;
    }

    /// <summary>
    /// A versioned, scope-aware aspect definition held in the registry. Version bumps on every edit;
    /// prior versions are immutable so any two versions can be diffed. Instances reference a def by
    /// name + the DefVersion they were authored against.
    /// </summary>
    public sealed class AspectDef
    {
        public string Name;
        public string Description;
        public List<AspectFieldDef> Fields = new List<AspectFieldDef>();
        public EmitFlags Emit;
        public EmitLocks EmitLocks;
        public int Version = 1;
        public bool SystemOwned;
        public AspectScope Scope = AspectScope.AdHoc;
        public ElementKind? ElementType;
        public GraphType? GraphType;
    }

    /// <summary>
    /// A sparse aspect attachment: references the def (name + version) and stores ONLY the field values the
    /// user overrode. Effective value = <see cref="Overrides"/>[field] ?? def.Default[field]. Free of a def
    /// reference, an instance is meaningless — always resolve via the helpers in this file.
    /// </summary>
    public sealed class AspectInstance
    {
        public string DefName;
        public int DefVersion;
        public Dictionary<string, string> Overrides = new Dictionary<string, string>();
        /// <summary>Per-instance emit-flag override (only unlocked flags honored); null = use def defaults.</summary>
        public EmitFlags? EmitOverride;
    }

    /// <summary>Freeform {key, value} escape hatch — no registry def, no typing.</summary>
    public sealed class FreeformEntry
    {
        public string Key;
        public string Value;
    }

    /// <summary>The aspect collection attached to a node or edge.</summary>
    public sealed class AspectSet
    {
        public List<AspectInstance> Aspects = new List<AspectInstance>();
        public List<FreeformEntry> Freeform = new List<FreeformEntry>();
    }

    /// <summary>Resolution helpers — the single source of truth for effective values/flags/editability.</summary>
    public static class AspectResolution
    {
        /// <summary>Deep-clone an aspect instance (so undo snapshots are independent of live mutation).</summary>
        public static AspectInstance Clone(AspectInstance a)
        {
            if (a == null) return null;
            var c = new AspectInstance { DefName = a.DefName, DefVersion = a.DefVersion, EmitOverride = a.EmitOverride };
            if (a.Overrides != null) foreach (var kv in a.Overrides) c.Overrides[kv.Key] = kv.Value;
            return c;
        }

        /// <summary>Deep-clone a whole aspect set (instances + freeform).</summary>
        public static AspectSet Clone(AspectSet set)
        {
            var c = new AspectSet();
            if (set == null) return c;
            foreach (var a in set.Aspects) c.Aspects.Add(Clone(a));
            foreach (var f in set.Freeform) c.Freeform.Add(new FreeformEntry { Key = f?.Key, Value = f?.Value });
            return c;
        }

        /// <summary>
        /// A valid aspect def name / field key / freeform key: non-empty and contains NO whitespace. Keys are
        /// always single-quoted on .trd-yaml write and the reader's bare-scalar path can't split a spaced key,
        /// so we reject whitespace at the source rather than try to support it.
        /// </summary>
        public static bool IsValidKey(string key)
        {
            if (string.IsNullOrEmpty(key)) return false;
            for (int i = 0; i < key.Length; i++)
                if (char.IsWhiteSpace(key[i])) return false;
            return true;
        }
        /// <summary>Effective value of a field: the instance override if present, else the def default.</summary>
        public static string EffectiveValue(AspectDef def, AspectInstance inst, string field)
        {
            if (inst != null && inst.Overrides != null && inst.Overrides.TryGetValue(field, out var v) && v != null)
                return v;
            return FieldDefault(def, field);
        }

        public static string FieldDefault(AspectDef def, string field)
        {
            if (def?.Fields == null) return null;
            foreach (var f in def.Fields)
                if (f != null && f.Name == field) return f.Default;
            return null;
        }

        /// <summary>True if a field may be overridden on an instance (exists on the def and not locked).</summary>
        public static bool IsFieldEditable(AspectDef def, string field)
        {
            if (def?.Fields == null) return false;
            foreach (var f in def.Fields)
                if (f != null && f.Name == field) return !f.Locked;
            return false;
        }

        /// <summary>Effective emit flags: def defaults with the instance's override applied to unlocked flags only.</summary>
        public static EmitFlags EffectiveEmit(AspectDef def, AspectInstance inst)
        {
            var e = def != null ? def.Emit : default;
            if (inst == null || inst.EmitOverride == null || def == null) return e;
            var o = inst.EmitOverride.Value;
            var locks = def.EmitLocks;
            if (!locks.Annotate) e.Annotate = o.Annotate;
            if (!locks.DocTag) e.DocTag = o.DocTag;
            if (!locks.Comment) e.Comment = o.Comment;
            if (!locks.Meta) e.Meta = o.Meta;
            return e;
        }

        /// <summary>Normalize an instance: drop overrides for non-existent or locked fields, and drop no-op emit overrides.</summary>
        public static void Normalize(AspectDef def, AspectInstance inst)
        {
            if (inst == null) return;
            if (inst.Overrides == null) { inst.Overrides = new Dictionary<string, string>(); }
            if (def != null)
            {
                var keep = new Dictionary<string, string>();
                foreach (var kv in inst.Overrides)
                {
                    bool editable = false;
                    foreach (var f in def.Fields)
                        if (f != null && f.Name == kv.Key) { editable = !f.Locked; break; }
                    if (editable) keep[kv.Key] = kv.Value;
                }
                inst.Overrides = keep;
            }
            if (inst.EmitOverride.HasValue && def != null)
            {
                var o = inst.EmitOverride.Value;
                var d = def.Emit;
                var locks = def.EmitLocks;
                bool same = (!locks.Annotate || o.Annotate == d.Annotate) &&
                            (!locks.DocTag || o.DocTag == d.DocTag) &&
                            (!locks.Comment || o.Comment == d.Comment) &&
                            (!locks.Meta || o.Meta == d.Meta) &&
                            o.Annotate == d.Annotate && o.DocTag == d.DocTag &&
                            o.Comment == d.Comment && o.Meta == d.Meta;
                if (same) inst.EmitOverride = null;
            }
        }
    }
}
