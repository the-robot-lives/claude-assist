---
id: US-011
title: "Invite Contacts from Address Book"
slug: invite-contacts-from-address-book
personas: [P-003, P-004]
epic: "Onboarding & Account Setup"
priority: should-have
complexity: high
tags: [contacts, invite, mutuals, onboarding]
---

# US-011: Invite Contacts from Address Book

## User Story

**As a** social connector
**I want to** import my phone contacts and invite friends who are already on Flywheel
**So that** I can instantly bootstrap my mutuals web with people I trust

## Acceptance Criteria

- **Given** I grant contacts permission
  **When** the import runs
  **Then** existing Flywheel users in my contacts appear as "People you may know" with a one-tap mutual request.

- **Given** a contact is not yet on Flywheel
  **When** I tap "Invite"
  **Then** an SMS invite with a personalized link is sent from my device's messaging app.

## Notes
Phone numbers are hashed before upload. Permission request must include a clear explanation of how data is used. Contacts not on the platform are never stored server-side beyond the session.
