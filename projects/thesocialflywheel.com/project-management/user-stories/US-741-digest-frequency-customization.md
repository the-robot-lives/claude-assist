---
id: US-741
title: "Customize Email Digest Delivery Frequency and Time"
slug: digest-frequency-customization
personas: [P-006]
epic: "Notifications"
priority: should-have
complexity: medium
tags: [email, digest, preferences, notifications]
---

# US-741: Customize Email Digest Delivery Frequency and Time

## User Story

**As a** Quiet Consumer
**I want to** choose how often and at what time I receive digest emails
**So that** digests fit my schedule and I actually read them instead of ignoring them

## Acceptance Criteria

- **Given** I am in email notification preferences
  **When** I configure the digest
  **Then** I can choose frequency (daily / weekly / never) and a preferred delivery time (hour of day, day of week for weekly)

- **Given** I set a preferred delivery time
  **When** the digest job runs
  **Then** the email is delivered within 15 minutes of my configured time in my local timezone

## Notes
The first digest after onboarding defaults to daily at 8:00 AM local time. Users can change this at any time.
