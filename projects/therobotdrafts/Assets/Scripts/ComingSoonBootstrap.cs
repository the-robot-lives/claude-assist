using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace TheRobotDraft
{
    /// <summary>
    /// Temporary placeholder splash for The Robot Draft.
    ///
    /// Builds a dark overlay with a "Coming Soon" title and an Exit button at runtime, and forces
    /// the standalone player into a resizable window. It is intentionally dependency-free: no scene
    /// wiring, no asset references, no render-pipeline setup — it runs automatically on Play and in a
    /// built player via <see cref="RuntimeInitializeOnLoadMethod"/>, so the project renders correctly
    /// on the very first try.
    ///
    /// This is a stub. The production shell will be a URP + Render Graph project with a UI Toolkit
    /// front-end and the DOTS/OpenXR bubble-view renderer described in docs/specs/unity-6.3-baseline.md
    /// and ADR-001. Replace this class when that shell lands.
    /// </summary>
    public static class ComingSoonBootstrap
    {
        private static readonly Color Background = new Color(0.06f, 0.07f, 0.09f, 1f);
        private static readonly Color TitleColor = new Color(0.92f, 0.94f, 0.98f, 1f);
        private static readonly Color SubtitleColor = new Color(0.55f, 0.60f, 0.70f, 1f);

        private const int WindowWidth = 1280;
        private const int WindowHeight = 720;

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void Boot()
        {
            EnsureWindowed();
            EnsureCamera();
            BuildOverlay();
        }

        private static void EnsureWindowed()
        {
            // Run in a window rather than fullscreen. PlayerSettings already requests this at build
            // time; this is the runtime safeguard (and a no-op worth skipping in the editor).
            if (!Application.isEditor)
                Screen.SetResolution(WindowWidth, WindowHeight, FullScreenMode.Windowed);
        }

        private static void EnsureCamera()
        {
            var cam = Camera.main;
            if (cam == null)
            {
                var camGo = new GameObject("Main Camera") { tag = "MainCamera" };
                cam = camGo.AddComponent<Camera>();
                camGo.AddComponent<AudioListener>();
                Object.DontDestroyOnLoad(camGo);
            }

            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = Background;
        }

        private static void BuildOverlay()
        {
            EnsureEventSystem();

            var canvasGo = new GameObject("ComingSoonCanvas");
            Object.DontDestroyOnLoad(canvasGo);

            var canvas = canvasGo.AddComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            canvas.sortingOrder = 32760; // sit on top of anything else

            var scaler = canvasGo.AddComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1920f, 1080f);
            scaler.matchWidthOrHeight = 0.5f;

            canvasGo.AddComponent<GraphicRaycaster>();

            // LegacyRuntime.ttf is the built-in fallback font (the old "Arial.ttf"),
            // available without importing TextMeshPro essentials — ideal for a stub.
            var font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");

            CreateLabel(canvasGo.transform, "Title", "Coming Soon",
                font, 96, FontStyle.Bold, TitleColor, new Vector2(0f, 80f));

            CreateLabel(canvasGo.transform, "Subtitle", "The Robot Draft",
                font, 36, FontStyle.Normal, SubtitleColor, new Vector2(0f, -20f));

            CreateExitButton(canvasGo.transform, font, new Vector2(0f, -180f));
        }

        /// <summary>uGUI buttons need an EventSystem + input module to receive clicks.</summary>
        private static void EnsureEventSystem()
        {
            if (Object.FindFirstObjectByType<EventSystem>() != null)
                return;

            var es = new GameObject("EventSystem");
            es.AddComponent<EventSystem>();
            es.AddComponent<StandaloneInputModule>();
            Object.DontDestroyOnLoad(es);
        }

        private static void CreateExitButton(Transform parent, Font font, Vector2 anchoredPos)
        {
            var go = new GameObject("ExitButton");
            go.transform.SetParent(parent, false);

            var rect = go.AddComponent<RectTransform>();
            rect.anchorMin = new Vector2(0.5f, 0.5f);
            rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.pivot = new Vector2(0.5f, 0.5f);
            rect.sizeDelta = new Vector2(220f, 64f);
            rect.anchoredPosition = anchoredPos;

            var img = go.AddComponent<Image>();
            img.color = new Color(0.16f, 0.18f, 0.22f, 1f);

            var button = go.AddComponent<Button>();
            button.targetGraphic = img;
            var colors = button.colors;
            colors.normalColor = new Color(0.16f, 0.18f, 0.22f, 1f);
            colors.highlightedColor = new Color(0.24f, 0.27f, 0.33f, 1f);
            colors.pressedColor = new Color(0.11f, 0.12f, 0.15f, 1f);
            colors.selectedColor = colors.highlightedColor;
            button.colors = colors;
            button.onClick.AddListener(Quit);

            var labelGo = new GameObject("Text");
            labelGo.transform.SetParent(go.transform, false);
            var lrect = labelGo.AddComponent<RectTransform>();
            lrect.anchorMin = Vector2.zero;
            lrect.anchorMax = Vector2.one;
            lrect.offsetMin = Vector2.zero;
            lrect.offsetMax = Vector2.zero;

            var label = labelGo.AddComponent<Text>();
            label.font = font;
            label.text = "Exit";
            label.fontSize = 28;
            label.alignment = TextAnchor.MiddleCenter;
            label.color = new Color(0.90f, 0.92f, 0.96f, 1f);
        }

        private static void Quit()
        {
#if UNITY_EDITOR
            UnityEditor.EditorApplication.isPlaying = false;
#else
            Application.Quit();
#endif
        }

        private static void CreateLabel(Transform parent, string name, string text,
            Font font, int size, FontStyle style, Color color, Vector2 anchoredPos)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false);

            var rect = go.AddComponent<RectTransform>();
            rect.anchorMin = new Vector2(0.5f, 0.5f);
            rect.anchorMax = new Vector2(0.5f, 0.5f);
            rect.pivot = new Vector2(0.5f, 0.5f);
            rect.sizeDelta = new Vector2(1600f, 240f);
            rect.anchoredPosition = anchoredPos;

            var label = go.AddComponent<Text>();
            label.font = font;
            label.text = text;
            label.fontSize = size;
            label.fontStyle = style;
            label.color = color;
            label.alignment = TextAnchor.MiddleCenter;
            label.horizontalOverflow = HorizontalWrapMode.Overflow;
            label.verticalOverflow = VerticalWrapMode.Overflow;
        }
    }
}
