# Marcus Bell — Agency / Independent Consultant

**Tagline:** "I win the deal by demoing a product that looks shipped — then I actually ship it."

## Demographics / context
- 42, runs a 6-person product studio; pitches new client engagements weekly.
- Sells outcomes: a believable working demo closes contracts faster than slides.
- Manages many client projects in parallel, each with its own brand/theme.
- Hands finished work to client engineering teams across varied stacks.

## Goals
- Walk into a pitch with a convincing, on-brand, interactive demo of the client's product.
- Spin up a new client's look from a few brand tokens, not a from-scratch redesign.
- Reuse the demo as the actual deliverable so pre-sales work isn't wasted.
- Deliver components the client's team can adopt regardless of their framework.

## Frustrations / pain points with current tools
- Building a credible pitch demo is hours of throwaway Figma or hand-code.
- Re-skinning a demo for each client's brand means redoing the styling every time.
- Clients ask "can it actually do X?" and the faked prototype can't.
- The polished demo can't be handed over as code, so the studio rebuilds it post-signature.

## How he'd use TRFI specifically
- Reuses a library of DSL screens, swapping each client's **theme.yaml** seed tokens to instantly rebrand.
- Presents mostly **high-fi** but uses the **scoped toggle** to keep speculative areas low-fi ("here's where the roadmap goes").
- Wires an **FSM + real API/LLM** path so the one feature the client doubts actually works live in the room.
- After signing, **upverts** the hero screens (**hybrid**) for production polish and **exports Lit** for the client's stack — Vue, React, or Phoenix.
- Uses **MCP/the robot** to regenerate variants quickly between meetings.

## Key features he cares about
- **theme.yaml** — instant per-client rebrand from a handful of tokens.
- **FSM + API/LLM** — answer "can it do X?" by doing X, live.
- **Scoped low-fi/high-fi** — sell the vision while flagging what's notional.
- **Upvert/hybrid + Lit export** — the pitch demo becomes the shippable deliverable.
- **MCP-managed** — fast regeneration and variant turnaround.

## Representative quote
> "Clients buy what they can see working. With TRFI the thing I demo to win the deal is the thing I deliver after."

## Success looks like
He closes an engagement off a live, on-brand, actually-working demo, then ships the same artifact as Lit components into the client's stack — no rebuild between pitch and product.
