# classical-chinese-c3.meta.md — variant meta + loss ledger

## Variant
- **slug:** classical-chinese-c3
- **derived from:** baseline
- **compactness level:** 3
- **style:** classical-chinese (文言文 literary register)
- **language:** lzh (Classical Chinese)
- **size:** 11916 bytes / 8921 chars (baseline: 11595 B / 11547 chars; +321 B / +2.8% bytes, −22.7% chars). Token count not yet measured — see Notes.

## How it was made
Baseline facts were re-expressed clause-by-clause in the terse literary register of Classical Chinese (文言文): normative-sequential particles (凡／必／勿／先／後／皆／乃), four-to-eight-character clauses, and no modern function-word padding. Section headers were reframed as classical titles (首務·立會, 儉約之道, 要目, 令典, 構造, 規約, 分樹之法, 終旨). All protected spans were carried through untranslated: every command in backtick/code form, the `echo` and `Session.Create` ToolCall blocks, all env-var names, and the two-line Trinity clause verbatim byte-for-byte with a single classical restatement placed above it. Tool/product/path/config tokens (Terragrunt, Helm, MinIO, k8s, `.infra-config.yaml`, namespace names, the tier table) stay in Latin script inline; a 凡例 legend mapping the key classical terms to their technical meanings was appended for weaker-model comprehension.

## Alterations to raise eval scores
- none yet

## Loss ledger
> Every fact dropped or MOVED. Protected facts appear only as *(protected)* rows kept inline.

| what | why (method / level / vs intent) | recoverable-where |
|------|----------------------------------|-------------------|
| Trinity clause (2-line block) | *(protected)* added near top, verbatim | kept inline, verbatim |
| Session-first flow + env-var non-expansion + `Session.Create` ToolCall + `echo` block + UUID capture + fail-loud rule | *(protected)* | kept inline, verbatim |
| Terragrunt `run --all` port-forward (127.0.0.1:9000) + KUBE_/AWS_ exports | *(protected)* | kept inline, verbatim |
| all `dc`/`secret-bucket`/`docker-*`/`helm-upgrade`/`deploy-service`/`terragrunt` invocations | *(protected)* | kept inline, verbatim |
| every Key-Dir entry, tier-table row, secrets-flow step, architecture/convention fact | level 3: near-lossless, all retained inline | kept inline |
| hedged caveats ("almost never want or need to run", "generally will not want", "where applicable") | nuance compressed into classical particles (幾不宜／無徑／當…者) — assertive register drops the English hedge softness | baseline for full wording |
| baseline typos ("frugile", "louad", "generall", "otu extra staps", "fodler") | corrected per brief; baseline retains them as control | baseline (intentional warts) |
| `protocol/` (singular, stale) → `protocols/` with 4 files listed | corrected per brief | baseline had the stale singular |

Coreference / omission flags: "Loom" resolved as the coordinating main thread wherever the baseline said "the main thread". No pronoun ambiguity introduced; the 凡例 legend disambiguates every coined classical term against its technical referent. No hard facts dropped.

## Eval  (dataset: CLAUDE.md.prompt, run —)
not yet run — dataset: CLAUDE.md.prompt

- **Aggregate:** —
- **required_pass:** —
- **token_cost:** —
- **reject_if hits:** —

## Adhoc evals
- none

## Notes
Token-economics data point: on modern CJK-aware vocabularies, Han characters often tokenize at ≈1 token each, whereas the equivalent English is many word-pieces. This variant is +2.8% in **bytes** yet −22.7% in **characters** vs baseline (8921 vs 11547), so despite being the largest on disk it is plausibly the **densest natural-language encoding by token count** — 文言文's compression comes from the register (no articles, copulas, or function-word padding) compounded with near-1:1 char↔token mapping. Prefer this variant when the target tokenizer is CJK-strong and you want maximum semantic density per token. Known weaknesses: comprehension risk and register ambiguity for weaker models (mitigated but not eliminated by the 凡例 legend); classical particles carry assertive/normative force that can flatten the baseline's softer hedges; requires the reading model to parse literary Chinese reliably, which is uneven across model families. Verify token cost on the actual target tokenizer before promoting — the byte size understates its advantage and the char count overstates it for non-CJK tokenizers.
