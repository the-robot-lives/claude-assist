using System.Collections.Generic;
using UnityEngine;

namespace TheRobotDraft.Uml3D
{
    /// <summary>
    /// 3-D mesh for an infrastructure / managed-service CLOUD node.
    ///
    /// Strategy: a cloud silhouette is non-convex, so it cannot be passed directly to
    /// <see cref="Uml3DMeshBuilder.AddConvexPrism"/>. Instead the shape is built as a union of
    /// several overlapping convex ellipse lobes — a wide central body plus four round bumps along
    /// the top and sides. Each lobe is an independent <c>AddConvexPrism</c> call extruded to the
    /// same depth; the overlapping solids weld visually into one puffy cloud slab.
    ///
    /// Coordinate contract (inherited from <see cref="Uml3DMeshBuilder"/>):
    ///   Mesh centered on origin, inscribed in [-w/2, w/2] x [-h/2, h/2] x [-d/2, d/2].
    ///   +Z front (camera), +Y up, +X right. d ~= 0.18.
    /// </summary>
    public static class Uml3DShape_Cloud
    {
        /// <summary>
        /// Build a cloud mesh inscribed in the given bounding box.
        /// </summary>
        /// <param name="w">Total width of the node (world units).</param>
        /// <param name="h">Total height of the node (world units).</param>
        /// <param name="d">Depth / thickness of the slab (world units, typically ~0.18).</param>
        /// <returns>A new <see cref="Mesh"/> representing the cloud silhouette.</returns>
        public static Mesh Build(float w, float h, float d)
        {
            var b = new Uml3DMeshBuilder();

            float zF = d * 0.5f;
            float zB = -d * 0.5f;
            float minWH = Mathf.Min(w, h);

            // Helper: offset every point in a CCW ellipse outline by (cx, cy).
            static Vector2[] Offset(Vector2[] src, float cx, float cy)
            {
                var dst = new Vector2[src.Length];
                for (int i = 0; i < src.Length; i++)
                    dst[i] = new Vector2(src[i].x + cx, src[i].y + cy);
                return dst;
            }

            // ---- Central body ellipse --------------------------------------------------------
            // Wide, slightly low, forms the base of the cloud puff.
            {
                float rx = w * 0.40f;
                float ry = h * 0.28f;
                // Clamp so the body stays within ±w/2 and ±h/2.
                rx = Mathf.Min(rx, w * 0.50f);
                ry = Mathf.Min(ry, h * 0.50f);
                float cy = -h * 0.05f;
                cy = Mathf.Clamp(cy, -h * 0.5f + ry, h * 0.5f - ry);
                var outline = Offset(Uml3DMeshBuilder.EllipseOutline(rx, ry, 32), 0f, cy);
                b.AddConvexPrism(outline, zF, zB);
            }

            // ---- Left lobe ------------------------------------------------------------------
            // Bulges to the left, sitting at roughly mid-height.
            {
                float r = minWH * 0.20f;
                float cx = -w * 0.26f;
                float cy = 0f;
                // Clamp lobe entirely within the bounding box.
                cx = Mathf.Clamp(cx, -w * 0.5f + r, w * 0.5f - r);
                cy = Mathf.Clamp(cy, -h * 0.5f + r, h * 0.5f - r);
                var outline = Offset(Uml3DMeshBuilder.EllipseOutline(r, r, 24), cx, cy);
                b.AddConvexPrism(outline, zF, zB);
            }

            // ---- Top-left lobe --------------------------------------------------------------
            // Smaller bump slightly left of centre, near the top.
            {
                float r = minWH * 0.22f;
                float cx = -w * 0.10f;
                float cy = h * 0.18f;
                cx = Mathf.Clamp(cx, -w * 0.5f + r, w * 0.5f - r);
                cy = Mathf.Clamp(cy, -h * 0.5f + r, h * 0.5f - r);
                var outline = Offset(Uml3DMeshBuilder.EllipseOutline(r, r, 24), cx, cy);
                b.AddConvexPrism(outline, zF, zB);
            }

            // ---- Top-right lobe -------------------------------------------------------------
            // Tallest bump, slightly right of centre and toward the top.
            {
                float r = minWH * 0.24f;
                float cx = w * 0.14f;
                float cy = h * 0.20f;
                cx = Mathf.Clamp(cx, -w * 0.5f + r, w * 0.5f - r);
                cy = Mathf.Clamp(cy, -h * 0.5f + r, h * 0.5f - r);
                var outline = Offset(Uml3DMeshBuilder.EllipseOutline(r, r, 24), cx, cy);
                b.AddConvexPrism(outline, zF, zB);
            }

            // ---- Right lobe -----------------------------------------------------------------
            // Smaller bump on the far right, at roughly mid-height.
            {
                float r = minWH * 0.18f;
                float cx = w * 0.30f;
                float cy = h * 0.02f;
                cx = Mathf.Clamp(cx, -w * 0.5f + r, w * 0.5f - r);
                cy = Mathf.Clamp(cy, -h * 0.5f + r, h * 0.5f - r);
                var outline = Offset(Uml3DMeshBuilder.EllipseOutline(r, r, 24), cx, cy);
                b.AddConvexPrism(outline, zF, zB);
            }

            return b.ToMesh("Cloud");
        }
    }
}
