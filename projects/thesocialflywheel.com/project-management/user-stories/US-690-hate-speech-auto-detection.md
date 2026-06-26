---
id: US-690
title: "Hate Speech Auto-Detection"
slug: hate-speech-auto-detection
personas: [P-007]
epic: "Moderation & Reporting"
priority: should-have
complexity: high
tags: [auto-moderation, hate-speech, ml]
---

# US-690: Hate Speech Auto-Detection

## User Story

**As a** channel moderator
**I want to** have an ML classifier scan new posts for hate speech before they are published
**So that** egregious content is caught proactively even before community members report it

## Acceptance Criteria

- **Given** a member submits a new post
  **When** the content is scored by the hate-speech classifier
  **Then** posts with a confidence score above the platform-configured threshold are auto-held and added to the mod queue with label "Possible hate speech (auto-detected, score: X%)"

- **Given** an auto-detected post is in the mod queue
  **When** I open it
  **Then** I see the classifier score, the flagged phrases highlighted within the content, and the same action options as a human-reported post

- **Given** I dismiss an auto-detected hold as a false positive
  **When** I confirm the dismissal
  **Then** the post is published and optionally I can mark it as "False positive" to feed back to the classifier training pipeline

## Notes
False-positive feedback should be aggregated and reviewed by platform T&S before being used for retraining; no individual mod should have direct model write access.
