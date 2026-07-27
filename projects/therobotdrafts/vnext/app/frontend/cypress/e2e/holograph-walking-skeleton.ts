/// <reference types="cypress" />

import {
  Given,
  Then,
  When,
} from "@badeball/cypress-cucumber-preprocessor";
import walkingSkeleton from "../../../../fixtures/holograph-m0-m1-walking-skeleton.graph-document.json";
import { dismissCookieBanner } from "../support/consent";

/** The element the scenario selects, focuses, and inspects. */
const SUBJECT_LABEL = "Uml3DScene";

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

/** Mirrors riskBandFor in src/lib/holograph/analysis.ts. */
function riskBand(value: number) {
  if (value >= 60) return "high";
  if (value >= 35) return "medium";
  return "low";
}

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

  requireNode("RobotDraftModel");
  requireNode("UmlNode3D");
  requireNode("UmlEdge3D");
  requireNode("PatchReviewService");
  requireNode("PlantUmlExporter");
  requireNode(SUBJECT_LABEL);
}

/** Open the Outline tab and click the row for a model element. */
function selectOutlineNode(label: string) {
  cy.contains(".trd-tab", "Outline").click();
  cy.get("[aria-label='Outline']").contains("button", label).click();
}

Given("the canonical HoloGraph walking skeleton fixture is available from the workspace document store", () => {
  assertGraphDocumentShape();

  // Logged out, the workspace binds to the browser-local DocStore, which serves this same
  // bundled fixture. The cloud document API is spied on so the scenario can prove the
  // anonymous path never reaches for it; a signed-in session gets that store instead.
  cy.intercept("GET", "**/api/v1/projects/*/docs").as("cloudDocumentList");
});

When("I open the HoloGraph workspace", () => {
  // A previous run's autosave would pre-empt the fixture load under test.
  cy.clearLocalStorage();
  cy.visit("/studio");
  dismissCookieBanner();

  // The Files tab lists every model the document store knows about; opening the fixture
  // from there is the workspace's real load path.
  cy.contains(".trd-tab", "Files").click();
  cy.get("[aria-label='Files']")
    .contains("button", graphDocument.slug)
    .should("be.visible")
    .click();
  cy.get("[aria-label='Workspace status']").should("contain", graphDocument.slug);
});

Then("the imported HoloGraph document should render", () => {
  cy.get("@cloudDocumentList.all").should("have.length", 0);
  cy.get(".trd-shell").should("be.visible");
  cy.get(".trd-three-scene").should("be.visible");
  cy.get("[aria-label='Workspace status']").within(() => {
    cy.contains(graphDocument.slug).should("be.visible");
    cy.contains(`v${graphDocument.version}`).should("be.visible");
  });

  cy.contains(".trd-tab", "Outline").click();
  cy.get("[aria-label='Outline']").within(() => {
    cy.contains("button", "UmlEdge3D").should("exist");
    cy.contains("button", "PatchReviewService").should("exist");
    cy.contains("button", SUBJECT_LABEL).should("exist");
  });
});

When("I select the Uml3DScene node", () => {
  selectOutlineNode(SUBJECT_LABEL);
});

Then("the Uml3DScene details should be shown", () => {
  const node = requireNode(SUBJECT_LABEL);

  cy.get("[aria-label='Inspector panel']").within(() => {
    cy.get("[aria-label='Element name']").should("have.value", node.label);
    cy.contains("label", "Package").should("exist");
    // Metrics section is collapsed by default; open it to read the risk band.
    cy.contains("button", "Metrics").click();
    cy.contains("label", `Risk — ${riskBand(node.metrics.risk)}`).should("exist");
  });

  cy.get("[aria-label='Workspace status']").contains(`${node.label} selected`).should("be.visible");
});

When("I focus the selected HoloGraph node", () => {
  cy.get("[title='Camera Controls (⇧⌘C)']").should("exist");
  cy.contains(".trd-menu > button", "Go").click();
  cy.contains(".trd-mi", "Frame Selected").click();
});

Then("the workspace should be focused on Uml3DScene", () => {
  cy.get(".trd-hint").should("contain", `Framed ${SUBJECT_LABEL}`);
  cy.get("[aria-label='Workspace status']").contains(`${SUBJECT_LABEL} selected`).should("be.visible");
});

When("I recenter the HoloGraph workspace", () => {
  cy.contains(".trd-menu > button", "Go").click();
  cy.contains(".trd-mi", "Frame All").click();
});

Then("the whole-system HoloGraph overview should be shown", () => {
  cy.get(".trd-hint").should("contain", "Framed the whole model");
  cy.contains(".trd-tab", "Outline").click();
  cy.get("[aria-label='Outline']").within(() => {
    cy.contains("button", "UmlEdge3D").should("exist");
    cy.contains("button", "PatchReviewService").should("exist");
  });
});
