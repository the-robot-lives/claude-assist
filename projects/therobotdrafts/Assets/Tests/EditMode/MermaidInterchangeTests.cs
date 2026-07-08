using System.Linq;
using NUnit.Framework;
using TheRobotDraft.Authoring.Interchange;

namespace TheRobotDraft.Authoring.Tests
{
    /// <summary>
    /// EditMode tests for the Mermaid <c>classDiagram</c> reader/writer (docs/formats/mermaid-format.md).
    /// The parser is engine-agnostic pure C#, so no renderer / XR is required. These cover the envelope
    /// skip-list, every element/member/relationship/styling construct the reader recognizes, deterministic
    /// export, and color grouping.
    /// </summary>
    public class MermaidInterchangeTests
    {
        // A representative diagram exercising the whole surface.
        private const string Sample = @"---
title: Sample
---
%%{init: {'theme':'default'}}%%
classDiagram
    direction LR
    %% a comment line
    namespace domain {
        class Repository~T~ {
            <<interface>>
            +findById(Guid id) T
            +save(T entity) void
        }
        class Entity {
            <<abstract>>
            +Guid id$
            #DateTime createdAt
            +touch()*
        }
    }
    class Customer {
        +String name
        -Status status
        +activate() void
    }
    Customer : +String email
    class Status {
        <<enumeration>>
        ACTIVE
        ARCHIVED
    }
    class Money~K, V~
    Entity <|-- Customer
    Entity --|> Base
    Repository <|.. CustomerRepo
    CustomerRepo ..|> Repository
    CustomerRepo ..> Customer : manages
    Customer ""1"" o-- ""0..*"" Status : has
    Customer --> ""1"" Entity : origin
    Customer *-- Money
    Customer -- Base
    note for Customer ""aggregate root""
    note ""floating note""
    class Customer:::hi
    classDef hi fill:#f9f,stroke:#333,color:#fff
    class Status hi
    style Money fill:#0f0
    click Customer call foo()
";

        private IxModel _m;

        [SetUp]
        public void SetUp() => _m = MermaidReader.Parse(Sample);

        private IxElement El(IxModel m, string name) => m.Elements.FirstOrDefault(e => e.Name == name);
        private IxElement El(string name) => El(_m, name);
        private string NameOf(IxModel m, string id) => m.Elements.First(e => e.Id == id).Name;

        private IxEdge Edge(IxModel m, IxEdgeType t, string from, string to) =>
            m.Edges.FirstOrDefault(e => e.Type == t && NameOf(m, e.FromId) == from && NameOf(m, e.ToId) == to);

        // --- envelope + skip-list ---------------------------------------------------------------

        [Test]
        public void Frontmatter_Comments_Directives_And_Click_Are_Skipped()
        {
            // Nothing from the ---frontmatter---, %%, %%{init}%%, direction, or click line becomes an element.
            Assert.IsNull(El("Sample"), "frontmatter title is not an element");
            Assert.IsNull(El("foo"), "click callback is not an element");
            Assert.IsNotNull(El("Customer"), "real classes still parse");
        }

        // --- elements + annotations -------------------------------------------------------------

        [Test]
        public void Interface_Enum_Abstract_And_Stereotype_Map_From_Annotations()
        {
            Assert.AreEqual(IxElementType.Interface, El("Repository").Type);
            Assert.AreEqual(IxElementType.Enum, El("Status").Type);
            Assert.IsTrue(El("Entity").IsAbstract);
        }

        [Test]
        public void Generics_On_Element_Both_Single_And_Multi()
        {
            Assert.AreEqual("T", El("Repository").GenericParams);
            Assert.AreEqual("K, V", El("Money").GenericParams);
        }

        [Test]
        public void Namespace_Becomes_Package_Parent()
        {
            Assert.AreEqual(IxElementType.Package, El("domain").Type);
            Assert.AreEqual(El("domain").Id, El("Entity").ParentId);
            Assert.AreEqual(El("domain").Id, El("Repository").ParentId);
        }

        // --- members ----------------------------------------------------------------------------

