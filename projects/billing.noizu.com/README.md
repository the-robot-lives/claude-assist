# Billing Noizu

**Domain:** billing.noizu.com
**Tagline:** Simple invoicing, client billing, and revenue tracking for Noizu projects.

## Project Idea

Billing Noizu is a FreshBooks-like invoicing tool for creating customers, sending
professional invoices, tracking payments, managing estimates, and keeping a clear
view of outstanding revenue across Noizu-operated products and services.

**Differentiator:** Billing Noizu is not a generic accounting suite. It is a
client billing operations tool built around project delivery, agent-assisted
administration, and invoice workflows that can connect to Noizu products such as
time tracking, consulting portals, support desks, and subscription systems.

## Core Use Cases

- **Customer invoicing** - create and send invoices with line items, taxes,
  discounts, terms, due dates, and branded PDF output.
- **Client management** - maintain customer profiles, contacts, billing emails,
  addresses, tax IDs, payment terms, and account notes.
- **Payment tracking** - record online payments, manual payments, partial
  payments, credits, refunds, and overdue balances.
- **Estimate to invoice flow** - draft estimates, send them for approval, and
  convert accepted estimates into invoices.
- **Expense rebilling** - attach expenses to customers or projects and convert
  billable expenses into invoice line items.
- **Revenue operations** - monitor outstanding invoices, overdue accounts, MRR,
  paid revenue, aging, and collection risk.

## Core Features

### 1. Customers And Contacts

- Customer records with company, individual, and department contacts
- Billing address, shipping address, tax ID, and default currency fields
- Default payment terms, invoice language, and delivery preferences
- Internal notes, tags, and account status

### 2. Invoices

- Draft, sent, viewed, paid, partially paid, overdue, void, and written-off states
- Line items with quantity, unit price, tax, discount, and service period
- Recurring invoice schedules for retainers and subscriptions
- Branded HTML and PDF invoice rendering
- Invoice email delivery with resend and activity history

### 3. Estimates And Proposals

- Estimate builder with reusable service items
- Customer approval status and approval timestamp
- Convert approved estimates into invoices without retyping line items
- Preserve revision history for scope and price changes

### 4. Payments And Credits

- Stripe-first online payment collection
- Manual payment entry for ACH, wire, check, cash, and external processors
- Partial payment support
- Customer credits and credit note application
- Payment reconciliation history

### 5. Expenses

- Expense capture with vendor, category, receipt, date, and amount
- Billable expense assignment to customers and projects
- Markup and tax handling for rebilled expenses
- Receipt attachment storage and export

### 6. Reporting

- Accounts receivable aging
- Revenue by customer, project, service, and period
- Paid vs outstanding invoice summary
- Tax and discount summaries
- CSV, JSON, and PDF exports

## Agent-Assisted Workflows

- Draft an invoice from approved project milestones or completed time entries
- Flag invoices that are overdue or likely to become overdue
- Summarize customer billing history before a sales or support call
- Reconcile imported payment events against open invoices
- Generate polite follow-up email drafts for overdue invoices

## Tech Stack Direction

- **Frontend:** Next.js 15, React 19, TypeScript, Tailwind CSS
- **Backend:** Phoenix 1.8, Elixir, Ecto, Oban
- **Database:** PostgreSQL
- **Payments:** Stripe for card and ACH collection
- **PDF Rendering:** HTML templates rendered to PDF through a worker
- **Storage:** S3-compatible object storage for PDFs and receipts
- **Infrastructure:** Existing Noizu Kubernetes cluster

## Data Model Sketch

- Customers
- Contacts
- Projects
- Service items
- Estimates
- Estimate revisions
- Invoices
- Invoice line items
- Payments
- Credits
- Expenses
- Attachments
- Email events
- Audit events

## MVP Scope

- Customer and contact management
- Manual invoice creation and editing
- Branded invoice PDF generation
- Invoice email sending
- Invoice status tracking
- Manual payment recording
- Stripe hosted payment link support
- Basic accounts receivable dashboard
- CSV export for customers, invoices, and payments

## Future Features

- Recurring invoices and subscription billing
- Estimate approval portal
- Expense receipt OCR
- Time tracking import from timely.noizu.com
- Customer self-service billing portal
- Multi-entity invoicing for separate brands or legal entities
- Tax rules by jurisdiction
- QuickBooks, Xero, and FreshBooks migration/import tools
- MCP interface for agent-driven billing administration

## Design Direction

- **Style:** Quiet finance operations dashboard
- **Tone:** Precise, trustworthy, and low-friction
- **Primary interaction:** Create, send, reconcile, and follow up on invoices
- **Visual priority:** Customer balance, invoice status, due dates, and payment state

## Status

Concept
