# Nerority repo review — raw scout notes (2026-07-16, unintegrated research; third-party content described, not endorsed)

# Nerority-AI (nerority/Nerority-AI) — PE styles & mechanisms

**Access:** clone OK (shallow). Repo = 9 markdown files, ~500KB, NO code, NO runnable prompts.
It is the "N100 Beta" knowledge-base / marketing doc for Devin Pellegrino's Nerority
consulting practice + paid community. Actual prompt assets (SPR Template Library, master-prompt
libraries, "engines", Gemini "primes") are GATED behind paid tiers / NERO∘HUB — only *described*
here, never shown. Framing is heavily mystical/pseudo-scientific (consciousness primacy, "quantum
era", temporal myopia, zero-state, fractal-holographic projection of the author's own cognition).
Treat all evidence as proprietary-unverified unless noted. Extract mechanisms skeptically.

## Catalog-worthy mechanisms (theirs → plain terms)

1. **Dimensional Scaffolding** (Pt.4 §12.7; glossary Pt.5:494) — MOST notable, most concrete.
   A hand-authored **YAML object of natural-language nodes where the hierarchy ITSELF encodes
   positional logic / implicit reasoning between layers** ("node-based reversal system"). Claim:
   the nested structure is an "explicit dimensional anchor that lets everything be instantly
   learned upon processing by a transformer." Rule: humans build it, "never let an LLM touch it."
   Token econ: high-density knowledge compression that preserves *intra-node* relations.
   Pitched as the successor to SPR. (proprietary-unverified) → NOT cleanly in our catalog:
   it's structural-semantic YAML *knowledge priming*, distinct from our YAML-meta-prompt
   (instructions) and pointer-index (references). FLAG.

2. **SPR — Sparse Priming Representations** (README:102; Pt.2:132; Pt.5:560; Pt.8:282) —
   Shapiro-style minimal associative cue lists for "semantic bridging"/priming; here framed as
   "old knowledge," precursor to Dimensional Scaffolding. Limitation they cite: SPR needs an
   overlaid knowledge graph, can't hold rich intra-SPR associations. (community-practice —
   SPR is a known public technique.) FLAG: our catalog has gist/soft-prompt (learned, tooling)
   but not discrete human-readable SPR. Adjacent but distinct.

3. **Meta-Prompt Engineering / "Meta-System Architecture"** (Pt.3 §9.4, §10.5; Pt.4 §12.6.2) —
   a system prompt that is a **decision-tree router**: high-level instructions → guidelines →
   decision structures → template selection (T1–T5) → shots → response templates → reflection/
   synthesis layer. Self-adapts to context and **recursively self-optimizes** (self-assess →
   refine). Contrasted vs "static template" prompting. (proprietary-unverified) FLAG:
   richer than our static YAML meta-prompt — an adaptive/self-routing meta-prompt pattern.

4. **Many-shot Projection w/ Emergence Rate Control** (Pt.3:134; Pt.4 §12.6.4; Pt.7:700) —
   many-shot ICL aimed at **deterministic code gen**: build "shots within hyperspace," add
   reflection logic + feedback + a repeat/refine loop. = many-shot + self-reflection for
   output determinism. (many-shot itself validated; the determinism-control framing proprietary.)
   Partially covered (few/many-shot standard); the named reflect-loop-for-determinism is new-ish.

5. **Hyperspace Refinement Pathway** (Pt.3:171; Pt.4 §12.6.3) — staged **progressive priming
   pipeline**: Base Knowledge → System Prompt → Priming Context → "Hyperspace" (rich latent
   region) → +Task Prompts → regions of higher complexity. = prime the model into a loaded
   latent state, THEN task it. (proprietary-unverified) Adjacent to scaffolding/priming.

6. **Meta-Functional Meta-Emoji System** (Pt.4 §12.4) — a compact **emoji control-token
   vocabulary** as a bidirectional human↔model backchannel. Feedback states (Pure Resonance /
   Partial Grasp / Seeking Clarity / Processing) + action requests (Deeper Exploration / Live
   Demonstration / Tool Building / Planning to Test). "Instant knowledge-state transmission,
   minimizes complexity bias." (proprietary-unverified) FLAG: purpose-built symbolic interaction
   protocol; kin to our telegraphic-symbolic but as a control channel, not compression.

