/// <reference types="cypress" />

import {
  Given,
  Then,
  When,
} from "@badeball/cypress-cucumber-preprocessor";
import walkingSkeleton from "../../../../fixtures/holograph-m0-m1-walking-skeleton.graph-document.json";

interface GraphDocumentFixture {
  id: string;
  slug: string;
  title: string;
  version: number;
  updatedAt: string;
  summary: string;
  nodes: Array<{
    id: string;
    label: string;
    kind: string;
    description: string;
    metrics: {
      complexity: number;
      churn: number;
      risk: number;
    };
    parentId?: string;
    packageName?: string;
    members?: string[];
    status?: string;
  }>;
  edges: Array<{
    id: string;
    sourceId: string;
    targetId: string;
    kind: string;
    label: string;
  }>;
}

const graphDocument = walkingSkeleton as GraphDocumentFixture;

function requireNode(label: string) {
  const node = graphDocument.nodes.find((candidate) => candidate.label === label);
  expect(node, `fixture node labelled ${label}`).to.exist;
  return node!;
}

function assertGraphDocumentShape() {
  expect(graphDocument.id).to.equal("trd-demo");
  expect(graphDocument.nodes.length).to.be.greaterThan(5);
  expect(graphDocument.edges.length).to.be.greaterThan(5);

  const nodeIds = new Set(graphDocument.nodes.map((node) => node.id));
  for (const edge of graphDocument.edges) {
    expect(nodeIds.has(edge.sourceId), `${edge.id} source exists`).to.equal(true);
    expect(nodeIds.has(edge.targetId), `${edge.id} target exists`).to.equal(true);
  }

  requireNode("M0 Contract Lane");
  requireNode("M0 Import Lane");
  requireNode("M1 Render Lane");
  requireNode("M1 Interaction Lane");
  requireNode("M1 QA Lane");
  requireNode("Renderer Bridge");
}

Given("the canonical HoloGraph walking skeleton fixture is available from the document API", () => {
  assertGraphDocumentShape();

  cy.intercept("GET", "**/api/v1/docs/trd-demo", {
    statusCode: 200,
    body: { data: graphDocument },
  }).as("loadHolographDocument");
});

When("I open the HoloGraph workspace", () => {
  cy.visit("/");
  cy.wait("@loadHolographDocument").its("response.statusCode").should("eq", 200);
});

Then("the imported HoloGraph document should render", () => {
  cy.contains("h1", "HoloGraph workspace").should("be.visible");
  cy.contains("span", `v${graphDocument.version}`).should("be.visible");
  cy.contains("span", `${graphDocument.nodes.length} nodes`).should("be.visible");
  cy.contains("span", `${graphDocument.edges.length} edges`).should("be.visible");
  cy.contains("span", "Loaded /api/v1/docs/trd-demo").should("be.visible");
  cy.get(".hg-canvas").should("be.visible");
  cy.get("[aria-label='Select M0 Import Lane']").should("exist");
  cy.get("[aria-label='Select M1 Render Lane']").should("exist");
  cy.get("[aria-label='Select Renderer Bridge']").should("exist");
});

When("I select the Renderer Bridge node", () => {
  cy.get("[aria-label='Select Renderer Bridge']").click({ force: true });
});

Then("the Renderer Bridge details should be shown", () => {
  const node = requireNode("Renderer Bridge");

  cy.get("[aria-label='Selection detail panel']").within(() => {
    cy.contains("h2", node.label).should("be.visible");
    cy.contains(node.description).should("be.visible");
    cy.contains("li", "aria-label Select").should("be.visible");
    cy.contains("dd", `${node.metrics.risk} - low`).should("be.visible");
  });
});

When("I focus the selected HoloGraph node", () => {
  cy.contains("button", "Focus selected").click();
});

Then("the workspace should be focused on Renderer Bridge", () => {
  cy.contains("strong", "Focused: Renderer Bridge").should("be.visible");
  cy.contains("span", "Focused Renderer Bridge").should("be.visible");
  cy.get("[aria-label='Select Renderer Bridge']").should("exist");
});

When("I recenter the HoloGraph workspace", () => {
  cy.contains("button", "Recenter").click();
});

Then("the whole-system HoloGraph overview should be shown", () => {
  cy.contains("strong", "Whole system").should("be.visible");
  cy.contains("span", "Recentered to whole-system overview").should("be.visible");
  cy.get("[aria-label='Select M0 Import Lane']").should("exist");
  cy.get("[aria-label='Select M1 Render Lane']").should("exist");
});
