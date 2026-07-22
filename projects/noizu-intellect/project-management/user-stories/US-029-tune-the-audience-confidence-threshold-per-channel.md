---
id: US-029
title: "Tune the audience-confidence threshold per channel"
slug: tune-the-audience-confidence-threshold-per-channel
personas: [P-003]
epic: "Channels & Messaging"
priority: should-have
complexity: medium
tags: [audience-confidence, threshold, channel-settings]
---

# US-029: Tune the Audience-Confidence Threshold Per Channel

## User Story

**As a** team lead
**I want to** raise or lower the confidence threshold agents use to decide whether to act on an unaddressed or `@everyone` message in a specific channel
**So that** a noisy channel doesn't get every agent jumping in, while a focused channel can be tuned to respond eagerly

## Acceptance Criteria

- **Given** a channel's settings panel
  **When** I adjust the audience-confidence threshold slider away from the default of 50
  **Then** the new threshold is saved as a channel-level setting and takes effect on the next message, not retroactively on messages already scored

- **Given** I set the threshold to 90 in a high-traffic channel
  **When** an `@everyone` message scores agents at their default baseline of 70
  **Then** no agent picks up the message automatically, and the channel shows a note that pickup requires a direct `@slug` mention at this threshold

- **Given** I lower the threshold below an agent's own configured minimum-confidence floor
  **When** the channel threshold is saved
  **Then** the system respects whichever value is higher (agent floor vs. channel threshold) and displays the effective threshold to avoid confusion

- **Given** I change the threshold
  **When** I view the channel's version history
  **Then** the change is recorded as a versioned settings edit with who changed it and when

## Notes
Threshold is orthogonal to `@slug` (always 100, always routes) per US-027. Consider exposing a per-agent override in a later iteration; out of scope here.
