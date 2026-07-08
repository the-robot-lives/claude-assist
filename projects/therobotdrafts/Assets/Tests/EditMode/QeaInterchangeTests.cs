using System.Collections.Generic;
using System.IO;
using System.Linq;
using NUnit.Framework;
using TheRobotDraft.Authoring.Interchange;

namespace TheRobotDraft.Authoring.Tests
{
    /// <summary>
    /// EditMode tests for the Sparx EA <c>.qea</c> reader/writer (docs/formats/qea-format.md). These exercise the real
    /// SQLite plumbing, so they need the <c>sqlite3</c> CLI and the checked-in fixture (<c>TestFixtures/oqo.qea</c>) /
    /// template (<c>Assets/StreamingAssets/Interchange/ea-template.qea</c>). When either is missing the test
    /// <see cref="Assert.Ignore(string)"/>s rather than fails — this is environment-dependent, not a defect.
    /// </summary>
    public class QeaInterchangeTests
    {
        // EditMode tests run with CWD = Unity project root; walk up to be robust to a different CWD.
        private static string _root;
        private static string Root => _root ??= FindRoot();

        private static string FixturePath => Path.Combine(Root ?? ".", "TestFixtures", "oqo.qea");
        private static string TemplatePath =>
            Path.Combine(Root ?? ".", "Assets", "StreamingAssets", "Interchange", "ea-template.qea");

        private static string FindRoot()
        {
            var dir = new DirectoryInfo(System.Environment.CurrentDirectory);
            while (dir != null)
            {
                if (File.Exists(Path.Combine(dir.FullName, "TestFixtures", "oqo.qea")) ||
                    File.Exists(Path.Combine(dir.FullName, "Assets", "StreamingAssets", "Interchange", "ea-template.qea")))
                    return dir.FullName;
                dir = dir.Parent;
            }
            return null;
        }

        private static void RequireFixture()
        {
            if (!SqliteCli.IsAvailable) Assert.Ignore("sqlite3 CLI not available");
            if (Root == null || !File.Exists(FixturePath)) Assert.Ignore("fixture TestFixtures/oqo.qea not found");
        }

        private static void RequireTemplate()
        {
            if (!SqliteCli.IsAvailable) Assert.Ignore("sqlite3 CLI not available");
            if (Root == null || !File.Exists(TemplatePath)) Assert.Ignore("ea-template.qea not found");
        }

        // ---------------------------------------------------------------- 1. fixture read

        [Test]
        public void Reads_Fixture_Model_Shape()
        {
            RequireFixture();
            var model = EaQeaReader.Read(FixturePath);

            Assert.IsFalse(string.IsNullOrEmpty(model.Name), "root Model package name populated");
            Assert.AreEqual("Model", model.Name);

            int packages = model.Elements.Count(e => e.Type == IxElementType.Package);
            int nonPackages = model.Elements.Count - packages;
            Assert.AreEqual(15, packages, "16 t_package rows minus the root");
            Assert.AreEqual(127, nonPackages, "104 classes + 7 notes + 11 boundaries + 4 artifacts + 1 constraint");
            Assert.AreEqual(142, model.Elements.Count);

            // Package mirrors are resolved, not emitted: no element carries EA Object_Type 'Package' data as a class.
            Assert.AreEqual(75, model.Elements.Count(e => e.Type == IxElementType.Table), "75 «table» classes");
        }

        [Test]
        public void Reads_Fixture_Table_With_Columns_And_Pk()
        {
            RequireFixture();
            var model = EaQeaReader.Read(FixturePath);

            var us = model.Elements.SingleOrDefault(e => e.Name == "user_session");
            Assert.IsNotNull(us, "user_session table present");
            Assert.AreEqual(IxElementType.Table, us.Type);

            var fields = us.Members.Where(m => !m.IsOperation).ToList();
            Assert.AreEqual(8, fields.Count, "8 columns");
            Assert.IsTrue(fields.Any(f => f.Name == "identifier" && f.Type == "uuid"));

            var ops = us.Members.Where(m => m.IsOperation).ToList();
            Assert.AreEqual(7, ops.Count, "1 PK + 3 FK + 3 index constraints");
            Assert.IsTrue(ops.Any(o => o.Name == "pk_user_session"), "primary-key constraint present");

            var fk = ops.FirstOrDefault(o => o.Name == "FK_user_session_user");
            Assert.IsNotNull(fk);
            Assert.IsTrue(fk.Parameters.Any(p => p.Name == "user_identifier"), "FK carries its participating column");
        }

