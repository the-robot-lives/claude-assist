---
id: US-543
title: "Report an Abusive Message"
slug: report-an-abusive-message
personas: [P-004]
epic: "Chat & Real-time Messaging"
priority: must-have
complexity: medium
tags: [report, safety, moderation, trust-and-safety]
---

# US-543: Report an Abusive Message

## User Story

**As a** Cautious Newcomer (P-004)
**I want to** report a specific message that I find abusive or violating community guidelines
**So that** the Trust & Safety team can review it and take appropriate action

## Acceptance Criteria

- **Given** I long-press or hover a message
  **When** I select "Report message"
  **Then** a categorized report form opens (Harassment, Hate speech, Spam, Violence, NSFW, Other) and I can add an optional note before submitting

- **Given** I submit a report
  **When** the report is processed
  **Then** I receive an in-app acknowledgement that my report was received and will be reviewed, along with the option to block the sender immediately

- **Given** I report a message in a channel
  **When** the channel moderator is notified
  **Then** the message is flagged in the moderation dashboard and the moderator can act independently of the T&S review

## Notes
The reported user is not notified that they were reported. Report data is retained for 24 months for legal purposes.