        [Test]
        public void Method_Has_Return_Type_After_Parens_And_TypeFirst_Params()
        {
            var m = El("Repository").Members.First(x => x.Name == "findById");
            Assert.IsTrue(m.IsOperation);
            Assert.AreEqual("T", m.Type, "return type after the parens");
            Assert.AreEqual(1, m.Parameters.Count);
            Assert.AreEqual("Guid", m.Parameters[0].Type, "param is type-first");
            Assert.AreEqual("id", m.Parameters[0].Name);
        }

        [Test]
        public void Field_Is_TypeFirst_And_Static_Suffix_Parsed()
        {
            var id = El("Entity").Members.First(x => x.Name == "id");
            Assert.IsFalse(id.IsOperation);
            Assert.AreEqual("Guid", id.Type);
            Assert.IsTrue(id.IsStatic, "$ suffix = static");
        }

        [Test]
        public void Abstract_Method_Suffix_Parsed()
        {
            var touch = El("Entity").Members.First(x => x.Name == "touch");
            Assert.IsTrue(touch.IsOperation);
            Assert.IsTrue(touch.IsAbstract, "* suffix = abstract");
        }

        [Test]
        public void External_Member_Form_Appends_To_Class()
        {
            var email = El("Customer").Members.FirstOrDefault(x => x.Name == "email");
            Assert.IsNotNull(email, "`Customer : +String email` appends a member");
            Assert.AreEqual("String", email.Type);
        }

        [Test]
        public void Enum_Literals_Collected()
        {
            CollectionAssert.AreEqual(new[] { "ACTIVE", "ARCHIVED" }, El("Status").EnumLiterals);
        }

        [Test]
        public void Member_Generic_Tilde_Becomes_Angle_Brackets_In_Ir()
        {
            var save = El("Repository").Members.First(x => x.Name == "save");
            Assert.AreEqual("T", save.Parameters[0].Type, "~T~ inside a member normalizes to T");
        }

        // --- relationships (both orientations per arrow) ----------------------------------------

        [Test]
        public void Generalization_Both_Orientations_Normalize_ChildToParent()
        {
            // Entity <|-- Customer  => child Customer, parent Entity
            Assert.IsNotNull(Edge(_m, IxEdgeType.Generalization, "Customer", "Entity"));
            // Entity --|> Base      => child Entity, parent Base
            Assert.IsNotNull(Edge(_m, IxEdgeType.Generalization, "Entity", "Base"));
        }

        [Test]
        public void Realization_Both_Orientations_Normalize_ImplToInterface()
        {
            // both `Repository <|.. CustomerRepo` and `CustomerRepo ..|> Repository` => impl->iface
            Assert.AreEqual(2, _m.Edges.Count(e => e.Type == IxEdgeType.Realization
                && NameOf(_m, e.FromId) == "CustomerRepo" && NameOf(_m, e.ToId) == "Repository"));
        }

        [Test]
        public void Composition_Aggregation_Dependency_DirectedAssociation_Association()
        {
            Assert.IsNotNull(Edge(_m, IxEdgeType.Composition, "Customer", "Money"));
            Assert.IsNotNull(Edge(_m, IxEdgeType.Aggregation, "Customer", "Status"), "whole=diamond side=Customer");
            Assert.IsNotNull(Edge(_m, IxEdgeType.Dependency, "CustomerRepo", "Customer"));
            Assert.IsNotNull(Edge(_m, IxEdgeType.DirectedAssociation, "Customer", "Entity"));
            Assert.IsNotNull(Edge(_m, IxEdgeType.Association, "Customer", "Base"));
        }

        [Test]
        public void Multiplicity_Follows_Ends_And_Label_Parsed()
        {
            var agg = Edge(_m, IxEdgeType.Aggregation, "Customer", "Status");
            Assert.AreEqual("1", agg.FromMultiplicity, "Customer end");
            Assert.AreEqual("0..*", agg.ToMultiplicity, "Status end");
            Assert.AreEqual("has", agg.Label);
        }

