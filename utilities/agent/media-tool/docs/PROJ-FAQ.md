# PROJ-FAQ — media-tool

Answer-first Q&A for *why/when/compared-to-what* questions about `generate-media-prompt`.
For *how* see [PROJ-HOWTO.md](PROJ-HOWTO.md); for *what it is* see [PROJ-ARCH.md](PROJ-ARCH.md).

---

## Motivation

### Why would I declare `quality: medium` instead of just picking a provider myself?
Because the tool already knows which provider is best-in-class per asset type per
tier, and will fall back automatically if your first choice fails or grades poorly —
pinning a `service` throws that away. The quality table (`quality-selection-and-eval.md`)
is maintained centrally, so when a new model beats the incumbent (e.g. a new Veo
release), every prompt using `quality: high` benefits without edits. The honest
trade-off: you lose determinism — two runs of the same `quality: medium` prompt weeks
apart may hit different providers/models as the table is updated, which matters if
you need bit-for-bit reproducibility. Pin `service:` explicitly when that matters more
than best-available quality.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-get-the-tool-to-auto-retry-across-providers-until-quality-passes).*

### Why declare an `eval` block instead of just eyeballing the output myself?
Because eyeballing doesn't scale across a batch of 50 prompts, and eval grading is
what drives the provider-fallback loop — without it, the tool accepts the first
successful generation regardless of quality. The catch: grading needs a reachable
LM Studio-compatible endpoint (defaults to a specific LAN host), and reasoning-model
grading is slow (up to 300s per artifact) and non-deterministic — the same output can
score differently between runs. Audio artifacts are currently un-scorable and always
pass. If the endpoint is unreachable, `eval` silently degrades to legacy accept-first
behavior — no error, just a warning.
→ *See [quality-selection-and-eval.md](quality-selection-and-eval.md).*

### Why is the FIM solution library injected by default instead of opt-in?
Because LLM chat providers (used for `component`/`html`/`diagram`/`document`/etc.
asset types) reliably produce *plausible-but-syntactically-wrong* output in niche
formats (WaveDrom, Vega-Lite, D2, ABC notation…) without format-specific guidance —
the failure mode is silent (it looks like a diagram until you try to render it). The
cost is prompt-size overhead per generation; it's proportional to the matched
solution's guide, not the whole ~190-solution catalog.
→ *See [howto/produce-rich-formats.md](howto/produce-rich-formats.md).*

---

## Fit

### When is `generate-media-prompt` the wrong tool for a one-off image?
When you just want to paste a prompt into a chat UI and eyeball the result once —
the tool's value (dependency DAGs, eval-gated retries, refinement history, batch
naming) only pays off across repeated or multi-asset generation. For a single
throwaway image, the YAML authoring overhead isn't worth it; use a provider's web UI
directly.

### When should I pin `service:`/`model:` instead of letting quality-based selection choose?
When you need reproducibility (same model every run), you're validating a specific
provider's output for a comparison, or you're using a `provider_options` key that
only one provider supports (e.g. Suno's `personaId`). Auto-selection is for the common
case where "best available for this quality tier" is what you actually want; pinning
is the escape hatch, and it fully bypasses fallback — if that one provider fails,
generation fails, no retry across candidates.

### When is `-r` (interactive recursive) the wrong flag to reach for?
In CI or any non-interactive batch — `-r` opens a toggle list and blocks on a
terminal. For scripted or headless runs, pass a plain directory
(`generate-media-prompt ./assets/prompts`) instead, which processes everything found
with no selection step.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-batch-generate-a-directory-with-selective-parallel-execution).*

---

## Comparison

### How does the Rust CLI differ from the legacy Python engine still in `lib/`?
The Rust binary (`src/`, installed via `make install` → `~/.local/bin`) is the
maintained implementation — single binary, async provider polling, TUI, the full
13-provider/eval/FIM feature set. The Python engine (`lib/media-prompt-engine.py`) is
kept only as a no-cargo fallback for hosts without a Rust toolchain; it predates
schema v0.4's quality/eval machinery and the FIM library, so its feature set is
strictly older. Don't extend the Python engine going forward — new work targets Rust.

### How does `collapse: file` differ from `collapse: inline`/`collapse: context` in `depends_on`?
`collapse: file` substitutes `${alias}` with a filesystem path to the dependency's
generated output — the only mode that's actually implemented end-to-end today. `inline`
(base64 content) and `context` (extracted metadata like dimensions/palette) are parsed
from YAML but variable substitution for them isn't wired yet — using them will not
error, but the alias won't resolve as documented. Use `file` until that lands.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-chain-prompts-together-with-depends_on) and the Remaining Work list in `../HOW-TO.md`.*

