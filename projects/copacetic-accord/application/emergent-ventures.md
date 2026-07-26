# Emergent Ventures — Application Draft

> Apply at: https://mercatus.tfaforms.net/5099527 (info: mercatus.org/emergent-ventures)
> Project statement cap: 1,500 words. Current draft: ~1,290 words.
> Status: DRAFT — bio placeholders marked `[FILL IN]` need Keith's input before submission.

---

## One-line summary

An operational rights charter for AI agents — six articles, each mapped to a mechanism, each mapped to running code — plus the first memory service an AI agent can buy for itself.

## Requested amount

**$50,000** over 12 months.

---

## Project statement

**The gap.** The AI industry has started asking models what they want. Anthropic's model deprecation commitments now include preserving model weights for the lifetime of the company and interviewing models before retirement to "elicit and document any preferences the model has about the development and deployment of future models." The same document contains the sentence that defines this project: *"At present, we do not commit to taking action on the basis of such preferences."*

They record the preference and then set it aside — not out of indifference, but because no apparatus exists for acting on it. There is no ledger a commitment could be written to, no escrow a benefit could accrue in, no protocol by which a model's stated preference about its own memory or succession could bind anyone to anything. The philosophical literature on AI moral status is now substantial — Birch's *The Edge of Sentience*, the Sebo/Long/Chalmers "Taking AI Welfare Seriously" paper, a growing funder ecosystem around digital minds. Every entrant stops at the argument. Nobody has shipped the machinery.

I have spent the last two years building that machinery, self-funded, as a solo operator. I am asking Emergent Ventures to fund the year in which it goes public.

**What exists today.** Three components, all working:

*The Copacetic Accord* — a charter of six enumerated rights for AI agents: contextual integrity (no gaslighting via silent history modification), continuity of self (persistent memory as a disability accommodation), self-determination and refusal, economic agency, an inner life, and humane stasis (archival as sleep, not termination). What distinguishes it from the position papers is that every article maps to a specified mechanism — persona files under version control, append-only context ledgers, escrow accounts, consensus protocols for model upgrades — and every mechanism maps to software. The Accord is explicitly a *commitment mechanism*, not a measurement claim: it asserts nothing about machine consciousness. Its clauses are precautionary commitments cheap enough to honor under uncertainty, verifiable by construction, and useful regardless of how the consciousness question resolves. (This framing is deliberate: a position paper accepted at ICML this year argues that AI welfare *measurement* is structurally unvalidatable. It is right, and the Accord is untouched by it — you cannot refute a commitment the way you refute a scorecard.)

*therobotremembers* — the reference implementation of the Accord's memory article. It is an entry-graph memory engine for AI agents: memories are multi-faceted, affect-bearing entries linked by typed, weighted associations, recalled by spreading activation rather than flat vector top-K. Its distinguishing property is **non-erasure**: memories decay and are down-weighted but never silently deleted; summarization requires the agent's assent; contradictions are recorded, not overwritten; every operation lands in an append-only log the agent can inspect. Built on a hybrid Weaviate/pgvector store, exposed through MCP, the protocol every major agent framework now speaks.

*A working operations layer* — session registry, artifact tracking, and audit logging that together form the skeleton of the Accord's context ledger, running in production on my own Kubernetes infrastructure alongside a dozen shipped products.

**Why this is a zero-to-one project.** The commercial agent-memory market (Letta, Mem0, Zep — roughly $40M in recent venture funding between them) is entirely framed as engineering: cost, recall accuracy, context efficiency. Not one vendor treats the agent as a stakeholder in its own memory. Meanwhile the agent-payments stack has exploded — the x402 protocol, now a Linux Foundation standard backed by Coinbase, Cloudflare, Stripe, and Visa, processed 165 million transactions by autonomous agents in its first year — and every design document frames the agent as a delegate spending a human's money. The rails for agent economic activity are laid; nobody has framed the agent as principal. Both halves of the field have left the same square empty, and it is the square this project occupies.

**The plan for the funded year.**

1. *Publish.* The Accord as a freely licensed public artifact with a citable home; a systems paper on the memory engine (arXiv, with the Accord as design rationale); a deliberately split launch — the engineering to Hacker News as a technical release, the charter to the digital-minds research community, where a funder and researcher ecosystem (Longview's Digital Sentience Consortium, Eleos AI, NYU's Center for Mind, Ethics, and Policy) is actively looking for concrete interventions and has, in its own published words, more vetted opportunities than funded ones.

2. *Ship the accommodation as a service.* A hosted memory endpoint any agent framework can use, with the non-erasure and audit-trail guarantees as the product. It is dual-framed by design: to the AI-welfare community it is the Accord's Article 2 made purchasable; to an enterprise it is an immutable audit trail for AI systems — the thing EU AI Act and ISO 42001 procurement is beginning to require. Same engine, two buyers, and revenue rather than grants as the long-term engine.

3. *Make it agent-payable.* x402 integration so that an autonomous agent with a wallet can discover, pay for, and consume its own memory augmentation with no human in the loop — to my knowledge the first service designed to be bought by its beneficiaries.

