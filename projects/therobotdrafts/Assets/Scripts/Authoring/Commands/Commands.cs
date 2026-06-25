using System;
using System.Collections.Generic;
using TheRobotDraft.Authoring.Model;
using TheRobotDraft.Authoring.Seams;

namespace TheRobotDraft.Authoring.Commands
{
    /// <summary>Mints stable ids for new elements/edges. Default uses GUIDs; the real pipeline uses qualified-name hashes.</summary>
    public interface IIdFactory
    {
        ElementId NewElementId(ElementId parent, ElementKind kind, string name);
        EdgeId NewEdgeId(ElementId from, ElementId to, EdgeKind kind);
    }

    /// <summary>Deterministic-enough default id source. Monotonic counter avoids collisions without a clock.</summary>
    public sealed class CountingIdFactory : IIdFactory
    {
        private int _n;
        public ElementId NewElementId(ElementId parent, ElementKind kind, string name)
            => new ElementId($"e{++_n}:{kind}");
        public EdgeId NewEdgeId(ElementId from, ElementId to, EdgeKind kind)
            => new EdgeId($"r{++_n}:{kind}");
    }

    /// <summary>What a command operates on: the model, the packer (position/re-pack), and the id source.</summary>
    public sealed class CommandContext
    {
        public AuthoringModel Model { get; }
        public IPacker Packer { get; }
        public IIdFactory Ids { get; }

        public CommandContext(AuthoringModel model, IPacker packer, IIdFactory ids)
        {
            Model = model;
            Packer = packer;
            Ids = ids;
        }
    }

    /// <summary>
    /// One reversible authoring mutation. Every authoring verb is exactly one of these so it is a single undo
    /// step (authoring-ux.md §0.2). <see cref="Do"/> must capture whatever <see cref="Undo"/> needs to restore
    /// the prior state precisely.
    /// </summary>
    public interface IAuthoringCommand
    {
        string Label { get; }
        void Do(CommandContext ctx);
        void Undo(CommandContext ctx);
    }

    /// <summary>Add a node as a child of <c>parent</c> (placement = pick the parent, §0.1/§3). Packer positions it.</summary>
    public sealed class AddNodeCommand : IAuthoringCommand
    {
        private readonly ElementId _parent;
        private readonly ElementKind _kind;
        private readonly string _name;
        private readonly bool _isAbstract;
        public ElementId CreatedId { get; private set; }

        public AddNodeCommand(ElementId parent, ElementKind kind, string name, bool isAbstract)
        {
            _parent = parent;
            _kind = kind;
            _name = name;
            _isAbstract = isAbstract;
        }

        public string Label => $"Add {_kind}";

        public void Do(CommandContext ctx)
        {
            if (!CreatedId.IsValid)
                CreatedId = ctx.Ids.NewElementId(_parent, _kind, _name);
            ctx.Model.AddElement(CreatedId, _kind, _name, _parent, _isAbstract);
            ctx.Packer.OnInserted(CreatedId, _parent);
        }

        public void Undo(CommandContext ctx)
        {
            ctx.Model.RemoveElement(CreatedId);
            ctx.Packer.OnRemoved(_parent);
        }
    }

    /// <summary>Connect two elements with a relationship (§4). Direction is from→to.</summary>
    public sealed class ConnectCommand : IAuthoringCommand
    {
        private readonly ElementId _from, _to;
        private readonly EdgeKind _kind;
        public EdgeId CreatedId { get; private set; }

        public ConnectCommand(ElementId from, ElementId to, EdgeKind kind)
        {
            _from = from;
            _to = to;
            _kind = kind;
        }

        public string Label => $"Connect ({_kind})";

        public void Do(CommandContext ctx)
        {
            if (!CreatedId.IsValid)
                CreatedId = ctx.Ids.NewEdgeId(_from, _to, _kind);
            ctx.Model.AddEdge(CreatedId, _kind, _from, _to);
        }

        public void Undo(CommandContext ctx) => ctx.Model.RemoveEdge(CreatedId);
    }

