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

console.log("holograph document-io tests passed");
