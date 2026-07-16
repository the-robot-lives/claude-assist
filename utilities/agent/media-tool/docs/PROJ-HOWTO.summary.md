# PROJ-HOWTO.md — Task Summary

Companion index for [PROJ-HOWTO.md](PROJ-HOWTO.md). Goal line only, no steps — for cheaply
answering "what can I be walked through here?"

| Task | Goal |
|------|------|
| Install media-tool and generate your first asset | Go from a fresh checkout to a real generated image in under 5 minutes. |
| Write a `.media.prompt` file for a given asset type | Pick the right minimal template (image, SVG, diagram, HTML, voice, music, video). |
| Preview a run before spending any API calls | See the resolved provider/model/output plan with zero API cost. |
| Batch-generate a directory with selective, parallel execution | Run a folder of related prompts, choosing which files to include, split across zellij panes. |
| Keep regenerating until the output actually looks right | Loop feedback → regenerate without hand-editing the prompt file yourself. |
| Chain prompts together with `depends_on` | Feed one generated asset's output path into another prompt, correctly ordered, in a single run. |
| Get the tool to auto-retry across providers until quality passes | Declare `quality:` + `eval` instead of pinning a provider; the tool grades and falls back automatically. |
| Reach the eval grader when you're off the LAN | Keep eval-gated generation working when the LAN inference host isn't directly reachable. |
| Get syntactically correct output in niche/rare file formats | Use the ~190-solution FIM library injected by default into every text-output generation. |
| Fix the common failure modes | Recognize dependency-cycle, missing-key, silently-stubbed-post-processing, and eval-not-firing messages, and apply the known fix. |
