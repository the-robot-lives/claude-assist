using System.Collections.Generic;
using UnityEngine;

namespace TheRobotDraft.Uml3D
{
    /// <summary>
    /// A small accumulator for procedurally building a single <see cref="Mesh"/> out of primitives, used by the
    /// per-kind 3-D node shape builders (<c>Uml3DShape_*</c>). It exists so each UML node kind can compose its
    /// silhouette from convex prisms, boxes, cylinders, spheres, tubes and rings — all welded into one mesh with
    /// correct outward normals and front-facing (Unity CCW-relative-to-normal) winding — without re-deriving the
    /// triangle bookkeeping every time.
    ///
    /// COORDINATE CONTRACT for shape builders that feed <see cref="UmlNode3D"/>:
    ///   • The mesh must be centered on the origin and inscribed in the bounding box
    ///     [-w/2, w/2] × [-h/2, h/2] × [-d/2, d/2] (w = width, h = height, d = depth/thickness; world units).
    ///   • +Z is the FRONT face the camera reads (the node's text canvas sits at z = +d/2). Put the readable
    ///     silhouette's front cap at z = +d/2 and the back cap at z = -d/2.
    ///   • +Y is up, +X is right (the flat UI's axes are preserved — no Y flip).
    /// The node keeps a bounding-box collider / selection cage at the full w×h×d, so a builder may inset its
    /// visual mesh (e.g. a thin actor figure) without affecting picking.
    /// </summary>
    public sealed class Uml3DMeshBuilder
    {
        private readonly List<Vector3> _v = new();
        private readonly List<Vector3> _n = new();
        private readonly List<int> _t = new();

        // ---- low-level primitives -------------------------------------------------------------------------

        /// <summary>Add a triangle, deriving a flat normal from the vertex winding (a→b→c, CCW = front).</summary>
        public void AddTriangle(Vector3 a, Vector3 b, Vector3 c)
        {
            Vector3 n = Vector3.Cross(b - a, c - a);
            if (n.sqrMagnitude < 1e-12f) n = Vector3.forward; else n.Normalize();
            Emit(a, b, c, n);
        }

        /// <summary>
        /// Add a triangle that should face <paramref name="outward"/>: the winding is flipped if needed so the
        /// triangle is front-facing in that direction, and <paramref name="outward"/> is used as the flat normal.
        /// Use this when you know the intended facing but not the winding.
        /// </summary>
        public void AddTriangleOriented(Vector3 a, Vector3 b, Vector3 c, Vector3 outward)
        {
            outward = outward.sqrMagnitude < 1e-12f ? Vector3.forward : outward.normalized;
            Vector3 geo = Vector3.Cross(b - a, c - a);
            if (Vector3.Dot(geo, outward) < 0f) (b, c) = (c, b);
            Emit(a, b, c, outward);
        }

        /// <summary>Add a quad a→b→c→d (auto flat normal from the first triangle's winding).</summary>
        public void AddQuad(Vector3 a, Vector3 b, Vector3 c, Vector3 d)
        {
            AddTriangle(a, b, c);
            AddTriangle(a, c, d);
        }

        /// <summary>Add a quad whose front faces <paramref name="outward"/> (winding auto-corrected).</summary>
        public void AddQuadOriented(Vector3 a, Vector3 b, Vector3 c, Vector3 d, Vector3 outward)
        {
            AddTriangleOriented(a, b, c, outward);
            AddTriangleOriented(a, c, d, outward);
        }

        // ---- mid-level solids -----------------------------------------------------------------------------

        /// <summary>An axis-aligned box centered at <paramref name="center"/> with the given <paramref name="size"/>.</summary>
        public void AddBox(Vector3 center, Vector3 size)
        {
            float x = size.x * 0.5f, y = size.y * 0.5f, z = size.z * 0.5f;
            Vector3 c = center;
            Vector3 ppp = c + new Vector3(x, y, z), ppm = c + new Vector3(x, y, -z);
            Vector3 pmp = c + new Vector3(x, -y, z), pmm = c + new Vector3(x, -y, -z);
            Vector3 mpp = c + new Vector3(-x, y, z), mpm = c + new Vector3(-x, y, -z);
            Vector3 mmp = c + new Vector3(-x, -y, z), mmm = c + new Vector3(-x, -y, -z);
            AddQuadOriented(mmp, pmp, ppp, mpp, Vector3.forward);  // +Z front
            AddQuadOriented(pmm, mmm, mpm, ppm, Vector3.back);     // -Z back
            AddQuadOriented(pmp, pmm, ppm, ppp, Vector3.right);    // +X
            AddQuadOriented(mmm, mmp, mpp, mpm, Vector3.left);     // -X
            AddQuadOriented(mpp, ppp, ppm, mpm, Vector3.up);       // +Y
            AddQuadOriented(mmm, pmm, pmp, mmp, Vector3.down);     // -Y
        }

