# 16: My Inquiries & Data

| Field | Value |
|-------|-------|
| ID | SCR-16 |
| Type | settings |
| Category | Preference Center |
| User Stories | US-065, US-067, US-068 |

## Description
The account-level section of the preference center: a list of the user's
submitted inquiries and privacy controls to export or request deletion of their
data.

## Key Components
- InquiryRow — a submitted inquiry with site/date/summary/status
- Button — "export my data" / "request deletion"
- ConfirmDialog — deletion request confirmation
- EmptyState — no inquiries yet

## Interactions
- Browse my inquiries; export data; request account/data deletion (confirm flow)

## Navigation
- **From:** Preference Center (SCR-14)
- **To:** back to Preference Center
