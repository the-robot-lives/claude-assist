using System.Collections.Generic;
using UnityEngine;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Uml3D
{
    /// <summary>
    /// Whiteboard primitive 3-D silhouettes (Track E). Each <see cref="Uml3DShape_*"/> builder follows the same
    /// contract: the mesh is centered on the origin, inscribed in [-w/2,w/2]×[-h/2,h/2]×[-d/2,d/2], with the
    /// readable front toward +Z. These primitives lean on <see cref="Uml3DMeshBuilder"/>'s existing primitives
    /// (box, sphere, cylinder, convex prism) where the silhouette already exists, and add two new ones
    /// (<see cref="Uml3DShape_Decahedron"/>, <see cref="Uml3DShape_Blob"/>) for the polyhedra without a base mesh.
    /// </summary>
    public static class Uml3DShape_Primitives
    {
        /// <summary>Dispatch the primitive mesh by element kind. Used by <see cref="Uml3DNodeShape.Build"/>.</summary>
        public static Mesh Build(ElementKind kind, float w, float h, float d) => kind switch
        {
            ElementKind.WhiteboardTriangle => Triangle(w, h, d),
            ElementKind.WhiteboardRectangle => Rectangle(w, h, d),
            ElementKind.WhiteboardCube => Cube(w, h, d),
            ElementKind.WhiteboardSphere => Sphere(w, h, d),
            ElementKind.WhiteboardCylinder => Cylinder(w, h, d),
            _ => Rectangle(w, h, d),
        };
        /// <summary>
        /// A flat whiteboard triangle: a thin triangular prism. The triangle points up (apex at +Y), base on −Y,
        /// extruded along Z so it reads as a slab from the side. Uses <see cref="Uml3DMeshBuilder.AddConvexPrism"/>.
        /// </summary>
        public static Mesh Triangle(float w, float h, float d)
        {
            float x = w * 0.5f, y = h * 0.5f;
            var outline = new List<Vector2>
            {
                new Vector2(0f,   y),   // apex
                new Vector2(x,  -y),   // bottom-right
                new Vector2(-x,  -y),  // bottom-left
            };
            var b = new Uml3DMeshBuilder();
            b.AddConvexPrism(outline, d * 0.5f, -d * 0.5f);
            return b.ToMesh("WhiteboardTriangle");
        }

        /// <summary>
        /// A flat whiteboard rectangle: a thin plate / slab. Distinct from the classifier box because the depth
        /// is intentionally shallow so it reads as a card, not a cuboid.
        /// </summary>
        public static Mesh Rectangle(float w, float h, float d)
        {
            float thin = Mathf.Clamp(d * 0.35f, 0.08f, d);
            var b = new Uml3DMeshBuilder();
            b.AddBox(Vector3.zero, new Vector3(w, h, thin));
            return b.ToMesh("WhiteboardRectangle");
        }

        /// <summary>A whiteboard cube: a full-depth box with roughly equal dimensions so it reads as a 3-D cube.</summary>
        public static Mesh Cube(float w, float h, float d)
        {
            // Use the deeper of d / a min-dimension-derived depth so the cube has real volume.
            float depth = Mathf.Max(d, Mathf.Min(w, h) * 0.7f);
            var b = new Uml3DMeshBuilder();
            b.AddBox(Vector3.zero, new Vector3(w, h, depth));
            return b.ToMesh("WhiteboardCube");
        }

        /// <summary>A whiteboard sphere: a UV sphere filling the smaller of w/h as diameter.</summary>
        public static Mesh Sphere(float w, float h, float d)
        {
            float r = Mathf.Max(0.02f, Mathf.Min(w, h) * 0.5f);
            var b = new Uml3DMeshBuilder();
            b.AddSphere(Vector3.zero, r, 16, 22);
            return b.ToMesh("WhiteboardSphere");
        }

        /// <summary>
        /// A whiteboard cylinder: an upright drum (axis along +Y), same silhouette as the Database node kind
        /// but unbranded so it reads as a plain primitive.
        /// </summary>
        public static Mesh Cylinder(float w, float h, float d)
        {
            float r = Mathf.Max(0.02f, Mathf.Min(w * 0.5f, h * 0.5f));
            float len = Mathf.Max(0.02f, h);
            var b = new Uml3DMeshBuilder();
            b.AddCylinder(new Vector3(0f, -h * 0.5f, 0f), Vector3.up, len, r, 28, caps: true);
            return b.ToMesh("WhiteboardCylinder");
        }
    }
}
