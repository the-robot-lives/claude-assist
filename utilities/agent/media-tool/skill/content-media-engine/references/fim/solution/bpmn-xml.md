# BPMN 2.0 XML — executable business-process interchange

BPMN 2.0 XML is the OMG standard serialization for Business Process Model and Notation: a tool-neutral, executable description of business processes (events, activities, gateways, flows, pools). It is a **model + diagram** format — the `bpmn:` namespace carries process semantics, and a separate `bpmndi:` (BPMN Diagram Interchange) section carries the shape bounds, edge waypoints, and optional colors that let a tool actually draw the process. Consumers include Camunda Modeler, bpmn.io / bpmn-js (the renderer behind most web BPMN editors), Signavio, Flowable, Activiti, and jBPM.

**Current Version**: BPMN 2.0.2 (OMG formal/2013-12-09)  **License**: OMG open specification (royalty-free)  **Runtime**: pure XML; render/execute via bpmn-js (browser) or a BPMN engine

## Official Resources & Documentation
- **BPMN spec (OMG)**: https://www.omg.org/spec/BPMN/2.0.2/
- **BPMN overview**: https://www.bpmn.org/
- **bpmn.io / bpmn-js (renderer + modeler)**: https://bpmn.io/ · https://github.com/bpmn-io/bpmn-js
- **bpmn-moddle (parse/serialize in Node)**: https://github.com/bpmn-io/bpmn-moddle
- **Camunda Modeler**: https://camunda.com/download/modeler/
- **Camunda BPMN reference**: https://docs.camunda.io/docs/components/modeler/bpmn/
- **Flowable**: https://www.flowable.com/ · **Signavio**: https://www.signavio.com/

## Installation & Setup
BPMN XML is data; you render or execute it with a library or engine.

### Web rendering / modeling (bpmn-js)
```bash
npm install bpmn-js          # viewer + modeler
npm install bpmn-moddle      # headless parse/manipulate/serialize
```
```javascript
import BpmnViewer from 'bpmn-js';
const viewer = new BpmnViewer({ container: '#canvas' });
await viewer.importXML(bpmnXmlString);   // renders using the bpmndi: section
```

### Desktop
- **Camunda Modeler** — download the desktop app; edits BPMN + writes `bioc:`/`color:` styling and Camunda/Zeebe extensions.

### Engines (execution)
- Camunda 7/8 (Zeebe), Flowable, Activiti, jBPM consume the same `.bpmn` file; `isExecutable="true"` and engine-specific extension attributes drive runtime behavior.

### Validate
```bash
xmllint --noout process.bpmn                     # well-formedness
# Semantic validity: import into bpmn-js or Camunda Modeler — it reports broken refs.
```

## Core Syntax / API Reference

### Root: definitions + namespaces
`bpmn:definitions` is the document root and declares every namespace used. The five standard ones are always present when the file includes a diagram; extension namespaces (Camunda, Zeebe, bpmn.io color) are optional.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions
    xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
    xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
    xmlns:dc="http://www.omg.org/spec/DD/20100524/DC"
    xmlns:di="http://www.omg.org/spec/DD/20100524/DI"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    id="Definitions_1"
    targetNamespace="http://bpmn.io/schema/bpmn">
  <!-- process(es) + collaboration + bpmndi:BPMNDiagram -->
</bpmn:definitions>
```

| Prefix | Namespace URI | Purpose |
|---|---|---|
| `bpmn` | `http://www.omg.org/spec/BPMN/20100524/MODEL` | process semantics |
| `bpmndi` | `http://www.omg.org/spec/BPMN/20100524/DI` | diagram shapes/edges |
| `dc` | `http://www.omg.org/spec/DD/20100524/DC` | `Bounds`, `Font` (geometry primitives) |
| `di` | `http://www.omg.org/spec/DD/20100524/DI` | `waypoint`, base diagram interfaces |
| `xsi` | `http://www.w3.org/2001/XMLSchema-instance` | `xsi:type` on formal expressions |

Optional extension namespaces:
```xml
xmlns:camunda="http://camunda.org/schema/1.0/bpmn"
xmlns:zeebe="http://camunda.org/schema/zeebe/1.0"
xmlns:bioc="http://bpmn.io/schema/bpmn/biocolor/1.0"
xmlns:color="http://www.omg.org/spec/BPMN/non-normative/color/1.0"
```

