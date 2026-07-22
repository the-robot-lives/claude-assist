import "cypress-real-events/support";
import "./commands";

beforeEach(() => {
  cy.clearCookies();
  cy.clearLocalStorage();
});