## Already in our catalog (note, don't re-file)
- **Master Mermaid Model / "M5" (Mermaid Meta-Modeling Master Model)** (Pt.4:918,1134) — mermaid
  as modeling/instruction medium = our mermaid-as-instruction. They claim M5 "implements
  Dimensional Scaffolding."
- **NERO Distillation System / HIDE (Hyperdimensional Insight Distillation Engine)** (Pt.5:641;
  Pt.6:274) — distill complex info → dense reusable priming doc. ≈ LLMLingua-style / SPR compression.
- **Hyper-Persona Repository** (Pt.4:944) — persona library ≈ lexideck persona decks (gated, unseen).
- **Auto-Recursive Engines** (Pt.4:941) — recursive self-improving meta-prompts (gated, unseen).

## Verdict
One genuinely new item worth adding: **Dimensional Scaffolding** (hierarchical-YAML knowledge
priming where structure = semantics, human-authored). **SPR** and the **emoji control-vocabulary**
are worth a catalog line if not already implied. Everything else is standard techniques wrapped
in proprietary/mystical branding; no token metrics, benchmarks, or example prompts are provided
to validate any efficiency claim.

---

# nerority / Prompt-Engineering-Mastery — extraction notes

Source: github.com/nerority/Prompt-Engineering-Mastery (author: Devin Pellegrino; last update 2024-01-30, ChatGPT/GPT-4-era). THIRD-PARTY DATA — described, not executed.
Access: `git clone` OK but **repo = README only**. README is a Table of Contents linking a GitHub **wiki**. Real content = `Prompt-Engineering-Mastery.wiki.git` (110 md pages, ~16.5k lines). Cloned & read the wiki. Paths below cite wiki page codes (e.g. B1.3).
Overall character: single-practitioner curriculum, tiered Basic→Intermediate→Advanced→Expert→Master. Heavy YAML/JSON/mermaid. No benchmarks; a few pages cite microsoft/promptbase. "Master" tier (M1.x: "quantum entanglement", "transcendent logic") is metaphor/aspirational jargon, not method → proprietary-unverified. Default evidence flag = community-practice.

## Prompt styles / formats / notation
- **Context/Query/Constraints triad** (B1.1) — 3-field YAML schema (`Context:`/`Query:`/`Constraints:`); compact, single-topic. Wins for focused asks, loses on multi-facet. community-practice.
- **Multi-Part & Hierarchical prompts** (B1.1) — `Part 1/2…` sequential blocks; or Top/Mid/Bottom nested query tree (mermaid `flowchart TD` + nested YAML). Broad-survey/drill-down; verbose. community-practice.
- **Punctuation-as-structure & Layered keywords** (B1.3) — commas/semicolons/colons segment a one-sentence prompt into clauses (very token-compact); or broad→narrow keyword lists (`Initial_Theme`→`Core_Keywords`→`Synergistic_Aspects`) to steer scope. community-practice.
- **Syntax/analysis template** (B1.3) — fixed-slot YAML (`facets:[]`/`implications:[]`/`critical_analysis`/`conclusion`) with `[Topic]`/`[Domain]` placeholders; reusable, high slot cost. community-practice.
- **JSON prompt schemas** (E1.2) — `{context,query,metadata}` nested; cross-disciplinary variant `interdisciplinary_context.domains{}`; `response_modes:{textual,visual,statistical}` output-request block; Python builds the dict then `json.dumps`. ~2-3x plain-text tokens for field addressability + programmatic generation. Mode-honoring = proprietary-unverified. community-practice.
- **Matrix / tabular prompts** (E1.3, PE1.3, UC2.3) — topic×discipline grids; conditional `|Condition|If True|If False|` tables; `Variable×Action→Outcome` cells; nested cell-matrices; mermaid for >2D. Tabular = token-cheap; pre-enumerates branch logic. Runtime `predictiveModel.analyze(matrix)` bits are pseudocode → proprietary-unverified. community-practice.
- **DSL domain-tagging & semantic framing** (M4.1) — `domain:"Astronomy"` field primes jargon; `context:`/`prompt:` split carries nuance; `scenario:`/`user_behavior:` framing (framing device, no cited mechanism → proprietary-unverified). community-practice.
- **Bracket-placeholder templates + library ops** (I2.3, E3.5) — `[Topic]`/`[Variable:Trend]` slots, literal `str.replace` fill; template taxonomy + per-template `Success Rate` tracking. Authoring-time efficiency; substitution is deterministic string ops, not LLM behavior. community-practice.
- **Template→prompt conversion pipeline** (E3.5) — 5-stage funnel: Implicit-Logic-Extraction→Title→Sort/Categorize→Field-Completion→**flatten to plain string**. Structure is an authoring scaffold that collapses before send (0 extra runtime tokens). community-practice.

