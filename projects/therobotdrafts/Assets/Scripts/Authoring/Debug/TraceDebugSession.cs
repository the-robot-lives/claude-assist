using System.Collections.Generic;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Authoring.Debug
{
    /// <summary>
    /// A deterministic, network-free <see cref="IDebugSession"/>: it "executes" the modeled code by walking it line
    /// by line through an <see cref="ICodeGraph"/>, descending into a callee when a step crosses a call site, and
    /// stopping wherever an enabled breakpoint sits. No process is launched and nothing is evaluated — it is a guided
    /// trace, the offline counterpart to a real debugger (exactly as the deterministic <c>CodeSkeleton</c> is the
    /// offline counterpart to LLM codegen). A Debug Adapter Protocol / LSP client implements the same
    /// <see cref="IDebugSession"/> later and the trace view is unchanged.
    ///
    /// Execution model (kept deliberately simple): a frame is (element, line). A line is "executable" when it is not
    /// blank. <see cref="StepInto"/> on a line that has a call site pushes a frame for the first callee's first
    /// executable line; <see cref="StepOver"/> ignores call sites and moves to the next executable line; running off
    /// the end of a frame pops back to the caller's next line. <see cref="Continue"/> repeats single steps (entering
    /// calls) until it lands on a breakpoint or the stack empties.
    /// </summary>
    public sealed class TraceDebugSession : IDebugSession
    {
        private readonly ICodeGraph _graph;
        private readonly BreakpointStore _breakpoints;
        private readonly List<StackFrame> _stack = new();
        // Guard against runaway Continue() over recursive/cyclic models — bounds total simulated steps per call.
        private const int MaxStepsPerContinue = 100_000;

        public TraceDebugSession(ICodeGraph graph, BreakpointStore breakpoints)
        {
            _graph = graph;
            _breakpoints = breakpoints ?? new BreakpointStore();
        }

        public bool IsRunning { get; private set; }
        public StopReason Reason { get; private set; } = StopReason.NotStarted;
        public StackFrame? Current => _stack.Count > 0 ? _stack[_stack.Count - 1] : (StackFrame?)null;
        public IReadOnlyList<StackFrame> CallStack
        {
            get { var s = new List<StackFrame>(_stack); s.Reverse(); return s; } // innermost first
        }

        public void Launch(ElementId entry)
        {
            _stack.Clear();
            int first = FirstExecutableLine(entry, 1);
            if (first <= 0) { IsRunning = false; Reason = StopReason.Exited; return; }
            _stack.Add(new StackFrame(entry, first));
            IsRunning = true;
            Reason = StopReason.Entry;
        }

        public void Continue()
        {
            if (!IsRunning) return;
            for (int guard = 0; guard < MaxStepsPerContinue; guard++)
            {
                if (!SingleStep(stepInto: true)) { return; } // exited (Reason set by SingleStep)
                var cur = Current.Value;
                if (_breakpoints.IsBreakLine(cur.Element, cur.Line)) { Reason = StopReason.Breakpoint; return; }
            }
            Reason = StopReason.Step; // hit the guard — stop gracefully rather than spin
        }

        public void StepOver()
        {
            if (!IsRunning) return;
            if (SingleStep(stepInto: false)) Reason = StopReason.Step;
        }

        public void StepInto()
        {
            if (!IsRunning) return;
            if (SingleStep(stepInto: true)) Reason = StopReason.Step;
        }

        public void StepOut()
        {
            if (!IsRunning) return;
            if (_stack.Count <= 1) { ExitRun(); return; }
            _stack.RemoveAt(_stack.Count - 1);
            AdvanceCurrentToNextExecutable();
            Reason = IsRunning ? StopReason.Step : Reason;
        }

        public void Stop()
        {
            _stack.Clear();
            IsRunning = false;
            Reason = StopReason.Exited;
        }

        // --- core stepper ---

        /// <summary>
        /// Advance execution by one line. When <paramref name="stepInto"/> and the current line has a call site,
        /// descend into the first callee; otherwise move to the next executable line in the current frame, popping
        /// to the caller when the frame ends. Returns false (and ends the run) when the stack empties.
        /// </summary>
        private bool SingleStep(bool stepInto)
        {
            if (_stack.Count == 0) { ExitRun(); return false; }
            var frame = _stack[_stack.Count - 1];

            if (stepInto)
            {
                var calls = _graph.CallSitesOn(frame.Element, frame.Line);
                if (calls != null && calls.Count > 0)
                {
                    var callee = calls[0].Target;
                    // Avoid infinite descent into a frame already on the stack (direct/indirect recursion in the model).
                    if (!OnStack(callee))
                    {
                        int first = FirstExecutableLine(callee, 1);
                        if (first > 0) { _stack.Add(new StackFrame(callee, first)); return true; }
                    }
                }
            }

            return AdvanceCurrentToNextExecutable();
        }

        /// <summary>Move the top frame to its next executable line; pop to the caller's next line when it runs out. False ⇒ exited.</summary>
        private bool AdvanceCurrentToNextExecutable()
        {
            while (_stack.Count > 0)
            {
                var frame = _stack[_stack.Count - 1];
                int next = FirstExecutableLine(frame.Element, frame.Line + 1);
                if (next > 0)
                {
                    _stack[_stack.Count - 1] = new StackFrame(frame.Element, next);
                    return true;
                }
                _stack.RemoveAt(_stack.Count - 1); // frame ran off the end → return to caller, continue from its next line
            }
            ExitRun();
            return false;
        }

        private void ExitRun()
        {
            IsRunning = false;
            Reason = StopReason.Exited;
        }

        private bool OnStack(ElementId element)
        {
            foreach (var f in _stack) if (f.Element == element) return true;
            return false;
        }

        /// <summary>First executable (non-blank) line at or after <paramref name="from"/> (1-based), or 0 if none.</summary>
        private int FirstExecutableLine(ElementId element, int from)
        {
            var lines = _graph.LinesFor(element);
            if (lines == null) return 0;
            for (int ln = System.Math.Max(1, from); ln <= lines.Count; ln++)
                if (!string.IsNullOrWhiteSpace(lines[ln - 1])) return ln;
            return 0;
        }
    }
}
