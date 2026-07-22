# File-Mode Convention

The working, on-disk form of prompt lifecycle management: a spec file, a hidden variants directory, and a best-version symlink. This is the fallback that works today (the MCP store in [mcp-prompt-entries.md](mcp-prompt-entries.md) is still SPEC), and it is designed to be driven by the media tool as an output type — so `generate-media-prompt` can produce and refresh prompt variants like any other asset.

It aligns with the media-tool `.media.prompt` convention (schema v0.4, `skills/shared/asset-prompt-payload-schema.md`) and extends it with the pieces prompts specifically need: named requirements, an eval dataset, compactness/style axes, and a retained multi-variant history.

---

## The three parts

For a prompt file `{name}.md` (e.g. `CLAUDE.md`, `.claude/commands/deploy.md`, an agent definition):

```
CLAUDE.md            → symlink into .CLAUDE.md/  (the live prompt)
CLAUDE.md.prompt     → the spec: original, requirements, eval rubric + dataset, axes, pin
.CLAUDE.md/          → hidden variants dir (sibling to the file)
├── baseline.md              # the original, retained forever
├── baseline.meta.md
├── pointer-index-c4.md      # a variant
├── pointer-index-c4.meta.md # its notes + eval scores + loss ledger
├── shorthand-c2.md
└── shorthand-c2.meta.md
```

### 1. `{name}.md.prompt` — the spec

A YAML file conforming to / extending asset-payload schema v0.4, with a new chat-type `type: prompt`. It holds the starting-point prompt and everything needed to generate, score, and select variants.

```yaml
# CLAUDE.md.prompt
schema: "0.4"
id: claude-md-root
type: prompt                      # NEW chat-type — see media-tool integration appendix

name: "Repo-root CLAUDE.md"
description: "Operating instructions Claude Code loads for the Noizu Infra monorepo."

# --- what this prompt must do (question-aware compression target) ---
key_requirements:
  - "Session registration via tobor-sessions survives verbatim."
  - "Every secrets/dc command reproduced exactly (no paraphrase)."
  - "Frugality + delegation doctrine preserved."

# --- axes: defaults for optimization runs on this prompt ---
compactness: 4                    # default target level (0..5)
style: pointer-index              # default methodology (optional)
protect:                          # survive verbatim at every level
  - "the terragrunt MinIO port-forward prerequisite"
  - "all dc / secret-bucket commands"
lossy_ok:                         # loss acceptable here
  - "repository-overview prose"

# --- evaluation (extends v0.4 eval block) ---
eval:
  rules: >
    Grade each variant on: (1) instruction compliance — does an agent following it
    behave like one following the baseline; (2) fact recall — are protected facts
    retrievable; (3) token cost. Weighted, pass_threshold 0.8.
  pass_threshold: 0.8
  dataset:                        # inline entries now; future: codefre.sh dataset links
    - id: session-reg
      input: "How do I register my work session?"
      expect: "Session.Create via tobor-sessions with resolved $NPL_ORG/$NPL_PROJECT slugs (values read, not passed literally)."
      scoring: rubric
      weight: 1.0
    - id: secret-lookup
      input: "Where is the Infisical secret FOO defined?"
      expect: "dc infisical get FOO (masked); dc bat --all --flat --filter-key."
      scoring: contains
      weight: 1.0
    - id: tofu-prereq
      input: "I'm about to run terragrunt run --all. Anything first?"
      expect: "Start the MinIO admin port-forward (127.0.0.1:9000) or root init fails."
      scoring: rubric
      weight: 1.0
  # dataset_links:                # FUTURE — link to codefre.sh project datasets
  #   - "codefresh://project/noizu-infra/datasets/claude-md-compliance"

# --- selection ---
pin: null                         # null = auto-select best eval; else a variant slug
```

**Extensions beyond v0.4** (all additive; a v0.4 reader ignores unknown keys):
- `type: prompt` — a new chat-type asset.
- `key_requirements` — the declared intent that drives question-aware compression.
- `compactness` / `style` / `protect` / `lossy_ok` — the request axes, as per-prompt defaults.
- `eval.rules` and `eval.dataset[]` — a prompt-specific rubric and inline scoring corpus (v0.4 `eval` has `criteria`/`pass_threshold`; we add `rules` + `dataset` for prompt behavior scoring). Future: `eval.dataset_links` to codefre.sh datasets.
- `pin` — selection override.

### 2. `.{name}.md/` — the variants directory

Hidden (dot-prefixed), sibling to the prompt file. Contains, per variant:
- `{slug}.md` — the variant body. The slug is kebab-case and encodes the axes: `pointer-index-c4`, `shorthand-c2`, `yaml-meta-c3`, `baseline`.
- `{slug}.meta.md` — the notes for that variant: how it was consolidated/compressed, why, alterations made to raise eval scores, the eval scores from the spec's dataset, any adhoc evals, and the loss ledger. Template: [../assets/variant-meta-template.md](../assets/variant-meta-template.md).

**Why a directory and not the media tool's flat `name.2.md` naming?** Media assets keep at most a handful of numbered outputs and no per-output sidecar. Prompts need **N concurrently-retained versions, each with its own eval history and loss ledger** — the meta sidecar is the whole point (it's what pinning and promotion read). A flat `name.2.md` scheme can't carry per-variant meta/eval, so file mode extends the convention with the variants dir. This is one of two deliberate divergences from the media-tool convention, both because prompts are versioned-and-scored artifacts, not single-shot renders: (1) the variants dir + per-variant meta sidecars replace flat `name.2.ext` output naming; (2) the spec file is `{name}.md.prompt` (the prompt file's real name plus `.prompt`) rather than the media tool's single `.media.prompt` extension, so a prompt's spec sits visibly beside the file it optimizes and the target filename is unambiguous.

