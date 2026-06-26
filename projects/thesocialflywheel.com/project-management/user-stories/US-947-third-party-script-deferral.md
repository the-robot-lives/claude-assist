---
id: US-947
title: "Deferred Loading of Third-Party Scripts"
slug: third-party-script-deferral
personas: [P-010]
epic: "Performance, Scale & Reliability"
priority: must-have
complexity: low
tags: [third-party, scripts, defer, performance, analytics]
---

# US-947: Deferred Loading of Third-Party Scripts

## User Story

**As a** skeptical switcher whose first page load is being slowed by analytics and tracking scripts
**I want to** have non-critical third-party scripts load after the main content
**So that** my ability to read and interact with the feed is not delayed by scripts I never directly use

## Acceptance Criteria

- **Given** the app page is loading
  **When** the HTML is parsed
  **Then** all third-party analytics and chat-widget scripts have `defer` or `async` attributes and load after LCP

- **Given** a third-party script fails to load (e.g., blocked by an ad blocker)
  **When** the script error occurs
  **Then** the failure is caught gracefully and the rest of the app functions normally

## Notes
Audit all third-party script tags each release. Only essential scripts (auth, payments) may load eagerly. Block total third-party script weight to < 100 KB. Fail CI if new blocking scripts are added.
