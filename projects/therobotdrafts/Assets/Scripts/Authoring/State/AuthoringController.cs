using System;
using TheRobotDraft.Authoring.Commands;
using TheRobotDraft.Authoring.Model;
using TheRobotDraft.Authoring.Rules;
using TheRobotDraft.Authoring.Seams;

namespace TheRobotDraft.Authoring.State
{
    /// <summary>How a candidate target reads right now: the §5.1 affordance, the resolved parent/endpoint, and a reason.</summary>
    public readonly struct TargetEvaluation
    {
        public readonly AffordanceState Affordance;
        public readonly ElementId Resolved;
        public readonly string Reason; // populated for InvalidTarget (the §B hover reason)

        public TargetEvaluation(AffordanceState affordance, ElementId resolved, string reason)
        {
            Affordance = affordance;
            Resolved = resolved;
            Reason = reason;
        }

        public bool IsValid => Affordance == AffordanceState.ValidTarget;
    }

    /// <summary>
    /// The input-agnostic authoring state machine — the shared brain behind both the desktop toolbar and the
    /// VR radial (authoring-ux.md §1–§4 at full parity). Desktop (Input System) and VR (XRI) adapters call the
    /// same verbs here; this class owns mode, spring-loaded commit style, target validity, and routes every
    /// mutation through the <see cref="UndoStack"/>. It holds no engine/render references — only the
    /// <see cref="IPacker"/> and <see cref="IBubblePicker"/> seams — so it unit-tests as plain C#.
    ///
    /// Invariants enforced here:
    ///   • Never stranded (§1): <see cref="Cancel"/> always returns to <see cref="AuthoringMode.Select"/>.
    ///   • Placement = pick the parent (§0.1): add/connect only ever resolve an element, never a coordinate.
    ///   • Validity felt before commit (§3.1/§4.4): commits are refused on an invalid target.
    ///   • Spring-loaded (§1): one-shot auto-returns to Select; sticky stays until cancel.
    /// </summary>
    public sealed class AuthoringController
    {
        private readonly AuthoringModel _model;
        private readonly UndoStack _history;

        public AuthoringController(AuthoringModel model, UndoStack history)
        {
            _model = model ?? throw new ArgumentNullException(nameof(model));
            _history = history ?? throw new ArgumentNullException(nameof(history));
        }

        // --- observable state (toolbar/radial re-light off these) ---

        public AuthoringMode Mode { get; private set; } = AuthoringMode.Select;
        public CommitStyle CommitStyle { get; private set; } = CommitStyle.OneShot;

        /// <summary>The kind the next add-node will create (creation palette selection, §3.1). Class is the default.</summary>
        public ElementKind PendingKind { get; private set; } = ElementKind.Class;
        public bool PendingAbstract { get; private set; }

        /// <summary>The pending edge type — sticky-type default (§4.2). Association is the draw-then-type default.</summary>
        public EdgeKind PendingEdgeKind { get; private set; } = EdgeKind.Association;

        /// <summary>The drill container the user is "inside"; empty-space targeting parents to it (§3.2 step 2).</summary>
        public ElementId CurrentContainer { get; set; } = ElementId.None;

        /// <summary>The source endpoint while a connect rubber-band is live, else None (§4.3).</summary>
        public ElementId ConnectSource { get; private set; } = ElementId.None;
        public bool ConnectDragActive => ConnectSource.IsValid;

        public bool CanUndo => _history.CanUndo;
        public bool CanRedo => _history.CanRedo;

        /// <summary>Raised when <see cref="Mode"/> changes so the toolbar/radial can re-light (parity §2.2/§5.5).</summary>
        public event Action<AuthoringMode> ModeChanged;

        // --- mode entry (§1, §2) ---

        public void EnterSelect()
        {
            ConnectSource = ElementId.None;
            SetMode(AuthoringMode.Select);
        }

        public void EnterAddNode(ElementKind kind, CommitStyle style = CommitStyle.OneShot)
        {
            PendingKind = kind;
            CommitStyle = style;
            ConnectSource = ElementId.None;
            SetMode(AuthoringMode.AddNode);
        }

        public void EnterConnect(CommitStyle style = CommitStyle.OneShot, EdgeKind? type = null)
        {
            if (type.HasValue) PendingEdgeKind = type.Value;
            CommitStyle = style;
            ConnectSource = ElementId.None;
            SetMode(AuthoringMode.Connect);
        }

        public void SetPendingKind(ElementKind kind) => PendingKind = kind;
        public void SetPendingAbstract(bool value) => PendingAbstract = value;
        public void SetPendingEdgeKind(EdgeKind kind) => PendingEdgeKind = kind;

