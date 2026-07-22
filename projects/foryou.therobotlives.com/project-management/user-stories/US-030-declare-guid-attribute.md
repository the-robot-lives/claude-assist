---
id: US-030
title: "Declare a guid attribute"
slug: declare-guid-attribute
personas: [P-004]
epic: "Lists & Attributes"
priority: should-have
complexity: low
tags: [attribute, guid, invite-token, no-migration]
---

# US-030: Declare a guid attribute

## User Story

**As a** Service editor
**I want to** add a guid attribute to a List
**So that** I can capture invite or referral tokens

## Acceptance Criteria

- **Given** I am editing a List's attributes
  **When** I add an attribute of type `guid`
  **Then** it accepts a valid identifier and validates its format
- **Given** a signup provides a malformed token
  **When** the form is validated
  **Then** the submission is rejected with a field-level error
- **Given** the guid is optional
  **When** a signup omits it
  **Then** the submission succeeds

## Notes
Example: `invite_token` on a Beta Access list.
