# Provider & Model Strengths — Fleet Assignment Reference

How to staff a work DAG across heterogeneous providers: which **strength class** each work unit belongs to, which providers currently fill each class, and the heuristics that map a task's attributes onto a class. Consumed by Step 4 (Staff) of the execution workflow and by [assets/fleet-roster-template.md](../assets/fleet-roster-template.md).

> **Caveat — read first.** The model roster shifts monthly: names, context windows, and prices change; new tiers ship and old ones retire. The **strength classes below are stable even when the specific models are not.** Every named model here is an *example of its class*, not a standing recommendation. Verify current offerings, quotas, and pricing before you staff — treat this file as a map of the terrain, not a live inventory.

Class names match the Fleet Assignment table in `SKILL.md` — use them verbatim on rosters so tickets, charters, and plans line up.

---

## Strength Classes (the durable abstraction)

| Class | Uniquely good at | Must never be assigned |
|-------|------------------|------------------------|
| **Frontier reasoning** | Ambiguity resolution, decomposition, contract/interface design, cross-track integration debugging, arbitration, review. The coordinator role. | High-volume mechanical passes (waste); anything a frozen contract already fully specifies. |
| **Fast inference** | Millisecond-throughput mechanical NL work: STATUS digests, room summarization, lint/format passes, log triage, high-volume classification, quick lookups. | Contract design, decomposition, integration debugging, any unit where a wrong call cascades. |
| **Cheap bulk reasoning** | Well-specified implementation and test-authoring where a frozen contract removes ambiguity. Best price/quality on code that has one correct shape. | Open-ended design, ambiguity resolution, Phase 0 contracts, blast-radius-wide surfaces. |
| **Local models** | Privacy-constrained data, zero-marginal-cost bulk transforms, offline/CI loops, latency-free tight iteration; custom fine-tunes as house-style specialists. | Frontier reasoning it lacks the parameters for; work whose quality ceiling exceeds local hardware. |
| **Specialized harnesses** | What their tooling does best: repo-scale coordinated edits, Elixir-native flows, live-info retrieval. Value is in the harness, not just the model. | Tasks outside their tooling's sweet spot where a general model is simpler. |

The class is chosen from the **task**, not the provider. A provider can serve multiple classes (Claude fills frontier *and* fast; a local box fills local *and*, if fine-tuned, a specialist niche).

### Which providers fill which class

One class is rarely served by one provider — this is what gives the fallback ladder its rungs. `●` primary fit, `○` viable, blank = wrong tool.

| Provider | Frontier | Fast | Cheap bulk | Local | Specialized harness |
|----------|:--:|:--:|:--:|:--:|:--:|
| Anthropic Claude | ● | ● (Haiku) | | | |
| OpenAI / Codex CLI | ● | | ○ | | ● (Codex repo edits) |
| DeepSeek | ○ | | ● | | |
| xAI Grok | ○ | ○ | | | ● (live-info) |
| Groq-hosted OSS | | ● | ○ | | |
| Local (Ollama/fine-tune) | | ○ | ○ | ● | ○ (house-style) |
| noizu-intellect | | | | | ● (Elixir-native) |

Read a column to build a fallback ladder (frontier has three fills → Claude → OpenAI → Grok); read a row to see a provider's reach.

---

## Provider Profiles

### Anthropic Claude
- **Strengths:** Frontier tiers (Opus / Fable) are the default coordinator and Phase-0 pick — strongest instruction-following, long-context planning, tool orchestration, and integration reasoning in the fleet. Haiku tier is a fast, cheap triage worker.
- **Weaknesses:** Frontier tokens are among the most expensive in the fleet; using them for mechanical work is pure burn.
- **Cost / latency:** Frontier = high cost, moderate latency. Haiku = low cost, low latency.
- **Ideal tracks:** Coordinator role; Phase 0 contract authoring; Phase 2/3 integration gates and review. Haiku for room summarization and triage (fast-inference class).

### OpenAI / Codex CLI
- **Strengths:** Codex CLI is a strong repo-scale editing harness — coordinated multi-file edits with tight apply/verify loops. Frontier tiers (GPT-5-class) are capable implementation models.
- **Weaknesses:** Most of its edge is harness-coupled; as a bare model it's a peer of other frontier tiers, not a coordination standout.
- **Cost / latency:** Frontier cost, moderate latency.
- **Ideal tracks:** Phase 1 implementation tracks with large, coordinated cross-file edits (frontend/backend build-out); anything where the Codex harness's repo tooling pays for itself.