        /// <summary>
        /// Esc / B-button: cancel any in-progress verb and return to Select, the home state (§1 "never
        /// stranded"). Safe to call from any state.
        /// </summary>
        public void Cancel()
        {
            ConnectSource = ElementId.None;
            SetMode(AuthoringMode.Select);
        }

        /// <summary>Abandon the current rubber-band but stay in Connect mode (release on empty space, §4.3).</summary>
        public void CancelConnectDrag() => ConnectSource = ElementId.None;

        // --- add-node (§3) ---

        /// <summary>
        /// Evaluate a hovered/ray-hit candidate as an add-node parent. A miss (empty space) resolves to the
        /// current drill container (§3.2 step 2). Returns the §5.1 affordance + reason without mutating.
        /// </summary>
        public TargetEvaluation EvaluateAddTarget(ElementId candidate)
        {
            var parent = candidate.IsValid ? candidate : CurrentContainer;

            // Empty world with no drill container → bootstrap: the first node is a root (§3.4); always valid.
            if (!parent.IsValid)
                return new TargetEvaluation(AffordanceState.ValidTarget, ElementId.None, null);

            if (!_model.TryGet(parent, out var parentElement))
                return new TargetEvaluation(AffordanceState.InvalidTarget, parent, "target no longer exists");

            var v = ContainmentRules.CanContain(parentElement.Kind, PendingKind);
            return v.IsValid
                ? new TargetEvaluation(AffordanceState.ValidTarget, parent, null)
                : new TargetEvaluation(AffordanceState.InvalidTarget, parent, v.Reason);
        }

        /// <summary>
        /// Commit an add-node into the resolved parent. Refuses on an invalid target (the rule is felt, not a
        /// post-drop error). On success returns the new id; one-shot returns to Select, sticky stays.
        /// </summary>
        public ElementId CommitAddNode(ElementId candidate, string name)
        {
            if (Mode != AuthoringMode.AddNode) return ElementId.None;

            var eval = EvaluateAddTarget(candidate);
            if (!eval.IsValid) return ElementId.None;

            var cmd = _history.Execute(new AddNodeCommand(eval.Resolved, PendingKind, name, PendingAbstract));
            AfterCommit();
            return cmd.CreatedId;
        }

        // --- connect (§4) ---

        /// <summary>Begin a rubber-band from <paramref name="source"/> (Connect mode click, or quick-handle drag).</summary>
        public bool BeginConnect(ElementId source)
        {
            if (!_model.Contains(source)) return false;
            // Quick-handle path can start a connect without first entering the mode (§4.1).
            if (Mode != AuthoringMode.Connect) SetMode(AuthoringMode.Connect);
            ConnectSource = source;
            return true;
        }

        /// <summary>Evaluate the bubble under the ray as a connect target during the drag (validity felt live, §4.4).</summary>
        public TargetEvaluation EvaluateConnectTarget(ElementId candidate, EdgeKind? typeOverride = null)
        {
            if (!ConnectDragActive)
                return new TargetEvaluation(AffordanceState.None, ElementId.None, null);
            if (!candidate.IsValid)
                return new TargetEvaluation(AffordanceState.InProgress, ElementId.None, null); // over empty space

            var kind = typeOverride ?? PendingEdgeKind;
            var v = EdgeRules.CanConnect(_model, kind, ConnectSource, candidate);
            return v.IsValid
                ? new TargetEvaluation(AffordanceState.ValidTarget, candidate, null)
                : new TargetEvaluation(AffordanceState.InvalidTarget, candidate, v.Reason);
        }

        /// <summary>
        /// Release on a target. Draw-then-type: the type defaults to <see cref="PendingEdgeKind"/> (sticky) and
        /// can be overridden by the picker. Refuses on an invalid target; releasing on empty cancels the drag.
        /// One-shot returns to Select; sticky stays and keeps the chosen type as the new pending default (§4.2).
        /// </summary>
        public EdgeId CommitConnect(ElementId target, EdgeKind? typeOverride = null)
        {
            if (Mode != AuthoringMode.Connect || !ConnectDragActive) return EdgeId.None;

            if (!target.IsValid) { CancelConnectDrag(); return EdgeId.None; } // release on empty (§4.3)

            var kind = typeOverride ?? PendingEdgeKind;
            var v = EdgeRules.CanConnect(_model, kind, ConnectSource, target);
            if (!v.IsValid) return EdgeId.None;

            var cmd = _history.Execute(new ConnectCommand(ConnectSource, target, kind));
            PendingEdgeKind = kind; // sticky-type: a run of same-type edges needs no per-edge picker
            ConnectSource = ElementId.None;
            AfterCommit();
            return cmd.CreatedId;
        }

