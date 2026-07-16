# Style Transforms

A catalog of prompt methodologies that target the **same behavioral end result** through a different format. Restyling is the second compression axis: the same instructions cost very different token counts as prose, YAML, a diagram, a checklist, or an NPL element set — and some formats read more reliably to the target model. Pick the format, then compress inside it with [compression-methods.md](compression-methods.md).

> Compression (removing words within a fixed format) and style transform (changing the format) compound. Do the transform first when the format is clearly wrong for the content, then compress the survivor. Always eval old-vs-new for behavior equivalence, not just token delta.

---

## How to choose

| If the source is… | …reach for | Because |
|-------------------|-----------|---------|
| Prose with many MUST/MUST-NOT rules | checklist-imperative | compliance-ordered, rules can't hide in paragraphs |
| Config-shaped (settings, agent definition, parameters) | YAML meta-prompt | declarative, machine-diffable, less connective prose |
| A workflow / state machine / decision tree | mermaid-as-instruction | control flow is denser as a graph than as prose |
| Mostly reference material with a few rules | pointer-index | move the reference out, keep the rules |
| Logic-heavy, ambiguous NL steps | pseudo-code prompting | code tightens ambiguity, fewer tokens for logic |
| Output that feeds code | structured-output contract | the schema *is* the instruction |
| Reused across many calls in an NPL project | pure NPL + `NPLLoad` | fetch element defs on demand (see npl-compression-integration.md) |
| Already dense, needs the last 10% | telegraphic shorthand + symbolic | notation substitution, lossless if a legend is kept |

Token economics below are directional (BPE tokenization favors English prose; structured formats spend tokens on punctuation/keys). **Measure the actual delta on the target tokenizer — never assume.**

---

## Verified / research-anchored transforms

### Pure NPL

- **Mechanism.** Express the prompt in Noizu Prompt Lingua syntax (element definitions, agents, directives). Definitions can be loaded on demand rather than inlined.
- **Token economics.** The inline form is *not* smaller than tight prose; the win is level-4 lossless-by-reference — element definitions live in the NPL server and are fetched via `NPLLoad` at the needed complexity tier, so the prompt ships a reference, not the body.
- **Wins when.** An NPL runtime is available and the same elements recur across prompts; you want a stable, versioned vocabulary; you need complexity-tiered detail.
- **Loses when.** No NPL runtime (the fetch instruction is dead weight), or a one-off prompt where the reference indirection costs more than it saves.
- **Detail.** [npl-compression-integration.md](npl-compression-integration.md).

### YAML meta-prompt

- **Mechanism.** Encode the prompt as declarative config — role, capabilities, constraints, inputs, outputs as YAML keys — instead of prose paragraphs. The agent-playbook role blocks in this repo are exactly this pattern.
- **Token economics.** Cuts prose boilerplate ("You should always make sure to…") down to keys and values; spends tokens on structure. Net win for config-heavy content, roughly neutral for rule-heavy content, a loss for narrative content.
- **Wins when.** Multi-agent config, versioned/diffable prompts, anything a tool also parses. Machine-diffable is a real operational win beyond tokens.
- **Loses when.** The instructions are genuinely narrative or conditional in ways YAML flattens awkwardly.
- **Citation.** https://julep.ai/blog/why-every-ai-agent-framework-should-adopt-yaml-a-technical-deep-dive

### Mermaid-as-instruction

