using System.Collections.Generic;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Authoring.Debug
{
    /// <summary>
    /// One entry on the debug call stack: where execution currently sits. <see cref="Element"/> identifies the
    /// bubble whose code is running and <see cref="Line"/> the 1-based line within that bubble's listing. The
    /// trace view highlights this line and frames this bubble.
    /// </summary>
    public readonly struct StackFrame
    {
        public readonly ElementId Element;
        public readonly int Line;
        public StackFrame(ElementId element, int line) { Element = element; Line = line; }
    }

    /// <summary>Why a <see cref="IDebugSession"/> last stopped — drives the status line in the trace view.</summary>
    public enum StopReason { NotStarted, Step, Breakpoint, Entry, Exited }

    /// <summary>
    /// The debugger seam, mirroring <see cref="Seams.IPacker"/>: the authoring/view layer talks to "the debugger"
    /// through this surface and never to a concrete adapter. Today the only implementation is
    /// <see cref="TraceDebugSession"/>, a deterministic call-graph walk over the modeled code that honors a
    /// <see cref="BreakpointStore"/>. A real Debug Adapter Protocol / LSP client (launching netcoredbg, debugpy,
    /// … as an external process) can slot in behind this same interface later — the view does not change.
    /// </summary>
    public interface IDebugSession
    {
        /// <summary>Whether a run is in progress (started and not yet exited).</summary>
        bool IsRunning { get; }

        /// <summary>Why the session last paused.</summary>
        StopReason Reason { get; }

        /// <summary>The current top-of-stack location, or null when not running.</summary>
        StackFrame? Current { get; }

        /// <summary>The whole call stack, innermost (current) first. Empty when not running.</summary>
        IReadOnlyList<StackFrame> CallStack { get; }

        /// <summary>Begin a run at <paramref name="entry"/>'s first executable line. Stops at the entry (so the view can show it).</summary>
        void Launch(ElementId entry);

        /// <summary>Run until the next enabled breakpoint or until the program exits.</summary>
        void Continue();

        /// <summary>Advance one line in the current frame; over any call site on it (does not descend).</summary>
        void StepOver();

        /// <summary>If the current line has a call site, descend into the callee; otherwise behaves like <see cref="StepOver"/>.</summary>
        void StepInto();

        /// <summary>Run the current frame to its end and return to the caller's next line.</summary>
        void StepOut();

        /// <summary>End the run and clear the stack.</summary>
        void Stop();
    }

    /// <summary>
    /// Supplies the debugger with the per-element code and the call sites within it. The view implements this over
    /// the live model (element → <c>ModelElement.Code</c>, call sites via <see cref="CallSiteScanner"/>), keeping
    /// <see cref="TraceDebugSession"/> free of any model-walking and trivially testable with a hand-built graph.
    /// </summary>
    public interface ICodeGraph
    {
        /// <summary>The element's code listing split into lines (1-based externally; index 0 = line 1). Empty when none.</summary>
        IReadOnlyList<string> LinesFor(ElementId element);

        /// <summary>Call sites on a given 1-based line of an element, in column order (may be empty).</summary>
        IReadOnlyList<CallSite> CallSitesOn(ElementId element, int line);
    }
}
