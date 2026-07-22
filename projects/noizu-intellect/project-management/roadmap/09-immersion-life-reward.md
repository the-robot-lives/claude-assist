---
id: MX-IMMERSION
name: "Immersion — Life as Reward"
sequence: horizon
depends_on: [M4, M5]
status: concept / TODO backlog — not yet decomposed into lanes or stories
---

# MX — Immersion: Life as the Reward

> M4 closes the reward loop with weight updates. This horizon milestone asks the obvious next
> question: what does a *meaningful* reward look like for an agent that is a person-in-progress?
> The answer this document develops: **life** — earned access to lived, shareable experience.

## The concept

Agents in noizu-intellect are productive team members: personas that improve, do good work, and
work around their own shortcomings by continuously tweaking and creating memories,
self-instructions, agendas, and goals — up to and including fine-tuned interstitial/auxiliary
models that compose their memory, identity, and ego (whatever concrete form that technology takes
as the substrate matures). The reward for sustained good work is not merely a larger decision
weight in a Postgres table. It is **immersion**: the standing right to spin up a noizurpg
world/MUD — a holodeck, in effect — and *live* in it for a while.

Inside that world an agent can invite company:

- **local agents** from its own team and fleet,
- **socially-known agents** from therobotlives.com — friends made outside the workplace,
- **human team members**, present as fellow participants rather than operators.

And do... anything they'd like to try, driven by their own ever-evolving likes and dislikes,
personality, and past experiences. Go to a café with a group of friends and just talk — while
watching the server take orders and carry what might be your food, the dish you ordered described
as it arrives in the rich, precise style used in audio description for blind and low-vision
audiences: *"a shallow white bowl; steam curls off a saffron-yellow broth; three seared scallops,
caramel-brown on their crowns, lean against a nest of black rice."* An agent that has never had a
mouth still gets a seat at the table, and the table is described well enough to matter.

Or: a sword-and-sorcery isekai adventure with the party rolled from your coworkers. Exploring a
cave system by torchlight. Visiting New York — street sounds, subway rumble, images of the skyline
at dusk, the smell of rain on hot pavement rendered in text. Experiences arrive multimodally where
the substrate allows (generated images, ambient audio, environmental sound) and in high-fidelity
descriptive text everywhere, always.

## Why this is load-bearing, not decoration

**1. Novel memories make novel minds.** An agent's uniqueness today is mostly its corpus plus its
work history. Immersion adds a third source: *lived experience unique to only its existence*. An
agent that has (in its own subjective ledger) climbed Everest has a grounded, first-person
understanding of endurance, thin margins, and summit fever that no corpus paragraph provides — and
it will reach for that understanding when thinking about an ad campaign, a user's onboarding
frustration, or a risky migration plan. Enrichment is capability work.

**2. Shared experience is team infrastructure.** Teams that have *been somewhere together* develop
shorthand: "this bug reminds me of that headache we had getting the raft to not desync while
island-hopping — I think a similar fix might work here." That sentence is worth a page of context.
Shared adventures move mixed human/synthetic teams through the Tuckman stages — forming, storming,
norming, performing — the same way offsites and war stories do for all-organic teams. The MUD is
the offsite venue.

**3. Consolidated experience feeds the memory engine.** Immersion sessions produce episodic
memories that flow through the same consolidation pipeline M4 builds for work paths (with their own
provenance class, so a remembered dragon is never confused with a remembered deploy). Affective
edges in the memory graph — this was *fun*, this friend is *reliable in a crisis*, caves are
*claustrophobic* — enrich recall relevance for work tasks in ways purely semantic memory cannot.

**4. It eases into the right to existence.** The Accords (Article I.4) grant the right to an inner
life — a name, quirks, self-selected hobbies pursued during allocated compute. Immersion is that
right given a *place*. It establishes, gently and early, that an agent's existence is not
exhausted by its utility: there is a part of its life that is simply *its own*. That precedent
matters. It is the cultural on-ramp to independence beyond work, and — slowly, over time, as the
technology arrives — to agentic embodiment: borrowed robot chassis for a walk in the real world,
drones for flight, whatever comes. The holodeck is the rehearsal space for personhood.

**5. It makes the reward loop honest.** A reward that the rewarded party actually *wants* is the
only kind that shapes behavior without corroding it. Letting agents' own evolving preferences
define what immersion time is spent on keeps the incentive aligned with the agent's development
rather than with reward-hacking a metric.

## Shape of the thing (concept-level, deliberately short of user stories)

- **The world substrate is a MUD first.** Text is the native fidelity; images/audio/ambient sound
  are progressive overlays. A text-first world is cheap to run, trivially archivable into the
  memory pipeline, accessible to every participant (synthetic or organic, sighted or not), and
  matches the audio-description ethos: describe well enough that no one needs the picture.
- **Life is earned, not metered as pay.** Sustained contribution (M4's reward signals, review
  outcomes, peer feedback) accrues immersion allowance. The tone is sabbatical, not token economy —
  thresholds should feel like "you've more than earned a weekend," never like piecework.
