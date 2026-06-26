---
id: US-370
title: "Permanently Stop Topic in Discovery"
slug: permanently-stop-topic-in-discovery
personas: [P-005]
epic: "Discovery Engine"
priority: must-have
complexity: medium
tags: [discovery, tuning, controls]
---

# US-370: Permanently Stop Topic in Discovery

## User Story

**As a** Debate Seeker
**I want to** permanently exclude a topic from my discovery feed regardless of rotation cycles
**So that** I never see content about topics I find harmful or simply uninteresting

## Acceptance Criteria

- **Given** I have disliked a discovery item and am shown a follow-up prompt
  **When** I select "Never show this topic"
  **Then** the topic is added to my permanent exclusion list and is not reconsidered in any future rotation

- **Given** a topic is on my permanent exclusion list
  **When** a monthly rotation occurs and the algorithm would normally surface that topic
  **Then** the topic is skipped and a substitute topic is selected instead

## Notes
Permanent exclusion list is visible and editable from the Discovery Settings page (see US-381).
