using UnityEngine;

namespace TheRobotDraft.Uml3D
{
    /// <summary>
    /// 3-D mesh for the <b>Database</b> node kind: a real rounded CYLINDER (a "can") standing upright with its
    /// curved side facing the camera (+Z) — the classic data-store drum. The cylinder's axis runs vertically (Y),
    /// so the round body and the elliptical top lip read straight on, and the tube genuinely bulges toward the
    /// viewer rather than being a flat slab. The front pole sits at <see cref="FrontPoleZ"/> so the node's name
    /// label can be seated on the curved face (the node reads that value when placing the face).
    /// </summary>
    public static class Uml3DShape_Cylinder
    {
        /// <summary>The cylinder radius — how far the rounded body reaches in X and toward the camera in Z.</summary>
        private static float Radius(float w, float h) => Mathf.Max(0.02f, Mathf.Min(w * 0.5f, h * 0.5f));

        /// <summary>
        /// The world-Z of the drum's frontmost point. The node places the name label here so the text rides on
        /// the curved front instead of being buried inside the tube.
        /// </summary>
        public static float FrontPoleZ(float w, float h, float d) => Mathf.Max(d * 0.5f, Radius(w, h));

        /// <summary>
        /// Build the upright cylinder, centered on the origin: axis along +Y, height h, radius
        /// <see cref="Radius"/>, capped top and bottom (the top cap is the visible elliptical lip).
        /// </summary>
        public static Mesh Build(float w, float h, float d)
        {
            var b = new Uml3DMeshBuilder();
            float r = Radius(w, h);
            float len = Mathf.Max(0.02f, h);
            b.AddCylinder(new Vector3(0f, -h * 0.5f, 0f), Vector3.up, len, r, 28, caps: true);
            return b.ToMesh("Database");
        }
    }
}