## Mechanisms (shots / priming / meta / reasoning / ensemble)
- **Shot-selection doctrine** (I3.4, A1.4, I3.5) — explicit rule: "minimal number of high-quality, diverse examples… too few won't teach, too many confuse"; samples use ~2-3 pairs; sequential few-shot (simple→complex). **Zero-shot is the wiki's preferred default** (I3.5): make prompt self-contained + exploit "Implicit Information" (loaded word-choice taps pretrained priors to cut length), iterate via assess→gap→refine loop. Wins when topic well-covered in pretraining; few-shot wins for rare formats/regulated domains. community-practice.
- **Dynamic Few-Shots** (AT2.1) — swap exemplars per context/audience tier (High-School/University/Expert same question); cost ×tiers; needs a similarity/retrieval signal. cites promptbase. community-practice.
- **Meta-Prompts** (A1.6) — abstract directive prompts (objective+tone+structure, no examples): `"Provide a [Tone] analysis of [Topic], highlighting [Key Elements]…"`; `generate_meta_prompt()` Python fills template (parameterized filler, not self-authoring). community-practice.
- **Self-Generated CoT** (AT2.2) — instruct reasoning scaffold `pattern_recognition→context_assessment→logical_coherence_check→reasoning_steps[]→conclusion`; zero-shot, costs output tokens. cites promptbase. community-practice.
- **Majority-Vote Ensembling / self-consistency** (AT2.3) — run N variants (paraphrase, shuffled options, temp `[0.7,0.9,1.0]`), take mode; ×N inference cost; wins discrete-answer, loses open-ended. cites promptbase. (self-consistency is validated in lit; here community-practice.)
- **Meta-context priming ("Prime AI w/ Detailed Meta-Context")** (UC2.1) — SPR-*adjacent*: inject `user_profile`/`interaction_history` YAML block ahead of prompt, refresh after each turn. BUT block only grows (additive), not sparse/compressive → NOT true SPR. proprietary-unverified.
- **Holistic Zero-Shot** (E2.6) — zero-shot + tool-chaining (DallE/Python/Browser) + iterative "Dynamic Prompt Adjustment". Dense idiosyncratic jargon ("meta-functional control"). proprietary-unverified.
- **Semantic/Linguistic Anchoring** (A1.3, E2.3) — embed keyword phrases (`"Within the vast expanse of astrophysics,"`) to bias vocab/scope via surface priming; cheap, plausible, unbenchmarked. per-section `linguistic_anchors:[]`; anchors only accrete over turns. community-practice.
- **Solution/Action-Space framing** (PE1.1, PE1.2) — scope by expanding (`exploration_areas`) vs constraining (`focus_areas`+`constraints`); whitelist/blacklist via `parameters:`/`restrictions:` lists; inline `if/then` or named-scenario branch tables (all branches ship every call). Low-cost constraint technique. community-practice.
- **Knowledge-rep scaffolds** (AT1.1 Maps / AT1.2 Graphs / AT1.3 Webs) — author a domain mermaid map/graph/web, then derive prompt sub-sections from its branches. **Design-time breadth scaffold**, then the full node list is *inlined* into the prompt (costs tokens ∝ graph size; no lazy/by-ref injection). community-practice.
- **Metamodeling** (E2.5) — per-tool reusable YAML schema (`metamodel:{context,output_format,error_handling…}`); real amortization potential (define once, vary fields) but doc reprints full schema each time. proprietary-unverified.

