using UnityEngine;

namespace TheRobotDraft.Uml3D
{
    /// <summary>
    /// Rounded-rectangle prism — the standard UML silhouette for Activity actions,
    /// States, and Call-Activity nodes. Mesh is centered on the origin and inscribed
    /// in [-w/2, w/2] × [-h/2, h/2] × [-d/2, d/2]; +Z is the front (camera) face.
    /// </summary>
    public static class Uml3DShape_RoundedRect
    {
        /// <summary>
        /// Build a rounded-rectangle prism mesh.
        /// </summary>
        /// <param name="w">Total width  (X extent).</param>
        /// <param name="h">Total height (Y extent).</param>
        /// <param name="d">Total depth  (Z extent); typically ≈ 0.18.</param>
        /// <returns>A new <see cref="Mesh"/> ready to assign to a MeshFilter.</returns>
        public static Mesh Build(float w, float h, float d)
        {
            // Corner radius: large enough to read clearly, capped so it stays inside the box.
            float rad = Mathf.Min(Mathf.Min(w, h) * 0.28f, 0.20f);

            var outline = Uml3DMeshBuilder.RoundedRectOutline(w, h, rad, 6);

            var b = new Uml3DMeshBuilder();
            b.AddConvexPrism(outline, d * 0.5f, -d * 0.5f);
            return b.ToMesh("RoundedRect");
        }
    }
}
