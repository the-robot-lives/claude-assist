---
id: US-039
title: "Run a walk-the-shelves counting session"
slug: "walk-the-shelves-count"
personas: [P-005]
epic: "Companion App"
priority: "must-have"
complexity: "L"
tags: [companion-app, counting, offline]
---

# US-039: Run a walk-the-shelves counting session

## User Story

**As a** stockroom clerk (P-005),
**I want to** walk through the shop with my phone, scanning or selecting each item and entering what I physically count,
**So that** the system's stock numbers get reconciled to reality in one focused pass, without needing a paper clipboard and a separate data-entry step later.

## Acceptance Criteria

- [ ] Given I start a new count session, when I choose scope (whole shop, one category, or one shelf/section), then the app presents items in that scope one at a time or as a scannable list, and tracks which have been counted vs. not yet.
- [ ] Given I scan or select an item during the session, when I enter a counted quantity, then it's held as a pending count (not yet applied to live stock) until I explicitly submit the session.
- [ ] Given my counted quantity differs from the system's expected quantity, when I enter it, then the app shows the delta inline (e.g. "system says 40, you entered 35, −5") so I notice large discrepancies before moving on, without blocking me from continuing.
- [ ] Given I submit a completed session, when it processes, then it generates stock adjustments with reason "count-correction" ([[US-033]]) for every item with a delta, and leaves unchanged items untouched.
- [ ] Given I pause mid-session (phone locks, interruption), when I reopen the app, then the session resumes exactly where I left off, with all entered counts preserved.

## Notes

This is the core companion-app feature and the largest story in this epic — session state machine (in-progress/paused/submitted), scope selection, and delta display all need to work reliably offline. Depends on offline sync foundation, [[US-044]]. Related: [[US-030]], [[US-041]].