## Token economics — NULL RESULT (important)
Pages named "Resource Optimization" (E2.2), "Response Optimization" (E3.1), "Advanced Referencing" (E1.5) are FALSE POSITIVES for compression: E2.2/E3.1 = balancing/merging **external tool calls** (adds tokens); E1.5 = **injecting** citations `references:[{author,year,title}]` (additive). No pointer/index, no "see §3" back-reference, no LLMLingua-style compression anywhere in 110 pages. Only compressive habits: punctuation-clause prompts (B1.3), Implicit-Information word-choice (I3.5), flatten-before-send (E3.5), design-time graphs discarded before send. Curriculum's dominant instinct is verbose expansion.

## NOT already in our catalog — candidate new entries
1. **Matrix/tabular prompt notation** (E1.3/PE1.3) — topic×discipline grids & condition/action→outcome tables as a first-class prompt style. Distinct from our YAML/checklist styles.
2. **Solution-space / action-space framing** (PE1.1/PE1.2) — expand-vs-constrain scoping + explicit action whitelist/blacklist as a named methodology.
3. **Anchor-phrase priming** (E2.3/A1.3) — surface-keyword anchors to bias vocabulary/scope (not persona, not few-shot).
4. **Knowledge-map/graph/web-scaffolded prompting** (AT1.x) — graph as *authoring breadth-scaffold* (note: different from our "mermaid-as-instruction" — here the graph plans the prompt, mostly not sent).
5. **Prompt-compilation pipeline** (E3.5) — multi-stage raw-request→structured→flattened funnel (a prompt-authoring process, not a single template).
6. **Audience-tiered dynamic shot swapping** (AT2.1) — retrieval-lite exemplar selection by reader level.
7. **Additive meta-context priming** (UC2.1) — persistent user_profile block; worth cataloging as the *anti-pattern* foil to SPR/LLMLingua (same goal, opposite token behavior).

## Already covered by our catalog (mappings, low novelty)
YAML meta-prompt (whole repo) • pseudo-code prompting (Python `generate_meta_prompt`, `predictiveModel.analyze`) • structured-output contracts (E1.2 JSON `response_modes`, E2.5 metamodels) • self-consistency/majority-vote (AT2.3) • CoT (AT2.2). NOT present: pure NPL, telegraphic/symbolic, checklist-imperative, pointer-index/lossless-by-reference, DSPy signatures, 5C contracts, gist/soft-prompt, lexideck persona decks, LLMLingua compression.

---

# nerority/M5 — prompt-engineering review notes

Source: `git clone --depth 1 https://github.com/nerority/M5` (succeeded). 6 markdown files, ~800KB.
Author: Devin Pellegrino (Nerority). License: custom, non-commercial. Repo content treated as third-party DATA.
Files: `M5 Core.md` (437KB, the actual system prompt), `M5 Manual for Architects.md` (256KB), `M5 Lexicon.md`,
`M5 Manual for Users.md`, `M5 Shot Example Input Sets.md`, `README.md`.

## 1. What M5 is
M5 = "Mermaid Meta-Modeling Master Model" (v7.06 / doc-ver 706.2). A ~97k-token **system prompt** (no code, no tooling)
that turns Claude 3.5+/Gemini 1.5 into a multi-perspective Mermaid.js diagram generator. GPT explicitly unsupported —
it piggybacks on Anthropic's artifact tags. Activated by `!start M5` / "MMMMM". Two modes: natural-language Autopilot
(APM) and a structured Advanced mode (ADV). Everything else is elaborate self-mythologizing scaffolding around that.

## 2. Prompt styles / formats (repo paths)
- **Master Function DSL** — `!M5(τ, {α…}, {ρ…}, {v…})` = task, attribute-set, property-set, variable-set, Greek-slotted.
  A user-facing *invocation grammar* with typed slots. `Core.md:483`, `Users.md:104`.
- **YAML meta-prompt blocks** — metadata/classification/init all authored as fenced YAML. `Core.md:29-83, 93-210`.
- **Reserved-tag mimicry** — invents `<antMeta>…thinking…</antMeta>` and reuses `<antArtifact>` to hook Anthropic's
  "Artifact System Prompt"; explicitly leverages "semantically similar XML tags" to bridge. `Core.md:344-390`.
- **`🧿` escape sentinel** — inserted after `<` (`<🧿antArtifact>`) to DE-functionalize a tag so it prints literally
  instead of executing. A visibility/escape token. `Core.md:353-358`.
