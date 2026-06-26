# Diagram Catalog

**Status:** Authoritative
**Audience:** Engineers implementing The Robot Draft
**Scope:** Every diagram family the tool must support, with notation and 3D bubble-view projection notes

---

## Purpose

The Robot Draft is a Unity/VR UML-IDE. It reverse-engineers source code into a navigable 3D "bubble" model — a spatial graph where every model element is a bubble and every relationship is an edge — and projects user-selected regions of that model into standard 2D diagrams on demand.

This document is the single authoritative catalog of the diagram families the tool must produce and round-trip. It targets feature parity with **Sparx Enterprise Architect** and **IBM Rational Rose**. For each diagram type you will find:

- **Purpose** — one line stating what the diagram communicates.
- **Key notation elements** — the symbols and relationships the renderer must draw.
- **Bubble-view mapping** — how the diagram appears in, and projects from, the 3D bubble navigation.

The bubble model is the source of truth. A diagram is a *view* — a filtered, laid-out projection of a region of bubbles and edges. Reverse-engineering populates bubbles; diagrams render them; round-tripping writes edits back to bubbles and (where a textual source-of-truth exists) to code.

> **Related specs**
> - File formats and import/export targets: [`../specs/file-formats.md`](./file-formats.md)
> - Notation, color, and layout conventions: [`../specs/design-conventions.md`](./design-conventions.md)
> - Core domain model (bubbles, edges, regions): [`../CONCEPTS.md`](../CONCEPTS.md)
> - System architecture: [`../ARCHITECTURE.md`](../ARCHITECTURE.md)

---

## Summary Matrix

