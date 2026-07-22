import assert from "node:assert/strict";
import {
  exportCodeSkeleton,
  exportDot,
  exportMermaid,
  exportPlantUml,
  importCodeFiles,
  importPlantUml,
  readGraphDocumentJson,
} from "./document-io";

const plantUml = [
  "@startuml",
  "title Payment Core",
  "package Billing",
  "class Invoice",
  "interface Payable",
  "Invoice ..> Payable : realizes",
  "@enduml",
].join("\n");

const plantDocument = importPlantUml(plantUml, "payment-core.puml");
assert.equal(plantDocument.title, "Payment Core");
assert.ok(plantDocument.nodes.some((node) => node.label === "Invoice"));
assert.ok(plantDocument.nodes.some((node) => node.kind === "interface"));
assert.ok(plantDocument.edges.length >= 1);

const codeDocument = importCodeFiles([
  {
    name: "OrderService.cs",
    text: "namespace Demo; public interface IOrderPort {} public class OrderService {}",
  },
]);
assert.equal(codeDocument.title, "Imported Codebase");
assert.ok(codeDocument.nodes.some((node) => node.label === "OrderService"));
assert.ok(codeDocument.edges.some((edge) => edge.kind === "contains"));

const jsonRoundTrip = readGraphDocumentJson(JSON.stringify(codeDocument));
assert.equal(jsonRoundTrip.nodes.length, codeDocument.nodes.length);

assert.match(exportPlantUml(plantDocument), /@startuml/);
assert.match(exportMermaid(plantDocument), /classDiagram/);
assert.match(exportDot(plantDocument), /digraph/);
assert.match(exportCodeSkeleton(codeDocument), /class OrderService/);

// Expanded PlantUML parsing: packages, members, visibility, inheritance, realization,
// composition, aggregation, multiplicity, implicit endpoint declaration.
const richPlantUml = [
  "@startuml",
  "title Rich Model",
  "package Billing {",
  "  class Invoice {",
  "    + id : Guid",
  "    - total : Money",
  "    + settle(amount : Money) : Receipt",
  "  }",
  "  interface Payable",
  "}",
  "class LineItem",
  "Invoice ..|> Payable",
  "Invoice *-- LineItem",
  "Customer <|-- VipCustomer",
  'Invoice "1" o-- "0..*" Note : annotations',
  "@enduml",
].join("\n");

const richDocument = importPlantUml(richPlantUml, "rich.puml");
const byLabel = (label: string) => richDocument.nodes.find((node) => node.label === label);
const byRelationship = (relationship: string) =>
  richDocument.edges.find((edge) => edge.uml?.relationship === relationship);

const billing = byLabel("Billing");
const invoice = byLabel("Invoice");
assert.ok(billing && billing.kind === "package");
assert.ok(invoice);
assert.equal(invoice?.parentId, billing?.id);
assert.equal(invoice?.packageName, "Billing");
assert.deepEqual(invoice?.uml?.attributes, ["+ id : Guid", "- total : Money"]);
assert.deepEqual(invoice?.uml?.operations, ["+ settle(amount : Money) : Receipt"]);
assert.ok(
  richDocument.edges.some(
    (edge) => edge.kind === "contains" && edge.sourceId === billing?.id && edge.targetId === invoice?.id,
  ),
);

const realization = byRelationship("realization");
assert.ok(realization?.uml?.dashed);
assert.equal(realization?.sourceId, invoice?.id);
assert.equal(realization?.targetId, byLabel("Payable")?.id);

const composition = byRelationship("composition");
assert.equal(composition?.sourceId, invoice?.id);
assert.equal(composition?.targetId, byLabel("LineItem")?.id);

// Customer/VipCustomer are only referenced by the edge; both are implicitly declared,
// and the triangle points at the parent so the edge runs child -> parent.
const generalization = byRelationship("generalization");
assert.equal(generalization?.sourceId, byLabel("VipCustomer")?.id);
assert.equal(generalization?.targetId, byLabel("Customer")?.id);

const aggregation = byRelationship("aggregation");
assert.equal(aggregation?.uml?.sourceMultiplicity, "1");
assert.equal(aggregation?.uml?.targetMultiplicity, "0..*");
assert.equal(aggregation?.label, "annotations");

// Language-selectable code skeletons.
assert.match(exportCodeSkeleton(richDocument, "typescript"), /export class Invoice \{/);
assert.match(exportCodeSkeleton(richDocument, "typescript"), /export interface Payable \{/);
assert.match(exportCodeSkeleton(richDocument, "python"), /class Invoice:/);
assert.match(exportCodeSkeleton(richDocument, "java"), /public class Invoice \{/);
assert.match(exportCodeSkeleton(richDocument, "go"), /type Invoice struct \{/);
assert.match(exportCodeSkeleton(richDocument), /public class Invoice/);

console.log("holograph document-io tests passed");