Note the model and DI URIs both carry the `20100524` token — that is the BPMN 2.0 DI revision date, not a typo; it does not change between BPMN 2.0.0 and 2.0.2.

### process
The container for flow elements. `isExecutable="true"` marks it for an engine.
```xml
<bpmn:process id="Process_Order" name="Order Fulfilment" isExecutable="true">
  <!-- events, tasks, gateways, sequenceFlows, lanes, data -->
</bpmn:process>
```

### Events
Events use `<bpmn:*Event>` and become "typed" by an inner event definition.
```xml
<bpmn:startEvent            id="Start_1"  name="Order received"/>
<bpmn:endEvent              id="End_1"    name="Order shipped"/>
<bpmn:intermediateCatchEvent id="Catch_1" name="Await payment"/>
<bpmn:intermediateThrowEvent id="Throw_1" name="Notify"/>
<bpmn:boundaryEvent id="Bnd_1" name="Timeout" attachedToRef="Task_Pay"
                    cancelActivity="true"/>
```
Event definitions (children of the event element) make an event a message/timer/error/signal/conditional event:
```xml
<bpmn:startEvent id="Start_Msg" name="Message in">
  <bpmn:messageEventDefinition id="med_1" messageRef="Msg_1"/>
</bpmn:startEvent>

<bpmn:intermediateCatchEvent id="Timer_1" name="Wait 2 days">
  <bpmn:timerEventDefinition id="ted_1">
    <bpmn:timeDuration xsi:type="bpmn:tFormalExpression">P2D</bpmn:timeDuration>
  </bpmn:timerEventDefinition>
</bpmn:intermediateCatchEvent>

<bpmn:boundaryEvent id="Err_1" attachedToRef="Task_Charge" cancelActivity="true">
  <bpmn:errorEventDefinition id="eed_1" errorRef="Err_Decline"/>
</bpmn:boundaryEvent>

<bpmn:intermediateThrowEvent id="Sig_1" name="Broadcast">
  <bpmn:signalEventDefinition id="sed_1" signalRef="Sig_Ready"/>
</bpmn:intermediateThrowEvent>

<bpmn:intermediateCatchEvent id="Cond_1" name="When stock low">
  <bpmn:conditionalEventDefinition id="ced_1">
    <bpmn:condition xsi:type="bpmn:tFormalExpression">${stock &lt; 10}</bpmn:condition>
  </bpmn:conditionalEventDefinition>
</bpmn:intermediateCatchEvent>
```
`boundaryEvent` attaches to an activity via `attachedToRef`; `cancelActivity="true"` = interrupting, `="false"` = non-interrupting. Referenced `messageRef`/`errorRef`/`signalRef` point at top-level `bpmn:message`/`bpmn:error`/`bpmn:signal` declarations inside `definitions`.

### Activities
```xml
<bpmn:task              id="T1"  name="Do work"/>
<bpmn:userTask          id="T2"  name="Review claim"/>
<bpmn:serviceTask       id="T3"  name="Charge card"/>
<bpmn:scriptTask        id="T4"  name="Compute total"/>
<bpmn:manualTask        id="T5"  name="Pack box"/>
<bpmn:businessRuleTask  id="T6"  name="Assess risk"/>
<bpmn:sendTask          id="T7"  name="Send invoice"/>
<bpmn:receiveTask       id="T8"  name="Await confirmation"/>
<bpmn:callActivity      id="T9"  name="Fulfil sub-order" calledElement="Process_Sub"/>
```
Subprocess and transaction contain their own flow elements:
```xml
<bpmn:subProcess id="Sub_1" name="Handle payment">
  <bpmn:startEvent id="s_1"/>
  <bpmn:task       id="s_t1" name="Authorize"/>
  <bpmn:endEvent   id="s_e1"/>
  <bpmn:sequenceFlow id="s_f1" sourceRef="s_1"  targetRef="s_t1"/>
  <bpmn:sequenceFlow id="s_f2" sourceRef="s_t1" targetRef="s_e1"/>
</bpmn:subProcess>

<bpmn:transaction id="Tx_1" name="Book & pay">
  <!-- flow elements; compensation/cancel semantics apply -->
</bpmn:transaction>
```
Activity markers (loop / multi-instance) are child elements of the activity:
```xml
<bpmn:userTask id="T_rev" name="Review item">
  <bpmn:multiInstanceLoopCharacteristics isSequential="false"/>
</bpmn:userTask>

<bpmn:task id="T_retry" name="Retry">
  <bpmn:standardLoopCharacteristics/>
</bpmn:task>
```
`isSequential="false"` renders the parallel (‖) multi-instance marker; `true` renders the sequential (≡) marker.

