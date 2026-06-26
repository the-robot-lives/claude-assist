---
id: US-734
title: "Unsubscribe From Marketing Digest Emails"
slug: unsubscribe-marketing-digest
personas: [P-010]
epic: "Notifications"
priority: must-have
complexity: low
tags: [email, unsubscribe, opt-out, marketing]
---

# US-734: Unsubscribe From Marketing Digest Emails

## User Story

**As a** Skeptical Switcher
**I want to** unsubscribe from marketing and promotional digest emails in one click
**So that** I can separate transactional notifications (matches, DMs) from promotional content I did not want

## Acceptance Criteria

- **Given** I receive a marketing or digest email
  **When** I click the "Unsubscribe" link in the email footer
  **Then** I am taken to a confirmation page that unsubscribes me from that email type within 2 seconds, with no further emails of that type sent

- **Given** I have unsubscribed from marketing emails
  **When** I open notification preferences in the app
  **Then** the marketing digest toggle is shown as disabled and reflects the unsubscription

## Notes
Unsubscribe must comply with CAN-SPAM and GDPR requirements. Transactional notifications (security, account actions) are not affected by marketing unsubscribe.
