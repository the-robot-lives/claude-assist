# LilyPond

## What
LilyPond is a professional music-engraving program that produces publication-quality sheet music from text input. It compiles a `.ly` source file into engraved output. Its primary consumer is a command-line/server-side compiler (not a browser library), though web integration is possible via a compile service.

## How
- **LLM emits:** LilyPond source text (`.ly`) — a `\version`, optional `\header`, and a music expression such as `\relative c' { \clef treble \time 4/4 \key c \major c4 d e f | ... }`.
- **Compile step:** run `lilypond example.ly` locally, producing `example.pdf`. Install with `brew install lilypond` (macOS) or `apt-get install lilypond` (Debian/Ubuntu). For the web, POST the code to a compile service (e.g. lilybin) that returns a PDF URL; `ly2video` can render animated scores to MP4.
- **Final artifact:** publication-quality engraved sheet music as PDF (or PNG); optionally an MP4 animated score via ly2video.

## Why
- **Reach for it when:** engraving quality is paramount — music publishing, academic papers with musical examples, complex classical/orchestral scores, and automated score generation from algorithms. Extremely powerful and flexible, and text-based so version-control friendly.
- **Limitations:** steep learning curve; server-side processing required for the web; not suitable for real-time rendering.
- **Relative to siblings:** LilyPond is the heavyweight offline engraver — it beats browser renderers (VexFlow/OSMD/abcjs) on final print quality and complex classical scores, but it is a compile-to-PDF toolchain rather than an interactive in-browser display, so it is the wrong choice when you need live, client-side notation.

## Source
- Solution reference: `fim/solution/lilypond.md`
