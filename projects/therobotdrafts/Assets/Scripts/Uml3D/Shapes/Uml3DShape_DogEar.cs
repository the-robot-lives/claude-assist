using UnityEngine;
using System.Collections.Generic;

namespace TheRobotDraft.Uml3D
{
    /// <summary>
    /// UML NOTE / ARTIFACT shape: a rectangle with a folded-over paper corner. Used by the Note and Artifact
    /// node kinds.
    ///
    /// The clip is cut from the mesh's top-LEFT corner so that it appears on the VIEWER'S RIGHT: the camera reads
    /// the node's +Z face from the front, which mirrors world X (world +X shows on screen-left), so a screen-right
    /// dog-ear must live at world −X. The fold is modelled as a triangular facet whose inner corner is pushed back
    /// INTO the slab, so the turned-down page corner reads as folded paper rather than a flat patch.
    /// </summary>
    public static class Uml3DShape_DogEar
    {
        /// <summary>
        /// Builds the dog-ear mesh centered on the origin, inscribed in [-w/2, w/2] x [-h/2, h/2] x [-d/2, d/2].
        /// </summary>
        public static Mesh Build(float w, float h, float d)
        {
            var b = new Uml3DMeshBuilder();

            float x = w * 0.5f;
            float y = h * 0.5f;
            float fold = Mathf.Min(Mathf.Min(w, h) * 0.22f, 0.22f);

            float zFront = d * 0.5f;
            float zBack = -d * 0.5f;

            // Body prism: convex pentagon with the top-LEFT corner cut (→ screen-right once the camera mirrors X).
            // CCW when viewed from +Z.
            var outline = new List<Vector2>
            {
                new Vector2(-x,         -y),       // bottom-left
                new Vector2( x,         -y),       // bottom-right
                new Vector2( x,          y),       // top-right
                new Vector2(-x + fold,   y),       // along the top edge to where the cut begins
                new Vector2(-x,          y - fold) // down the left side to where the cut ends
            };
            b.AddConvexPrism(outline, zFront, zBack);

            // Fold facet: a triangle whose two outer corners sit on the front face (at the ends of the diagonal cut)
            // and whose inner corner is pushed back into the slab, so the folded page corner recedes inward.
            Vector3 topPt = new Vector3(-x + fold, y, zFront);       // on the top edge
            Vector3 leftPt = new Vector3(-x, y - fold, zFront);      // on the left edge
            float zInner = Mathf.Max(zBack, zFront - fold * 0.8f);   // inner corner, recessed into the shape
            Vector3 innerPt = new Vector3(-x + fold, y - fold, zInner);

            // Faces roughly up-and-left toward the camera; AddTriangleOriented fixes the winding.
            b.AddTriangleOriented(topPt, leftPt, innerPt, new Vector3(-0.5f, 0.5f, 1f));

            return b.ToMesh("DogEar");
        }
    }
}
