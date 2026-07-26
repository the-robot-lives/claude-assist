# Carpet Grand Prix — Production: Budget Breakdown

Total development budget: **$944,500** — adjusted from the GDD's $919,000 for
the Swift/Metal team change in `production/team-plan.md`. The salary line goes
up (a specialist Metal engineer costs more than a generic engine engineer);
the tooling line goes down (there is no per-seat engine license to buy).

| Category | Cost | Notes |
|---|---|---|
| Salaries (11 months, 9.5 peak heads) | $692,500 | `production/team-plan.md` |
| Contract audio (music mastering, SFX library) | $18,000 | Beyond the composer's retainer; unchanged from the GDD |
| Device matrix (14 handsets, iOS + Android) | $9,500 | Sensor behaviour varies enormously by OEM — this is R-01 in the risk register, and buying real hardware to test on is the mitigation, not a nice-to-have |
| Tools & CI (Apple Developer Program, Xcode Cloud / macOS CI runners, crash + analytics SDK, code signing) | $9,000 | Down from the GDD's $16,000 "Unity Pro ×8, analytics, CI" — there is no per-seat engine license in a native Xcode toolchain; Xcode itself is free |
| External QA / accessibility audit | $22,000 | Independent audit is non-negotiable given the Audio Mode claim; unchanged from the GDD |
| Localisation (9 languages, UI only — no dialogue) | $7,500 | Wordless narrative keeps this cheap; unchanged from the GDD |
| Marketing (capture, trailer, festival submissions) | $85,000 | Weighted to the parallax demo video — the tilt-diorama effect is the single most screen-recordable thing in the game and the actual acquisition asset; unchanged from the GDD |
| Contingency (12%) | $101,000 | Applied to the $843,500 subtotal above this line |
| **Total** | **$944,500** | |

---

## Scope-honesty note

At 9.5 peak heads and 11 months of production, this budget only closes in the
**Good** revenue scenario or better (GDD §10 revenue scenarios: Floor,
Modest, Good, Breakout). If the M3 feel-lock gate fails — if testers do not
describe the tilt as natural — the correct decision is to cut to 24 courses,
4 rooms, and 8 cars, drop the animated vignettes to stills, and rebuild this
plan at ~$480,000. **That decision belongs at M3, not M9** — see
`production/milestone-schedule.md`.

This budget is a bet on the core mechanic reading as intuitive to a mass
audience, financed by a $4.99 premium purchase with no ads and no IAP to fall
back on if conversion runs soft. There is no economy to re-tune, no live-ops
lever to pull, no gacha rate to adjust. If the mechanic doesn't land at M3,
or if the demo-to-paid conversion rate comes in under the Good scenario's
6.5% assumption post-launch, there is no in-game monetization mechanism to
compensate — only a smaller sequel scope, a price change, or a marketing
spend increase, none of which are assumed in the numbers above.
