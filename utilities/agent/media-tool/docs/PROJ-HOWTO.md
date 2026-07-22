# How-To: media-tool

Task-oriented guides for the things you'll actually do with `generate-media-prompt`. For *what
it is* see [PROJ-ARCH.md](PROJ-ARCH.md); for *where things live* see
[PROJ-LAYOUT.md](PROJ-LAYOUT.md); for the full schema and CLI flag reference see `../README.md`
and `../HOW-TO.md`.

---

## How to: install media-tool and generate your first asset
Go from a fresh checkout to a real generated image in under 5 minutes.
→ *See [howto/first-hour.md](howto/first-hour.md)*

## How to: write a `.media.prompt` file for a given asset type
Image, SVG, diagram, HTML, voice, music, or video — each has a minimal template.
→ *See `../HOW-TO.md`* (the project's own quickstart reference; not duplicated here)

## How to: preview a run before spending any API calls

**Goal:** see exactly which provider/model will be called, the output path, and the resolved
dependency order — with zero API cost.
**Prereqs:** none — `--dry-run` tolerates a missing API key.

```bash
generate-media-prompt --dry-run --verbose demos/image/sample-logo.media.prompt
# or preview an entire directory, including dependency-tier ordering:
generate-media-prompt --dry-run --verbose demos/
```

**Verify:** output ends with `✅ Dry run complete — no API calls made`, and each prompt's line
shows the provider it would call plus the final `Output:` path.

**Gotchas:** dry-run still validates attachments and resolves the dependency DAG, so it *will*
catch cycle errors and missing-attachment errors before you'd spend a call.

---

## How to: batch-generate a directory with selective, parallel execution

**Goal:** run a folder of related prompts, choosing which files to include, optionally splitting
them across parallel zellij panes.
**Prereqs:** running inside a zellij session if you want `-j` > 1.

```bash
# Toggle which nested *.prompt files to run:
generate-media-prompt -r ./assets/prompts

# Same, but distribute the selected files across up to 4 zellij panes
# (files with a depends_on relationship stay together in one batch):
generate-media-prompt -r ./assets/prompts -j 4
```

**Verify:** each pane/run prints its own generation plan and success/skip lines per prompt.

**Gotchas:** `-r` opens an interactive toggle list — it's not scriptable as-is; for CI/non-
interactive batches, pass a plain directory (`generate-media-prompt ./assets/prompts`) instead,
which processes everything found without a selection step.

---

## How to: keep regenerating until the output actually looks right

**Goal:** loop feedback → regenerate without hand-editing the prompt file yourself.
**Prereqs:** a prompt already producing *some* output.

```bash
generate-media-prompt --refine hero.media.prompt
```

Answer `y` to accept, `n` (then describe what's wrong) or type feedback directly. The tool sends
your feedback + the original prompt to a text model, rewrites `prompt.text` in place, appends a
`# --- Refinement History ---` comment block to the file, deletes the previous output, and
regenerates — looping until you accept.

**Verify:** the `.media.prompt` file itself now has a refinement history trailer, and its
`prompt.text` differs from what you started with.

**Gotchas:** this mutates the prompt file in place — commit or copy it first if you want to keep
the pre-refinement version around.

---

## How to: chain prompts together with `depends_on`
Generate a base asset once, then feed its output file path into one or more prompts that build
on it (image-to-video, compositing, a hero page referencing a generated logo) in a single run.
→ *See [howto/declare-dependencies-between-prompts.md](howto/declare-dependencies-between-prompts.md)*

---

## How to: get the tool to auto-retry across providers until quality passes
Declare `quality:` + an `eval` block instead of pinning `service:` — the tool tries candidate
providers in order and grades each output, falling back until one passes (or the best-scoring one
is kept with a warning).
→ *See `../HOW-TO.md#evaluation-criteria` and [quality-selection-and-eval.md](quality-selection-and-eval.md) for the full design*

---

## How to: reach the eval grader when you're off the LAN

**Goal:** keep eval-gated generation working when `192.168.68.59:3713` (the LAN inference host)
isn't directly reachable from your machine.
**Prereqs:** `kubectl` context `noizu` configured.

```bash
bin/media-eval-port-forward
```

Loops `kubectl port-forward svc/lmstudio-proxy 3713:3713` in namespace `platform-ai`,
reconnecting automatically. The tool's endpoint probe already checks `127.0.0.1:3713` last, so
once this is running, generation with an `eval` block picks it up with no flags needed.

**Verify:** `curl http://127.0.0.1:3713/v1/models` returns a model list while the script runs.

---

## How to: get syntactically correct output in niche/rare file formats
The tool injects format-specific guidance from a ~190-solution library (diagram DSLs, 3D/WebGL,
math typesetting, music notation, EDA tools, and more) into every text-output generation, by
default — this is why prompts asking for e.g. WaveDrom or Vega-Lite come back correct instead of
plausible-but-broken.
→ *See [howto/produce-rich-formats.md](howto/produce-rich-formats.md)*

---

## How to: fix the common failure modes
Dependency cycles, unresolved `${alias}` refs, dead-on-missing-key errors, silently-stubbed
post-processing, and eval grading that never seems to fire — recognize the message, apply the fix.
→ *See [howto/troubleshooting-common-errors.md](howto/troubleshooting-common-errors.md)*

---

## Maintenance

See `~/.claude/commands/npl-update-howto-docs.md` for how this file and its `howto/` extractions
are kept in sync. Companion task list: [PROJ-HOWTO.summary.md](PROJ-HOWTO.summary.md).
