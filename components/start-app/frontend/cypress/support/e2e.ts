/// <reference types="cypress" />

beforeEach(() => {
  cy.clearCookies();
  cy.clearLocalStorage();

  cy.intercept("GET", "**/api/v1/consent/cookies", {
    statusCode: 200,
    body: { consent: null },
  }).as("getCookieConsent");

  cy.intercept("PUT", "**/api/v1/consent/cookies", (req) => {
    const categories = {
      necessary: true,
      analytics: Boolean(req.body?.consent?.categories?.analytics),
      marketing: Boolean(req.body?.consent?.categories?.marketing),
      preferences: Boolean(req.body?.consent?.categories?.preferences),
    };

    req.reply({
      statusCode: 200,
      body: {
        consent: {
          version: req.body?.consent?.version || 1,
          categories,
          accepted_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
          requires_session_tracking: false,
        },
        requires_session_tracking: false,
      },
    });
  }).as("saveCookieConsent");
});
