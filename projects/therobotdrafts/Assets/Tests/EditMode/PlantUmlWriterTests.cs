using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using NUnit.Framework;
using TheRobotDraft.Authoring.Interchange;

namespace TheRobotDraft.Authoring.Tests
{
    /// <summary>
    /// Tests for <see cref="PlantUmlWriter"/> (export) and its round-trip pairing with <see cref="PlantUmlReader"/>
    /// (import) over the PlantUML class-diagram profile — docs/formats/plantuml-format.md §9. Two flavors:
    ///   • Writer-output tests assert the emitted text directly (deterministic, minimal, idiomatic).
    ///   • Round-trip tests build (or parse) a model, Write it, Parse it back, and deep-compare — verifying the
    ///     writer emits forms the reader recovers losslessly.
    /// The comparer normalizes one benign reader quirk: a generic classifier's display name keeps its
    /// <c>&lt;T&gt;</c> suffix on re-read (GenericParams is preserved separately), so names are compared modulo a
    /// trailing generic argument list.
    /// </summary>
    public class PlantUmlWriterTests
    {
        // ------------------------------------------------------------------ writer output

        [Test]
        public void Header_Is_Startuml_With_Hide_Empty_Members()
        {
            var m = new IxModel();
            m.Elements.Add(Cls("A"));
            string s = PlantUmlWriter.Write(m);
            Assert.IsTrue(s.StartsWith("@startuml\n"), "starts with @startuml");
            Assert.IsTrue(s.Contains("hide empty members"), "suppresses empty compartments");
            Assert.IsTrue(s.TrimEnd().EndsWith("@enduml"), "ends with @enduml");
            Assert.IsTrue(s.EndsWith("\n"), "trailing newline");
        }

        [Test]
        public void Header_Carries_Diagram_Name_When_Present()
        {
            var m = new IxModel { Name = "MyDiagram" };
            m.Elements.Add(Cls("A"));
            Assert.IsTrue(PlantUmlWriter.Write(m).Contains("@startuml MyDiagram"));
        }

        [Test]
        public void Keywords_Match_Element_Types()
        {
            var m = new IxModel();
            m.Elements.Add(new IxElement { Id = "I", Name = "I", Type = IxElementType.Interface });
            m.Elements.Add(new IxElement { Id = "E", Name = "E", Type = IxElementType.Enum });
            m.Elements.Add(new IxElement { Id = "S", Name = "S", Type = IxElementType.Struct });
            m.Elements.Add(new IxElement { Id = "A", Name = "A", Type = IxElementType.Class, IsAbstract = true });
            m.Elements.Add(new IxElement { Id = "T", Name = "T", Type = IxElementType.Table });
            string s = PlantUmlWriter.Write(m);
            Assert.IsTrue(s.Contains("interface I"), "interface");
            Assert.IsTrue(s.Contains("enum E"), "enum");
            Assert.IsTrue(s.Contains("struct S"), "struct");
            Assert.IsTrue(s.Contains("abstract class A"), "abstract class");
            Assert.IsTrue(s.Contains("class T <<table>>"), "table stereotype");
        }

        [Test]
        public void NonIdentifier_Name_Uses_Quoted_Alias()
        {
            var m = new IxModel();
            m.Elements.Add(new IxElement { Id = "MyClass", Name = "My Class", Type = IxElementType.Class });
            Assert.IsTrue(PlantUmlWriter.Write(m).Contains("class \"My Class\" as MyClass"));
        }

        [Test]
        public void Generic_Params_Are_Emitted_In_Angle_Brackets()
        {
            var m = new IxModel();
            m.Elements.Add(new IxElement { Id = "Map", Name = "Map", Type = IxElementType.Interface, GenericParams = "K,V" });
            Assert.IsTrue(PlantUmlWriter.Write(m).Contains("interface Map<K,V>"));
        }