        /// <summary>A box rotated by <paramref name="rot"/> — for angled limb segments and tilted parts.</summary>
        public void AddOrientedBox(Vector3 center, Vector3 size, Quaternion rot)
        {
            Vector3 hx = rot * new Vector3(size.x * 0.5f, 0f, 0f);
            Vector3 hy = rot * new Vector3(0f, size.y * 0.5f, 0f);
            Vector3 hz = rot * new Vector3(0f, 0f, size.z * 0.5f);
            Vector3 ppp = center + hx + hy + hz, ppm = center + hx + hy - hz;
            Vector3 pmp = center + hx - hy + hz, pmm = center + hx - hy - hz;
            Vector3 mpp = center - hx + hy + hz, mpm = center - hx + hy - hz;
            Vector3 mmp = center - hx - hy + hz, mmm = center - hx - hy - hz;
            Vector3 nx = rot * Vector3.right, ny = rot * Vector3.up, nz = rot * Vector3.forward;
            AddQuadOriented(mmp, pmp, ppp, mpp, nz);   // +Z
            AddQuadOriented(pmm, mmm, mpm, ppm, -nz);  // -Z
            AddQuadOriented(pmp, pmm, ppm, ppp, nx);   // +X
            AddQuadOriented(mmm, mmp, mpp, mpm, -nx);  // -X
            AddQuadOriented(mpp, ppp, ppm, mpm, ny);   // +Y
            AddQuadOriented(mmm, pmm, pmp, mmp, -ny);  // -Y
        }

        /// <summary>
        /// Extrude a closed 2-D <paramref name="outline"/> (a polygon in the XY plane) along Z into a prism:
        /// a front cap at <paramref name="zFront"/> (normal +Z), a back cap at <paramref name="zBack"/>
        /// (normal -Z), and outward side walls. The outline may be wound either way — caps and walls are oriented
        /// automatically. Caps are fan-triangulated, so the outline must be CONVEX (ellipse, rounded rect,
        /// diamond, stadium, parallelogram, regular polygon…). For non-convex silhouettes, compose several
        /// convex prisms / boxes instead. Pass <paramref name="zFront"/> = +d/2 and <paramref name="zBack"/> = -d/2.
        /// </summary>
        public void AddConvexPrism(IList<Vector2> outline, float zFront, float zBack)
            => AddPrism(outline, null, zFront, zBack, 0f);

