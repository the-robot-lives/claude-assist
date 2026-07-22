# PRD-M2: Embeddable Signup Widget + Public UX (Chunk C)

**Version**: 1.0
**Status**: Draft (PRD-gate — review before coding)
**Author**: npl-prd-editor
**Milestone**: M2
**Chunk**: C (front half of M2)
**Created**: 2026-07-22
**Updated**: 2026-07-22

**Branch**: `develop` (shared checkout; no worktrees — monorepo rule)
**Scope owner**: frontend lane (`projects/foryou.therobotlives.com/app/frontend/`)
**Backend dependency**: Chunk B (M1) must land first.

---

## Overview

A **drop-in embeddable signup widget** that lets any portfolio site collect signups
with a single `<script>` or `<iframe>` line, replacing the copy-pasted per-site React
forms (`waitlist-form.tsx`, `ContactModal.tsx`) that today POST straight to
`listmonk.noizu.com`. This is the **listmonk-replacement vehicle** (plan item 3).

The widget fetches a List's declared typed Attributes at runtime and renders the correct
field control for each (`email`, `string`, `int`, `float`, `date`, `guid`, `select`,
`multi-select`) — so adding/removing a field on a List changes every embedded form with
no code change. It themes to match the host site, submits **cross-origin** to the foryou
public endpoint (CORS preflight), and honors the **no-leak 202** contract so the form
behaves identically whether the email is new or already on the list.

### Goals

1. One embed line replaces a bespoke React form per site (US-046).
2. Dynamic field rendering from declared List attributes, shared with the hosted form (US-038).
3. Per-site theming with safe Service-branding fallback (US-047).
4. Cross-origin submission that works from allowed portfolio origins and is blocked from others (US-048, US-096).
5. Success/error/loading UX that is accessible and never leaks membership (US-044, US-045, US-049).

### Non-Goals

- The hosted Preference Center `/app/me` (Chunk E).
- The Admin signups table / export (Chunk D).
- The noizu.com richer inquiry form (Chunk F) — though the widget's field renderers are reusable there.
- listmonk backfill / cutover mechanics (Chunk G) — this PRD only defines the **swap contract** Chunk G follows.
- Authoring/sending campaigns ("beyond listmonk"); deferred post-M5.

---

## User Stories

From `project-management/user-stories/`. Every AC in those stories maps to an
Acceptance Test below.

| ID | Title | Priority | Epic |
|----|-------|----------|------|
| [US-046](../user-stories/US-046-embeddable-signup-widget.md) | Embed a drop-in signup widget | must-have | Signups & Subscriptions |
| [US-047](../user-stories/US-047-widget-theming.md) | Theme the embeddable widget to match a site | could-have | Signups & Subscriptions |
| [US-048](../user-stories/US-048-cross-origin-submission.md) | Submit signups cross-origin from external sites | must-have | Signups & Subscriptions |
| [US-096](../user-stories/US-096-cors-configuration.md) | Configure CORS for cross-origin signups | must-have | Infrastructure |

**Foundation stories this widget implements/conforms to** (their ACs are in-scope for the
widget even though they live in M1):
US-038 (dynamic field rendering), US-044 (success state), US-045 (generic 202 / no-leak),
US-049 (honeypot). The public endpoint itself (US-037 submit, US-045 no-leak, US-100
rate-limit, US-040 double opt-in) is delivered by **Chunk B**; this PRD consumes it.

**Personas**: P-006 (Embedder/dev), P-007 (Subscriber — accessibility/low-bandwidth), P-008 (Abuser/enumerator).

**Screen**: SCR-12 Embeddable Widget. **Components**: CMP-02 DynamicForm, CMP-01 FormField,
CMP-19 HoneypotField, CMP-04 InlineAlert, CMP-20 BrandingEditor (source of defaults).

---

## Architecture

### Two embed variants (both required per US-047 notes)

The widget ships as two embeddable surfaces sharing one rendering core (CMP-02 DynamicForm):

