type CypressSubject = JQuery<HTMLElement>;

function dataCySelector(role: string): string {
  return `[data-cy="${role}"]`;
}

function dataCyIdSelector(id: string): string {
  return `[data-cy-id="${id}"]`;
}

function dataCyForSelector(id: string): string {
  return `[data-cy-for="${id}"]`;
}

Cypress.Commands.add("getByCy", (role: string, options?: Partial<Cypress.Loggable & Cypress.Timeoutable & Cypress.Withinable & Cypress.Shadow>) => {
  return cy.get(dataCySelector(role), options);
});

Cypress.Commands.add("getByCyId", (id: string, options?: Partial<Cypress.Loggable & Cypress.Timeoutable & Cypress.Withinable & Cypress.Shadow>) => {
  return cy.get(dataCyIdSelector(id), options);
});

Cypress.Commands.add("getByCyFor", (id: string, options?: Partial<Cypress.Loggable & Cypress.Timeoutable & Cypress.Withinable & Cypress.Shadow>) => {
  return cy.get(dataCyForSelector(id), options);
});

Cypress.Commands.add("withinScope", (scope: string, fn: ($scope: CypressSubject) => void) => {
  return cy.get(`[data-cy-scope="${scope}"]`).within(fn);
});

Cypress.Commands.add("pair", (role: string, id: string) => {
  return cy.get(`${dataCySelector(role)}${dataCyIdSelector(id)}`);
});

declare global {
  namespace Cypress {
    interface Chainable {
      getByCy(role: string, options?: Partial<Loggable & Timeoutable & Withinable & Shadow>): Chainable<JQuery<HTMLElement>>;
      getByCyId(id: string, options?: Partial<Loggable & Timeoutable & Withinable & Shadow>): Chainable<JQuery<HTMLElement>>;
      getByCyFor(id: string, options?: Partial<Loggable & Timeoutable & Withinable & Shadow>): Chainable<JQuery<HTMLElement>>;
      withinScope(scope: string, fn: ($scope: JQuery<HTMLElement>) => void): Chainable<JQuery<HTMLElement>>;
      pair(role: string, id: string): Chainable<JQuery<HTMLElement>>;
    }
  }
}

export {};
