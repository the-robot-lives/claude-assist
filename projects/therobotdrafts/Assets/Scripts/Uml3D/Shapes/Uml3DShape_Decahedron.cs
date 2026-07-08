using UnityEngine;

namespace TheRobotDraft.Uml3D
{
    /// <summary>
    /// 3-D mesh for the whiteboard decahedron: a regular pentagonal bipyramid (ten triangular faces — five
    /// meeting at the top apex, five at the bottom). A faceted polyhedron silhouette that reads from any angle
    /// as a gem / crystal. Centered on the origin, inscribed in [-w/2,w/2]×[-h/2,h/2]×[-d/2,d/2].
    /// </summary>
    public static class Uml3DShape_Decahedron
    {
        /// <param name="w">Total width of the bounding box.</param>
        /// <param name="h">Total height of the bounding box.</param>
        /// <param name="d">Depth (the decahedron is near-spherical, so d is used as the third axis diameter).</param>
        public static Mesh Build(float w, float h, float d)
        {
            float r = Mathf.Max(0.02f, Mathf.Min(w, h, d) * 0.5f);
            var b = new Uml3DMeshBuilder();
            b.AddDecahedron(Vector3.zero, r);
            return b.ToMesh("WhiteboardDecahedron");
        }
    }
}
