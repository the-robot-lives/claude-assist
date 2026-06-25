using System.IO;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEngine;

namespace TheRobotDraft.EditorTools
{
    /// <summary>
    /// Builds the macOS standalone (.app) for The Robot Draft.
    ///
    /// Run it either way:
    ///   • Editor menu:  The Robot Draft ▸ Build ▸ macOS
    ///   • Headless / CI: Unity -batchmode -nographics -quit -projectPath . \
    ///                          -executeMethod TheRobotDraft.EditorTools.BuildMac.Build
    ///     (the repo-root <c>build-mac.sh</c> wrapper does exactly this and auto-picks an
    ///      editor that has Mac Build Support)
    ///
    /// Requires the "Mac Build Support" module for the editor doing the build (the Mac editor
    /// does NOT always include it — add it in Unity Hub: Installs ▸ ⋮ ▸ Add modules). Without it
    /// the build fails fast with a clear error and exits non-zero. Architecture is left at the
    /// editor default (Apple silicon on an arm64 editor) to keep this script module-agnostic at
    /// compile time; set a universal/Intel target in Build Profiles if you need it.
    /// </summary>
    public static class BuildMac
    {
        private const string OutputDir = "Builds/macOS";
        private const string AppName = "The Robot Draft.app";

        [MenuItem("The Robot Draft/Build/macOS")]
        public static void Build()
        {
            // Set identity here rather than hand-editing ProjectSettings.asset.
            PlayerSettings.companyName = "Noizu Labs";
            PlayerSettings.productName = "The Robot Draft";

            // Run in a resizable window (not fullscreen). The runtime bootstrap also enforces this.
            PlayerSettings.fullScreenMode = FullScreenMode.Windowed;
            PlayerSettings.defaultIsNativeResolution = false;
            PlayerSettings.defaultScreenWidth = 1280;
            PlayerSettings.defaultScreenHeight = 720;
            PlayerSettings.resizableWindow = true;

            var options = new BuildPlayerOptions
            {
                scenes = new[] { "Assets/Scenes/Boot.unity" },
                locationPathName = Path.Combine(OutputDir, AppName),
                target = BuildTarget.StandaloneOSX,
                targetGroup = BuildTargetGroup.Standalone,
                options = BuildOptions.None,
            };

            Directory.CreateDirectory(OutputDir);

            BuildReport report = BuildPipeline.BuildPlayer(options);
            BuildSummary summary = report.summary;

            if (summary.result == BuildResult.Succeeded)
            {
                Debug.Log($"[BuildMac] Succeeded — {summary.totalSize} bytes -> {options.locationPathName}");
                if (Application.isBatchMode) EditorApplication.Exit(0);
            }
            else
            {
                Debug.LogError($"[BuildMac] FAILED — result={summary.result}, errors={summary.totalErrors}. " +
                               "If this says the Mac module is missing, add 'Mac Build Support' in Unity Hub.");
                if (Application.isBatchMode) EditorApplication.Exit(1);
            }
        }
    }
}
