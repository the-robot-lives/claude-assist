# foryou.therobotlives.com — Roadmap

This folder is the **roadmap authority** for foryou (analogous to
`tobornalp.com/project-management/roadmap/`). It sequences the 100 user stories in
`../user-stories/` into milestones M0–M5, mapped to the implementation chunks
(A–H) from the approved plan (`resilient-beaming-wozniak.md`).

## PRD gate (biggest process risk)

The user stories are **5-bullet AC templates, not implementation-ready**. Before
coding **each** implementation chunk, an `npl-prd-editor` PRD MUST be authored from
that chunk's stories (folding in the preliminary backend-domain design agent's
report: file paths, changelog numbering, CORS/mailer config, PBAC approach). Stand
up the PRD pipeline **before Chunk B**. Publish (`git push` + `deploy-service`) only
at verified chunk boundaries — never half-built images.

## Milestone matrix

| Milestone | Theme | Chunk(s) | Epics | Original items |
|-----------|-------|----------|-------|----------------|
| **M0** | Platform baseline + quick wins | A | Onboarding & Auth; admin guard; infra recon | 1, 2 |
| **M1** | Service/List/Attribute/Signup domain (backend) | B | Services & Branding; Lists & Attributes; Signups core | (foundation for 3, 4) |
| **M2** | Embeddable widget + public UX | C | Signups & Subscriptions (widget) | 3 (vehicle) |
| **M3** | Admin Console + Preference Center + Contact Preferences | D, E | Admin Console; Preference Center; Contact Preferences | 5, 6 |
| **M4** | noizu.com inquiry + per-site listmonk cutover | F, G | Inquiries & Lead Capture; listmonk Migration (cutover) | 4, 3 |
| **M5** | Decommission listmonk | H | listmonk Migration (teardown) | 3 (finish) |
| **post-M5** | Multi-channel delivery (deferred) | — | Contact Preferences (senders) | — |

## M0 — Platform baseline + quick wins (Chunk A)
Quick wins and the guards/recon everything else depends on. Backend for create-org
already exists; this is UI + fixes + recon.
- **Stories:** US-001, US-002, US-003, US-004, US-005, US-006, US-007, US-008,
  US-011, US-012, US-071 (RequireAdmin fix + guarded admin layout), US-096 (CORS
  recon/config), US-097 (mailer recon/config)
- **Highlights:** remove cookie-settings button (US-011, item 1); create-org UI for
  orgless users (US-005/006/007/008, item 2); fix `RequireAdmin`/`:admin` schema gap
  so admin guards work; recon CORS + mailer.

## M1 — Service/List/Attribute/Signup domain, backend (Chunk B)
The core domain: Services, Lists, typed Attributes (no-migration), Signups, the
public signup endpoint, double opt-in, unsubscribe, reconcile, and safety.
- **Stories:** US-013–US-022 (Services & Branding), US-023–US-036 (Lists &
  Attributes), US-037, US-038, US-039, US-040, US-041, US-042, US-043, US-044,
  US-045, US-049, US-050, US-088 (backward-compat inquiries), US-098 (TF
  provisioning), US-100 (rate-limiting)
- **Gate:** double opt-in default per list (compliance); generic 202 / no-leak;
  unique (list_id, lower(email)).

## M2 — Embeddable widget + public UX (Chunk C)
The listmonk-replacement vehicle: one drop-in embed replacing per-site forms.
- **Stories:** US-046 (widget), US-047 (theming), US-048 (cross-origin), and
  finalizing US-096 (CORS for cross-origin from portfolio domains)
- **Gate:** CORS must be correct or every external signup 4xx's.

## M3 — Admin Console + Preference Center + Contact Preferences (Chunks D, E)
Operator and subscriber surfaces atop the M1 domain.
- **Admin (Chunk D):** US-072, US-073, US-074, US-075 (item 5), US-076, US-077,
  US-078, US-079, US-080, US-099 (observability)
- **Preference Center (Chunk E):** US-061 (item 6), US-062, US-063, US-064, US-065,
  US-066, US-067, US-068, US-069, US-070
- **Contact Preferences:** US-051, US-052, US-053, US-054, US-055, US-056, US-057
- **Depends on:** US-071 admin guard (M0) must be fixed for admin guards to work.

## M4 — noizu.com inquiry + per-site listmonk cutover (Chunks F, G)
- **Inquiries (Chunk F):** US-081 (noizu.com enhancement, item 4), US-082, US-083,
  US-084, US-085, US-086, US-087 (US-088 backend landed in M1)
- **Migration (Chunk G):** US-089 (item 3 umbrella), US-090, US-091, US-092, US-093,
  US-094 — per-site: provision → repoint → verify → backfill (dedupe by email).
- **Gate:** verify no new signups reach listmonk before backfill; dedupe on import.

## M5 — Decommission listmonk (Chunk H)
- **Stories:** US-095 — remove listmonk TF, DB/role, DNS once all sites cut over.
- **Gate:** must be last; retain a final export/backup before teardown.

## post-M5 — Deferred multi-channel delivery (won't-have for M0–M5)
Preferences are stored earlier; the actual senders come later.
- **Stories:** US-058 (SMS), US-059 (push), US-060 (webhook + physical mail).

## MoSCoW summary (100 stories)

| Priority | Count |
|----------|-------|
| must-have | 48 |
| should-have | 41 |
| could-have | 8 |
| won't-have | 3 |

Must > Should > Could >> Won't. Won't-have = the three deferred non-email delivery
channels (US-058/059/060).

## The 6 original items → milestones

| # | Item | Milestone(s) | Key stories |
|---|------|--------------|-------------|
| 1 | Remove cookie button from navbar | M0 | US-011 |
| 2 | Create-org for orgless users | M0 | US-005, US-006, US-007, US-008 |
| 3 | Migrate all listmonk signups → foryou | M1+M2+M4+M5 | US-046, US-089–US-095 |
| 4 | Channels per project + richer noizu.com inquiry | M1(+M4) | US-023, US-081 |
| 5 | Admin page: signups per service/list | M3 | US-075 |
| 6 | User page: lists/subscriptions + inquiries | M3 | US-061 |

## Validation

- Every story → ≥1 screen (see `../screens/README.md` coverage index). ✔
- Every screen → components (see `../components/README.md`). ✔
- Every persona referenced by ≥3 stories (see `../personas/index.yaml`). ✔
- MoSCoW realistic (above). ✔
- Index files written after individual files. ✔