- **Mechanism.** Encode a workflow, state machine, or decision tree as mermaid (or other diagram) text; the diagram *is* the instruction. Control flow ("if X then step 3 else step 5") becomes edges.
- **Token economics.** Dense vs prose for branching logic — one edge replaces a sentence. Poor for flat declarative facts (a diagram of a list is bigger than the list).
- **Wins when.** Sequential/branching processes, approval flows, state transitions. Also renders to a visual for humans (the media tool's `diagram` type).
- **Loses when.** The content isn't a flow; forcing prose facts into a graph inflates them.
- **Citation.** Common pattern, no single canonical academic cite — **unverified** as a compression technique specifically; treat token wins as content-dependent and measure.

### Checklist-imperative

- **Mechanism.** Lead with MUST/MUST-NOT rules as a flat checklist, ordered by compliance priority; reference material follows. Matches the repo corpus's `checklist-imperative` variant.
- **Token economics.** Neutral-to-slightly-smaller vs prose, but the real win is *reliability* — rules can't get buried mid-paragraph, which improves compliance at roughly equal token cost (pairs with the reordering method).
- **Wins when.** The prompt is mostly behavioral rules and compliance matters (a CLAUDE.md, a guardrail prompt, a definition-of-done).
- **Loses when.** The content needs explanation/rationale to be followed correctly; a bare checklist can strip the *why* and cause misapplication.

### Pointer-index / lossless-by-reference

- **Mechanism.** Keep behavioral rules inline; replace every block of reference material with a one-line denotation + a verified pointer to where the detail lives (`docs/…`, a runbook, an `NPLLoad` element). The prompt asserts *that* something exists and *where* to read it, not the thing itself. This is compactness level 4.
- **Token economics.** The biggest single win available — in the worked example it took a 10KB prompt to 3.8KB *losslessly*, because ~4.2KB was reference material that moved out. Costs one doc read per referenced area at use time.
- **Wins when.** The prompt is rules + a large reference tail (commands, schemas, catalogs), and the referenced docs exist and are stable.
- **Loses when.** The "reference" is actually needed every turn (then it's a rule, keep it inline), or the pointed-at docs don't exist / aren't verified — an unverified pointer is a silent omission.
- **Detail.** [file-mode-convention.md](file-mode-convention.md) and the worked example.

### Telegraphic shorthand + symbolic

- **Mechanism.** Substitute abbreviations (b4, w/, cfg, TF) and symbols (⇒, ∀, ¬, →) for common words/relations. Matches the repo corpus's live `shorthand-symbolic` variant. Lossless *if* the notation is unambiguous to the target model and a legend is retained.
- **Token economics.** Modest, tokenizer-dependent — some symbols are single tokens, some abbreviations split oddly under BPE. Measure; a "shorter" string can tokenize longer.
- **Wins when.** A dense prompt needs the last few percent and the model reliably reads the notation.
- **Loses when.** The notation is ambiguous (a symbol the model interprets inconsistently) or the target model handles shorthand worse than full words — then it *costs* accuracy for a few tokens. Never use for `protect` items.

### Pseudo-code prompting

- **Mechanism.** Express a task as code/algorithm (functions, conditionals, loops) rather than natural language. Tightens ambiguous NL and packs logic densely.
- **Token economics.** Wins for logic-heavy tasks (control flow, multi-condition rules); neutral-to-worse for declarative content.
- **Wins when.** The task is procedural and the model codes well; removes NL ambiguity ("do X, unless Y, but always Z").
- **Loses when.** The task is not procedural; pseudo-code of a fact list is just an obfuscated list.
- **Citation.** Prompting-frameworks survey, https://arxiv.org/pdf/2311.12785

### DSPy-style signatures

- **Mechanism.** Declare typed I/O ("question -> answer", "document -> summary") instead of hand-writing the instruction; a compiler/optimizer fills in the wording.
- **Token economics.** Minimal at authoring time — you ship the signature, not the prose. The prompt body is generated/optimized downstream.
- **Wins when.** Programmatic pipelines where a framework compiles prompts; you want the wording tuned by optimization, not by hand.
- **Loses when.** There's no DSPy-like runtime; a bare signature to a plain chat model under-specifies.
- **Citation.** https://dspy.ai/learn/programming/signatures/

### Structured-output contracts

- **Mechanism.** Enforce a JSON Schema at the decode layer; the schema *is* the instruction. Prose describing the output shape disappears because the constraint is machine-enforced.
- **Token economics.** Cuts all "return a JSON object with fields a, b, c…" prose; spends tokens on the schema (often cached / out of the prompt entirely if enforced by the API).
- **Wins when.** Output feeds code and shape matters more than freeform quality.
- **Loses when.** The task is open-ended generation where a schema straitjackets useful variation.
- **Citation.** Meaning-Typed Prompting, https://arxiv.org/pdf/2410.18146

### 5C prompt contracts

- **Mechanism.** A minimalist token-efficient contract: Character, Cause, Constraint, Contingency, Calibration — five slots that cover a reusable single prompt without prose sprawl.
- **Token economics.** Compact by construction; each slot is a phrase, not a paragraph.
- **Wins when.** Cheap, reusable, single-purpose prompts (SME/no-framework use).
- **Loses when.** Complex multi-step agent prompts that outgrow five slots.
- **Citation.** https://arxiv.org/html/2507.07045v1

---

## Soft-prompt / learned-compression awareness (tooling-only)

These are **not in-LLM techniques** — they require training or decoder control and cannot be applied by rewriting a prompt in-context. Know them so you can *recommend* them when the situation fits, and say plainly that this skill can't perform them.

- **Gist tokens** — train an attention mask so a few "gist" tokens absorb a fixed prompt; generation attends only to the gist. ~26x compression, ~40% FLOPs cut, cacheable. **Recommend when:** a fixed instruction block is reused across enormous call volume and you control the model. https://arxiv.org/abs/2304.08467
- **ICAE / AutoCompressor** — soft-prompt encoders folding long context into a few summary vectors. **Recommend when:** repeated long *static* context. (survey: https://arxiv.org/html/2410.12388v2)
- **500xCompressor** — encode context into KV pairs (not embeddings); 6x–480x, retains ~62–73% capability at extreme ratios. **Recommend when:** extreme compression is tolerable and you control the decoder. https://arxiv.org/html/2408.03094v1

Survey anchor for the hard-vs-soft split (drop-text vs learned-tokens): "Prompt Compression for LLMs: A Survey," NAACL 2025 — https://arxiv.org/html/2410.12388v2.

---

## Lexideck patterns (proprietary vocabulary — unverified)

Lexideck Technologies (founder Matthew Murphy; a commercial ChatGPT GPT + paid curriculum, **not** peer-reviewed research) publishes a modular multi-agent meta-prompting vocabulary. The evidence base is thin and self-published; treat the following as **pattern vocabulary to borrow honestly, not validated results**. They are useful *shapes* for restyling multi-agent prompts.

- **Persona deck + single orchestrator** — a fixed roster of named, invokable cognitive agents (their Lexi/Dexter/Maisie/Gus/Anna/Titus) with one orchestrator that routes by name. As a prompt shape: define roles once, invoke by name, avoid re-describing each role inline every call. (Overlaps with our agent-playbook role blocks.)
- **Multi-axis self-rating rubric** — their "Unified Hyperplane" rates a response on four bipolar axes (emotional/logical/sensory/ethical). As a shape: a compact self-check rubric embedded in a prompt, cheaper than prose describing quality expectations.
- **Explicit ethics-sieve gate** — their "Sieve Ethics" as a named decision guardrail. As a shape: a single named gate the prompt references rather than restating guardrails inline.
- **Batch/chain command syntax over agents** — invoking/sequencing multiple agents with a terse command grammar instead of prose orchestration.

**Honesty note to carry into any output:** when recommending a lexideck-derived pattern, name it as an unverified commercial coinage (source: https://www.lexidecktechnologies.com/ , GPT: https://gptstore.ai/gpts/gupdqjMndf) and justify it on mechanism, not on claimed results.

---

## Transform + eval, always

A style transform is only "equivalent behavior" if the evals say so. After restyling:
1. Keep the source as a variant (never overwrite the baseline).
2. Run the same eval dataset against old and new — you are checking *behavior equivalence*, not just that the new one is smaller.
3. Record the token delta *and* the eval delta in the variant meta. A transform that saves 30% tokens but drops an eval case is a regression; promote on score. See [eval-and-scoring.md](eval-and-scoring.md).
