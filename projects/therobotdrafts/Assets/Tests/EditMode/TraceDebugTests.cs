using System.Collections.Generic;
using NUnit.Framework;
using TheRobotDraft.Authoring.Debug;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Authoring.Tests
{
    /// <summary>
    /// EditMode tests for the trace / debug subsystem: breakpoint bookkeeping, call-site discovery, and the
    /// deterministic <see cref="TraceDebugSession"/> stepper that walks modeled code and honors breakpoints.
    /// All pure C# — no renderer / process required (the seam keeps a real debugger out of the unit tests).
    /// </summary>
    public class TraceDebugTests
    {
        private static ElementId Id(string s) => new ElementId(s);

        // --- BreakpointStore ---

        [Test]
        public void Toggle_Sets_Then_Clears_A_Breakpoint()
        {
            var store = new BreakpointStore();
            var c = Id("ClassA");
            Assert.IsTrue(store.Toggle(c, 5), "first toggle sets");
            Assert.IsTrue(store.IsBreakLine(c, 5));
            Assert.AreEqual(1, store.Count);
            Assert.IsFalse(store.Toggle(c, 5), "second toggle clears");
            Assert.IsFalse(store.IsBreakLine(c, 5));
            Assert.AreEqual(0, store.Count);
        }

        [Test]
        public void Disabled_Breakpoint_Is_Not_A_Break_Line()
        {
            var store = new BreakpointStore();
            var c = Id("ClassA");
            store.Set(new Breakpoint(c, 3, condition: null, enabled: false));
            Assert.IsTrue(store.HasLine(c, 3), "still present");
            Assert.IsFalse(store.IsBreakLine(c, 3), "but disabled → no stop");
        }

        [Test]
        public void RemoveAllFor_Drops_Only_That_Elements_Breakpoints()
        {
            var store = new BreakpointStore();
            var a = Id("A"); var b = Id("B");
            store.Toggle(a, 1); store.Toggle(a, 2); store.Toggle(b, 1);
            store.RemoveAllFor(a);
            Assert.AreEqual(1, store.Count);
            Assert.IsTrue(store.IsBreakLine(b, 1));
        }

        // --- CallSiteScanner ---

        [Test]
        public void Scan_Finds_Reference_To_Another_Element()
        {
            var names = new Dictionary<string, ElementId> { { "Class2", Id("Class2") } };
            string src = "void run() {\n    var s = Class2();\n}\n";
            var sites = CallSiteScanner.Scan(src, Id("Class1"), names);
            Assert.AreEqual(1, sites.Count);
            Assert.AreEqual(Id("Class2"), sites[0].Target);
            Assert.AreEqual(2, sites[0].Line, "reference is on line 2");
        }

        [Test]
        public void Scan_Ignores_Self_And_Comments_And_Strings()
        {
            var names = new Dictionary<string, ElementId>
            {
                { "Class1", Id("Class1") }, { "Class2", Id("Class2") },
            };
            // Class1 = self (skip); Class2 appears only in a comment and a string (both blanked).
            string src = "class Class1 {\n  // talks to Class2\n  log(\"Class2 ran\");\n}\n";
            var sites = CallSiteScanner.Scan(src, Id("Class1"), names);
            Assert.AreEqual(0, sites.Count);
        }

        // --- TraceDebugSession ---

        // A tiny hand-built code graph: two elements, with a call site from A's line 2 into B.
        private sealed class FakeGraph : ICodeGraph
        {
            public readonly Dictionary<ElementId, List<string>> Lines = new();
            public readonly Dictionary<(ElementId, int), List<CallSite>> Calls = new();

            public IReadOnlyList<string> LinesFor(ElementId element) =>
                Lines.TryGetValue(element, out var l) ? l : new List<string>();

            public IReadOnlyList<CallSite> CallSitesOn(ElementId element, int line) =>
                Calls.TryGetValue((element, line), out var c) ? c : new List<CallSite>();
        }

        private static (FakeGraph graph, ElementId a, ElementId b) TwoFrameGraph()
        {
            var a = Id("A"); var b = Id("B");
            var g = new FakeGraph();
            g.Lines[a] = new List<string> { "line a1", "call b", "line a3" };       // lines 1..3
            g.Lines[b] = new List<string> { "line b1", "line b2" };                  // lines 1..2
            g.Calls[(a, 2)] = new List<CallSite> { new CallSite(b, "B", 2, 0) };     // A:2 calls B
            return (g, a, b);
        }

        [Test]
        public void Launch_Stops_At_First_Line()
        {
            var (g, a, _) = TwoFrameGraph();
            var s = new TraceDebugSession(g, new BreakpointStore());
            s.Launch(a);
            Assert.IsTrue(s.IsRunning);
            Assert.AreEqual(a, s.Current.Value.Element);
            Assert.AreEqual(1, s.Current.Value.Line);
        }

        [Test]
        public void StepInto_Descends_Into_Callee()
        {
            var (g, a, b) = TwoFrameGraph();
            var s = new TraceDebugSession(g, new BreakpointStore());
            s.Launch(a);            // A:1
            s.StepOver();           // A:2 (the call line)
            Assert.AreEqual(a, s.Current.Value.Element);
            Assert.AreEqual(2, s.Current.Value.Line);
            s.StepInto();           // → B:1
            Assert.AreEqual(b, s.Current.Value.Element);
            Assert.AreEqual(1, s.Current.Value.Line);
            Assert.AreEqual(2, s.CallStack.Count, "B over A");
        }

        [Test]
        public void StepOver_Does_Not_Descend()
        {
            var (g, a, _) = TwoFrameGraph();
            var s = new TraceDebugSession(g, new BreakpointStore());
            s.Launch(a);            // A:1
            s.StepOver();           // A:2
            s.StepOver();           // A:3 (stepped OVER the call, stayed in A)
            Assert.AreEqual(a, s.Current.Value.Element);
            Assert.AreEqual(3, s.Current.Value.Line);
        }

        [Test]
        public void Run_Returns_To_Caller_After_Callee_Ends()
        {
            var (g, a, b) = TwoFrameGraph();
            var s = new TraceDebugSession(g, new BreakpointStore());
            s.Launch(a);            // A:1
            s.StepOver();           // A:2
            s.StepInto();           // B:1
            s.StepOver();           // B:2
            s.StepOver();           // B ends → back to A:3
            Assert.AreEqual(a, s.Current.Value.Element);
            Assert.AreEqual(3, s.Current.Value.Line);
            s.StepOver();           // A ends → program exits
            Assert.IsFalse(s.IsRunning);
            Assert.AreEqual(StopReason.Exited, s.Reason);
        }

        [Test]
        public void Continue_Stops_At_A_Breakpoint_In_The_Callee()
        {
            var (g, a, b) = TwoFrameGraph();
            var bps = new BreakpointStore();
            bps.Toggle(b, 2); // breakpoint on B's second line
            var s = new TraceDebugSession(g, bps);
            s.Launch(a);
            s.Continue();
            Assert.IsTrue(s.IsRunning);
            Assert.AreEqual(b, s.Current.Value.Element);
            Assert.AreEqual(2, s.Current.Value.Line);
            Assert.AreEqual(StopReason.Breakpoint, s.Reason);
        }

        [Test]
        public void Continue_With_No_Breakpoints_Runs_To_Exit()
        {
            var (g, a, _) = TwoFrameGraph();
            var s = new TraceDebugSession(g, new BreakpointStore());
            s.Launch(a);
            s.Continue();
            Assert.IsFalse(s.IsRunning);
            Assert.AreEqual(StopReason.Exited, s.Reason);
        }
    }
}
