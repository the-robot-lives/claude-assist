# Compression Methods

In-LLM compression: how to apply the LLMLingua research family *by hand* — the model does the pruning the tool would otherwise do — plus the compactness-scale semantics and the loss-accounting discipline that keeps compression honest.

> The methods here compress *within a fixed methodology* (prose stays prose, YAML stays YAML). When the format itself is the lever, see [style-transforms.md](style-transforms.md). When NPL is available and reference material can be fetched on demand, see [npl-compression-integration.md](npl-compression-integration.md).

---

## The core idea: imitate the tool, don't run it

Microsoft's LLMLingua family (project: https://www.microsoft.com/en-us/research/project/llmlingua/ · code: https://github.com/microsoft/LLMLingua) compresses prompts by running a small language model over the text and deleting tokens the small model finds predictable. We do not run that pipeline. Instead, a capable model applies the *same decision procedure* the papers describe: allocate a budget per section, drop coarse units first, prune low-information tokens iteratively, and keep whatever the declared question needs. The research gives us a principled, tested set of rules; we execute them in-context.

Everything below is a **method card**: the mechanism, how to apply it in-LLM, and what it costs.

---

## Method cards

### 1. Budget controller — allocate compression by section sensitivity

**Source:** LLMLingua, EMNLP 2023 (https://arxiv.org/abs/2310.05736).

**Mechanism.** Not every part of a prompt deserves the same compression. The budget controller assigns each section a compression ratio by importance: instructions and the question get protected (little or no compression); demonstrations, examples, and background context get compressed hard.

**In-LLM application.** Before pruning a single word, segment the prompt: *behavioral rules / instructions* (protect), *the task or question* (protect), *examples and demonstrations* (compress aggressively), *reference/background* (compress or move to reference-mode). Spend the token budget where loss is cheapest. This is the single highest-leverage step — it is why level-1 edits on filler outperform level-3 telegraphing of rules.

**Cost.** Almost none if segmentation is honest. The failure is mis-segmenting a rule as background and compressing it.

### 2. Coarse-to-fine — drop whole units before touching words

**Source:** LLMLingua (coarse-to-fine pipeline).

**Mechanism.** Compress in passes of decreasing granularity. First drop whole demonstrations/sections by importance (coarse). Only then prune sentences, then individual tokens (fine). Removing one redundant example saves more than word-smithing ten sentences and does less damage to the ones that remain.

**In-LLM application.** Ask "can a whole section go?" before "can this word go?" If three examples all teach the same rule, keep one. If a section restates a rule stated elsewhere, cut it. Then, and only then, tighten wording inside what survives.

**Cost.** Coarse drops are visible and easy to ledger. Watch for a demonstration that looks redundant but covers an edge case the others miss.

### 3. Iterative token-level pruning — condition each drop on the last

**Source:** LLMLingua (iterative token-level compression).

**Mechanism.** Naively scoring every token's importance *once, independently* ignores that tokens depend on each other — dropping one changes the value of its neighbors. LLMLingua prunes iteratively: drop, re-assess, drop again, so each removal conditions the next.

**In-LLM application.** Compress in small rounds, re-reading the shrinking text each round, rather than deleting everything flagged in a single pass. This prevents the classic failure where two individually-droppable words were the only two carrying a fact between them.

**Cost.** More passes = more effort, but far safer at high ratios. Skipping iteration is the main cause of accidental fact loss.

### 4. Perplexity-proxy retention — keep the surprising, drop the predictable

**Source:** LLMLingua (self-information / perplexity-based token selection).

**Mechanism.** The small model keeps tokens it finds *surprising* (high self-information / high perplexity) and drops tokens it can predict from context (low information). Rare, load-bearing tokens — entity names, numbers, negations, domain terms — survive; predictable connective tissue ("in order to", "it is important to note that") gets cut.

**In-LLM application.** Ask of each span: "could the model reconstruct this from what remains?" If yes, it is low-information — cut it. If no (a proper noun, a specific number, a flag name, a `not`), keep it verbatim. Entities and numbers are never predictable; protect them.

**Cost.** Reliable for filler. The trap: **negations and pronouns look predictable but are not** (see Failure Modes).

### 5. Question-aware compression — keep what the declared intent needs

**Source:** LongLLMLingua, ACL 2024 (https://arxiv.org/pdf/2310.06839).

**Mechanism.** Generic information-scoring keeps what's surprising *in general*; question-aware scoring keeps what's relevant *to the task*, scoring each span conditioned on the question (contrastive perplexity). This raises key-information density dramatically — the same budget carries more of what the answer actually needs.

**In-LLM application.** This is why the caller's `key_requirements` / intent statement is mandatory. Compress *toward* the declared purpose: a prompt "focused on getting-started guides for non-technical users" keeps onboarding facts and can shed advanced-tuning detail. Without a declared intent, fall back to generic retention and warn that compression is un-targeted.

**Cost.** None — it makes compression *better*. The risk is a wrong/narrow intent statement that sheds facts a future use needs; record what was shed so it can be restored.

### 6. Reordering against lost-in-the-middle

**Source:** LongLLMLingua (document reordering); lost-in-the-middle position bias.

**Mechanism.** Models attend most strongly to the beginning and end of a long context and least to the middle. LongLLMLingua ranks context by importance and moves the most important to the edges (front) to fight this bias.

**In-LLM application.** After compressing, order the surviving content so the most load-bearing rules sit at the top (and optionally repeat a critical few at the very end). Don't bury a MUST rule in the middle of a long file. This is a *placement* optimization, not a size one — it improves compliance at equal token cost.

**Cost.** Free. Purely reordering.

### 7. Subsequence recovery — restore verbatim spans after the fact

**Source:** LongLLMLingua (subsequence recovery).

**Mechanism.** Aggressive compression can mangle exact spans — names, numbers, code, commands. LongLLMLingua restores these verbatim from the original after generation.

**In-LLM application.** Anything on the `protect` list — exact commands, code blocks, credentials-shaped strings, precise numbers — is copied through **verbatim** and never paraphrased, regardless of compactness level. If a later pass touched one, restore it from the baseline. This is the mechanism behind the "protected facts survive at every level" guarantee.

**Cost.** None to correctness; a few tokens back to the budget. Always worth it for exact strings.

### 8. Task-agnostic keep/drop (awareness only)

**Source:** LLMLingua-2, ACL 2024 (https://llmlingua.com/llmlingua2.html).

**Mechanism.** LLMLingua-2 distills GPT-4's "which tokens are essential" judgments into a BERT-level binary keep/drop classifier — fast, bidirectional, task-agnostic, more faithful than perplexity-only selection because a strong model defined "essential." It is 3–6x faster than LLMLingua and generalizes better out of domain.

**In-LLM application.** You *are* the strong model LLMLingua-2 distilled from. When no task/question is available (task-agnostic mode), judge essentialness directly with bidirectional context: read the whole prompt, then decide keep/drop per span using full surrounding context rather than left-to-right perplexity. Prefer this framing for general-purpose compression of a prompt with many possible future uses.

**Cost.** None — it is the higher-fidelity default when you have the whole text in view.

---

## Reported ratios (calibration, not promises)

- LLMLingua: **up to ~20x** with minimal loss on cooperative tasks; degrades sharply past ~25–30x (GSM8K).
- LongLLMLingua: **+21.4% on NaturalQuestions multi-doc QA using ~1/4 the tokens**; but cited ~47% quality drop going from 1.53x→3.44x on some tasks.
- LLMLingua-2: **3–6x faster** than LLMLingua, better out-of-domain, more faithful.

Read these as: modest compression is nearly free; aggressive compression is a cliff, and the cliff is task-dependent. Target the gentlest level that fits the budget.

---

## Failure modes (the reasons to keep a loss ledger)

Sources: https://tianpan.co/blog/2026-04-16-context-compression-what-your-model-sees · https://arxiv.org/pdf/2406.02376

- **Coreference loss.** Pronouns ("it", "they", "this") read as cheap and predictable, so aggressive pruning drops them — breaking the chain that told the model *what* "it" was. Mitigation: when compressing, resolve pronouns to their referents (replace "it" with the noun) rather than deleting, or keep the pronoun and its antecedent together.
- **Information omission (the main failure).** The dominant failure is not the text drifting in *meaning* — it is a reasoning-critical **fact getting pruned** while the passage still *reads* correct and still scores high on semantic similarity. A budget number, a boundary condition, a "must not" clause vanishes and nothing looks wrong until the task fails. Mitigation: the loss ledger — force every drop to be named, so omissions are visible instead of silent.
- **Task dependence.** Multi-step reasoning, math, and code degrade fast under compression; summarization and open-ended generation stay robust. Mitigation: **never compress the reasoning chain itself**, and compress reasoning-heavy prompts more conservatively (cap them a level lower than the request if evals wobble).
- **Benchmarks understate degradation.** Clean test sets lose less than messy real inputs; a variant that scores well on an easy dataset can still fail in production. Mitigation: put *hard, realistic* cases in the eval dataset, not just tidy ones (see [eval-and-scoring.md](eval-and-scoring.md)).

---

## The compactness scale (semantics)

The `compactness` axis is leveled 0–5. Each level names a **known sacrifice**; there is no free compression. Levels 0–3 are lossless (all facts retained). Level 4 is lossless *by reference*. Level 5 is lossy.

| Level | Name | Method emphasis | Known sacrifice | Reversible? |
|-------|------|-----------------|-----------------|-------------|
| 0 | Verbatim | none | none | n/a — it's the original |
| 1 | Edited-lossless | budget controller + drop filler (methods 1, 4) | redundancy, hedging, filler words | fully (nothing dropped but noise) |
| 2 | Shorthand-lossless | + notation/abbreviation substitution | readability for the uninitiated | fully (expand the shorthand) |
| 3 | Dense-lossless floor | + coarse-to-fine + iterative pruning (methods 2, 3) | prose flow; near the inline floor | fully (facts are all present) |
| 4 | Lossless-by-reference | reference material → verified pointer/`NPLLoad` | one fetch per referenced area | by fetching the pointed-at doc |
| 5 | Telegraphic-lossy | + question-aware drop of non-essential facts | named facts dropped | **only from the baseline/ledger** |

The jump that matters is **3 → 4**: at level 3 you have squeezed style as far as inline prose allows; further size wins come from *moving* reference material out (level 4), not deleting it (level 5). In the worked example, level 5 (3.9KB) landed slightly larger than level 4 (3.8KB) while dropping ~4.2KB of facts — a strictly worse trade. Reach for level 4 first; only go to level 5 when the caller explicitly accepts loss in a `lossy_ok` area.

Full per-level sacrifice statements: [../assets/compactness-scale.md](../assets/compactness-scale.md).

---

## Loss accounting discipline

Every variant ships a **loss ledger**. The rule: *a fact that is dropped or moved without a ledger entry is a bug.* Each entry records three things:

| Field | Meaning | Example |
|-------|---------|---------|
| **what** | The specific fact, span, or section removed or relocated | "the MinIO port-forward prerequisite for `terragrunt run --all`" |
| **why** | Which method/level justified it, and against which intent | "level 4: reference material, moved — not a per-turn behavioral rule" |
| **recoverable-where** | Exactly where the information now lives (or that it is gone) | "docs/terraform-runbook.md §3 (verified present)" — or "DROPPED, in baseline variant only" |

Discipline rules:
- **Protected facts never appear in the ledger as dropped.** If a `protect` item can't fit the budget, report the overage; do not compress it.
- **"Moved" requires verification.** Before writing a pointer as recoverable-where, confirm the target actually contains the fact. An unverified pointer is worse than the omission it hides.
- **Level 5 drops are recoverable only from the baseline.** That is why the baseline variant is retained forever (see [file-mode-convention.md](file-mode-convention.md)).
- **Coreference and omission risks get flagged**, not just counted — note any pronoun chains resolved and any fact that was borderline.

The ledger is written into each variant's `{slug}.meta.md` (see [../assets/variant-meta-template.md](../assets/variant-meta-template.md)) and feeds the eval step: a variant whose ledger shows a dropped fact that an eval case needs will fail that case, which is exactly the signal we want.
