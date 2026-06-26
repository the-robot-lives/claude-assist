---
id: US-301
title: "First Encounter with Opposing-View Post"
slug: first-encounter-opposing-view-post
personas: [P-004]
epic: "Opposing-Views Lane"
priority: must-have
complexity: low
tags: [opposing-views, onboarding, discovery]
---

# US-301: First Encounter with Opposing-View Post

## User Story

**As a** cautious newcomer
**I want to** be gently introduced to the Opposing-Views Lane the first time a qualifying post appears in it
**So that** I understand why I'm seeing content from someone who disagrees with me before I feel blindsided

## Acceptance Criteria

- **Given** I have never seen the Opposing-Views Lane before
  **When** a post first qualifies to appear in it
  **Then** a one-time tooltip or card explains the lane's purpose before the post is revealed

- **Given** I dismissed the first-encounter tooltip
  **When** I return to the lane
  **Then** the tooltip does not reappear and posts display normally

## Notes
Tooltip should be dismissible with a single action and must not block the underlying post.