### DeepSeek
- **Strengths:** Cheap with genuinely strong code reasoning. The workhorse of the **cheap bulk** class — excellent on well-specified implementation and test-authoring where the contract has already removed ambiguity.
- **Weaknesses:** Weaker at open-ended architecture and ambiguity resolution; degrades when handed under-specified work.
- **Cost / latency:** Very low cost, moderate latency.
- **Ideal tracks:** Phase 1 tracks keyed to a frozen API contract; backend unit/integration tests against mocks; e2e specs against a frozen selector schema.

### xAI Grok
- **Strengths:** Fast, frontier-adjacent reasoning; live/current-information retrieval; the grok harness.
- **Weaknesses:** More output variability than the top frontier tier; the live-info edge is irrelevant to most offline coding tracks.
- **Cost / latency:** Moderate cost, fast.
- **Ideal tracks:** Units needing current external info (a just-changed third-party API, latest docs); fast frontier-adjacent implementation; research-flavored spikes. A viable frontier fallback under Claude/OpenAI rate limits.

### Groq-hosted OSS models (Llama / Qwen / etc.)
- **Strengths:** Extreme tokens/sec — the defining trait. The fast-inference default: room summarization, STATUS digests, lint/format passes, log triage, high-volume classification.
- **Weaknesses:** OSS-model reasoning ceiling. **Never** contract design, decomposition, or integration work.
- **Cost / latency:** Low cost, highest throughput / lowest latency in the fleet.
- **Ideal tracks:** Fast-inference class end to end — digesting the coordination room, mechanical gate passes, bulk labeling.

### Local models (Ollama / llama.cpp / custom fine-tunes)
- **Strengths:** Zero marginal cost; privacy-constrained data never leaves the host; offline/CI loops; latency-free tight iteration. Custom fine-tunes act as **house-style specialists** (naming, comment density, repo idiom).
- **Weaknesses:** Capability ceiling is set by local hardware; small models have weak reasoning — scope tightly.
- **Cost / latency:** Zero marginal cost; latency bounded only by local hardware (often the lowest round-trip available).
- **Ideal tracks:** PII/secret-adjacent transforms, unlimited-volume bulk work, offline CI, and any tight edit loop where round-trip latency dominates. Fine-tunes for house-style enforcement passes.

### noizu-intellect
- **Strengths:** Elixir-native agent runtime; supports long-lived **resident** agents that persist across a whole initiative rather than one session. Native to the Noizu framework flows.
- **Weaknesses:** Specialized to the Elixir/Phoenix domain; not a general polyglot pick. Capability tracks its backing model.
- **Cost / latency:** Depends on the backing model; resident and long-lived rather than one-shot.
- **Ideal tracks:** Elixir/Phoenix implementation tracks; long-lived resident watchers/coordinators embedded in the Noizu stack.

---

## Assignment Heuristics

Read the task's attributes, then pick the class. When attributes disagree, **the one demanding the higher class wins** — under-provisioning a hard unit costs more than over-provisioning an easy one.

| Task attribute | Signal | Push toward |
|----------------|--------|-------------|
| **Ambiguity** | High / open-ended | Frontier reasoning |
| | Low / one correct shape | Cheap bulk (or fast, if trivial) |
| **Blast radius** | Touches a contract or shared surface | Frontier reasoning |
| | Confined to one track's owned file set | Cheap bulk / fast |
| **Volume** | High token count, repetitive | Fast inference / local |
| **Privacy** | Sensitive / regulated data | Local models (hard gate — see below) |
| **Latency-sensitivity** | Interactive or tight iteration loop | Fast inference / local |
| **Specification tightness** | Frozen contract removes all ambiguity | Cheap bulk is safe |
| | Spec is loose or evolving | Escalate a class; or tighten the spec first |

**Worked examples:**
- Write Cypress specs against a frozen selector schema → **cheap bulk**, e.g. DeepSeek (tight contract, single-track blast radius).
- Decompose a vague feature request into a work DAG → **frontier**, e.g. Claude Opus/Fable (high ambiguity + high blast radius).
- Summarize 40 room messages into one STATUS digest → **fast inference**, e.g. Groq-hosted Llama (high volume, mechanical).
- Anonymize 10k customer records into test fixtures → **local model** (privacy gate; also zero-marginal-cost bulk).
- Implement 12 CRUD endpoints against a frozen OpenAPI spec → **cheap bulk**, e.g. DeepSeek (tight contract).
- Debug why frontend and backend disagree at the integration gate → **frontier**, e.g. Claude (cross-track, high blast radius).
- Build a Phoenix LiveView track in the Noizu stack → **specialized harness**, noizu-intellect (Elixir-native tooling).