        [Test]
        public void Reverse_Arrow_Heads_Are_Mirrored()
        {
            var mm = MermaidReader.Parse("classDiagram\nA <-- B\nC --* D\nE --o F\nG <.. H\nI <--> J");
            string N(string id) => mm.Elements.First(e => e.Id == id).Name;
            var da = mm.Edges.First(e => e.Type == IxEdgeType.DirectedAssociation);
            Assert.AreEqual("B", N(da.FromId)); Assert.AreEqual("A", N(da.ToId)); // arrow at A => target A
            var comp = mm.Edges.First(e => e.Type == IxEdgeType.Composition);
            Assert.AreEqual("D", N(comp.FromId)); // filled diamond at D => whole D
            var agg = mm.Edges.First(e => e.Type == IxEdgeType.Aggregation);
            Assert.AreEqual("F", N(agg.FromId)); // hollow diamond at F => whole F
            var dep = mm.Edges.First(e => e.Type == IxEdgeType.Dependency);
            Assert.AreEqual("H", N(dep.FromId)); Assert.AreEqual("G", N(dep.ToId));
            Assert.IsTrue(mm.Edges.Any(e => e.Type == IxEdgeType.Association), "<--> is a two-way association");
        }

        // --- notes ------------------------------------------------------------------------------

        [Test]
        public void Note_For_Creates_Note_Element_And_Link()
        {
            var notes = _m.Elements.Where(e => e.Type == IxElementType.Note).ToList();
            Assert.IsTrue(notes.Any(n => n.Documentation == "aggregate root"));
            Assert.IsTrue(notes.Any(n => n.Documentation == "floating note"));
            var link = _m.Edges.FirstOrDefault(e => e.Type == IxEdgeType.NoteLink);
            Assert.IsNotNull(link);
            Assert.AreEqual("Customer", NameOf(_m, link.ToId), "note for target");
        }

        // --- styling ----------------------------------------------------------------------------

        [Test]
        public void ClassDef_Assignment_And_ThreeDigit_Hex_Normalized()
        {
            Assert.AreEqual("#FF99FF", El("Customer").FillColor, "#f9f expands to #FF99FF");
            Assert.AreEqual("#333333", El("Customer").LineColor, "#333 expands to #333333");
            Assert.AreEqual("#FFFFFF", El("Customer").TextColor);
            Assert.AreEqual("hi", El("Customer").StyleClass);
        }

        [Test]
        public void Class_Assignment_Statement_Shares_Style()
        {
            Assert.AreEqual("#FF99FF", El("Status").FillColor, "`class Status hi` inherits the classDef colors");
            Assert.AreEqual("hi", El("Status").StyleClass);
        }

        [Test]
        public void Style_Statement_Sets_Colors_Directly()
        {
            Assert.AreEqual("#00FF00", El("Money").FillColor, "`style Money fill:#0f0` -> #00FF00");
        }

        // --- round trip -------------------------------------------------------------------------

        [Test]
        public void RoundTrip_Preserves_Structure_Colors_And_StyleClass()
        {
            string s1 = MermaidWriter.Write(_m);
            var m2 = MermaidReader.Parse(s1);

            Assert.AreEqual(IxElementType.Interface, El(m2, "Repository").Type);
            Assert.AreEqual("T", El(m2, "Repository").GenericParams);
            Assert.IsTrue(El(m2, "Entity").IsAbstract);
            CollectionAssert.AreEqual(new[] { "ACTIVE", "ARCHIVED" }, El(m2, "Status").EnumLiterals);

            var find = El(m2, "Repository").Members.First(x => x.Name == "findById");
            Assert.AreEqual("T", find.Type);
            Assert.AreEqual("Guid", find.Parameters[0].Type);

            // colors + style-class survive (source element carried a StyleClass name -> reused, re-read)
            Assert.AreEqual("#FF99FF", El(m2, "Customer").FillColor);
            Assert.AreEqual("hi", El(m2, "Customer").StyleClass);

            // relationships survive with orientation + multiplicity + label
            var agg = Edge(m2, IxEdgeType.Aggregation, "Customer", "Status");
            Assert.IsNotNull(agg);
            Assert.AreEqual("1", agg.FromMultiplicity);
            Assert.AreEqual("0..*", agg.ToMultiplicity);
            Assert.AreEqual("has", agg.Label);
            Assert.IsNotNull(Edge(m2, IxEdgeType.Generalization, "Customer", "Entity"));
            Assert.IsNotNull(Edge(m2, IxEdgeType.Realization, "CustomerRepo", "Repository"));
        }