        [Test]
        public void Members_Compose_Fields_Then_Methods_With_Glyphs_And_Modifiers()
        {
            var c = Cls("C");
            c.Members.Add(new IxMember { Name = "count", Type = "int", IsStatic = true, Visibility = IxVisibility.Public });
            c.Members.Add(new IxMember { Name = "secret", Type = "String", Visibility = IxVisibility.Private });
            c.Members.Add(new IxMember { Name = "id", Type = "Guid", IsAbstract = true, Visibility = IxVisibility.Protected });
            c.Members.Add(Op("save", "void", new IxParam { Name = "e", Type = "Entity" }));
            var m = new IxModel();
            m.Elements.Add(c);
            string s = PlantUmlWriter.Write(m);

            // fields precede methods
            int idxField = s.IndexOf("count", System.StringComparison.Ordinal);
            int idxMethod = s.IndexOf("save(", System.StringComparison.Ordinal);
            Assert.Less(idxField, idxMethod, "fields emitted before methods");

            // modifiers lead the visibility glyph (the reader only recognizes them there)
            Assert.IsTrue(s.Contains("{static} + count : int"), "static field: " + s);
            Assert.IsTrue(s.Contains("- secret : String"), "private field");
            Assert.IsTrue(s.Contains("{abstract} # id : Guid"), "abstract protected field");
            Assert.IsTrue(s.Contains("+ save(e: Entity) : void"), "method with typed param + return");
        }

        [Test]
        public void Enum_Literals_Are_Bare_Lines()
        {
            var e = new IxElement { Id = "Status", Name = "Status", Type = IxElementType.Enum };
            e.EnumLiterals.Add("ACTIVE");
            e.EnumLiterals.Add("ARCHIVED");
            var m = new IxModel();
            m.Elements.Add(e);
            string s = PlantUmlWriter.Write(m);
            Assert.IsTrue(Regex.IsMatch(s, @"\n\s*ACTIVE\n"), "ACTIVE bare");
            Assert.IsTrue(Regex.IsMatch(s, @"\n\s*ARCHIVED\n"), "ARCHIVED bare");
        }

        [Test]
        public void Packages_Nest_Their_Children()
        {
            var m = new IxModel();
            m.Elements.Add(new IxElement { Id = "p", Name = "p", Type = IxElementType.Package });
            m.Elements.Add(new IxElement { Id = "C", Name = "C", Type = IxElementType.Class, ParentId = "p" });
            string s = PlantUmlWriter.Write(m);
            Assert.IsTrue(Regex.IsMatch(s, @"package p \{\s*\n\s+class C\s*\n\}"), "class nested in package:\n" + s);
        }

        [Test]
        public void Relationship_Arrows_Are_Canonical()
        {
            var m = new IxModel();
            foreach (string id in new[] { "A", "B" })
            {
                m.Elements.Add(Cls(id));
            }
            m.Edges.Add(new IxEdge { Type = IxEdgeType.Generalization, FromId = "A", ToId = "B" });
            m.Edges.Add(new IxEdge { Type = IxEdgeType.Realization, FromId = "A", ToId = "B" });
            m.Edges.Add(new IxEdge { Type = IxEdgeType.Composition, FromId = "A", ToId = "B" });
            m.Edges.Add(new IxEdge { Type = IxEdgeType.Aggregation, FromId = "A", ToId = "B" });
            m.Edges.Add(new IxEdge { Type = IxEdgeType.DirectedAssociation, FromId = "A", ToId = "B" });
            m.Edges.Add(new IxEdge { Type = IxEdgeType.Association, FromId = "A", ToId = "B" });
            m.Edges.Add(new IxEdge { Type = IxEdgeType.Dependency, FromId = "A", ToId = "B" });
            m.Edges.Add(new IxEdge { Type = IxEdgeType.Extension, FromId = "A", ToId = "B" });
            string s = PlantUmlWriter.Write(m);
            Assert.IsTrue(s.Contains("A --|> B"), "generalization");
            Assert.IsTrue(s.Contains("A ..|> B"), "realization");
            Assert.IsTrue(s.Contains("A *-- B"), "composition");
            Assert.IsTrue(s.Contains("A o-- B"), "aggregation");
            Assert.IsTrue(s.Contains("A --> B"), "directed association");
            Assert.IsTrue(s.Contains("A -- B"), "plain association");
            Assert.IsTrue(s.Contains("A ..> B"), "dependency");
            Assert.IsTrue(s.Contains("A ..> B : <<extension>>"), "extension");
        }

