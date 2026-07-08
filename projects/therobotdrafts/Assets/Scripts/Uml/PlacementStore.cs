using System.Collections.Generic;
using UnityEngine;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// The geometry of one node within one diagram. Bundles the five per-node geometry facets that used to live
    /// in parallel <c>ElementId</c>-keyed dictionaries on <see cref="UmlCanvas"/> (<c>_pos/_size/_posZ/_nodeDepth/_nodeRot</c>).
    /// </summary>
    /// <remarks>
    /// Bundling loses the old "is this key present?" signal that <c>_nodeDepth</c> / <c>_nodeRot</c> used to mean
    /// "unset → use the default". So the store's accessors re-derive that from the value itself: <see cref="HasSize"/>
    /// (x&gt;1 &amp;&amp; y&gt;1, matching the existing convention), <c>Depth &gt; 0</c>, and <see cref="HasRot"/>
    /// (not identity). <c>PosZ == 0</c> is already the identity offset, so no "present" flag is needed for it.
    /// </remarks>
    public struct Placement
    {
        public Vector2 Pos;      // node centre, model px, Y-up   (was _pos)
        public Vector2 Size;     // px; unset when !HasSize       (was _size)
        public float PosZ;       // continuous world-Z offset     (was _posZ)
        public float Depth;      // slab thickness, world units; 0 ⇒ unset (was _nodeDepth)
        public Quaternion Rot;   // local orientation; identity ⇒ unset    (was _nodeRot)

        public bool HasSize => Size.x > 1f && Size.y > 1f;
        public bool HasRot  => Rot != Quaternion.identity;

        public static Placement At(Vector2 pos) => new Placement { Pos = pos, Rot = Quaternion.identity };
    }

    /// <summary>
    /// Per-diagram node geometry. Outer key = the diagram (the active package/page id — i.e. <c>UmlCanvas._activePackage</c>);
    /// inner key = element. The same element can therefore be placed (linked, not cloned) in several diagrams with
    /// independent geometry.
    /// </summary>
    /// <remarks>
    /// An <see cref="Active"/> scope pointer is kept in sync by <c>UmlCanvas.SetActivePackage</c> so the many interactive
    /// call sites read/write the current diagram with no extra argument (the implicit-scope accessors — <see cref="Pos"/>,
    /// <see cref="SetPos"/>, …), exactly like the old <c>_pos[id]</c>. Save/load and interchange iterate several diagrams
    /// and use the explicit-scope members (<see cref="Set"/>, <see cref="TryGet"/>, <see cref="InDiagram"/>, …).
    /// </remarks>
    public sealed class PlacementStore
    {
        private readonly Dictionary<ElementId, Dictionary<ElementId, Placement>> _byDiagram = new();
        private ElementId _active = ElementId.None;

        /// <summary>The diagram every implicit-scope accessor targets. Set from <c>UmlCanvas.SetActivePackage</c>.</summary>
        public ElementId Active { get => _active; set => _active = value; }

        private Dictionary<ElementId, Placement> ScopeOf(ElementId diagram, bool create)
        {
            if (!diagram.IsValid) return null;
            if (_byDiagram.TryGetValue(diagram, out var m)) return m;
            if (!create) return null;
            m = new Dictionary<ElementId, Placement>();
            _byDiagram[diagram] = m;
            return m;
        }

        private static Placement Normalize(Placement p)
        {
            if (p.Rot == default) p.Rot = Quaternion.identity; // (0,0,0,0) is not a valid rotation — treat as unset
            return p;
        }

        // ---- explicit-scope core (save/load, interchange — iterate several diagrams) ----

        public bool TryGet(ElementId diagram, ElementId id, out Placement p)
        {
            var m = ScopeOf(diagram, false);
            if (m != null) return m.TryGetValue(id, out p);
            p = default; return false;
        }

        /// <summary>Add or overwrite an element's geometry in a specific diagram (also the drag-drop-LINK case).</summary>
        public void Set(ElementId diagram, ElementId id, Placement p)
        {
            var m = ScopeOf(diagram, true);
            if (m != null) m[id] = Normalize(p);
        }

        public bool Contains(ElementId diagram, ElementId id)
        {
            var m = ScopeOf(diagram, false);
            return m != null && m.ContainsKey(id);
        }

        /// <summary>The (element → geometry) entries placed in a diagram — its membership + geometry. Empty if none.</summary>
        public IEnumerable<KeyValuePair<ElementId, Placement>> InDiagram(ElementId diagram)
        {
            var m = ScopeOf(diagram, false);
            if (m == null) yield break;
            foreach (var kv in m) yield return kv;
        }

        /// <summary>Every diagram scope that holds at least one placement.</summary>
        public IEnumerable<ElementId> Diagrams => _byDiagram.Keys;

        /// <summary>Every diagram in which <paramref name="element"/> is placed (native or linked). For C1's browse tree.</summary>
        public IEnumerable<ElementId> DiagramsPlacing(ElementId element)
        {
            foreach (var kv in _byDiagram)
                if (kv.Value.ContainsKey(element)) yield return kv.Key;
        }

        // ---- implicit active-scope accessors (drop-in for the interactive call sites) ----

        /// <summary>Active-scope placement, or a zero/identity default when absent.</summary>
        public Placement Get(ElementId id) => TryGet(_active, id, out var p) ? p : Placement.At(Vector2.zero);

        public Vector2 Pos(ElementId id) => TryGet(_active, id, out var p) ? p.Pos : Vector2.zero;
        public bool TryPos(ElementId id, out Vector2 v)
        {
            if (TryGet(_active, id, out var p)) { v = p.Pos; return true; }
            v = default; return false;
        }

        /// <summary>Active-scope size, true only when a real (x&gt;1,y&gt;1) size is stored — matches the old <c>s.x&gt;1f</c> guard.</summary>
        public bool TrySize(ElementId id, out Vector2 v)
        {
            if (TryGet(_active, id, out var p) && p.HasSize) { v = p.Size; return true; }
            v = default; return false;
        }

        /// <summary>Active-scope world-Z offset (0 when absent — the identity offset).</summary>
        public float PosZ(ElementId id) => TryGet(_active, id, out var p) ? p.PosZ : 0f;

        /// <summary>Active-scope slab thickness, true only when a real (&gt;0) depth is stored — matches the old key-present guard.</summary>
        public bool TryDepth(ElementId id, out float v)
        {
            if (TryGet(_active, id, out var p) && p.Depth > 0f) { v = p.Depth; return true; }
            v = 0f; return false;
        }

        /// <summary>Active-scope orientation, true only when a non-identity rotation is stored.</summary>
        public bool TryRot(ElementId id, out Quaternion v)
        {
            if (TryGet(_active, id, out var p) && p.HasRot) { v = p.Rot; return true; }
            v = Quaternion.identity; return false;
        }

        // ---- implicit active-scope mutators (seed the entry if absent, preserving other facets) ----
        // Written out (no closures) because SetPos/SetSize fire every frame during a drag — a lambda per call would
        // churn the GC. Placement is a struct, so get-modify-store stays alloc-free.

        private bool Begin(ElementId id, out Dictionary<ElementId, Placement> m, out Placement p)
        {
            m = ScopeOf(_active, true);
            if (m == null) { p = default; return false; } // no active diagram — nothing to place into
            p = m.TryGetValue(id, out var cur) ? cur : Placement.At(Vector2.zero);
            return true;
        }

        public void SetPos(ElementId id, Vector2 v)    { if (Begin(id, out var m, out var p)) { p.Pos = v;   m[id] = p; } }
        public void SetSize(ElementId id, Vector2 v)   { if (Begin(id, out var m, out var p)) { p.Size = v;  m[id] = p; } }
        public void SetPosZ(ElementId id, float v)     { if (Begin(id, out var m, out var p)) { p.PosZ = v;  m[id] = p; } }
        public void SetDepth(ElementId id, float v)    { if (Begin(id, out var m, out var p)) { p.Depth = v; m[id] = p; } }
        public void SetRot(ElementId id, Quaternion v) { if (Begin(id, out var m, out var p)) { p.Rot = v;   m[id] = p; } }

        /// <summary>Ensure the active diagram has an entry for a natively-parented element (replaces the lazy seed in
        /// <c>RebuildFromModel</c>): returns the existing placement, or seeds &amp; returns <c>Placement.At(seed)</c>.</summary>
        public Placement EnsureNative(ElementId id, Vector2 seed)
        {
            var m = ScopeOf(_active, true);
            if (m == null) return Placement.At(seed);
            if (!m.TryGetValue(id, out var p)) { p = Placement.At(seed); m[id] = p; }
            return p;
        }

        // ---- lifecycle ----

        /// <summary>Remove an element from ONE diagram (un-link). Leaves its other appearances intact.</summary>
        public void Remove(ElementId diagram, ElementId id) => ScopeOf(diagram, false)?.Remove(id);

        /// <summary>Remove an element from EVERY diagram (the element was deleted from the model).</summary>
        public void RemoveEverywhere(ElementId id)
        {
            foreach (var m in _byDiagram.Values) m.Remove(id);
        }

        /// <summary>Drop a whole diagram's geometry (delete-diagram / reset).</summary>
        public void RemoveDiagram(ElementId diagram) => _byDiagram.Remove(diagram);

        public void Clear() { _byDiagram.Clear(); _active = ElementId.None; }

        // ---- geometry undo (whole-store snapshot; replaces cloning five dictionaries) ----

        public PlacementStore Clone()
        {
            var c = new PlacementStore { _active = _active };
            foreach (var kv in _byDiagram)
                c._byDiagram[kv.Key] = new Dictionary<ElementId, Placement>(kv.Value);
            return c;
        }

        public void RestoreFrom(PlacementStore snap)
        {
            _byDiagram.Clear();
            foreach (var kv in snap._byDiagram)
                _byDiagram[kv.Key] = new Dictionary<ElementId, Placement>(kv.Value);
            _active = snap._active;
        }
    }
}