| Variant | Snippet | Cross-origin POST? | When to use |
|---------|---------|--------------------|-------------|
| **Script (Web Component)** | `<div data-foryou-service=… data-foryou-list=…></div>` + `<script src=widget.js>` | **Yes** — `fetch()` from host origin → needs CORS (US-096) | Default for portfolio React/Next sites; native feel, themeable via attrs. |
| **Iframe** | `<iframe src="…/embed/:svc/:list">` | **No** — iframe document is same-origin to the API (both on `foryou.therobotlives.com`); no CORS preflight | Zero-CORS fallback; maximal isolation; sites that disallow 3rd-party script. |

> The **iframe variant needs no CORS** because its POST originates inside a document on
> `foryou.therobotlives.com`. Only the **script variant** issues a cross-origin `fetch`
> from the host origin, which is what US-096/US-048 govern. This de-risks the M2 CORS gate:
> the iframe path works even before US-096 hardening lands.

### Origins / serving

All three assets are served from `foryou.therobotlives.com` (single ingress; frontend Next.js + backend behind it):

- `GET https://foryou.therobotlives.com/widget.js` — versioned, minified, `async defer`-safe bundle (frontend public asset; cached with immutable hash + long `max-age`). Target ≤ 30KB gzipped.
- `GET https://foryou.therobotlives.com/embed/:service_slug/:list_slug` — hosted iframe page (frontend route, SSR/CSR), renders CMP-02 DynamicForm.
- `GET https://foryou.therobotlives.com/api/v1/public/services/:service_slug/lists/:list_slug` — **List manifest** (Chunk B public read).
- `POST https://foryou.therobotlives.com/api/v1/public/services/:service_slug/lists/:list_slug/signups` — **submit** (Chunk B public write; always 202 / no-leak).

The host site is on a different origin (e.g. `https://therobotlives.com`); the script
variant's `fetch` to the API is the cross-origin hop CORS governs.

### Isolation

- Script variant renders into a **Shadow DOM** root so host-page CSS cannot leak in or out (US-047 AC3).
- Iframe variant is fully origin-isolated by construction.

---

## Functional Requirements

> FR-003/FR-006/FR-011 define the **contract Chunk B must expose**; FR-001/002/004/005/007–010/012/013 are the widget's own work. Chunk B ownership is called out per-FR.

### FR-001: Script-variant embed & bootstrap

**Status**: Draft
**Description**: A host page adds a declarative placeholder + one script tag; on load the script discovers placeholders, fetches each List manifest, and renders an isolated form.
**Interface** (host HTML):

```html
<div data-foryou-service="therobotlives"
     data-foryou-list="beta-access"
     data-foryou-theme='{"accent":"#4aedc4","mode":"dark"}'></div>
<script src="https://foryou.therobotlives.com/widget.js" async defer></script>
```

**Behavior**:
- Given a page with one or more `[data-foryou-service][data-foryou-list]` elements, when `widget.js` loads, then each placeholder is upgraded in place (idempotent; re-running is a no-op).
- Given a placeholder missing a required attr, when bootstrapped, then it renders an InlineAlert "Configuration error" visible only in dev/console; never throws on the host page.
- Given multiple placeholders for the same list, when rendered, then each renders independently.
**Edge cases**: script loaded twice (guard via global flag); placeholder inside Shadow DOM (query `document` + observed roots); host SPA navigation (MutationObserver to catch late-inserted placeholders).
**Related stories**: US-046 AC1. **Test coverage**: 4–6 tests.

### FR-002: Iframe-variant embed & auto-resize

**Status**: Draft
**Description**: A host page embeds an iframe pointing at the hosted embed page; the page renders CMP-02 DynamicForm and posts its content height to the host for auto-resize with **zero host code**.
**Interface** (host HTML):

```html
<iframe src="https://foryou.therobotlives.com/embed/therobotlives/beta-access?theme=..."
        title="Sign up" loading="lazy" scrolling="no"
        style="border:0;width:100%;min-height:160px"></iframe>
```

