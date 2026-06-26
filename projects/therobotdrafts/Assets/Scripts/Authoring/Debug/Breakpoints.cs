using System.Collections.Generic;
using TheRobotDraft.Authoring.Model;

namespace TheRobotDraft.Authoring.Debug
{
    /// <summary>
    /// One breakpoint placed on a UML element at a 1-based source line. Breakpoints are authoring data (they ride
    /// with the diagram and persist), distinct from any live debug session: a <see cref="IDebugSession"/> reads them
    /// to decide where to stop. <see cref="Condition"/> is an optional break-when expression (free text for now —
    /// a real adapter passes it through to the underlying debugger); <see cref="Enabled"/> lets a breakpoint be
    /// kept but skipped without losing its condition.
    /// </summary>
    public readonly struct Breakpoint
    {
        public readonly ElementId Element;
        public readonly int Line;        // 1-based, in the element's own code listing (see ModelElement.Code)
        public readonly string Condition; // null/empty = unconditional
        public readonly bool Enabled;

        public Breakpoint(ElementId element, int line, string condition = null, bool enabled = true)
        {
            Element = element;
            Line = line;
            Condition = string.IsNullOrWhiteSpace(condition) ? null : condition.Trim();
            Enabled = enabled;
        }

        public Breakpoint With(string condition = null, bool? enabled = null) =>
            new Breakpoint(Element, Line,
                condition ?? Condition,
                enabled ?? Enabled);
    }

    /// <summary>
    /// The set of breakpoints across the whole diagram, keyed by (element, line) so a line carries at most one.
    /// Pure logic (no engine refs) so it unit-tests as plain C# and lives in the authoring assembly alongside the
    /// model. The trace/debug view mutates it through <see cref="Toggle"/> / <see cref="Set"/> / <see cref="Remove"/>;
    /// a debug session queries it through <see cref="ForElement"/> / <see cref="IsBreakLine"/>.
    /// </summary>
    public sealed class BreakpointStore
    {
        // (element, line) → breakpoint. A dictionary keeps toggling O(1) and guarantees one bp per line.
        private readonly Dictionary<(ElementId, int), Breakpoint> _bps = new();

        public IReadOnlyCollection<Breakpoint> All => _bps.Values;
        public int Count => _bps.Count;

        /// <summary>Add (or clear) the breakpoint on <paramref name="element"/> at <paramref name="line"/>; returns the new state (true = a breakpoint is now set).</summary>
        public bool Toggle(ElementId element, int line)
        {
            if (line < 1 || !element.IsValid) return false;
            var key = (element, line);
            if (_bps.Remove(key)) return false;
            _bps[key] = new Breakpoint(element, line);
            return true;
        }

        /// <summary>Set/replace a breakpoint (carries a condition / enabled flag). Use to restore from persistence or edit a condition.</summary>
        public void Set(Breakpoint bp)
        {
            if (bp.Line < 1 || !bp.Element.IsValid) return;
            _bps[(bp.Element, bp.Line)] = bp;
        }

        public void Remove(ElementId element, int line) => _bps.Remove((element, line));

        /// <summary>Drop every breakpoint on an element (called when the element is deleted or its code is replaced wholesale).</summary>
        public void RemoveAllFor(ElementId element)
        {
            var doomed = new List<(ElementId, int)>();
            foreach (var key in _bps.Keys)
                if (key.Item1 == element) doomed.Add(key);
            foreach (var key in doomed) _bps.Remove(key);
        }

        public void Clear() => _bps.Clear();

        public bool TryGet(ElementId element, int line, out Breakpoint bp) =>
            _bps.TryGetValue((element, line), out bp);

        /// <summary>True when an enabled breakpoint sits on this line (what a debug session checks before stopping).</summary>
        public bool IsBreakLine(ElementId element, int line) =>
            _bps.TryGetValue((element, line), out var bp) && bp.Enabled;

        public bool HasLine(ElementId element, int line) => _bps.ContainsKey((element, line));

        /// <summary>Every breakpoint on one element, ascending by line (for drawing the gutter).</summary>
        public List<Breakpoint> ForElement(ElementId element)
        {
            var list = new List<Breakpoint>();
            foreach (var bp in _bps.Values)
                if (bp.Element == element) list.Add(bp);
            list.Sort((a, b) => a.Line.CompareTo(b.Line));
            return list;
        }
    }
}
