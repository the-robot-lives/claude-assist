# US-14 — Cross-framework reuse of exported components

**As** the frontend engineer (`design-system-frontend-engineer`)
**I want** the exported Lit components to drop into Vue, React/Next.js, Phoenix/Elixir (hex), Svelte, or raw HTML unchanged,
**so that** I ship one implementation instead of maintaining parallel copies per framework.

**Priority:** P1  **Size:** M

## Acceptance criteria
- A single exported component is consumed unchanged in at least Vue, React/Next.js, and Phoenix/Elixir.
- No framework-specific fork of the component source is required.
- Properties/attributes and `aria-*`/`data-*` behave consistently across host frameworks.
- Styling stays encapsulated and consistent regardless of host.
- Documentation/snippets show consuming the same element in multiple frameworks.

## Notes / linked README concept
§5 "reusable in Vue, React/Next.js, Phoenix/Elixir (hex), Svelte, or raw HTML without a rewrite." Core to persona Priya.