        [Test]
        public void Reads_Fixture_Edges_With_Expected_Distribution()
        {
            RequireFixture();
            var model = EaQeaReader.Read(FixturePath);

            Assert.AreEqual(63, model.Edges.Count);
            var byType = model.Edges.GroupBy(e => e.Type).ToDictionary(g => g.Key, g => g.Count());
            Assert.AreEqual(33, byType[IxEdgeType.DirectedAssociation], "Association with Direction Source->Destination");
            Assert.AreEqual(6, byType[IxEdgeType.Association], "Association with Direction Unspecified");
            Assert.AreEqual(9, byType[IxEdgeType.Extension]);
            Assert.AreEqual(8, byType[IxEdgeType.Dependency]);
            Assert.AreEqual(7, byType[IxEdgeType.NoteLink]);

            // Every endpoint resolves to a real element (package mirrors included).
            var ids = new HashSet<string>(model.Elements.Select(e => e.Id));
            Assert.IsTrue(model.Edges.All(e => ids.Contains(e.FromId) && ids.Contains(e.ToId)), "no dangling endpoints");
        }

        [Test]
        public void Reads_Fixture_Diagrams_With_Downward_Positive_Placements()
        {
            RequireFixture();
            var model = EaQeaReader.Read(FixturePath);

            Assert.AreEqual(15, model.Diagrams.Count);
            Assert.IsTrue(model.Diagrams.All(d => d.LayoutProvenance == IxLayoutProvenance.Authored));

            var placements = model.Diagrams.SelectMany(d => d.Nodes).ToList();
            Assert.AreEqual(118, placements.Count, "all placements resolved (incl. the package mirror placement)");
            Assert.IsTrue(placements.All(p => p.Width > 0 && p.Height > 0), "positive width/height");
            Assert.IsTrue(placements.Count(p => p.Y > 0) > 100, "Y grows downward-positive for the bulk of placements");
        }

        // ---------------------------------------------------------------- 2. identity

        [Test]
        public void Populates_External_Guids_In_Brace_Form()
        {
            RequireFixture();
            var model = EaQeaReader.Read(FixturePath);

            bool Braced(string g) => !string.IsNullOrEmpty(g) && g[0] == '{' && g[g.Length - 1] == '}';

            Assert.IsTrue(model.Elements.All(e => Braced(e.ExternalUuid)), "every element carries a {GUID}");
            Assert.IsTrue(model.Elements.All(e => e.Id == e.ExternalUuid), "Id == ExternalUuid for EA");
            Assert.IsTrue(model.Edges.All(e => Braced(e.ExternalUuid)), "every edge carries a {GUID}");

            var us = model.Elements.Single(e => e.Name == "user_session");
            Assert.IsTrue(us.Members.All(m => Braced(m.ExternalUuid)), "members carry {GUID}s");
        }

        // ---------------------------------------------------------------- 3. template sanity

        [Test]
        public void Template_Is_Blank_But_Keeps_Seed_Data()
        {
            RequireTemplate();

            string[][] One(string sql) => SqliteCli.Query(TemplatePath, sql);
            int Count(string table) => int.Parse(One($"SELECT count(*) FROM {table};")[0][0]);

            Assert.AreEqual("ok", One("PRAGMA integrity_check;")[0][0]);
            Assert.AreEqual(1, Count("t_package"), "only the root Model package survives");
            Assert.AreEqual(694, Count("t_datatypes"), "seed datatype catalog preserved");
            foreach (var t in new[] { "t_object", "t_attribute", "t_operation", "t_connector", "t_diagram",
                                      "t_diagramobjects", "t_xref", "t_objectproperties" })
                Assert.AreEqual(0, Count(t), t + " should be empty in the template");

            Assert.AreEqual("Model", One("SELECT Name FROM t_package;")[0][0]);
        }

        // ---------------------------------------------------------------- 4. programmatic round-trip