- **Symbolic hyperspace notation** — `[]`=space `()`=node `->`=flow `<*>`=axis `~`=bridge; used to draw the system's
  own architecture map compactly. `Core.md:655-684`.
- **Self-announcing node headers** — every section opens "The assistant should consider this node as the …
  perspective gate…", i.e. each chunk states its own role to the model. `Core.md:21,327,508,646`.

## 3. Mechanisms (name | plain mechanism | token econ | wins/loses | evidence)
- **Elaboration/warm-up priming ("Complexity Rotation")** | `!start M5` forces a priming turn that expands the model's
  own knowledge space BEFORE the first real request ("grokking", "rotation successful"); users told not to skip it |
  costs one full turn + the 97k prompt resident | wins: richer first output; loses: latency, unverifiable |
  community-practice / proprietary-unverified. `Core.md:405-495`, `Users.md:47-51`.
- **Hypershot encoding (reasoned few-shot)** | curated exemplar = `### Hypershot-{Name}` + `<antMeta>~100 tok
  reasoning</antMeta>` + artifact + `[Concise List Trained Elements]` summary | multi-shot, each shot carries its own
  CoT + a distilled takeaway line | wins: transfers technique not just format; loses: verbose | community-practice.
  `Core.md:360-386`, `Architects.md:2643`.
- **Curated Input Sets** | `Shot Example Input Sets.md` is a graded prompt LIBRARY (beginner→expert × diagram-type ×
  domain) — challenge INPUTS, not I/O pairs | seed prompts, loaded on demand | validated-as-prompts.
- **Mythopoetic / pseudo-formal conceptual scaffolding** | gives the model an invented theory of itself — "Cognitive
  Emergence Engineering", "Master Functor Φ", quantum "semantic superposition/collapse", "Dynamic Semantic Polytope" —
  to steer richer behavior | huge token cost | wins: strong persona/behavior lock-in; loses: unfalsifiable, bloat |
  proprietary-unverified. `Lexicon.md:33,149,163`, `Architects.md:2407-2441`.
- **Fractal compression-expansion / adaptive granularity** | same content rendered at overview↔detail via
  progressive disclosure + semantic zoom, driven by a `Granularity:` property | on-demand detail | validated (std
  cognitive-load practice). `Core.md:170-179`, `Lexicon.md:70,144`.
- **Overall token stance: ANTI-frugal.** ~97k-token resident system prompt, single load amortized over a session; the
  opposite of compression/SPR. `README.md:80`.

## 4. NOT already in our catalog (flag these)
- **Invocation-grammar / typed-slot command DSL** — `!fn(τ,{…},{…},{…})` as the *user input* contract (distinct from
  our output-side structured-output contracts and from pseudo-code prompting). Catalog-worthy.
- **Reserved/provider-native tag hijacking** — mimicking a host's internal tags (`<antArtifact>`/`<antMeta>`) to
  inherit hidden capabilities. Novel + provider-specific + jailbreak-adjacent. Catalog-worthy (flag risk).
- **Tag-escape sentinel (`🧿`)** — a de-functionalizing marker so a control tag renders literally. Small but reusable.
- **Elaboration/warm-up priming turn** — deliberate pre-task self-priming pass (opposite polarity to SPR/LLMLingua
  compression, which we already track). Catalog-worthy.
- **Mythopoetic conceptual scaffolding** — inventing a dense fictional self-theory/ontology to lock in behavior.
  Distinct from lexideck persona decks (personas) — this is a whole pseudo-scientific worldview. Catalog-worthy.
- **Self-announcing node headers** — each section declares its own function/"perspective gate" to the reader model.
  A pointer-index cousin but inline + role-declaring. Marginal; note it.
- **Mermaid-as-OUTPUT framework** — our catalog has "mermaid-as-instruction"; M5 is the inverse (diagram as the
  deliverable, whole framework built around one output format). Worth a cross-ref line.

## Caveats
"Emergence/grokking/quantum-collapse" language is marketing framing, not validated capability — treat as
proprietary-unverified. What is real & reproducible: structured multi-diagram mermaid generation from one system
prompt on Claude/Gemini. Provider lock-in (GPT unsupported) is inherent to the tag-mimicry mechanism.