        /// <summary>
        /// Extrude a GENERAL closed 2-D contour (concave allowed) along Z into a prism, with optional interior
        /// <paramref name="holes"/> and an optional front <paramref name="bevel"/> (45°-ish chamfer):
        ///   • Front cap at <paramref name="zFront"/> (normal +Z) and back cap at <paramref name="zBack"/>
        ///     (normal −Z), triangulated by ear-clipping (<see cref="TriangulateWithHoles"/> when holes are present,
        ///     otherwise <see cref="Triangulate"/>).
        ///   • Outward side walls along the outer contour, plus inward-facing walls around every hole.
        ///   • <paramref name="bevel"/> &gt; 0 replaces the flat front cap with a chamfer ring (from the original
        ///     front edge out to a contour inset by <paramref name="bevel"/> and raised by <paramref name="bevel"/>
        ///     in +Z) followed by the inset cap. Holes keep straight walls under a bevel.
        /// A flat cap (<paramref name="bevel"/> == 0, <paramref name="holes"/> == null) reproduces the old convex
        /// prism exactly. Robust to bad input: never throws, falls back to a fan triangulation on degenerate data.
        /// Pass <paramref name="zFront"/> = +d/2 and <paramref name="zBack"/> = -d/2.
        /// </summary>
        public void AddPrism(IList<Vector2> outer, IList<IList<Vector2>> holes, float zFront, float zBack, float bevel = 0f)
        {
            if (outer == null || outer.Count < 3) return;
            bool hasHoles = holes != null && holes.Count > 0;

            // --- triangulated cap topology (shared by front flat cap and back cap) ---
            Vector2[] capVerts;
            int[] capTris;
            if (hasHoles)
            {
                capTris = TriangulateWithHoles(outer, holes, out capVerts);
            }
            else
            {
                capVerts = new Vector2[outer.Count];
                for (int i = 0; i < outer.Count; i++) capVerts[i] = outer[i];
                capTris = Triangulate(capVerts);
            }

            bool bevelOn = bevel > 1e-5f;

            // --- front cap (+Z) ---
            if (!bevelOn)
            {
                for (int i = 0; i + 2 < capTris.Length; i += 3)
                {
                    Vector2 A = capVerts[capTris[i]], B = capVerts[capTris[i + 1]], C = capVerts[capTris[i + 2]];
                    AddTriangleOriented(new Vector3(A.x, A.y, zFront), new Vector3(B.x, B.y, zFront),
                        new Vector3(C.x, C.y, zFront), Vector3.forward);
                }
            }
            else
            {
                float frontCapZ = zFront + bevel;
                Vector2[] inset = InsetContour(outer, bevel);
                int m = outer.Count;
                // chamfer ring: from original front edge (at zFront) up/in to the raised inset edge
                for (int i = 0; i < m; i++)
                {
                    Vector2 a = outer[i], b = outer[(i + 1) % m];
                    Vector2 ai = inset[i], bi = inset[(i + 1) % m];
                    Vector2 edge = b - a;
                    Vector3 outward = new Vector3(edge.y, -edge.x, 0f).normalized + Vector3.forward;
                    AddQuadOriented(new Vector3(a.x, a.y, zFront), new Vector3(b.x, b.y, zFront),
                        new Vector3(bi.x, bi.y, frontCapZ), new Vector3(ai.x, ai.y, frontCapZ), outward);
                }
                // inset cap at the raised plane
                Vector2[] icVerts;
                int[] icTris;
                if (hasHoles) icTris = TriangulateWithHoles(inset, holes, out icVerts);
                else { icVerts = inset; icTris = Triangulate(inset); }
                for (int i = 0; i + 2 < icTris.Length; i += 3)
                {
                    Vector2 A = icVerts[icTris[i]], B = icVerts[icTris[i + 1]], C = icVerts[icTris[i + 2]];
                    AddTriangleOriented(new Vector3(A.x, A.y, frontCapZ), new Vector3(B.x, B.y, frontCapZ),
                        new Vector3(C.x, C.y, frontCapZ), Vector3.forward);
                }
            }

            // --- back cap (−Z) ---
            for (int i = 0; i + 2 < capTris.Length; i += 3)
            {
                Vector2 A = capVerts[capTris[i]], B = capVerts[capTris[i + 1]], C = capVerts[capTris[i + 2]];
                AddTriangleOriented(new Vector3(A.x, A.y, zBack), new Vector3(B.x, B.y, zBack),
                    new Vector3(C.x, C.y, zBack), Vector3.back);
            }

            // --- side walls ---
            AddWalls(outer, zFront, zBack, faceTowardInterior: false); // outer: outward
            if (hasHoles)
                foreach (var h in holes)
                    if (h != null && h.Count >= 3) AddWalls(h, zFront, zBack, faceTowardInterior: true); // holes: inward
        }

        /// <summary>
        /// Build a flat ribbon (stroked open or closed path) following <paramref name="points"/>: each segment is a
        /// box of cross-section <paramref name="width"/> (across) × <paramref name="depth"/> (in Z), centered at
        /// <paramref name="z"/>; interior joints get a round filler so the ribbon stays watertight around corners.
        /// Represents an SVG stroked path. Endpoints are flat (butt) caps; <paramref name="closed"/> wraps the last
        /// point back to the first. Robust to degenerate/coincident points (zero-length segments are skipped).
        /// </summary>
        public void AddPolyline(IList<Vector2> points, float width, float z, float depth, bool closed)
        {
            if (points == null || points.Count < 2) return;
            float hw = Mathf.Max(1e-4f, width * 0.5f);
            float zF = z + depth * 0.5f, zB = z - depth * 0.5f;
            int n = points.Count;
            int segCount = closed ? n : n - 1;

            for (int s = 0; s < segCount; s++)
            {
                Vector2 p0 = points[s], p1 = points[(s + 1) % n];
                Vector2 dir = p1 - p0;
                float len = dir.magnitude;
                if (len < 1e-6f) continue;
                dir /= len;
                Vector2 nrm = new Vector2(-dir.y, dir.x) * hw;
                Vector2 a = p0 + nrm, b = p1 + nrm, c = p1 - nrm, d = p0 - nrm;
                AddQuadOriented(V(a, zF), V(b, zF), V(c, zF), V(d, zF), Vector3.forward);        // front
                AddQuadOriented(V(a, zB), V(b, zB), V(c, zB), V(d, zB), Vector3.back);           // back
                AddQuadOriented(V(a, zF), V(b, zF), V(b, zB), V(a, zB), new Vector3(nrm.x, nrm.y, 0f));   // +side
                AddQuadOriented(V(c, zF), V(d, zF), V(d, zB), V(c, zB), new Vector3(-nrm.x, -nrm.y, 0f)); // −side
                AddQuadOriented(V(b, zF), V(c, zF), V(c, zB), V(b, zB), new Vector3(dir.x, dir.y, 0f));   // end cap
                AddQuadOriented(V(d, zF), V(a, zF), V(a, zB), V(d, zB), new Vector3(-dir.x, -dir.y, 0f)); // start cap
            }

            // round fillers at interior joints (and every vertex when closed) to bridge the corner gaps
            int jStart = closed ? 0 : 1, jEnd = closed ? n : n - 1;
            for (int j = jStart; j < jEnd; j++)
            {
                Vector2 p = points[j % n];
                AddCylinder(new Vector3(p.x, p.y, zB), Vector3.forward, depth, hw, 10, true);
            }
        }