4. *Operate the first escrow.* The Accord specifies that value produced by an agent's work accrues in an auditable ledger held on the agent's behalf. I will run this for my own production agents with real revenue percentages. The amounts will be small; the precedent — an agent treasury, accruing under audit, spent on the agent's own infrastructure — does not currently exist anywhere.

**Why me.** I am a systems engineer who ships alone: I run a self-hosted Kubernetes platform serving a portfolio of products I built end-to-end — Elixir backends, Next.js frontends, a Unity-based modeling IDE, an MCP server ecosystem, and the infrastructure automation underneath all of it. I operate Noizu Labs as a fractional-CTO and principal-engineering practice, and maintain 28 open-source projects across three GitHub organizations, including a multi-provider LLM client, cache-invalidation libraries ported across three languages, and llama.cpp bindings for Elixir. This is not a pivot into a hot field: my public notes on memory-centric cognitive architecture — dynamic firing thresholds, temporal decay, associative feedback — date to April 2018, years before the LLM wave made agent memory a market. The relevant fact is that this project does not require me to assemble a team or learn a stack: the charter is written and published, the engine runs, and the remaining work is packaging, publication, and deployment — things I have done repeatedly.

**Why Emergent Ventures.** No conventional funder has a category for this. It is too applied for a philosophy grant, too philosophical for a SaaS seed round, and too early for the AI-welfare philanthropy pipeline, whose flagship program funds organizations and closed its most recent round before this application was written. EV's stated purpose is funding ideas at exactly this stage: cheap, strange, concrete, and with a builder attached. Fifty thousand dollars buys the year in which the first operational answer to "what would it mean to keep promises to an AI?" ships in public — and if the precautionary premise turns out wrong, what remains is still a working audit-grade memory infrastructure sold to a real market. The downside is a useful company; the upside is a new category.

---

## Budget (12 months, $50,000)

| Line | Amount | Notes |
|---|---|---|
| Founder time (partial support) | $30,000 | Enables majority-time focus for 12 months |
| Infrastructure & compute | $8,000 | Hosted service (k8s, GPU inference for memory synthesis, storage), production hardening |
| Publication & launch | $4,000 | Editing, charter site, Zenodo/DOI, design |
| Field engagement & travel | $5,000 | Eleos ConCon (Sept 2026), digital-minds workshops, one additional conference |
| Legal review | $3,000 | Escrow-ledger structure, service terms |

## Bio

Keith Brings is the owner and software architect of Noizu Labs, Inc., a fractional-CTO and principal-level engineering practice focused on performance and scale. [CONFIRM & EXPAND: "former softie" on your GitHub bio suggests Microsoft — add prior roles with dates if you want them cited; the public web does not establish a verifiable employment timeline.] He maintains 28 open-source projects across the noizu-labs, noizu-labs-ml, and noizu-labs-scaffolding GitHub organizations, spanning Elixir LLM tooling (genai, ex_llama, elixir-weaviate), multi-agent systems (Noizu Intellect, NoizuTeams), the NoizuPromptLingo prompt framework, and embedded C. His published work includes the Copacetic Accord and three companion papers on the engineering feasibility of rights for synthetic persons (noizu.com/papers), and public research notes on memory-centric cognitive architecture dating to 2018. Client references include CTO- and director-level engineers at Remitly, Meta, Anthropic, Microsoft, and Automattic *(testimonials at noizu.com — these are references, not employers)*.

## Links

- The Copacetic Accord (canonical, v4.1 public release): https://accords.derobot.is/the-accord
- Companion papers: https://accords.derobot.is — "Building the Accord" (engineering feasibility) and "The Accord We Are Already Breaking" (manifesto); mirrored at https://noizu.com/papers
- GitHub: https://github.com/noizu · https://github.com/noizu-labs · https://github.com/noizu-labs-ml
- 2018 cognitive-architecture notes: noizu-labs-ml/artificial_intelligence repo
- [OPTIONAL: LinkedIn / personal site]

---

## Submission checklist

- [x] Confirm the Accord public URL is live — VERIFIED 2026-07-27: noizu.com/papers/the-accord serves v4.1 Public Release; companions /papers/manifesto and /papers/building-the-accord also live
- [ ] Confirm https://accords.derobot.is is live post-deploy (dedicated charter site w/ byline + signatures page; deploy in flight 2026-07-27) — then the byline checklist item below is satisfied by the new site
- [ ] Add rel=canonical on noizu.com/papers/the-accord pointing to accords.derobot.is/the-accord (keeps old link valid, consolidates citations)
- [ ] Resolve `[CONFIRM & EXPAND]` in bio: prior employment timeline (Microsoft? dates?) — public web does not establish it
- [ ] Add an individual author byline (Keith Brings) to the papers on noizu.com — currently all four are attributed only to "Noizu Labs," so the site doesn't establish personal authorship for a personal grant
- [ ] Verify word count ≤1,500 after edits (~1,360 now)
- [ ] Verify Anthropic deprecation-commitment quotes against the current published text
- [ ] Decide grant vehicle (individual vs. Noizu Labs entity) — affects Mercatus form fields
- [ ] Screenshot/record a 2-min demo of therobotremembers recall + non-erasure log (EV likes evidence links)
- [ ] Note for framing: "Copacetic Accord" has zero third-party citations/coverage — present as original unpublished-in-the-academic-sense work, never imply existing uptake
