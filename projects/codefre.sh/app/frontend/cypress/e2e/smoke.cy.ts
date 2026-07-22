const DEV_INVITE_TOKEN = "dev-bootstrap-invite-token-do-not-use-in-prod";
const PASSWORD = "password123";
const CONSENT_STORAGE_KEY = "start-app.cookie-consent.v1";

function visitWithConsent(path: string): void {
  cy.visit(path, {
    onBeforeLoad(win) {
      win.localStorage.setItem(
        CONSENT_STORAGE_KEY,
        JSON.stringify({
          version: 1,
          categories: {
            necessary: true,
            analytics: false,
            marketing: false,
            preferences: false,
          },
          acceptedAt: "2026-01-01T00:00:00.000Z",
          updatedAt: "2026-01-01T00:00:00.000Z",
        })
      );
    },
  });
}

function uniqueEmail(prefix: string): string {
  return `${prefix}-${Date.now()}-${Cypress._.random(1000, 9999)}@example.test`;
}

describe("auth smoke", () => {
  it("rejects an invalid password login", () => {
    visitWithConsent("/login");
    cy.pair("auth-card", "login").should("be.visible");
    cy.getByCy("email-input").type("admin@starter.local");
    cy.getByCy("password-input").type("not-the-password");
    cy.getByCy("submit-login").click();
    cy.getByCy("auth-error").should("be.visible");
  });

  it("logs in with seeded development credentials", () => {
    visitWithConsent("/login");
    cy.getByCy("email-input").type("admin@starter.local");
    cy.getByCy("password-input").type(PASSWORD);
    cy.getByCy("submit-login").click();

    cy.location("pathname", { timeout: 12000 }).should("match", /^\/app(\/|$)/);
    cy.window().its("localStorage.access_token").should("be.a", "string").and("not.be.empty");
  });

  it("rejects signup without a valid invite", () => {
    visitWithConsent("/signup");
    cy.pair("auth-card", "signup").should("be.visible");
    cy.getByCy("invite-token-input").type("invalid-invite-token");
    cy.getByCy("email-input").type(uniqueEmail("bad-invite"));
    cy.getByCy("password-input").type(PASSWORD);
    cy.getByCy("submit-signup").click();
    cy.getByCy("auth-error").should("be.visible");
  });

  it("signs up with the development bootstrap invite", () => {
    visitWithConsent("/signup");
    cy.getByCy("invite-token-input").type(DEV_INVITE_TOKEN);
    cy.getByCy("email-input").type(uniqueEmail("invite"));
    cy.getByCy("password-input").type(PASSWORD);
    cy.getByCy("submit-signup").click();

    cy.location("pathname", { timeout: 12000 }).should("match", /^\/app(\/|$)/);
    cy.window().its("localStorage.access_token").should("be.a", "string").and("not.be.empty");
  });
});
