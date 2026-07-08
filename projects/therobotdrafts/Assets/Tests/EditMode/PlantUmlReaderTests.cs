using System.Linq;
using NUnit.Framework;
using TheRobotDraft.Authoring.Interchange;

namespace TheRobotDraft.Tests
{
    /// <summary>
    /// PlantUmlReader coverage across every diagram family the image import accepts: class/ERD, use case,
    /// state, activity (block syntax), sequence, component/deployment, and mindmap — plus the LLM-output
    /// tolerances (markdown fences, undeclared endpoints) the vision pipeline depends on.
    /// </summary>
    public class PlantUmlReaderTests
    {
        // ------------------------------------------------------------------ class / ERD

        [Test]
        public void ClassDiagram_MembersRelationsAndNotes()
        {
            var m = PlantUmlReader.Parse(@"
@startuml
title Shop
package Billing {
  abstract class Order {
    +id : int
    -total : decimal = 0
    {static} +Create(customer : Customer) : Order
    #recalc() : void
  }
  class Invoice <<entity>>
}
interface Payable
enum Status {
  OPEN
  PAID
}
class Customer
Order <|-- Invoice
Payable <|.. Order
Order ""1"" *-- ""0..*"" LineItem : contains
Customer o-- Order
Order ..> Emailer : notify
note right of Order : the aggregate root
@enduml");
            Assert.AreEqual("class", m.Diagrams[0].Kind);
            Assert.AreEqual("Shop", m.Name);

            var order = m.Elements.First(e => e.Id == "Order");
            Assert.IsTrue(order.IsAbstract);
            Assert.AreEqual("Billing", order.ParentId);
            Assert.AreEqual(4, order.Members.Count);
            Assert.IsTrue(order.Members[2].IsStatic && order.Members[2].IsOperation);
            Assert.AreEqual("Order", order.Members[2].Type);
            Assert.AreEqual(IxVisibility.Private, order.Members[1].Visibility);
            Assert.AreEqual("0", order.Members[1].DefaultValue);

            Assert.AreEqual(2, m.Elements.First(e => e.Id == "Status").EnumLiterals.Count);
            Assert.AreEqual("entity", m.Elements.First(e => e.Id == "Invoice").Stereotype);

            var gen = m.Edges.First(e => e.Type == IxEdgeType.Generalization);
            Assert.AreEqual("Invoice", gen.FromId, "generalization is normalized child → parent");
            Assert.AreEqual("Order", gen.ToId);
            var real = m.Edges.First(e => e.Type == IxEdgeType.Realization);
            Assert.AreEqual("Order", real.FromId);
            Assert.AreEqual("Payable", real.ToId);

            var comp = m.Edges.First(e => e.Type == IxEdgeType.Composition);
            Assert.AreEqual("Order", comp.FromId, "whole at the * side");
            Assert.AreEqual("1", comp.FromMultiplicity);
            Assert.AreEqual("0..*", comp.ToMultiplicity);
            Assert.AreEqual("contains", comp.Label);

            Assert.IsTrue(m.Edges.Any(e => e.Type == IxEdgeType.Aggregation && e.FromId == "Customer"));
            Assert.IsTrue(m.Edges.Any(e => e.Type == IxEdgeType.Dependency && e.Label == "notify"));
            Assert.IsTrue(m.Elements.Any(e => e.Type == IxElementType.Note));
            Assert.IsTrue(m.Edges.Any(e => e.Type == IxEdgeType.NoteLink));
            Assert.AreEqual(IxElementType.Class, m.Elements.First(e => e.Id == "LineItem").Type,
                "undeclared relation endpoints are auto-created");
        }

        [Test]
        public void Erd_EntitiesBecomeTables()
        {
            var m = PlantUmlReader.Parse(@"
entity users {
  id : uuid
  email : varchar
}
entity orders {
  id : uuid
}
users --> orders : places");
            Assert.AreEqual(IxElementType.Table, m.Elements.First(e => e.Id == "users").Type);
            Assert.AreEqual(2, m.Elements.First(e => e.Id == "users").Members.Count);
        }

        // ------------------------------------------------------------------ use case

        [Test]
        public void UseCase_ActorsIncludesExtendsAndBoundary()
        {
            var m = PlantUmlReader.Parse(@"
@startuml
actor Customer
actor ""Support Agent"" as Agent
usecase ""Place Order"" as UC1
(Track Shipment) as UC2
rectangle Webshop {
  usecase ""Browse Catalog"" as UC3
}
Customer --> UC1
Agent --> UC2
UC1 .> UC3 : <<include>>
UC2 .> UC1 : <<extend>>
@enduml");
            Assert.AreEqual("usecase", m.Diagrams[0].Kind);
            Assert.AreEqual("Support Agent", m.Elements.First(e => e.Id == "Agent").Name);
            Assert.AreEqual("Webshop", m.Elements.First(e => e.Id == "UC3").ParentId);
            Assert.IsTrue(m.Edges.Any(e => e.Type == IxEdgeType.Include && e.FromId == "UC1" && e.ToId == "UC3"));
            Assert.IsTrue(m.Edges.Any(e => e.Type == IxEdgeType.Extend));
        }

        // ------------------------------------------------------------------ state

        [Test]
        public void StateMachine_PseudostatesTransitionsDescriptions()
        {
            var m = PlantUmlReader.Parse(@"
@startuml
[*] --> Idle
state ""Running Fast"" as Running
state Choice <<choice>>
Idle --> Running : start
Running --> Choice : check
Choice --> Idle : [retry]
Choice --> [*] : [done]
Idle : waits for input
@enduml");
            Assert.AreEqual("state", m.Diagrams[0].Kind);
            Assert.IsTrue(m.Elements.Any(e => e.Type == IxElementType.StateStart));
            Assert.IsTrue(m.Elements.Any(e => e.Type == IxElementType.StateEnd));
            Assert.AreEqual(IxElementType.Decision, m.Elements.First(e => e.Id == "Choice").Type);
            Assert.AreEqual(5, m.Edges.Count(e => e.Type == IxEdgeType.Transition));
            Assert.IsTrue(m.Edges.Any(e => e.Label == "start"));
            Assert.AreEqual("waits for input", m.Elements.First(e => e.Id == "Idle").Documentation);
        }

        // ------------------------------------------------------------------ activity

        [Test]
        public void Activity_BlockSyntaxWithBranchAndFork()
        {
            var m = PlantUmlReader.Parse(@"
@startuml
start
:Receive request;
if (valid?) then (yes)
  :Process;
  :Store result;
else (no)
  :Reject;
endif
:Send response;
fork
  :Log;
fork again
  :Notify;
end fork
stop
@enduml");
            Assert.AreEqual("activity", m.Diagrams[0].Kind);
            Assert.AreEqual(7, m.Elements.Count(e => e.Type == IxElementType.Activity));
            Assert.AreEqual(1, m.Elements.Count(e => e.Type == IxElementType.Decision));
            Assert.AreEqual(2, m.Elements.Count(e => e.Type == IxElementType.ForkJoin));

            var dec = m.Elements.First(e => e.Type == IxElementType.Decision);
            Assert.IsTrue(m.Edges.Any(e => e.FromId == dec.Id && e.Label == "yes"));
            Assert.IsTrue(m.Edges.Any(e => e.FromId == dec.Id && e.Label == "no"));

            var send = m.Elements.First(e => e.Name == "Send response");
            Assert.AreEqual(2, m.Edges.Count(e => e.ToId == send.Id), "both branches merge into the next action");
        }

        // ------------------------------------------------------------------ sequence

        [Test]
        public void Sequence_ParticipantsAndMessageKinds()
        {
            var m = PlantUmlReader.Parse(@"
@startuml
actor User
participant ""Web App"" as Web
participant API
database DB
User -> Web : click buy
Web -> API : POST /orders
activate API
API ->> DB : insert order
API --> Web : 201 Created
deactivate API
Web --> User : confirmation
@enduml");
            Assert.AreEqual("sequence", m.Diagrams[0].Kind);
            Assert.AreEqual(4, m.Elements.Count(e => e.Type == IxElementType.Lifeline));
            Assert.AreEqual("actor", m.Elements.First(e => e.Id == "User").Stereotype);
            Assert.AreEqual(2, m.Edges.Count(e => e.Type == IxEdgeType.MessageSync));
            Assert.AreEqual(1, m.Edges.Count(e => e.Type == IxEdgeType.MessageAsync));
            Assert.AreEqual(2, m.Edges.Count(e => e.Type == IxEdgeType.MessageReply),
                "in sequence diagrams `-->` is the dotted reply arrow");
            Assert.IsTrue(m.Edges.Any(e => e.Label == "POST /orders"));
        }

        // ------------------------------------------------------------------ component / deployment

        [Test]
        public void Component_BracketsDatabasesAndContainment()
        {
            var m = PlantUmlReader.Parse(@"
@startuml
component ""Order Service"" as OS
[Payment Gateway]
database ""Postgres"" as PG
node AppServer {
  [Web Frontend]
}
OS --> PG
[Web Frontend] --> OS : REST
OS ..> [Payment Gateway] : uses
@enduml");
            Assert.AreEqual("component", m.Diagrams[0].Kind);
            Assert.AreEqual(IxElementType.Database, m.Elements.First(e => e.Id == "PG").Type);
            Assert.IsTrue(m.Elements.Any(e => e.Id == "Payment Gateway" && e.Type == IxElementType.Component));
            Assert.AreEqual("AppServer", m.Elements.First(e => e.Id == "Web Frontend").ParentId);
        }

        // ------------------------------------------------------------------ mindmap

        [Test]
        public void Mindmap_DepthTreeIncludingLeftSide()
        {
            var m = PlantUmlReader.Parse(@"
@startmindmap
* Product Vision
** Features
*** Import
*** Export
** Risks
left side
** Team
@endmindmap");
            Assert.AreEqual("mindmap", m.Diagrams[0].Kind);
            Assert.AreEqual(6, m.Elements.Count(e => e.Type == IxElementType.MindNode));
            var root = m.Elements.First(e => e.Name == "Product Vision");
            Assert.AreEqual(3, m.Edges.Count(e => e.FromId == root.Id));
            var features = m.Elements.First(e => e.Name == "Features");
            Assert.AreEqual(2, m.Edges.Count(e => e.FromId == features.Id));
        }

        // ------------------------------------------------------------------ LLM-output tolerances

        [Test]
        public void Tolerates_MarkdownFences()
        {
            var m = PlantUmlReader.Parse("```plantuml\n@startuml\nclass A\nclass B\nA --> B\n@enduml\n```");
            Assert.AreEqual(2, m.Elements.Count);
            Assert.AreEqual(1, m.Edges.Count);
        }

        [Test]
        public void Throws_OnEmptyAndOnSalt()
        {
            Assert.Throws<InterchangeException>(() => PlantUmlReader.Parse("   \n  "));
            Assert.Throws<InterchangeException>(() => PlantUmlReader.Parse("@startsalt\n{\n[Button]\n}\n@endsalt"));
        }

        [Test]
        public void DetectFamily_WithoutFullParse()
        {
            Assert.AreEqual("sequence", PlantUmlReader.DetectFamily("participant A\nA -> B : hi"));
            Assert.AreEqual("state", PlantUmlReader.DetectFamily("[*] --> S1"));
            Assert.AreEqual("mindmap", PlantUmlReader.DetectFamily("@startmindmap\n* root"));
        }
    }
}
