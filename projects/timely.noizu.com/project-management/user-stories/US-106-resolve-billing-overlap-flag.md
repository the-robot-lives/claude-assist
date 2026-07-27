---
id: US-106
title: "Resolve a billing overlap flag"
slug: resolve-billing-overlap-flag
personas: [P-001, P-002, P-006]
epic: "Sync & Multi-Device"
priority: must-have
complexity: medium
tags: [sync, billing]
---

# US-106: Resolve a billing overlap flag

## User Story

**As a** billing admin or consultant
**I want to** see when two billable spans overlap in time but bill to different clients
**So that** I catch a double-booking before it reaches an invoice, without the system silently choosing a client for me

## Acceptance Criteria

- **Given** two spans intersect in time by more than 60 seconds, both are marked billable, and their resolved client ids differ (including one being null)
  **When** the second span is created or updated
  **Then** the server raises a `billing_overlap` review reason on BOTH rows - it never trims, splits, or reassigns either span automatically

- **Given** two billable spans overlap but resolve to the SAME client
  **When** the overlap is evaluated
  **Then** no `billing_overlap` flag is raised - overlapping parallel work for one client is the product's normal case, and the weighted rollup in the summary report splits the contested time instead of double-billing it

- **Given** a `billing_overlap` flag is open on a span
  **When** I generate an invoice or export a report that includes it
  **Then** the flag is visible in the report before export, not discovered after the fact

## Notes

See docs/SYNC-PROTOCOL.md §8.2 (conflict matrix rule 9) and §12 (worked example T5, which shows the un-flagged same-client case). Cross-reference US-061 (create invoice report) and US-105 (the sibling suspected-duplicate flag - same design principle, different trigger condition).