### Gateways
```xml
<bpmn:exclusiveGateway  id="G1" name="Approved?" default="Flow_reject"/>
<bpmn:parallelGateway   id="G2" name="Fork"/>
<bpmn:inclusiveGateway  id="G3" name="Notify which?"/>
<bpmn:eventBasedGateway id="G4" name="Message or timeout"/>
<bpmn:complexGateway    id="G5" name="Custom join"/>
```
The `default` attribute names the sequence flow taken when no condition matches (valid on exclusive, inclusive, complex gateways, and on activities). An `eventBasedGateway` must be followed only by catch events or receive tasks.

### Connections
`sequenceFlow` wires flow nodes; `conditionExpression` makes a flow conditional:
```xml
<bpmn:sequenceFlow id="Flow_ok" name="approved"
                   sourceRef="G1" targetRef="Task_Ship">
  <bpmn:conditionExpression xsi:type="bpmn:tFormalExpression"
    >${approved == true}</bpmn:conditionExpression>
</bpmn:sequenceFlow>
<bpmn:sequenceFlow id="Flow_reject" sourceRef="G1" targetRef="End_Reject"/>
```
Flow nodes may also carry explicit `<bpmn:incoming>`/`<bpmn:outgoing>` child elements listing flow ids; these are redundant with `sourceRef`/`targetRef` but many tools emit them and bpmn-js tolerates their absence.

### Collaboration, pools, lanes
Pools (`participant`) and message flows live in a `collaboration`; each pool references a `process`. Lanes partition a process's nodes.
```xml
<bpmn:collaboration id="Collab_1">
  <bpmn:participant id="Pool_Cust"  name="Customer" processRef="Process_Cust"/>
  <bpmn:participant id="Pool_Shop"  name="Shop"     processRef="Process_Order"/>
  <bpmn:messageFlow id="MF_1" name="Order"
                    sourceRef="Task_Place" targetRef="Start_1"/>
</bpmn:collaboration>

<bpmn:process id="Process_Order" isExecutable="true">
  <bpmn:laneSet id="LaneSet_1">
    <bpmn:lane id="Lane_Sales" name="Sales">
      <bpmn:flowNodeRef>Start_1</bpmn:flowNodeRef>
      <bpmn:flowNodeRef>Task_Ship</bpmn:flowNodeRef>
    </bpmn:lane>
  </bpmn:laneSet>
  <!-- flow elements -->
</bpmn:process>
```
`messageFlow` crosses pool boundaries (dashed); `sequenceFlow` never does. Lane membership is by `flowNodeRef` id, not containment.

### Data
```xml
<bpmn:dataObjectReference id="DOR_1" name="Order" dataObjectRef="DO_1"/>
<bpmn:dataObject          id="DO_1"/>
<bpmn:dataStoreReference  id="DS_1"  name="Order DB"/>
<!-- associate data to an activity -->
<bpmn:dataInputAssociation id="dia_1">
  <bpmn:sourceRef>DOR_1</bpmn:sourceRef>
</bpmn:dataInputAssociation>
```

## Diagram/Output Types (element surface summary)
- **Events**: start, end, intermediate catch/throw, boundary; typed by message/timer/error/signal/conditional/escalation/compensate/link/terminate event definitions.
- **Activities**: task, userTask, serviceTask, scriptTask, manualTask, businessRuleTask, sendTask, receiveTask, subProcess, callActivity, transaction, adHocSubProcess; loop & multi-instance markers.
- **Gateways**: exclusive, parallel, inclusive, eventBased, complex.
- **Connections**: sequenceFlow, messageFlow, association, dataInput/OutputAssociation.
- **Swimlanes**: collaboration, participant (pool), laneSet, lane.
- **Data**: dataObject(+Reference), dataStoreReference, property.
- **Diagram interchange**: BPMNDiagram, BPMNPlane, BPMNShape, BPMNEdge, BPMNLabel.

