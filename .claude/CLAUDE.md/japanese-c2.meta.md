# japanese-c2.meta.md — variant meta + loss ledger

## Variant
- **slug:** japanese-c2
- **derived from:** baseline
- **compactness level:** 2
- **style:** shorthand (Japanese kanji-dense telegraphic register — 体言止め・箇条書き中心、である調)
- **language:** ja
- **size:** 12623 bytes / not-yet-measured tokens  (baseline: 11595 B, +1028 B / +8.9%)

## How it was made
Full Japanese translation of the baseline into a dense technical register: noun-ending (体言止め) telegraphic bullets, である調 where sentences are needed, and 必須/禁止/最優先 for normative force; Japanese section headers (最初の行動, 倹約原則, 主要ディレクトリ, コマンド, アーキテクチャ, 規約). Tool/product names stay Latin script (Terragrunt, Helm, Infisical, MinIO, k8s). Prose typos fixed; `protocol/` → `protocols/` with all four governance docs listed. Trinity clause ADDED (new requirement) as a Japanese-framed section with a Japanese restatement line above the verbatim English two-line block. Protected spans kept as English islands: the `Session.Create` ToolCall block, `echo $NPL_*`, all command syntax, the `Organization '$NPL_ORG' not found` error string, the terragrunt/MinIO prereq, and the closing accords path — only trailing `#` comments and prose were translated.

## Alterations to raise eval scores
- Authored on the main thread after the sub-agent auto-mode safety classifier flagged the verbatim Trinity block as instruction-poisoning (context-blind to the user's plan approval). Content is brief-conformant. User (Keith) explicitly confirmed the flag was a false positive and authorized the write 2026-07-16.

## Loss ledger
> Lossless translation. Nothing dropped or moved; protected spans stay verbatim English.

| what | why (method / level / vs intent) | recoverable-where |
|------|----------------------------------|-------------------|
| Trinity clause (2-line block) | *(protected)* — ADDED near top, verbatim English | kept inline, verbatim |
| Session-first flow + `Session.Create` block + env-var non-expansion rule + error string | *(protected)* — level 2, Japanese prose with English islands | kept inline, verbatim |
| Terragrunt prereq (127.0.0.1:9000 port-forward + KUBE_*/AWS_* exports) | *(protected)* — level 2, inline | kept inline, verbatim |
| All `dc`/`secret-bucket`/`docker-*`/`helm-upgrade`/`deploy-service`/`terragrunt` command syntax | *(protected)* — command tokens verbatim English, comments translated | kept inline, verbatim |
| — (no baseline fact dropped) | level 2 — translation, lossless | kept inline |

Coreference / omission flags: baseline pronouns resolved to explicit Japanese nouns during translation (「セッション」「バケット」). No borderline omissions. Risk: a Japanese editor might "fix" a protected English command token — those spans were kept byte-for-byte English and must stay so.

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
Why it exists: a CJK lossless take on the corpus — tests (a) whether Session-first + Trinity compliance holds when the harness prompt is authored in Japanese with English command/tool islands, and (b) multilingual robustness of the eval battery. Token economics (honest assessment): although the byte size is +8.9% (kanji/kana cost 3 bytes each in UTF-8), modern tokenizers often map common kanji to ~1 token, so the *character* count (much lower than baseline) is the truer density signal — the token count may land near or below baseline despite the byte growth. Do not judge this variant's cost by bytes. Weakness: mixed-script surface (Japanese prose + English command islands) reads awkwardly and invites accidental edits to protected tokens; classical/formal register aside, comprehension is generally reliable for modern Japanese on current models.
