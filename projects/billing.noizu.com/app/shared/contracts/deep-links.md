# Billing Noizu Deep-Link Contract

Canonical links are web URLs. Native apps resolve these URLs through universal links, Android app links, or macOS associated domains after authorization.

| Target | URL Pattern | Native Screen |
|--------|-------------|---------------|
| Dashboard | `/` | Receivables dashboard |
| Invoice list | `/invoices?status={status}` | Invoice queue with status filter |
| Invoice detail | `/invoices?invoice={invoiceId}` | Invoice review/detail |
| New invoice | `/invoices/new?customer={customerId}` | Draft invoice creation |
| Customer detail | `/customers?customer={customerId}` | Customer billing history |
| Apps | `/apps` | Platform readiness/status |
| Audit | `/audit?event={eventId}` | Financial event trail |

## Rules

- Workspace authorization is checked server-side before record details are returned.
- Links never encode payment instruments, raw bank details, or secret tokens.
- Native apps fall back to the web app if the target platform app is unavailable.
- Offline native clients may open cached read-only records, but mutation actions require fresh server confirmation.
