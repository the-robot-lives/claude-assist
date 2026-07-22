using System;
using System.Collections.Concurrent;
using System.Runtime.InteropServices;
using UnityEngine;

namespace TheRobotDraft.Uml
{
    /// <summary>
    /// Bridges the native macOS menu bar (Assets/Plugins/macOS/RobotDraftMenu.bundle) to Unity. On a macOS
    /// standalone player it installs the File / Edit / View menus; a menu click arrives on the AppKit main
    /// thread, is queued here, and drained on the Unity main thread by <see cref="Drain"/> (called from
    /// <c>UmlCanvas.Update</c>), which forwards the command id to the registered handler
    /// (<c>UmlCanvas.RunMenuCommand</c>). No-op in the editor and on non-macOS players — the keyboard
    /// shortcuts in <c>UmlCanvas.Update</c> remain the fallback everywhere.
    ///
    /// Command ids mirror native/RobotDraftMenu/NativeMenu.mm — keep the two in sync.
    /// </summary>
    public static class NativeMacMenu
    {
        private delegate void CommandCallback(int cmd);

        private static readonly ConcurrentQueue<int> Queue = new ConcurrentQueue<int>();
        private static Action<int> _handler;
        private static bool _installed;
        private static CommandCallback _kept; // held so the delegate isn't GC'd while native holds the pointer

#if UNITY_STANDALONE_OSX && !UNITY_EDITOR
        [DllImport("RobotDraftMenu")]
        private static extern void RDInstallMenu(CommandCallback cb);
#endif

        /// <summary>Install the native menu once and register the handler that runs each command.</summary>
        public static void Install(Action<int> handler)
        {
            _handler = handler;
            if (_installed) return;
            _installed = true;
#if UNITY_STANDALONE_OSX && !UNITY_EDITOR
            try
            {
                _kept = OnNativeCommand;
                RDInstallMenu(_kept);
            }
            catch (Exception e)
            {
                Debug.LogWarning("[NativeMacMenu] native install failed: " + e.Message);
            }
#endif
        }

#if ENABLE_IL2CPP
        [AOT.MonoPInvokeCallback(typeof(CommandCallback))]
#endif
        private static void OnNativeCommand(int cmd) => Queue.Enqueue(cmd);

        /// <summary>Run any queued menu commands on the Unity main thread. Call once per frame.</summary>
        public static void Drain()
        {
            if (_handler == null) return;
            while (Queue.TryDequeue(out int cmd))
            {
                try { _handler(cmd); }
                catch (Exception e) { Debug.LogWarning("[NativeMacMenu] command " + cmd + " failed: " + e.Message); }
            }
        }

        // Legacy command ids (still dispatched; no longer emitted by the native menu).
        public const int New = 1, Open = 2, Save = 3, SaveAs = 4, ExportCode = 5;
        public const int Undo = 10, Redo = 11, Copy = 12, Paste = 13, Delete = 14;
        public const int FrameAll = 20, CycleNav = 21, Toggle2D = 22;

        // Nav-redesign IA v2 command ids (mirror NativeMenu.mm; grouped by menu).
        // File 1xx
        public const int FileNew = 100, FileOpen = 101, FileSave = 102, FileSaveAs = 103;
        public const int ImportPuml = 110, ImportXmiCmd = 111, ImportMermaidCmd = 112, ImportQeaCmd = 113;
        public const int ImportCode = 114, ImportImage = 115, ImportDb = 116;
        public const int ExportPuml = 120, ExportXmiCmd = 121, ExportMermaidCmd = 122, ExportQeaCmd = 123;
        public const int ExportPng = 124, Export3DObj = 125, Export3DJson = 126;
        // Edit 2xx
        public const int EditUndo = 200, EditRedo = 201, EditCopy = 202, EditPaste = 203, EditDelete = 204;
        // Model 3xx
        public const int AddClass = 300, AddInterface = 301, AddEnum = 302, AddPackage = 303, AddNote = 304;
        public const int ModeConnect = 310, ModePlace = 311, ModeSelect = 312;
        // Diagram 4xx
        public const int DiagramNew = 400, DiagramDelete = 401;
        public const int LayoutGrid = 410, LayoutForce = 411, LayoutSource = 412, LayoutHierarchy = 413;
        public const int LayoutAi = 414, LayoutSequence = 415;
        // Code 5xx
        public const int CodeWizard = 500, CodeImport = 501, CodeLiquibase = 502, CodeDbConnect = 503;
        // Go 6xx
        public const int GoFrameAll = 600, GoZUp = 601, GoZDown = 602, GoCycleNav = 603, GoTrace = 604;
        // View 7xx
        public const int ViewToggle2D = 700, ViewHelp = 701, ViewLlmSettings = 702, ViewVisionSettings = 703;
        // Window / Help 8xx
        public const int WindowFullScreen = 800, HelpSample = 801;
    }
}
