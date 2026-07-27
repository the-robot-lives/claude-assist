using NUnit.Framework;
using TheRobotDraft.Authoring.Commands;
using TheRobotDraft.Authoring.Model;
using TheRobotDraft.Authoring.Rules;
using TheRobotDraft.Authoring.Seams;
using TheRobotDraft.Authoring.State;

namespace TheRobotDraft.Authoring.Tests
{
    /// <summary>
    /// EditMode tests for the engine-agnostic authoring core (authoring-ux.md §0–§4). These validate the
    /// invariants the whole authoring surface depends on: containment + edge legality, single-step undo,
    /// spring-loaded modes, and never-stranded cancel. No renderer / XR required — the core is pure C#.
    /// </summary>
    public class AuthoringCoreTests
    {
        private AuthoringModel _model;
        private AuthoringController _ctl;
        private CommandContext _ctx;

        private static (AuthoringModel model, AuthoringController ctl, CommandContext ctx) NewWorld()
        {
            var model = new AuthoringModel();
            var ctx = new CommandContext(model, new NullPacker(), new CountingIdFactory());
            var ctl = new AuthoringController(model, new UndoStack(ctx));
            return (model, ctl, ctx);
        }

        [SetUp]
        public void SetUp() => (_model, _ctl, _ctx) = NewWorld();

        // Helper: directly seed an element (bypasses the controller) for arranging fixtures.
        private ElementId Seed(ElementKind kind, string name, ElementId parent)
        {
            var id = new ElementId($"seed:{name}");
            _model.AddElement(id, kind, name, parent, false);
            return id;
        }

        // --- containment rules (§3.1) ---

        [Test]
        public void Field_Under_Package_Is_Invalid()
        {
            Assert.IsFalse(ContainmentRules.CanContain(ElementKind.Package, ElementKind.Field).IsValid);
        }

        [Test]
        public void Field_Under_Class_Is_Valid()
        {
            Assert.IsTrue(ContainmentRules.CanContain(ElementKind.Class, ElementKind.Field).IsValid);
        }

        [Test]
        public void Members_Cannot_Contain_Anything()
        {
            Assert.IsFalse(ContainmentRules.CanContain(ElementKind.Function, ElementKind.Field).IsValid);
            Assert.IsFalse(ContainmentRules.CanContain(ElementKind.Field, ElementKind.Class).IsValid);
        }

        [Test]
        public void Invalid_Containment_Carries_A_Reason()
        {
            // The §B invalid affordance shows a hover reason at point-of-use, so the reason must be populated.
            var v = ContainmentRules.CanContain(ElementKind.Package, ElementKind.Field);
            Assert.IsFalse(v.IsValid);
            Assert.IsNotNull(v.Reason);
            Assert.IsNotEmpty(v.Reason);
        }

        // --- edge rules (§4.4) ---

        [Test]
        public void Generalization_Class_To_Class_Is_Valid()
        {
            var a = Seed(ElementKind.Class, "A", ElementId.None);
            var b = Seed(ElementKind.Class, "B", ElementId.None);
            Assert.IsTrue(EdgeRules.CanConnect(_model, EdgeKind.Generalization, a, b).IsValid);
        }

        [Test]
        public void Generalization_Class_To_Interface_Is_Invalid()
        {
            var a = Seed(ElementKind.Class, "A", ElementId.None);
            var i = Seed(ElementKind.Interface, "I", ElementId.None);
            Assert.IsFalse(EdgeRules.CanConnect(_model, EdgeKind.Generalization, a, i).IsValid);
        }

        [Test]
        public void Realization_Class_To_Interface_Is_Valid()
        {
            var a = Seed(ElementKind.Class, "A", ElementId.None);
            var i = Seed(ElementKind.Interface, "I", ElementId.None);
            Assert.IsTrue(EdgeRules.CanConnect(_model, EdgeKind.Realization, a, i).IsValid);
        }

        [Test]
        public void Member_As_Edge_Endpoint_Is_Invalid()
        {
            var c = Seed(ElementKind.Class, "C", ElementId.None);
            var f = Seed(ElementKind.Field, "f", c);
            Assert.IsFalse(EdgeRules.CanConnect(_model, EdgeKind.Association, c, f).IsValid);
        }

        [Test]
        public void Reflexive_Association_Is_Valid_But_Self_Generalization_Is_Not()
        {
            var c = Seed(ElementKind.Class, "C", ElementId.None);
            Assert.IsTrue(EdgeRules.CanConnect(_model, EdgeKind.Association, c, c).IsValid);
            Assert.IsFalse(EdgeRules.CanConnect(_model, EdgeKind.Generalization, c, c).IsValid);
        }

