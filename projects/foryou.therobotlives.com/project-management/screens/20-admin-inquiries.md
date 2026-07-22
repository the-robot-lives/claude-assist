# 20: Admin Inquiries

| Field | Value |
|-------|-------|
| ID | SCR-20 |
| Type | primary |
| Category | Admin Console |
| User Stories | US-080, US-084 |

## Description
Admin view to review submitted inquiries (including enhanced noizu.com fields),
search/filter/paginate them, and see owner notifications for new inquiries.

## Key Components
- InquiriesDataTable — submitter/site/fields/date rows
- SearchFilterBar — search + filters
- InquiryDetailPanel — full content incl. company/project/budget/timeline
- NotificationIndicator — new-inquiry signal

## Interactions
- Browse/search/filter/paginate inquiries; open detail
- Owner notified on new inquiries

## Navigation
- **From:** Admin Console (SCR-17)
- **To:** inquiry detail panel