### How does eval-gated quality selection differ from just running `-n 3` and eyeballing?
`-n <count>` generates N independent variants with no automatic judgment — you (or a
downstream step) still pick. An `eval` block adds automated grading *and* drives
provider fallback (retry with a different candidate provider on failure), which `-n`
alone never does. The two combine: `eval.max_attempts` caps how many providers are
tried, and each attempt can itself generate multiple variants.

---

## Capability

### Can post-processing actions (resize, crop, optimize) actually transform my output today?
No — every `post_processing` action is currently stubbed. The YAML is parsed and
shown in `--dry-run` output, but no ImageMagick/ffmpeg/optipng transformation runs
yet. If your prompt declares `post_processing`, plan on doing that step manually
until it lands (tracked in `../HOW-TO.md` Remaining Work).

### Can I run generations in parallel to speed up a large batch?
Partially. `-j <panes>` splits a batch across zellij panes (requires an active
zellij session) — that's process-level parallelism you drive yourself. True
within-tier parallelism (the engine generating independent tier-0 assets
concurrently in one process) is planned but not implemented; DAG tiers still
generate one prompt at a time internally.

### Can eval grading judge audio output (music, TTS)?
No — audio artifacts (mp3/wav/ogg/flac) are always un-scorable today; the tool warns
and accepts the first successful generation regardless of the `eval` block. Only
images, text-like formats, and video (via ffmpeg frame extraction) are actually
graded.

---

## Caveats

### What happens if the eval endpoint is unreachable mid-run?
Grading (and provider fallback) is skipped for that run — the tool falls back to
legacy accept-first behavior (or Groq-graded best-of if `GROQ_API_KEY` is set), with
no hard failure. This is silent unless you pass `--verbose`: an `eval` block you wrote
expecting quality gating may produce ungraded output and you won't get an error
telling you so.
→ *See [howto/troubleshooting-common-errors.md](howto/troubleshooting-common-errors.md).*

### What's the cost/latency trade-off of eval-gated generation vs `--no-eval`?
Eval grading adds a real-time cost: the hosted evaluator is a reasoning model with up
to a 300s timeout per graded artifact (`MEDIA_EVAL_TIMEOUT`), and a failed grade
triggers a full regeneration against the next candidate provider — so a `quality: high`
prompt with a strict `pass_threshold` can mean several full generations plus several
slow grading calls before it settles. `--no-eval` accepts the first successful
generation immediately, trading quality assurance for speed and predictable cost.

### What happens to my prompt file when I use `--refine`?
It's mutated in place: `prompt.text` is overwritten with the LLM-rewritten version,
and a `# --- Refinement History ---` YAML-comment trailer is appended recording each
round. There is no automatic backup — if you want the pre-refinement prompt preserved,
commit or copy the file first. The previous output file is also deleted before each
regeneration, so intermediate results aren't kept.
→ *See [PROJ-HOWTO.md](PROJ-HOWTO.md#how-to-keep-regenerating-until-the-output-actually-looks-right).*

### Is the ~190-solution FIM library exhaustive, or can it still get niche formats wrong?
Not exhaustive — it covers the catalog of solutions currently indexed
(`skill/content-media-engine/references/fim/`); a format outside that catalog gets no
injected guidance and reverts to plain-LLM-knowledge quality, i.e. the original
plausible-but-broken risk. Check the solution index before trusting output correctness
for a genuinely obscure target.

---

## Trust

### Where do my API keys come from, and does the tool log them?
Resolved per-provider from environment variables first, then `.envrc.k8.dc` secrets
at `$INFRA_ROOT`; missing keys abort generation (but not `--dry-run`, which tolerates
absence). Keys are never written to output files or the refinement-history trailer.
`--verbose` shows prompt text and attachment info, not credential values.

### Does anything I generate leave my machine/cluster boundary beyond the provider I chose?
Yes, in one specific path: eval-gated generation sends your rendered artifact
(image/text/extracted video frames) to the evaluator endpoint, which by default
resolves to a LAN inference host (`192.168.68.59:3713`) or the cluster's
`lmstudio-proxy` service — both under your own infra, not a third party. `--no-eval`
or an unreachable evaluator skips this entirely. Generation itself always goes to
whichever provider API you declared or was auto-selected (Gemini, Suno, ElevenLabs,
etc.) per their own data-handling terms.
