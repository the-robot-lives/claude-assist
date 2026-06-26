---
id: US-091
title: "Moderator Suspicious Activity Dashboard"
slug: moderator-suspicious-activity-view
personas: [P-007]
epic: "Authentication & Security"
priority: could-have
complexity: high
tags: [moderator, security, suspicious-activity, dashboard]
---

# US-091: Moderator Suspicious Activity Dashboard

## User Story

**As a** channel moderator
**I want to** see a summary of accounts in my channel flagged for suspicious login behavior
**So that** I can proactively identify potentially compromised accounts spreading spam or harm

## Acceptance Criteria

- **Given** I open the Moderation Dashboard
  **When** I navigate to the "Security Signals" section
  **Then** I see a list of accounts with active suspicious-login flags, the flag reason, and available actions (flag for review, force reset, ban)

## Notes
Moderators see flag signals only, not raw IP addresses or session data (privacy protection).
