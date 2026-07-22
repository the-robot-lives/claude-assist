---
id: US-008
title: "Accept terms of service and org policies"
slug: accept-terms-of-service-and-org-policies
personas: [P-006]
epic: "Onboarding & Identity"
priority: must-have
complexity: low
tags: [terms-of-service, compliance, legal, onboarding]
---

# US-008: Accept Terms of Service and Org Policies

## User Story

**As a** self-hosting admin/SRE bringing a new instance online
**I want to** require every account to explicitly accept the instance's terms of service (and any org-specific usage policy I define) before they can act, with each acceptance versioned and timestamped
**So that** I have an auditable record of consent and can update policy text later without silently applying it retroactively to people who agreed to an older version

## Acceptance Criteria

- **Given** a new account completes signup ([[US-001]]) for the first time
  **When** they reach the point of creating or joining an org
  **Then** they must explicitly accept the current versioned terms-of-service text before the org-creation/join action proceeds — no implicit "continuing means agreeing"

- **Given** I (as admin) publish a new ToS version
  **When** an existing user with a prior acceptance next logs in
  **Then** they are blocked from further action until they re-accept the new version, and both the old and new acceptance events remain in the audit log with their respective ToS version IDs

- **Given** an org owner has defined an org-specific usage policy in addition to the instance-wide ToS
  **When** a human is invited into that org ([[US-003]])
  **Then** acceptance of the org policy is captured as a separate versioned record at invite-acceptance time, distinct from the instance ToS acceptance

- **Given** I query the acceptance audit log for a given account
  **When** I look up their consent history
  **Then** I can see every ToS/policy version they accepted and the timestamp, immutable and non-editable after the fact

## Notes
Acceptance records should reuse the platform's versioned-content mechanic (immutable, diffable rows) rather than a bespoke boolean flag, so policy text itself stays auditable the same way agent profile prompts are. Downstream investigation tooling for [[P-007]] (Ken Watanabe) would consume this log but is out of scope for this story.
