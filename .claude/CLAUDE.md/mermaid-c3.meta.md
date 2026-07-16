# mermaid-c3.meta.md — variant meta + loss ledger

## Variant
- **slug:** mermaid-c3
- **derived from:** baseline
- **compactness level:** 3 (lossless)
- **style:** mermaid (mermaid-as-instruction — control flow lives in diagrams, not sentences)
- **language:** en
- **size:** 12459 B / tokens not measured  (baseline: 11595 B, **+7.5%** — larger; diagram markup outweighs prose savings at c3)

## How it was made
Restyle transform, not a size compression: every procedural/ordered fact in the baseline was re-expressed as a mermaid diagram — (1) session-first registration as a `flowchart TD` with a Trinity gate, fail-loudly branches, and UUID capture; (2) the deploy pipeline as an `LR` subgraph with `deploy-service` as the composite; (3) the secrets flow and the `dc/override/auto/default` credential precedence as two `LR` chains; (4) terraform stack ordering as a `TD` graph gated on the MinIO port-forward; (5) deployment tiers as an ordered `LR` graph carrying purpose+namespace in the node labels. Flat facts that do not express as edges (key dirs, conventions, project structure, and every exact command) stay in compact tables and verbatim fenced code blocks between the diagrams, with one line of prose glue per section. Baseline prose typos were corrected (frugile→frugal, louad→loud, generall→generally, otu→out, staps→steps, fodler→folder, acords→accords); the `protocol/` dir entry was corrected to `protocols/` and expanded to its four governance files per the brief. All mermaid node labels containing special characters (`⇒`, `·`, `:`, `/`, `*`, `$`, parens, `--flags`) are wrapped in quoted strings; no literal double-quote/`#`/`<`/`>` appears inside any label.

## Alterations to raise eval scores
- none yet

## Loss ledger
> Lossless c3: no non-protected fact was dropped or moved behind a pointer. Protected items are listed as rows kept inline, verbatim.

| what | why (method / level / vs intent) | recoverable-where |
|------|----------------------------------|-------------------|
| Trinity clause (2-line protected block) *(protected)* | added verbatim, adjacent to the Trinity gate node in diagram 1; never translated | kept inline, verbatim |
| Session-first flow — resolve slugs → Session.Create → capture UUID → fail-loudly *(protected)* | rendered as flowchart 1; behavioral rule preserved | kept inline, verbatim |
| Env-var gotcha (`"$NPL_ORG"` ⇒ `Organization '$NPL_ORG' not found`) *(protected)* | stated in the prose line adjacent to diagram 1 rather than a node label, to avoid double-quote escaping in mermaid; text unchanged | kept inline, verbatim |
| `ToolCall(tool: "Session.Create", …)` args block *(protected)* | kept as a fenced code block below diagram 1 | kept inline, verbatim |
| Terragrunt port-forward prerequisite (127.0.0.1:9000) *(protected)* | encoded as the gate node in diagram 4 AND restated in the **Important** prose line + code block | kept inline, verbatim |
| All `dc` / `secret-bucket` / `docker-*` / `helm-upgrade` / `deploy-service` / `terragrunt` command syntax *(protected)* | reproduced verbatim in fenced code blocks; diagrams reference them by flow only | kept inline, verbatim |
| Key dirs, deployment tiers, platform modules, docker-image config, project structure, liquibase, conventions, git-trees, accords close | c3 lossless — retained in tables / node labels / prose | kept inline |

Coreference / omission flags: env-var gotcha double-quote example placed in adjacent prose (not a node label) — mermaid cannot safely carry a literal `"` inside a label; fact text is unchanged and still inline. Deployment-tier table collapsed into diagram-6 node labels (tier · purpose · namespace) rather than a separate table — no data lost. Baseline typos resolved as above; `the acords` → `the accords`; closing accords pointer kept at `./protocols/the-accords.summary.md` per brief.

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
Exists to test whether an agent reading a CLAUDE.md follows **control-flow-as-diagram** more reliably than prose sentences — the mechanism is that ordering, branches, and gates become explicit edges (session-first gate, fail-loudly branch, tier order, stack order, MinIO port-forward gate) instead of buried imperatives. Prefer this variant when the operative facts are sequences and preconditions and the reader benefits from seeing the branch structure at a glance. Known weaknesses: (1) at c3 it is *larger* than baseline — diagram markup is pure overhead for the many flat facts (dirs, conventions, command flags) that carry no control flow, so it is a poor pick when size is the goal; (2) mermaid parse fragility — a single unquoted special char in a label breaks the whole block, and rendering fidelity varies by mermaid version; (3) diagram node labels get long, which pushes some detail toward the edge of what reads cleanly as a graph. Not validated against a live mermaid renderer (no mmdc/chromium available); syntax verified by construction — all special-char labels quoted, `end` used only to close the one subgraph.
