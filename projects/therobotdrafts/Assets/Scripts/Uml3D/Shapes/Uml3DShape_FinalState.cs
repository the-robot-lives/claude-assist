using UnityEngine;

namespace TheRobotDraft.Uml3D
{
    /// <summary>
    /// UML Final State shape — the classic ⦿ symbol rendered in 3-D.
    /// Composed of a flat torus (outer ring) in the XY plane plus a small inner
    /// sphere (filled bullseye), both centred at the origin.
    /// Inscribed in [-w/2, w/2] × [-h/2, h/2]; +Z faces the camera.
    /// </summary>
    public static class Uml3DShape_FinalState
    {
        /// <summary>
        /// Builds the Final State mesh.
        /// </summary>
        /// <param name="w">Bounding width  (X axis). Typical value ≈ 0.30.</param>
        /// <param name="h">Bounding height (Y axis). Typical value ≈ 0.30.</param>
        /// <param name="d">Bounding depth  (Z axis). Not used for sizing but
        ///                 preserved for signature parity with other shape builders.</param>
        /// <returns>A combined <see cref="Mesh"/> with the ring and inner sphere.</returns>
        public static Mesh Build(float w, float h, float d)
        {
            var b = new Uml3DMeshBuilder();

            // Outer radius — half the smaller bounding dimension, clamped to a
            // sensible minimum so the shape remains visible at tiny scales.
            float R = Mathf.Max(0.03f, Mathf.Min(w, h) * 0.5f);

            // Outer ring: flat torus lying in the XY plane (axis = +Z).
            // majorR drives the ring diameter; minorR is the tube thickness.
            b.AddTorus(
                center:    Vector3.zero,
                axis:      Vector3.forward,
                majorR:    R * 0.78f,
                minorR:    Mathf.Max(0.01f, R * 0.12f),
                majorSegs: 28,
                minorSegs: 10);

            // Inner filled disc: small sphere at origin acting as the bullseye.
            b.AddSphere(
                center:  Vector3.zero,
                radius:  R * 0.42f,
                latSegs: 12,
                lonSegs: 18);

            return b.ToMesh("FinalState");
        }
    }
}
