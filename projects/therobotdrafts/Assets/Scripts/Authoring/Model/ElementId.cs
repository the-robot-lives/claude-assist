using System;

namespace TheRobotDraft.Authoring.Model
{
    /// <summary>
    /// Stable identity for a model element. The value is the element's <em>stable key</em> (qualified-name
    /// hash, rendering-and-vr.md §2.1 "stable addresses") so a node keeps its identity — and roughly its
    /// packed position — across edits and re-derivation. Authoring commands address elements by this id, never
    /// by transient array index or scene-object reference.
    /// </summary>
    public readonly struct ElementId : IEquatable<ElementId>
    {
        public readonly string Value;

        public ElementId(string value) => Value = value;

        public bool IsValid => !string.IsNullOrEmpty(Value);
        public static readonly ElementId None = new ElementId(null);

        public bool Equals(ElementId other) => string.Equals(Value, other.Value, StringComparison.Ordinal);
        public override bool Equals(object obj) => obj is ElementId other && Equals(other);
        public override int GetHashCode() => Value is null ? 0 : StringComparer.Ordinal.GetHashCode(Value);
        public override string ToString() => Value ?? "<none>";

        public static bool operator ==(ElementId a, ElementId b) => a.Equals(b);
        public static bool operator !=(ElementId a, ElementId b) => !a.Equals(b);
    }

    /// <summary>Stable identity for an edge (relationship). Edges are model objects, not drawn artifacts (§0.2).</summary>
    public readonly struct EdgeId : IEquatable<EdgeId>
    {
        public readonly string Value;

        public EdgeId(string value) => Value = value;

        public bool IsValid => !string.IsNullOrEmpty(Value);
        public static readonly EdgeId None = new EdgeId(null);

        public bool Equals(EdgeId other) => string.Equals(Value, other.Value, StringComparison.Ordinal);
        public override bool Equals(object obj) => obj is EdgeId other && Equals(other);
        public override int GetHashCode() => Value is null ? 0 : StringComparer.Ordinal.GetHashCode(Value);
        public override string ToString() => Value ?? "<none>";

        public static bool operator ==(EdgeId a, EdgeId b) => a.Equals(b);
        public static bool operator !=(EdgeId a, EdgeId b) => !a.Equals(b);
    }
}