        [Test]
        public void Generalization_Cycle_Is_Rejected()
        {
            var a = Seed(ElementKind.Class, "A", ElementId.None);
            var b = Seed(ElementKind.Class, "B", ElementId.None);
            // A --|> B exists; now B --|> A would close a cycle.
            _model.AddEdge(new EdgeId("g1"), EdgeKind.Generalization, a, b);
            Assert.IsFalse(EdgeRules.CanConnect(_model, EdgeKind.Generalization, b, a).IsValid);
        }

        [Test]
        public void Package_Level_Dependency_Is_Valid()
        {
            var p1 = Seed(ElementKind.Package, "p1", ElementId.None);
            var p2 = Seed(ElementKind.Package, "p2", ElementId.None);
            Assert.IsTrue(EdgeRules.CanConnect(_model, EdgeKind.Dependency, p1, p2).IsValid);
        }

        // --- add-node + undo (§3, §0.2) ---

        [Test]
        public void AddNode_Then_Undo_Round_Trips()
        {
            var pkg = Seed(ElementKind.Package, "root", ElementId.None);
            _ctl.EnterAddNode(ElementKind.Class, CommitStyle.OneShot);
            var created = _ctl.CommitAddNode(pkg, "MyClass");

            Assert.IsTrue(created.IsValid);
            Assert.IsTrue(_model.Contains(created));
            Assert.AreEqual(AuthoringMode.Select, _ctl.Mode, "one-shot returns to Select");

            Assert.IsTrue(_ctl.Undo());
            Assert.IsFalse(_model.Contains(created), "undo removes the added node");

            Assert.IsTrue(_ctl.Redo());
            Assert.IsTrue(_model.Contains(created), "redo restores it");
        }

        [Test]
        public void NewElements_Get_Uuid5_DeepLinks_With_Kind_Defaults()
        {
            var pkg = Seed(ElementKind.Package, "root", ElementId.None);

            _ctl.EnterAddNode(ElementKind.Class, CommitStyle.OneShot);
            var cls = _ctl.CommitAddNode(pkg, "Customer");
            _ctl.EnterAddNode(ElementKind.Field, CommitStyle.OneShot);
            var field = _ctl.CommitAddNode(cls, "- id : Guid");
            _ctl.EnterAddNode(ElementKind.Function, CommitStyle.OneShot);
            var op = _ctl.CommitAddNode(cls, "+ save() : void");

            Assert.IsNotEmpty(_model.Get(cls).DeepLinkUuid);
            Assert.IsNotEmpty(_model.Get(cls).DeepLinkCode);
            Assert.IsTrue(_model.Get(cls).EmbedDeepLinkCode, "class doc pointers embed by default");
            Assert.IsFalse(_model.Get(field).EmbedDeepLinkCode, "fields/properties are opt-in");
            Assert.IsTrue(_model.Get(op).EmbedDeepLinkCode, "operations embed by default");
        }

        [Test]
        public void DeepLink_Encoder_Matches_DocPointers_Utility()
        {
            var uuid = DeepLinkIdentity.Uuid5(DeepLinkIdentity.NamespaceUuid, "doc-pointers:TestPointer");

            Assert.AreEqual("5c692577-ad0c-51f1-992c-759b5e5fffb5", uuid);
            Assert.AreEqual("𓳔𔐮𔘟𔄵", DeepLinkIdentity.EncodeToken(uuid));
        }

        [Test]
        public void AddNode_Refuses_Invalid_Parent()
        {
            var pkg = Seed(ElementKind.Package, "root", ElementId.None);
            _ctl.EnterAddNode(ElementKind.Field, CommitStyle.OneShot); // Field under Package is illegal
            var created = _ctl.CommitAddNode(pkg, "f");
            Assert.IsFalse(created.IsValid, "commit refused on invalid target");
            Assert.IsFalse(_ctl.CanUndo, "nothing was recorded");
        }

        // --- spring-loaded modes (§1) ---

        [Test]
        public void Sticky_AddNode_Stays_In_Mode()
        {
            var pkg = Seed(ElementKind.Package, "root", ElementId.None);
            _ctl.EnterAddNode(ElementKind.Class, CommitStyle.Sticky);
            _ctl.CommitAddNode(pkg, "A");
            Assert.AreEqual(AuthoringMode.AddNode, _ctl.Mode, "sticky stays for the next placement");
            _ctl.CommitAddNode(pkg, "B");
            Assert.AreEqual(AuthoringMode.AddNode, _ctl.Mode);
        }

