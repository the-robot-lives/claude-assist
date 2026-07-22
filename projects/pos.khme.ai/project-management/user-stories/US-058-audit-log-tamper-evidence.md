---
id: US-058
title: "Tamper-Evident, Append-Only Audit Log"
slug: "audit-log-tamper-evidence"
personas: [P-002, P-004]
epic: "Cash & Audit"
priority: "must-have"
complexity: "L"
tags: [audit, trust, security]
---

# US-058: Tamper-Evident, Append-Only Audit Log

## User Story

**As a** minimart owner (P-002),
**I want to** be confident that no one — not even a staff member with device access, and not even me by accident — can quietly edit or delete an audit entry,
**So that** the audit trail is actually trustworthy evidence, not just another editable list.

## Acceptance Criteria

- [ ] Given an audit event is written, when it is stored, then each entry is chained (e.g. includes a hash of the previous entry) so that any deletion or retroactive edit breaks the chain and is detectable.
- [ ] Given the app is used offline and audit events are queued locally, when they later sync to the backend, then the backend independently verifies the chain integrity before accepting them, rejecting any that show signs of local tampering.
- [ ] Given an owner runs an integrity check from settings, when it completes, then the app reports whether the full chain is intact or flags the specific point of a break.
- [ ] Given a device is lost, stolen, or factory-reset, when a new device syncs for that store, then the audit history is restored from the backend as the source of truth, not reconstructed from the device.

## Notes

This is the technical backbone that makes "trust through transparency" credible rather than just a slogan. Builds on [[US-056]]. Verification-only surface for staff/owners is [[US-057]]; this story is about the underlying integrity guarantee, not the browsing UI.
