using System.Linq;
using NUnit.Framework;
using TheRobotDraft.Authoring.Interchange;

namespace TheRobotDraft.Authoring.Tests
{
    /// <summary>
    /// EditMode tests for the XMI 2.x reader/writer (docs/formats/xmi-format.md). They pin the
    /// leniency the importer promises — two roots, several namespace families, all three type
    /// encodings, EA's split-end associations, and diagram geometry — plus a Write→Parse round trip
    /// that must survive every element and edge kind. Pure C#; no renderer / XR required.
    /// </summary>
    public class XmiInterchangeTests
    {
        // --- fixtures -----------------------------------------------------------------------------

        // (1) Plain OMG UML 2.5 flavor: bare <uml:Model> root, www.omg.org/20131001 namespaces,
        //     attribute-form ("Form 1") type references.
        private const string PlainUml25 = @"<?xml version='1.0' encoding='UTF-8'?>
<uml:Model xmi:version='2.0'
           xmlns:xmi='http://www.omg.org/spec/XMI/20131001'
           xmlns:uml='http://www.omg.org/spec/UML/20131001'
           xmi:id='m1' name='Shop'>
  <packagedElement xmi:type='uml:PrimitiveType' xmi:id='pInt' name='int'/>
  <packagedElement xmi:type='uml:Class' xmi:id='cOrder' name='Order'>
    <ownedAttribute xmi:type='uml:Property' xmi:id='a1' name='total' visibility='private' type='pInt'/>
    <ownedOperation xmi:type='uml:Operation' xmi:id='o1' name='submit' visibility='public'>
      <ownedParameter xmi:type='uml:Parameter' xmi:id='pr1' direction='return' type='pInt'/>
    </ownedOperation>
  </packagedElement>
</uml:Model>";

        // (2) Sparx EA flavor: <xmi:XMI> root, schema.omg.org namespaces, EAID_ ids, nested
        //     <type xmi:idref>, one href EAJava primitive, a composite association split across
        //     ownedAttribute/ownedEnd, generalization, interfaceRealization, an enum, and an EA
        //     extension carrying one diagram with geometry. Declared windows-1252 on purpose.
        private const string EaXmi21 = @"<?xml version='1.0' encoding='windows-1252'?>
<xmi:XMI xmi:version='2.1'
         xmlns:uml='http://schema.omg.org/spec/UML/2.1'
         xmlns:xmi='http://schema.omg.org/spec/XMI/2.1'>
  <xmi:Documentation exporter='Enterprise Architect' exporterVersion='6.5'/>
  <uml:Model xmi:type='uml:Model' name='Garage' visibility='public'>
    <packagedElement xmi:type='uml:Package' xmi:id='EAPK_Domain' name='Domain' visibility='public'>

      <packagedElement xmi:type='uml:PrimitiveType' xmi:id='EAJava_int' name='int'/>

      <packagedElement xmi:type='uml:Enumeration' xmi:id='EAID_Fuel' name='Fuel' visibility='public'>
        <ownedLiteral xmi:type='uml:EnumerationLiteral' xmi:id='EAID_Fuel_G' name='Gas'/>
        <ownedLiteral xmi:type='uml:EnumerationLiteral' xmi:id='EAID_Fuel_E' name='Electric'/>
      </packagedElement>

      <packagedElement xmi:type='uml:Interface' xmi:id='EAID_IDrivable' name='Drivable' visibility='public'>
        <ownedOperation xmi:type='uml:Operation' xmi:id='EAID_drv' name='drive' visibility='public'/>
      </packagedElement>

      <packagedElement xmi:type='uml:Class' xmi:id='EAID_Vehicle' name='Vehicle' visibility='public' isAbstract='true'>
        <ownedAttribute xmi:type='uml:Property' xmi:id='EAID_V_wheels' name='wheels' visibility='protected'>
          <type xmi:idref='EAJava_int'/>
        </ownedAttribute>
      </packagedElement>