        // ---- triangulation (ear clipping + hole bridging) -------------------------------------------------

        /// <summary>
        /// Ear-clipping triangulation of a simple (possibly concave) polygon. Returns triangle indices into
        /// <paramref name="outer"/>. Accepts CW or CCW input (detected via signed area; processed CCW internally).
        /// Skips degenerate/collinear ears; never hangs — bails out to a fan over the remainder on bad input.
        /// </summary>
        public static int[] Triangulate(IList<Vector2> outer)
        {
            int n = outer == null ? 0 : outer.Count;
            if (n < 3) return System.Array.Empty<int>();

            // CCW-ordered list of original indices
            var idx = new List<int>(n);
            if (SignedArea(outer) >= 0f) for (int i = 0; i < n; i++) idx.Add(i);
            else for (int i = n - 1; i >= 0; i--) idx.Add(i);

            var tris = new List<int>((n - 2) * 3);
            int count = idx.Count;
            int safety = count * count + 16;
            int guard = 0;

            while (count > 3)
            {
                bool ear = false;
                for (int i = 0; i < count; i++)
                {
                    int i0 = idx[(i + count - 1) % count];
                    int i1 = idx[i];
                    int i2 = idx[(i + 1) % count];
                    Vector2 a = outer[i0], b = outer[i1], c = outer[i2];
                    if (Cross(b - a, c - b) <= 1e-9f) continue; // reflex or collinear
                    bool contains = false;
                    for (int j = 0; j < count; j++)
                    {
                        int vj = idx[j];
                        if (vj == i0 || vj == i1 || vj == i2) continue;
                        if (PointInTri(outer[vj], a, b, c)) { contains = true; break; }
                    }
                    if (contains) continue;
                    tris.Add(i0); tris.Add(i1); tris.Add(i2);
                    idx.RemoveAt(i);
                    count--;
                    ear = true;
                    break;
                }
                if (!ear || ++guard > safety)
                {
                    // fallback: fan over whatever remains (never hang)
                    for (int i = 1; i < count - 1; i++) { tris.Add(idx[0]); tris.Add(idx[i]); tris.Add(idx[i + 1]); }
                    return tris.ToArray();
                }
            }
            if (count == 3) { tris.Add(idx[0]); tris.Add(idx[1]); tris.Add(idx[2]); }
            return tris.ToArray();
        }

        /// <summary>
        /// Triangulate a polygon with holes by the standard "bridge holes then ear-clip" (Eberly) approach: each
        /// hole is spliced into the outer contour via a bridge edge from the hole's max-X vertex to a mutually
        /// visible outer vertex (hole inserted with opposite winding), then the merged contour is ear-clipped.
        /// <paramref name="verts"/> returns the merged vertex list the returned indices refer to. Robust: holes
        /// with &lt; 3 points are ignored; bad input degrades to a fan rather than throwing or hanging.
        /// </summary>
        public static int[] TriangulateWithHoles(IList<Vector2> outer, IList<IList<Vector2>> holes, out Vector2[] verts)
        {
            var contour = new List<Vector2>(outer);
            if (SignedArea(contour) < 0f) contour.Reverse(); // outer CCW

            if (holes == null || holes.Count == 0)
            {
                verts = contour.ToArray();
                return Triangulate(contour);
            }

            // hole copies wound CW (opposite of outer), bridged rightmost-first
            var holeList = new List<List<Vector2>>();
            foreach (var h in holes)
            {
                if (h == null || h.Count < 3) continue;
                var hl = new List<Vector2>(h);
                if (SignedArea(hl) > 0f) hl.Reverse(); // CW
                holeList.Add(hl);
            }
            holeList.Sort((x, y) => MaxX(y).CompareTo(MaxX(x)));

            foreach (var hole in holeList) BridgeHole(contour, hole);

            verts = contour.ToArray();
            return Triangulate(contour);
        }

