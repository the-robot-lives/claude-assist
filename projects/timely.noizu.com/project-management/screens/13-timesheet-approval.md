# 13: Timesheet Approval

| Field | Value |
|-------|-------|
| ID | SCR-13 |
| Type | primary |
| Category | Billing |
| User Stories | US-061, US-062, US-063, US-064, US-067, US-068 |

## Description
Timesheet Approval supports Timely's billing workflow by exposing the evidence, task state, policy, or reporting controls implied by the linked user stories.

## Key Components
- ApprovalQueue - reusable element for this workflow.
- TimesheetSummary - reusable element for this workflow.
- CommentThread - reusable element for this workflow.
- AuditTrail - reusable element for this workflow.

## Interactions
- Approve submitted time
- Reject with comments
- Reopen with reason

## Navigation
- **From:** Dashboard, Weekly Summary
- **To:** Report Builder