        [Test]
        public void Multiplicities_And_Label_Hug_The_Correct_Ends()
        {
            var m = new IxModel();
            m.Elements.Add(Cls("Order"));
            m.Elements.Add(Cls("Line"));
            m.Edges.Add(new IxEdge
            {
                Type = IxEdgeType.Composition,
                FromId = "Order",
                ToId = "Line",
                FromMultiplicity = "1",
                ToMultiplicity = "0..*",
                Label = "contains",
            });
            Assert.IsTrue(PlantUmlWriter.Write(m).Contains("Order \"1\" *-- \"0..*\" Line : contains"));
        }

        [Test]
        public void Notes_Emit_As_Floating_Notes_With_NoteLinks()
        {
            var m = new IxModel();
            m.Elements.Add(Cls("C"));
            m.Elements.Add(new IxElement { Id = "N", Name = "hi", Type = IxElementType.Note, Documentation = "hi" });
            m.Edges.Add(new IxEdge { Type = IxEdgeType.NoteLink, FromId = "N", ToId = "C" });
            string s = PlantUmlWriter.Write(m);
            Assert.IsTrue(s.Contains("note \"hi\" as N"), "floating note");
            Assert.IsTrue(s.Contains("N .. C"), "note link");
        }

        // ------------------------------------------------------------------ round-trip

        [Test]
        public void RoundTrip_Representative_Model_Is_Lossless()
        {
            IxModel model = Representative();
            IxModel back = PlantUmlReader.Parse(PlantUmlWriter.Write(model));
            AssertModelsEqual(model, back);
        }

        [Test]
        public void RoundTrip_Doc9_Shaped_Text_Is_Stable_And_Complete()
        {
            // The docs/formats/plantuml-format.md §9 worked example verbatim: packages, a generic interface,
            // an abstract class, an enum, typed fields/methods, and every class-diagram relationship kind with
            // multiplicities and a reading-direction label. The class literally named "Entity" (which previously
            // collided with the `entity` keyword) is exercised here to guard that regression.
            const string src =
                "@startuml\n" +
                "hide empty members\n" +
                "package domain {\n" +
                "  interface Repository<T> {\n" +
                "    + findById(id: Guid): T\n" +
                "    + save(entity: T): void\n" +
                "  }\n" +
                "  abstract class Entity {\n" +
                "    + {abstract} id: Guid\n" +
                "    # createdAt: DateTime\n" +
                "  }\n" +
                "  enum Status {\n" +
                "    ACTIVE\n" +
                "    ARCHIVED\n" +
                "    DELETED\n" +
                "  }\n" +
                "  class Customer {\n" +
                "    + name: String\n" +
                "    + email: String\n" +
                "    - status: Status\n" +
                "    + activate(): void\n" +
                "  }\n" +
                "  class CustomerRepository {\n" +
                "    + findById(id: Guid): Customer\n" +
                "    + save(entity: Customer): void\n" +
                "  }\n" +
                "}\n" +
                "Entity <|-- Customer\n" +
                "Repository <|.. CustomerRepository\n" +
                "CustomerRepository ..> Customer : manages\n" +
                "Customer \"1\" o-- \"0..*\" Status : has\n" +
                "Customer --> \"1\" Status : current >\n" +
                "@enduml\n";

            IxModel m1 = PlantUmlReader.Parse(src);

            // structural spot-checks on the parse
            Assert.IsTrue(Has(m1, "domain", IxElementType.Package), "package domain");
            IxElement repo = Find(m1, "Repository");
            Assert.AreEqual(IxElementType.Interface, repo.Type);
            Assert.AreEqual("T", repo.GenericParams, "generic interface");
            Assert.IsTrue(Find(m1, "Entity").IsAbstract, "abstract class");
            Assert.AreEqual(3, Find(m1, "Status").EnumLiterals.Count, "enum literals");
            Assert.IsTrue(m1.Edges.Any(e => e.Type == IxEdgeType.Generalization && e.FromId == "Customer" && e.ToId == "Entity"),
                "generalization normalized child->parent (class named Entity, not misparsed as entity keyword)");
            Assert.IsTrue(m1.Edges.Any(e => e.Type == IxEdgeType.Realization && e.FromId == "CustomerRepository" && e.ToId == "Repository"),
                "realization impl->interface");
            Assert.IsTrue(m1.Edges.Any(e => e.Type == IxEdgeType.Dependency && e.FromId == "CustomerRepository" && e.ToId == "Customer"),
                "dependency");
            Assert.IsTrue(m1.Edges.Any(e => e.Type == IxEdgeType.Aggregation && e.FromId == "Customer" && e.ToId == "Status"
                    && e.FromMultiplicity == "1" && e.ToMultiplicity == "0..*"), "aggregation with multiplicities");
            Assert.IsTrue(m1.Edges.Any(e => e.Type == IxEdgeType.DirectedAssociation && e.FromId == "Customer" && e.ToId == "Status"
                    && e.ToMultiplicity == "1"), "directed association with multiplicity");

            // Parse -> Write -> Parse is stable (the writer emits what the reader read).
            IxModel m2 = PlantUmlReader.Parse(PlantUmlWriter.Write(m1));
            AssertModelsEqual(m1, m2);
        }

