# PROJ-FAQ.summary — media-tool

Companion index: question headings only, grouped by category. Full answers in
[PROJ-FAQ.md](PROJ-FAQ.md).

## Motivation
- Why would I declare `quality: medium` instead of just picking a provider myself?
- Why declare an `eval` block instead of just eyeballing the output myself?
- Why is the FIM solution library injected by default instead of opt-in?

## Fit
- When is `generate-media-prompt` the wrong tool for a one-off image?
- When should I pin `service:`/`model:` instead of letting quality-based selection choose?
- When is `-r` (interactive recursive) the wrong flag to reach for?

## Comparison
- How does the Rust CLI differ from the legacy Python engine still in `lib/`?
- How does `collapse: file` differ from `collapse: inline`/`collapse: context` in `depends_on`?
- How does eval-gated quality selection differ from just running `-n 3` and eyeballing?

## Capability
- Can post-processing actions (resize, crop, optimize) actually transform my output today?
- Can I run generations in parallel to speed up a large batch?
- Can eval grading judge audio output (music, TTS)?

## Caveats
- What happens if the eval endpoint is unreachable mid-run?
- What's the cost/latency trade-off of eval-gated generation vs `--no-eval`?
- What happens to my prompt file when I use `--refine`?
- Is the ~190-solution FIM library exhaustive, or can it still get niche formats wrong?

## Trust
- Where do my API keys come from, and does the tool log them?
- Does anything I generate leave my machine/cluster boundary beyond the provider I chose?
