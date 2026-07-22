---
id: US-060
title: "Staff Accounts with PIN Login"
slug: "staff-account-pin-login"
personas: [P-002, P-003]
epic: "Staff & Admin"
priority: "must-have"
complexity: "M"
tags: [staff, authentication, shift]
---

# US-060: Staff Accounts with PIN Login

## User Story

**As a** cashier (P-003),
**I want to** log into the shared register with a short numeric PIN tied to my own staff account,
**So that** I can start my shift quickly without typing a full username/password, while every action I take is still attributed to me personally.

## Acceptance Criteria

- [ ] Given an owner has created a staff account for me, when I enter my assigned PIN on the register's lock screen, then I am logged in as myself within a few seconds.
- [ ] Given I enter an incorrect PIN, when the attempt fails, then the app shows a generic error without revealing whether the PIN is close or which part is wrong, and after a configurable number of failed attempts, locks that PIN entry point for a cooldown period.
- [ ] Given I am logged in, when any transaction, void, or drawer action occurs, then it is attributed to my staff ID for the audit trail per [[US-056]].
- [ ] Given the register is idle for a configurable timeout, when the timeout is reached, then the current staff member is automatically logged out and the lock screen returns.

## Notes

PINs are per-store, unique per staff member within that store; not a substitute for the owner's own account credentials. Feeds every subsequent action requiring staff attribution. Related: [[US-061]] (roles), [[US-063]] (shift open ties to login).
