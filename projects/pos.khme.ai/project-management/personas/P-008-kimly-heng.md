---
id: P-008
name: "Kimly Heng"
slug: "kimly-heng"
archetype: "Rural Pharmacy Owner"
segment: "edge-case"
tags: [pharmacy, expiry-batch-tracking, intermittent-power, regulatory-sensitivity, provincial]
---

# Kimly Heng — Rural Pharmacy Owner

## Demographics

| Field | Value |
|-------|-------|
| **Age** | 40-55 |
| **Role** | Owner, provincial-town pharmacy |
| **Technical Level** | Novice-to-intermediate |
| **Industry** | Pharmacy / regulated retail (pharmaceuticals) |
| **Location** | Provincial town (e.g. Battambang, Kampong Cham) |

## Bio

Kimly has run her pharmacy for over a decade, having trained as a pharmacy assistant before opening her own shop. Unlike a general minimart, her stock carries batch numbers and expiry dates that matter for both patient safety and regulatory compliance, and she deals with intermittent grid power and patchy connectivity more often than merchants in Phnom Penh. She currently tracks expiry dates with sticky notes and a memorized sense of which shelf holds the oldest stock, which she knows isn't sustainable as her inventory grows.

## Goals
1. Know which items are approaching expiry so she can discount, return to supplier, or discard them before they become a liability.
2. Track batch/lot numbers per item in case of a recall or a patient question about a specific batch.
3. Keep the register and inventory working through frequent short power outages without losing data.
4. Stay compliant with whatever regulatory record-keeping is expected of a pharmacy, not just a general shop.

## Frustrations
1. Sticky-note expiry tracking has already led to her almost selling an expired item.
2. Power cuts are common in her area; she's wary of any system that could lose data or lock her out mid-sale during an outage.
3. Generic POS/inventory tools don't have a concept of batch/lot or expiry date at all.
4. She's unsure what Cambodian pharmacy record-keeping regulations actually require and worries about being caught unprepared.

## Behaviors
- Physically checks shelf stock for near-expiry items periodically, a slow manual process today.
- Keeps a small battery backup / relies on her phone during power cuts to keep some record of sales.
- Sources some stock from suppliers who deliver irregularly, making reorder timing less predictable than a minimart.
- More risk-averse about new software than an average merchant, given the regulatory stakes of her business.

## Job to Be Done
> "When new stock arrives or expiry dates approach, I want to track batch and expiry per item and get warned before something expires, so I don't risk selling expired medicine or falling short on records I might need to show."

## Relationship to Product
Kimly represents an edge case the core v1 scope doesn't fully serve — she'll adopt the general register, stock tracking, and audit trail readily since those map directly onto her existing needs, but batch/lot and expiry-date tracking are pharmacy-specific gaps she'll notice immediately and may treat as a blocker rather than a nice-to-have. Her offline resilience bar is higher than an urban merchant's — brief unannounced power cuts are routine for her, not exceptional — so she'll stress-test the offline-first claim harder than most personas and is a good proxy user for validating it. She's cautious about new tools generally and will likely wait for local peer validation (another provincial pharmacy owner using it successfully) before switching. Churn risk: any data loss or lockout during a power cut, absence of expiry/batch tracking pushing her back to sticky notes for that specific need, or uncertainty about whether the audit trail satisfies whatever regulatory record-keeping she's expected to maintain.

## Scenarios
1. **Expiry sweep** — Once a week, Kimly reviews a list of items nearing expiry within 30 days, generated automatically from stock she received with dates entered at intake, and marks items for discount or supplier return.
2. **Power-cut sale** — Mid-transaction, the power flickers off and the tablet switches to battery; Kimly needs the sale to complete and save locally without interruption, syncing once power and connectivity return.
