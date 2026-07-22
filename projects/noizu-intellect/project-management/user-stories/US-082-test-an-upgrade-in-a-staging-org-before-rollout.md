---
id: US-082
title: "Test an upgrade in a staging org before rollout"
slug: test-an-upgrade-in-a-staging-org-before-rollout
personas: [P-006]
epic: "Admin & Platform Ops"
priority: could-have
complexity: high
tags: [upgrades, staging, deployment]
---

# US-082: Test an Upgrade in a Staging Org Before Rollout

## User Story

**As a** self-hosting admin/SRE
**I want to** clone or provision a staging org that mirrors production agent definitions, provider config, and model tiers, run an upgrade against it, and verify path execution still behaves correctly
**So that** I can catch breaking changes (schema migrations, provider API drift, prompt-pipeline regressions) before they hit the org my team actually depends on

## Acceptance Criteria

- **Given** I want to test an upgrade
  **When** I provision a staging org from a production org snapshot
  **Then** agent identities, provider configs (with keys re-encrypted, not copied in plaintext), and model tier definitions are cloned, while message history and long-term memory are excluded by default

- **Given** a staging org exists
  **When** I apply a platform upgrade to it (new app version, migration set)
  **Then** the upgrade runs in isolation from production, and I can execute a sample parallel-path run end-to-end (Plan → paths → Reflect → Review → pick) to confirm the pipeline still works

- **Given** a staged upgrade run in the staging org produces an error not seen in the current production version
  **When** I review results
  **Then** the error is captured with enough detail (stack trace, failing turn, agent, path) to file as a blocking issue before promoting the upgrade

- **Given** I'm satisfied with staging results
  **When** I promote the upgrade to production
  **Then** the promotion is a distinct, audited action ([[US-083]]) separate from the staging apply, so staging and production upgrade timing can differ

## Notes
This is explicitly a should-/could-have for v1 — full blue/green org cloning is heavier infra than a single-admin self-host typically needs day one, but Nadia (P-006) still wants a lower-risk path than "upgrade production and hope."
