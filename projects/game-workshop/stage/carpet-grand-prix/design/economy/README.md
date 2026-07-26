# Carpet Grand Prix — Economy

**There is no currency, no economy, and no IAP in this game.** This is a deliberate
design decision, not an unscoped feature.

## Why

Carpet Grand Prix sells a 50-second session and the premise that the toys on screen are
*yours* — bought once, owned outright, never metered. Any currency system, no matter how
softly implemented, introduces the two things that premise cannot survive:

1. **A gate on the 50-second session.** The moment a run costs a resource — energy,
   fuel, an entry ticket — the core loop (`../core-loop.md`) stops being "pick up the
   phone, play one run, put it down" and starts being "check if I'm allowed to play."
   That single change breaks the exact use case the Commuter Gamer persona (P-011) buys
   the game for.
2. **A crack in the toys-are-yours premise.** A currency implies something in the toy box
   is still for sale after the $4.99 purchase. Cars, track skins, and rooms in this game
   are earned through medals precisely so nothing ever prompts a second wallet moment —
   see `../monetization/revenue-model.md` for why premium-with-no-IAP is also the more
   economically coherent model given the tilt input's hard session-frequency ceiling.

## What replaces it

**Medals are the only progression currency.** Every unlock in the game — rooms, cars,
track skins, the story vignettes in The Box — is priced in medal counts, not in any
spendable resource (see `../meta-loop.md` for the full unlock table). Medals cannot be
farmed, traded, boosted, or purchased; the only way to earn one is to drive the course it
belongs to. This keeps the entire meta-loop legible as a single axis: better driving is
the only lever that exists, and it is the same lever whether a player is chasing their
first bronze or their hundredth Sprue.
