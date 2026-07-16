# german-c2.meta.md — variant meta + loss ledger

## Variant
- **slug:** german-c2
- **derived from:** baseline
- **compactness level:** 2
- **style:** shorthand (German Kompakt-Stil — telegraphic technical register, Stichpunkte + Nominalstil, MUSS/NIEMALS/ZUERST for normative force)
- **language:** de
- **size:** 11777 bytes / ~not-yet-measured tokens on target tokenizer  (baseline: 11595 B, +182 B / +1.6%)

## How it was made
Full German translation of the baseline into a telegraphic technical register (Nominalstil, dropped copulas/articles, `⇒`/`→` connectives, deontic markers MUSS/NIEMALS/ZUERST/PFLICHT). Prose typos were corrected; the `protocol/` Key-Dirs entry was corrected to `protocols/` and expanded to list all four governance docs (`the-accords.md`, `the-accords.summary.md`, `the-trinity-protocol.md`, `the-trinity-protocol.summary.md`). The Trinity clause was ADDED near the top (new requirement, absent from baseline) as a German-framed section with a German restatement line above the verbatim English two-line block. Protected spans kept as English islands inside German prose: every `dc`/`secret-bucket`/`docker-*`/`helm-upgrade`/`deploy-service`/`terragrunt`/`export`/`echo` invocation, all `$NPL_*` env-var names, the `Organization '$NPL_ORG' not found` error string, the `Session.Create` ToolCall block, and the closing accords path — command tokens verbatim, only their trailing `#` comments translated to German.

## Alterations to raise eval scores
- none yet

## Loss ledger
> Every fact dropped or MOVED. Protected facts never appear here as dropped.
> "Moved" requires a VERIFIED recoverable-where. Level-5 drops are recoverable only from the baseline.

| what | why (method / level / vs intent) | recoverable-where |
|------|----------------------------------|-------------------|
| Trinity clause (2-line block) | *(protected)* — ADDED near top, verbatim English | kept inline, verbatim |
| Session-first registration flow + `Session.Create` ToolCall block + env-var non-expansion rule + error string | *(protected)* — level 2, all inline in German with English islands | kept inline, verbatim |
| Terragrunt prereq (port-forward to 127.0.0.1:9000 + KUBE_CONFIG_PATH/KUBE_CONFIG_CONTEXT/AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY exports) | *(protected)* — level 2, inline | kept inline, verbatim |
| All `dc`/`secret-bucket`/`docker-*`/`helm-upgrade`/`deploy-service`/`terragrunt` command syntax | *(protected)* — command tokens verbatim English, comments translated | kept inline, verbatim |
| `docs/secret-management.md` pointer | baseline-provided supplementary pointer, retained inline (not a c2 move) — target verified `test -e` | kept inline; target `docs/secret-management.md` (verified) |
| — (no baseline fact dropped) | level 2 is lossless | n/a |

Coreference / omission flags: "it/this/that" pronouns in the baseline (e.g. "hang off this session", "use that bucket") resolved to explicit German nouns (Session, Bucket) during translation. Example session `title` string translated from "Scope personas to project" to „Personas auf Projekt eingrenzen" (illustrative value, not protected). No borderline omissions.

## Eval  (dataset: CLAUDE.md.prompt, run not yet run)
| case id | criterion outcomes | pass? |
|---------|--------------------|-------|
| — | not yet run | — |

- **Aggregate:** not yet run — dataset: CLAUDE.md.prompt
- **required_pass:** not yet run
- **token_cost:** not yet measured
- **reject_if hits:** not yet run

## Adhoc evals
- none

## Notes
Why it exists: a non-English lossless take on the corpus — tests (a) whether instruction compliance holds when the harness prompt is authored in German with English command/tool islands, and (b) multilingual robustness of the eval battery itself (does a model follow the Session-first + Trinity rules when they arrive in German?).

Token economics (honest assessment): German is generally a WORSE fit for BPE/tiktoken-family tokenizers than English. Compound nouns (Schlüsselverzeichnisse, Umgebungsvariablen, Deployment-Tiers) and inflectional endings fragment into more sub-word tokens per concept, and umlauts/`ß` and the „ " guillemets cost extra bytes/tokens. Byte size here is only +1.6% over baseline because the telegraphic Kompakt-Stil (dropped articles/copulas, Nominalstil) offsets German's verbosity — but expect the *token* count on an English-centric tokenizer to run meaningfully higher than the byte delta suggests. Do not pick this variant to minimize tokens.

When to prefer: German-speaking maintainers who will read/edit the file directly; or as a deliberate multilingual data point in the eval corpus. When NOT to prefer: token-budget-driven selection, or any English-tokenizer cost optimization — use a shorthand/ultra-terse English variant instead.

Known weaknesses: mixed-language surface (German prose + English command islands) can read awkwardly and raises the chance a translator/editor accidentally "fixes" a protected English token — the protected command/ToolCall/Trinity spans MUST stay English and were verified byte-for-byte. Token cost per above.
