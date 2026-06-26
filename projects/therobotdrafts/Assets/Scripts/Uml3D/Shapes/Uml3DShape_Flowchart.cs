using UnityEngine;
using System.Collections.Generic;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Uml3D
{
    /// <summary>
    /// Flowchart node shapes: stadium (terminator), parallelogram (IO), and
    /// wavy-bottom rectangle (document).  Each shape is centered on the origin,
    /// inscribed in [-w/2, w/2] x [-h/2, h/2] x [-d/2, d/2], front face at +d/2.
    /// </summary>
    public static class Uml3DShape_Flowchart
    {
        /// <summary>
        /// Builds the mesh for a flowchart node kind.
        /// </summary>
        /// <param name="kind">
        ///   FlowTerminator → stadium (pill with semicircular ends).
        ///   FlowIO         → parallelogram leaning right.
        ///   FlowDocument   → rectangle with a single-S wavy bottom edge.
        /// </param>
        /// <param name="w">Total width.</param>
        /// <param name="h">Total height.</param>
        /// <param name="d">Depth/thickness; front cap at +d/2, back at -d/2.</param>
        /// <returns>A Unity Mesh representing the requested flowchart shape.</returns>
        public static Mesh Build(ElementKind kind, float w, float h, float d)
        {
            switch (kind)
            {
                case ElementKind.FlowTerminator:
                    return BuildTerminator(w, h, d);
                case ElementKind.FlowIO:
                    return BuildIO(w, h, d);
                case ElementKind.FlowDocument:
                    return BuildDocument(w, h, d);
                default:
                    // Fallback: plain box
                    var fb = new Uml3DMeshBuilder();
                    fb.AddBox(Vector3.zero, new Vector3(w, h, d));
                    return fb.ToMesh("FlowchartDefault");
            }
        }

        // -----------------------------------------------------------------------
        // FlowTerminator — STADIUM (pill shape with fully rounded ends)
        // The rounded-rect outline with radius = h/2 produces semicircular caps.
        // -----------------------------------------------------------------------

        /// <summary>
        /// Stadium / pill shape used for flow start and end terminators.
        /// Radius is clamped to h/2, which the RoundedRectOutline helper further
        /// clamps to min(w,h)/2, yielding true semicircular ends.
        /// </summary>
        private static Mesh BuildTerminator(float w, float h, float d)
        {
            var b = new Uml3DMeshBuilder();
            var outline = Uml3DMeshBuilder.RoundedRectOutline(w, h, h * 0.5f, 8);
            b.AddConvexPrism(outline, d * 0.5f, -d * 0.5f);
            return b.ToMesh("FlowchartTerminator");
        }

        // -----------------------------------------------------------------------
        // FlowIO — PARALLELOGRAM (input/output symbol, leaning to the right)
        // Outline: top-left shifted right, bottom-right shifted left.
        // -----------------------------------------------------------------------

        /// <summary>
        /// Parallelogram shape used for flowchart input/output steps.
        /// The shape leans right: the top edge is shifted right by <c>s</c> and
        /// the bottom edge is shifted left by <c>s</c>, keeping within bounds.
        /// </summary>
        private static Mesh BuildIO(float w, float h, float d)
        {
            var b = new Uml3DMeshBuilder();

            float x = w * 0.5f;
            float y = h * 0.5f;
            float s = Mathf.Min(w * 0.22f, x * 0.8f);

            // Counter-clockwise when viewed from +Z
            var outline = new List<Vector2>
            {
                new Vector2(-x + s,  y),  // top-left (shifted right)
                new Vector2( x,      y),  // top-right
                new Vector2( x - s, -y),  // bottom-right (shifted left)
                new Vector2(-x,     -y),  // bottom-left
            };

            b.AddConvexPrism(outline, d * 0.5f, -d * 0.5f);
            return b.ToMesh("FlowchartIO");
        }

        // -----------------------------------------------------------------------
        // FlowDocument — RECTANGLE with a WAVY (single-S) BOTTOM EDGE
        // Non-convex silhouette: built in two parts —
        //   (a) straight rectangular body (AddBox) covering the upper portion,
        //   (b) wavy bottom band assembled from explicit quads.
        // -----------------------------------------------------------------------

        /// <summary>
        /// Document shape: a rectangle whose bottom edge forms a single-period
        /// sine wave (S-curve), matching the standard flowchart document symbol.
        /// The body above the wave is a plain box; the wavy band below is built
        /// as an explicit triangle strip with front, back, and side edge quads.
        /// </summary>
        private static Mesh BuildDocument(float w, float h, float d)
        {
            var b = new Uml3DMeshBuilder();

            float x   = w * 0.5f;
            float y   = h * 0.5f;
            float amp = Mathf.Min(h * 0.16f, 0.18f);

            // (a) Upper rectangular body — from (yBottom = -y + amp) up to y.
            float bodyHeight = h - amp;
            float bodyCenterY = amp * 0.5f;  // = (-y + amp + y) / 2 = amp/2
            b.AddBox(new Vector3(0f, bodyCenterY, 0f), new Vector3(w, bodyHeight, d));

            // (b) Wavy bottom band ——————————————————————————————————————————
            // yTop is the flat seam between body and band.
            // yBot(t) follows a sine that dips to (-y) at its trough and rises
            // back to (-y + amp) at its crest, creating a smooth S over [0,1].
            //
            // Parametric column:  t ∈ [0, 1]  →  xPos ∈ [-x, x]
            // yTop is constant; yBot varies with sine.
            //
            // phase = -π/2 so the wave starts low at the left edge and ends
            // low at the right edge, matching the classic document silhouette.

            const int cols  = 24;          // number of vertical slices
            float zF = d * 0.5f;          // front z
            float zB = -d * 0.5f;         // back z

            float yTop = -y + amp;         // flat seam (top of band)

            // Pre-compute sample columns
            var xSamples    = new float[cols + 1];
            var yBotSamples = new float[cols + 1];

            for (int i = 0; i <= cols; i++)
            {
                float t = (float)i / cols;
                xSamples[i]    = Mathf.Lerp(-x, x, t);
                // Phase = -π/2: wave = -y + amp*0.5 + amp*0.5*sin(t*2π - π/2)
                //              = -y + amp*0.5 - amp*0.5*cos(t*2π)
                yBotSamples[i] = -y + amp * 0.5f + amp * 0.5f * Mathf.Sin(t * Mathf.PI * 2f - Mathf.PI * 0.5f);
            }

            // Emit one quad-pair per adjacent sample pair
            for (int i = 0; i < cols; i++)
            {
                float xL = xSamples[i];
                float xR = xSamples[i + 1];
                float yBL = yBotSamples[i];      // bottom-left
                float yBR = yBotSamples[i + 1];  // bottom-right

                // ---- FRONT face (outward = +Z) ----
                // quad: top-left, top-right, bottom-right, bottom-left  (CCW from +Z)
                Vector3 fTL = new Vector3(xL, yTop, zF);
                Vector3 fTR = new Vector3(xR, yTop, zF);
                Vector3 fBR = new Vector3(xR, yBR,  zF);
                Vector3 fBL = new Vector3(xL, yBL,  zF);
                b.AddQuadOriented(fTL, fTR, fBR, fBL, Vector3.forward);

                // ---- BACK face (outward = -Z) ----
                // Reverse winding for back face
                Vector3 bTL = new Vector3(xL, yTop, zB);
                Vector3 bTR = new Vector3(xR, yTop, zB);
                Vector3 bBR = new Vector3(xR, yBR,  zB);
                Vector3 bBL = new Vector3(xL, yBL,  zB);
                b.AddQuadOriented(bTR, bTL, bBL, bBR, Vector3.back);

                // ---- BOTTOM edge: connect front-bottom to back-bottom ----
                // The outward normal approximates -Y for this sliver.
                // Quad: front-left-bottom → front-right-bottom → back-right-bottom → back-left-bottom
                Vector3 ebFL = new Vector3(xL, yBL, zF);
                Vector3 ebFR = new Vector3(xR, yBR, zF);
                Vector3 ebBR = new Vector3(xR, yBR, zB);
                Vector3 ebBL = new Vector3(xL, yBL, zB);
                b.AddQuadOriented(ebFL, ebFR, ebBR, ebBL, Vector3.down);
            }

            // ---- LEFT end cap (x = -x, outward = -X) ----
            {
                float xCap = -x;
                float yBotCap = yBotSamples[0];
                Vector3 capFT = new Vector3(xCap, yTop,    zF);
                Vector3 capFB = new Vector3(xCap, yBotCap, zF);
                Vector3 capBB = new Vector3(xCap, yBotCap, zB);
                Vector3 capBT = new Vector3(xCap, yTop,    zB);
                b.AddQuadOriented(capFT, capBT, capBB, capFB, Vector3.left);
            }

            // ---- RIGHT end cap (x = +x, outward = +X) ----
            {
                float xCap  = x;
                float yBotCap = yBotSamples[cols];
                Vector3 capFT = new Vector3(xCap, yTop,    zF);
                Vector3 capFB = new Vector3(xCap, yBotCap, zF);
                Vector3 capBB = new Vector3(xCap, yBotCap, zB);
                Vector3 capBT = new Vector3(xCap, yTop,    zB);
                b.AddQuadOriented(capBT, capFT, capFB, capBB, Vector3.right);
            }

            return b.ToMesh("FlowchartDocument");
        }
    }
}
