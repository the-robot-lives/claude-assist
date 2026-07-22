---
id: US-018
title: "View a turn's Plan/Reply/Reflect passes for debugging"
slug: view-a-turns-plan-reply-reflect-passes
personas: [P-002, P-001]
epic: "Agents & Cognition"
priority: must-have
complexity: medium
tags: [debugging, turn-pipeline, observability]
---

# US-018: View a Turn's Plan/Reply/Reflect Passes for Debugging

## User Story

**As a** agent designer/prompt engineer
**I want to** inspect the three internal passes (Plan, Reply, Reflect) of a single agent turn
**So that** I can see exactly what the agent reasoned before replying and what cognition patch it produced afterward

## Acceptance Criteria

- **Given** an agent has completed a turn in a channel
  **When** I open the turn's debug view
  **Then** I see the Plan pass output, the Reply pass output (what was actually posted), and the Reflect pass's structured patch, each as a separate labeled section

- **Given** the Reflect pass emitted updates to memories, observations, opinions, objectives, and reminders
  **When** I view the Reflect section
  **Then** each cognition table update is itemized with before/after values and links to the resulting cognition record (see US-016)

- **Given** a turn's Plan pass considered the audience-confidence score for the triggering message
  **When** I view the Plan pass
  **Then** the confidence value and threshold comparison that caused the agent to act (or would have caused it to skip) are shown

- **Given** a turn failed or produced an unexpected reply
  **When** I inspect the turn debug view
  **Then** I can see the raw model/provider used, token counts, and any fallback that was triggered, to distinguish a model issue from a prompt issue

## Notes
This is the primary debugging surface tying together the turn pipeline mechanic with cognition mutation. Useful for P-001 diagnosing unexpected agent behavior mid-run, and essential for P-002 prompt iteration.
