---
id: US-061
title: "View my subscriptions and inquiries in one place"
slug: unified-preference-center
personas: [P-001, P-007]
epic: "Preference Center"
priority: must-have
complexity: high
tags: [preference-center, subscriptions, inquiries, cross-site, item-6]
---

# US-061: View my subscriptions and inquiries in one place

## User Story

**As a** person with one account across the portfolio
**I want to** see all my lists/subscriptions and my inquiries on a single page
**So that** I have one authoritative view of how I'm engaged across every site

## Acceptance Criteria

- **Given** I am signed in at `/app/me`
  **When** the preference center loads
  **Then** I see my subscriptions across all portfolio sites and my submitted inquiries together
- **Given** subscriptions span multiple Services
  **When** they render
  **Then** each shows its Service, List, status, and quick actions (manage/unsubscribe)
- **Given** I have inquiries
  **When** I view the page
  **Then** each inquiry shows its site, submitted date, and summary

## Notes
MANDATORY — plan item 6. The cross-site unified dashboard. Depends on
reconcile-by-email (US-050) to attach anonymous signups.
