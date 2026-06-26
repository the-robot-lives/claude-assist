using UnityEngine;

namespace TheRobotDraft.Uml3D
{
    /// <summary>
    /// 3-D mesh for UML disc/bead pseudostate markers: Initial State (solid dot),
    /// Junction (small filled dot), and History (circled H — the H letter is drawn
    /// as a face label; this geometry supplies only the enclosing disc/bead).
    ///
    /// Rendered as a glossy sphere centered at the origin.  The radius is clamped to
    /// half the smaller canvas dimension so the bead inscribes cleanly inside the
    /// [−w/2, w/2] × [−h/2, h/2] cell.  The sphere may bulge in ±Z past d/2; a
    /// separate box collider handles picking, so that is acceptable per the coordinate
    /// contract.
    /// </summary>
    public static class Uml3DShape_DiscMarker
    {
        /// <summary>
        /// Build a sphere bead mesh that fits inside the given cell dimensions.
        /// </summary>
        /// <param name="w">Cell width  (X extent).  Typically ≈ 0.26.</param>
        /// <param name="h">Cell height (Y extent).  Typically ≈ 0.26.</param>
        /// <param name="d">Cell depth  (Z extent).  Used only for callers that need
        ///                 to know the nominal thickness; the sphere radius is derived
        ///                 from w/h, not d.</param>
        /// <returns>A Unity <see cref="Mesh"/> representing a solid sphere bead.</returns>
        public static Mesh Build(float w, float h, float d)
        {
            // Radius = half the smaller dimension, floored at 0.02 to avoid
            // degenerate geometry on very small nodes.
            float r = Mathf.Max(0.02f, Mathf.Min(w, h) * 0.5f);

            var b = new Uml3DMeshBuilder();
            // 14 latitude segments × 20 longitude segments give a smooth bead
            // at typical node sizes without excess triangle count.
            b.AddSphere(Vector3.zero, r, 14, 20);

            return b.ToMesh("DiscMarker");
        }
    }
}