## How-To (worked recipes)

### How to build a linear process (start → task → end) that actually renders
```xml
<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions
    xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
    xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
    xmlns:dc="http://www.omg.org/spec/DD/20100524/DC"
    xmlns:di="http://www.omg.org/spec/DD/20100524/DI"
    id="Definitions_1" targetNamespace="http://bpmn.io/schema/bpmn">
  <bpmn:process id="Process_1" isExecutable="true">
    <bpmn:startEvent id="Start_1" name="Order received">
      <bpmn:outgoing>Flow_1</bpmn:outgoing>
    </bpmn:startEvent>
    <bpmn:userTask id="Task_1" name="Process order">
      <bpmn:incoming>Flow_1</bpmn:incoming>
      <bpmn:outgoing>Flow_2</bpmn:outgoing>
    </bpmn:userTask>
    <bpmn:endEvent id="End_1" name="Done">
      <bpmn:incoming>Flow_2</bpmn:incoming>
    </bpmn:endEvent>
    <bpmn:sequenceFlow id="Flow_1" sourceRef="Start_1" targetRef="Task_1"/>
    <bpmn:sequenceFlow id="Flow_2" sourceRef="Task_1"  targetRef="End_1"/>
  </bpmn:process>
  <bpmndi:BPMNDiagram id="Diagram_1">
    <bpmndi:BPMNPlane id="Plane_1" bpmnElement="Process_1">
      <bpmndi:BPMNShape id="Start_1_di" bpmnElement="Start_1">
        <dc:Bounds x="160" y="100" width="36" height="36"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Task_1_di" bpmnElement="Task_1">
        <dc:Bounds x="250" y="78" width="100" height="80"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="End_1_di" bpmnElement="End_1">
        <dc:Bounds x="410" y="100" width="36" height="36"/>
      </bpmndi:BPMNShape>
      <bpmndi:BPMNEdge id="Flow_1_di" bpmnElement="Flow_1">
        <di:waypoint x="196" y="118"/>
        <di:waypoint x="250" y="118"/>
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_2_di" bpmnElement="Flow_2">
        <di:waypoint x="350" y="118"/>
        <di:waypoint x="410" y="118"/>
      </bpmndi:BPMNEdge>
    </bpmndi:BPMNPlane>
  </bpmndi:BPMNDiagram>
</bpmn:definitions>
```
Every `bpmnElement` in the DI section references a model id; every model node has one shape, every flow one edge. Without the `bpmndi:` block, engines can still execute the process but bpmn-js renders nothing.

### How to add a decision (exclusive gateway with conditions + default)
```xml
<bpmn:exclusiveGateway id="Gw_1" name="Amount &gt; 1000?" default="Flow_small"/>
<bpmn:sequenceFlow id="Flow_big" name="yes" sourceRef="Gw_1" targetRef="Task_Manual">
  <bpmn:conditionExpression xsi:type="bpmn:tFormalExpression"
    >${amount &gt; 1000}</bpmn:conditionExpression>
</bpmn:sequenceFlow>
<bpmn:sequenceFlow id="Flow_small" name="no" sourceRef="Gw_1" targetRef="Task_Auto"/>
```
`default` names the fallback flow; note `&gt;` — `>` must be escaped inside XML text.

### How to model two pools exchanging a message
```xml
<bpmn:collaboration id="Collab_1">
  <bpmn:participant id="Pool_A" name="Customer" processRef="Proc_A"/>
  <bpmn:participant id="Pool_B" name="Shop"     processRef="Proc_B"/>
  <bpmn:messageFlow id="MF_1" name="Place order"
                    sourceRef="Send_A" targetRef="Start_B"/>
</bpmn:collaboration>
<bpmn:process id="Proc_A" isExecutable="false">
  <bpmn:startEvent id="Start_A"/>
  <bpmn:sendTask   id="Send_A" name="Send order"/>
  <bpmn:sequenceFlow id="fa1" sourceRef="Start_A" targetRef="Send_A"/>
</bpmn:process>
<bpmn:process id="Proc_B" isExecutable="true">
  <bpmn:startEvent id="Start_B" name="Order in"/>
</bpmn:process>
```
In the DI, pools are `BPMNShape` with `isHorizontal="true"` and large bounds; the message flow gets a `BPMNEdge`.