        [Test]
        public void RoundTrip_Arrow_Orientation_And_DotVsDash_Preserved()
        {
            // Distinct edge kinds that differ only by head orientation / dot-vs-dash must survive a round-trip.
            var m = new IxModel();
            foreach (string id in new[] { "Child", "Parent", "Impl", "Iface", "Src", "Tgt" })
            {
                m.Elements.Add(Cls(id));
            }
            m.Edges.Add(new IxEdge { Type = IxEdgeType.Generalization, FromId = "Child", ToId = "Parent" });
            m.Edges.Add(new IxEdge { Type = IxEdgeType.Realization, FromId = "Impl", ToId = "Iface" });
            m.Edges.Add(new IxEdge { Type = IxEdgeType.DirectedAssociation, FromId = "Src", ToId = "Tgt" });
            m.Edges.Add(new IxEdge { Type = IxEdgeType.Dependency, FromId = "Src", ToId = "Tgt" });

            IxModel back = PlantUmlReader.Parse(PlantUmlWriter.Write(m));
            AssertModelsEqual(m, back);
        }

        [Test]
        public void RoundTrip_Table_And_Extension()
        {
            // Table (emitted as `class <<table>>`) and Extension (emitted as `..> : <<extension>>`) now map back
            // to their IR types on import, so both survive a round-trip.
            var m = new IxModel();
            var orders = new IxElement { Id = "orders", Name = "orders", Type = IxElementType.Table };
            orders.Members.Add(new IxMember { Name = "id", Type = "bigint", Visibility = IxVisibility.Public });
            orders.Members.Add(new IxMember { Name = "total", Type = "numeric", Visibility = IxVisibility.Public });
            m.Elements.Add(orders);
            m.Elements.Add(Cls("Profile"));
            m.Elements.Add(Cls("Person"));
            m.Edges.Add(new IxEdge { Type = IxEdgeType.Extension, FromId = "Profile", ToId = "Person" });

            IxModel back = PlantUmlReader.Parse(PlantUmlWriter.Write(m));
            Assert.AreEqual(IxElementType.Table, Find(back, "orders").Type, "class <<table>> re-imports as Table");
            Assert.IsTrue(
                back.Edges.Any(e => e.Type == IxEdgeType.Extension && e.FromId == "Profile" && e.ToId == "Person"),
                "..> : <<extension>> re-imports as Extension");
            AssertModelsEqual(m, back);
        }