      <packagedElement xmi:type='uml:Class' xmi:id='EAID_Car' name='Car' visibility='public'>
        <generalization xmi:type='uml:Generalization' xmi:id='EAID_G1' general='EAID_Vehicle'/>
        <interfaceRealization xmi:type='uml:InterfaceRealization' xmi:id='EAID_IR1'
                              client='EAID_Car' supplier='EAID_IDrivable' contract='EAID_IDrivable'/>
        <ownedAttribute xmi:type='uml:Property' xmi:id='EAID_Car_name' name='name' visibility='private'>
          <type xmi:type='uml:PrimitiveType' href='http://schema.omg.org/spec/UML/2.1/uml.xml#EAJava_String'/>
        </ownedAttribute>
        <ownedAttribute xmi:type='uml:Property' xmi:id='EAID_end_engine' name='engine'
                        visibility='private' association='EAID_assoc1' aggregation='composite'>
          <type xmi:idref='EAID_Engine'/>
          <lowerValue xmi:type='uml:LiteralInteger' xmi:id='lv1' value='1'/>
          <upperValue xmi:type='uml:LiteralUnlimitedNatural' xmi:id='uv1' value='1'/>
        </ownedAttribute>
      </packagedElement>

      <packagedElement xmi:type='uml:Class' xmi:id='EAID_Engine' name='Engine' visibility='public'/>

      <packagedElement xmi:type='uml:Association' xmi:id='EAID_assoc1' name='powertrain' visibility='public'>
        <memberEnd xmi:idref='EAID_end_engine'/>
        <memberEnd xmi:idref='EAID_end_car'/>
        <ownedEnd xmi:type='uml:Property' xmi:id='EAID_end_car' name='car'
                  visibility='public' association='EAID_assoc1' aggregation='none'>
          <type xmi:idref='EAID_Car'/>
          <lowerValue xmi:type='uml:LiteralInteger' xmi:id='lv2' value='1'/>
          <upperValue xmi:type='uml:LiteralUnlimitedNatural' xmi:id='uv2' value='1'/>
        </ownedEnd>
      </packagedElement>

    </packagedElement>
  </uml:Model>
  <xmi:Extension extender='Enterprise Architect' extenderID='6.5'>
    <elements>
      <element xmi:idref='EAID_Car' xmi:type='uml:Class' name='Car'>
        <properties documentation='The car.'/>
      </element>
    </elements>
    <diagrams>
      <diagram xmi:id='EAID_DIA1'>
        <model package='EAPK_Domain' localID='1' owner='EAPK_Domain'/>
        <properties name='Domain Class Diagram' type='Logical'/>
        <elements>
          <element geometry='Left=70;Top=50;Right=160;Bottom=200;' subject='EAID_Car' seqno='1'/>
          <element geometry='Left=290;Top=50;Right=380;Bottom=210;' subject='EAID_Engine' seqno='2'/>
        </elements>
      </diagram>
    </diagrams>
  </xmi:Extension>
</xmi:XMI>";

        // (3) XMI 1.x: dotted xmi.version / xmi.id, uppercase UML: metaclass, <XMI.content> wrapper.
        private const string Xmi1x = @"<?xml version='1.0' encoding='UTF-8'?>
<XMI xmi.version='1.1' xmlns:UML='org.omg.xmi.namespace.UML'>
  <XMI.content>
    <UML:Model xmi.id='m1' name='Legacy'>
      <UML:Class xmi.id='c1' name='Old'/>
    </UML:Model>
  </XMI.content>
</XMI>";

        // (4) All three type encodings in one class, plus a deliberately unresolvable reference.
        private const string TypeMatrix = @"<?xml version='1.0' encoding='UTF-8'?>
<xmi:XMI xmi:version='2.1'
         xmlns:uml='http://schema.omg.org/spec/UML/2.1'
         xmlns:xmi='http://schema.omg.org/spec/XMI/2.1'>
  <uml:Model xmi:type='uml:Model' name='Types'>
    <packagedElement xmi:type='uml:PrimitiveType' xmi:id='pInt' name='int'/>
    <packagedElement xmi:type='uml:Class' xmi:id='cC' name='C'>
      <ownedAttribute xmi:type='uml:Property' xmi:id='f1' name='a' type='pInt'/>
      <ownedAttribute xmi:type='uml:Property' xmi:id='f2' name='b'><type xmi:idref='pInt'/></ownedAttribute>
      <ownedAttribute xmi:type='uml:Property' xmi:id='f3' name='c'><type xmi:type='uml:PrimitiveType' href='http://x/uml.xml#String'/></ownedAttribute>
      <ownedAttribute xmi:type='uml:Property' xmi:id='f4' name='d'><type xmi:idref='missing_id'/></ownedAttribute>
    </packagedElement>
  </uml:Model>
</xmi:XMI>";

