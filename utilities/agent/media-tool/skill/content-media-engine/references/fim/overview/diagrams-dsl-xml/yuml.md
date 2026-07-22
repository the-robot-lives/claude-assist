# yUML

## What
yUML is a simple online UML diagram service that generates class, activity, and use-case diagrams from short text descriptions. It requires no installation — diagrams are produced through URL-based image endpoints and embedded directly in HTML or Markdown.

## How
- The LLM emits yUML text markup — bracketed classes with relationship arrows (`[Customer]<>-orders*>[Order]`), use-case parentheses, and inline `{bg:...}` styling.
- That markup is turned into a viewable artifact by embedding it in a yuml.me diagram URL, e.g. `<img src="https://yuml.me/diagram/scruffy/class/[Customer]->[Order]">`; visual styles include scruffy, plain, and nofunky. Rendering is remote (requires internet).
- Typical final artifact: a rendered diagram image served from the URL, embeddable anywhere an `<img>` works.

## Why
- Reach for yUML when you want zero-setup, URL-embeddable diagrams for lightweight contexts — best for `quick-sketches`, `documentation`, `teaching`, `blog-posts`, and `README-diagrams`.
- Limitations: limited to class, activity, and use-case diagrams (no sequence diagrams), only basic styling, simple relationships, and no local rendering (it always requires internet access).
- Relative to nomnoml (a nearby minimalist sibling): both favor terse syntax for quick diagrams, but yUML renders remotely via image URLs while nomnoml can render locally/in-browser.

## Source
- Solution reference: `fim/solution/yuml.md`
