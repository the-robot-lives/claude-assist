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
            /// <summary>EA/Sparx-style notation face with kind-specific adornments and property rows.</summary>
            EaNotation,
            /// <summary>No text — the glyph itself is the meaning (markers, control nodes).</summary>
            None,
        }

        /// <summary>Build the visual mesh for <paramref name="kind"/> inscribed in the w×h×d bounding box.</summary>
        public static Mesh Build(ElementKind kind, float w, float h, float d) => kind switch
        {
            ElementKind.Actor or ElementKind.Person => Uml3DShape_Actor.Build(w, h, d),

            ElementKind.UseCase or ElementKind.Collaboration or ElementKind.BpmnEvent
                or ElementKind.WhiteboardCircle => Uml3DShape_UseCase.Build(w, h, d),

            ElementKind.State or ElementKind.Activity or ElementKind.CallActivity or ElementKind.BpmnActivity
                => Uml3DShape_RoundedRect.Build(w, h, d),

            // Async send / receive: the send-signal pentagon and the concave accept-event notch.
            ElementKind.AsyncSend => Uml3DShape_Ext.Pentagon(w, h, d),
            ElementKind.AsyncReceive => Uml3DShape_Ext.AcceptEvent(w, h, d),

            ElementKind.Decision or ElementKind.BpmnGateway
                or ElementKind.DecisionTreeNode or ElementKind.WhiteboardDiamond => Uml3DShape_Diamond.Build(w, h, d),

            // Pointy hexagon: BPMN conversation, UAF operational node.
            ElementKind.BpmnConversation or ElementKind.UafOperationalNode => Uml3DShape_Ext.Hexagon(w, h, d),

            // Process / value arrows drawn as a chevron.
            ElementKind.ValueStream or ElementKind.ValueChainActivity or ElementKind.ArchiBusinessProcess
                => Uml3DShape_Ext.Chevron(w, h, d),

            // Stadium / pill: DMN input data and the ArchiMate / UAF service elements.
            ElementKind.DmnInputData or ElementKind.ArchiApplicationService
                or ElementKind.ArchiTechnologyService or ElementKind.UafService => Uml3DShape_Ext.Stadium(w, h, d),

            // Face-on disc: a TOGAF ADM phase.
            ElementKind.TogafArchitecturePhase => Uml3DShape_Ext.Disc(w, h, d),

            // Chunky 3-D box for the deployment / device / server / resource nodes.
            ElementKind.DeploymentNode or ElementKind.ArchiNode or ElementKind.ArchiDevice
                or ElementKind.Server or ElementKind.UafResource => Uml3DShape_Ext.DeepBox(w, h, d),

            ElementKind.StateStart or ElementKind.Junction or ElementKind.History
                => Uml3DShape_DiscMarker.Build(w, h, d),

            ElementKind.StateEnd => Uml3DShape_FinalState.Build(w, h, d),

            ElementKind.FlowFinal or ElementKind.Terminate => Uml3DShape_FlowFinal.Build(kind, w, h, d),

            ElementKind.PackageNode or ElementKind.Profile => Uml3DShape_Folder.Build(w, h, d),

            ElementKind.Database or ElementKind.BpmnDataStore => Uml3DShape_Cylinder.Build(w, h, d),

            ElementKind.MindNode => Uml3DShape_MindNode.Build(w, h, d),

            ElementKind.Cloud => Uml3DShape_Cloud.Build(w, h, d),

            ElementKind.Note or ElementKind.Artifact or ElementKind.WhiteboardSticky
                or ElementKind.BpmnDataObject => Uml3DShape_DogEar.Build(w, h, d),

            ElementKind.Component or ElementKind.ArchiApplicationComponent => Uml3DShape_Component.Build(w, h, d),

            ElementKind.FlowTerminator or ElementKind.FlowIO or ElementKind.FlowDocument
                => Uml3DShape_Flowchart.Build(kind, w, h, d),

            // Thin synchronization / activation bars and ports (were full slabs).
            ElementKind.ForkJoin or ElementKind.Activation or ElementKind.Port
                or ElementKind.SysmlProxyPort or ElementKind.SysmlFullPort => Uml3DShape_Ext.Bar(w, h, d),

            // Members as balls (design-conventions §1.1): functions = sphere, fields = flattened sphere.
            ElementKind.Function => Uml3DShape_Ext.Sphere(w, h, d),
            ElementKind.Field => Uml3DShape_Ext.FlatSphere(w, h, d),

            // Rounded "capability / service" tiles.
            ElementKind.SoftwareSystem or ElementKind.Container
                or ElementKind.ArchiCapability or ElementKind.BusinessCapability or ElementKind.UafCapability
                or ElementKind.ArchiSystemSoftware or ElementKind.SysmlConstraintBlock
                or ElementKind.DmnDecisionService => Uml3DShape_RoundedRect.Build(w, h, d),

            ElementKind.DmnBusinessKnowledge => Uml3DShape_Ext.ClippedTop(w, h, d),   // BKM: clipped top corners
            ElementKind.DmnKnowledgeSource => Uml3DShape_Flowchart.Build(ElementKind.FlowDocument, w, h, d), // wavy
            ElementKind.ArchiDeliverable => Uml3DShape_Ext.RoundedBottom(w, h, d),     // rounded bottom edge
            ElementKind.ArchiPlateau => Uml3DShape_Ext.Layered(w, h, d),               // stacked slabs

            _ => Box(w, h, d),  // class, interface, enum, struct, table, frames, remaining EA rectangles, …
        };

        /// <summary>How the +Z face should be populated for <paramref name="kind"/>.</summary>
        public static FaceStyle Face(ElementKind kind) => kind switch
        {
            // Markers / control nodes: the glyph is the meaning.
            ElementKind.StateStart or ElementKind.StateEnd or ElementKind.Junction or ElementKind.ForkJoin
                or ElementKind.FlowFinal or ElementKind.Terminate or ElementKind.Activation or ElementKind.Port
                or ElementKind.SysmlProxyPort or ElementKind.SysmlFullPort
                or ElementKind.Decision => FaceStyle.None,

            ElementKind.History => FaceStyle.GlyphH,

            // Kinds we now render with a non-rectangular silhouette (hexagon, chevron, stadium, pentagon,
            // accept-event, disc) get a centered label only — a full-face opaque EA/compartment card would
            // poke outside the outline. Their EA property rows move to the inspector, not the face.
            _ when HasNonRectSilhouette(kind) => FaceStyle.NameOnly,

            // Wireframe widgets: the concrete UI control glyph, composed on the face canvas by WireframeGlyph.
            // (Screen / Panel are regions — handled as region cubes, not widget glyphs — so they fall through.)
            _ when KindInfo.IsWireframeWidget(kind) => FaceStyle.WireframeWidget,

            _ when KindInfo.IsEaNotationNode(kind) => FaceStyle.EaNotation,

            _ when KindInfo.IsSingleLabelNode(kind) => FaceStyle.NameOnly,

            // Non-rectangular silhouettes: a centered name only (a compartment card would spill the outline).
            ElementKind.Actor or ElementKind.Person or ElementKind.UseCase or ElementKind.Collaboration
                or ElementKind.State or ElementKind.Activity or ElementKind.CallActivity
                or ElementKind.AsyncSend or ElementKind.AsyncReceive
                or ElementKind.PackageNode or ElementKind.Database or ElementKind.Cloud
                or ElementKind.BpmnEvent or ElementKind.BpmnGateway or ElementKind.BpmnConversation
                or ElementKind.DmnDecision or ElementKind.DecisionTreeNode
                or ElementKind.MindNode or ElementKind.Note or ElementKind.Artifact or ElementKind.DeploymentNode
                or ElementKind.FlowTerminator or ElementKind.FlowIO or ElementKind.FlowDocument
                or ElementKind.WhiteboardSticky or ElementKind.WhiteboardCard or ElementKind.WhiteboardText
                or ElementKind.WhiteboardCircle or ElementKind.WhiteboardDiamond
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

        /// <summary>
        /// Kinds whose <see cref="Build"/> mesh is a non-rectangular silhouette (pentagon, accept-event, hexagon,
        /// chevron, stadium, disc). These take a centered-label face so a rectangular card can't spill past the
        /// outline; the (deep-box, folder, cylinder, dog-ear, component) kinds stay rectangular-enough to keep
        /// their normal face and are deliberately not listed here.
        /// </summary>
        private static bool HasNonRectSilhouette(ElementKind kind) => kind switch
        {
            ElementKind.AsyncSend or ElementKind.AsyncReceive
                or ElementKind.BpmnConversation or ElementKind.UafOperationalNode
                or ElementKind.ValueStream or ElementKind.ValueChainActivity or ElementKind.ArchiBusinessProcess
                or ElementKind.DmnInputData or ElementKind.ArchiApplicationService
                or ElementKind.ArchiTechnologyService or ElementKind.UafService
                or ElementKind.TogafArchitecturePhase
                or ElementKind.Function or ElementKind.Field
                or ElementKind.DmnKnowledgeSource or ElementKind.ArchiDeliverable or ElementKind.ArchiPlateau => true,
            _ => false,
        };
    }
}
