# 09: Idle Gap Review Queue

| Field | Value |
|-------|-------|
| ID | SCR-09 |
| Type | primary |
| Category | Review |
| User Stories | US-041, US-042, US-043, US-044, US-050, US-061 |

## Description
Idle Gap Review Queue supports Timely's review workflow by exposing the evidence, task state, policy, or reporting controls implied by the linked user stories.

## Key Components
- GapQueueList - reusable element for this workflow.
- IdleBlock - reusable element for this workflow.
- ClassificationChips - reusable element for this workflow.
- BatchResolveControls - reusable element for this workflow.

## Interactions
- Classify gaps
- Apply batch decision
- Open related evidence

## Navigation
- **From:** Dashboard, Daily Timeline
- **To:** Daily Timeline