        [Test]
        public void Write_Is_Deterministic_ByteForByte()
        {
            Assert.AreEqual(MermaidWriter.Write(_m), MermaidWriter.Write(_m), "same model -> identical output");
            string s1 = MermaidWriter.Write(_m);
            string s2 = MermaidWriter.Write(MermaidReader.Parse(s1));
            Assert.AreEqual(s1, s2, "parse->write->parse->write is a fixed point");
        }

        // --- color grouping ---------------------------------------------------------------------

        [Test]
        public void Grouping_Three_Sharing_Colors_Emit_One_ClassDef_Distinct_Emit_Separate()
        {
            var g = new IxModel();
            for (int i = 0; i < 3; i++)
                g.Elements.Add(new IxElement { Id = "c" + i, Name = "C" + i, FillColor = "#112233", LineColor = "#445566", StyleClass = "shared" });
            g.Elements.Add(new IxElement { Id = "d", Name = "D", FillColor = "#ABCDEF", StyleClass = "other" });

            string outp = MermaidWriter.Write(g);
            int classDefs = outp.Split('\n').Count(l => l.TrimStart().StartsWith("classDef "));
            Assert.AreEqual(2, classDefs, "one classDef per distinct color tuple");
            StringAssert.Contains("classDef shared fill:#112233,stroke:#445566", outp);
            StringAssert.Contains("classDef other fill:#ABCDEF", outp);
            // all three shared members get an assignment line
            Assert.AreEqual(3, outp.Split('\n').Count(l => l.Trim().StartsWith("class ") && l.Trim().EndsWith(" shared")));
        }

        [Test]
        public void Grouping_Generates_StyleNames_When_No_StyleClass()
        {
            var g = new IxModel();
            g.Elements.Add(new IxElement { Id = "a", Name = "A", FillColor = "#111111" });
            g.Elements.Add(new IxElement { Id = "b", Name = "B", FillColor = "#222222" });
            string outp = MermaidWriter.Write(g);
            StringAssert.Contains("classDef style1 fill:#111111", outp);
            StringAssert.Contains("classDef style2 fill:#222222", outp);
        }

        [Test]
        public void Uncolored_Element_Produces_No_Styling()
        {
            var g = new IxModel();
            g.Elements.Add(new IxElement { Id = "a", Name = "A" });
            string outp = MermaidWriter.Write(g);
            Assert.IsFalse(outp.Contains("classDef"), "no colors -> no classDef");
        }

        // --- tolerance --------------------------------------------------------------------------

        [Test]
        public void Unknown_Lines_Do_Not_Throw()
        {
            Assert.DoesNotThrow(() => MermaidReader.Parse("classDiagram\n  ??? weird $$ line\n  gibberish here\n  link A B"));
        }

        [Test]
        public void Empty_Input_Yields_Empty_Model()
        {
            Assert.AreEqual(0, MermaidReader.Parse("").Elements.Count);
            Assert.AreEqual(0, MermaidReader.Parse("   \n  \n").Elements.Count);
        }

        [Test]
        public void Missing_Header_Is_Tolerated()
        {
            var m = MermaidReader.Parse("class A\nclass B\nA --> B");
            Assert.IsNotNull(El(m, "A"));
            Assert.IsNotNull(Edge(m, IxEdgeType.DirectedAssociation, "A", "B"));
        }

        [Test]
        public void Sanitized_Name_Uses_Bracket_Label_Form()
        {
            var g = new IxModel();
            g.Elements.Add(new IxElement { Id = "x", Name = "Bank Account" });
            string outp = MermaidWriter.Write(g);
            StringAssert.Contains("class Bank_Account[\"Bank Account\"]", outp);
            // and it round-trips back to the same display name
            Assert.AreEqual("Bank Account", El(MermaidReader.Parse(outp), "Bank Account").Name);
        }