        // (5) Multiplicity: defaults (absent = 1..1) and the several spellings of unbounded.
        private const string MultDoc = @"<?xml version='1.0' encoding='UTF-8'?>
<xmi:XMI xmi:version='2.1'
         xmlns:uml='http://schema.omg.org/spec/UML/2.1'
         xmlns:xmi='http://schema.omg.org/spec/XMI/2.1'>
  <uml:Model xmi:type='uml:Model' name='Mult'>
    <packagedElement xmi:type='uml:PrimitiveType' xmi:id='pInt' name='int'/>
    <packagedElement xmi:type='uml:Class' xmi:id='cM' name='M'>
      <ownedAttribute xmi:type='uml:Property' xmi:id='m1' name='one'><type xmi:idref='pInt'/></ownedAttribute>
      <ownedAttribute xmi:type='uml:Property' xmi:id='m2' name='many'><type xmi:idref='pInt'/>
        <upperValue xmi:type='uml:LiteralUnlimitedNatural' xmi:id='u2' value='*'/></ownedAttribute>
      <ownedAttribute xmi:type='uml:Property' xmi:id='m3' name='opt'><type xmi:idref='pInt'/>
        <lowerValue xmi:type='uml:LiteralInteger' xmi:id='l3' value='0'/>
        <upperValue xmi:type='uml:LiteralUnlimitedNatural' xmi:id='u3' value='1'/></ownedAttribute>
      <ownedAttribute xmi:type='uml:Property' xmi:id='m4' name='star'><type xmi:idref='pInt'/>
        <lowerValue xmi:type='uml:LiteralInteger' xmi:id='l4' value='0'/>
        <upperValue xmi:type='uml:LiteralUnlimitedNatural' xmi:id='u4' value='-1'/></ownedAttribute>
    </packagedElement>
  </uml:Model>
</xmi:XMI>";

        // --- (1) plain UML 2.5 ---------------------------------------------------------------------

        [Test]
        public void Parses_Bare_UmlModel_Root_With_Attribute_Form_Types()
        {
            var m = XmiReader.Parse(PlainUml25);

            Assert.AreEqual("Shop", m.Name);
            // The int PrimitiveType is a type target only — it is not surfaced as an element.
            Assert.IsNull(m.Elements.FirstOrDefault(e => e.Name == "int"));

            var order = E(m, "Order");
            Assert.AreEqual(IxElementType.Class, order.Type);
            Assert.AreEqual(2, order.Members.Count);

            var total = Member(order, "total");
            Assert.IsFalse(total.IsOperation);
            Assert.AreEqual("int", total.Type, "Form 1 attribute type reference resolves");
            Assert.AreEqual(IxVisibility.Private, total.Visibility);

            var submit = Member(order, "submit");
            Assert.IsTrue(submit.IsOperation);
            Assert.AreEqual("int", submit.Type, "return parameter supplies the operation type");
            Assert.AreEqual(0, submit.Parameters.Count);
        }

        // --- (2) Sparx EA ---------------------------------------------------------------------------

