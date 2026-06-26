using UnityEngine;

namespace TheRobotDraft.Uml3D
{
    /// <summary>
    /// 3-D mesh for a mind-map <b>MindNode</b> (topic / idea): a smooth OVOID — an oval that bulges toward the
    /// camera like an egg/pebble, rather than a flat slab — so brainstorming topics read as soft organic bubbles.
    /// The silhouette fills the node's width/height; the front pole sits at <see cref="FrontPoleZ"/> so the node's
    /// name label can be seated on the dome (the node reads that value when placing the face).
    /// </summary>
    public static class Uml3DShape_MindNode
    {
        /// <summary>
        /// The world-Z of the ovoid's front pole (its closest point to the camera). The node places the name
        /// label here so the text rides on the dome instead of being buried inside it.
        /// </summary>
        public static float FrontPoleZ(float w, float h, float d) =>
            Mathf.Max(d * 0.5f, Mathf.Min(w, h) * 0.26f);

        /// <summary>Build the ovoid mesh, inscribed (in X/Y) in the w×h box and bulging to ±<see cref="FrontPoleZ"/> in Z.</summary>
        public static Mesh Build(float w, float h, float d)
        {
            var b = new Uml3DMeshBuilder();
            float rx = Mathf.Max(0.02f, w * 0.5f);
            float ry = Mathf.Max(0.02f, h * 0.5f);
            float rz = FrontPoleZ(w, h, d);
            b.AddEllipsoid(Vector3.zero, new Vector3(rx, ry, rz), 16, 26);
            return b.ToMesh("MindNode");
        }
    }
}
