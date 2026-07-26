/// <reference types="cypress" />

/** Clear the first-visit consent bar so it cannot overlay the page under test. */
export function dismissCookieBanner() {
  cy.contains("button", "Reject optional", { timeout: 10_000 }).click({ force: true });
  cy.get(".cookie-consent").should("not.exist");
}
