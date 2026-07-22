# Architecture Decision Records

## ADR-001: Static Export Over Server-Side Rendering

**Status:** Accepted  
**Context:** No backend exists yet. The prototype is purely UI/UX exploration.  
**Decision:** Use `next build` static export served by nginx.  
**Consequences:** Simple deployment (no Node runtime in production), CDN-friendly. Dynamic routes require `generateStaticParams`. API integration will require revisiting this decision.

## ADR-002: Mock Data Modules Over API Stubs

**Status:** Accepted  
**Context:** Iterating on UI design before backend architecture is finalized.  
**Decision:** TypeScript modules in `src/data/` export mock data arrays directly. Components import data at build time.  
**Consequences:** Zero network latency during prototyping, type-safe fixtures, trivial to swap for `fetch()` calls later. Risk: UI may assume synchronous data availability that won't hold with a real API.

## ADR-003: D3.js for Knowledge Graph Visualization

**Status:** Accepted  
**Context:** The knowledge graph is a core differentiator — needs custom force simulation, zoom, drag, and interactive node selection.  
**Decision:** Use D3.js (d3-force, d3-zoom, d3-drag, d3-selection) with React integration.  
**Consequences:** Full control over layout and interaction. Higher implementation cost than drop-in libraries (Cytoscape, vis.js). D3 manages its own DOM subtree; React reconciliation must be carefully isolated.

## ADR-004: Tailwind CSS v4

**Status:** Accepted  
**Context:** Rapid prototyping with consistent styling across incubator projects.  
**Decision:** Tailwind v4 via PostCSS plugin.  
**Consequences:** Utility-first approach accelerates UI iteration. Custom design tokens defined as CSS variables in `globals.css`. Consistent with other incubator projects using the styleguide engine.

## ADR-005: Seven Entry-Type Taxonomy

**Status:** Accepted  
**Context:** Need a fixed set of entry categories that covers world-building primitives without over-specialization.  
**Decision:** `character`, `location`, `event`, `faction`, `object`, `concept`, `rule`.  
**Consequences:** Covers the vast majority of creative world-building use cases (fiction, RPGs, game design). Each type has a distinct icon and color treatment. Custom types may be needed eventually — but premature to add extensibility now.

## ADR-006: Phoenix Guardian as Canonical Auth Authority

**Status:** Accepted  
**Date:** 2026-07-22  
**Context:** The frontend prototype authenticates directly against Authentik (`auth.derobot.is`) via PKCE. The platform backend already implements full auth (register/login/refresh/magic-link/OTP/password-reset/email-verify) plus ueberauth SSO, issuing Guardian JWTs. Dual auth authorities would split session state and block KB API authorization.

**Decision:**
1. **Phoenix Guardian is the sole token authority** for product APIs. Access and refresh tokens are issued by the backend at `/api/v1/auth/*`.
2. **Authentik is demoted to an optional OIDC upstream** consumed only by the backend via ueberauth (`/auth/oidc` → callback → one-time SSO code → `POST /api/v1/auth/sso/exchange`).
3. **The frontend never talks to Authentik (or any IdP) directly.** All login UI posts to backend auth endpoints; SSO buttons redirect to backend OIDC start URLs.
4. Tokens live in `localStorage` (`access_token`, `refresh_token`); the API client attaches `Authorization: Bearer <access_token>` and refreshes on 401.

**Consequences:**
- Frontend `lib/auth.ts` Authentik PKCE path is removed in M1.S1.3.
- Existing backend auth surface is reused as-is; no parallel session store.
- Staging/production IdP config stays on the backend (`OIDC_*` env).
- See `app/docs/api/conventions.md` for the wire contract.

## ADR-007: Entry Versioning — Snapshot-on-Write

**Status:** Accepted  
**Date:** 2026-07-22  
**Context:** US-025 requires entry history and restore. Options: (a) snapshot full body/metadata on every write, (b) store deltas/patches. Delta stores are smaller but make restore and diff harder; rich-text document JSON is already a discrete blob.

**Decision:** **Snapshot-on-write.** Each successful entry create/update inserts a row into `entry_versions` with a full snapshot of mutable fields (title, body, type, status, tags, era, region, excerpt, metadata) plus actor and reason. Version tables land in changelogs 036–038 (M2.S2.6). Restore creates a new version (never mutates history).

**Consequences:**
- Storage grows with edit volume — acceptable for v0.1/v0.2 creative corpora.
- Diff = structured field comparison of two snapshots (FE in M4.S4.2).
- Generation promote-to-canon (M3) reuses the same snapshot hook.

## ADR-008: Universe Membership Over Bare Owner

**Status:** Accepted  
**Date:** 2026-07-22  
**Context:** Collaboration (US-091/US-092) is deferred to M5, but schema surgery later is costly. Roadmap D-001 requires membership-based ownership from day one.

**Decision:** Universes use a `universe_members` table (`universe_id`, `user_id`, `role`) seeded with the creating user as `owner`. No bare `owner_id` column on `universes`. v0.1 always has exactly one member; M5 maps roles onto PBAC without schema rewrite.

**Consequences:**
- Changelog 025 creates both tables together.
- Authorization checks membership role, not a single FK.
- Aligns with existing platform `scoped_memberships` patterns for projects.
