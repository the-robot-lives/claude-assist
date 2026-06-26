using System.Collections.Generic;
using UnityEngine;

namespace TheRobotDraft.Uml3D
{
    /// <summary>
    /// Builds the 3-D mesh for a UML Use Case node: a horizontal ellipse extruded
    /// into a thin elliptical disc/slab. Used by the UseCase and Collaboration kinds.
    /// </summary>
    public static class Uml3DShape_UseCase
    {
        /// <summary>
        /// Returns a mesh inscribed in [-w/2,w/2]×[-h/2,h/2]×[-d/2,d/2], with the
        /// front cap at z=+d/2 and the back cap at z=-d/2.
        /// </summary>
        /// <param name="w">Total width of the bounding box.</param>
        /// <param name="h">Total height of the bounding box.</param>
        /// <param name="d">Depth (thickness) of the extruded slab; typically ~0.18.</param>
        public static Mesh Build(float w, float h, float d)
        {
            var b = new Uml3DMeshBuilder();
            IList<Vector2> outline = Uml3DMeshBuilder.EllipseOutline(w * 0.5f, h * 0.5f, 44);
            b.AddConvexPrism(outline, d * 0.5f, -d * 0.5f);
            return b.ToMesh("UseCase");
        }
    }
}