| # | Diagram | Standard | Category | Tier | Bubble primitive |
|---|---------|----------|----------|------|------------------|
| 1 | Class | UML 2.5.1 | Structural | 1 | Type bubbles + member sub-bubbles, inheritance/association edges |
| 2 | Object | UML 2.5.1 | Structural | 2 | Instance bubbles with slot values, link edges |
| 3 | Package | UML 2.5.1 | Structural | 1 | Namespace container bubbles, dependency/import edges |
| 4 | Component | UML 2.5.1 | Structural | 1 | Component bubbles with port studs, provided/required interface edges |
| 5 | Composite Structure | UML 2.5.1 | Structural | 2 | Owner bubble with nested part bubbles, ports, connectors |
| 6 | Deployment | UML 2.5.1 | Structural | 1 | Node bubbles hosting artifact bubbles, communication edges |
| 7 | Profile | UML 2.5.1 | Structural | 2 | Stereotype bubbles extending metaclass bubbles |
| 8 | Use Case | UML 2.5.1 | Behavioral | 2 | Actor + use-case bubbles inside a boundary shell |
| 9 | Activity | UML 2.5.1 | Behavioral | 2 | Action bubbles on flow edges, fork/join/decision gates, swimlane volumes |
| 10 | State Machine | UML 2.5.1 | Behavioral | 2 | State bubbles, transition edges labeled event[guard]/action |
| 11 | Sequence | UML 2.5.1 | Interaction | 1 | Lifeline lanes, time-ordered message edges, activation segments |
| 12 | Communication | UML 2.5.1 | Interaction | 2 | Same bubbles as sequence, structural link edges with sequence numbers |
| 13 | Timing | UML 2.5.1 | Interaction | 3 | Lifeline lanes with state/value tracks against a time axis |
| 14 | Interaction Overview | UML 2.5.1 | Interaction | 3 | Activity-style flow whose nodes are interaction-fragment bubbles |
| 15 | Block Definition (BDD) | SysML 1.x | Structure | 2 | Block bubbles (class-like) with value/flow features |
| 16 | Internal Block (IBD) | SysML 1.x | Structure | 2 | Block interior with part bubbles, ports, item-flow connectors |
| 17 | Parametric | SysML 1.x | Structure | 2 | Constraint-block bubbles binding parameter ports |
| 18 | SysML Package | SysML 1.x | Structure | 2 | Reuses UML Package projection |
| 19 | SysML Activity | SysML 1.x | Behavior | 2 | UML Activity + continuous-flow / control-operator decorations |
| 20 | Requirement | SysML 1.x | Requirements | 2 | Requirement bubbles, «derive»/«satisfy»/«verify»/«refine»/«trace» edges |
| 21 | BPMN Process | BPMN 2.0 | Process | 2 | Event/task/gateway bubbles on sequence-flow edges in one pool |
| 22 | BPMN Collaboration | BPMN 2.0 | Process | 2 | Multiple pool volumes joined by message-flow edges |
| 23 | BPMN Choreography | BPMN 2.0 | Process | 2 | Choreography-task bubbles banded by participant |
| 24 | DRD (Decision Requirements) | DMN | Decision | 2 | Decision/input-data/knowledge bubbles, information-requirement edges |
| 25 | ArchiMate views | ArchiMate 3.x | Enterprise | 3 | Layer-colored element bubbles across stacked layer planes |
| 26 | ERD / Physical Data Model | ER / vendor | Data | 1 | Entity/table bubbles with column sub-bubbles, relationship edges |
| 27 | Data Flow (DFD) | Yourdon / Gane-Sarson | Data | 2 | Process/store/external bubbles, data-flow edges |
| 28 | UAF / UPDM | OMG (DoDAF/MODAF/NAF) | Enterprise | 3 | Grid-addressed bubbles across architecture viewpoints |
| 29 | TOGAF (ADM) | Open Group | Enterprise | 3 | Phase/artifact bubbles around the ADM cycle |
| 30 | Zachman | Zachman | Enterprise | 3 | 6×6 grid of cell bubbles |
| 31 | Requirements + Traceability | EA-general | Requirements | 2 | Requirement bubbles, traceability matrix as edge adjacency view |
| 32 | Mind Map | EA-general | Auxiliary | 3 | Central topic bubble with radial child bubbles |
| 33 | Gantt / Kanban | EA-general | Project | 3 | Task bubbles on a time axis / column volumes |
| 34 | Wireframe / UI Mockup | EA-general | Design | 3 | Screen container bubbles with widget sub-bubbles |
| 35 | Whiteboard / Sketch | EA-general | Auxiliary | 3 | Freeform frames, sticky notes, cards, text, clouds, bubbles, sketch connectors |
| 36 | Network Diagram | EA-general | Infrastructure | 3 | Device bubbles, link edges |
| 37 | XSD / WSDL Schema | W3C | Data/Service | 3 | Type/element bubbles, containment + reference edges |
| 38 | Rose Use Case (legacy) | UML 1.x (Rose) | Legacy | 3 | UML Use Case projection, legacy element names preserved |
| 39 | Rose Class (legacy) | UML 1.x (Rose) | Legacy | 3 | UML Class projection |
| 40 | Rose Object (legacy) | UML 1.x (Rose) | Legacy | 3 | UML Object projection |
| 41 | Rose Sequence (legacy) | UML 1.x (Rose) | Legacy | 3 | UML Sequence projection |
| 42 | Rose Collaboration (legacy) | UML 1.x (Rose) | Legacy | 3 | UML Communication projection, name kept as "Collaboration" |
| 43 | Rose Statechart (legacy) | UML 1.x (Rose) | Legacy | 3 | UML State Machine projection, name kept as "Statechart" |
| 44 | Rose Activity (legacy) | UML 1.x (Rose) | Legacy | 3 | UML Activity projection |
| 45 | Rose Component (legacy) | UML 1.x (Rose) | Legacy | 3 | UML Component projection |
| 46 | Rose Deployment (legacy) | UML 1.x (Rose) | Legacy | 3 | UML Deployment projection |
| 47 | Capsule Structure | Rose RealTime (UML-RT/ROOM) | Real-time | 3 | Capsule bubbles with typed ports, protocol-typed connectors |

