---
id: US-742
title: "Customize What Content Appears in the Email Digest"
slug: digest-content-customization
personas: [P-010]
epic: "Notifications"
priority: could-have
complexity: medium
tags: [email, digest, preferences, content]
---

# US-742: Customize What Content Appears in the Email Digest

## User Story

**As a** Skeptical Switcher
**I want to** choose which sections appear in my digest email (e.g., new moots yes, channel activity no)
**So that** the digest is relevant to me and not padded with content I do not care about

## Acceptance Criteria

- **Given** I open email digest settings
  **When** I view the content configuration
  **Then** I can toggle individual digest sections: New moots, Unread messages, Post engagement, Channel highlights, Platform announcements

- **Given** I disable "Channel highlights"
  **When** the next digest is generated
  **Then** that section is absent from my email and the digest is proportionally shorter

## Notes
At least one section must remain enabled; the system prevents disabling all sections (prompt to use "unsubscribe" instead).
