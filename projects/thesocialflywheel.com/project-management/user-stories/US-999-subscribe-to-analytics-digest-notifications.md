---
id: US-999
title: "Subscribe to Analytics Digest Notifications"
slug: subscribe-to-analytics-digest-notifications
personas: [P-009]
epic: "Insights, Analytics & Integrations"
priority: should-have
complexity: low
tags: [analytics, notifications, digest, email]
---

# US-999: Subscribe to Analytics Digest Notifications

## User Story

**As a** Creator
**I want to** opt in to a weekly or monthly digest notification that summarizes my key analytics highlights
**So that** I can stay informed about my content performance without logging in daily

## Acceptance Criteria

- **Given** Settings > Notifications
  **When** I enable the Analytics Digest and choose weekly or monthly frequency
  **Then** I receive an email and/or in-app notification on the chosen schedule with: top post of the period, total reach, new mutuals, and engagement rate trend (up/down arrow vs. prior period)

- **Given** the digest notification email
  **When** I click "View full analytics"
  **Then** I am taken directly to my analytics dashboard with the matching date range pre-selected

## Notes
Digest format is accessible plain-text plus HTML. Users can opt out at any time via the notification settings or the unsubscribe link in the email. Digest is not sent if the account had no activity in the period.
