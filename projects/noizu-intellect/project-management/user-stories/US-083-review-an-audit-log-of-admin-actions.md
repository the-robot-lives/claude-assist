---
id: US-083
title: "Review an audit log of admin actions"
slug: review-an-audit-log-of-admin-actions
personas: [P-006, P-007]
epic: "Admin & Platform Ops"
priority: should-have
complexity: low
tags: [audit-log, compliance, admin]
---

# US-083: Review an Audit Log of Admin Actions

## User Story

**As a** self-hosting admin/SRE
**I want to** see a chronological, filterable log of every admin action taken across the org (provider changes, role changes, budget edits, retention policy changes, upgrade promotions)
**So that** I can answer "who changed what, when, and why" without reconstructing it from memory or scattered notifications

## Acceptance Criteria

- **Given** an admin performs a tracked action (add/edit/remove provider, change a member role, edit a budget, change a retention policy, promote a staged upgrade)
  **When** the action completes
  **Then** an immutable audit log entry is written with actor, timestamp, action type, before/after values where applicable, and the affected entity's id

- **Given** I am viewing the audit log
  **When** I filter by actor, action type, or date range
  **Then** the log narrows to matching entries only, and pagination preserves the filter across pages

- **Given** an audit log entry references an entity that was later deleted (e.g. a removed provider)
  **When** I view that entry
  **Then** the entry still renders with the entity's last-known name/id rather than erroring or showing a broken reference

- **Given** I am a compliance/support role (Ken, P-007) rather than an SRE admin
  **When** I access the audit log
  **Then** I can view and export entries but cannot modify or delete them, since the log itself must stay tamper-evident

## Notes
Every other story in this epic writes into this log — [[US-075]] (providers), [[US-076]] (tiers), [[US-077]] (budgets/path caps), [[US-080]] (roles), [[US-081]] (retention), [[US-082]] (upgrade promotion). This story is the single reading surface over all of them, and is distinct from the diffable versioned-content history that already covers prompt/bio edits.
