# How to: chain prompts together with `depends_on`

**Goal:** generate a base asset once, then feed its output file path into one or more prompts
that build on it (image-to-video, compositing, a hero page referencing a generated logo) — in a
single `generate-media-prompt` run, correctly ordered.
**Prereqs:** the depending prompt(s) and the prompt(s) they depend on must live in the same scan
scope (same directory, or a parent directory you pass to the CLI).

1. Give the base prompt a stable `id`:

   ```yaml
   # base-logo.media.prompt
   id: logo-001
   type: image
   prompt:
     text: "minimalist geometric fox logo, flat vector, transparent background"
   ```

2. Reference it from the dependent prompt via `depends_on`, using `collapse: file` — the only
   collapse mode that's actually wired up end-to-end today:

   ```yaml
   # hero-page.media.prompt
   id: hero-001
   type: html
   depends_on:
     - ref: logo-001            # matches the other file's `id:` (or its relative path)
       as: logo                 # ${logo} in prompt.text below
       collapse: file            # file | inline | context — only "file" resolves substitution
       optional: false           # true = keep going even if logo-001 fails
   prompt:
     text: "landing page hero section, use ${logo} as the header logo image"
   ```

3. Run the tool against the directory containing both files (not just the dependent one) so the
   DAG can resolve:

   ```bash
   generate-media-prompt --dry-run --verbose ./assets/
   ```

**Verify:** the `--dry-run --verbose` output's "Resolving dependencies" section lists
`1. logo-001` before `2. hero-001` — confirming the DAG resolved and ordered them correctly before
anything would actually generate. (`${logo}` still shows literally in the dry-run's `Prompt:` line
— substitution happens at real generation time, not during dry-run.) Drop `--dry-run` to run for
real; the tool generates `logo-001` first, then substitutes `${logo}` with the filesystem path to
its output before generating `hero-001`.

**Gotchas:**
- `collapse: inline` (base64 content) and `collapse: context` (extracted metadata like
  dimensions/palette) parse without error but variable substitution for them isn't implemented
  yet — the alias won't resolve as documented. Use `collapse: file` until that lands.
- `ref` matches by the dependency's `id:` field or its relative path — not its filename. If
  `${alias}` never resolves, confirm `id:` in the referenced file matches `ref:` exactly and both
  files are inside the directory/scope you passed to the CLI.
- Two files depending on each other (directly or transitively) aborts the *entire* batch with a
  cycle error, not just the offending files — dependency resolution happens before any generation
  starts. Always `--dry-run` a new batch of interdependent prompts first to catch this for free.

→ *See `../../README.md#dependencies` for the full collapse-mode table and resolution algorithm,
and [troubleshooting-common-errors.md](troubleshooting-common-errors.md) for the cycle/unresolved-
alias error messages.*
