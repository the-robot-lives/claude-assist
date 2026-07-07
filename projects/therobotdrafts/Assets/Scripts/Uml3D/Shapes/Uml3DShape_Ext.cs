using System.Collections.Generic;
using UnityEngine;

namespace TheRobotDraft.Uml3D
{
    /// <summary>
    /// Extra node silhouettes that give the previously box-defaulted kinds a distinct 3-D shape, so every
    /// <see cref="TheRobotDraft.Authoring.Model.ElementKind"/> reads as its own notation from any angle rather than
    /// as an identical slab. Same contract as the other <c>Uml3DShape_*</c> builders: the mesh is centered on the
    /// origin, inscribed in [-w/2,w/2]×[-h/2,h/2]×[-d/2,d/2], with the readable front cap at +d/2.
    ///
    /// Model +X is treated as "right" (matching <see cref="Uml3DShape_Flowchart"/>'s parallelogram convention).
    /// Outlines are given counter-clockwise-from-+Z; convex outlines go through <c>AddConvexPrism</c> (which
    /// auto-orients), concave ones through <c>AddPrism</c> (ear-clipped, robust to winding).
    /// </summary>
    public static class Uml3DShape_Ext
    {
        /// <summary>UML send-signal / async-send action: a rectangle with a triangular point on the +X end.</summary>
        public static Mesh Pentagon(float w, float h, float d)
        {
            float x = w * 0.5f, y = h * 0.5f;
            float notch = Mathf.Min(w * 0.28f, h * 0.5f);
            var outline = new List<Vector2>
            {
                new Vector2(-x,        -y),
                new Vector2( x - notch,-y),
                new Vector2( x,         0f),
                new Vector2( x - notch, y),
                new Vector2(-x,         y),
            };
            var b = new Uml3DMeshBuilder();
            b.AddConvexPrism(outline, d * 0.5f, -d * 0.5f);
            return b.ToMesh("SendSignal");
        }

        /// <summary>UML accept-event / async-receive action: a rectangle with a concave event notch on the −X end.</summary>
        public static Mesh AcceptEvent(float w, float h, float d)
        {
            float x = w * 0.5f, y = h * 0.5f;
            float notch = Mathf.Min(w * 0.24f, h * 0.5f);
            var outline = new List<Vector2>
            {
                new Vector2(-x,        -y),
                new Vector2( x,        -y),
                new Vector2( x,         y),
                new Vector2(-x,         y),
                new Vector2(-x + notch, 0f), // concave dent poking into the −X edge
            };
            var b = new Uml3DMeshBuilder();
            b.AddPrism(outline, null, d * 0.5f, -d * 0.5f);
            return b.ToMesh("AcceptEvent");
        }

        /// <summary>A pointy-left/right hexagon (BPMN conversation, UAF operational node).</summary>
        public static Mesh Hexagon(float w, float h, float d)
        {
            float x = w * 0.5f, y = h * 0.5f;
            float ix = Mathf.Min(w * 0.24f, x * 0.9f);
            var outline = new List<Vector2>
            {
                new Vector2(-x,       0f),
                new Vector2(-x + ix, -y),
                new Vector2( x - ix, -y),
                new Vector2( x,       0f),
                new Vector2( x - ix,  y),
                new Vector2(-x + ix,  y),
            };
            var b = new Uml3DMeshBuilder();
            b.AddConvexPrism(outline, d * 0.5f, -d * 0.5f);
            return b.ToMesh("Hexagon");
        }

        /// <summary>A chevron / process arrow: rectangle with a point on +X and a matching notch cut into −X.</summary>
        public static Mesh Chevron(float w, float h, float d)
        {
            float x = w * 0.5f, y = h * 0.5f;
            float tip = Mathf.Min(w * 0.22f, x * 0.9f);
            var outline = new List<Vector2>
            {
                new Vector2(-x,       -y),
                new Vector2( x - tip, -y),
                new Vector2( x,        0f),
                new Vector2( x - tip,  y),
                new Vector2(-x,        y),
                new Vector2(-x + tip,  0f), // concave rear notch
            };
            var b = new Uml3DMeshBuilder();
            b.AddPrism(outline, null, d * 0.5f, -d * 0.5f);
            return b.ToMesh("Chevron");
        }

        /// <summary>A stadium / pill (fully rounded ends) — DMN input data, ArchiMate/UAF services.</summary>
        public static Mesh Stadium(float w, float h, float d)
        {
            var outline = Uml3DMeshBuilder.RoundedRectOutline(w, h, h * 0.5f, 8);
            var b = new Uml3DMeshBuilder();
            b.AddConvexPrism(outline, d * 0.5f, -d * 0.5f);
            return b.ToMesh("Stadium");
        }