        [Test]
        public void Parses_Ea_Xmi_With_Split_Association_Generalization_Realization_Enum()
        {
            var m = XmiReader.Parse(EaXmi21);

            Assert.AreEqual("Garage", m.Name);

            var domain = E(m, "Domain");
            Assert.AreEqual(IxElementType.Package, domain.Type);
            Assert.IsNull(domain.ParentId);

            var fuel = E(m, "Fuel");
            Assert.AreEqual(IxElementType.Enum, fuel.Type);
            Assert.AreEqual(domain.Id, fuel.ParentId, "nesting chains ParentId through the package");
            CollectionAssert.AreEqual(new[] { "Gas", "Electric" }, fuel.EnumLiterals);

            var drivable = E(m, "Drivable");
            Assert.AreEqual(IxElementType.Interface, drivable.Type);
            Assert.AreEqual("drive", Member(drivable, "drive").Name);
            Assert.IsNull(Member(drivable, "drive").Type, "untyped operation return is void/null");

            var vehicle = E(m, "Vehicle");
            Assert.IsTrue(vehicle.IsAbstract);
            Assert.AreEqual("int", Member(vehicle, "wheels").Type);
            Assert.AreEqual(IxVisibility.Protected, Member(vehicle, "wheels").Visibility);

            var car = E(m, "Car");
            Assert.AreEqual("The car.", car.Documentation, "EA extension documentation= fallback");
            // The href EAJava primitive strips its EA prefix to a plain type name.
            Assert.AreEqual("String", Member(car, "name").Type);
            // The composite end and its back-end are ends, not fields — Car keeps only 'name'.
            Assert.AreEqual(1, car.Members.Count);

            var gen = Edge(m, IxEdgeType.Generalization, "Car", "Vehicle");
            Assert.IsNotNull(gen, "generalization: From=child, To=parent");

            var real = Edge(m, IxEdgeType.Realization, "Car", "Drivable");
            Assert.IsNotNull(real, "realization: From=class, To=interface");

            // Composition: filled diamond on the whole; From=whole(Car), To=part(Engine).
            var comp = Edge(m, IxEdgeType.Composition, "Car", "Engine");
            Assert.IsNotNull(comp, "composition direction From=whole To=part");
            Assert.AreEqual("powertrain", comp.Label);
            Assert.AreEqual("car", comp.FromRole);
            Assert.AreEqual("engine", comp.ToRole);
            Assert.AreEqual("1", comp.FromMultiplicity);
            Assert.AreEqual("1", comp.ToMultiplicity);
            Assert.AreEqual("EAID_assoc1", comp.ExternalUuid);

            // Diagram geometry from the extension: X=Left, Y=Top, W=Right-Left, H=Bottom-Top.
            Assert.AreEqual(1, m.Diagrams.Count);
            var dia = m.Diagrams[0];
            Assert.AreEqual(IxLayoutProvenance.Authored, dia.LayoutProvenance);
            Assert.AreEqual("Domain Class Diagram", dia.Name);
            Assert.AreEqual("Logical", dia.Kind);
            Assert.AreEqual(2, dia.Nodes.Count);
            var carNode = dia.Nodes.First(n => n.ElementId == "EAID_Car");
            Assert.AreEqual(70f, carNode.X, 0.001f);
            Assert.AreEqual(50f, carNode.Y, 0.001f);
            Assert.AreEqual(90f, carNode.Width, 0.001f);
            Assert.AreEqual(150f, carNode.Height, 0.001f);
        }

        // --- (3) XMI 1.x rejection ------------------------------------------------------------------

        [Test]
        public void Rejects_Xmi_1x_With_Actionable_Message()
        {
            var ex = Assert.Throws<InterchangeException>(() => XmiReader.Parse(Xmi1x));
            StringAssert.Contains("XMI 2", ex.Message);
        }

        // --- (4) type encodings ---------------------------------------------------------------------

        [Test]
        public void Resolves_All_Three_Type_Encodings_And_Preserves_Unresolved()
        {
            var m = XmiReader.Parse(TypeMatrix);
            var c = E(m, "C");

            Assert.AreEqual(4, c.Members.Count, "an unresolved type never drops the member");
            Assert.AreEqual("int", Member(c, "a").Type, "Form 1: type= attribute");
            Assert.AreEqual("int", Member(c, "b").Type, "Form 2: nested <type xmi:idref>");
            Assert.AreEqual("String", Member(c, "c").Type, "Form 3: nested <type href>");
            Assert.AreEqual("missing_id", Member(c, "d").Type, "unresolved ref preserved verbatim");
        }

