using UnityEngine;

namespace TheRobotDraft.Uml3D
{
    /// <summary>
    /// 3-D mesh for a UML Package node, rendered as a tabbed folder silhouette.
    /// Composed of two axis-aligned boxes (body + upper-left tab), both at full depth d.
    /// Mesh is centered on the origin, inscribed in [-w/2,w/2]×[-h/2,h/2]×[-d/2,d/2].
    /// </summary>
    public static class Uml3DShape_Folder
    {
        /// <summary>
        /// Builds the folder mesh for a UML Package node.
        /// </summary>
        /// <param name="w">Total width of the node bounding box.</param>
        /// <param name="h">Total height of the node bounding box.</param>
        /// <param name="d">Depth (thickness) of the node; typically ~0.18.</param>
        /// <returns>A <see cref="Mesh"/> representing the folder silhouette.</returns>
        public static Mesh Build(float w, float h, float d)
        {
            var b = new Uml3DMeshBuilder();

            // --- Tab dimensions ---
            float tabH = Mathf.Min(h * 0.22f, 0.20f);
            float tabW = Mathf.Min(w * 0.42f, w * 0.42f); // clamped to 42 % of width

            // Tab box: upper-left corner, x in [-w/2, -w/2+tabW], y in [h/2-tabH, h/2]
            Vector3 tabCenter = new Vector3(-w / 2f + tabW / 2f, h / 2f - tabH / 2f, 0f);
            Vector3 tabSize   = new Vector3(tabW, tabH, d);
            b.AddBox(tabCenter, tabSize);

            // Body box: full width, height = (h - tabH), y in [-h/2, h/2-tabH]
            Vector3 bodyCenter = new Vector3(0f, -tabH / 2f, 0f);
            Vector3 bodySize   = new Vector3(w, h - tabH, d);
            b.AddBox(bodyCenter, bodySize);

            return b.ToMesh("Folder");
        }
    }
}
