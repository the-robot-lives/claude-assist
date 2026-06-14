# asciinema - FIM Solution Documentation

## Description
[asciinema](https://asciinema.org) records terminal sessions as lightweight, text-based `.cast` files (asciicast v2 JSON) that replay as crisp, copy-pasteable terminal animations — not video. Paired with converters, it produces embeddable web players, animated SVGs, or GIFs, making it the standard way to show CLI workflows in developer content.

## Basic Syntax
```bash
# Record, then replay
asciinema rec demo.cast
asciinema play demo.cast

# Embed the web player
# <script src="https://asciinema.org/a/<id>.js" async></script>

# Convert to standalone SVG or GIF
svg-term --in demo.cast --out demo.svg --window
agg demo.cast demo.gif        # asciinema gif generator
```

## Toolchain
- **asciinema** - Record/play `.cast` sessions
- **asciinema-player** - Self-hostable JS player (embed in articles/docs)
- **svg-term-cli** - `.cast` -> animated SVG (sharp, scalable, no video)
- **agg** - `.cast` -> GIF for platforms lacking script embeds
- **termtosvg** - Alternative recorder that emits animated SVG directly

## Strengths
- Tiny, text-based recordings (vs heavy screen-capture video)
- Crisp at any resolution; selectable/copyable text in the player
- Embeddable player or self-contained SVG/GIF outputs
- Trivial to re-record when commands change
- Perfect for reproducible CLI/DevOps demos

## Limitations
- Terminal-only (no GUI capture)
- GIF conversion loses text selectability and inflates size
- Self-hosting the player needs asset hosting
- No audio/voiceover track

## Best Use Cases
- CLI tutorials and DevOps walkthroughs in articles/docs
- README demos of command-line tools
- Reproducible install/setup sequences
- Lightweight animated terminal media for the blog

## NPL-FIM Integration
```npl
⌜asciinema-cast|asciicast|FIM@1.0⌝
format: asciicast-v2 (.cast)
record: asciinema
embed: asciinema-player
convert: svg-term | agg-gif | termtosvg
output: terminal-demo
⌞asciinema-cast⌟
```

NPL agents capture CLI workflows as asciicast and convert to player/SVG/GIF when content needs lightweight, reproducible terminal demos.
