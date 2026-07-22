# Hugo

## What
Hugo is a fast, flexible static site generator written in Go. It transforms Markdown content into static websites with themes, Go templates, and content management features, and is known for exceptional build speed.

## How
- The LLM emits Markdown content files (organized under `content/`) plus Go-template layouts and site config.
- Built with the `hugo` CLI: `hugo new site mysite`, `hugo new posts/first-post.md`, `hugo server -D` for live preview, and `hugo` to build the static site; installs via `brew`/`snap`/`choco`.
- Final artifact: a static HTML site (with optional JSON/RSS outputs).

## Why
- Reach for Hugo when build speed matters (thousands of pages in seconds), you need built-in multilingual/i18n without plugins, or you want an asset pipeline (SCSS/PostCSS/JS bundling) — great for large docs and content sites.
- Tradeoffs: Go template syntax learning curve, a smaller plugin ecosystem than Jekyll, binary distribution (not embeddable), and complex customization needs Go knowledge.
- Versus Jekyll: Hugo is Go-based single-binary speed, Jekyll offers Ruby-ecosystem plugin maturity and native GitHub Pages integration.

## Source
- Solution reference: `fim/solution/hugo.md`
