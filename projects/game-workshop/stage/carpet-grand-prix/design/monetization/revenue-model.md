# Carpet Grand Prix — Monetization: Revenue Model

## Model: Premium, $4.99. No ads. No IAP. No currency.

Carpet Grand Prix sells once, for $4.99, and never asks again.

## Why this model fits this game

The fiction is a kid's toy box, aimed at an audience that explicitly includes parents
buying for children — P-002 (Sarah Chen) plays with her kids watching, and the broader
persona library includes parent-buyer segments this title is positioned against. Every
F2P instrument available to a mobile racer — energy gates, gacha cars, ad breaks between
runs — actively destroys the two things this game sells: a **50-second session you can
start any time**, and **toys that are yours**. An energy gate on a toy box is a
contradiction the target audience would notice immediately.

The tilt input itself caps the addressable ad/IAP surface even if the design wanted one:
arm fatigue caps a sitting at roughly seven minutes (`core-loop.md`), which caps
ad-impression and IAP-exposure volume well below what an F2P economy needs to sustain
itself. A tilt racer simply cannot generate enough session volume per day to make an
energy-gate economy viable — so premium is not just the thematically honest choice, it is
close to the only economically coherent one.

Premium at $4.99 monetises the one moment of genuine purchase intent, and the free demo
carries the entire conversion load rather than a paywall inside the product.

## Price and structure

| SKU | Price | Contents |
|---|---|---|
| Free demo | $0 | Playroom (4 courses), 2 cars, no story. Full tilt system, unrestricted. |
| **Carpet Grand Prix** | **$4.99** | 38 courses, 7 rooms, 14 cars, full story, ghosts, Audio Mode |
| *The Garage Sale* (expansion, month 9) | $2.99 | 12 courses, 3 rooms (Shed, Loft, Driveway), 4 cars, 3 vignettes |
| Track editor update (free, month 6) | $0 | Retention + UGC sharing via deep link |

No regional discount below $2.99, and no launch discount — a launch discount on a $4.99
title trains the audience to wait for the next sale, which is a worse outcome than a
slower initial ramp at full price.

## Revenue scenarios

12 months from launch, net of a 30% platform store cut:

| Scenario | Demo installs | Demo→paid | Units | Base rev | Expansion att. | Exp. rev | **Net total** |
|---|---|---|---|---|---|---|---|
| **Floor** | 60,000 | 3.5% | 2,100 | $7,350 | 12% | $756 | **$5,674** |
| **Modest** | 250,000 | 5.0% | 12,500 | $43,750 | 18% | $6,750 | **$35,350** |
| **Good** | 900,000 | 6.5% | 58,500 | $204,750 | 22% | $38,600 | **$170,345** |
| **Breakout** | 4,200,000 | 8.0% | 336,000 | $1,176,000 | 26% | $261,200 | **$1,006,040** |

The Breakout case assumes an Apple editorial feature ("Games We Love") plus one viral
capture demonstrating the parallax effect — the single most screen-recordable moment in
the game, and the reason the tilt-diorama look, not the racing itself, is the marketing
asset (see `mechanics/primary-mechanic.md`).

## KPI targets

| Metric | Target | Rationale |
|---|---|---|
| Demo → paid conversion | ≥ 5.0% | Premium mobile demo benchmark sits at 3–7% |
| D1 retention (paid) | ≥ 55% | Short sessions, no gate, nothing standing between install and a second run |
| D7 retention (paid) | ≥ 28% | Ghost-chasing (`meta-loop.md`) is the primary D7 driver |
| D30 retention (paid) | ≥ 12% | The free track-editor update at month 6 is targeted directly at this number |
| Median sessions/day | 2.4 | Roughly two commutes |
| Median session length | 5.5 min | Sits just under the arm-fatigue ceiling described in `mechanics/primary-mechanic.md` |
| Crash-free sessions | ≥ 99.7% | |
| Refund rate | ≤ 3% | The free demo is expected to absorb the "tilt isn't for me" segment before purchase, not after |

## What is deliberately absent

There is no in-app currency, no consumable, no energy system, and no ad placement
anywhere in the product — see `economy/README.md` for the full rationale. The Garage Sale
expansion and the free track-editor update are the only two post-launch revenue or
retention levers this model uses, and both are structured as one-time content additions
rather than recurring monetisation surfaces.
