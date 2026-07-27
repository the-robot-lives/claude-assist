/// <reference types="cypress" />

import { Then, When } from "@badeball/cypress-cucumber-preprocessor";
import { dismissCookieBanner } from "../support/consent";

When("I open the public landing page", () => {
  cy.visit("/");
  dismissCookieBanner();
});

Then("the product pitch and hero illustration should be shown", () => {
  // The landing page is marketing only: the workspace shell lives at /studio now.
  cy.get(".trd-shell").should("not.exist");

  cy.get(".trd-landing__title").should("contain", "The Robot Drafts");
  cy.get(".trd-landing__pitch").should("contain", "3D scene");
  cy.get(".trd-landing__mock svg").should("be.visible");
  cy.get(".trd-landing__card").should("have.length", 4);
});

Then("the landing page should offer the studio, sign-in, and sign-up entry points", () => {
  cy.get('.trd-landing a[href="/studio"]').should("have.length.at.least", 1);
  cy.get('.trd-landing__cta-row a[href="/studio"]').should("contain", "Open Studio");
  cy.get('.trd-landing__cta-row a[href="/login"]').should("contain", "Sign in");
  cy.get('.trd-landing__cta-row a[href="/signup"]').should("contain", "Sign up");
});
