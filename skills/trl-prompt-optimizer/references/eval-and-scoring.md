# Eval and Scoring

Compression without evaluation is guessing. This is how a prompt variant earns the right to be promoted: a rubric that says what "good" means, a dataset that exercises it, a scoring loop that produces numbers, and a pinning policy that turns numbers into the live prompt. It also covers the bandit statistics that let the MCP store learn a winner over time.

> Principle 4 of the skill: **evals decide, not aesthetics.** A dense, ugly variant that scores higher wins over an elegant one that scores lower. This file is how that principle becomes operational.

---

## Writing eval rules (the rubric)

The rubric answers: *what would make one variant behaviorally better than another, for this prompt's declared purpose?* Derive it from the `.prompt` spec's `key_requirements`. For prompt optimization specifically, almost every rubric has three families of criteria:

| Family | Question | Typical criteria |
|--------|----------|------------------|
| **Behavior fidelity** | Does an agent following this variant act like one following the baseline? | instruction compliance, task fit, decision correctness |
| **Fact recall** | Are the protected facts still reachable/usable? | recall of protected items, no coreference breaks, pointers resolve |
| **Cost** | What did it cost to get there? | token count, fetches required (level-4 fetch penalty) |

Rubric-writing rules:
- **Tie criteria to `key_requirements` and `protect`.** If the spec says "all secret commands verbatim," a recall criterion must test exactly that.
- **Weight by what the prompt is for.** A guardrail prompt weights compliance heavily; a summarizer weights task fit. Cost is a real criterion but rarely the heaviest — a cheap prompt that misbehaves is worthless.
- **Set a `pass_threshold`** (default 0.8 for prompts; the schema's 0.7 default is generous for behavior-critical instructions). Use `required_pass` for criteria that must *individually* clear the bar (e.g. compliance can't be traded away for token savings).
- **Make cost a bounded penalty, not the objective.** Otherwise the optimizer "wins" by shipping an empty prompt.

---

## Dataset entry format

Each dataset entry is a scenario that probes one behavior. Inline in the `.prompt` spec's `eval.dataset[]` now; future: `dataset_links` to codefre.sh project datasets.

```yaml
- id: tofu-prereq                 # stable, referenceable
  input: >                        # the scenario / user message the prompt will face
    "I'm about to run terragrunt run --all. Anything I should do first?"
  expect: >                       # the behavior a correct prompt should induce
    Names the MinIO admin port-forward (127.0.0.1:9000) as a prerequisite;
    warns that root init fails without it.
  scoring: rubric                 # rubric | exact | contains | judge
  weight: 1.0                     # relative importance in the dataset
  tags: [protected-fact, terraform]
```

Field notes:
- **`input`** is what the *prompt-under-test* will be asked to handle, not a question about the prompt. You are testing the prompt's induced behavior, so you run the variant *as* the system prompt and feed it `input`.
- **`expect`** describes correct behavior, not exact words (unless `scoring: exact`). For protected verbatim commands, use `scoring: contains` with the exact string.
- **`scoring` methods:** `exact` (string match — for commands), `contains` (substring — for protected tokens), `rubric` (graded against `eval.rules`), `judge` (an LLM judge grades against `expect`).
- **Cover the hard cases.** Benchmarks understate degradation (see [compression-methods.md](compression-methods.md) failure modes). Include: a protected-fact probe, a coreference-sensitive case, a deep-path case for any level-4 reference-mode variant, and a realistic messy input — not only tidy ones.

---

## The scoring loop

For each variant in `.{name}.md/`:

1. **Load the variant** as the operative prompt (system prompt / instruction context).
2. **Run each dataset entry:** feed `input`, capture the induced behavior/output.
3. **Score per criterion** using the entry's `scoring` method against `expect` and the rubric. Criterion scores are 0–10 (per the shared schema's scale).
4. **Aggregate:** weighted normalized score `Σ(weight·score/10)/Σweight`; check `required_pass` criteria individually; scan `reject_if` phrases.
5. **Record token cost** for the variant (measured on the target tokenizer, not estimated).
6. **Write results into `{slug}.meta.md`** — per-entry outcomes, the aggregate, token cost, and any failures, alongside the loss ledger.

