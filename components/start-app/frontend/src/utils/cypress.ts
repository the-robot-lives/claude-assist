// Cypress test attribute utility following the guidelines docs/cypress-attributes.md
type Cy = {
  cy?: string;
  cyId?: string | number;
  cyFor?: string | number;
  cyValue?: string | number;
  cyScope?: string;
  cyFlags?: Record<string, string>;
};

// ⟦𓇰𓀤𓇗𓁕⟧ cyFlag :: auto-generated pointer for public function cyFlag
export const cyFlag = (flag: string, value: string = 'true') => ({
  [`data-cy-flag-${flag}`]: value,
});

// ⟦𓇢𓋈𓉭𓎗⟧ cyAttrs :: auto-generated pointer for public function cyAttrs
export const cyAttrs = ({ cy, cyId, cyFor, cyValue, cyScope, cyFlags }: Cy = {}) => ({
  ...(cy && { 'data-cy': cy }),
  ...(cyId && { 'data-cy-id': String(cyId) }),
  ...(cyFor && { 'data-cy-for': String(cyFor) }),
  ...(cyValue !== undefined && { 'data-cy-value': String(cyValue) }),
  ...(cyScope && { 'data-cy-scope': cyScope }),
  ...(cyFlags &&
    Object.fromEntries(
      Object.entries(cyFlags).map(([k, v]) => [`data-cy-flag-${k}`, v]),
    )),
});