        // --- (5) multiplicity -----------------------------------------------------------------------

        [Test]
        public void Multiplicity_Defaults_And_Unbounded_Spellings()
        {
            var m = XmiReader.Parse(MultDoc);
            var cm = E(m, "M");

            Assert.AreEqual("int", Member(cm, "one").Type, "absent lower/upper = 1..1, no suffix");
            Assert.AreEqual("int[1..*]", Member(cm, "many").Type, "value='*' is unbounded");
            Assert.AreEqual("int[0..1]", Member(cm, "opt").Type);
            Assert.AreEqual("int[0..*]", Member(cm, "star").Type, "value='-1' is also unbounded");
        }

        // --- (6) round trip -------------------------------------------------------------------------

        [Test]
        public void Round_Trips_Every_Element_And_Edge_Kind()
        {
            var original = BuildRoundTripModel();
            string xml = XmiWriter.Write(original);

            // The envelope must literally carry the chosen dialect + exporter stanza (§8.1).
            StringAssert.Contains("http://schema.omg.org/spec/UML/2.1", xml);
            StringAssert.Contains("http://schema.omg.org/spec/XMI/2.1", xml);
            StringAssert.Contains("exporter=\"TheRobotDrafts\"", xml);
            StringAssert.Contains("exporterVersion=\"1.0\"", xml);

            var m = XmiReader.Parse(xml);

            Assert.AreEqual("Factory", m.Name);

            var domain = E(m, "Domain");
            Assert.AreEqual(IxElementType.Package, domain.Type);
            Assert.IsNull(domain.ParentId);

            var drivable = E(m, "Drivable");
            Assert.AreEqual(IxElementType.Interface, drivable.Type);
            Assert.AreEqual(domain.Id, drivable.ParentId);
            var idrive = Member(drivable, "drive");
            Assert.IsTrue(idrive.IsOperation);
            Assert.IsNull(idrive.Type, "void operation survives as null return type");
            Assert.AreEqual(0, idrive.Parameters.Count);

            var color = E(m, "Color");
            Assert.AreEqual(IxElementType.Enum, color.Type);
            CollectionAssert.AreEqual(new[] { "Red", "Green" }, color.EnumLiterals);

            var baseCls = E(m, "Base");
            Assert.IsTrue(baseCls.IsAbstract);
            Assert.AreEqual("String", Member(baseCls, "tag").Type);
            Assert.AreEqual(IxVisibility.Protected, Member(baseCls, "tag").Visibility);

            var car = E(m, "Car");
            Assert.AreEqual(3, car.Members.Count, "association ends are not re-imported as fields");

            var speed = Member(car, "speed");
            Assert.AreEqual("int", speed.Type);
            Assert.AreEqual(IxVisibility.Private, speed.Visibility);
            Assert.IsTrue(speed.IsStatic);
            Assert.AreEqual("0", speed.DefaultValue);

            Assert.AreEqual("Color", Member(car, "color").Type, "member typed by a model classifier");

            var drive = Member(car, "drive");
            Assert.IsTrue(drive.IsOperation);
            Assert.AreEqual("Boolean", drive.Type);
            Assert.AreEqual(1, drive.Parameters.Count);
            Assert.AreEqual("distance", drive.Parameters[0].Name);
            Assert.AreEqual("int", drive.Parameters[0].Type);
            Assert.AreEqual("in", drive.Parameters[0].Direction);

            Assert.IsNotNull(E(m, "Engine"));
            Assert.IsNotNull(E(m, "Wheel"));
            Assert.IsNotNull(E(m, "Driver"));
            Assert.IsNotNull(E(m, "Radio"));

            Assert.IsNotNull(Edge(m, IxEdgeType.Generalization, "Car", "Base"));
            Assert.IsNotNull(Edge(m, IxEdgeType.Realization, "Car", "Drivable"));
            Assert.IsNotNull(Edge(m, IxEdgeType.Dependency, "Car", "Color"));

            var comp = Edge(m, IxEdgeType.Composition, "Car", "Engine");
            Assert.IsNotNull(comp);
            Assert.AreEqual("powertrain", comp.Label);
            Assert.AreEqual("engine", comp.ToRole);
            Assert.AreEqual("1", comp.ToMultiplicity);

            var agg = Edge(m, IxEdgeType.Aggregation, "Car", "Wheel");
            Assert.IsNotNull(agg);
            Assert.AreEqual("wheels", agg.ToRole);
            Assert.AreEqual("0..*", agg.ToMultiplicity, "unbounded multiplicity survives the round trip");

            var dir = Edge(m, IxEdgeType.DirectedAssociation, "Car", "Driver");
            Assert.IsNotNull(dir, "one-way navigability recovered from the ownedAttribute/ownedEnd split");
            Assert.AreEqual("driver", dir.ToRole);

            var assoc = Edge(m, IxEdgeType.Association, "Car", "Radio");
            Assert.IsNotNull(assoc);
            Assert.AreEqual("car", assoc.FromRole);
            Assert.AreEqual("radio", assoc.ToRole);

            var note = m.Elements.First(e => e.Type == IxElementType.Note);
            Assert.AreEqual("A car.", note.Documentation);
            var link = m.Edges.First(e => e.Type == IxEdgeType.NoteLink);
            Assert.AreEqual(note.Id, link.FromId);
            Assert.AreEqual("Car", NameOf(m, link.ToId));

            Assert.AreEqual(1, m.Diagrams.Count);
            var dia = m.Diagrams[0];
            Assert.AreEqual(IxLayoutProvenance.Authored, dia.LayoutProvenance);
            Assert.AreEqual("Main", dia.Name);
            Assert.AreEqual("Logical", dia.Kind);
            var carNode = dia.Nodes.First(n => NameOf(m, n.ElementId) == "Car");
            Assert.AreEqual(100f, carNode.Width, 0.001f);
            Assert.AreEqual(80f, carNode.Height, 0.001f);
        }

