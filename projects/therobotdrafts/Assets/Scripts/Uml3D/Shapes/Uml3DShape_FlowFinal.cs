using UnityEngine;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Uml3D
{
    /// <summary>
    /// Builds 3-D meshes for UML flow-control markers.
    /// <list type="bullet">
    ///   <item><see cref="ElementKind.FlowFinal"/> — ⊗ a torus ring with a crossing X inside.</item>
    ///   <item><see cref="ElementKind.Terminate"/>  — ✗ a bold crossing X with no ring.</item>
    /// </list>
    /// Mesh is centered on the origin, inscribed in X/Y within [-w/2, w/2] × [-h/2, h/2].
    /// +Z faces the camera, +Y is up, +X is right.
    /// </summary>
    public static class Uml3DShape_FlowFinal
    {
        /// <summary>
        /// Builds the mesh for the given <paramref name="kind"/>.
        /// </summary>
        /// <param name="kind">
        ///   <see cref="ElementKind.FlowFinal"/> for ⊗ (ring + X);
        ///   <see cref="ElementKind.Terminate"/> for ✗ (X only).
        /// </param>
        /// <param name="w">Total allocated width  (X axis).</param>
        /// <param name="h">Total allocated height (Y axis).</param>
        /// <param name="d">Total allocated depth  (Z axis, unused for flat shapes).</param>
        /// <returns>A new <see cref="Mesh"/> ready for a MeshFilter.</returns>
        public static Mesh Build(ElementKind kind, float w, float h, float d)
        {
            float R = Mathf.Max(0.03f, Mathf.Min(w, h) * 0.5f);

            var b = new Uml3DMeshBuilder();

            switch (kind)
            {
                // ⊗  Flow-Final — torus ring in the XY plane, X crossing inside.
                case ElementKind.FlowFinal:
                {
                    // Torus ring: sits flat in XY, axis = +Z.
                    float majorR  = Mathf.Max(0.01f, R * 0.82f);
                    float minorR  = Mathf.Max(0.005f, R * 0.10f);
                    b.AddTorus(Vector3.zero, Vector3.forward, majorR, minorR, 32, 12);

                    // X inside the circle: two diagonals spanning ±R*0.5 in the inset square.
                    float xExt   = Mathf.Max(0.005f, R * 0.50f);
                    float tubeR  = Mathf.Max(0.003f, R * 0.08f);

                    // Diagonal 1: bottom-left → top-right
                    Vector3 bl1 = new Vector3(-xExt, -xExt, 0f);
                    Vector3 tr1 = new Vector3( xExt,  xExt, 0f);
                    b.AddTube(bl1, tr1, tubeR);

                    // Diagonal 2: top-left → bottom-right
                    Vector3 tl2 = new Vector3(-xExt,  xExt, 0f);
                    Vector3 br2 = new Vector3( xExt, -xExt, 0f);
                    b.AddTube(tl2, br2, tubeR);

                    return b.ToMesh("FlowFinal");
                }

                // ✗  Terminate — bold X, no ring.
                default: // ElementKind.Terminate
                {
                    float xExt  = Mathf.Max(0.005f, R * 0.72f);
                    float tubeR = Mathf.Max(0.003f, R * 0.11f);

                    // Diagonal 1: bottom-left → top-right
                    Vector3 bl1 = new Vector3(-xExt, -xExt, 0f);
                    Vector3 tr1 = new Vector3( xExt,  xExt, 0f);
                    b.AddTube(bl1, tr1, tubeR);

                    // Diagonal 2: top-left → bottom-right
                    Vector3 tl2 = new Vector3(-xExt,  xExt, 0f);
                    Vector3 br2 = new Vector3( xExt, -xExt, 0f);
                    b.AddTube(tl2, br2, tubeR);

                    return b.ToMesh("Terminate");
                }
            }
        }
    }
}