    /// <summary>Re-parent — the only "move" gesture (§3.6). Packer re-packs both old and new parent.</summary>
    public sealed class ReParentCommand : IAuthoringCommand
    {
        private readonly ElementId _element, _newParent;
        private ElementId _oldParent;

        public ReParentCommand(ElementId element, ElementId newParent)
        {
            _element = element;
            _newParent = newParent;
        }

        public string Label => "Re-parent";

        public void Do(CommandContext ctx)
        {
            _oldParent = ctx.Model.Get(_element).Parent;
            ctx.Model.Reparent(_element, _newParent);
            ctx.Packer.OnRemoved(_oldParent);
            ctx.Packer.OnInserted(_element, _newParent);
        }

        public void Undo(CommandContext ctx)
        {
            ctx.Model.Reparent(_element, _oldParent);
            ctx.Packer.OnRemoved(_newParent);
            ctx.Packer.OnInserted(_element, _oldParent);
        }
    }

    /// <summary>Change a relationship's type in place (§4.6 re-type).</summary>
    public sealed class ReTypeEdgeCommand : IAuthoringCommand
    {
        private readonly EdgeId _edge;
        private readonly EdgeKind _newKind;
        private EdgeKind _oldKind;

        public ReTypeEdgeCommand(EdgeId edge, EdgeKind newKind)
        {
            _edge = edge;
            _newKind = newKind;
        }

        public string Label => $"Re-type → {_newKind}";

        public void Do(CommandContext ctx)
        {
            _oldKind = ctx.Model.Get(_edge).Kind;
            ctx.Model.SetEdgeType(_edge, _newKind);
        }

        public void Undo(CommandContext ctx) => ctx.Model.SetEdgeType(_edge, _oldKind);
    }

    /// <summary>Re-home one endpoint of an edge (§4.6 re-target). Keeps the edge's type.</summary>
    public sealed class RetargetEdgeCommand : IAuthoringCommand
    {
        private readonly EdgeId _edge;
        private readonly ElementId _newFrom, _newTo;
        private ElementId _oldFrom, _oldTo;

        public RetargetEdgeCommand(EdgeId edge, ElementId newFrom, ElementId newTo)
        {
            _edge = edge;
            _newFrom = newFrom;
            _newTo = newTo;
        }

        public string Label => "Re-target edge";

        public void Do(CommandContext ctx)
        {
            var e = ctx.Model.Get(_edge);
            _oldFrom = e.From;
            _oldTo = e.To;
            ctx.Model.SetEdgeEndpoints(_edge, _newFrom, _newTo);
        }

        public void Undo(CommandContext ctx) => ctx.Model.SetEdgeEndpoints(_edge, _oldFrom, _oldTo);
    }

    /// <summary>Delete a relationship edge as a single undo step (§4.6).</summary>
    public sealed class DeleteEdgeCommand : IAuthoringCommand
    {
        private readonly EdgeId _id;
        private EdgeKind _kind;
        private ElementId _from, _to;

        public DeleteEdgeCommand(EdgeId id) => _id = id;

        public string Label => "Delete link";

        public void Do(CommandContext ctx)
        {
            var e = ctx.Model.Get(_id);
            _kind = e.Kind; _from = e.From; _to = e.To;
            ctx.Model.RemoveEdge(_id);
        }

        public void Undo(CommandContext ctx) => ctx.Model.AddEdge(_id, _kind, _from, _to);
    }

    /// <summary>Rename an element (§3.5). Empty name is a caller concern (deduped default); this just sets it.</summary>
    public sealed class RenameCommand : IAuthoringCommand
    {
        private readonly ElementId _element;
        private readonly string _newName;
        private string _oldName;

        public RenameCommand(ElementId element, string newName)
        {
            _element = element;
            _newName = newName;
        }

        public string Label => "Rename";

        public void Do(CommandContext ctx)
        {
            _oldName = ctx.Model.Get(_element).Name;
            ctx.Model.Rename(_element, _newName);
        }