        // --- (7) non-native edge kinds survive -----------------------------------------------------

        [Test]
        public void Non_Native_Edge_Kinds_Survive_As_Marked_Dependencies()
        {
            var m0 = new IxModel { Name = "Edges" };
            m0.Elements.Add(El("A", IxElementType.Class, null));
            m0.Elements.Add(El("B", IxElementType.Class, null));
            m0.Edges.Add(new IxEdge { Id = "x", Type = IxEdgeType.Extension, FromId = "A", ToId = "B", Label = "ext" });
            m0.Edges.Add(new IxEdge { Id = "u", Type = IxEdgeType.Unknown, FromId = "A", ToId = "B" });
            m0.Edges.Add(new IxEdge { Id = "i", Type = IxEdgeType.Include, FromId = "A", ToId = "B" });
            m0.Edges.Add(new IxEdge { Id = "d", Type = IxEdgeType.Dependency, FromId = "A", ToId = "B" });

            string xml = XmiWriter.Write(m0);
            StringAssert.Contains("<connectors", xml);
            StringAssert.Contains("trdKind=\"Extension\"", xml);

            var m = XmiReader.Parse(xml);
            Assert.AreEqual(4, m.Edges.Count, "nothing is dropped — 4 in, 4 out");

            var ext = Edge(m, IxEdgeType.Extension, "A", "B");
            Assert.IsNotNull(ext, "Extension edge kind restored from the connector marker");
            Assert.AreEqual("ext", ext.Label, "the dependency name preserves the label");
            Assert.IsNotNull(Edge(m, IxEdgeType.Unknown, "A", "B"));
            Assert.IsNotNull(Edge(m, IxEdgeType.Include, "A", "B"));
            // A genuine Dependency stays a Dependency (it carries no marker).
            Assert.IsNotNull(Edge(m, IxEdgeType.Dependency, "A", "B"));
        }

        // --- (8) real UML metaclasses for Artifact/Actor/UseCase/Component --------------------------