### Worked roster: the flagship fullstack fan-out

Staffing every track of the interface-first pattern (`SKILL.md` § Interface-First Fan-Out) by class — a complete roster, not a menu:

| Phase / Track | Class | Example fill | Why |
|---------------|-------|--------------|-----|
| Phase 0 — contracts (API spec, selector schema, data model) | Frontier | Claude Opus/Fable | Ambiguity + max blast radius; the coordinator's own work. |
| Frontend build | Frontier / cheap bulk | OpenAI Codex CLI | Repo-scale coordinated edits against a frozen contract. |
| Backend build | Cheap bulk | DeepSeek | Endpoints fully specified by the API contract. |
| E2E tests | Cheap bulk | DeepSeek | Keyed to the frozen selector schema; runs against a stub. |
| Backend tests | Cheap bulk | DeepSeek | Contract + mocks remove all ambiguity. |
| Fixtures / mock server | Cheap bulk / local | Local model | Bulk seed data; local if the data is sensitive. |
| Room STATUS digests | Fast | Groq-hosted Llama | High-volume mechanical summarization. |
| Phase 2/3 integration + review | Frontier | Claude Opus/Fable | Cross-track debugging and arbitration. |

The frontier tier bookends the plan (contracts in, integration out); the parallel middle is almost entirely cheap-bulk and fast — which is exactly where the token budget should land.

---

## Cost Model Intuition

**Frugality rule:** the coordinator (frontier) spends its expensive tokens on **contracts, arbitration, and integration** — the three things only frontier reasoning does well. Everything mechanical is delegated *down-class*: cheap bulk for specified implementation, fast inference for digests and lint, local for private/bulk transforms.

Both directions of misassignment are failures, and they are not symmetric:

| Failure | What it looks like | Cost |
|---------|--------------------|------|
| **Frontier on mechanical** | Opus/Fable reformatting JSON, writing boilerplate tests a contract fully specifies, digesting a room | Wasted spend, no quality gain. Bounded and visible. |
| **Fast on architecture** | A fast/cheap model designs a contract, resolves ambiguity, or picks cut points | Wrong contract → **every track keyed to it is rebuilt** at the integration gate. Rework dwarfs the token savings, often many-fold, and surfaces late. |

The asymmetry is the whole point: frontier-on-mechanical wastes a known, small amount now; fast-on-architecture risks an unknown, large amount later. **Never economize on Phase 0.** The cost of a wrong frozen contract is the sum of all downstream tracks redone.

---

## Availability & Fallback

Every roster names a **fallback per provider-risk** (rate limits, outages, quota exhaustion, hardware contention). The governing preference: **degrade the class with a tighter spec before you block a track.** A blocked track stalls its whole downstream cone; a downgraded track ships if you narrow the contract enough to fit the weaker model.

| Primary | Risk | Fallback | Mitigation |
|---------|------|----------|------------|
| Claude frontier | Rate limit / outage | OpenAI frontier or Grok heavy | Re-issue against the *same* frozen contract — no re-decomposition. |
| DeepSeek (cheap bulk) | API outage / latency spike | Local model or Groq-hosted | Tighten the spec further if the substitute is weaker. |
| Groq-hosted (fast) | Rate limit | Local model (Ollama) | Accept lower throughput; the work is mechanical either way. |
| Local (private/bulk) | Hardware busy | Groq-hosted fast | **Only if data is not privacy-constrained.** Sensitive data never falls back off-host — escalate scheduling instead. |
| noizu-intellect | Runtime down | Claude/DeepSeek on the same Elixir contract | Lose residency, keep the contract. |

**Two hard rules:**
1. A downgrade in class is *paid for* with a tighter contract. If you can't tighten the spec enough to trust the weaker model, escalate the class instead of shipping ambiguity downward.
2. The privacy gate is not negotiable for latency or availability. Off-host fallback is forbidden for privacy-constrained data — no exceptions under load.

---

## Cross-References

- **[persona-assignment.md](persona-assignment.md)** — Personas are **orthogonal** to model class. A persona (reviewer temperament, domain voice, house style) rides on top of whatever class the task demands; pick the class here first, then attach the persona there. The same persona can execute on a frontier or a cheap-bulk model depending on the unit.
- **[harness-coordination.md](harness-coordination.md)** — Harness capability **constrains** assignment: some units require a specific harness's tooling (repo-scale edits, tobor-room participation, Elixir-native flows) regardless of the ideal model class. When a harness constraint and a class preference conflict, reconcile there before finalizing the roster.
