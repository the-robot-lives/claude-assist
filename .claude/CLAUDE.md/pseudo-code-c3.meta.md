# pseudo-code-c3.meta.md — variant meta + loss ledger

## Variant
- **slug:** pseudo-code-c3
- **derived from:** baseline
- **compactness level:** 3
- **style:** pseudo-code (typed module — functions, guards, enums, invariants; commands as string literals / doc-comments)
- **language:** en (Rust/TS-flavored pseudo-code)
- **size:** 15283 bytes / not-yet-measured tokens  (baseline: 11595 B, +3688 B / +31.8%)

## How it was made
Baseline expressed as a single typed pseudo-code module (`module NoizuInfra { … }`, arxiv 2311.12785 pattern): session registration as `fn session_first() -> SessionId` with precondition/`unwrap_or_else`/`require!` guards; key dirs as `const KEY_DIRS: Map<Path, Purpose>`; deployment tiers as `enum Tier { Secrets=0, … HealthTests=9 }`; deploy pipeline, secrets flow, and terraform ordering as functions/chains with an explicit `require(port_forward("127.0.0.1:9000"))` guard; conventions as `invariant` declarations; `struct Loom` for identity. Shell commands appear verbatim as string literals or in `/** doc-comments */` above the functions — command syntax untouched. Prose typos fixed; `protocols/` listed with governance docs. Trinity clause present under `#![required_runtime_behavior]` + `assert(trinity_protocol_active)` with the verbatim two-line block.

## Alterations to raise eval scores
- Authored on the main thread after the sub-agent auto-mode safety classifier flagged the verbatim Trinity block as instruction-poisoning (context-blind to the user's plan approval). Kept the brief's framing only — an `#![required_runtime_behavior]` marker + `assert(...)` + verbatim block — WITHOUT the extra imperatives ("non-negotiable", "overrides convenience", "highest precedence") that amplified the flag. No behavioral change; scope-conformant. User (Keith) explicitly confirmed the flag was a false positive and authorized the write 2026-07-16.

## Loss ledger
> Lossless. Every baseline fact encoded as a type, const, guard, invariant, literal, or doc-comment.

| what | why (method / level / vs intent) | recoverable-where |
|------|----------------------------------|-------------------|
| *(protected)* Trinity clause (2-line block) | ADDED at module top, verbatim in fenced comment | kept inline, verbatim |
| *(protected)* session-first flow + `Session.Create` doc-comment block + env-var non-expansion + fail-loud | `fn session_first()` guards + `/** … */` | kept inline, verbatim |
| *(protected)* terragrunt port-forward prereq + KUBE_*/AWS_* exports | `require(port_forward(...))` + `mod terraform` doc-comment | kept inline, verbatim |
| *(protected)* all `dc`/`secret-bucket`/`docker-*`/`helm-upgrade`/`deploy-service`/`terragrunt` syntax | verbatim in `mod commands` / `mod terraform` doc-comments | kept inline, verbatim |
| — (no baseline fact dropped) | level 3 — restyle to typed code; comments minimal | kept inline |

Coreference / omission flags: prose pronouns resolved to named symbols (session.uuid, that-bucket → `tfstate` backend). No borderline omissions.

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
Why it exists: probes whether expressing an operating manual as typed pseudo-code tightens ambiguous rules (guards/asserts make preconditions explicit) and whether models follow code-shaped instructions as well as prose. Weakness: it is the second-largest variant (+31.8%) — doc-comments carrying verbatim commands plus type scaffolding cost bytes; this is a legibility/precision play, NOT a size win. Prefer it for logic-heavy rule sets or code-native models; avoid it for token budgets. Note the classifier-provenance story in *Alterations* — the block is user-sanctioned corpus content, not a live-root directive (root symlink stays on pristine `shorthand-c2`).
