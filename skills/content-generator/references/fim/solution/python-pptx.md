# python-pptx - FIM Solution Documentation

## Description
[python-pptx](https://python-pptx.readthedocs.io) creates and edits Microsoft PowerPoint `.pptx` files programmatically — slides, layouts, text frames, tables, charts, and images. It produces fully editable native decks (real shapes, not rasterized), making it the right tool when a deck must be handed off for further editing in PowerPoint/Keynote.

## Basic Syntax
```python
from pptx import Presentation
from pptx.util import Inches, Pt

prs = Presentation()
title_slide = prs.slides.add_slide(prs.slide_layouts[0])
title_slide.shapes.title.text = "Rate Limiting 101"
title_slide.placeholders[1].text = "Token, leaky, sliding window"

bullets = prs.slides.add_slide(prs.slide_layouts[1])
bullets.shapes.title.text = "Token Bucket"
tf = bullets.placeholders[1].text_frame
tf.text = "Allows controlled bursts"
p = tf.add_paragraph(); p.text = "Refills at a fixed rate"; p.level = 1

bullets.shapes.add_picture("diagram.png", Inches(5), Inches(1.5), width=Inches(4))
prs.save("deck.pptx")
```

## Toolchain
- **python-pptx** - Core create/edit library
- **Template .pptx** - Start from a branded master for layouts/themes
- **Marp / Pandoc** - Alternative Markdown -> PPTX paths (less native control)
- **Pillow / Matplotlib** - Generate images/charts to embed
- **Slide layouts** - Map content blocks to master placeholders

## Strengths
- Native, fully editable PPTX (real text frames, tables, charts)
- Reuse corporate template masters for on-brand decks
- Programmatic generation from data (reports, dashboards-to-slides)
- Embed images and native charts
- Automatable for batch/recurring decks

## Limitations
- No rendering/preview without PowerPoint/LibreOffice
- Animations and transitions are not supported
- Complex custom graphics are tedious vs a design tool
- Chart styling is more limited than the PowerPoint UI

## Best Use Cases
- Repurposing an article into an editable corporate deck
- Data-driven decks generated from metrics or trackers
- Templated client/sales decks at scale
- Hand-off presentations the recipient will edit in PowerPoint

## NPL-FIM Integration
```npl
⌜pptx-author|pptx|FIM@1.0⌝
format: pptx
builder: python-pptx
template: brand-master.pptx
blocks: [title, bullets, table, image, chart]
output: editable-powerpoint
⌞pptx-author⌟
```

NPL agents author PPTX with python-pptx when the deck must be native and editable; they fall back to Marp/Pandoc for quick Markdown-driven decks.