        [Test]
        public void Cancel_Always_Returns_To_Select()
        {
            _ctl.EnterConnect(CommitStyle.Sticky);
            var c = Seed(ElementKind.Class, "C", ElementId.None);
            _ctl.BeginConnect(c);
            Assert.IsTrue(_ctl.ConnectDragActive);

            _ctl.Cancel();
            Assert.AreEqual(AuthoringMode.Select, _ctl.Mode, "never stranded");
            Assert.IsFalse(_ctl.ConnectDragActive, "cancel clears the in-progress drag");
        }

        // --- connect + sticky type (§4.2) ---

        [Test]
        public void Connect_Commits_And_Sticky_Type_Persists()
        {
            var a = Seed(ElementKind.Class, "A", ElementId.None);
            var b = Seed(ElementKind.Class, "B", ElementId.None);

            _ctl.EnterConnect(CommitStyle.Sticky, EdgeKind.Dependency);
            Assert.IsTrue(_ctl.BeginConnect(a));
            var edge = _ctl.CommitConnect(b);

            Assert.IsTrue(edge.IsValid);
            Assert.AreEqual(EdgeKind.Dependency, _ctl.PendingEdgeKind, "sticky type carries to the next edge");
            Assert.AreEqual(1, CountEdges());
        }

        [Test]
        public void Connect_Release_On_Empty_Cancels_Drag_Without_Edge()
        {
            var a = Seed(ElementKind.Class, "A", ElementId.None);
            _ctl.EnterConnect(CommitStyle.Sticky);
            _ctl.BeginConnect(a);
            var edge = _ctl.CommitConnect(ElementId.None); // released over empty space
            Assert.IsFalse(edge.IsValid);
            Assert.IsFalse(_ctl.ConnectDragActive);
            Assert.AreEqual(0, CountEdges(), "no orphan edge");
            Assert.AreEqual(AuthoringMode.Connect, _ctl.Mode, "sticky stays after an empty release");
        }

        // --- delete subtree + undo (§4.6 / §3.6) ---

        [Test]
        public void Delete_Removes_Subtree_And_Incident_Edges_And_Undo_Restores()
        {
            var pkg = Seed(ElementKind.Package, "root", ElementId.None);
            var cls = Seed(ElementKind.Class, "C", pkg);
            var field = Seed(ElementKind.Field, "f", cls);
            var other = Seed(ElementKind.Class, "Other", pkg);
            _model.AddEdge(new EdgeId("dep"), EdgeKind.Dependency, cls, other);

            Assert.IsTrue(_ctl.Delete(cls));
            Assert.IsFalse(_model.Contains(cls));
            Assert.IsFalse(_model.Contains(field), "subtree removed");
            Assert.AreEqual(0, CountEdges(), "incident edge removed");
            Assert.IsTrue(_model.Contains(other), "unrelated element untouched");

            Assert.IsTrue(_ctl.Undo());
            Assert.IsTrue(_model.Contains(cls));
            Assert.IsTrue(_model.Contains(field), "subtree restored");
            Assert.AreEqual(1, CountEdges(), "incident edge restored");
        }

        // --- reparent guard (§3.6) ---

        [Test]
        public void Cannot_Reparent_Into_Own_Descendant()
        {
            var outer = Seed(ElementKind.Package, "outer", ElementId.None);
            var inner = Seed(ElementKind.Package, "inner", outer);
            Assert.IsFalse(_ctl.Reparent(outer, inner), "would orphan the subtree");
        }

        [Test]
        public void Reparent_Valid_Move_Succeeds_And_Undo_Restores_Parent()
        {
            var p1 = Seed(ElementKind.Package, "p1", ElementId.None);
            var p2 = Seed(ElementKind.Package, "p2", ElementId.None);
            var cls = Seed(ElementKind.Class, "C", p1);

            Assert.IsTrue(_ctl.Reparent(cls, p2));
            Assert.AreEqual(p2, _model.Get(cls).Parent);

            Assert.IsTrue(_ctl.Undo());
            Assert.AreEqual(p1, _model.Get(cls).Parent, "undo restores the original parent");
        }

        private int CountEdges()
        {
            int n = 0;
            foreach (var _ in _model.Edges) n++;
            return n;
        }
    }
}
