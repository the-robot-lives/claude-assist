---
id: US-085
title: "Model an inquiry as a contact-list signup"
slug: model-inquiry-as-contact-list
personas: [P-003, P-004]
epic: "Inquiries & Lead Capture"
priority: should-have
complexity: medium
tags: [inquiry, list, attributes, modeling]
---

# US-085: Model an inquiry as a contact-list signup

## User Story

**As a** site owner
**I want to** inquiries captured as signups on a "contact" List
**So that** lead fields are typed attributes I can view and export like any list

## Acceptance Criteria

- **Given** a "contact" List with declared attributes
  **When** an inquiry is submitted
  **Then** a signup is created on that list with the inquiry values stored as attributes
- **Given** the contact List defines optional fields
  **When** an inquiry omits them
  **Then** the signup stores only the provided values
- **Given** an inquiry-signup exists
  **When** I view it in the admin console
  **Then** it appears in the contact list's signups table (US-075)

## Notes
Lets inquiries reuse the Lists/Attributes and admin export machinery.