        [Test]
        public void RoundTrip_Diagram_Name_Via_Startuml_Header()
        {
            var m = new IxModel { Name = "Ordering" };
            m.Elements.Add(Cls("Order"));
            IxModel back = PlantUmlReader.Parse(PlantUmlWriter.Write(m));
            Assert.AreEqual("Ordering", back.Name, "@startuml Name recovered into IxModel.Name");
        }

        // ------------------------------------------------------------------ fixtures & helpers

        private static IxModel Representative()
        {
            var m = new IxModel();
            m.Elements.Add(new IxElement { Id = "domain", Name = "domain", Type = IxElementType.Package });

            var repo = new IxElement { Id = "Repository", Name = "Repository", Type = IxElementType.Interface, ParentId = "domain", GenericParams = "T" };
            repo.Members.Add(Op("findById", "T", new IxParam { Name = "id", Type = "Guid" }));
            repo.Members.Add(Op("save", "void", new IxParam { Name = "entity", Type = "T" }));
            m.Elements.Add(repo);

            var entity = new IxElement { Id = "Entity", Name = "Entity", Type = IxElementType.Class, ParentId = "domain", IsAbstract = true };
            entity.Members.Add(new IxMember { Name = "id", Type = "Guid", IsAbstract = true, Visibility = IxVisibility.Public });
            entity.Members.Add(new IxMember { Name = "createdAt", Type = "DateTime", Visibility = IxVisibility.Protected });
            m.Elements.Add(entity);

            var status = new IxElement { Id = "Status", Name = "Status", Type = IxElementType.Enum, ParentId = "domain" };
            status.EnumLiterals.Add("ACTIVE");
            status.EnumLiterals.Add("ARCHIVED");
            status.EnumLiterals.Add("DELETED");
            m.Elements.Add(status);

            var cust = new IxElement { Id = "Customer", Name = "Customer", Type = IxElementType.Class, ParentId = "domain" };
            cust.Members.Add(new IxMember { Name = "name", Type = "String", Visibility = IxVisibility.Public });
            cust.Members.Add(new IxMember { Name = "email", Type = "String", Visibility = IxVisibility.Public });
            cust.Members.Add(new IxMember { Name = "status", Type = "Status", Visibility = IxVisibility.Private });
            cust.Members.Add(new IxMember { Name = "instances", Type = "int", IsStatic = true, Visibility = IxVisibility.Public });
            cust.Members.Add(Op("activate", "void"));
            m.Elements.Add(cust);

            var custRepo = new IxElement { Id = "CustomerRepository", Name = "CustomerRepository", Type = IxElementType.Class, ParentId = "domain" };
            custRepo.Members.Add(Op("findById", "Customer", new IxParam { Name = "id", Type = "Guid" }));
            custRepo.Members.Add(Op("save", "void", new IxParam { Name = "entity", Type = "Customer" }));
            m.Elements.Add(custRepo);

            m.Elements.Add(new IxElement { Id = "N1", Name = "a customer note", Type = IxElementType.Note, Documentation = "a customer note" });

            m.Edges.Add(new IxEdge { Type = IxEdgeType.Generalization, FromId = "Customer", ToId = "Entity" });
            m.Edges.Add(new IxEdge { Type = IxEdgeType.Realization, FromId = "CustomerRepository", ToId = "Repository" });
            m.Edges.Add(new IxEdge { Type = IxEdgeType.Dependency, FromId = "CustomerRepository", ToId = "Customer", Label = "manages" });
            m.Edges.Add(new IxEdge { Type = IxEdgeType.Aggregation, FromId = "Customer", ToId = "Status", FromMultiplicity = "1", ToMultiplicity = "0..*", Label = "has" });
            m.Edges.Add(new IxEdge { Type = IxEdgeType.DirectedAssociation, FromId = "Customer", ToId = "Status", ToMultiplicity = "1", Label = "current" });
            m.Edges.Add(new IxEdge { Type = IxEdgeType.NoteLink, FromId = "N1", ToId = "Customer" });
            return m;
        }

        private static IxElement Cls(string id)
        {
            return new IxElement { Id = id, Name = id, Type = IxElementType.Class };
        }