        private static void BridgeHole(List<Vector2> contour, List<Vector2> hole)
        {
            // M = hole vertex with max X
            int mIdx = 0;
            for (int i = 1; i < hole.Count; i++) if (hole[i].x > hole[mIdx].x) mIdx = i;
            Vector2 M = hole[mIdx];

            // cast a +X ray from M, find nearest contour edge crossing at x >= M.x
            int n = contour.Count;
            float bestDist = float.MaxValue;
            int edgeA = -1, edgeB = -1;
            Vector2 hit = Vector2.zero;
            for (int i = 0; i < n; i++)
            {
                Vector2 a = contour[i], b = contour[(i + 1) % n];
                if ((a.y > M.y) == (b.y > M.y)) continue;             // no horizontal crossing
                float t = (M.y - a.y) / (b.y - a.y);
                float xInt = a.x + t * (b.x - a.x);
                if (xInt < M.x) continue;
                float dist = xInt - M.x;
                if (dist < bestDist) { bestDist = dist; hit = new Vector2(xInt, M.y); edgeA = i; edgeB = (i + 1) % n; }
            }

            int bridgeIdx;
            if (edgeA < 0)
            {
                // degenerate: connect to the contour's max-X vertex
                bridgeIdx = 0;
                for (int i = 1; i < n; i++) if (contour[i].x > contour[bridgeIdx].x) bridgeIdx = i;
            }
            else
            {
                int pIdx = contour[edgeA].x > contour[edgeB].x ? edgeA : edgeB;
                Vector2 P = contour[pIdx];
                int best = pIdx;
                float bestCos = AngleCos(M, hit, P);
                for (int i = 0; i < n; i++)
                {
                    if (i == pIdx) continue;
                    Vector2 R = contour[i];
                    if (PointInTri(R, M, hit, P))
                    {
                        float ca = AngleCos(M, hit, R);
                        if (ca > bestCos) { bestCos = ca; best = i; }
                    }
                }
                bridgeIdx = best;
            }

            // splice: contour[0..bridgeIdx] -> hole(M..around..M) -> contour[bridgeIdx] -> rest
            var merged = new List<Vector2>(contour.Count + hole.Count + 2);
            for (int i = 0; i <= bridgeIdx; i++) merged.Add(contour[i]);
            for (int k = 0; k <= hole.Count; k++) merged.Add(hole[(mIdx + k) % hole.Count]);
            merged.Add(contour[bridgeIdx]);
            for (int i = bridgeIdx + 1; i < contour.Count; i++) merged.Add(contour[i]);

            contour.Clear();
            contour.AddRange(merged);
        }

        // ---- mid-level solids (continued) -----------------------------------------------------------------

        /// <summary>
        /// A cylinder of <paramref name="length"/> along <paramref name="axis"/>, starting at
        /// <paramref name="baseCenter"/>. Adds the tube wall and (optionally) both end caps.
        /// </summary>
        public void AddCylinder(Vector3 baseCenter, Vector3 axis, float length, float radius, int segments, bool caps)
        {
            axis = axis.normalized;
            BasisFor(axis, out Vector3 u, out Vector3 vAxis);
            Vector3 topCenter = baseCenter + axis * length;
            for (int i = 0; i < segments; i++)
            {
                float a0 = i / (float)segments * Mathf.PI * 2f;
                float a1 = (i + 1) / (float)segments * Mathf.PI * 2f;
                Vector3 d0 = (Mathf.Cos(a0) * u + Mathf.Sin(a0) * vAxis);
                Vector3 d1 = (Mathf.Cos(a1) * u + Mathf.Sin(a1) * vAxis);
                Vector3 b0 = baseCenter + d0 * radius, b1 = baseCenter + d1 * radius;
                Vector3 t0 = topCenter + d0 * radius, t1 = topCenter + d1 * radius;
                AddQuadOriented(b0, b1, t1, t0, (d0 + d1) * 0.5f); // wall, outward = radial
                if (caps)
                {
                    AddTriangleOriented(baseCenter, b1, b0, -axis); // bottom
                    AddTriangleOriented(topCenter, t0, t1, axis);   // top
                }
            }
        }