        [Test]
        public void Artifact_Actor_UseCase_Component_Round_Trip_As_Metaclasses()
        {
            var m0 = new IxModel { Name = "Behavioral" };
            m0.Elements.Add(El("doc", IxElementType.Artifact, null));
            m0.Elements.Add(El("user", IxElementType.Actor, null));
            m0.Elements.Add(El("login", IxElementType.UseCase, null));
            m0.Elements.Add(El("svc", IxElementType.Component, null));

            string xml = XmiWriter.Write(m0);
            StringAssert.Contains("xmi:type=\"uml:Artifact\"", xml);
            StringAssert.Contains("xmi:type=\"uml:Actor\"", xml);

            var m = XmiReader.Parse(xml);
            Assert.AreEqual(IxElementType.Artifact, E(m, "doc").Type);
            Assert.AreEqual(IxElementType.Actor, E(m, "user").Type);
            Assert.AreEqual(IxElementType.UseCase, E(m, "login").Type);
            Assert.AreEqual(IxElementType.Component, E(m, "svc").Type);
        }

        // --- (9) kind + stereotype recovery via the EA extension -----------------------------------

        [Test]
        public void Table_Boundary_Struct_Kind_And_Stereotype_Recovered_From_Extension()
        {
            var m0 = new IxModel { Name = "Erd" };

            var session = El("user_session", IxElementType.Table, null);
            session.Stereotype = "table";
            session.Members.Add(Field("id", "uuid", IxVisibility.Public));
            session.Members.Add(Field("expires", "timestamp", IxVisibility.Public));
            m0.Elements.Add(session);

            m0.Elements.Add(El("ui", IxElementType.Boundary, null));

            var point = El("point", IxElementType.Struct, null);
            point.Members.Add(Field("x", "int", IxVisibility.Public));
            point.Members.Add(Field("y", "int", IxVisibility.Public));
            m0.Elements.Add(point);

            var entity = El("Account", IxElementType.Class, null);
            entity.Stereotype = "entity"; // custom stereotype on a plain class
            m0.Elements.Add(entity);

            string xml = XmiWriter.Write(m0);
            StringAssert.Contains("trdKind=\"Table\"", xml);
            StringAssert.Contains("stereotype=\"table\"", xml);

            var m = XmiReader.Parse(xml);

            var s = E(m, "user_session");
            Assert.AreEqual(IxElementType.Table, s.Type, "Table kind recovered, not collapsed to Class");
            Assert.AreEqual("table", s.Stereotype);
            Assert.AreEqual(2, s.Members.Count, "members survive on a stereotyped element");

            Assert.AreEqual(IxElementType.Boundary, E(m, "ui").Type);

            var p = E(m, "point");
            Assert.AreEqual(IxElementType.Struct, p.Type);
            Assert.AreEqual(2, p.Members.Count);

            var acct = E(m, "Account");
            Assert.AreEqual(IxElementType.Class, acct.Type, "custom stereotype does not change the kind");
            Assert.AreEqual("entity", acct.Stereotype);
        }

        // --- round-trip model builder -------------------------------------------------------------