**Behavior**:
- Given the iframe loads, when DynamicForm mounts/resizes, then it `postMessage({source:'foryou-widget', type:'height', height})` to `parent`; the shipped loader (small inline snippet OR a `widget.js` listener) sets `iframe.height`. (Recommended: ship a 1-line loader so hosts add nothing; document the raw postMessage protocol for hosts that prefer it.)
- Given theme via `?theme=` query (URL-safe JSON or flat params), when the page renders, then theme is applied (FR-007).
- Given `sandbox` attrs a host sets, when they block scripts, then the form still renders (the embed page needs `allow-scripts allow-forms allow-same-origin` — document the minimum sandbox).
**Edge cases**: cross-origin `postMessage` (validate `event.origin === 'https://foryou.therobotlives.com'`); ResizeObserver fallback to interval; host CSS `min-height` conflict.
**Related stories**: US-046 AC1, US-047 AC3. **Test coverage**: 3–5 tests.

### FR-003: List manifest fetch (public read) — Chunk B owns the endpoint

**Status**: Draft — **Chunk B dependency**
**Description**: The widget calls a public, unauthenticated read endpoint that returns the List's name, declared typed attributes, opt-in mode, and success-message copy, plus the Service branding defaults.
**Interface** (Chunk B must provide):

```
GET /api/v1/public/services/:service_slug/lists/:list_slug
200 OK
{
  "service": { "slug": "therobotlives", "name": "TheRobotLives",
               "branding": { "accent": "#4aedc4", "mode": "dark", ... } },
  "list":     { "slug": "beta-access", "name": "Beta Access", "kind": "waitlist" },
  "attributes": [
    { "slug": "email",        "label": "Email",     "type": "email",        "required": true },
    { "slug": "name",         "label": "Name",      "type": "string",       "required": false },
    { "slug": "invite_token", "label": "Invite token", "type": "guid",      "required": false },
    { "slug": "justification","label": "Why do you want access?", "type": "string", "required": false, "multiline": true },
    { "slug": "role",         "label": "Role",      "type": "select",       "required": false, "options": ["Dev","Designer"] },
    { "slug": "interests",    "label": "Interests", "type": "multi-select", "required": false, "options": ["AI","Games"] }
  ],
  "settings": {
    "opt_in_mode": "single",                         // "single" | "double"
    "success_message":              "You're on the list!",
    "success_message_double_optin": "Check your inbox to confirm your spot."
  }
}
```

**Behavior**:
- Given a valid service/list slug pair, when fetched, then the manifest is returned (public, cacheable ~60s).
- Given an unknown/archived list, when fetched, then 404 with a generic body (the widget shows a neutral "Sign-up unavailable" state).
- Given attributes change on the List, when the form is reloaded, then it reflects the current set with **no widget/host code change** (US-038 AC3) — this is why the schema is fetched at runtime, not compiled in.
**Edge cases**: manifest fetch failure (network/offline) → neutral fallback message, no partial form; malicious manifest (defensive: sanitize strings, cap option counts, ignore unknown types).
**Related stories**: US-038 (all ACs), US-046 AC1. **Test coverage**: 3–4 tests.
> **Ambiguity A1**: confirm Chunk B's PRD includes this public read (manifest) endpoint. If not, Chunk C must add it — **blocking dependency**.

### FR-004: Per-type field renderers (dynamic rendering)

**Status**: Draft
**Description**: Each declared attribute renders the correct HTML control with appropriate client validation and a11y. Shared with the hosted form (CMP-02 DynamicForm + CMP-01 FormField).
**Interface** (renderer table):

| Attribute `type` | Control | Client validation |
|------------------|---------|--------------------|
| `string` | `<input type="text">` (textarea if `multiline`) | required; `maxlength` |
| `email` | `<input type="email" autocomplete="email">` | required; RFC-ish regex |
| `int` | `<input type="number" step="1">` | integer parse; min/max |
| `float` | `<input type="number" step="any">` | numeric parse |
| `date` | `<input type="date">` | valid date |
| `guid` | `<input type="text">` (or hidden when an invite token is passed via URL → prefilled) | lenient uuid-ish format |
| `select` | `<select>` + `<option>`s | value ∈ options |
| `multi-select` | `<fieldset>` of `<input type="checkbox">` | values ⊆ options |

**Behavior**:
- Given a manifest, when rendered, then each attribute renders with the correct control and its `label` (US-038 AC1).
- Given `required: true`, when rendered, then the field is `required` + `aria-required="true"` + a visible `*` (US-038 AC2).
- Given an unknown `type`, when rendered, then it degrades to a plain text input (never breaks the form).
**Edge cases**: very long option lists (cap + document); URL-prefilled `guid` (read `?invite_token=`/`?ref=` into the field); re-render on manifest change.
**Related stories**: US-038 AC1–3, US-046 AC1. **Test coverage**: one renderer test per type (8) + required + unknown-type = 10–12 tests.

