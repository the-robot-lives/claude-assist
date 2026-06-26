using UnityEngine;

namespace TheRobotDraft.Uml3D
{
    /// <summary>
    /// UML Component silhouette: a rectangular body with two small connector
    /// tabs jutting from its left edge, matching the classic UML component icon.
    /// </summary>
    public static class Uml3DShape_Component
    {
        /// <summary>
        /// Builds a UML Component mesh inscribed in [-w/2,w/2]x[-h/2,h/2]x[-d/2,d/2].
        /// Composed of three boxes: one main body and two left-edge connector tabs.
        /// </summary>
        /// <param name="w">Total width of the node bounding box.</param>
        /// <param name="h">Total height of the node bounding box.</param>
        /// <param name="d">Total depth of the node bounding box (typically ~0.18).</param>
        /// <returns>A Unity Mesh representing the component shape.</returns>
        public static Mesh Build(float w, float h, float d)
        {
            var b = new Uml3DMeshBuilder();

            // Main body: full bounding box centered at origin.
            b.AddBox(Vector3.zero, new Vector3(w, h, d));

            // Tab dimensions: small rectangles that straddle the left edge.
            float tabW = Mathf.Min(w * 0.18f, 0.22f);
            float tabH = Mathf.Min(h * 0.16f, 0.16f);
            float tabD = d * 0.7f;

            // Upper left-edge connector tab (y = +h*0.20).
            b.AddBox(new Vector3(-w * 0.5f, h * 0.20f, 0f), new Vector3(tabW, tabH, tabD));

            // Lower left-edge connector tab (y = -h*0.20).
            b.AddBox(new Vector3(-w * 0.5f, -h * 0.20f, 0f), new Vector3(tabW, tabH, tabD));

            return b.ToMesh("Component");
        }
    }
}
