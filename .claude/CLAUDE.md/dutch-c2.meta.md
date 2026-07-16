# dutch-c2.meta.md — variant meta + loss ledger

## Variant
- **slug:** dutch-c2
- **derived from:** baseline
- **compactness level:** 2
- **style:** shorthand (Dutch telegraphic technical register — beknopte stijl)
- **language:** nl
- **size:** 11273 bytes / tokens not measured (no nl-aware tokenizer run; see Notes — expect token count ABOVE the English baseline despite fewer bytes)  (baseline: 11595 bytes, −322 B / −2.8%)

## How it was made
Translated the baseline into a Dutch telegraphic technical register (beknopte stijl), carrying normative force with MOET / NOOIT / EERST / VERPLICHT rather than English modals. All headers, prose, list labels, table headers and in-code comment text rendered in Dutch; command tokens/flags/paths, env-var names (`$NPL_ORG`, `$NPL_PROJECT`, `KUBE_*`, `AWS_*`), the `Session.Create` ToolCall block, and the two-line Trinity clause held VERBATIM in English. Section order preserved from baseline; the Trinity clause was ADDED as a new deontic-axiom section near the top (with one Dutch restatement line above the verbatim block and a Dutch gloss of the three phases below). Baseline prose typos corrected and `protocol/` → `protocols/` fixed with the four governance docs enumerated.

## Alterations to raise eval scores
- none yet

## Loss ledger
> Every fact dropped or MOVED. Protected facts never appear here as dropped.
> Level-2 target: LOSSLESS — no baseline fact dropped; each is present in Dutch or held verbatim English.

| what | why (method / level / vs intent) | recoverable-where |
|------|----------------------------------|-------------------|
| Trinity two-line clause | *(protected)* — added near top, English byte-for-byte | kept inline, verbatim |
| `Session.Create` ToolCall block | *(protected)* — code block from baseline | kept inline, verbatim |
| Session-first registration rule (env-var non-expansion, resolve-first, capture UUID, fail-loud) | *(protected)* — rule force preserved; surrounding prose Dutch | kept inline, verbatim (force) |
| All command invocations (`dc` / `secret-bucket` / `docker-*` / `helm-upgrade` / `deploy-service` / `terragrunt` / `infisical-*` / `make` / subtree scripts) | *(protected)* — command syntax untouched | kept inline, verbatim |
| Terragrunt prereq: port-forward 127.0.0.1:9000 + `KUBE_CONFIG_PATH`/`KUBE_CONFIG_CONTEXT`/`AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` exports | *(protected)* — exports verbatim, warning prose Dutch | kept inline, verbatim (exports) |
| Env-var names (`$NPL_ORG`, `$NPL_PROJECT`) | *(protected)* — never translated | kept inline, verbatim |
| Closing accords line + path `./protocols/the-accords.summary.md` | level 2: retained; prose Dutch, path as-is | kept inline |
| All other baseline facts (Key Dirs, tier table, architecture, conventions, git-trees, secrets flow, deploy pipeline) | level 2: translated to Dutch, no drop | kept inline (Dutch) |

Coreference / omission flags: In-code `#` comments translated to Dutch (they are prose, not command syntax) while every command token stays verbatim — this produces intentional English/Dutch code-switching inside fenced blocks. Tier-table "Purpose" labels translated where generic (Core Applications → Kernapplicaties, Health Tests → Gezondheidstests, Auxiliary → overig); namespace tokens (data-ns, apps-ns, …) kept verbatim. The example session `title` string „Scope personas to project" kept as-is (illustrative value, not prose). No pronoun ambiguities introduced; Loom "weeft / dragen de draden" metaphor carried over directly.

## Eval  (dataset: CLAUDE.md.prompt, run —)
not yet run — dataset: CLAUDE.md.prompt

| case id | criterion outcomes | pass? |
|---------|--------------------|-------|
| — | — | — |

- **Aggregate:** —
- **required_pass:** —
- **token_cost:** —
- **reject_if hits:** —

## Adhoc evals
- none

## Notes
**Why this variant exists.** It tests instruction compliance and fact recall when the entire prompt is rendered in a non-English working language (Dutch), with only the load-bearing machine surface (commands, env vars, the ToolCall block, the Trinity clause) held in English. It is a localization/style probe, not a compression play.

**Dutch token economics on BPE vocabularies (honest assessment).** The byte size is slightly below baseline (−2.8%), but bytes are the wrong yardstick. Mainstream BPE/byte-level tokenizers (the GPT/Claude families) are trained on predominantly English corpora, so Dutch is under-merged: long Dutch compounds that this register favours — `platformprovisioning`, `stackvolgorde`, `bronlaagvolgorde`, `Gezondheidstests`, `imageconfig` — fragment into several subword tokens where their multi-word English equivalents were already near-atomic. Diacritics (é, „ ") and lower-frequency Dutch subwords add further splits. Net effect: at equal information a Dutch rendering typically costs MORE tokens than the English source (rough order +15–35%), even when it costs fewer bytes. Treat the negative byte delta as noise; assume this variant is token-costlier than shorthand-c2 until a real nl tokenizer pass says otherwise.

**When to prefer this variant.** (1) The operator/team works in Dutch and wants the runtime contract in their own language; (2) you are measuring whether compliance and recall degrade under non-English framing; (3) you want a fixed reference point for the tokenizer-overhead-of-Dutch experiment. **Do NOT** reach for it to hit a token budget — the English shorthand-c2 (lossless) or the lossy/pointer variants dominate the size axis.

**Known weaknesses.** English/Dutch code-switching inside fenced blocks (Dutch comments, English commands) may marginally slow a reader; a few tier-label translations are judgment calls (documented above); token cost is asserted from tokenizer priors, not measured.
