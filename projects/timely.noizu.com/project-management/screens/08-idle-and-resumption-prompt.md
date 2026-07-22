# 08: Idle And Resumption Prompt

| Field | Value |
|-------|-------|
| ID | SCR-08 |
| Type | modal |
| Category | Capture Intelligence |
| User Stories | US-041, US-042, US-043, US-044, US-047, US-048, US-049, US-050 |

## Description
Idle And Resumption Prompt supports Timely's capture intelligence workflow by exposing the evidence, task state, policy, or reporting controls implied by the linked user stories.

## Key Components
- IdleClassificationPrompt - reusable element for this workflow.
- ResumeSuggestionCard - reusable element for this workflow.
- WhereWasIPanel - reusable element for this workflow.
- PromptSnoozeControl - reusable element for this workflow.

## Interactions
- Discard idle
- Keep with reason
- Resume task
- Snooze prompts

## Navigation
- **From:** Desktop agent return event
- **To:** Daily Timeline
