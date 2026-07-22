---
id: P-007
name: "Marcus Webb"
slug: marcus-webb
archetype: "The Listener"
segment: edge-case
tags: [accessibility, screen-reader, keyboard-only, wcag, reduced-motion]
---

# P-007: Marcus Webb

## Demographics

| Attribute | Value |
|-----------|-------|
| Age | 41 |
| Occupation | Senior Developer (backend/platform) |
| Location | Toronto, Canada |
| Tech comfort | high |

## Bio
Marcus is blind and has worked as a professional software developer for close to two decades, almost entirely via screen reader — primarily in the terminal, with a browser screen reader (NVDA/JAWS-equivalent workflow) for anything that requires a GUI. He is extremely fast with keyboard-only navigation and has little patience for interfaces that assume sighted, mouse-driven interaction as the default and treat accessibility as an afterthought bolted on later.

## Goals
- Use every core feature of the product — `/query`, flashcards, quizzes, simulations, learning plans — entirely through keyboard and screen reader, with no mouse-dependent or visual-only interaction required.
- Get terminal output that reads cleanly and predictably through a screen reader: no dense box-drawing ASCII art standing in for information, no meaning conveyed by color alone.
- Use the quiz React SPA with full WCAG conformance — proper focus management, semantic markup, and no motion or animation that isn't controllable.
- Trust that accessibility isn't a separate, lagging mode but a first-class, continuously verified property of the product.

## Frustrations
- Terminal UIs that rely on elaborate box-drawing or spatial layout to convey structure force him to mentally reconstruct meaning his screen reader can't linearize cleanly.
- Web apps that pass a cursory glance but fail on keyboard-only navigation the moment he tries to actually complete a flow (focus traps, unlabeled interactive elements, unannounced dynamic content).
- Animations or transitions that can't be disabled and interfere with his screen reader's ability to track focus and content changes.
- Being treated as an edge case that's "nice to fix eventually" rather than someone who needs the product to work today, at the same feature parity as any other user.

## Behaviors
- Runs `robot-learns` entirely from the terminal for `/query`, `/flashcard`, `/learning-plan`, and `/simulate` — this is his primary, near-exclusive interaction mode and it needs to be complete on its own, not a stripped-down fallback.
- When he does use the quiz SPA, navigates it purely by keyboard (Tab, Enter, arrow keys, screen-reader-specific navigation commands) and immediately notices any element that doesn't announce its role, state, or label correctly.
- Sets any available "reduced motion" or animation-disabling preference immediately upon first use of a visual interface.
- Tests new tools methodically: he'll deliberately try to break keyboard flows (skip a step, tab past an expected stop, trigger an error state) to see whether the interface degrades gracefully or silently fails.
- Vocal, credible, and specific in feedback — cites exact ARIA attributes or announced text that's wrong rather than vague complaints, which makes his reports unusually actionable.

## Job to Be Done
> "When I use any part of this product, I want every interaction — terminal or browser — to be fully operable and legible through keyboard and screen reader, so I get the same functionality and quality of experience as a sighted, mouse-using developer, not a degraded fallback."

## Relationship to Product
Marcus is the edge-case persona whose needs, if genuinely met, raise the baseline quality of the product for everyone — clean, linear terminal output and well-structured, keyboard-navigable UI tend to be better for all users, not just screen reader users. He is the primary validator for two distinct surfaces: the CLI/TUI output (must avoid meaning-through-visual-layout-alone) and the React quiz SPA (must be WCAG-conformant with real focus management, not just passable automated-audit scores). Because his usage is thorough and methodical, he is likely to surface accessibility regressions early and precisely, before they reach a broader user base. He has essentially no interest in the future cloud phase beyond expecting it not to regress the accessibility bar already established locally.

## Scenarios
- **Scenario 1: A Clean Terminal Answer** — Marcus asks `/query` a nuanced backend architecture question. The response reads linearly through his screen reader — headings and structure conveyed through actual semantic cues rather than ASCII box-drawing or table alignment that only makes sense visually.
- **Scenario 2: Keyboard-Only Quiz** — Marcus takes a `/quiz` session in the React SPA entirely by keyboard: tabbing through questions, selecting answers via Enter/Space, and having his screen reader correctly announce which question he's on, how many remain, and whether an answer was marked correct — with no unannounced dynamic content changes and all motion effects disabled by his stated preference.
- **Scenario 3: Simulation Without Visual Cues** — Marcus runs a `/simulate` terminal role-play scenario and confirms that all state changes and prompts are conveyed in text his screen reader can read in order, with no information (like a "warning" state) conveyed through color or symbol alone without an accompanying text label.
