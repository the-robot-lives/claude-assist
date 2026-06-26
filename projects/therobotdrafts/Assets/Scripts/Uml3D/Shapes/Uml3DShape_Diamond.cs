using UnityEngine;

namespace TheRobotDraft.Uml3D
{
    /// <summary>
    /// Builds the 3-D mesh for a UML Decision / Merge pseudostate node.
    /// The shape is a rhombus (diamond) extruded into a thin slab, centered on the origin,
    /// inscribed in [-w/2, w/2] x [-h/2, h/2] x [-d/2, d/2].
    /// </summary>
    public static class Uml3DShape_Diamond
    {
        /// <summary>
        /// Builds a diamond (rhombus) prism mesh.
        /// </summary>
        /// <param name="w">Total width of the bounding box.</param>
        /// <param name="h">Total height of the bounding box.</param>
        /// <param name="d">Depth (thickness) of the slab; front cap at +d/2, back cap at -d/2.</param>
        /// <returns>A <see cref="Mesh"/> centered on the origin representing the decision diamond.</returns>
        public static Mesh Build(float w, float h, float d)
        {
            var b = new Uml3DMeshBuilder();
            Vector2[] outline = Uml3DMeshBuilder.DiamondOutline(w, h);
            b.AddConvexPrism(outline, d * 0.5f, -d * 0.5f);
            return b.ToMesh("Diamond");
        }
    }
}