### How to control appearance — Diagram Interchange & colors (mandatory)
Appearance in BPMN is entirely in the `bpmndi:` section. Geometry is standard; **colors** are a widely-supported extension used by bpmn.io and Camunda Modeler via two parallel attribute pairs on `BPMNShape`/`BPMNEdge`:
- `color:background-color` / `color:border-color` (OMG non-normative color namespace) — the portable, current form.
- `bioc:stroke` / `bioc:fill` (bpmn.io legacy) — older Camunda Modeler files; keep both for max compatibility.

```xml
<bpmn:definitions
    xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
    xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
    xmlns:dc="http://www.omg.org/spec/DD/20100524/DC"
    xmlns:di="http://www.omg.org/spec/DD/20100524/DI"
    xmlns:bioc="http://bpmn.io/schema/bpmn/biocolor/1.0"
    xmlns:color="http://www.omg.org/spec/BPMN/non-normative/color/1.0"
    id="Definitions_c" targetNamespace="http://bpmn.io/schema/bpmn">
  <bpmn:process id="Process_c" isExecutable="true">
    <bpmn:task id="Task_hot" name="Escalate"/>
  </bpmn:process>
  <bpmndi:BPMNDiagram id="Diagram_c">
    <bpmndi:BPMNPlane id="Plane_c" bpmnElement="Process_c">
      <bpmndi:BPMNShape id="Task_hot_di" bpmnElement="Task_hot"
          bioc:stroke="#E53935" bioc:fill="#FFCDD2"
          color:border-color="#E53935" color:background-color="#FFCDD2">
        <dc:Bounds x="250" y="78" width="100" height="80"/>
        <bpmndi:BPMNLabel>
          <dc:Bounds x="266" y="108" width="68" height="20"/>
        </bpmndi:BPMNLabel>
      </bpmndi:BPMNShape>
    </bpmndi:BPMNPlane>
  </bpmndi:BPMNDiagram>
</bpmn:definitions>
```
`BPMNLabel` with its own `dc:Bounds` positions the element's text; a `dc:Font` inside a `BPMNLabelStyle` (referenced from the plane) sets typography. Line/edge styling for flows uses the same color attributes on `BPMNEdge`. Broad rendering (fonts, exact fills) beyond these color attributes is tool-specific.

## Do's and Don'ts

### ✅ Do
- Always include a `bpmndi:BPMNDiagram` if you want it to render; keep every `bpmnElement` id in sync with the model.
- Declare all five standard namespaces (`bpmn`, `bpmndi`, `dc`, `di`, `xsi`) on `definitions`; add `color:`/`bioc:` only when you set colors.
- Type formal expressions with `xsi:type="bpmn:tFormalExpression"` on `conditionExpression`/`condition`/`timeDuration`.
- Escape `<`, `>`, `&` inside expression text (`&lt;`, `&gt;`, `&amp;`).
- Give exclusive/inclusive/complex gateways a `default` flow so there's always a path out.
- Reference `messageRef`/`errorRef`/`signalRef` to top-level `bpmn:message`/`error`/`signal` declared under `definitions`.
- Emit both `color:` and `bioc:` color attributes for cross-version Camunda/bpmn.io compatibility.

### ❌ Don't
- Don't cross pools with a `sequenceFlow` — inter-pool communication must be a `messageFlow`.
- Don't reference a `bpmnElement` in the DI that doesn't exist in the model (or vice-versa) — bpmn-js drops the shape and may error.
- Don't attach a `boundaryEvent` without `attachedToRef`, and don't forget `cancelActivity` (defaults to interrupting `true`).
- Don't put an event definition on the wrong event kind (e.g. a `terminateEventDefinition` only makes sense on an end event).
- Don't rely on `<incoming>`/`<outgoing>` alone — the authoritative wiring is `sequenceFlow`'s `sourceRef`/`targetRef`.
- Don't leave a node with no shape when a diagram exists — half-laid-out diagrams render inconsistently.
- Don't hardcode absolute pixel colors on the model elements — color belongs on the DI shape/edge, never on `bpmn:task` itself.

