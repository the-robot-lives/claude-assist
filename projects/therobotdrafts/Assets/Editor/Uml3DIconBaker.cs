using System.IO;
using UnityEngine;
using UnityEditor;
using TheRobotDraft.Authoring.Model;
using TheRobotDraft.Uml3D;

namespace TheRobotDraft.EditorTools
{
    /// <summary>
    /// Renders the real per-kind 3-D node mesh (<see cref="Uml3DNodeShape.Build"/>) for every
    /// <see cref="ElementKind"/> to a PNG, so the actual in-engine geometry can be reviewed as a gallery — the
    /// 3-D counterpart of the 2-D <c>Assets/Icons/Nodes</c> silhouette set. Each node is lit and shot at a 3/4
    /// angle so the extrusion depth reads. Run headless with:
    ///   Unity -batchmode -projectPath . -executeMethod TheRobotDraft.EditorTools.Uml3DIconBaker.BakeAll -quit
    /// or from the editor via Tools ▸ Robot Draft ▸ Bake 3D Node Gallery.
    /// </summary>
    public static class Uml3DIconBaker
    {
        private const int Size = 256;
        private const string OutDir = "Assets/Icons/Nodes3D";

        [MenuItem("Tools/Robot Draft/Bake 3D Node Gallery")]
        public static void BakeAll()
        {
            Directory.CreateDirectory(OutDir);

            var bg = new Color(0.078f, 0.086f, 0.106f, 1f); // matches the 2D contact sheet (#14171C)

            var camGo = new GameObject("BakeCam");
            var cam = camGo.AddComponent<Camera>();
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = bg;
            cam.orthographic = true;
            cam.orthographicSize = 1.0f;
            cam.nearClipPlane = 0.01f;
            cam.farClipPlane = 50f;
            camGo.transform.position = new Vector3(0f, 0f, 4f);
            camGo.transform.LookAt(Vector3.zero); // forward = -Z, so the +Z front face points at the camera

            var lightGo = new GameObject("BakeLight");
            var light = lightGo.AddComponent<Light>();
            light.type = LightType.Directional;
            light.intensity = 1.05f;
            light.color = new Color(1f, 0.98f, 0.95f);
            lightGo.transform.rotation = Quaternion.Euler(38f, 205f, 0f); // rakes across the +Z face and side walls

            var prevMode = RenderSettings.ambientMode;
            var prevAmbient = RenderSettings.ambientLight;
            RenderSettings.ambientMode = UnityEngine.Rendering.AmbientMode.Flat;
            RenderSettings.ambientLight = new Color(0.42f, 0.44f, 0.48f);

            var rt = new RenderTexture(Size, Size, 24, RenderTextureFormat.ARGB32, RenderTextureReadWrite.sRGB)
            { antiAliasing = 8 };
            cam.targetTexture = rt;

            Shader lit = Shader.Find("Standard");
            if (lit == null) lit = Shader.Find("Universal Render Pipeline/Lit");
            if (lit == null) lit = Shader.Find("Diffuse");

            int n = 0;
            foreach (ElementKind kind in System.Enum.GetValues(typeof(ElementKind)))
            {
                Mesh mesh;
                try { mesh = Uml3DNodeShape.Build(kind, 1.3f, 0.85f, 0.18f); }
                catch (System.Exception e) { Debug.LogWarning($"[bake] {kind}: {e.Message}"); continue; }
                if (mesh == null || mesh.vertexCount == 0) continue;

                Color hue = HexToColor(KindInfo.Hue(kind));
                var mat = new Material(lit) { color = hue };
                if (mat.HasProperty("_BaseColor")) mat.SetColor("_BaseColor", hue);
                if (mat.HasProperty("_Glossiness")) mat.SetFloat("_Glossiness", 0.12f);
                if (mat.HasProperty("_Smoothness")) mat.SetFloat("_Smoothness", 0.12f);

                var go = new GameObject(kind.ToString());
                go.AddComponent<MeshFilter>().sharedMesh = mesh;
                go.AddComponent<MeshRenderer>().sharedMaterial = mat;
                go.transform.rotation = Quaternion.Euler(16f, -26f, 0f); // 3/4 view so depth reads

                RenderTexture.active = rt;
                GL.Clear(true, true, bg);
                cam.Render();

                var tex = new Texture2D(Size, Size, TextureFormat.RGBA32, false);
                tex.ReadPixels(new Rect(0, 0, Size, Size), 0, 0);
                tex.Apply();
                File.WriteAllBytes(Path.Combine(OutDir, kind + ".png"), tex.EncodeToPNG());

                Object.DestroyImmediate(tex);
                Object.DestroyImmediate(go);
                Object.DestroyImmediate(mat);
                n++;
            }

            cam.targetTexture = null;
            RenderTexture.active = null;
            Object.DestroyImmediate(rt);
            Object.DestroyImmediate(camGo);
            Object.DestroyImmediate(lightGo);
            RenderSettings.ambientMode = prevMode;
            RenderSettings.ambientLight = prevAmbient;

            AssetDatabase.Refresh();
            Debug.Log($"[Uml3DIconBaker] baked {n} node meshes to {OutDir}");
        }

        private static Color HexToColor(string hex)
        {
            return ColorUtility.TryParseHtmlString(hex, out var c) ? c : Color.gray;
        }
    }
}