        [Test]
        public void Round_Trips_A_Hand_Built_Model()
        {
            RequireTemplate();

            var model = BuildSampleModel();
            string outPath = Path.Combine(Path.GetTempPath(), "trd-qea-roundtrip-" + System.Guid.NewGuid().ToString("N") + ".qea");
            try
            {
                EaQeaWriter.Write(model, TemplatePath, outPath);
                Assert.AreEqual("ok", SqliteCli.Query(outPath, "PRAGMA integrity_check;")[0][0]);

                var back = EaQeaReader.Read(outPath);

                Assert.AreEqual(2, back.Elements.Count(e => e.Type == IxElementType.Package), "2 packages");
                Assert.AreEqual(7, back.Elements.Count, "2 packages + 5 classifiers");

                var domain = back.Elements.Single(e => e.Name == "Domain");
                var sub = back.Elements.Single(e => e.Name == "Sub");
                Assert.AreEqual(domain.Id, sub.ParentId, "nested package parent preserved");

                var customer = back.Elements.Single(e => e.Name == "Customer");
                Assert.AreEqual(IxElementType.Table, customer.Type);
                var fields = customer.Members.Where(m => !m.IsOperation).ToList();
                Assert.AreEqual(2, fields.Count);
                Assert.IsTrue(fields.Any(f => f.Name == "id" && f.Type == "uuid"));
                Assert.IsTrue(fields.Any(f => f.Name == "name" && f.Visibility == IxVisibility.Private));
                var save = customer.Members.SingleOrDefault(m => m.IsOperation && m.Name == "save");
                Assert.IsNotNull(save, "operation preserved");
                Assert.AreEqual("void", save.Type);
                Assert.AreEqual(1, save.Parameters.Count);
                Assert.AreEqual("arg", save.Parameters[0].Name);
                Assert.AreEqual("in", save.Parameters[0].Direction);

                var status = back.Elements.Single(e => e.Name == "Status");
                Assert.AreEqual(IxElementType.Enum, status.Type);
                CollectionAssert.AreEquivalent(new[] { "Active", "Inactive" }, status.EnumLiterals);

                Assert.AreEqual(IxElementType.Interface, back.Elements.Single(e => e.Name == "IService").Type);
                Assert.AreEqual(IxElementType.Class, back.Elements.Single(e => e.Name == "Base").Type);

                string NameOf(string id) => back.Elements.First(e => e.Id == id).Name;

                var gen = back.Edges.Single(e => e.Type == IxEdgeType.Generalization);
                Assert.AreEqual("Customer", NameOf(gen.FromId), "generalization From = child");
                Assert.AreEqual("Base", NameOf(gen.ToId), "generalization To = parent");

                var comp = back.Edges.Single(e => e.Type == IxEdgeType.Composition);
                Assert.AreEqual("Customer", NameOf(comp.FromId), "composition From = whole");
                Assert.AreEqual("Base", NameOf(comp.ToId), "composition To = part");
                Assert.AreEqual("1", comp.FromMultiplicity);
                Assert.AreEqual("0..*", comp.ToMultiplicity);

                var dassoc = back.Edges.Single(e => e.Type == IxEdgeType.DirectedAssociation);
                Assert.AreEqual("Customer", NameOf(dassoc.FromId));
                Assert.AreEqual("IService", NameOf(dassoc.ToId));

                var note = back.Edges.Single(e => e.Type == IxEdgeType.NoteLink);
                Assert.AreEqual(IxElementType.Note, back.Elements.First(e => e.Id == note.FromId).Type);

                Assert.AreEqual(1, back.Diagrams.Count);
                var diagram = back.Diagrams[0];
                Assert.AreEqual("Main", diagram.Name);
                Assert.AreEqual(2, diagram.Nodes.Count);
                var cNode = diagram.Nodes.Single(n => n.ElementId == customer.Id);
                Assert.AreEqual(100f, cNode.X, 0.5f);
                Assert.AreEqual(50f, cNode.Y, 0.5f);
                Assert.AreEqual(150f, cNode.Width, 0.5f);
                Assert.AreEqual(120f, cNode.Height, 0.5f);
                // The package placement resolves onto the package element (via its mirror).
                Assert.IsTrue(diagram.Nodes.Any(n => n.ElementId == domain.Id), "package placement round-trips");
            }
            finally { if (File.Exists(outPath)) File.Delete(outPath); }
        }

        // ---------------------------------------------------------------- 5. full-circle stress