### FR-005: Client-side validation

**Status**: Draft
**Description**: Validate before submit; show field-level inline errors; never rely on the endpoint for UX feedback (see FR-011 for why).
**Behavior**:
- Given a required field left empty / an invalid email / an out-of-range select, when the user submits, then submission is blocked and the field shows an inline message with `aria-invalid="true"` + `aria-describedby`.
- Given valid input, when submitted, then the POST proceeds (FR-006).
**Edge cases**: validate on blur after first submit attempt; clear error on edit; honor `novalidate` is NOT set (we control the form).
**Related stories**: US-038 AC2, US-039. **Test coverage**: 4–6 tests.

### FR-006: Cross-origin submit (POST + CORS preflight) — script variant

**Status**: Draft
**Description**: The script variant POSTs the attributes as JSON to the public endpoint; the browser issues a CORS preflight because of `Content-Type: application/json`. The iframe variant POSTs same-origin (no preflight).
**Interface** (request):

```
POST /api/v1/public/services/:service_slug/lists/:list_slug/signups
Content-Type: application/json
{ "attributes": { "email": "…", "name": "…", "invite_token": "…" }, "_hp": "" }
```

`_hp` is the honeypot value (FR-010). Response contract in FR-011.
**Behavior**:
- Given an allowed origin, when the widget submits, then the preflight (`OPTIONS`) and POST both succeed and the signup is accepted (US-048 AC1).
- Given a disallowed origin, when the widget submits, then the browser blocks the response and the widget shows a non-technical error (FR-009) (US-048 AC2).
**Edge cases**: preflight cache (`Access-Control-Max-Age`); aborted/double submit (debounce + disable).
**Related stories**: US-046 AC2, US-048 AC1–2. **Test coverage**: 4–5 tests.
> The CORS headers themselves are Chunk B/US-096 work — see **CORS Contract** below.

### FR-007: Theming & branding

**Status**: Draft
**Description**: The widget accepts an optional theme and falls back to Service branding (US-016) then to foryou defaults. Isolation (Shadow DOM / iframe) prevents host CSS conflicts.
**Interface** (theme object — all keys optional):

```jsonc
{ "accent": "#4aedc4", "accentText": "#080B14", "surface": "#0c1018",
  "text": "#e6e9ef", "mode": "auto",        // "light" | "dark" | "auto"
  "radius": "0.75rem", "font": "Inter, sans-serif" }
```

Delivery: script variant via `data-foryou-theme` JSON attr or `window.foryouConfig.theme`; iframe via `?theme=` query.
**Behavior**:
- Given theme options, when rendered, then the widget reflects them (US-047 AC1).
- Given no theme, when rendered, then the widget uses the Service's branding defaults from the manifest (US-016) (US-047 AC2).
- Given `mode: "auto"`, when rendered, then it follows `prefers-color-scheme`.
- Given a theme that would drop a foreground/background pair below **WCAG AA contrast**, when rendered, then the widget clamps the offending pair to a compliant value (and `console.warn`s in dev) — it never renders unreadable text.
**Edge cases**: invalid color strings (ignore key, keep default); theme keys partially provided (merge over defaults, not replace).
**Related stories**: US-047 AC1–3. **Test coverage**: 4–6 tests.

### FR-008: Success state (double vs single opt-in)

**Status**: Draft
**Description**: On a successful submit, replace the form with a confirmation whose copy reflects the List's opt-in mode; announce it for assistive tech.
**Behavior**:
- Given a single-opt-in list, when submit succeeds, then show `settings.success_message` (default "You're on the list!") (US-044 AC1).
- Given a double-opt-in list (`newsletter`/`mixed`), when submit succeeds, then show `settings.success_message_double_optin` (default "Check your inbox to confirm your spot.") (US-044 AC2).
- Given any success, when rendered, then it is announced via an `aria-live="polite"` region and focus moves to the message (US-044 AC3).
**Edge cases**: success then re-submit (replace instance with a fresh form after N seconds, optional); copy overrides from manifest.
**Related stories**: US-044 AC1–3, US-040. **Test coverage**: 3–4 tests.

