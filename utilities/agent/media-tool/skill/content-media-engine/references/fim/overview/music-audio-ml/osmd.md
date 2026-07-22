# OSMD (OpenSheetMusicDisplay)

## What
OSMD is a TypeScript/JavaScript library that renders MusicXML scores in the browser using VexFlow underneath, with automatic layout and formatting. It is a high-level MusicXML display library; its primary consumer is browser JavaScript. BSD-3-Clause open source, free for commercial use.

## How
- **LLM emits:** a MusicXML document (the score to display) — OSMD is configured in code, not via a bespoke text DSL.
- **Render step:** `import { OpenSheetMusicDisplay }`, construct `new OpenSheetMusicDisplay('score-container', { backend: 'svg', drawTitle: true, ... })`, then `await osmd.load('score.musicxml')` followed by `await osmd.render()`. Install via `npm install opensheetmusicdisplay` (types included) or a CDN script. Rich options control page format, part names, measure numbers, and more.
- **Final artifact:** an engraved score rendered as SVG (or canvas) in the browser, with automatic spacing/alignment and basic cursor support.

## Why
- **Reach for it when:** you have MusicXML and want professional automatic layout without hand-positioning — digital sheet-music platforms, education software with score display, practice apps needing cursor/score-following, analysis/annotation tools, and MusicXML→web publishing. Comprehensive MusicXML support and a simpler API than raw VexFlow.
- **Limitations:** larger bundle (~2–3MB); less granular control than direct VexFlow; no built-in audio playback (needs a separate audio library); memory-intensive on very large orchestral scores; limited animation; web print may not match screen exactly.
- **Relative to siblings:** OSMD is the MusicXML-file renderer, VexFlow the low-level programmatic notation API it is built on. Reach for OSMD when your input is a complete MusicXML score and you want layout handled for you; reach for VexFlow when you are generating notation programmatically and want fine control.

## Source
- Solution reference: `fim/solution/osmd.md`