        // --- instantaneous verbs (§1: never modes) ---

        public bool Delete(ElementId element)
        {
            if (!_model.Contains(element)) return false;
            _history.Execute(new DeleteElementCommand(element));
            return true;
        }

        public bool Rename(ElementId element, string name)
        {
            if (!_model.Contains(element)) return false;
            _history.Execute(new RenameCommand(element, name));
            return true;
        }

        public bool Reparent(ElementId element, ElementId newParent)
        {
            if (!_model.TryGet(element, out _) || !_model.TryGet(newParent, out var parent)) return false;
            // Cannot drop a node into itself or its own descendant (would orphan the subtree).
            if (element == newParent || _model.IsAncestorOf(element, newParent)) return false;
            if (!ContainmentRules.CanContain(parent.Kind, _model.Get(element).Kind).IsValid) return false;
            _history.Execute(new ReParentCommand(element, newParent));
            return true;
        }

        /// <summary>Toggle a classifier's <c>abstract</c> modifier (§3.1) as one undo step.</summary>
        public bool SetAbstract(ElementId element, bool value)
        {
            if (!_model.Contains(element)) return false;
            _history.Execute(new SetAbstractCommand(element, value));
            return true;
        }

        /// <summary>Set classifier metadata — implementation language and a custom stereotype override (Rose/Sparx).</summary>
        public bool SetMeta(ElementId element, string language, string stereotype)
        {
            if (!_model.Contains(element)) return false;
            _history.Execute(new SetMetaCommand(element, language, stereotype));
            return true;
        }

        /// <summary>Set an element's free-text description / documentation (fed to code generation), one undo step.</summary>
        public bool SetDescription(ElementId element, string description)
        {
            if (!_model.Contains(element)) return false;
            _history.Execute(new SetDescriptionCommand(element, description));
            return true;
        }

        /// <summary>Save an element's source code (the approved "Generate code" output), one undo step.</summary>
        public bool SetCode(ElementId element, string code)
        {
            if (!_model.Contains(element)) return false;
            _history.Execute(new SetCodeCommand(element, code));
            return true;
        }

        /// <summary>Set an element's originating source-file path (folder import / overlay round-trip), one undo step.</summary>
        public bool SetSourceFile(ElementId element, string sourceFile)
        {
            if (!_model.Contains(element)) return false;
            _history.Execute(new SetSourceFileCommand(element, sourceFile));
            return true;
        }

        /// <summary>Set an element's diagram z-layer (0 = base), one undo step.</summary>
        public bool SetZLayer(ElementId element, int z)
        {
            if (!_model.Contains(element)) return false;
            _history.Execute(new SetZLayerCommand(element, z));
            return true;
        }

        /// <summary>Change a relationship's type in place (§4.6), validity-checked against its current endpoints.</summary>
        public bool ReTypeEdge(EdgeId edge, EdgeKind kind)
        {
            if (!_model.TryGet(edge, out var e)) return false;
            if (!EdgeRules.CanConnect(_model, kind, e.From, e.To).IsValid) return false;
            _history.Execute(new ReTypeEdgeCommand(edge, kind));
            return true;
        }

        /// <summary>Set a relationship's midpoint label, per-end multiplicities, and constraint (§4.6), one undo step.</summary>
        public bool SetEdgeMeta(EdgeId edge, string label, string source, string target, string constraint = null)
        {
            if (!_model.TryGet(edge, out _)) return false;
            _history.Execute(new SetEdgeMetaCommand(edge, label, source, target, constraint));
            return true;
        }

        /// <summary>Flip a relationship's direction (swap from/to ends), one undo step.</summary>
        public bool ReverseEdge(EdgeId edge)
        {
            if (!_model.TryGet(edge, out _)) return false;
            _history.Execute(new ReverseEdgeCommand(edge));
            return true;
        }

        /// <summary>Delete a relationship edge (§4.6), one undo step.</summary>
        public bool DeleteEdge(EdgeId edge)
        {
            if (!_model.TryGet(edge, out _)) return false;
            _history.Execute(new DeleteEdgeCommand(edge));
            return true;
        }

        public bool Undo() => _history.Undo();
        public bool Redo() => _history.Redo();

        /// <summary>Drop all undo/redo history (e.g. after loading a document) without disturbing the id factory.</summary>
        public void ClearHistory() => _history.Clear();

        // --- internals ---

        private void AfterCommit()
        {
            if (CommitStyle == CommitStyle.OneShot)
                EnterSelect();
        }

        private void SetMode(AuthoringMode mode)
        {
            if (Mode == mode) return;
            Mode = mode;
            ModeChanged?.Invoke(mode);
        }
    }
}
