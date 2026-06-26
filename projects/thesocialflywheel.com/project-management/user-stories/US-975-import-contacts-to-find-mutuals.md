---
id: US-975
title: "Import Contacts to Find Potential Mutuals"
slug: import-contacts-to-find-potential-mutuals
personas: [P-003]
epic: "Insights, Analytics & Integrations"
priority: should-have
complexity: high
tags: [integrations, contacts, onboarding, mutuals]
---

# US-975: Import Contacts to Find Potential Mutuals

## User Story

**As a** Social Connector
**I want to** upload my contacts list to discover which of my existing contacts are already on Flywheel
**So that** I can quickly grow my mutuals web with people I already know.

## Acceptance Criteria

- **Given** the Connections page
  **When** I upload a CSV of email addresses with my explicit consent acknowledged
  **Then** Flywheel shows me a list of Flywheel accounts matched to those emails, without revealing the email addresses of accounts that didn't match.

- **Given** the matched account list
  **When** I select accounts and click "Send Mutual Request"
  **Then** mutual requests are sent to those accounts.

- **Given** my contact CSV after processing
  **When** the match is complete
  **Then** the uploaded file is deleted from Flywheel servers and a confirmation is shown.

## Notes

Email addresses are hashed before matching; plaintext emails are never stored. Users must affirmatively consent to the import. Matched accounts have opted in to contact-matching in their privacy settings.