        /// <summary>A flat disc / circle standing face-on (TOGAF ADM phase).</summary>
        public static Mesh Disc(float w, float h, float d)
        {
            float r = Mathf.Max(0.02f, Mathf.Min(w, h) * 0.5f);
            var outline = Uml3DMeshBuilder.EllipseOutline(r, r, 40);
            var b = new Uml3DMeshBuilder();
            b.AddConvexPrism(outline, d * 0.5f, -d * 0.5f);
            return b.ToMesh("Disc");
        }

        /// <summary>
        /// A chunky 3-D box — the deployment "node" / device / server silhouette. It is a real cuboid with a
        /// deeper Z than the flat classifier slab, so it reads as a box you could rotate around, not a card.
        /// </summary>
        public static Mesh DeepBox(float w, float h, float d)
        {
            float depth = Mathf.Clamp(Mathf.Min(w, h) * 0.42f, d, 0.5f);
            var b = new Uml3DMeshBuilder();
            b.AddBox(Vector3.zero, new Vector3(w, h, depth));
            return b.ToMesh("DeepBox");
        }

        /// <summary>A thin horizontal bar — fork/join synchronization bar, activation, and ports.</summary>
        public static Mesh Bar(float w, float h, float d)
        {
            float bh = Mathf.Min(h, Mathf.Max(0.12f, w * 0.14f));
            var b = new Uml3DMeshBuilder();
            b.AddBox(Vector3.zero, new Vector3(w, bh, d));
            return b.ToMesh("Bar");
        }

        /// <summary>A round ball — a function / method (design-conventions §1.1: functions are small spheres).</summary>
        public static Mesh Sphere(float w, float h, float d)
        {
            float r = Mathf.Max(0.02f, Mathf.Min(w, h) * 0.5f);
            var b = new Uml3DMeshBuilder();
            b.AddSphere(Vector3.zero, r, 16, 22);
            return b.ToMesh("Sphere");
        }

        /// <summary>A flattened ball — a field / property (design-conventions §1.1: the smallest, flattened sphere).</summary>
        public static Mesh FlatSphere(float w, float h, float d)
        {
            var b = new Uml3DMeshBuilder();
            b.AddEllipsoid(Vector3.zero,
                new Vector3(Mathf.Max(0.02f, w * 0.5f), Mathf.Max(0.02f, h * 0.42f),
                    Mathf.Max(0.02f, Mathf.Min(w, h) * 0.26f)), 14, 22);
            return b.ToMesh("FlatSphere");
        }

        /// <summary>A rectangle with both top corners cut off — the DMN business-knowledge-model silhouette.</summary>
        public static Mesh ClippedTop(float w, float h, float d)
        {
            float x = w * 0.5f, y = h * 0.5f, c = Mathf.Min(w * 0.16f, h * 0.4f);
            var o = new List<Vector2>
            {
                new Vector2(-x, -y), new Vector2(x, -y), new Vector2(x, y - c),
                new Vector2(x - c, y), new Vector2(-x + c, y), new Vector2(-x, y - c),
            };
            var b = new Uml3DMeshBuilder();
            b.AddConvexPrism(o, d * 0.5f, -d * 0.5f);
            return b.ToMesh("ClippedTop");
        }

        /// <summary>A rectangle whose bottom edge bulges into a shallow arc — the ArchiMate deliverable silhouette.</summary>
        public static Mesh RoundedBottom(float w, float h, float d)
        {
            float x = w * 0.5f, y = h * 0.5f, seam = y * 0.45f;
            var o = new List<Vector2> { new Vector2(-x, y), new Vector2(x, y), new Vector2(x, -seam) };
            const int seg = 14;
            for (int i = 0; i <= seg; i++)
            {
                float t = i / (float)seg;
                float ax = Mathf.Lerp(x, -x, t);
                float ay = -seam - (y - seam) * Mathf.Sin(t * Mathf.PI);
                o.Add(new Vector2(ax, ay));
            }
            o.Add(new Vector2(-x, -seam));
            var b = new Uml3DMeshBuilder();
            b.AddPrism(o, null, d * 0.5f, -d * 0.5f);
            return b.ToMesh("RoundedBottom");
        }

        /// <summary>Three stacked slabs with gaps — the ArchiMate plateau silhouette.</summary>
        public static Mesh Layered(float w, float h, float d)
        {
            float lh = h * 0.26f, y = h * 0.5f - lh * 0.5f;
            var b = new Uml3DMeshBuilder();
            float[] cys = { y, 0f, -y };
            for (int i = 0; i < 3; i++)
                b.AddBox(new Vector3(0f, cys[i], (i - 1) * d * 0.18f), new Vector3(w, lh, d));
            return b.ToMesh("Layered");
        }
    }
}
