# shorthand-c2.meta.md — variant meta + loss ledger

## Variant
- **slug:** shorthand-c2
- **derived from:** baseline
- **compactness level:** 2
- **style:** shorthand (English abbreviations b4/w/cfg/TF + logic symbols ⇒ ∀ ¬)
- **language:** en
- **size:** 10038 bytes / not-yet-measured tokens  (baseline: 11595 B, −1557 B / −13.4%)

## How it was made
The pre-file-mode live root `CLAUDE.md`, renamed into the corpus unchanged. Baseline recast into telegraphic shorthand — abbreviations (b4, w/, cfg, 1st, TF), logic symbols (⇒, ∀, ¬), dropped articles/copulas — with every fact retained and all command blocks verbatim. Prose typos fixed; the stale `protocol/` Key-Dirs reference NOT fixed here (see Notes — pristine).

## Alterations to raise eval scores
- none yet

## Loss ledger
> Lossless style transform. Nothing dropped or moved.

| what | why (method / level / vs intent) | recoverable-where |
|------|----------------------------------|-------------------|
| — (all baseline facts retained inline) | level 2 — shorthand/symbolic restyle only | kept inline |
| Session-first flow + `Session.Create` block + env-var non-expansion rule | *(protected)* — inline, verbatim | kept inline, verbatim |
| Terragrunt port-forward prereq (127.0.0.1:9000) + KUBE_*/AWS_* exports | *(protected)* — inline | kept inline, verbatim |
| All `dc`/`secret-bucket`/`docker-*`/`helm-upgrade`/`deploy-service`/`terragrunt` syntax | *(protected)* — verbatim | kept inline, verbatim |

Coreference / omission flags: none — pronouns already terse in baseline; symbol legend (⇒/∀/¬) assumed unambiguous to the target model.

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
**Trinity clause ABSENT by design — this is the pristine pre-trinity live pin.** `shorthand-c2` is byte-identical to the repo-root `CLAUDE.md` that preceded file mode; the spec pins the live symlink here (`pin: shorthand-c2`) so migrating to file mode changed *nothing* about live behavior, and the user's "trinity not live at root yet" decision holds. Its trinity-bearing twin is **`shorthand-trinity-c2`** (identical + clause + `protocols/` fix). To take Trinity live, repoint the symlink / `pin` to the twin. Because this file is the pin, its stale `protocol/` reference is left intact to preserve byte-identity with the historical root; the twin carries the corrected `protocols/` listing.
