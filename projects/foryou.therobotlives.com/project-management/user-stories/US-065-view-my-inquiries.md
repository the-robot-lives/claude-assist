---
id: US-065
title: "View my submitted inquiries"
slug: view-my-inquiries
personas: [P-001, P-005]
epic: "Preference Center"
priority: should-have
complexity: low
tags: [preference-center, inquiries, history]
---

# US-065: View my submitted inquiries

## User Story

**As a** signed-in person who submitted contact inquiries
**I want to** see them in my dashboard
**So that** I can track what I've asked and any follow-up

## Acceptance Criteria

- **Given** I submitted inquiries with my email
  **When** I open my dashboard
  **Then** I see each inquiry with its site, date, and content summary
- **Given** an inquiry has a status
  **When** it renders
  **Then** the status is shown
- **Given** I have no inquiries
  **When** I view the section
  **Then** I see an appropriate empty state

## Notes
Inquiries reconcile to the account by email (US-050).
