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
            cam.orthographicSize = 1.12f;
            cam.nearClipPlane = 0.01f;
            cam.farClipPlane = 60f;
            // Elevated 3/4 so each node sits on the ground plane and casts a soft contact shadow.
            camGo.transform.position = new Vector3(1.05f, 1.35f, 3.6f);
            camGo.transform.LookAt(new Vector3(0f, -0.14f, 0f));

            var prevShadows = QualitySettings.shadows;
            var prevShadowDist = QualitySettings.shadowDistance;
            QualitySettings.shadows = ShadowQuality.All;
            QualitySettings.shadowDistance = 40f;

            // Three-point rig matching Uml3DScene: warm key (soft shadows), cool fill, back/rim.
            var keyGo = new GameObject("BakeKey");
            var key = keyGo.AddComponent<Light>();
            key.type = LightType.Directional; key.intensity = 1.1f;
            key.color = new Color(1f, 0.97f, 0.92f);
            key.shadows = LightShadows.Soft; key.shadowStrength = 0.55f;
            key.shadowBias = 0.04f; key.shadowNormalBias = 0.4f;
            keyGo.transform.rotation = Quaternion.Euler(52f, 42f, 0f);

            var fillGo = new GameObject("BakeFill");
            var fill = fillGo.AddComponent<Light>();
            fill.type = LightType.Directional; fill.intensity = 0.45f;
            fill.color = new Color(0.80f, 0.86f, 1f); fill.shadows = LightShadows.None;
            fillGo.transform.rotation = Quaternion.Euler(16f, -60f, 0f);

            var rimGo = new GameObject("BakeRim");
            var rim = rimGo.AddComponent<Light>();
            rim.type = LightType.Directional; rim.intensity = 0.55f;
            rim.color = new Color(0.85f, 0.90f, 1f); rim.shadows = LightShadows.None;
            rimGo.transform.rotation = Quaternion.Euler(-42f, 205f, 0f);

            var prevMode = RenderSettings.ambientMode;
            var prevSky = RenderSettings.ambientSkyColor;
            var prevEq = RenderSettings.ambientEquatorColor;
            var prevGnd = RenderSettings.ambientGroundColor;
            RenderSettings.ambientMode = UnityEngine.Rendering.AmbientMode.Trilight;
            RenderSettings.ambientSkyColor = new Color(0.34f, 0.36f, 0.40f);
            RenderSettings.ambientEquatorColor = new Color(0.24f, 0.25f, 0.28f);
            RenderSettings.ambientGroundColor = new Color(0.12f, 0.13f, 0.15f);

            var rt = new RenderTexture(Size, Size, 24, RenderTextureFormat.ARGB32, RenderTextureReadWrite.sRGB)
            { antiAliasing = 8 };
            cam.targetTexture = rt;

            Shader lit = Shader.Find("Standard");
            if (lit == null) lit = Shader.Find("Universal Render Pipeline/Lit");
            if (lit == null) lit = Shader.Find("Diffuse");

            // Ground plane (thin box) just under the nodes' base to catch the key light's contact shadow.
            var groundMat = new Material(lit) { color = new Color(0.16f, 0.17f, 0.20f) };
            if (groundMat.HasProperty("_Glossiness")) groundMat.SetFloat("_Glossiness", 0.04f);
            if (groundMat.HasProperty("_Smoothness")) groundMat.SetFloat("_Smoothness", 0.04f);
            if (groundMat.HasProperty("_Metallic")) groundMat.SetFloat("_Metallic", 0f);
            var groundGo = GameObject.CreatePrimitive(PrimitiveType.Cube);
            groundGo.transform.position = new Vector3(0f, -0.445f, 0f);
            groundGo.transform.localScale = new Vector3(9f, 0.04f, 9f);
            groundGo.GetComponent<MeshRenderer>().sharedMaterial = groundMat;
            Object.DestroyImmediate(groundGo.GetComponent<Collider>());

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
                if (mat.HasProperty("_Metallic")) mat.SetFloat("_Metallic", 0f);
                if (mat.HasProperty("_Glossiness")) mat.SetFloat("_Glossiness", 0.22f);
                if (mat.HasProperty("_Smoothness")) mat.SetFloat("_Smoothness", 0.22f);

                var go = new GameObject(kind.ToString());
                go.AddComponent<MeshFilter>().sharedMesh = mesh;
                go.AddComponent<MeshRenderer>().sharedMaterial = mat;
                go.transform.rotation = Quaternion.identity; // the elevated camera provides the 3/4 angle

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
            Object.DestroyImmediate(keyGo);
            Object.DestroyImmediate(fillGo);
            Object.DestroyImmediate(rimGo);
            Object.DestroyImmediate(groundGo);
            Object.DestroyImmediate(groundMat);
            RenderSettings.ambientMode = prevMode;
            RenderSettings.ambientSkyColor = prevSky;
            RenderSettings.ambientEquatorColor = prevEq;
            RenderSettings.ambientGroundColor = prevGnd;
            QualitySettings.shadows = prevShadows;
            QualitySettings.shadowDistance = prevShadowDist;

            AssetDatabase.Refresh();
            Debug.Log($"[Uml3DIconBaker] baked {n} node meshes to {OutDir}");
        }

        private static Color HexToColor(string hex)
        {
            return ColorUtility.TryParseHtmlString(hex, out var c) ? c : Color.gray;
        }
    }
}