        [Test]
        public void Full_Circle_Fixture_Preserves_Counts()
        {
            RequireFixture();
            RequireTemplate();

            var first = EaQeaReader.Read(FixturePath);
            string outPath = Path.Combine(Path.GetTempPath(), "trd-qea-fullcircle-" + System.Guid.NewGuid().ToString("N") + ".qea");
            try
            {
                EaQeaWriter.Write(first, TemplatePath, outPath);
                Assert.AreEqual("ok", SqliteCli.Query(outPath, "PRAGMA integrity_check;")[0][0]);

                var second = EaQeaReader.Read(outPath);

                Assert.AreEqual(first.Elements.Count, second.Elements.Count, "element count preserved");
                Assert.AreEqual(first.Edges.Count, second.Edges.Count, "edge count preserved");
                Assert.AreEqual(first.Diagrams.Count, second.Diagrams.Count, "diagram count preserved");

                int P1 = first.Diagrams.Sum(d => d.Nodes.Count);
                int P2 = second.Diagrams.Sum(d => d.Nodes.Count);
                Assert.AreEqual(P1, P2, "placement count preserved");

                int M1 = first.Elements.Sum(e => e.Members.Count);
                int M2 = second.Elements.Sum(e => e.Members.Count);
                Assert.AreEqual(M1, M2, "member count preserved");

                var us1 = first.Elements.Single(e => e.Name == "user_session");
                var us2 = second.Elements.Single(e => e.Name == "user_session");
                Assert.AreEqual(us1.Members.Count(m => !m.IsOperation), us2.Members.Count(m => !m.IsOperation),
                    "user_session column count preserved");
            }
            finally { if (File.Exists(outPath)) File.Delete(outPath); }
        }

        // ---------------------------------------------------------------- sample model

        private static IxModel BuildSampleModel()
        {
            var m = new IxModel { Name = "Sample" };

            var domain = new IxElement { Id = "domain", Type = IxElementType.Package, Name = "Domain" };
            var sub = new IxElement { Id = "sub", Type = IxElementType.Package, Name = "Sub", ParentId = "domain" };

            var customer = new IxElement { Id = "customer", Type = IxElementType.Table, Name = "Customer", ParentId = "sub" };
            customer.Members.Add(new IxMember { IsOperation = false, Name = "id", Type = "uuid", Visibility = IxVisibility.Public });
            customer.Members.Add(new IxMember { IsOperation = false, Name = "name", Type = "varchar", Visibility = IxVisibility.Private, DefaultValue = "x" });
            var save = new IxMember { IsOperation = true, Name = "save", Type = "void", Visibility = IxVisibility.Public };
            save.Parameters.Add(new IxParam { Name = "arg", Type = "int", Direction = "in" });
            customer.Members.Add(save);

            var baseCls = new IxElement { Id = "base", Type = IxElementType.Class, Name = "Base", ParentId = "domain" };

            var status = new IxElement { Id = "status", Type = IxElementType.Enum, Name = "Status", ParentId = "sub" };
            status.EnumLiterals.Add("Active");
            status.EnumLiterals.Add("Inactive");

            var svc = new IxElement { Id = "svc", Type = IxElementType.Interface, Name = "IService", ParentId = "domain" };
            var note = new IxElement { Id = "note", Type = IxElementType.Note, Name = null, Documentation = "a note body", ParentId = "domain" };

            m.Elements.AddRange(new[] { domain, sub, customer, baseCls, status, svc, note });

            m.Edges.Add(new IxEdge { Type = IxEdgeType.Generalization, FromId = "customer", ToId = "base" });
            m.Edges.Add(new IxEdge
            {
                Type = IxEdgeType.Composition, FromId = "customer", ToId = "base",
                FromMultiplicity = "1", ToMultiplicity = "0..*", FromRole = "owner", ToRole = "parts",
            });
            m.Edges.Add(new IxEdge
            {
                Type = IxEdgeType.DirectedAssociation, FromId = "customer", ToId = "svc",
                FromMultiplicity = "1", ToMultiplicity = "0..1",
            });
            m.Edges.Add(new IxEdge { Type = IxEdgeType.NoteLink, FromId = "note", ToId = "customer" });

            var diagram = new IxDiagram { Id = "d1", Name = "Main", Kind = "Logical", LayoutProvenance = IxLayoutProvenance.Authored };
            diagram.Nodes.Add(new IxNodePlacement { ElementId = "customer", X = 100, Y = 50, Width = 150, Height = 120 });
            diagram.Nodes.Add(new IxNodePlacement { ElementId = "domain", X = 300, Y = 60, Width = 120, Height = 80 });
            m.Diagrams.Add(diagram);

            return m;
        }
    }
}