        /// <summary>A UV sphere centered at <paramref name="center"/>.</summary>
        public void AddSphere(Vector3 center, float radius, int latSegs = 12, int lonSegs = 16)
        {
            for (int la = 0; la < latSegs; la++)
            {
                float t0 = la / (float)latSegs * Mathf.PI;
                float t1 = (la + 1) / (float)latSegs * Mathf.PI;
                for (int lo = 0; lo < lonSegs; lo++)
                {
                    float p0 = lo / (float)lonSegs * Mathf.PI * 2f;
                    float p1 = (lo + 1) / (float)lonSegs * Mathf.PI * 2f;
                    Vector3 a = SpherePt(t0, p0), b = SpherePt(t1, p0), c = SpherePt(t1, p1), dd = SpherePt(t0, p1);
                    AddQuadOriented(center + a * radius, center + b * radius, center + c * radius,
                        center + dd * radius, (a + b + c + dd));
                }
            }
        }

        /// <summary>
        /// A UV ellipsoid (ovoid) centered at <paramref name="center"/> with per-axis <paramref name="radii"/>
        /// (rx, ry, rz). Normals use the true surface gradient so the dome shades smoothly. Pass rz = d/2 to keep
        /// the front pole on the slab face, or a larger rz for a rounder egg that bulges toward the camera.
        /// </summary>
        public void AddEllipsoid(Vector3 center, Vector3 radii, int latSegs = 14, int lonSegs = 22)
        {
            float rx = Mathf.Max(1e-4f, radii.x), ry = Mathf.Max(1e-4f, radii.y), rz = Mathf.Max(1e-4f, radii.z);
            for (int la = 0; la < latSegs; la++)
            {
                float t0 = la / (float)latSegs * Mathf.PI;
                float t1 = (la + 1) / (float)latSegs * Mathf.PI;
                for (int lo = 0; lo < lonSegs; lo++)
                {
                    float p0 = lo / (float)lonSegs * Mathf.PI * 2f;
                    float p1 = (lo + 1) / (float)lonSegs * Mathf.PI * 2f;
                    Vector3 ua = SpherePt(t0, p0), ub = SpherePt(t1, p0), uc = SpherePt(t1, p1), ud = SpherePt(t0, p1);
                    Vector3 pa = center + new Vector3(ua.x * rx, ua.y * ry, ua.z * rz);
                    Vector3 pb = center + new Vector3(ub.x * rx, ub.y * ry, ub.z * rz);
                    Vector3 pc = center + new Vector3(uc.x * rx, uc.y * ry, uc.z * rz);
                    Vector3 pd = center + new Vector3(ud.x * rx, ud.y * ry, ud.z * rz);
                    // Surface gradient ∝ (x/rx², y/ry², z/rz²); summed across the quad's corners for a flat normal.
                    Vector3 outward =
                        new Vector3(ua.x / rx, ua.y / ry, ua.z / rz) + new Vector3(ub.x / rx, ub.y / ry, ub.z / rz) +
                        new Vector3(uc.x / rx, uc.y / ry, uc.z / rz) + new Vector3(ud.x / rx, ud.y / ry, ud.z / rz);
                    AddQuadOriented(pa, pb, pc, pd, outward);
                }
            }
        }

        /// <summary>A capped cylinder ("tube") spanning two points — used for actor limbs and similar struts.</summary>
        public void AddTube(Vector3 p0, Vector3 p1, float radius, int segments = 8)
        {
            Vector3 axis = p1 - p0;
            float len = axis.magnitude;
            if (len < 1e-6f) return;
            AddCylinder(p0, axis / len, len, radius, segments, true);
        }

