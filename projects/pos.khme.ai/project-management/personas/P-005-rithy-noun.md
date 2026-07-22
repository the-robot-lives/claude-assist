---
id: P-005
name: "Rithy Noun"
slug: "rithy-noun"
archetype: "Stockroom Runner"
segment: "secondary"
tags: [inventory-clerk, mobile-companion-app, receiving, shelf-counts, scan-unknown-items]
---

# Rithy Noun — Stockroom Runner

## Demographics

| Field | Value |
|-------|-------|
| **Age** | 20-30 |
| **Role** | Inventory clerk / stock handler |
| **Technical Level** | Intermediate |
| **Industry** | Retail / minimart back-of-house |
| **Location** | Minimart or small chain, Phnom Penh or provincial town |

## Bio

Rithy spends his shift on his feet in the stockroom and aisles rather than at the register, physically receiving deliveries, counting shelves, and flagging anything that looks wrong. He's the person who actually knows what's really on the shelf versus what the system claims, and he's frustrated when the tools he's given don't match how he actually moves through the store. He lives on his phone for work — the register screen is someone else's job.

## Goals
1. Receive a shipment against a purchase order quickly, flagging discrepancies on the spot.
2. Do a physical shelf count without carrying a clipboard, syncing counts directly to the system.
3. Handle unfamiliar items (no barcode match, new supplier product) without blocking the receiving process.

## Frustrations
1. Discrepancies between what's physically on the shelf and what the system says go unresolved for days.
2. Unlabeled or unknown-barcode items force him to set them aside or guess at manual entry.
3. Paper-based counting is slow and error-prone, and results get lost or transcribed wrong later.
4. Weak signal in the stockroom (concrete walls, back of building) makes real-time sync unreliable.

## Behaviors
- Walks the aisles with his phone, scanning barcodes as he goes.
- Physically opens and checks delivery boxes against supplier invoices before shelving.
- Reports discrepancies verbally to the owner/manager today rather than through any system.
- Comfortable with a scan-first workflow; impatient with manual text-entry forms.

## Job to Be Done
> "When a shipment arrives or I'm doing a shelf count, I want to scan items as I go and have discrepancies flagged automatically, so I don't have to reconcile everything by memory or paper later."

## Relationship to Product
Rithy is a secondary user who is handed the companion app by his employer (Dara Lim or Chenda Prak) rather than discovering it himself — his adoption is really about whether the mobile companion mode fits his physical workflow on day one. He lives almost entirely in receiving, shelf-count, and scan-unknown-item flows and never touches the register or reporting screens. The scan-unknown-item AI-assisted quick-add is his single most valuable feature since it's his most common daily friction point; offline-first behavior is critical since he works in low-signal stockroom areas. Churn risk: if the companion app requires connectivity to function, or if scanning/counting is slower than his current mental-tally-plus-verbal-report method, he'll revert and the inventory data will silently go stale.

## Scenarios
1. **Receiving a shipment** — Rithy scans each item as a delivery is unboxed, matching quantities against the expected purchase order and flagging any item that's short, damaged, or unlisted.
2. **Unknown item at intake** — He scans a barcode that isn't in the catalog yet; the app walks him through a quick-add flow with AI-suggested category and name so the item can be shelved and sold immediately.
