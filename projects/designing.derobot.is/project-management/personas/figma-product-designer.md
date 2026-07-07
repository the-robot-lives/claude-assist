# Devon Reyes — Product Designer

**Tagline:** "I live in Figma, but I'm tired of designs that die at handoff."

## Demographics / context
- 34, senior product designer at a ~60-person B2B SaaS company.
- Spends the day in Figma, Tokens Studio, and FigJam; partners with 3 frontend engineers.
- Owns the design system in Figma but doesn't own the code implementation of it.
- Measured on shipped UI quality and design-to-dev fidelity, not just mockups.

## Goals
- Produce designs that arrive in the codebase looking exactly as drawn.
- Stop being the bottleneck where pixel specs get "interpreted" and drift.
- Iterate on real type/color/spacing tokens, not detached visual approximations.
- Hand engineers something runnable, not a redline screenshot.

## Frustrations / pain points with current tools
- Figma → code is always a lossy retranslation; spacing and states get re-guessed.
- Design tokens in Figma and CSS variables in the repo drift out of sync.
- Interactive prototypes in Figma are faked clicks, not real state or data.
- She can't easily express `aria-*`/`data-*` intent that survives to the build.

## How she'd use TRFI specifically
- Builds screens in the **DSL** (or upverts from a rough sketch a teammate typed).
- Tunes **theme.yaml** seed tokens in Theme Studio and watches generated CSS update live — one source of truth for type/color/spacing.
- **Upverts** only the components that need pixel-level control (**hybrid mode**), leaving the rest as fast text.
- Annotates accessibility intent inline with **first-class `aria-*`/`data-*`** so it ships, not gets lost.
- Hands engineers **Lit components** that already match the design exactly.

## Key features she cares about
- **theme.yaml + generated CSS** — tokens are the design, and they're real.
- **Upvert / hybrid mode** — fine-grained control exactly where craft matters.
- **aria-/data- as first-class** — accessibility and behavior intent survive handoff.
- **Lit export** — what she designs is literally what ships.
- **Low-fi/high-fi toggle** — explore structure before committing to polish.

## Representative quote
> "I don't want to *describe* the spacing to an engineer. I want the spacing to be the artifact."

## Success looks like
Her designs reach production with zero "that's not what I drew" tickets, because the themed mockup and the shipped component are generated from the same tokens.
