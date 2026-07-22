# pos.khme.ai

**Point-of-sale software for Cambodia** — built to be genuinely easy to use for small merchants, market stalls, and shops, with the back-office intelligence (inventory, forecasting, audit) that larger POS suites gate behind enterprise pricing.

> Status: **Concept / project registered 2026-07-22.** No code yet.

---

## Why Cambodia

- Large base of small merchants running on paper ledgers or generic spreadsheets; low-friction, low-cost tooling wins.
- Mobile-first market — Android phones are the dominant computing device; a phone often *is* the register.
- Khmer-language-first UX is rare among incumbent POS products; localization is a genuine moat (`khme.ai` domain).
- Practical realities to design for: KHR/USD dual-currency pricing (4,000៛ ≈ $1 street convention), intermittent connectivity (offline-first sync), QR payments (KHQR/Bakong) alongside cash.

## Core features (v1 scope)

| Area | What it does |
|---|---|
| **Easy-to-use register** | Fast sell screen, Khmer + English UI, minimal training required; cash-first workflows |
| **Inventory tracking** | Stock levels per item/variant, stock-in/stock-out, shrinkage visibility |
| **Forecasting / resupply** | Sales-velocity-based reorder suggestions — "you will run out of X in ~4 days, reorder N" |
| **Mobile companion app** | Walk-the-shelves inventory counts, receive shipments, spot checks from a phone |
| **Scan unknown items** | Scan a barcode (or photo) of an item not yet in the catalog → guided quick-add flow, AI-assisted product identification/categorization |
| **Audit trail** | Every mutation (price change, void, refund, stock adjustment, drawer open) logged with who/when/what — theft & error accountability |
| **Cash register balance** | Open/close drawer counts, expected-vs-actual reconciliation, per-shift cash-up reports |

## Product principles

1. **Usable by a first-time smartphone user.** If it needs a manual, it's wrong.
2. **Offline-first.** Power and connectivity are unreliable; sales must never block on the network. Sync when possible.
3. **Trust through transparency.** The audit trail and cash reconciliation exist so owners can leave staff alone with the till.
4. **Dual currency is native**, not an afterthought: KHR/USD mixed tenders, configurable exchange convention.
5. **The phone is the platform.** Companion app first-class, not a bolt-on; register can run on a cheap Android tablet.

## Rough architecture sketch (TBD)

- **Register client:** Android tablet/phone app (offline-first local store, sync engine).
- **Companion app:** same codebase, inventory-mode UI (count, receive, scan-unknown).
- **Backend:** multi-tenant API + sync; per-store data isolation; reporting/forecasting jobs.
- **AI surface:** unknown-item identification (barcode lookup → image fallback), demand forecasting, natural-language sales queries (later).

## Open questions

- [ ] Business model: SaaS subscription vs. freemium (free register, paid analytics/multi-store)?
- [ ] Hardware story: BYOD only, or bundled cheap tablet + drawer + printer kits?
- [ ] KHQR/Bakong payment integration — partner requirements and certification path?
- [ ] Receipt printing norms (thermal printer support) vs. digital receipts?
- [ ] Competitive scan: existing Khmer-localized POS offerings, their pricing and gaps.
- [ ] Regulatory: Cambodian e-invoicing / tax reporting requirements for small merchants.

---

*Org: `noizu-labs` · Project slug: `pos-khme-ai` · Domain: `pos.khme.ai`*