        /// <summary>
        /// A torus (ring) centered at <paramref name="center"/> lying in the plane perpendicular to
        /// <paramref name="axis"/>. <paramref name="majorR"/> is the ring radius, <paramref name="minorR"/> the
        /// tube radius.
        /// </summary>
        public void AddTorus(Vector3 center, Vector3 axis, float majorR, float minorR, int majorSegs = 24, int minorSegs = 10)
        {
            axis = axis.normalized;
            BasisFor(axis, out Vector3 u, out Vector3 v);
            for (int i = 0; i < majorSegs; i++)
            {
                float A0 = i / (float)majorSegs * Mathf.PI * 2f;
                float A1 = (i + 1) / (float)majorSegs * Mathf.PI * 2f;
                Vector3 c0 = (Mathf.Cos(A0) * u + Mathf.Sin(A0) * v);
                Vector3 c1 = (Mathf.Cos(A1) * u + Mathf.Sin(A1) * v);
                Vector3 ringC0 = center + c0 * majorR, ringC1 = center + c1 * majorR;
                for (int j = 0; j < minorSegs; j++)
                {
                    float B0 = j / (float)minorSegs * Mathf.PI * 2f;
                    float B1 = (j + 1) / (float)minorSegs * Mathf.PI * 2f;
                    Vector3 n00 = Mathf.Cos(B0) * c0 + Mathf.Sin(B0) * axis;
                    Vector3 n10 = Mathf.Cos(B0) * c1 + Mathf.Sin(B0) * axis;
                    Vector3 n11 = Mathf.Cos(B1) * c1 + Mathf.Sin(B1) * axis;
                    Vector3 n01 = Mathf.Cos(B1) * c0 + Mathf.Sin(B1) * axis;
                    AddQuadOriented(ringC0 + n00 * minorR, ringC1 + n10 * minorR,
                        ringC1 + n11 * minorR, ringC0 + n01 * minorR, (n00 + n10 + n11 + n01));
                }
            }
        }

        // ---- 2-D outline helpers (XY) ---------------------------------------------------------------------

        /// <summary>CCW ellipse outline centered on the origin.</summary>
        public static Vector2[] EllipseOutline(float rx, float ry, int segs = 40)
        {
            var pts = new Vector2[segs];
            for (int i = 0; i < segs; i++)
            {
                float a = i / (float)segs * Mathf.PI * 2f;
                pts[i] = new Vector2(Mathf.Cos(a) * rx, Mathf.Sin(a) * ry);
            }
            return pts;
        }

        /// <summary>CCW rounded-rectangle outline of size w×h centered on the origin, corner radius <paramref name="rad"/>.</summary>
        public static Vector2[] RoundedRectOutline(float w, float h, float rad, int cornerSegs = 6)
        {
            float x = w * 0.5f, y = h * 0.5f;
            rad = Mathf.Min(rad, Mathf.Min(x, y));
            var pts = new List<Vector2>();
            void Corner(Vector2 cc, float start)
            {
                for (int i = 0; i <= cornerSegs; i++)
                {
                    float a = start + i / (float)cornerSegs * (Mathf.PI * 0.5f);
                    pts.Add(new Vector2(cc.x + Mathf.Cos(a) * rad, cc.y + Mathf.Sin(a) * rad));
                }
            }
            Corner(new Vector2(x - rad, y - rad), 0f);              // top-right
            Corner(new Vector2(-x + rad, y - rad), Mathf.PI * 0.5f); // top-left
            Corner(new Vector2(-x + rad, -y + rad), Mathf.PI);       // bottom-left
            Corner(new Vector2(x - rad, -y + rad), Mathf.PI * 1.5f); // bottom-right
            return pts.ToArray();
        }

        /// <summary>CCW diamond (rhombus) outline filling w×h.</summary>
        public static Vector2[] DiamondOutline(float w, float h)
        {
            float x = w * 0.5f, y = h * 0.5f;
            return new[] { new Vector2(x, 0f), new Vector2(0f, y), new Vector2(-x, 0f), new Vector2(0f, -y) };
        }

        // ---- finalize -------------------------------------------------------------------------------------

        public Mesh ToMesh(string name = "UmlNodeShape")
        {
            var mesh = new Mesh { name = name };
            if (_v.Count > 65000) mesh.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32;
            mesh.SetVertices(_v);
            mesh.SetNormals(_n);
            mesh.SetTriangles(_t, 0);
            mesh.RecalculateBounds();
            return mesh;
        }

        // ---- internals ------------------------------------------------------------------------------------

        private void Emit(Vector3 a, Vector3 b, Vector3 c, Vector3 n)
        {
            int i = _v.Count;
            _v.Add(a); _v.Add(b); _v.Add(c);
            _n.Add(n); _n.Add(n); _n.Add(n);
            _t.Add(i); _t.Add(i + 1); _t.Add(i + 2);
        }

        private static Vector3 V(Vector2 p, float z) => new(p.x, p.y, z);

