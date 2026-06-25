using System.Collections.Generic;

namespace TheRobotDraft.Authoring.Commands
{
    /// <summary>
    /// The authoring history. Executing a command runs it and pushes it onto the undo stack, clearing the redo
    /// stack (standard linear history). <c>Undo</c>/<c>Redo</c> are the instantaneous §1 verbs — never modes.
    /// Toolbar Undo/Redo dim from <see cref="CanUndo"/>/<see cref="CanRedo"/> (authoring-ux.md §2.2).
    /// </summary>
    public sealed class UndoStack
    {
        private readonly CommandContext _ctx;
        private readonly Stack<IAuthoringCommand> _undo = new();
        private readonly Stack<IAuthoringCommand> _redo = new();

        public UndoStack(CommandContext ctx) => _ctx = ctx;

        public bool CanUndo => _undo.Count > 0;
        public bool CanRedo => _redo.Count > 0;
        public int Depth => _undo.Count;

        /// <summary>The label of the command Undo would reverse (for the tooltip), or null.</summary>
        public string PendingUndoLabel => _undo.Count > 0 ? _undo.Peek().Label : null;
        public string PendingRedoLabel => _redo.Count > 0 ? _redo.Peek().Label : null;

        /// <summary>Run a command and record it. Returns the same instance so callers can read its result (e.g. CreatedId).</summary>
        public T Execute<T>(T command) where T : IAuthoringCommand
        {
            command.Do(_ctx);
            _undo.Push(command);
            _redo.Clear();
            return command;
        }

        public bool Undo()
        {
            if (_undo.Count == 0) return false;
            var cmd = _undo.Pop();
            cmd.Undo(_ctx);
            _redo.Push(cmd);
            return true;
        }

        public bool Redo()
        {
            if (_redo.Count == 0) return false;
            var cmd = _redo.Pop();
            cmd.Do(_ctx);
            _undo.Push(cmd);
            return true;
        }

        public void Clear()
        {
            _undo.Clear();
            _redo.Clear();
        }
    }
}
