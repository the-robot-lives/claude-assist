---
id: US-082
title: "Submit a basic inquiry"
slug: submit-basic-inquiry
personas: [P-005, P-001]
epic: "Inquiries & Lead Capture"
priority: must-have
complexity: low
tags: [inquiry, contact, public]
---

# US-082: Submit a basic inquiry

## User Story

**As a** visitor
**I want to** send a simple inquiry with my name, email, and message
**So that** I can make contact without creating an account

## Acceptance Criteria

- **Given** a contact form
  **When** I submit name, email, and a message
  **Then** the inquiry is recorded without requiring authentication
- **Given** a missing required field
  **When** I submit
  **Then** I see a field-level validation error
- **Given** a successful submission
  **When** it completes
  **Then** I see a confirmation (US-083)

## Notes
Uses the existing global `inquiries` table.
