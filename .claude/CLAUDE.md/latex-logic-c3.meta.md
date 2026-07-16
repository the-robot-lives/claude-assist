# latex-logic-c3.meta.md — variant meta + loss ledger

## Variant
- **slug:** latex-logic-c3
- **derived from:** baseline
- **compactness level:** 3 (lossless)
- **style:** pseudo-code (LaTeX-flavored formal spec: deontic + symbolic logic, numbered Axiom/Definition/Theorem/Corollary environments, set-builder notation)
- **language:** en (+ math/deontic notation)
- **size:** 16026 bytes / ~4.4k tokens (est.)  (baseline: 11595 bytes, **+38.2%**)

## How it was made
Restyle transform only — no fact removal (lossless c3). The baseline prose was
recast as a mathematical paper in markdown: every behavioral rule became a
numbered deontic environment ($O/F/P$ over actions), orderings became strict
partial orders ($\prec$, e.g. Terraform stack `init ≺ infra ≺ …`, tiers
`n ≺ n+1`), the secrets flow became a composition chain, key-dirs / tiers /
namespaces became set-builder and map definitions, and a compact **Notation**
legend was placed up front so the symbols are unambiguous (losslessness
requirement). All command blocks were carried verbatim; only prose typos were
fixed. Reordering: behavioral obligations (Trinity, Session, Frugality, Loom)
hoisted into §1 ahead of the domain/command/architecture material.

## Alterations to raise eval scores
- none yet

## Loss ledger
> Every fact dropped or MOVED. Protected facts never appear here as dropped.

| what | why (method / level / vs intent) | recoverable-where |
|------|----------------------------------|-------------------|
| Trinity clause (2-line block) *(protected)* | level 3: framed as Axiom 1 (Trinity Obligation), verbatim block retained | kept inline, verbatim |
| Session-first registration + `ToolCall(Session.Create)` block + env-no-expansion + capture-UUID + fail-loud *(protected)* | level 3: Axiom 2 / Lemma 2.1 / Corollary 2.2, code blocks verbatim | kept inline, verbatim |
| Terragrunt port-forward precondition + 4 exports *(protected)* | level 3: Axiom 7, exports in verbatim code block | kept inline, verbatim |
| All `dc`/`secret-bucket`/`docker-*`/`helm-upgrade`/`deploy-service`/`terragrunt` commands *(protected)* | level 3: §3 verbatim code blocks, syntax untouched | kept inline, verbatim |
| Deployment-tier table (0,1,2,5,9…) | level 3: restyled as Definition 12 (map `ns: Tier → Namespace`) + full table | kept inline |
| Secrets flow (5 steps + credential layering) | level 3: restyled as Definition 10 composition chain | kept inline |
| TF stack ordering, platform modules, docker cfg, subtrees, liquibase, conventions, git-trees | level 3: recast as Theorems/Definitions, all facts retained | kept inline |
| `protocol/` → `protocols/` + 4 governance files | correction per brief (baseline warts fixed) | Definition 6 (corrected) |
| prose typos ("frugile", "louad", "generall", "otu staps", "acords", …) | correction per brief | fixed throughout |

Coreference / omission flags: "proj" bound to `$NPL_PROJECT` (or user override)
explicitly in Axiom 2; `$NPL_ORG`/`$NPL_PROJECT` literals preserved exactly where
they must not be expanded. No omissions.

## Eval  (dataset: CLAUDE.md.prompt)
not yet run — dataset: CLAUDE.md.prompt

| case id | criterion outcomes | pass? |
|---------|--------------------|-------|
| — | not yet run | — |

- **Aggregate:** n/a (not yet run)
- **required_pass:** n/a
- **token_cost:** ~4.4k (est.)
- **reject_if hits:** none

## Adhoc evals
- none

## Notes
Exists to test whether formal/symbolic framing improves rule adherence for
audiences and models comfortable with mathematical notation. **Prefer when:** the
consuming model (or reviewer) reasons well over formal notation and the task is
rule-heavy — the deontic operators make each obligation's modality
($O$/$F$/$P$) explicit and the partial orders make sequencing unambiguous.
**Known weaknesses:** (1) legend overhead — the notation must be learned before
the body parses, and this variant is *larger* than baseline (+38.2%), so it is
the wrong pick under a tight token budget; (2) symbol-misread risk — weaker
models may misread $\prec$, $\circ$, $\mathcal{P}(\cdot)$, or the deontic
operators, or ignore inline `$…$` LaTeX that their markdown renderer drops.
Every fact also appears in prose beside its symbolic form to mitigate (2).