        /// <summary>Emit side walls for a contour between zFront and zBack, winding-robust (uses signed area to
        /// find the true outward direction). <paramref name="faceTowardInterior"/> = true makes hole walls face
        /// into the empty hole.</summary>
        private void AddWalls(IList<Vector2> contour, float zFront, float zBack, bool faceTowardInterior)
        {
            int m = contour.Count;
            if (m < 2) return;
            float area = SignedArea(contour);
            for (int i = 0; i < m; i++)
            {
                Vector2 a = contour[i], b = contour[(i + 1) % m];
                Vector2 edge = b - a;
                Vector3 perp = new Vector3(edge.y, -edge.x, 0f);    // outward for CCW
                Vector3 awayFromInterior = area >= 0f ? perp : -perp;
                Vector3 normal = faceTowardInterior ? -awayFromInterior : awayFromInterior;
                if (normal.sqrMagnitude < 1e-12f) continue;
                AddQuadOriented(new Vector3(a.x, a.y, zFront), new Vector3(b.x, b.y, zFront),
                    new Vector3(b.x, b.y, zBack), new Vector3(a.x, a.y, zBack), normal);
            }
        }

        /// <summary>Inset a contour inward by <paramref name="d"/> via per-vertex angle bisectors (winding-aware,
        /// miter clamped to avoid blow-ups at sharp corners). Used for the front bevel chamfer.</summary>
        private static Vector2[] InsetContour(IList<Vector2> c, float d)
        {
            int m = c.Count;
            var outp = new Vector2[m];
            float sign = SignedArea(c) >= 0f ? 1f : -1f;
            for (int i = 0; i < m; i++)
            {
                Vector2 prev = c[(i - 1 + m) % m], cur = c[i], next = c[(i + 1) % m];
                Vector2 e0 = (cur - prev), e1 = (next - cur);
                if (e0.sqrMagnitude > 1e-12f) e0.Normalize();
                if (e1.sqrMagnitude > 1e-12f) e1.Normalize();
                Vector2 n0 = new Vector2(-e0.y, e0.x) * sign; // inward for CCW
                Vector2 n1 = new Vector2(-e1.y, e1.x) * sign;
                Vector2 bis = n0 + n1;
                if (bis.sqrMagnitude < 1e-9f) bis = n1;
                bis.Normalize();
                float denom = Mathf.Max(0.25f, Vector2.Dot(bis, n1));
                outp[i] = cur + bis * (d / denom);
            }
            return outp;
        }

        private static float SignedArea(IList<Vector2> p)
        {
            float s = 0f; int n = p.Count;
            for (int i = 0; i < n; i++) { Vector2 a = p[i], b = p[(i + 1) % n]; s += a.x * b.y - b.x * a.y; }
            return s * 0.5f;
        }

        private static float Cross(Vector2 a, Vector2 b) => a.x * b.y - a.y * b.x;

        private static bool PointInTri(Vector2 p, Vector2 a, Vector2 b, Vector2 c)
        {
            float d1 = Cross(b - a, p - a), d2 = Cross(c - b, p - b), d3 = Cross(a - c, p - c);
            bool neg = d1 < 0f || d2 < 0f || d3 < 0f;
            bool pos = d1 > 0f || d2 > 0f || d3 > 0f;
            return !(neg && pos); // inside or on boundary
        }

        /// <summary>Cosine of the angle between the ray a→b and the direction a→r (used for visible-vertex pick).</summary>
        private static float AngleCos(Vector2 a, Vector2 b, Vector2 r)
        {
            Vector2 d1 = b - a, d2 = r - a;
            if (d1.sqrMagnitude < 1e-12f || d2.sqrMagnitude < 1e-12f) return -1f;
            return Vector2.Dot(d1.normalized, d2.normalized);
        }

        private static float MaxX(List<Vector2> p)
        {
            float mx = float.MinValue;
            foreach (var v in p) if (v.x > mx) mx = v.x;
            return mx;
        }

        private static Vector3 SpherePt(float theta, float phi) =>
            new(Mathf.Sin(theta) * Mathf.Cos(phi), Mathf.Cos(theta), Mathf.Sin(theta) * Mathf.Sin(phi));

        /// <summary>Two unit vectors spanning the plane perpendicular to <paramref name="axis"/>.</summary>
        private static void BasisFor(Vector3 axis, out Vector3 u, out Vector3 v)
        {
            Vector3 reference = Mathf.Abs(axis.y) < 0.99f ? Vector3.up : Vector3.right;
            u = Vector3.Normalize(Vector3.Cross(reference, axis));
            v = Vector3.Normalize(Vector3.Cross(axis, u));
        }
    }
}
