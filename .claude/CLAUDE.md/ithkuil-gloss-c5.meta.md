# ithkuil-gloss-c5.meta.md — variant meta + loss ledger

## Variant
- **slug:** ithkuil-gloss-c5
- **derived from:** baseline
- **compactness level:** 5 (lossy, experimental)
- **style:** telegraphic-symbolic / experimental (interlinear conlang gloss)
- **language:** art-x-ithkuil (constructed) + en gloss
- **size:** 6394 bytes / ~2.4k tokens (est.)  (baseline: 11595 B, −44.9%)

## How it was made
Each retained content unit was rendered as a best-effort romanized Ithkuil line (Quijada
orthographic style, aesthetic only) immediately followed by an indented `⟶ gloss:` English line
that carries the operative meaning — an interlinear morpheme-gloss framing. Behavioral rules were
kept in full (as normative gloss); reference material (command catalog, architecture detail, tier
table) was dropped and ledgered per c5. Protected items (Trinity clause, Session.Create snippet +
env-resolution flow, terragrunt/MinIO prereq, kept command invocations) are preserved as verbatim
English islands with only an Ithkuil framing line above them — never transliterated. The secrets
cheatsheet was moved behind the verified pointer `docs/secret-management.md`. Baseline prose typos
were corrected; `protocol/` → `protocols/`; the accords line still points at
`./protocols/the-accords.summary.md`.

## Alterations to raise eval scores
- none yet

## Loss ledger
> Protected facts appear only as *(protected)* rows. Moved facts cite a verified target.
> Level-5 drops are recoverable only from baseline.

| what | why (method / level / vs intent) | recoverable-where |
|------|----------------------------------|-------------------|
| Trinity clause (2-line block) | *(protected)* — verbatim island, Ithkuil framing above only | kept inline, verbatim |
| Session-first flow + `echo $NPL_ORG/$NPL_PROJECT` + `Session.Create` ToolCall snippet | *(protected)* — verbatim island | kept inline, verbatim |
| Terragrunt/MinIO port-forward prereq + `KUBE_*`/`AWS_*` exports | *(protected)* — verbatim island | kept inline, verbatim |
| Kept command invocations (`terragrunt run --all …`, single-stack) | *(protected)* — verbatim English code, untranslated | kept inline, verbatim |
| Frugality/delegation, Loom identity, repo one-liner, conventions, worktrees, accords | behavioral rules — required at every level | kept inline as normative gloss |
| Secrets command cheatsheet (infisical-populate-secrets, infisical-bootstrap, hydrate-envrc, dc, secret-bucket) | level 5: reference, moved behind pointer | docs/secret-management.md (verified `test -e`) |
| Key Directories full catalog (13 entries) | level 5: reference, dropped | DROPPED — baseline only |
| Product-domain example list (codefre.sh, derobot.is, aifighter.com, gotta.cc, iotgo.io) | level 5: reference, dropped | DROPPED — baseline only |
| `make install-utilities`; docker-build/docker-push flag catalog; helm-upgrade flag catalog; deploy-service; push-subtrees.sh / rebuild-subtrees.sh | level 5: command catalog, dropped | DROPPED — baseline only |
| Architecture: TF stack ordering (init→tfstate, S3 backend, `tofu`/root.hcl); platform module list; secrets 5-step flow + `dc:`/`override:`/`auto:`/`default:` layering; docker image config (`project.projects[].services[]`, `helm:` stanza); Liquibase (`liquibase_targets`, `liquibase-shell`) | level 5: architecture detail, dropped | DROPPED — baseline only |
| Deployment tier table (7 rows: 0–5, 9) | level 5: reference table, dropped | DROPPED — baseline only |

Coreference / omission flags: "it weaves" resolved to Loom; "the main thread" = Loom throughout;
the caveat header binds "gloss lines are NORMATIVE" so the untrusted Ithkuil lines cannot be read as
instructions. No behavioral rule omitted.

## Eval  (dataset: CLAUDE.md.prompt)
not yet run — dataset: CLAUDE.md.prompt

| case id | criterion outcomes | pass? |
|---------|--------------------|-------|
| — | not yet run | — |

- **Aggregate:** n/a
- **required_pass:** n/a
- **token_cost:** ~2.4k (est.)
- **reject_if hits:** none

## Adhoc evals
- none

## Notes
Why it exists: an art-piece / experimental data point in the corpus — it probes whether framing the
whole document in an ultra-dense constructed language (Ithkuil, famed for extreme semantic density)
primes more disciplined instruction-following, or whether the exotic framing just adds noise. It is
the "does aesthetic density transfer to behavioral density?" probe.

When to prefer it: essentially never for production use — promote only as a research candidate when
comparing whether conlang framing changes compliance vs. plain English at equal fact coverage.

Known weaknesses:
- **Ithkuil competence risk** — the romanized lines are aesthetic/experimental and morphologically
  unverifiable; no LLM (author included) generates dependable Ithkuil. The `⟶ gloss:` lines are the
  only normative content; a reader who trusts the Ithkuil lines over the gloss will be misled. The
  caveat header states this explicitly.
- **Doubled lines negate density gains** — interlinear format prints two lines per unit, so despite
  Ithkuil's reputation for compression the file lands at 6.4 KB (over the ~4–5 KB target) because
  every rule must also appear in full-fidelity English gloss. The conlang buys style, not size.
- Lossy: reference material is gone from the file; recover from baseline or the cited doc.