## Styling, Theming & Customization
- **Layout**: `dc:Bounds x/y/width/height` per `BPMNShape`; `di:waypoint x/y` list per `BPMNEdge` (2+ points).
- **Color**: `color:background-color`/`color:border-color` (+ legacy `bioc:fill`/`bioc:stroke`) on shapes and edges.
- **Labels**: `BPMNLabel` + `dc:Bounds` for position; `BPMNLabelStyle` + `dc:Font` (referenced by `labelStyle`) for typography.
- **Pools**: `BPMNShape isHorizontal="true"` with tall bounds; lanes are child shapes.
- **CSS (bpmn-js only)**: at render time you can also skin via `.djs-*` classes and custom renderers, but that lives in the host app, not the XML.

## Advanced Features
- **Engine extensions**: `bpmn:extensionElements` hosting `camunda:*` (Camunda 7) or `zeebe:*` (Camunda 8) — form fields, task listeners, IO mappings, job types. These drive execution but are ignored by pure viewers.
- **Multi-instance & compensation**: `multiInstanceLoopCharacteristics` (with `loopCardinality`, `completionCondition`), `compensateEventDefinition`, `transaction` cancel semantics.
- **Call activity / reusable subprocess**: `callActivity calledElement="..."` invokes another process by id.
- **Escalation / link / terminate**: `escalationEventDefinition`, `linkEventDefinition` (paired throw/catch by name), `terminateEventDefinition` (ends the whole process instance).
- **Round-trip**: `bpmn-moddle` reads and rewrites the XML preserving unknown extension elements.

## Common Pitfalls & Troubleshooting
- **Renders blank in bpmn-js**: missing or mismatched `bpmndi:` section — every node needs a `BPMNShape`, every flow a `BPMNEdge`, ids matching the model.
- **"no diagram to display"**: the `BPMNPlane bpmnElement` must reference a `process` or `collaboration` id that exists.
- **Broken parse on expressions**: unescaped `<`/`>`/`&` in `conditionExpression`; wrap logic in `${...}` and escape entities.
- **Colors ignored**: consumer predates the color namespace, or only one of `color:`/`bioc:` present — emit both.
- **Boundary event floats free**: `attachedToRef` missing or pointing at a non-activity.
- **Message flow rejected**: `messageFlow` declared inside a `process` instead of the `collaboration`.
- **Namespace token confusion**: the `20100524` in model and DI URIs is correct for all of BPMN 2.0.x; don't "modernize" it.
- **`default` flow still evaluated**: the default flow must **not** carry a `conditionExpression`; if it does, it's treated as a normal conditional flow.

## Integration Notes
- **bpmn-js / bpmn.io** is the reference renderer; if it imports cleanly, the file is well-formed and refs resolve.
- **Camunda Modeler** is the most common authoring tool and the source of `bioc:`/`color:` and `camunda:`/`zeebe:` attributes.
- **Engines** (Camunda, Flowable, Activiti, jBPM) execute the same file; a viewer ignores the execution extensions and an engine ignores pure-visual DI.
- Not interchangeable with UML/XMI — BPMN and UML are distinct OMG serializations though they share the `dc`/`di` Diagram Interchange foundation (see uml-xmi.md).

## Best For / Avoid For
`business-processes`, `workflow-automation`, `executable-workflows`, `enterprise-integration`, `compliance-documentation` — choose BPMN when the process must be both **drawn and executed** by standard tooling.

Avoid for: quick conceptual flowcharts (Mermaid `flowchart` is far lighter), software architecture (C4/Structurizr), or class/data models (UML/XMI). BPMN's verbosity only pays off when engine execution or formal process semantics matter.

## See Also
- [uml-xmi.md](uml-xmi.md) — sibling OMG XML interchange (UML models); shares the `dc`/`di` foundation
- [mermaid.md](mermaid.md) — lightweight `flowchart`/`stateDiagram` when you only need a picture
- [plantuml.md](plantuml.md) — text UML incl. activity diagrams
- [c4-plantuml.md](c4-plantuml.md) — C4 architecture diagrams
- [structurizr-dsl.md](structurizr-dsl.md) — model-as-code architecture DSL
- [../use-case/diagram-generation.md](../use-case/diagram-generation.md) — choosing a diagram/process format for a task
