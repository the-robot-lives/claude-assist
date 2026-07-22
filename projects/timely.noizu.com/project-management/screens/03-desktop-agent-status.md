# 03: Desktop Agent Status

| Field | Value |
|-------|-------|
| ID | SCR-03 |
| Type | primary |
| Category | Capture |
| User Stories | US-004, US-005, US-021, US-022, US-023, US-098, US-100 |

## Description
Desktop Agent Status supports Timely's capture workflow by exposing the evidence, task state, policy, or reporting controls implied by the linked user stories.

## Key Components
- CaptureStatusBadge - reusable element for this workflow.
- AgentHealthPanel - reusable element for this workflow.
- PauseResumeControl - reusable element for this workflow.
- PermissionRepairPanel - reusable element for this workflow.

## Interactions
- Pause or resume capture
- Inspect current app context
- Repair permissions

## Navigation
- **From:** Tray app, dashboard
- **To:** Daily Timeline, Settings