        private static IxMember Op(string name, string ret, params IxParam[] ps)
        {
            var m = new IxMember { Name = name, Type = ret, IsOperation = true, Visibility = IxVisibility.Public };
            m.Parameters.AddRange(ps);
            return m;
        }

        private static bool Has(IxModel m, string id, IxElementType type)
        {
            return m.Elements.Any(e => e.Id == id && e.Type == type);
        }

        private static IxElement Find(IxModel m, string id)
        {
            return m.Elements.First(e => e.Id == id);
        }

        // A generic classifier re-reads with its "<T>" suffix retained in the display name; compare names
        // modulo a trailing generic argument list so that benign quirk doesn't fail an otherwise-lossless trip.
        private static string NameCore(string name)
        {
            return name == null ? null : Regex.Replace(name, @"\s*<[^<>]*>\s*$", "");
        }

        private static void AssertModelsEqual(IxModel expected, IxModel actual)
        {
            Assert.AreEqual(expected.Name, actual.Name, "diagram name");
            var ex = expected.Elements.ToDictionary(e => e.Id);
            var ac = actual.Elements.ToDictionary(e => e.Id);
            CollectionAssert.AreEquivalent(ex.Keys, ac.Keys, "element ids");

            foreach (var pair in ex)
            {
                IxElement a = pair.Value;
                IxElement b = ac[pair.Key];
                string where = "element " + pair.Key;
                Assert.AreEqual(a.Type, b.Type, where + " type");
                Assert.AreEqual(NameCore(a.Name), NameCore(b.Name), where + " name");
                Assert.AreEqual(a.ParentId, b.ParentId, where + " parent");
                Assert.AreEqual(a.IsAbstract, b.IsAbstract, where + " abstract");
                Assert.AreEqual(a.GenericParams, b.GenericParams, where + " generics");
                Assert.AreEqual(a.Stereotype, b.Stereotype, where + " stereotype");
                CollectionAssert.AreEqual(a.EnumLiterals, b.EnumLiterals, where + " literals");
                if (a.Type == IxElementType.Note)
                {
                    Assert.AreEqual(a.Documentation, b.Documentation, where + " documentation");
                }

                Assert.AreEqual(a.Members.Count, b.Members.Count, where + " member count");
                for (int i = 0; i < a.Members.Count; i++)
                {
                    IxMember ma = a.Members[i];
                    IxMember mb = b.Members[i];
                    string mw = where + " member[" + i + "]";
                    Assert.AreEqual(ma.Name, mb.Name, mw + " name");
                    Assert.AreEqual(ma.IsOperation, mb.IsOperation, mw + " isOperation");
                    Assert.AreEqual(ma.Type, mb.Type, mw + " type");
                    Assert.AreEqual(ma.Visibility, mb.Visibility, mw + " visibility");
                    Assert.AreEqual(ma.IsStatic, mb.IsStatic, mw + " static");
                    Assert.AreEqual(ma.IsAbstract, mb.IsAbstract, mw + " abstract");
                    Assert.AreEqual(ma.Parameters.Count, mb.Parameters.Count, mw + " param count");
                    for (int j = 0; j < ma.Parameters.Count; j++)
                    {
                        Assert.AreEqual(ma.Parameters[j].Name, mb.Parameters[j].Name, mw + " p" + j + " name");
                        Assert.AreEqual(ma.Parameters[j].Type, mb.Parameters[j].Type, mw + " p" + j + " type");
                    }
                }
            }

            List<string> ee = expected.Edges.Select(EdgeKey).OrderBy(x => x).ToList();
            List<string> ae = actual.Edges.Select(EdgeKey).OrderBy(x => x).ToList();
            CollectionAssert.AreEqual(ee, ae, "edges");
        }

        private static string EdgeKey(IxEdge e)
        {
            return e.Type + "|" + e.FromId + "->" + e.ToId + "|L=" + e.Label
                   + "|FM=" + e.FromMultiplicity + "|TM=" + e.ToMultiplicity;
        }
    }
}
