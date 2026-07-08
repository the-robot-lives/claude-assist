using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Text;
using UnityEngine;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// Export the diagram's 3-D scene as a portable model: Wavefront <b>OBJ + MTL</b> (the interchange format
    /// Blender — and every other DCC tool — imports out of the box via File ▸ Import ▸ Wavefront) and/or a simple
    /// <b>JSON vertex-collections</b> file (<c>{"objects":[{name, color, vertices:[x,y,z,…], triangles:[…]}]}</c>)
    /// for scripts and custom pipelines. Geometry is gathered from every <see cref="MeshFilter"/> under the
    /// 3-D scene's DiagramRoot, plus each edge's <see cref="LineRenderer"/> baked to a mesh; uGUI face text is an
    /// overlay, not geometry, so labels aren't part of the mesh. OBJ output converts Unity's left-handed Y-up
    /// coordinates to OBJ's right-handed convention (x negated, triangle winding flipped); the JSON keeps raw
    /// Unity coordinates and notes so in its header.
    /// </summary>
    public sealed partial class UmlCanvas
    {
        /// <summary>Collect the scene geometry and write the chosen format(s) into a user-picked folder
        /// (native chooser; falls back to persistentDataPath/3d-export). The output path is copied to the
        /// clipboard so it can be pasted straight into Blender's import dialog.</summary>
        private void Export3DModel(bool obj, bool alsoJson = false)
        {
            var parts = Gather3DParts();
            if (parts.Count == 0) { Flash("nothing to export — the 3-D scene is empty"); return; }

            string dir = BrowseForFolder();
            if (string.IsNullOrEmpty(dir))
                dir = Path.Combine(Application.persistentDataPath, "3d-export");
            string baseName = SanitizeFileName(
                (_activePackage.IsValid ? PackageName(_activePackage) : "diagram")) +
                "-" + DateTime.Now.ToString("yyyyMMdd-HHmmss");

            try
            {
                Directory.CreateDirectory(dir);
                var written = new List<string>();
                if (obj)
                {
                    string objPath = Path.Combine(dir, baseName + ".obj");
                    string mtlPath = Path.Combine(dir, baseName + ".mtl");
                    WriteObj(parts, objPath, Path.GetFileName(mtlPath));
                    WriteMtl(parts, mtlPath);
                    written.Add(objPath);
                }
                if (!obj || alsoJson)
                {
                    string jsonPath = Path.Combine(dir, baseName + ".json");
                    WriteVertexJson(parts, jsonPath);
                    written.Add(jsonPath);
                }

                GUIUtility.systemCopyBuffer = written[0];
                int verts = 0; foreach (var p in parts) verts += p.Vertices.Length;
                Flash($"exported {parts.Count} object(s), {verts} vertices → {written[0]}  (path copied; labels are UI overlays, not mesh)");
            }
            catch (Exception ex)
            {
                Flash("3D export failed: " + ex.Message);
                Debug.LogWarning("3D export failed: " + ex);
            }
        }

        // ------------------------------------------------------------------ gathering

        private sealed class ExportPart
        {
            public string Name;
            public Color Color = Color.white;
            public Vector3[] Vertices;   // world space (Unity, left-handed Y-up)
            public Vector3[] Normals;    // may be empty
            public int[] Triangles;
        }

        /// <summary>World-space snapshot of every mesh (and baked edge line) under the 3-D diagram root.</summary>
        private List<ExportPart> Gather3DParts()
        {
            var parts = new List<ExportPart>();
            if (_scene == null || _scene.DiagramRoot == null) return parts;

            foreach (var mf in _scene.DiagramRoot.GetComponentsInChildren<MeshFilter>())
            {
                var mesh = mf != null ? mf.sharedMesh : null;
                if (mesh == null || mesh.vertexCount == 0) continue;
                var t = mf.transform;
                var verts = mesh.vertices;
                var world = new Vector3[verts.Length];
                for (int i = 0; i < verts.Length; i++) world[i] = t.TransformPoint(verts[i]);
                var normals = mesh.normals ?? new Vector3[0];
                var worldN = new Vector3[normals.Length];
                for (int i = 0; i < normals.Length; i++) worldN[i] = t.TransformDirection(normals[i]).normalized;

                parts.Add(new ExportPart
                {
                    Name = ExportPartName(t),
                    Color = RendererColor(mf.GetComponent<Renderer>()),
                    Vertices = world,
                    Normals = worldN,
                    Triangles = mesh.triangles,
                });
            }

            // Relationship lines: bake each LineRenderer into a mesh (world space when it renders in world space).
            foreach (var line in _scene.DiagramRoot.GetComponentsInChildren<LineRenderer>())
            {
                if (line == null || line.positionCount < 2) continue;
                var baked = new Mesh();
                try
                {
                    var cam = _scene.Camera;
                    if (cam != null) line.BakeMesh(baked, cam, true);
                    else line.BakeMesh(baked, true);
                    if (baked.vertexCount == 0) continue;
                    parts.Add(new ExportPart
                    {
                        Name = ExportPartName(line.transform) + "_edge",
                        Color = line.startColor,
                        Vertices = baked.vertices,      // BakeMesh with useTransform=true yields world space
                        Normals = baked.normals ?? new Vector3[0],
                        Triangles = baked.triangles,
                    });
                }
                catch (Exception) { /* a bake failure skips just that edge */ }
                finally { Destroy(baked); }
            }
            return parts;
        }

        private static string ExportPartName(Transform t)
        {
            // "Node:Order/Slab" → "Node_Order_Slab" — walk up to the diagram-root child for a stable prefix.
            var sb = new StringBuilder();
            var chain = new List<string>();
            var cur = t;
            int guard = 0;
            while (cur != null && cur.name != "Nodes" && cur.name != "Edges" && cur.name != "DiagramRoot" && guard++ < 8)
            { chain.Add(cur.name); cur = cur.parent; }
            for (int i = chain.Count - 1; i >= 0; i--)
            {
                if (sb.Length > 0) sb.Append('_');
                sb.Append(chain[i]);
            }
            return SanitizeFileName(sb.Length == 0 ? "part" : sb.ToString());
        }

        private static Color RendererColor(Renderer r)
        {
            if (r == null || r.sharedMaterial == null) return Color.white;
            var m = r.sharedMaterial;
            if (m.HasProperty("_BaseColor")) return m.GetColor("_BaseColor");
            if (m.HasProperty("_Color")) return m.color;
            return Color.white;
        }

        private static string SanitizeFileName(string s)
        {
            if (string.IsNullOrWhiteSpace(s)) return "diagram";
            var sb = new StringBuilder(s.Length);
            foreach (char c in s)
                sb.Append(char.IsLetterOrDigit(c) || c == '-' || c == '_' ? c : '_');
            return sb.ToString();
        }

        // ------------------------------------------------------------------ OBJ + MTL

        /// <summary>Wavefront OBJ: `o` per part, shared v/vn streams, faces 1-based; x negated + winding flipped
        /// for the left- → right-handed conversion so the model imports upright and un-mirrored in Blender.</summary>
        private static void WriteObj(List<ExportPart> parts, string objPath, string mtlFileName)
        {
            var inv = CultureInfo.InvariantCulture;
            var sb = new StringBuilder(1 << 20);
            sb.Append("# The Robot Draft — diagram 3D export\n");
            sb.Append("# Unity left-handed → OBJ right-handed: x negated, winding flipped\n");
            sb.Append("mtllib ").Append(mtlFileName).Append('\n');

            int vBase = 1, nBase = 1;
            for (int p = 0; p < parts.Count; p++)
            {
                var part = parts[p];
                sb.Append("o ").Append(part.Name).Append('_').Append(p).Append('\n');
                sb.Append("usemtl m").Append(p).Append('\n');

                foreach (var v in part.Vertices)
                    sb.Append("v ").Append((-v.x).ToString("F6", inv)).Append(' ')
                      .Append(v.y.ToString("F6", inv)).Append(' ')
                      .Append(v.z.ToString("F6", inv)).Append('\n');
                bool hasN = part.Normals != null && part.Normals.Length == part.Vertices.Length;
                if (hasN)
                    foreach (var n in part.Normals)
                        sb.Append("vn ").Append((-n.x).ToString("F6", inv)).Append(' ')
                          .Append(n.y.ToString("F6", inv)).Append(' ')
                          .Append(n.z.ToString("F6", inv)).Append('\n');

                var tri = part.Triangles;
                for (int i = 0; i + 2 < tri.Length; i += 3)
                {
                    // flipped winding: a, c, b
                    int a = tri[i] + vBase, b = tri[i + 1] + vBase, c = tri[i + 2] + vBase;
                    if (hasN)
                    {
                        int an = tri[i] + nBase, bn = tri[i + 1] + nBase, cn = tri[i + 2] + nBase;
                        sb.Append("f ").Append(a).Append("//").Append(an)
                          .Append(' ').Append(c).Append("//").Append(cn)
                          .Append(' ').Append(b).Append("//").Append(bn).Append('\n');
                    }
                    else
                    {
                        sb.Append("f ").Append(a).Append(' ').Append(c).Append(' ').Append(b).Append('\n');
                    }
                }
                vBase += part.Vertices.Length;
                if (hasN) nBase += part.Normals.Length;
            }
            File.WriteAllText(objPath, sb.ToString());
        }

        private static void WriteMtl(List<ExportPart> parts, string mtlPath)
        {
            var inv = CultureInfo.InvariantCulture;
            var sb = new StringBuilder();
            sb.Append("# The Robot Draft — materials\n");
            for (int p = 0; p < parts.Count; p++)
            {
                var c = parts[p].Color;
                sb.Append("newmtl m").Append(p).Append('\n');
                sb.Append("Kd ").Append(c.r.ToString("F4", inv)).Append(' ')
                  .Append(c.g.ToString("F4", inv)).Append(' ')
                  .Append(c.b.ToString("F4", inv)).Append('\n');
                sb.Append("Ka 0 0 0\nKs 0.05 0.05 0.05\nNs 8\n");
                if (c.a < 0.999f) sb.Append("d ").Append(c.a.ToString("F4", inv)).Append('\n');
                sb.Append('\n');
            }
            File.WriteAllText(mtlPath, sb.ToString());
        }

        // ------------------------------------------------------------------ JSON vertex collections

        /// <summary>The "simple vertices" format: flat per-object vertex / triangle-index arrays, raw Unity coords.</summary>
        private static void WriteVertexJson(List<ExportPart> parts, string jsonPath)
        {
            var inv = CultureInfo.InvariantCulture;
            var sb = new StringBuilder(1 << 20);
            sb.Append("{\n  \"format\": \"trd-vertex-collections\",\n  \"version\": 1,\n");
            sb.Append("  \"coordinates\": \"unity-left-handed-y-up\",\n  \"objects\": [\n");
            for (int p = 0; p < parts.Count; p++)
            {
                var part = parts[p];
                sb.Append("    {\n      \"name\": \"").Append(part.Name).Append('_').Append(p).Append("\",\n");
                sb.Append("      \"color\": \"#").Append(ColorUtility.ToHtmlStringRGB(part.Color)).Append("\",\n");
                sb.Append("      \"vertices\": [");
                for (int i = 0; i < part.Vertices.Length; i++)
                {
                    if (i > 0) sb.Append(',');
                    var v = part.Vertices[i];
                    sb.Append(v.x.ToString("F5", inv)).Append(',')
                      .Append(v.y.ToString("F5", inv)).Append(',')
                      .Append(v.z.ToString("F5", inv));
                }
                sb.Append("],\n      \"triangles\": [");
                for (int i = 0; i < part.Triangles.Length; i++)
                {
                    if (i > 0) sb.Append(',');
                    sb.Append(part.Triangles[i]);
                }
                sb.Append("]\n    }");
                sb.Append(p < parts.Count - 1 ? ",\n" : "\n");
            }
            sb.Append("  ]\n}\n");
            File.WriteAllText(jsonPath, sb.ToString());
        }
    }
}
