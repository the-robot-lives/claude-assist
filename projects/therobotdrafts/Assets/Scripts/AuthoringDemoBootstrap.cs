using UnityEngine;
using UnityEngine.EventSystems;

namespace TheRobotDraft
{
    /// <summary>
    /// Runtime entry point for the on-screen authoring harness. Stands up a camera + EventSystem and a single
    /// <see cref="UmlCanvas"/> that builds the interactive 2D UML editor and drives the real
    /// <c>AuthoringController</c> (Assets/Scripts/Authoring). It is a desktop stand-in for the (gated) DOTS
    /// bubble renderer — same command model, 2D boxes instead of 3D bubbles — so the authoring core is visible
    /// and usable today. The production surface is the UI Toolkit toolbar + VR radial (authoring-ux.md §2).
    /// </summary>
    public static class AuthoringDemoBootstrap
    {
        /// <summary>When true, <see cref="ComingSoonBootstrap"/> stands down so this harness owns the screen.
        /// Flip to <c>false</c> to restore the plain "Coming Soon" splash. (static readonly, not const, so the
        /// guard in <see cref="ComingSoonBootstrap"/> doesn't trip an unreachable-code warning.)</summary>
        public static readonly bool Active = true;

        private static readonly Color Background = new Color(0.07f, 0.08f, 0.10f, 1f);

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void Boot()
        {
            if (!Active) return;

            EnsureCamera();
            EnsureEventSystem();
            RemoveComingSoon();

            var go = new GameObject("UmlAuthoringCanvas");
            Object.DontDestroyOnLoad(go);
            go.AddComponent<UmlCanvas>(); // builds its own Canvas + UI in Awake
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

        private static void EnsureEventSystem()
        {
            if (Object.FindFirstObjectByType<EventSystem>() != null) return;
            var es = new GameObject("EventSystem");
            es.AddComponent<EventSystem>();
            es.AddComponent<StandaloneInputModule>();
            Object.DontDestroyOnLoad(es);
        }

        private static void RemoveComingSoon()
        {
            var existing = GameObject.Find("ComingSoonCanvas");
            if (existing != null) Object.Destroy(existing);
        }
    }
}