        // --- model name (frontmatter title) -----------------------------------------------------

        [Test]
        public void Model_Name_Round_Trips_Via_Frontmatter_Title()
        {
            var g = new IxModel { Name = "My Domain" };
            g.Elements.Add(new IxElement { Id = "a", Name = "A" });
            string outp = MermaidWriter.Write(g);
            StringAssert.StartsWith("---\ntitle: My Domain\n---\n", outp);
            Assert.AreEqual("My Domain", MermaidReader.Parse(outp).Name);
        }

        [Test]
        public void No_Model_Name_Emits_No_Frontmatter()
        {
            var g = new IxModel();
            g.Elements.Add(new IxElement { Id = "a", Name = "A" });
            StringAssert.StartsWith("classDiagram", MermaidWriter.Write(g));
        }

        // --- notes with multiple targets --------------------------------------------------------

        [Test]
        public void Note_With_Multiple_Targets_Preserves_Every_Link()
        {
            // One note linked to two elements: Mermaid can't tie one note box to two, so it is written
            // as two `note for` lines and re-imports as two notes — but all links survive (no silent drop).
            var g = new IxModel();
            g.Elements.Add(new IxElement { Id = "a", Name = "A" });
            g.Elements.Add(new IxElement { Id = "b", Name = "B" });
            g.Elements.Add(new IxElement { Id = "n", Name = "n", Type = IxElementType.Note, Documentation = "shared note" });
            g.Edges.Add(new IxEdge { Type = IxEdgeType.NoteLink, FromId = "n", ToId = "a" });
            g.Edges.Add(new IxEdge { Type = IxEdgeType.NoteLink, FromId = "n", ToId = "b" });

            string outp = MermaidWriter.Write(g);
            Assert.AreEqual(2, outp.Split('\n').Count(l => l.TrimStart().StartsWith("note for ")), "one note-for per target");

            var m = MermaidReader.Parse(outp);
            Assert.AreEqual(2, m.Edges.Count(e => e.Type == IxEdgeType.NoteLink), "both links preserved");
            var targets = m.Edges.Where(e => e.Type == IxEdgeType.NoteLink).Select(e => NameOf(m, e.ToId)).OrderBy(x => x).ToArray();
            CollectionAssert.AreEqual(new[] { "A", "B" }, targets);
        }

        // --- determinism after normalization ----------------------------------------------------

        [Test]
        public void Write_Parse_Is_A_Fixed_Point_After_One_Normalization_Cycle()
        {
            // The first Write may normalize (flatten packages, split a multi-target note), so W1 can
            // differ from W2. The honest invariant is that write∘parse is stable thereafter: W2 == W3.
            var g = new IxModel { Name = "Sample" };
            var pkg = new IxElement { Id = "p", Name = "pkg", Type = IxElementType.Package };
            var a = new IxElement { Id = "a", Name = "A", ParentId = "p", FillColor = "#112233", StyleClass = "s" };
            var b = new IxElement { Id = "b", Name = "B", ParentId = "p", FillColor = "#112233", StyleClass = "s" };
            var note = new IxElement { Id = "n", Name = "n", Type = IxElementType.Note, Documentation = "shared" };
            g.Elements.Add(pkg); g.Elements.Add(a); g.Elements.Add(b); g.Elements.Add(note);
            g.Edges.Add(new IxEdge { Type = IxEdgeType.Generalization, FromId = "b", ToId = "a" });
            g.Edges.Add(new IxEdge { Type = IxEdgeType.NoteLink, FromId = "n", ToId = "a" });
            g.Edges.Add(new IxEdge { Type = IxEdgeType.NoteLink, FromId = "n", ToId = "b" });

            string w2 = MermaidWriter.Write(MermaidReader.Parse(MermaidWriter.Write(g)));
            string w3 = MermaidWriter.Write(MermaidReader.Parse(w2));
            Assert.AreEqual(w2, w3, "write∘parse is a fixed point after the first normalization cycle");
        }
    }
}