        private static IxModel BuildRoundTripModel()
        {
            var m = new IxModel { Name = "Factory" };

            m.Elements.Add(El("Domain", IxElementType.Package, null));

            var drivable = El("Drivable", IxElementType.Interface, "Domain");
            drivable.Members.Add(Op("drive", null, IxVisibility.Public)); // void
            m.Elements.Add(drivable);

            var color = El("Color", IxElementType.Enum, "Domain");
            color.EnumLiterals.Add("Red");
            color.EnumLiterals.Add("Green");
            m.Elements.Add(color);

            var baseCls = El("Base", IxElementType.Class, "Domain");
            baseCls.IsAbstract = true;
            baseCls.Members.Add(Field("tag", "String", IxVisibility.Protected));
            m.Elements.Add(baseCls);

            var car = El("Car", IxElementType.Class, "Domain");
            car.Members.Add(Field("speed", "int", IxVisibility.Private, stat: true, def: "0"));
            car.Members.Add(Field("color", "Color", IxVisibility.Public));
            car.Members.Add(Op("drive", "Boolean", IxVisibility.Public, P("distance", "int", "in")));
            m.Elements.Add(car);

            m.Elements.Add(El("Engine", IxElementType.Class, "Domain"));
            m.Elements.Add(El("Wheel", IxElementType.Class, "Domain"));
            m.Elements.Add(El("Driver", IxElementType.Class, "Domain"));
            m.Elements.Add(El("Radio", IxElementType.Class, "Domain"));

            var note = new IxElement
            {
                Id = "Note1",
                ExternalUuid = "Note1",
                Type = IxElementType.Note,
                Name = "note",
                Documentation = "A car.",
            };
            m.Elements.Add(note);

            m.Edges.Add(new IxEdge { Id = "g1", Type = IxEdgeType.Generalization, FromId = "Car", ToId = "Base" });
            m.Edges.Add(new IxEdge { Id = "r1", Type = IxEdgeType.Realization, FromId = "Car", ToId = "Drivable" });
            m.Edges.Add(new IxEdge
            {
                Id = "comp1", Type = IxEdgeType.Composition, FromId = "Car", ToId = "Engine",
                Label = "powertrain", ToRole = "engine", FromMultiplicity = "1", ToMultiplicity = "1",
            });
            m.Edges.Add(new IxEdge
            {
                Id = "agg1", Type = IxEdgeType.Aggregation, FromId = "Car", ToId = "Wheel",
                ToRole = "wheels", FromMultiplicity = "1", ToMultiplicity = "0..*",
            });
            m.Edges.Add(new IxEdge
            {
                Id = "dir1", Type = IxEdgeType.DirectedAssociation, FromId = "Car", ToId = "Driver",
                ToRole = "driver", FromMultiplicity = "1", ToMultiplicity = "1",
            });
            m.Edges.Add(new IxEdge
            {
                Id = "assoc1", Type = IxEdgeType.Association, FromId = "Car", ToId = "Radio",
                FromRole = "car", ToRole = "radio", FromMultiplicity = "1", ToMultiplicity = "1",
            });
            m.Edges.Add(new IxEdge { Id = "dep1", Type = IxEdgeType.Dependency, FromId = "Car", ToId = "Color" });
            m.Edges.Add(new IxEdge { Id = "nl1", Type = IxEdgeType.NoteLink, FromId = "Note1", ToId = "Car" });

            var dia = new IxDiagram
            {
                Id = "Dia1",
                Name = "Main",
                Kind = "Logical",
                LayoutProvenance = IxLayoutProvenance.Authored,
            };
            dia.Nodes.Add(new IxNodePlacement { ElementId = "Car", X = 10, Y = 20, Width = 100, Height = 80 });
            dia.Nodes.Add(new IxNodePlacement { ElementId = "Engine", X = 200, Y = 20, Width = 100, Height = 80 });
            m.Diagrams.Add(dia);

            return m;
        }

        // --- test-local helpers -------------------------------------------------------------------

        private static IxElement El(string name, IxElementType type, string parentId) => new IxElement
        {
            Id = name,           // NCName-safe ids so the writer keeps them stable and round trip aligns
            ExternalUuid = name,
            Type = type,
            Name = name,
            ParentId = parentId,
        };

        private static IxMember Field(string name, string type, IxVisibility vis, bool stat = false, string def = null)
            => new IxMember { IsOperation = false, Name = name, Type = type, Visibility = vis, IsStatic = stat, DefaultValue = def };

        private static IxMember Op(string name, string ret, IxVisibility vis, params IxParam[] ps)
        {
            var m = new IxMember { IsOperation = true, Name = name, Type = ret, Visibility = vis };
            m.Parameters.AddRange(ps);
            return m;
        }

        private static IxParam P(string name, string type, string dir)
            => new IxParam { Name = name, Type = type, Direction = dir };

        private static IxElement E(IxModel m, string name) => m.Elements.First(e => e.Name == name);
        private static IxMember Member(IxElement e, string name) => e.Members.First(x => x.Name == name);
        private static string NameOf(IxModel m, string id) => m.Elements.FirstOrDefault(e => e.Id == id)?.Name;

        private static IxEdge Edge(IxModel m, IxEdgeType t, string from, string to) =>
            m.Edges.FirstOrDefault(e => e.Type == t && NameOf(m, e.FromId) == from && NameOf(m, e.ToId) == to);
    }
}