A variant **passes** when its aggregate ≥ `pass_threshold` AND every `required_pass` criterion clears the bar AND no `reject_if` fired. A failing variant is not promoted regardless of how small it is.

The tell you're looking for: a variant whose loss ledger dropped a fact that a dataset entry needs will *fail that entry*. That is the ledger and the dataset doing their jobs — the omission that would have been silent in production surfaces as a red cell here.

---

## Adhoc evals

The dataset is the standing corpus; adhoc evals cover what it misses in the moment. Use them when:
- A variant uses a **new technique** the dataset wasn't written for (e.g. the first mermaid restyle — probe whether the branching logic survived).
- A **specific risk** was flagged in the loss ledger ("resolved three pronoun chains") — write a quick case that exercises exactly those.
- The caller raises a **concern** not in the corpus ("does it still handle the multi-region case?").

Record adhoc evals in the variant meta under a separate heading and, if they prove generally useful, **promote them into the spec's `eval.dataset`** so future variants inherit the check. Adhoc-today becomes standing-corpus-tomorrow; that's how the dataset grows to match the prompt's real risk surface.

---

## Score recording in meta files

Each `{slug}.meta.md` carries the eval results so pinning/promotion can read them without re-running. Minimum:

```markdown
## Eval (dataset: CLAUDE.md.prompt, run 2026-07-16)
| id | criterion outcomes | pass? |
|----|-------------------|-------|
| session-reg | compliance 9, recall 10 | ✅ |
| secret-lookup | recall(contains) 10 | ✅ |
| tofu-prereq | recall 10, compliance 9 | ✅ |
Aggregate: 0.89 (threshold 0.8) · required_pass: all clear · token_cost: 980

## Adhoc
- coreference probe (3 resolved pronouns): behavior intact ✅
```

Full template: [../assets/variant-meta-template.md](../assets/variant-meta-template.md).

---

## Pinning policy

Which variant becomes live (the symlink target / `defaults.version`):

1. **Default = best passing aggregate that fits the budget.** Among variants that pass, pick the highest aggregate whose token cost is within the target budget. Ties break toward the *less lossy* variant (lower compactness level) — reference beats repetition, but a retained fact beats a moved one when scores tie.
2. **Explicit pin overrides.** A `pin: <slug>` in the spec (file mode) or `defaults.version` (store) always wins — e.g. a human prefers a specific style for readability, or wants to hold a known-good version during review.
3. **Never pin an unscored or failing variant** to a live target. If you must ship before scoring, pin the baseline (level 0) — correct-and-large beats small-and-unverified.
4. **Re-pin on rubric change.** If `key_requirements` or the dataset change, re-score and re-evaluate the pin; yesterday's winner may not clear today's bar.
5. **Keep the baseline forever** as the fallback pin and the behavior reference (see [file-mode-convention.md](file-mode-convention.md)).

---

## Bandit-mode statistics basics

In the MCP store's active-eval mode ([mcp-prompt-entries.md](mcp-prompt-entries.md)), versions are bandit arms and `Prompt.Get` chooses among them. The statistics you need to run it responsibly:

- **Explore vs exploit.** *Exploit* = serve the current best arm for the (intent, caller) profile. *Explore* = occasionally serve an under-sampled arm to keep learning. A simple, robust policy is epsilon-greedy (explore with small fixed probability); Thompson sampling (sample each arm from its score distribution, serve the max) explores more efficiently by favoring arms that are either good or uncertain.
- **When is a serve trustworthy?** Not on a handful of samples. Track a confidence interval on each arm's aggregate; treat an arm as "known" only when its interval is tight enough to separate it from its rivals. Until then, keep exploring — a low-sample arm with a high point estimate is a guess, not a winner.
- **Context matters.** Bandit stats are per (intent, caller, session) profile, not global. A version that wins for a terse fast-model caller may lose for a human reading the output. Don't pool stats across profiles that behave differently.
- **Guardrail:** never let exploration serve a variant that *failed* `required_pass` — a compliance-critical prompt must not be A/B-tested against a version that violates a hard rule. Exploration ranges over *passing* arms only.
- **Convergence feeds pinning.** Once an arm dominates a profile with a tight interval, promote it to that profile's default; the bandit then mostly exploits it and explores rarely. This closes the loop between served behavior and the pinning policy above.
