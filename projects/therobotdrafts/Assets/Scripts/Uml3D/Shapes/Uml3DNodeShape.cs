using UnityEngine;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Uml3D
{
    /// <summary>
    /// Maps an <see cref="ElementKind"/> to its 3-D node mesh and to the style of text its front face should
    /// carry. The flat renderer draws each kind as a distinct UML silhouette (<c>UmlShapeGraphic</c>); this is
    /// the 3-D counterpart, so a node reads as the same notation in the bubble view as on the flat canvas.
    ///
    /// Every mesh is centered on the origin, inscribed in the w×h×d bounding box, and oriented with its readable
    /// front toward +Z (see <see cref="Uml3DMeshBuilder"/>). The kinds without a dedicated silhouette fall back
    /// to the plain box slab — the right shape for the rectangular classifiers (class, interface, enum, table…).
    /// </summary>
    public static class Uml3DNodeShape
    {
        /// <summary>What the +Z face should display for a kind.</summary>
        public enum FaceStyle
        {
            /// <summary>Stereotype + bold name + attribute / operation compartments (the classifier card).</summary>
            Compartments,
            /// <summary>A single centered name label, no opaque card (for non-rectangular silhouettes).</summary>
            NameOnly,
            /// <summary>The circled-H history glyph, centered.</summary>
            GlyphH,
            /// <summary>A wireframe widget glyph — the concrete UI control (button, field, table, …) composed on
            /// the face canvas by <see cref="WireframeGlyph"/>. Distinct from the classifier compartment card.</summary>
            WireframeWidget,
            /// <summary>No text — the glyph itself is the meaning (markers, control nodes).</summary>
            None,
        }

        /// <summary>Build the visual mesh for <paramref name="kind"/> inscribed in the w×h×d bounding box.</summary>
        public static Mesh Build(ElementKind kind, float w, float h, float d) => kind switch
        {
            ElementKind.Actor or ElementKind.Person => Uml3DShape_Actor.Build(w, h, d),

            ElementKind.UseCase or ElementKind.Collaboration => Uml3DShape_UseCase.Build(w, h, d),

            ElementKind.State or ElementKind.Activity or ElementKind.CallActivity
                => Uml3DShape_RoundedRect.Build(w, h, d),

            ElementKind.Decision => Uml3DShape_Diamond.Build(w, h, d),

            ElementKind.StateStart or ElementKind.Junction or ElementKind.History
                => Uml3DShape_DiscMarker.Build(w, h, d),

            ElementKind.StateEnd => Uml3DShape_FinalState.Build(w, h, d),

            ElementKind.FlowFinal or ElementKind.Terminate => Uml3DShape_FlowFinal.Build(kind, w, h, d),

            ElementKind.PackageNode => Uml3DShape_Folder.Build(w, h, d),

            ElementKind.Database => Uml3DShape_Cylinder.Build(w, h, d),

            ElementKind.MindNode => Uml3DShape_MindNode.Build(w, h, d),

            ElementKind.Cloud => Uml3DShape_Cloud.Build(w, h, d),

            ElementKind.Note or ElementKind.Artifact => Uml3DShape_DogEar.Build(w, h, d),

            ElementKind.Component => Uml3DShape_Component.Build(w, h, d),

            ElementKind.FlowTerminator or ElementKind.FlowIO or ElementKind.FlowDocument
                => Uml3DShape_Flowchart.Build(kind, w, h, d),

            _ => Box(w, h, d),  // class, interface, enum, struct, table, deployment box, bars, frames, …
        };

        /// <summary>How the +Z face should be populated for <paramref name="kind"/>.</summary>
        public static FaceStyle Face(ElementKind kind) => kind switch
        {
            // Markers / control nodes: the glyph is the meaning.
            ElementKind.StateStart or ElementKind.StateEnd or ElementKind.Junction or ElementKind.ForkJoin
                or ElementKind.FlowFinal or ElementKind.Terminate or ElementKind.Activation or ElementKind.Port
                or ElementKind.Decision => FaceStyle.None,

            ElementKind.History => FaceStyle.GlyphH,

            // Wireframe widgets: the concrete UI control glyph, composed on the face canvas by WireframeGlyph.
            // (Screen / Panel are regions — handled as region cubes, not widget glyphs — so they fall through.)
            _ when KindInfo.IsWireframeWidget(kind) => FaceStyle.WireframeWidget,

            // Non-rectangular silhouettes: a centered name only (a compartment card would spill the outline).
            ElementKind.Actor or ElementKind.Person or ElementKind.UseCase or ElementKind.Collaboration
                or ElementKind.State or ElementKind.Activity or ElementKind.CallActivity
                or ElementKind.PackageNode or ElementKind.Database or ElementKind.Cloud
                or ElementKind.MindNode or ElementKind.Note or ElementKind.Artifact or ElementKind.DeploymentNode
                or ElementKind.FlowTerminator or ElementKind.FlowIO or ElementKind.FlowDocument
                => FaceStyle.NameOnly,

            // Rectangular classifiers and everything else: the full compartment card.
            _ => FaceStyle.Compartments,
        };

        /// <summary>The plain box slab (front face at +Z), for rectangular kinds and the catch-all fallback.</summary>
        public static Mesh Box(float w, float h, float d)
        {
            var b = new Uml3DMeshBuilder();
            b.AddBox(Vector3.zero, new Vector3(w, h, d));
            return b.ToMesh("UmlNodeBox");
        }
    }
}
