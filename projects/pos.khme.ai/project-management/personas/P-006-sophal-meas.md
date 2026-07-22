---
id: P-006
name: "Sophal Meas"
slug: "sophal-meas"
archetype: "Numbers Keeper"
segment: "secondary"
tags: [bookkeeper, exports, reconciliation, tax-ready-reports, multi-client]
---

# Sophal Meas — Numbers Keeper

## Demographics

| Field | Value |
|-------|-------|
| **Age** | 28-45 |
| **Role** | Part-time/freelance bookkeeper serving several small merchants |
| **Technical Level** | Intermediate-to-advanced (spreadsheet-fluent) |
| **Industry** | Bookkeeping / accounting services for small retail clients |
| **Location** | Phnom Penh, works remotely across multiple client shops |

## Bio

Sophal handles the books for six or seven small merchants around the city, visiting some in person once a week and working remotely for others. She's comfortable in Excel and basic accounting software but every client hands her data in a different format — some paper, some photos of a ledger, a couple with makeshift spreadsheets — and reconciling it all consumes most of her billable hours. She's not the shop owner and has no stake in day-to-day operations, only in producing accurate, timely, tax-ready numbers.

## Goals
1. Pull clean, structured sales/expense/inventory exports from each client's shop without manual re-entry.
2. Reconcile cash-register totals against reported sales quickly, flagging mismatches for the owner.
3. Produce tax-ready summaries in the format Cambodian tax filing requires, per client, per period.
4. Serve multiple client accounts from one login without mixing up their data.

## Frustrations
1. Every client currently uses a different (or no) system, so her reconciliation process isn't repeatable.
2. Manual data entry from paper ledgers or photos is slow and error-prone.
3. No visibility into a client's daily numbers until she visits in person or is sent photos.
4. Cambodian tax reporting norms for small merchants are inconsistently understood even by clients.

## Behaviors
- Works across multiple spreadsheets and a basic accounting tool, largely client-by-client.
- Visits some clients in person weekly, communicates with others via Telegram.
- Exports data into whatever format she needs for filing, reformatting manually today.
- Values accuracy and auditability far more than visual polish in any tool she uses.

## Job to Be Done
> "When it's time to close the books for a client, I want a clean export of their sales, cash reconciliation, and stock movement, so I can prepare accurate reports without re-keying data from paper or photos."

## Relationship to Product
Sophal is typically brought in by an existing merchant client (Dara Lim or Chenda Prak) who wants their bookkeeper to have direct access rather than sending photos — her account is provisioned as a read/export-focused role on top of an existing shop's account rather than something she seeks out independently. Adoption hinges on export quality and reconciliation views: CSV/PDF exports that map cleanly to how she files, and a reconciliation report that highlights discrepancies without her having to dig. She has no interest in the sell screen, inventory scanning, or companion app — her entire relationship to the product is the reporting/export layer, ideally accessible across all her clients from one login if the product later supports it. Churn risk: exports that don't match Cambodian tax filing formats, or a permissions model that forces her to log into each client's account separately with no unified view.

## Scenarios
1. **Monthly close for a client** — At month-end, Sophal pulls a sales and cash-reconciliation export for one client's shop, cross-checks it against her own records, and flags a discrepancy for the owner to resolve.
2. **Tax-season report prep** — Ahead of a filing deadline, she generates tax-ready summaries for several clients in sequence, relying on consistent formatting across all of them to save time.