### FR-009: Error & loading states

**Status**: Draft
**Description**: Loading disables re-submit; network/CORS/rate-limit failures show a clear, **non-technical** inline error (CMP-04 InlineAlert), never exposing backend/CORS details.
**Behavior**:
- Given a submit in flight, when loading, then inputs + button are disabled and the button shows "Joining…" (prevent double-submit).
- Given a network/CORS failure (`TypeError` on fetch), when caught, then show "Something went wrong — please try again." (US-048 AC3).
- Given a `429` (rate-limited, US-100), when received, then show "Too many attempts — please wait a moment and try again."
- Given a `422` (structural validation — see FR-011 decision), when received, then map to field-level errors.
**Edge cases**: timeouts; offline; repeated 429 (do not auto-retry — surface to user).
**Related stories**: US-044, US-048 AC3. **Test coverage**: 4–5 tests.

### FR-010: Honeypot field

**Status**: Draft
**Description**: Render an accessible-hidden honeypot field (CMP-19); real users never fill it; the backend silently drops filled submissions and returns the same 202 (FR-011).
**Interface**: a field named `_hp` rendered `aria-hidden="true"`, `tabindex="-1"`, `autocomplete="off"`, positioned off-screen (not `display:none` — bots skip those).
**Behavior**:
- Given a real user, when they submit, then `_hp` is empty and the submission proceeds (US-049 AC2).
- Given an automated client that fills `_hp`, when it submits, then the backend silently drops it and returns the same generic 202 (US-049 AC1/AC3); the widget shows the normal success state.
**Edge cases**: browser autofill populating the honeypot (use a non-standard label like "Company website"); honeypot name rotation (optional hardening).
**Related stories**: US-049 AC1–3. **Test coverage**: 2–3 tests.

### FR-011: No-leak 202 contract (client conformance) — Chunk B owns the response

**Status**: Draft — **Chunk B dependency**
**Description**: For all well-formed submissions the endpoint returns an identical `202` regardless of whether the email is new, already subscribed, previously unsubscribed, or honeypot-tripped. The widget therefore shows the **same success state** in all those cases.
**Interface** (response):

```
202 Accepted
{ "accepted": true }
```

**Behavior**:
- Given an email already on the List, when submitted, then response is the identical generic 202 (US-045 AC1) and the widget shows success.
- Given a brand-new email, when submitted, then response is the same generic 202 (US-045 AC2) and the widget shows success.
- Given any well-formed submission, when processed, then the response body and timing do not distinguish existing from new members (US-045 AC3) — the widget treats 202 uniformly.
**Edge cases**: the widget must not branch its success UX on response body variations; must not log/expose prior-membership signals.
**Related stories**: US-045 AC1–3, US-043. **Test coverage**: 3 tests (new / existing / honeypot all render identically).
> **Ambiguity A2 (decision needed)**: strictest no-leak posture = endpoint returns 202 for **all** syntactically-JSON requests and silently drops semantically-invalid ones (malformed email, bad select option), with the widget doing all UX validation client-side. Alternative = endpoint returns `422` for malformed input (not a membership leak). **Recommendation**: always-202-for-well-formed + client-side validation (FR-005), accepting the trade-off that a typo'd email gets a false-positive success. Confirm before Chunk B finalizes.

### FR-012: Accessibility & resilience

**Status**: Draft
**Description**: Usable with assistive tech and on slow connections; degrades gracefully.
**Behavior**:
- Given keyboard navigation, when used, then all controls are reachable in order with visible focus (US-046 AC3).
- Given a screen reader, when interacting, then fields have associated `<label>`s, required/invalid states are announced, and status changes use live regions (US-044 AC3).
- Given `prefers-reduced-motion`, when rendering transitions, then motion is suppressed.
- Given a slow connection, when the manifest is still loading, then a lightweight skeleton renders (not a blank box); if the manifest fails to load, a neutral "Sign-up unavailable" message shows.
- WCAG 2.1 AA target: contrast (FR-007 enforces), labels, focus, names, roles.
**Related stories**: US-046 AC3, US-044 AC3, US-012. **Test coverage**: 4–6 tests (axe-core pass in CI).

