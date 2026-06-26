using System.Collections.Generic;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.CodeGen
{
    /// <summary>
    /// The input for wireframe code generation: a Screen/Panel region, its identity, and the ordered list of the
    /// concrete widgets it contains (each carrying its kind, label, and Field-member items). Built by the canvas
    /// alongside <see cref="CodeGenContext"/>; consumed by <see cref="WireframeSkeleton"/> to emit an HTML mockup
    /// and a PlantUML <c>salt</c> block — the two artifacts that make a wireframe "usable" for handoff.
    /// </summary>
    public sealed class WireframeContext
    {
        public string Name;
        public ElementKind RegionKind;   // Screen or Panel

        /// <summary>One widget inside the region, in authored order.</summary>
        public sealed class Widget
        {
            public ElementKind Kind;
            public string Label;          // the widget's name (button text, placeholder, table title, …)
            public readonly List<string> Items = new(); // Field-member items (table columns, list entries, …)
        }

        public readonly List<Widget> Widgets = new();
    }
}
