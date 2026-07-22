import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { exportTrdYaml, importTrdYaml, looksLikeTrdYaml } from "./trd-yaml";

// Inline sample mirroring the Unity/C# writer output (TrdYamlWriter.cs).
const sample = [
  "# .trd-yaml — TheRobotDrafts native model (IxModel serialization)",
  "name: Example Class Diagram - Simple Banking Domain",
  "elements:",
  "  - { id: Billing, type: Package, name: Billing }",
  "  - { id: Customer, type: Class, name: Customer, parentId: Billing, members: [{ name: customerId, isOperation: false, visibility: Private, type: String, rawText: '-customerId: String' }, { name: register, isOperation: true, visibility: Public, type: void, rawText: '+register(): void' }] }",
  "  - { id: Account, type: Class, name: Account, isAbstract: true, members: [{ name: deposit, isOperation: true, visibility: Public, type: Boolean, params: [{ name: amount, type: Decimal }], rawText: '+deposit(amount: Decimal): Boolean' }] }",
  "  - { id: SavingsAccount, type: Class, name: SavingsAccount }",
  "edges:",
  "  - { id: e1, type: DirectedAssociation, from: Customer, to: Account, label: owns, fromMultiplicity: 1, toMultiplicity: '*' }",
  "  - { id: e3, type: Generalization, from: SavingsAccount, to: Account, label: extends }",
  "diagrams:",
  "  - { id: d1, name: Example Class Diagram - Simple Banking Domain, kind: class, layoutProvenance: Synthesized }",
].join("\n");

assert.ok(looksLikeTrdYaml(sample));
assert.ok(looksLikeTrdYaml("", "model.trd-yaml"));
assert.ok(!looksLikeTrdYaml('{"id":"x"}', "model.trd.json"));

const document = importTrdYaml(sample, "banking.trd-yaml");
assert.equal(document.title, "Example Class Diagram - Simple Banking Domain");

const customer = document.nodes.find((node) => node.label === "Customer");
const account = document.nodes.find((node) => node.label === "Account");
const billing = document.nodes.find((node) => node.label === "Billing");
assert.ok(billing && billing.kind === "package");
assert.equal(customer?.parentId, "Billing");
assert.deepEqual(customer?.uml?.attributes, ["-customerId: String"]);
assert.deepEqual(customer?.uml?.operations, ["+register(): void"]);
assert.ok(account?.uml?.abstract);
assert.deepEqual(account?.uml?.operations, ["+deposit(amount: Decimal): Boolean"]);

// parentId containment materializes as a contains edge for the 3D scene.
assert.ok(document.edges.some((edge) => edge.kind === "contains" && edge.sourceId === "Billing" && edge.targetId === "Customer"));

const association = document.edges.find((edge) => edge.uml?.relationship === "association");
assert.equal(association?.uml?.sourceMultiplicity, "1");
assert.equal(association?.uml?.targetMultiplicity, "*");
const generalization = document.edges.find((edge) => edge.uml?.relationship === "generalization");
assert.equal(generalization?.sourceId, "SavingsAccount");
assert.equal(generalization?.targetId, "Account");

// Writer output re-imports to the same model (round-trip stability), and containment
// stays in parentId (no contains edges emitted).
const exported = exportTrdYaml(document);
assert.ok(exported.startsWith("# .trd-yaml"));
assert.ok(!/type: (?:DirectedAssociation[^\n]*label: contains)/.test(exported));
assert.match(exported, /fromMultiplicity: 1/);
assert.match(exported, /toMultiplicity: '\*'/);
assert.match(exported, /rawText: '-customerId: String'/);
const reimported = importTrdYaml(exported, "roundtrip.trd-yaml");
assert.equal(reimported.nodes.length, document.nodes.length);
assert.equal(reimported.edges.length, document.edges.length);
assert.deepEqual(
  reimported.nodes.map((node) => [node.id, node.kind, node.parentId ?? null, node.uml?.attributes, node.uml?.operations]),
  document.nodes.map((node) => [node.id, node.kind, node.parentId ?? null, node.uml?.attributes, node.uml?.operations]),
);

// Against the real Unity-authored sample when running inside the monorepo
// (test is expected to run from vnext/app/frontend).
const realSample = resolve(
  process.cwd(),
  "../../../docs/diagrams/tier1-codereverse/class-diagram/simple-banking-domain.trd-yaml",
);
if (existsSync(realSample)) {
  const realDocument = importTrdYaml(readFileSync(realSample, "utf8"), "simple-banking-domain.trd-yaml");
  assert.equal(realDocument.nodes.length, 5);
  assert.equal(realDocument.edges.filter((edge) => edge.uml?.relationship === "generalization").length, 2);
  const realCustomer = realDocument.nodes.find((node) => node.label === "Customer");
  assert.equal(realCustomer?.uml?.attributes?.length, 4);
  assert.equal(realCustomer?.uml?.operations?.length, 3);
  const reExported = exportTrdYaml(realDocument);
  const stable = importTrdYaml(reExported, "stable.trd-yaml");
  assert.equal(stable.nodes.length, realDocument.nodes.length);
  assert.equal(stable.edges.length, realDocument.edges.length);
}

console.log("trd-yaml tests passed");