### FR-013: Bundle size, caching & performance

**Status**: Draft
**Description**: The script bundle is small, cached, and non-blocking so it never materially slows a host page.
**Behavior**:
- Given `widget.js`, when served, then it is ≤ 30KB gzipped, served with a far-future immutable cache header on the hashed filename, and a short `max-age` on the stable `/widget.js` URL for patch rollouts.
- Given a host page, when loading, then the script is `async defer` and never blocks first paint; the manifest fetch is parallelizable.
**Edge cases**: subresource integrity (SRI) optional; CDN/edge caching of manifest.
**Related stories**: US-046 AC3. **Test coverage**: 1–2 tests + bundle-size CI check.

---

## CORS Contract (US-048 + US-096)

Chunk A recon located the existing endpoint-global CORS plug at `lib/foryou_web/plugs/cors.ex`
(reflect-any-origin). US-096 **hardens** it into an allowlist for the public scope. This PRD
defines what the widget requires of that plug; Chunk B/US-096 implements it.

**Required response to a preflight from an allowed origin**:

```
OPTIONS /api/v1/public/services/:svc/lists/:list/signups
Origin: https://therobotlives.com
Access-Control-Allow-Origin: https://therobotlives.com      // reflected ONLY if allowlisted
Access-Control-Allow-Methods: POST, OPTIONS
Access-Control-Allow-Headers: Content-Type
Access-Control-Max-Age: 600
Vary: Origin
HTTP/1.1 204
```

**Allowlist source (two layers)**:
1. **Platform floor** — `CORS_ORIGINS` env var (comma/space separated), set in `.envrc.dc`/Infisical. Hardens the current reflect-any plug.
2. **Dynamic (per-Service)** — origins from Service domain mapping (US-018), read from the DB so a newly-mapped domain is permitted **without a redeploy** (US-096 AC3). Effective allowlist = floor ∪ dynamic.

**Behavior**:
- Allowed origin → `Access-Control-Allow-Origin` reflected; request proceeds (US-048 AC1, US-096 AC1).
- Disallowed origin → header omitted → browser blocks (US-048 AC2, US-096 AC2).
- Origin changes (new domain mapped via US-018) → permitted without redeploy where the dynamic layer is in place (US-096 AC3).

> **Ambiguity A3**: is the **dynamic DB-backed** allowlist in M2 scope, or is M2 the env-floor only with DB-backed as a fast-follow? A3 affects whether US-096 AC3 ("without a redeploy") is fully met in M2. **Recommendation**: ship the env floor for M2 (unblocks the script variant immediately) and the DB-backed layer as a fast-follow tracked under US-018/US-096 — confirm with team-lead.

---

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Widget bundle weight | gzipped size | ≤ 30KB |
| NFR-2 | First usable render on host page | TTI added | < 500ms over cache (excl. manifest fetch) |
| NFR-3 | Accessibility | WCAG 2.1 AA | axe-core 0 violations (serious/critical) |
| NFR-4 | Host-page CSS isolation | Shadow DOM / iframe | 0 style leaks either direction |
| NFR-5 | Test coverage for new widget code | line coverage | ≥ 80% |
| NFR-6 | No-leak integrity | timing/body variance (new vs existing) | indistinguishable |

---

## Error Handling Summary

| Condition | Where handled | User-facing result |
|-----------|---------------|--------------------|
| Required field empty / invalid email / bad select | Client (FR-005) | Inline field error, `aria-invalid` |
| Honeypot filled | Backend (FR-010/FR-011) | Normal success (silent drop) |
| Network/CORS failure | Client (FR-009) | "Something went wrong — please try again." |
| Rate limited (429) | Client (FR-009) | "Too many attempts — please wait a moment…" |
| Manifest fetch failure / 404 | Client (FR-003) | "Sign-up unavailable" neutral state |
| Double opt-in confirm pending | Client (FR-008) | "Check your inbox to confirm…" |
| Unknown attribute type | Client (FR-004) | Degrades to text input |

---

## Acceptance Tests