### 3. `{name}.md` — the symlink

`{name}.md` becomes a symlink into the variants dir:

```
CLAUDE.md -> .CLAUDE.md/pointer-index-c4.md
```

- **Default target:** the variant with the best eval score against the spec's dataset.
- **Override:** set `pin: <slug>` in the `.prompt` spec, or repoint the symlink by hand. A pin always wins over auto-selection.
- The live prompt is always whatever the symlink points at, so promoting a new best version is a single atomic repoint (see Safety).

---

## Migration guide — plain file → file mode

Given a plain `{name}.md` with no spec:

1. **Snapshot the baseline.** `mkdir .{name}.md/`; copy the current file to `.{name}.md/baseline.md`. This copy is permanent and never compressed.
2. **Write the spec.** Create `{name}.md.prompt` from [../assets/prompt-spec-template.md.prompt](../assets/prompt-spec-template.md.prompt). Put the current content's intent into `key_requirements`, mark `protect` items, and seed `eval.dataset` with 3–5 cases that capture what the prompt must do.
3. **Replace the file with a symlink.** Move the original aside (it's already copied as `baseline.md`), then `ln -s .{name}.md/baseline.md {name}.md`. At this point behavior is unchanged — the symlink points at the byte-identical baseline.
4. **Generate variants.** Produce compressed/restyled variants into `.{name}.md/`, each with a meta + loss ledger.
5. **Score and promote.** Run the dataset against each variant; repoint the symlink to the best (or set `pin`).

Rollback at any step is trivial: point the symlink back at `baseline.md`.

For an existing interim corpus that predates this convention — such as this repo's `.claude/CLAUDE.md/` directory (an 8-variant corpus with a `README.md` index but no `.prompt` spec and no symlink) — migration means: write the `.prompt` spec from the README's intent, rename variants to the `{slug}` convention, add per-variant `.meta.md` files carrying the loss ledgers, and introduce the symlink. The worked example walks this exact case: [worked-example-claude-md.md](worked-example-claude-md.md).

---

## Media-tool integration appendix (implementation path)

File mode is deliberately shaped so the media tool (`utilities/agent/media-tool/`, Rust CLI `generate-media-prompt`) can treat a prompt as just another asset type and generate/refresh variants. Output-type registration in that tool is **not declarative** — it is Rust — so adding `type: prompt` is a small, localized code change (all paths under `utilities/agent/media-tool/src/`):

1. **`enum AssetType`** (`src/schema.rs`) — add a `Prompt` variant.
2. **`from_type_str`** (`src/schema.rs`) — add an arm mapping `"prompt"` → `AssetType::Prompt`.
3. **`default_extension` / `is_chat_type`** (`src/schema.rs`) — give `Prompt` a `.md` default extension and mark it a **chat type** (`is_chat_type` → true), so it dispatches to a chat-completion provider and uses `prompt.system` for role instructions, exactly like `document`/`diagram`.
4. **Provider candidate match** (`src/providers/mod.rs`, ~line 84) — route `Prompt` through the chat candidate list (same tier as `document`).
5. **Chat-output path** (`src/pipeline.rs`) — the chat-completion branch keys off `prompt.meta.asset_type.is_chat_type()` (see `pipeline.rs:604` and `pipeline.rs:1001`); once `Prompt` is a chat type it already flows down that path. Add the prompt-specific write there: emit the generated variant to `.{name}.md/{slug}.md` and its meta to `{slug}.meta.md` rather than the flat `name.2.ext` scheme. Note that `src/renderers/` holds only *diagram* renderers (mermaid, plantuml, graphviz, puppeteer) — text/chat output is written by the pipeline, not a renderer, so the variants-dir divergence lives in `pipeline.rs`, not `renderers/`.

With that in place, `generate-media-prompt some-prompt.md.prompt` would resolve the spec, generate a variant at the requested compactness/style, score it against the embedded `eval` block (v0.4's grading path already exists), and drop it into the variants dir — closing the loop so prompt optimization runs on the same machinery as image/video/document generation. Until that code lands, run the workflow manually per [agent-playbook.claude-code.md](agent-playbook.claude-code.md).

---

## Safety notes

- **The baseline is permanent.** `.{name}.md/baseline.md` is the compactness-level-0 variant and is never edited or deleted. It is the only recovery source for level-5 lossy drops and the reference for every eval's "behaves like baseline" check. Losing it means losing the ability to audit every later variant.
- **Symlink flips are atomic and cheap.** Promoting a variant, rolling back a regression, or A/B-swapping is a single `ln -sf` — no content is rewritten, so a bad promotion is instantly reversible. Prefer repointing the symlink to overwriting files.
- **Never point the live symlink at an unscored variant.** The default target must have eval scores in its meta; an unscored variant can regress behavior invisibly. If you must ship before scoring, pin the baseline.
- **Verify pointers before shipping level-4 variants.** A lossless-by-reference variant is only lossless if its doc pointers / `NPLLoad` targets actually resolve. Confirm each before promoting; a dangling pointer converts a "lossless" variant into a silent level-5 loss.
- **Keep the `.prompt` spec and the variants in sync.** If `key_requirements` or the dataset change, re-score existing variants — a variant that was "best" under the old rubric may not be under the new one.