> Tiers are recommended implementation priority. See [Coverage Tiers](#coverage-tiers).
> Auxiliary EA families noted but not individually rendered (BPEL, BPSim, ORM, GML, ICONIX, Eriksson-Penker) appear under [Additional EA Families](#additional-enterprise-architecture-families).
>
> **EA gallery parity note.** The authoring palette now includes first-pass EA-gallery vocabulary for SysML (blocks, value types, constraint blocks, requirements, ports, parameters), BPMN (events, activities, gateways, pools/lanes, data nodes, choreography and conversation), DMN (decision, input data, knowledge source/business knowledge, decision service, annotation), ArchiMate (business, application, technology, motivation and implementation elements), and enterprise framework views (business capabilities, value streams/chains, strategy objectives, scorecard perspectives, org units, heat-map and decision-tree nodes, UAF, TOGAF and Zachman cells). These nodes now use notation-specific face styling and editable kind-specific property rows instead of generic placeholder boxes. Standards-level interchange and validation are tracked separately from basic diagram authoring.

---

## 1. UML 2.5.1

The OMG UML 2.5.1 standard defines 14 diagram types: 7 structural, 7 behavioral. These are the core of the tool. Reverse-engineering populates the bubble model directly from these element kinds.

### Structural Diagrams

#### 1.1 Class Diagram

- **Purpose:** Show the static structure — classes, their attributes and operations, and the relationships among them.
- **Key notation:** Class rectangles (name / attribute / operation compartments); visibility markers (`+ - # ~`); generalization (hollow triangle), association (line, with multiplicity, roles, navigability), aggregation (hollow diamond), composition (filled diamond), dependency (dashed arrow), realization (dashed hollow triangle); interfaces and abstract classes.
- **Bubble-view mapping:** Each type is a **type bubble**; its attributes and operations are **member sub-bubbles** nested inside it. Inheritance and realization render as upward edges to supertype bubbles; associations, aggregations, and compositions render as labeled edges carrying multiplicity and role metadata. This is the canonical bubble projection — most other structural views are specializations of it.

#### 1.2 Object Diagram

- **Purpose:** Capture a snapshot of instances and their links at a single moment.
- **Key notation:** Instance specifications (`name : Class`, underlined); attribute slots with concrete values; links (instance-level associations).
- **Bubble-view mapping:** **Instance bubbles** carry slot sub-bubbles holding concrete values. Link edges connect instances. An object diagram is a runtime/example state of a class-diagram region; the navigator can pivot between a type bubble and its instance bubbles.

#### 1.3 Package Diagram

- **Purpose:** Organize the model into namespaces and show their dependencies and imports.
- **Key notation:** Package (tabbed folder) symbol; dependency (dashed arrow); `«import»` and `«access»` stereotypes; nesting.
- **Bubble-view mapping:** Packages are **container bubbles** that physically enclose their member bubbles in 3D space — they define the primary spatial hierarchy of the world. Dependency and import edges cross package boundaries. Package containment is the default zoom/navigation hierarchy.

#### 1.4 Component Diagram

- **Purpose:** Show software components and the interfaces they provide and require.
- **Key notation:** Component symbol (rectangle with component icon); provided interface (ball / lollipop); required interface (socket / cup); assembly connectors; ports; delegation connectors.
- **Bubble-view mapping:** Each component is a **component bubble** with **port studs** on its surface. Provided interfaces render as ball edges, required as socket edges; an assembly connection is a ball-into-socket edge between two component bubbles.

#### 1.5 Composite Structure Diagram

- **Purpose:** Decompose a classifier into its internal parts, ports, and connectors.
- **Key notation:** Structured classifier frame; parts (roles); ports on the boundary; connectors between parts; collaborations.
- **Bubble-view mapping:** An **owner bubble** is entered to reveal **nested part bubbles** wired by connector edges, with ports on the owner's inner shell. This is the natural "zoom inside a bubble" interaction — composite structure is the bubble model's internal-decomposition view.

#### 1.6 Deployment Diagram

- **Purpose:** Map software artifacts onto physical or virtual hardware.
- **Key notation:** Node (3D box) and device/execution-environment stereotypes; artifacts; deployment (`«deploy»`); communication paths between nodes.
- **Bubble-view mapping:** **Node bubbles** are large host volumes that contain **artifact bubbles**. Communication paths are edges between node bubbles; `«deploy»` is a containment relationship. Maps cleanly onto the spatial metaphor — hardware as places, artifacts as occupants.

#### 1.7 Profile Diagram

- **Purpose:** Extend UML itself — define stereotypes, tagged values, and metaclass extensions. This is the foundation of all UML profiles and MDG-style technologies.
- **Key notation:** Stereotype (`«stereotype»`); metaclass; extension (filled-arrowhead line); tagged value definitions; profile package.
- **Bubble-view mapping:** **Stereotype bubbles** connect via extension edges to **metaclass bubbles**. Tagged-value definitions are sub-bubbles. Profiles are meta-level bubbles: applying a profile decorates target bubbles with stereotype badges and tag slots. Implementing this enables every downstream extension family (SysML, ArchiMate-via-profile, UAF).

### Behavioral Diagrams

#### 1.8 Use Case Diagram

- **Purpose:** Show actors, the use cases they engage, and the system boundary.
- **Key notation:** Actor (stick figure); use case (ellipse); system boundary (rectangle); associations; `«include»`, `«extend»`; actor generalization.
- **Bubble-view mapping:** **Actor bubbles** sit outside a **boundary shell** containing **use-case bubbles**. Association edges cross the shell; `«include»`/`«extend»` are dashed edges between use-case bubbles.

#### 1.9 Activity Diagram

- **Purpose:** Model control and data flow through a procedure, including concurrency and decisions.
- **Key notation:** Action (rounded rectangle); call behavior action (rake marker); send-signal action (pentagon pointing right); accept-event/receive action (concave event notch); initial/final nodes; decision/merge (diamond); fork/join (bar); object nodes; control and object flows; swimlanes (partitions).
- **Bubble-view mapping:** **Action bubbles** are sequenced along flow edges. Fork/join and decision/merge are **gate bubbles** that split or rejoin edges. Swimlane partitions are translucent **lane volumes** grouping action bubbles by responsible classifier.

#### 1.10 State Machine Diagram

- **Purpose:** Model the lifecycle of an object as states and the transitions between them.
- **Key notation:** State (rounded rectangle, optional entry/do/exit); initial (filled dot) and final (bullseye); transition arrow labeled `event [guard] / action`; composite and submachine states; history pseudostates; choice/junction.
- **Bubble-view mapping:** **State bubbles** connect via transition edges labeled with trigger/guard/effect. Composite states are container bubbles entered to reveal nested state bubbles — reusing the composite-structure zoom interaction.

### Interaction Diagrams (Behavioral sub-family)

#### 1.11 Sequence Diagram

- **Purpose:** Show messages exchanged between participants in time order.
- **Key notation:** Lifelines (head box + dashed line); activation/execution bars; synchronous (filled arrow), asynchronous (open arrow), and reply (dashed) messages; create/destroy; combined fragments (`alt`, `opt`, `loop`, `par`, `ref`); guards.
- **Bubble-view mapping:** Each lifeline is a **vertical lane**; messages are **time-ordered edges** between lanes, ordered top-to-bottom along the lane axis. Activation segments highlight the active span of a lane. Combined fragments are framed depth bands. Time is the dominant spatial axis in this projection.

#### 1.12 Communication Diagram

- **Purpose:** Show the same interaction as a sequence diagram, but emphasizing the structural links rather than time order.
- **Key notation:** Objects/roles; links (association lines); sequence-numbered messages along the links (`1:`, `1.1:`, `2:`).
- **Bubble-view mapping:** Reuses the **same participant bubbles** but lays them out by structural link rather than time. Messages become **numbered edge annotations** on the link edges. A communication diagram and its sequence diagram are two layouts of one interaction region — the tool toggles between them.

#### 1.13 Timing Diagram

- **Purpose:** Show how participants' states or values change against an explicit time axis.
- **Key notation:** Lifelines stacked vertically; state/value lanes; the timeline (horizontal axis); state-change waveform; duration and time constraints; events.
- **Bubble-view mapping:** Lifelines are **horizontal tracks**; each track plots its state or value as a step waveform against a shared time axis. Edges mark events and inter-track constraints. A time-series projection of the same lifeline bubbles used by sequence and communication views.

#### 1.14 Interaction Overview Diagram

- **Purpose:** Tie multiple interactions together with activity-style control flow.
- **Key notation:** Activity-diagram frame (initial/final, decision/merge, fork/join) whose nodes are interaction-use references (`ref`) or inline interaction fragments.
- **Bubble-view mapping:** An activity-style flow whose **action bubbles are interaction-fragment bubbles** — each node drills into a full sequence diagram. Combines the activity gate model with sequence-region nodes.

---

## 2. SysML (OMG)

SysML extends UML for systems engineering. The 1.x line defines 9 diagram kinds: four reuse UML diagrams, two are modified, and three are new. All are implemented as UML profile applications (see [Profile Diagram](#17-profile-diagram)).

#### 2.1 Block Definition Diagram (BDD)

- **Purpose:** Define blocks (system building elements), their features, and relationships — a modified class diagram.
- **Key notation:** Block (stereotyped class with value/part/reference/flow-property compartments); composition; generalization; value types; units.
- **Bubble-view mapping:** **Block bubbles** mirror class bubbles, with value, part, and flow features as member sub-bubbles. Composition edges define the part hierarchy that IBDs zoom into.

#### 2.2 Internal Block Diagram (IBD)

- **Purpose:** Show a block's internal parts, ports, and the item flows between them — a modified composite structure diagram.
- **Key notation:** Parts; standard, full, proxy, and flow ports; connectors; item flows.
- **Bubble-view mapping:** Zoom into a **block bubble** to reveal **part bubbles** wired by connectors; **flow ports** on shells carry item-flow edges. Reuses the composite-structure interior interaction.

#### 2.3 Parametric Diagram

- **Purpose:** Bind constraint blocks to parameters for engineering analysis (equations, simulation). *New in SysML.*
- **Key notation:** Constraint block; constraint parameters; binding connectors; value properties bound to parameters.
- **Bubble-view mapping:** **Constraint-block bubbles** expose **parameter ports**; binding connectors are edges linking a parameter port to a value sub-bubble. A computational overlay — edges represent equality bindings, not flow.

#### 2.4 SysML Package Diagram

- **Purpose:** Organize the SysML model. Reuses the UML package diagram.
- **Bubble-view mapping:** Reuses the [Package Diagram](#13-package-diagram) container-bubble projection.

#### 2.5 SysML Activity Diagram

- **Purpose:** Model behavior with systems-engineering extensions — continuous flows, control operators, and probabilities. A modified UML activity diagram.
- **Key notation:** UML activity notation plus continuous/streaming flows, control operators, probability annotations on edges, rate/`«continuous»`/`«discrete»` stereotypes.
- **Bubble-view mapping:** UML [Activity](#19-activity-diagram) projection with edge decorations for rate, continuity, and probability.

#### 2.6 SysML Use Case / Sequence / State Machine

- **Purpose:** Reuse the UML behavioral diagrams unchanged.
- **Bubble-view mapping:** Reuse the corresponding UML projections ([Use Case](#18-use-case-diagram), [Sequence](#111-sequence-diagram), [State Machine](#110-state-machine-diagram)).

#### 2.7 Requirement Diagram

- **Purpose:** Represent text requirements as first-class model elements and trace them to design and tests. *New in SysML.*
- **Key notation:** Requirement (stereotyped box with `id` and `text` tags); `«derive»`, `«satisfy»`, `«verify»`, `«refine»`, `«trace»`, `«copy»` relationships; rationale.
- **Bubble-view mapping:** **Requirement bubbles** hold id/text slots and connect via typed trace edges to the design bubbles (blocks, classes) that satisfy them and the test bubbles that verify them. The edge type set is the backbone of the [traceability matrix](#31-requirements-and-traceability) view.

> **SysML v2 (forward-looking target).** SysML v2 is a ground-up redefinition built on KerML with interchangeable textual and graphical notation and a standard REST/HTTP API. Treat it as a future target requiring the tool to round-trip a **textual source-of-truth**: bubbles project to graphical views while a canonical text model stays authoritative. Architect the SysML importer so v1 graphical fidelity and v2 text round-tripping can coexist. See [`../specs/file-formats.md`](./file-formats.md).

---

## 3. BPMN 2.0 (OMG)

Business Process Model and Notation. Defined by element categories rather than a fixed diagram list; rendered in three styles.

### Element Categories

- **Flow Objects**
  - **Events** — start, intermediate, end; typed: message, timer, error, signal, escalation, compensation, conditional. (Circle: thin = start, double = intermediate, thick = end.)
  - **Activities** — tasks (user, service, send, receive, manual, script, business-rule) and sub-processes (collapsed/expanded, transaction, ad-hoc, call).
  - **Gateways** — exclusive (XOR), inclusive (OR), parallel (AND), event-based, complex. (Diamond with type marker.)
- **Connecting Objects** — sequence flow (solid arrow), message flow (dashed arrow with circle/arrowhead), association (dotted), data association.
- **Swimlanes** — pools (participants) and lanes (sub-partitions).
- **Artifacts** — data objects, data stores, groups, text annotations.

### Diagram Styles

#### 3.1 Process Diagram

- **Purpose:** Model the internal flow of a single process within one pool.
- **Bubble-view mapping:** Event, task, and gateway bubbles are sequenced along **sequence-flow edges** inside one pool volume; gateways are split/merge gate bubbles. Lane sub-volumes group bubbles by role.

#### 3.2 Collaboration Diagram

- **Purpose:** Model two or more participants exchanging messages.
- **Bubble-view mapping:** Multiple **pool volumes**, each holding its own process region, joined by **message-flow edges** that cross pool boundaries.

#### 3.3 Choreography Diagram

- **Purpose:** Model the message exchange sequence between participants without a controlling process.
- **Bubble-view mapping:** **Choreography-task bubbles** banded with their participant labels, sequenced on flow edges — no enclosing pool.

---

## 4. DMN (OMG)

Decision Model and Notation. Complements BPMN for decision logic.

#### 4.1 Decision Requirements Diagram (DRD)

- **Purpose:** Show how decisions depend on input data and business knowledge.
- **Key notation:** Decision (rectangle); input data (rounded-end/stadium shape); business knowledge model (clipped rectangle); knowledge source (document shape); information requirement (solid arrow), knowledge requirement (dashed arrow), authority requirement (dashed line with filled circle).
- **Bubble-view mapping:** **Decision bubbles** draw from **input-data bubbles** and **knowledge-model bubbles** via typed requirement edges; entering a decision bubble reveals its **decision table** and **FEEL expressions** as the bubble's interior content.

> **Decision tables and FEEL.** Each decision bubble owns a decision table (input/output columns, hit policy) and FEEL (Friendly Enough Expression Language) expressions. The tool must edit and evaluate these as the decision bubble's payload, distinct from the DRD topology.

---

## 5. ArchiMate 3.x (Open Group)

Enterprise architecture modeling language. Defined by **layers** and a **viewpoint mechanism** rather than fixed diagram types.

### Layers (with standard color)

| Layer | Color | Concern |
|-------|-------|---------|
| Strategy | (light) | Capabilities, resources, courses of action |
| Business | Yellow | Actors, roles, processes, services, products |
| Application | Blue | Application components, services, data objects |
| Technology | Green | Nodes, devices, system software, networks |
| Physical | Green (extension) | Equipment, facilities, materials |
| Implementation & Migration | Pink | Work packages, deliverables, plateaus, gaps |

### Cross-cutting Aspects

Active Structure (who/what acts), Behavior (what happens), Passive Structure (what is acted on), and Motivation (why — stakeholders, drivers, goals, requirements).

### Viewpoints (not fixed diagrams)

ArchiMate has no fixed diagram catalog. A **viewpoint** filters the model to a stakeholder concern. Basic viewpoints include Composition, Support, Cooperation, and Realization; the standard adds Motivation, Strategy, and Implementation viewpoints.

- **Bubble-view mapping:** Elements are **layer-colored bubbles** arranged across **stacked layer planes** (Strategy on top, Physical at the bottom). A viewpoint is a saved **region filter + layout** over the bubble world — it selects which layers, aspects, and relationship types are visible. Cross-layer relationships (serving, realization, assignment) are edges between planes. The viewpoint mechanism maps directly to the tool's region-projection model: a viewpoint *is* a diagram definition.

---

## 6. Data Modeling

#### 6.1 ERD / Physical Data Model

- **Purpose:** Model entities (logical) or tables (physical) and the relationships between them; generate and reverse-engineer DDL.
- **Key notation:** Entity/table box (name + attribute/column rows); primary key, foreign key, unique markers; relationship lines with cardinality (crow's-foot or IE notation); identifying vs. non-identifying relationships; logical-to-physical transforms (datatype mapping, denormalization).
- **Bubble-view mapping:** **Entity/table bubbles** hold **column sub-bubbles** with type, key, and nullability badges. Relationship edges carry cardinality; FK edges link to referenced key sub-bubbles. Reverse-engineering reads schemas from Oracle, SQL Server, PostgreSQL, and MySQL; forward engineering emits vendor DDL. Logical and physical are two projections of one entity region.

#### 6.2 Data Flow Diagram (DFD)

- **Purpose:** Show how data moves between processes, stores, and external entities (Yourdon / Gane-Sarson).
- **Key notation:** Process (circle in Yourdon, rounded rectangle in Gane-Sarson); data store (open-ended rectangle / two parallel lines); external entity (square); data flow (labeled arrow); leveling (context → level-0 → level-n).
- **Bubble-view mapping:** **Process bubbles**, **data-store bubbles**, and **external-entity bubbles** connected by labeled **data-flow edges**. Leveling maps to bubble nesting — a process bubble is entered to reveal its child DFD.

---

## 7. Additional Enterprise Architecture Families

These families round out parity with Sparx EA and broaden the tool's reach. Several are rendered directly; the rest are listed for completeness and import fidelity.

#### 7.1 UAF / UPDM

- **Purpose:** Unified Architecture Framework (and predecessor UPDM) realize defense architecture frameworks — DoDAF, MODAF, NAF — through grid-organized viewpoints.
- **Bubble-view mapping:** **Grid-addressed bubbles** placed by (viewpoint row × aspect column); each grid cell is a region projection. Built on the UML/SysML profile mechanism.

#### 7.2 TOGAF (ADM)

- **Purpose:** Open Group enterprise architecture method centered on the Architecture Development Method cycle.
- **Bubble-view mapping:** **Phase bubbles** (A–H plus Requirements) arranged around the ADM cycle, each containing its artifact bubbles.

#### 7.3 Zachman Framework

- **Purpose:** Classify architecture artifacts across a 6×6 matrix (perspectives × interrogatives).
- **Bubble-view mapping:** A **6×6 grid of cell bubbles**; each cell holds the artifacts answering one (perspective, question) pair.

#### 7.4 Requirements + Traceability Matrices

- **Purpose:** Manage requirements as model elements and trace them across design and test.
- **Bubble-view mapping:** **Requirement bubbles** (shared with SysML) plus a **traceability matrix view** — an adjacency-grid projection of the trace edges between two selected bubble sets (e.g., requirements × test cases).

#### 7.5 Mind Mapping

- **Purpose:** Capture and organize ideas hierarchically.
- **Bubble-view mapping:** A central **topic bubble** with **radial child bubbles** — the most literal bubble layout in the catalog.

#### 7.6 Gantt / Kanban

- **Purpose:** Plan and track project work — schedule (Gantt) and flow state (Kanban).
- **Bubble-view mapping:** Gantt: **task bubbles** on a time axis with dependency edges. Kanban: **column volumes** (To Do / Doing / Done) holding card bubbles.

#### 7.7 Wireframing / UI Mockups

- **Purpose:** Sketch screen layouts and UI flows.
- **Bubble-view mapping:** **Screen container bubbles** holding **widget sub-bubbles**; navigation edges link screens.

#### 7.8 Whiteboard / Sketch Diagrams

- **Purpose:** Capture early design thinking without forcing the user into formal UML semantics too soon.
- **Key notation:** Freeform frame, sticky note, card, text label, cloud, circle/bubble, diamond, async send/receive marker, and lightweight sketch connector.
- **Bubble-view mapping:** A **whiteboard frame volume** groups sketch bubbles; sticky notes and cards are normal connectable bubbles; sketch connectors can later be retyped as UML, architecture, or traceability relationships.

#### 7.9 Network Diagrams

- **Purpose:** Show physical/logical network topology.
- **Bubble-view mapping:** **Device bubbles** (routers, switches, hosts) joined by **link edges** annotated with addressing.

#### 7.9 XSD / WSDL Schema Modeling

- **Purpose:** Model XML schemas and web-service contracts.
- **Bubble-view mapping:** **Type and element bubbles** with containment and reference edges; WSDL adds port-type, operation, and binding bubbles. Round-trips to/from `.xsd` and `.wsdl`.

#### 7.10 Listed for Import Fidelity (not individually rendered)

The tool must recognize and preserve these on import even when projecting them through a related renderer:

- **BPEL generation** — emit executable BPEL from BPMN process regions.
- **BPSim** — simulation parameters layered onto BPMN bubbles.
- **ORM (Object Role Modeling)** — fact-based data modeling; project through the ERD renderer with role annotations.
- **GML** — geography markup; geo-typed bubbles.
- **ICONIX** — robustness diagrams (boundary/control/entity stereotypes) projected through UML class/sequence renderers.
- **Eriksson-Penker** — business-process extension profile projected through the UML activity renderer.

---

## 8. Rational Rose Legacy

IBM Rational Rose predates UML 2. Rose import fidelity requires preserving the **UML 1.x diagram set and its legacy names** — most importantly `Statechart` and `Collaboration`, which were renamed in UML 2.

### Rose UML 1.x Diagrams (9)

| Rose name | UML 2 equivalent | Renderer reused |
|-----------|------------------|-----------------|
| Use Case | Use Case | [1.8](#18-use-case-diagram) |
| Class | Class | [1.1](#11-class-diagram) |
| Object | Object | [1.2](#12-object-diagram) |
| Sequence | Sequence | [1.11](#111-sequence-diagram) |
| **Collaboration** | Communication | [1.12](#112-communication-diagram) |
| **Statechart** | State Machine | [1.10](#110-state-machine-diagram) |
| Activity | Activity | [1.9](#19-activity-diagram) |
| Component | Component | [1.4](#14-component-diagram) |
| Deployment | Deployment | [1.6](#16-deployment-diagram) |

- **Bubble-view mapping:** Each reuses its UML 2 projection. **Preserve the legacy element and diagram names on import and export** — do not silently rename `Statechart` → `State Machine` or `Collaboration` → `Communication`, or Rose round-tripping breaks.

### Rose RealTime (UML-RT / ROOM)

Rose RealTime adds real-time modeling constructs from ROOM (Real-time Object-Oriented Modeling). These have no plain-UML equivalent and need dedicated bubble primitives.

- **Capsule** — an active, concurrent component with its own thread of control.
- **Port** — a typed interaction point on a capsule, typed by a protocol.
- **Protocol** — the set of messages (incoming/outgoing signals) that types a port.
- **Connector** — wires compatible ports together.
- **Capsule Structure Diagram** — the internal decomposition of a capsule into sub-capsule parts and connectors.
- **Executable State Machine** — a capsule's behavior, runnable for simulation.

#### 8.1 Capsule Structure Diagram

- **Purpose:** Show a capsule's internal parts, ports, and protocol-typed connectors.
- **Bubble-view mapping:** **Capsule bubbles** carry **typed port studs**; connectors are **protocol-typed edges** (the protocol governs which messages may cross). Zoom into a capsule to reveal sub-capsule part bubbles, reusing the composite-structure interior. The executable state machine is the capsule bubble's behavioral payload.

---

## Coverage Tiers

Recommended implementation priority. Each tier should be production-quality before the next begins, because later tiers reuse earlier renderers and the profile mechanism.

### Tier 1 — Core round-trip from code

The diagrams that pay off reverse-engineering immediately. Ship these first.

- UML **Class**, **Sequence**, **Package**, **Component**, **Deployment**
- **ERD / Physical Data Model** (with DDL reverse-engineering)

Rationale: these are what engineers extract from a codebase on day one, and they exercise the bubble model's core primitives — type bubbles, member sub-bubbles, container bubbles, lifeline lanes, and node volumes.

### Tier 2 — Full modeling coverage

Complete UML, add systems and process modeling.

- Remaining UML: **Object**, **Composite Structure**, **Profile**, **Use Case**, **Activity**, **State Machine**, **Communication**
- Full **SysML 1.x** (BDD, IBD, Parametric, Requirement, modified Activity, reused diagrams)
- **BPMN 2.0** (Process, Collaboration, Choreography) and **DMN** (DRD + decision tables/FEEL)
- **Requirements + Traceability matrices**, **DFD**

Rationale: the **Profile** diagram unlocks SysML and every other profile-based family; BPMN/DMN extend the tool from software design into process/decision modeling.

### Tier 3 — Enterprise architecture and specialized families

Breadth for EA parity and legacy import.

- **ArchiMate 3.x** (layers + viewpoints), **UAF/UPDM**, **TOGAF (ADM)**, **Zachman**
- **Rose RealTime** (Capsules, Ports, Protocols, Capsule Structure, executable state machines)
- Auxiliary families: **Timing**, **Interaction Overview**, **Mind Map**, **Gantt/Kanban**, **Wireframe/UI**, **Network**, **XSD/WSDL**, and the import-fidelity set (BPEL, BPSim, ORM, GML, ICONIX, Eriksson-Penker)

Rationale: these target enterprise-architecture parity with Sparx EA and full Rose import fidelity. They depend on the profile mechanism and region-projection model proven in Tiers 1–2.

---

## See Also

- [`../specs/file-formats.md`](./file-formats.md) — import/export formats (XMI, vendor schemas, BPEL, SysML v2 textual model)
- [`../specs/design-conventions.md`](./design-conventions.md) — notation, color, layout, and rendering conventions
- [`../CONCEPTS.md`](../CONCEPTS.md) — bubbles, edges, regions, and the projection model
- [`../ARCHITECTURE.md`](../ARCHITECTURE.md) — system architecture and the reverse-engineering pipeline
