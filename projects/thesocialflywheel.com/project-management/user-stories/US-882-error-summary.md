---
id: US-882
title: "Error Summary on Form Submission"
slug: error-summary
personas: [P-008]
epic: "Accessibility & Internationalization"
priority: must-have
complexity: low
tags: [error-messaging, forms, screen-reader, wcag-2.2]
---

# US-882: Error Summary on Form Submission

## User Story

**As a** screen-reader user
**I want to** see a summary of all form errors at the top of the form when I submit
**So that** I can get an overview of what needs fixing before navigating to individual fields

## Acceptance Criteria

- **Given** I submit a form with multiple errors
  **When** validation runs
  **Then** an error summary box appears above the first field listing all errors as anchor links

- **Given** I click an error link in the summary
  **When** it activates
  **Then** focus moves directly to the corresponding invalid field

- **Given** the error summary appears
  **When** it renders
  **Then** focus is automatically moved to the summary heading so it is the first thing the screen reader announces

## Notes
The summary heading should read "There are [N] errors. Please correct the following:" followed by the error list. This pattern mirrors GOV.UK design system conventions well-tested for accessibility.
