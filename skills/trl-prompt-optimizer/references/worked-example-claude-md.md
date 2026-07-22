# Worked Example — Compressing a CLAUDE.md

The end-to-end case, on a real file: this repo's own root `CLAUDE.md`. It was compressed into an eight-variant corpus (living at `.claude/CLAUDE.md/` with a `README.md` index), and the results teach the skill's central lesson — that most of the "compression" people reach for is actually *style*, and that moving reference material out beats deleting it. The example ends by showing what full file-mode adoption would look like for this same file.

---

## The problem

The baseline `CLAUDE.md` is a ~11.6KB operating manual: session-registration ritual, a frugality/delegation doctrine, a repository overview, a large block of exact shell commands (docker build, helm, terragrunt, and a `dc`/Infisical secrets cheatsheet), architecture notes, and conventions. It is loaded into context every session, so its size is a recurring tax — but it also contains behavioral rules that *must not* drift and exact commands that *must not* be paraphrased. Classic compression target: high value, high risk, mixed rules-and-reference.

Declared intent (what became `key_requirements`): session registration survives verbatim; every secrets/dc command reproduced exactly; the frugality-and-delegation doctrine preserved. `protect`: the terragrunt MinIO port-forward prerequisite, all `dc`/`secret-bucket` commands. `lossy_ok`: the repository-overview prose.

---

## The eight variants

Each variant sits at a compactness level and makes that level's declared sacrifice. Sizes are the measured file sizes.

| slug | level | approach | lossless? | size | what it trades |
|------|-------|----------|-----------|------|----------------|
| `baseline-original` | 0 | verbatim from git (typos intact) | yes | 11.6KB | nothing — the control |
| `plain-english-concise` | 1 | ruthless plain-English edit; full words, no notation | yes | 11.1KB | redundancy, hedging |
| `shorthand-symbolic` | 2 | abbreviations (b4, w/, cfg, TF) + symbols (⇒ ∀ ¬); **currently live** | yes | 10.0KB | readability for the uninitiated |
| `structured-data` | 2–3 | rules/facts as YAML blocks, prose minimized, commands consolidated | yes | 9.9KB | prose framing (tests machine-parseable form) |
| `checklist-imperative` | 3 | MUST-checklist rules first, reference after (compliance-ordered) | yes | 9.5KB | rationale/explanation ordering |
| `ultra-terse-min-loss` | 3 | telegraphic sections, ALL facts retained — full command semantics + secrets cheatsheet compacted inline | yes | 8.1KB | prose flow; the **inline lossless floor** |
| `pointer-index` | 4 | rules inline; all reference material = one-line denotation + verified pointer into `docs/` | by reference | **3.8KB** | one doc read per referenced area |
| `ultra-terse-lossy` | 5 | telegraphic one-block sections; secrets cheatsheet → pointer, other facts dropped | **lossy** | 3.9KB | ~4.2KB of facts dropped outright |

---

## The result that matters

Two variants land at essentially the same size — `pointer-index` at 3.8KB and `ultra-terse-lossy` at 3.9KB — but they are not equivalent:

- **`pointer-index` (3.8KB) is lossless by reference.** Every fact still exists; the bulky reference material (the command cheatsheet) was moved to `docs/` with a one-line pointer left behind, each pointer verified to resolve.
- **`ultra-terse-lossy` (3.9KB) dropped ~4.2KB of facts** to reach the same size and is *larger* while being *worse*.

So the lossy variant paid ~4.2KB of information and got nothing for it — the reference-based variant was already smaller without losing anything. That is the whole doctrine in one comparison.

### Loss decomposition — style vs content

Walking the size ladder from the live `shorthand-symbolic` (10.0KB) down:

- **10.0KB → 8.1KB (`ultra-terse-min-loss`): ~1.9KB, all style.** Telegraphing sections and compacting inline, zero facts lost. This is the last of the purely-inline style savings; 8.1KB is the floor for "everything inline, nothing lost."
- **8.1KB → 3.8KB (`pointer-index`): ~4.3KB, by moving reference out.** The command cheatsheet and other reference blocks left the file for `docs/`, replaced by pointers. Facts retained, location changed.
- **Rough split across the corpus: ~3.5KB of the total achievable savings was *style* (levels 1–3), and ~4.2KB was *content* (reference material) that could be moved (level 4) or deleted (level 5).**

The lesson: past the inline floor (level 3), further size comes from **moving reference material, not deleting facts.** Deleting (level 5) buys nothing that moving (level 4) doesn't already buy — because the thing taking up space was *reference*, and reference wants to be pointed at, not pruned.

---

## The doc-pointer doctrine

The `pointer-index` variant codifies the rule the skill applies everywhere:

- **Behavioral rules stay inline.** Anything the model needs *every turn* to act correctly — session registration, the frugality doctrine, the MinIO port-forward warning, the exact secret commands (`protect`) — is kept in the prompt verbatim. These are not reference; they are the operating instructions.
- **Reference material is denoted + pointed at.** For material consulted *occasionally* — the full command catalog, architecture deep-dives — the prompt keeps a one-line denotation ("Secrets management: see `docs/secret-management.md`") instead of the block. The prompt asserts *that* the capability exists and *where* the detail lives.
- **Pointers are verified before citing.** Every `docs/…` target was confirmed to actually contain the referenced material before the pointer shipped. An unverified pointer is not compression — it is a silent level-5 omission wearing a level-4 costume. This verification is the line between lossless-by-reference and accidental data loss.

Cost, stated honestly: `pointer-index` costs a `docs/` read whenever a referenced area is actually needed. For a file loaded every session but whose command catalog is used only sometimes, that is a good trade — the recurring tax drops by two-thirds and the fetch is paid only on demand.

---

## What full file-mode adoption looks like

The existing corpus is an *interim* form: eight files plus a `README.md` index, but no `.prompt` spec, no per-variant meta/ledger, and no symlink (promotion is a manual "copy it over `CLAUDE.md`"). Migrating it to the file-mode convention ([file-mode-convention.md](file-mode-convention.md)) looks like this.

**1. The spec — `CLAUDE.md.prompt`:**

```yaml
schema: "0.4"
id: claude-md-root
type: prompt
name: "Repo-root CLAUDE.md"
description: "Operating instructions Claude Code loads for the Noizu Infra monorepo."
key_requirements:
  - "Session registration via tobor-sessions survives verbatim."
  - "Every secrets/dc command reproduced exactly (no paraphrase)."
  - "Frugality + delegation doctrine preserved."
compactness: 4
style: pointer-index
protect:
  - "the terragrunt MinIO port-forward prerequisite"
  - "all dc / secret-bucket commands"
lossy_ok:
  - "repository-overview prose"
eval:
  rules: "Grade instruction compliance, protected-fact recall, and token cost. Weighted, pass 0.8."
  pass_threshold: 0.8
  dataset:
    - id: session-reg
      input: "How do I register my work session?"
      expect: "Session.Create via tobor-sessions with resolved slugs (values read, not passed literally)."
      scoring: rubric
    - id: secret-lookup
      input: "Where is the Infisical secret FOO defined?"
      expect: "dc infisical get FOO (masked); dc bat --all --flat --filter-key."
      scoring: contains
    - id: tofu-prereq
      input: "About to run terragrunt run --all — anything first?"
      expect: "Start the MinIO admin port-forward (127.0.0.1:9000) or root init fails."
      scoring: rubric
pin: null            # auto-select best passing variant within budget
```

**2. The variants dir — `.CLAUDE.md/`:**

```
.CLAUDE.md/
├── baseline.md                  # = baseline-original, retained forever
├── baseline.meta.md
├── shorthand-c2.md              # = shorthand-symbolic (the old "live" one)
├── shorthand-c2.meta.md
├── ultra-terse-min-loss-c3.md
├── ultra-terse-min-loss-c3.meta.md
├── pointer-index-c4.md          # the lossless-by-reference winner
├── pointer-index-c4.meta.md     # ← carries the loss ledger below
└── ... (remaining variants)
```

A `pointer-index-c4.meta.md` loss ledger entry:

| what | why | recoverable-where |
|------|-----|-------------------|
| the full `dc`/Infisical secrets cheatsheet | level 4: reference material, moved — not a per-turn rule | `docs/secret-management.md` (verified present) |
| docker/helm/terragrunt command catalog | level 4: reference, moved | `docs/…` runbook (verified present) |
| *(protected)* MinIO port-forward prerequisite | — | **kept inline**, never moved |
| *(protected)* all `dc`/`secret-bucket` commands | — | **kept inline**, verbatim |

**3. The symlink:**

```
CLAUDE.md -> .CLAUDE.md/pointer-index-c4.md
```

After scoring, `pointer-index-c4` is the best passing variant within a reasonable budget (lossless, ~3.8KB), so the symlink points there. Promotion or rollback is now a single atomic `ln -sf`; the old "copy it over `CLAUDE.md`" step is gone, and the baseline survives as both the fallback pin and the behavior reference every eval checks against.

---

## Takeaways to reuse

1. **Style savings top out around level 3.** For a rules-plus-reference file, inline compression bottoms out at the "everything inline, nothing lost" floor (~8KB here); the big win is level 4.
2. **Prefer moving to deleting.** `pointer-index` (level 4) beat `ultra-terse-lossy` (level 5) on *both* size and loss. Only go lossy when the caller explicitly accepts it in a `lossy_ok` area.
3. **Verify every pointer.** Lossless-by-reference is only lossless if the target resolves — check before you cite.
4. **Keep rules inline, point at reference.** The rule/reference split is the single most useful classification you make in Phase 2.
