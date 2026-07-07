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

        // Command ids (mirror NativeMenu.mm).
        public const int New = 1, Open = 2, Save = 3, SaveAs = 4, ExportCode = 5;
        public const int Undo = 10, Redo = 11, Copy = 12, Paste = 13, Delete = 14;
        public const int FrameAll = 20, CycleNav = 21, Toggle2D = 22;
    }
}
