/// <reference types="cypress" />

import {
  Given,
  Then,
  When,
} from "@badeball/cypress-cucumber-preprocessor";

const pendingUser = {
  id: "user-pending",
  email: "ada@example.com",
  user_name: "ada",
  status: "pending",
  verified: false,
  profile_complete: true,
  requires_profile_completion: false,
};

function passwordEmail() {
  return `ada@${Cypress.env("passwordDomain")}`;
}

function ssoEmail() {
  return `ada@${Cypress.env("ssoDomain")}`;
}

function dismissCookieBanner() {
  cy.contains("button", "Reject optional", { timeout: 10_000 }).click({ force: true });
  cy.get(".cookie-consent").should("not.exist");
}

Given("SSO is configured for the generated app", () => {
  cy.intercept("GET", "**/api/v1/auth/sso/providers", {
    statusCode: 200,
    body: {
      providers: ["oidc"],
      domains: {
        [Cypress.env("ssoDomain")]: ["oidc"],
      },
      domain_policies: {
        [Cypress.env("ssoDomain")]: { providers: ["oidc"], auto_approve: false },
      },
    },
  }).as("ssoProviders");
});

Given("registration will create a pending account", () => {
  cy.intercept("POST", "**/api/v1/auth/register", (req) => {
    req.alias = "register";
    req.reply({
      statusCode: 201,
      body: {
        user: { ...pendingUser, email: req.body?.user?.email },
        organizations: [],
        access_token: "test-access-token",
        refresh_token: "test-refresh-token",
      },
    });
  });
});

Given("SSO exchange returns an incomplete generated app user", () => {
  cy.intercept("POST", "**/api/v1/auth/sso/exchange", {
    statusCode: 200,
    body: {
      user: {
        id: "sso-user",
        email: ssoEmail(),
        user_name: "ada",
        status: "pending",
        verified: true,
        profile_complete: false,
        requires_profile_completion: true,
      },
      organizations: [],
      access_token: "sso-access-token",
      refresh_token: "sso-refresh-token",
    },
  }).as("ssoExchange");
});

When("I open the login page", () => {
  cy.visit("/login");
  dismissCookieBanner();
});

When("I open the signup page", () => {
  cy.visit("/signup");
  dismissCookieBanner();
});

When("I open the generated app home page", () => {
  cy.visit("/");
});

When("I continue with an SSO email", () => {
  cy.get("input[type='email']").first().clear().type(ssoEmail());
  cy.contains("button", "Continue").click();
});

When("I continue signup with a password email", () => {
  cy.get("input[type='email']").first().clear().type(passwordEmail());
  cy.contains("button", "Continue").click();
});

When("I complete password signup with an invite token", () => {
  cy.get("#invite-token").clear().type("INVITE-123");
  cy.get("#email-password").should("have.value", passwordEmail());
  cy.get("#user-name").clear().type("ada");
  cy.get("#first-name").clear().type("Ada");
  cy.get("#last-name").clear().type("Lovelace");
  cy.get("#mobile-phone").clear().type("+15555550123");
  cy.get("#password").clear().type("password123");
  cy.contains("button", "Sign Up").click();
});

When("I return from SSO with a valid code", () => {
  cy.visit("/auth/sso-callback?code=test-sso-code&provider=oidc");
});

When("I reject optional cookies", () => {
  cy.contains("Cookie choices").should("be.visible");
  cy.contains("button", "Reject optional").click();
});

Then("I should see the SSO login option", () => {
  cy.contains("a", "Sign in with SSO").should("be.visible");
});

Then("the password field should not be shown", () => {
  cy.get("input[type='password']").should("not.exist");
});

Then("the registration request should include profile and invite details", () => {
  cy.wait("@register").then(({ request }) => {
    expect(request.body.invite_token).to.equal("INVITE-123");
    expect(request.body.user.email).to.equal(passwordEmail());
    expect(request.body.user.user_name).to.equal("ada");
    expect(request.body.user.first_name).to.equal("Ada");
    expect(request.body.user.last_name).to.equal("Lovelace");
    expect(request.body.user.mobile_phone).to.equal("+15555550123");
  });
});

Then("I should be on the pending approval page", () => {
  cy.location("pathname").should("eq", "/pending-approval");
});

Then("I should be on the complete registration page", () => {
  cy.wait("@ssoExchange").its("response.statusCode").should("eq", 200);
  cy.location("pathname", { timeout: 10_000 }).should("eq", "/complete-registration");
});

Then("the saved cookie preferences should keep necessary cookies enabled", () => {
  cy.wait("@saveCookieConsent").then(({ request }) => {
    expect(request.body.consent.categories.necessary).to.equal(true);
    expect(request.body.consent.categories.analytics).to.equal(false);
    expect(request.body.consent.categories.marketing).to.equal(false);
    expect(request.body.consent.categories.preferences).to.equal(false);
  });
});