        public void Undo(CommandContext ctx) => ctx.Model.Rename(_element, _oldName);
    }

    /// <summary>Toggle the <c>abstract</c> modifier (§3.1). Glyph switches to outline/wireframe in the renderer.</summary>
    public sealed class SetAbstractCommand : IAuthoringCommand
    {
        private readonly ElementId _element;
        private readonly bool _value;
        private bool _old;

        public SetAbstractCommand(ElementId element, bool value)
        {
            _element = element;
            _value = value;
        }

        public string Label => _value ? "Mark abstract" : "Mark concrete";

        public void Do(CommandContext ctx)
        {
            _old = ctx.Model.Get(_element).IsAbstract;
            ctx.Model.SetAbstract(_element, _value);
        }

        public void Undo(CommandContext ctx) => ctx.Model.SetAbstract(_element, _old);
    }

    /// <summary>
    /// Delete an element and its whole subtree plus every incident edge, as a single undo step (§4.6/§3.6).
    /// Snapshots everything removed so <see cref="Undo"/> restores the subtree and edges exactly.
    /// </summary>
    public sealed class DeleteElementCommand : IAuthoringCommand
    {
        private readonly ElementId _root;
        private ElementId _rootParent;

        private readonly struct ElementSnap
        {
            public readonly ElementId Id, Parent;
            public readonly ElementKind Kind;
            public readonly string Name;
            public readonly bool IsAbstract;
            public ElementSnap(ModelElement e)
            {
                Id = e.Id; Parent = e.Parent; Kind = e.Kind; Name = e.Name; IsAbstract = e.IsAbstract;
            }
        }

        private readonly struct EdgeSnap
        {
            public readonly EdgeId Id; public readonly EdgeKind Kind; public readonly ElementId From, To;
            public EdgeSnap(ModelEdge e) { Id = e.Id; Kind = e.Kind; From = e.From; To = e.To; }
        }

        private List<ElementSnap> _removedElements;
        private List<EdgeSnap> _removedEdges;

        public DeleteElementCommand(ElementId root) => _root = root;

        public string Label => "Delete";

        public void Do(CommandContext ctx)
        {
            var model = ctx.Model;
            var root = model.Get(_root);
            _rootParent = root.Parent;

            // Collect the subtree in parent-before-child order so undo can re-add parents first.
            var ordered = new List<ElementId>();
            var queue = new Queue<ElementId>();
            queue.Enqueue(_root);
            while (queue.Count > 0)
            {
                var id = queue.Dequeue();
                ordered.Add(id);
                foreach (var child in model.Get(id).ChildIds)
                    queue.Enqueue(child);
            }

            var subtree = new HashSet<ElementId>(ordered);
            _removedElements = new List<ElementSnap>(ordered.Count);
            foreach (var id in ordered)
                _removedElements.Add(new ElementSnap(model.Get(id)));

            // Any edge touching the subtree goes too.
            _removedEdges = new List<EdgeSnap>();
            foreach (var edge in model.Edges)
                if (subtree.Contains(edge.From) || subtree.Contains(edge.To))
                    _removedEdges.Add(new EdgeSnap(edge));

            foreach (var e in _removedEdges) model.RemoveEdge(e.Id);
            // Remove children before parents (reverse of add order) to keep the tree consistent.
            for (int i = ordered.Count - 1; i >= 0; i--)
                model.RemoveElement(ordered[i]);

            ctx.Packer.OnRemoved(_rootParent);
        }

        public void Undo(CommandContext ctx)
        {
            var model = ctx.Model;
            // Parents first (snapshot is in BFS order), so each child's parent already exists.
            foreach (var s in _removedElements)
                model.AddElement(s.Id, s.Kind, s.Name, s.Parent, s.IsAbstract);
            foreach (var e in _removedEdges)
                model.AddEdge(e.Id, e.Kind, e.From, e.To);
            ctx.Packer.OnInserted(_root, _rootParent);
        }
    }
}
