# Manim - FIM Solution Documentation

## Description
[Manim](https://www.manim.community) (Mathematical Animation Engine, Community Edition) is a Python library for programmatic explanatory math and algorithm animations — the engine behind 3Blue1Brown-style videos. It renders precise, timed animations of equations, graphs, geometry, and transformations to MP4/GIF/PNG, ideal for educational and technical explainer content.

## Basic Syntax
```python
from manim import *

class TokenBucket(Scene):
    def construct(self):
        title = Text("Token Bucket").to_edge(UP)
        eq = MathTex(r"tokens(t) = \min(C,\; tokens + r \cdot \Delta t)")
        self.play(Write(title))
        self.play(FadeIn(eq))
        self.play(eq.animate.set_color(YELLOW))
        self.wait()
# Render: manim -qh scene.py TokenBucket   (-> media/.../TokenBucket.mp4)
```

## Toolchain
- **manim** (Community Edition) - Core animation + CLI renderer
- **LaTeX** - Required for `MathTex`/`Tex` equation rendering
- **manim-slides** - Turn scenes into interactive presentation slides
- **Cairo/FFmpeg** - Backends for rasterization and video encoding
- **Quality flags** - `-ql/-qm/-qh/-qk` for draft-to-4K renders

## Strengths
- Precise, reproducible math/algorithm animations from code
- High-quality typeset equations via LaTeX
- Smooth transformations, graphs, and geometric constructions
- Version-controlled, parameterizable scenes
- Exports to MP4/GIF for video platforms and embeds

## Limitations
- Requires a LaTeX + FFmpeg toolchain
- Steep learning curve for complex choreography
- Rendering high quality is slow
- Python/animation API churn between versions

## Best Use Cases
- Educational explainer videos (math, algorithms, systems)
- Animated figures for technical articles and courses
- Visualizing transformations, proofs, or data structures
- YouTube/short-form companion media for written content

## NPL-FIM Integration
```npl
⌜manim-animate|manim|FIM@1.0⌝
format: mp4 | gif | png
runtime: python + latex + ffmpeg
scenes: [equations, graphs, transforms]
quality: ql | qm | qh | qk
slides: manim-slides
⌞manim-animate⌟
```

NPL agents use Manim for precise, code-driven mathematical/algorithmic animations as explainer video or animated article figures.