Each AT ties to story AC(s). See `acceptance-tests/` (to be generated by TDD Tester from this PRD). Summary:

| ID | Validates | Story ACs | Category | Status |
|----|-----------|-----------|----------|--------|
| AT-001 | Snippet + script → form renders with fields from List attributes | US-046 AC1, US-038 AC1 | e2e | Not started |
| AT-002 | Script-variant cross-origin submit succeeds (preflight + POST) | US-046 AC2, US-048 AC1 | e2e | Not started |
| AT-003 | Slow connection + assistive tech: usable, accessible, graceful | US-046 AC3 | e2e/a11y | Not started |
| AT-004 | Theme options applied (colors/spacing/mode) | US-047 AC1 | unit/e2e | Not started |
| AT-005 | No theme → Service branding defaults (US-016) | US-047 AC2 | e2e | Not started |
| AT-006 | Host CSS cannot break the form (Shadow DOM + iframe) | US-047 AC3 | unit | Not started |
| AT-007 | Allowed origin: preflight + POST succeed | US-048 AC1, US-096 AC1 | integration | Not started |
| AT-008 | Disallowed origin: blocked by CORS | US-048 AC2, US-096 AC2 | integration | Not started |
| AT-009 | Cross-origin failure → clear non-technical error | US-048 AC3 | e2e | Not started |
| AT-010 | New mapped domain permitted without redeploy (dynamic allowlist) | US-096 AC3 | integration | Not started |
| AT-011 | Per-type controls render correctly; required marked; schema change reflected w/o code change | US-038 AC1–3 | unit | Not started |
| AT-012 | Success state shows correct copy (single vs double opt-in) + live region | US-044 AC1–3 | unit/e2e | Not started |
| AT-013 | Identical 202 + identical widget success for new / existing / honeypot | US-045 AC1–3, US-049 AC1–3 | integration | Not started |

---

## Migration Note: listmonk → widget (feeds Chunk G)

This is the **swap contract** Chunk G executes per site. The widget exists so this is one
line, not a React port.

**Per-site steps** (site list + old listmonk UUIDs from plan recon):

| Site | Old listmonk list UUID (per plan) |
|------|-----------------------------------|
| therobotlives.com | `b5ddf546…` ⚠ see A4 |
| codefre.sh (×2 apps) | `a7063958…` |
| gotta.cc | `ff9aca9d…` ⚠ see A4 |
| aifighter.com | `3d7f6e9c…` |
| noizu.com | `b64a0218…` |
| robots-unite.com | `90a7e213…` |
| jailbreakingsite.com | `0c076e0c…` |
| noizurpg.com | `f95d1108…` |
| iotgo.io | `d0611a6b…` |

**Steps**:
1. **Provision** a foryou List for the site via `terraform-provider-foryou` (US-036, Chunk B) — service slug + list slug (e.g. `therobotlives` / `beta-access`).
2. **Declare attributes** matching what the old form collected. Most portfolio lists are **email-only** (see the existing `waitlist-form.tsx`: `email` + empty `name`); noizu.com's `ContactModal.tsx` adds name + free-text inquiry (handled in Chunk F). Do **not** over-collect.
3. **Swap** the component usage for the embed snippet. Concrete before/after (therobotlives):

   Before (`app/frontend/src/app/waitlist-form.tsx`, bespoke React, hardcoded `LISTMONK_URL` + `LIST_UUID`):
   ```tsx
   const LISTMONK_URL = "https://listmonk.noizu.com/api/public/subscription";
   const LIST_UUID = "ff9aca9d-3ee5-4d62-9cac-35f3ec598b75";
   // …fetch POST { email, name: "", list_uuids: [LIST_UUID] }…
   <WaitlistForm />
   ```

   After (one snippet in the page where `<WaitlistForm />` was):
   ```html
   <div data-foryou-service="therobotlives" data-foryou-list="beta-access"></div>
   <script src="https://foryou.therobotlives.com/widget.js" async defer></script>
   ```
   Delete `waitlist-form.tsx`. (Or keep a thin React wrapper that renders the snippet for SSR-safe hydration.)