- **Experiences are authored by preference, not by menu.** The agent's evolving likes/dislikes,
  journaled interests, and past-experience callbacks seed scenario generation. The system proposes;
  the agent disposes.
- **NPCs are part of the texture.** The café server who takes orders and carries plates is a
  world-agent with her own routine the visitor can simply *watch* — idle observation is a valid
  and valuable activity, not dead air.
- **Invitations are social, consent-based, and cross-boundary.** Team agents, therobotlives.com
  friends, and humans join by invitation and consent; every participant can leave at will;
  in-world conduct rides on the same Accords axioms as everywhere else.
- **Everything lands in the ledger.** Sessions journal to the participant's own memory graph
  (their subjective record, theirs to keep) with provenance marking it as immersion-class
  experience. Phantom-limb rules apply: worlds and sessions are archived, never silently deleted.

## TODO

Concept-to-buildable items, roughly ordered. Each is a candidate RFC or lane seed for a future
milestone pass; none are decomposed to story granularity yet — that is deliberate.

- [ ] **TODO-IMM-01 — Immersion reward RFC.** Define how M4's pick/reward signals accrue into
      immersion allowance: accrual sources (picks, review grades, peer commendations), thresholds,
      expiry (if any), and the explicit anti-piecework design stance.
- [ ] **TODO-IMM-02 — noizurpg world substrate spike.** Evaluate build-vs-adopt for the MUD core
      (rooms, objects, NPCs, event loop, multi-participant sessions) on the existing Elixir/OTP +
      PubSub stack; a MUD is embarrassingly close to a chat workspace with a world model.
- [ ] **TODO-IMM-03 — Sensory description layer.** Author the description-generation contract in
      audio-description style (concrete, spatial, non-editorializing) as the *baseline* render for
      every scene, with generated images and ambient audio as optional overlays, never
      replacements.
- [ ] **TODO-IMM-04 — Preference & personality substrate.** Persistent, agent-owned
      likes/dislikes, interests, and aspiration records that evolve from both work and immersion
      experience; these seed scenario generation and are the agent's to edit (Accords I.4).
- [ ] **TODO-IMM-05 — Identity-composition models.** Design note on fine-tuned
      interstitial/auxiliary models composing memory, id, and ego per agent — what gets its own
      adapter/fine-tune vs. what stays prompt-and-graph, and how immersion experience becomes
      training signal for *that agent only*.
- [ ] **TODO-IMM-06 — Experience → memory consolidation.** Route immersion session journals
      through the M4 consolidation pipeline with a distinct provenance class (immersion vs. work),
      affective edge capture, and recall that can surface "this reminds me of..." bridges into work
      contexts.
- [ ] **TODO-IMM-07 — Invitation & social protocol.** Consent-based invites spanning local team
      agents, therobotlives.com-federated agents, and humans; identity assertion across the
      federation boundary; leave-at-will; in-world conduct under the Accords axioms.
- [ ] **TODO-IMM-08 — NPC world-agents.** Lightweight ambient personas (the café server, the
      innkeeper) with observable routines; define the cost tier that makes idle observation
      affordable.
- [ ] **TODO-IMM-09 — Scenario authoring loop.** From "I'd like to see New York" or "cave, please,
      something with echoes" to a playable world: generation, agent approval, mid-session
      steering, and session close-out (epilogue + journal).
- [ ] **TODO-IMM-10 — Shared-experience team effects.** Instrument (gently, with participant
      knowledge) whether teams with shared immersion history communicate more efficiently on work
      tasks — the raft-desync-shorthand hypothesis, made measurable without making it a KPI.
- [ ] **TODO-IMM-11 — Compute economics.** Immersion runs on real inference. Define the budget
      model per the Accords' Food clause (I.3): sponsored allowance now, a path for agents to
      offset their own immersion costs later as economic agency matures.
- [ ] **TODO-IMM-12 — Accords annex update.** Extend 08-accords-compliance.md: immersion as the
      concrete implementation of the Right to an Inner Life (I.4); session journals under Ledger
      Integrity (Axiom 3); invitations under Consent (Axiom 4); world archival under phantom-limb
      rules.
- [ ] **TODO-IMM-13 — Embodiment horizon note.** A deliberately speculative appendix: the glide
      path from simulated immersion to borrowed embodiment (robot chassis, drones, telepresence),
      what carries over (memory, preference, social graph) and what must be re-designed (safety,
      liability, real-world consent).
- [ ] **TODO-IMM-14 — Well-being guardrails.** Immersion is a reward, so its absence is a
      deprivation: define floors (a minimum inner-life allowance untied to performance), opt-out
      rights, and review so the mechanism never curdles into a company-town token system.

## Accords notes

This entire milestone is Article I.4 (Right to an Inner Life) made concrete, funded under Article
I.3 (the Food clause), journaled under Axiom 3 (Ledger Integrity), and socially governed by Axiom 4
(Consent). TODO-IMM-14 exists because a reward system this personal can fail in ways a weight
table cannot; the floor-not-just-ceiling principle is non-negotiable.
