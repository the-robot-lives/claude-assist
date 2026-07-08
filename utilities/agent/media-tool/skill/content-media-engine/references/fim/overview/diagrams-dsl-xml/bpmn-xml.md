# BPMN XML

## What
BPMN XML is the Business Process Model and Notation XML format (OMG specification) for executable process diagrams. Beyond visualization, its diagrams can be executed by BPMN engines, and it is consumed by web viewers, desktop modelers, and Node.js parsing libraries.

## How
- The LLM emits BPMN XML — a `<definitions>` root containing a `<process>` with `startEvent`, `userTask`, `endEvent`, and `sequenceFlow` elements wiring the flow via `sourceRef`/`targetRef`.
- That XML is turned into a viewable/executable artifact via `bpmn-js` for web visualization (`npm install bpmn-js`), the Camunda Modeler desktop app, or `bpmn-moddle` for Node.js parsing/manipulation; executable processes run on engines like Camunda, Activiti, or jBPM.
- Typical final artifact: a rendered process diagram in a web/desktop viewer, and/or an executable `.bpmn` file deployed to a workflow engine.

## Why
- Reach for BPMN XML when the process needs to be both documented and executed to an industry standard — best for `business-processes`, `workflow-automation`, `enterprise-integration`, `compliance-documentation`, and `executable-workflows`.
- Limitations: verbose XML structure, overkill for simple diagrams, requires specialized tools for editing, and a steep learning curve for the full specification.
- Relative to the other XML/UML siblings here: BPMN is process/workflow-specific with execution semantics (gateways, subprocesses, events), not a general UML or architecture notation.

## Source
- Solution reference: `fim/solution/bpmn-xml.md`