4. **Map the Service domain** (US-018) so the host origin is in the CORS allowlist.
5. **Verify**: submit on the live host → 202 → row appears in foryou DB / admin (Chunk D). Confirm **no new signups land in listmonk**.
6. **Backfill** existing listmonk subscribers once via mgmt `POST /api/v1/management/services/:svc/lists/:list/signups/import` (Chunk B) — dedupe by email, import as `subscribed`, preserve original attribs under `attribs.listmonk`, **send no opt-in emails**.
7. **Decommission** listmonk only after all sites cut over (Chunk H).

> **Ambiguity A4 (data discrepancy)**: the plan's recon maps `ff9aca9d…` to gotta.cc and `b5ddf546…` to therobotlives.com, but `projects/therobotlives.com/app/frontend/src/app/waitlist-form.tsx:6` actually hardcodes `LIST_UUID = "ff9aca9d-3ee5-4d62-9cac-35f3ec598b75"`. Either the UUIDs were mis-attributed in recon, or therobotlives.com is POSTing into gotta.cc's listmonk list. **Resolve before Chunk G backfill** (which listmonk list each site truly owns) — affects which subscribers get backfilled where.

---

## Dependencies

- **Chunk B (M1) — hard blocker**: public read manifest endpoint (FR-003), public submit endpoint with always-202/no-leak (FR-006/FR-011), typed List attributes + Service branding fields (FR-004/FR-007), per-list double/single opt-in config (FR-008), rate limiting US-100, honeypot-aware silent drop (FR-010).
- **US-096 (CORS hardening)** — hard blocker for the **script variant** only; iframe variant works without it. Land the env-floor (`CORS_ORIGINS`) before/with M2; DB-backed layer (US-018) is the fast-follow (A3).
- **US-016 (Service branding)** — theming defaults source (FR-007).
- **US-018 (Service domain mapping)** — feeds the dynamic CORS allowlist (US-096 AC3).
- **terraform-provider-foryou** (US-036) — provisions the Lists the widget points at.

---

## Out of Scope

- Preference Center `/app/me`, Admin console, noizu.com inquiry fields, listmonk backfill/cutover execution, campaign sending (see Non-Goals).
- Native mobile SDKs (the iframe/script works in mobile browsers).
- A/B testing of widget variants.
- Server-side rendering of the widget into host HTML (SSR hydration) beyond a thin optional wrapper.

---

## Open Questions / Ambiguities

- **A1** (blocker): Does Chunk B's PRD include the **public manifest read endpoint** (FR-003)? If not, Chunk C must add it.
- **A2** (decision): No-leak posture — always-202-for-well-formed (recommended, strongest) vs `422`-on-malformed. Confirm before Chunk B finalizes the endpoint.
- **A3** (scope): Is the **dynamic DB-backed CORS allowlist** (US-018) in M2, or env-floor only for M2 with DB-backed fast-follow? Affects US-096 AC3.
- **A4** (data): listmonk UUID mis-attribution for therobotlives.com (`ff9aca9d…` in code vs `b5ddf546…` in plan). Resolve before Chunk G.
- **A5** (minor): Where is `widget.js` + `/embed` served — frontend Next public routes (recommended) or a backend static plug? Confirm with frontend lane.
- **A6** (minor): Iframe auto-resize — ship a zero-host-code loader (recommended) vs require hosts to add a postMessage listener.

---

## Success Criteria

1. US-046, US-047, US-048, US-096 (and the widget-facing ACs of US-038/044/045/049) pass.
2. A portfolio site can replace its `waitlist-form.tsx`/`ContactModal.tsx` with one snippet and collect signups (AT-001, AT-002, migration note).
3. Cross-origin submit succeeds from an allowed origin and is blocked from a disallowed one (AT-007, AT-008).
4. The widget shows identical success for new, existing, and honeypot submissions (AT-013) — no membership leak.
5. `npm run build` (frontend) passes with 0 `tsc` errors; axe-core reports 0 serious/critical issues; widget bundle ≤ 30KB gzipped.
6. claude-in-chrome smoke: embedded widget on a host origin → submit → 202 → signup visible in foryou DB.

---

*Authored by npl-prd-editor. Stories are 5-bullet AC templates; this PRD makes Chunk C implementation-ready. Fold any resolution to A1–A6 back in before coding.*
