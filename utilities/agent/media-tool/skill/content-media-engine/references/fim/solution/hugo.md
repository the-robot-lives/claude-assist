# Hugo — Fast static site generator (Go)

Hugo is a static site generator written in Go, renowned for building thousands of pages in milliseconds. It transforms Markdown content plus Go-template layouts into a static website, with built-in taxonomies, multilingual support, an asset pipeline (Hugo Pipes), and shortcodes. Popular for documentation sites, blogs, and corporate marketing pages.

**Current Version**: Hugo 0.13x+ (extended edition recommended for SCSS)  **License**: Apache-2.0  **Runtime**: single Go binary `hugo`; no Node/Ruby required for the core

## Official Resources & Documentation
- **Website**: https://gohugo.io/
- **Documentation**: https://gohugo.io/documentation/
- **Templating (Go templates)**: https://gohugo.io/templates/introduction/
- **Functions reference**: https://gohugo.io/functions/
- **Themes**: https://themes.gohugo.io/
- **GitHub**: https://github.com/gohugoio/hugo
- **Discourse forum**: https://discourse.gohugo.io/

## Installation & Setup
```bash
brew install hugo                   # macOS (extended edition)
snap install hugo                   # Linux
choco install hugo-extended         # Windows (extended for SCSS/SASS)

hugo new site mysite                # scaffold
cd mysite
git init && git submodule add https://github.com/theme/repo themes/mytheme
echo "theme = 'mytheme'" >> hugo.toml
hugo new content posts/first-post.md
hugo server -D                      # dev server, includes drafts
hugo --minify                       # production build -> public/
```

## Project Structure
```
mysite/
├── hugo.toml            # site config (or hugo.yaml / hugo.json)
├── content/             # Markdown content
│   ├── posts/
│   │   ├── _index.md    # section landing page
│   │   └── first.md
│   └── about.md
├── layouts/             # template overrides
│   ├── _default/
│   │   ├── baseof.html  # base template
│   │   ├── single.html  # single page
│   │   └── list.html    # section/list page
│   └── partials/
├── static/              # copied verbatim to site root
├── assets/              # processed by Hugo Pipes (SCSS/JS)
├── data/                # data files (YAML/JSON/TOML)
├── i18n/                # translation strings
└── themes/
```

## Core Concepts & Syntax

### Front matter (TOML / YAML / JSON)
```yaml
---
title: "My First Post"
date: 2024-06-01T10:00:00-07:00
draft: false
tags: ["hugo", "static-site"]
categories: ["tutorials"]
weight: 10
description: "An intro post"
params:
  featured_image: /images/hero.jpg
---
```
Front matter drives page metadata, taxonomies, ordering (`weight`), and custom `params`. Delimiters: `---` YAML, `+++` TOML, `{ }` JSON.

### Site configuration (hugo.toml)
```toml
baseURL = "https://example.com/"
languageCode = "en-us"
title = "My Site"
theme = "mytheme"

[params]
  author = "Me"

[menu]
  [[menu.main]]
    name = "Blog"
    url = "/posts/"
    weight = 1

[markup.highlight]
  style = "github"
  lineNos = true

[languages]
  [languages.en]
    weight = 1
  [languages.fr]
    weight = 2
    title = "Mon Site"
```

### Go templates (layouts)
```go-html-template
{{ define "main" }}
  <h1>{{ .Title }}</h1>
  {{ .Content }}
  <ul>
  {{ range .Pages }}
    <li><a href="{{ .RelPermalink }}">{{ .Title }}</a> — {{ .Date.Format "Jan 2, 2006" }}</li>
  {{ end }}
  </ul>
{{ end }}
```
`{{ }}` is a Go-template action; `.` is the current context (a Page, Site, etc.). `range` iterates, `with` rebinds context, `partial` includes a partial, `|` pipes through functions.

### Shortcodes (reusable content components)
```markdown
{{</* youtube w7Ft2ymGmfc */>}}

{{</* figure src="/img/arch.png" title="Architecture" width="600" */>}}

{{%/* callout type="warning" */%}}
This body is rendered as Markdown inside the shortcode.
{{%/* /callout */%}}
```
`{{< >}}` passes raw HTML output; `{{% %}}` renders the inner content as Markdown. Define custom shortcodes in `layouts/shortcodes/name.html`.

### Taxonomies
```toml
[taxonomies]
  tag = "tags"
  category = "categories"
  author = "authors"
```
Hugo auto-generates term and list pages for each taxonomy from front-matter values.

## How-To (worked recipes)

### How to theme & add colors (Hugo Pipes / SCSS)
Hugo Extended processes SCSS through the asset pipeline — the "add colors/styling" path:
```scss
// assets/scss/main.scss
$brand: #1e6fba;
$bg: #ffffff;

body { background: $bg; color: #222; }
a { color: $brand; }
.callout-warning { border-left: 4px solid $brand; background: lighten($brand, 55%); }
```
```go-html-template
{{/* layouts/partials/head.html */}}
{{ $style := resources.Get "scss/main.scss" | css.Sass | resources.Minify | resources.Fingerprint }}
<link rel="stylesheet" href="{{ $style.RelPermalink }}" integrity="{{ $style.Data.Integrity }}">
```
`css.Sass` compiles SCSS, `Minify` shrinks it, `Fingerprint` adds a cache-busting hash. Requires the **extended** Hugo binary. Site colors are typically exposed as `[params]` and injected into the SCSS or as CSS variables.

### How to create a custom shortcode
```go-html-template
{{/* layouts/shortcodes/callout.html */}}
<div class="callout callout-{{ .Get "type" }}">
  {{ .Inner | markdownify }}
</div>
```
```markdown
{{%/* callout type="tip" */%}}
Use `.Inner` with `markdownify` so the body supports Markdown.
{{%/* /callout */%}}
```

### How to add syntax highlighting
```toml
[markup.highlight]
  style = "monokai"     # Chroma style name
  lineNos = true
  guessSyntax = true
```
Hugo uses the built-in **Chroma** highlighter — no JS needed. Fenced code blocks with a language tag are highlighted at build time.

### How to build a multilingual site
```toml
defaultContentLanguage = "en"
[languages.en]
  contentDir = "content/en"
[languages.fr]
  contentDir = "content/fr"
```
```go-html-template
{{ i18n "greeting" }}    {{/* pulls from i18n/en.toml, i18n/fr.toml */}}
{{ range .Translations }}<a href="{{ .RelPermalink }}">{{ .Language.Lang }}</a>{{ end }}
```

## Do's and Don'ts

### ✅ Do
- Install the **extended edition** if you use SCSS/SASS (`css.Sass` needs it).
- Use **`_index.md`** to give sections a landing page and front-matter-driven content.
- Order content with **`weight`** and menus with `[[menu.main]]` weights.
- Keep unprocessed files in **`static/`**, processed assets in **`assets/`** (Hugo Pipes).
- Use **`{{% %}}`** shortcodes when the inner content is Markdown, **`{{< >}}`** for raw HTML.

### ❌ Don't
- Don't expect drafts to publish — `draft: true` pages are excluded unless you pass `-D`/`--buildDrafts`.
- Don't put future-dated posts live — Hugo skips `date` in the future without `--buildFuture`.
- Don't confuse `static/` (copied verbatim) with `assets/` (pipeline-processed) — SCSS in `static/` won't compile.
- Don't fight Go templates with string hacks — use built-in functions (`where`, `first`, `sort`, `partial`).
- Don't hardcode `baseURL` paths in templates — use `.RelPermalink`/`absURL` so subpath deploys work.

## Styling, Theming & Templates
- **Themes**: install as a Hugo Module (`hugo mod get`) or git submodule; override any theme template by placing a same-named file in your `layouts/`.
- **Hugo Pipes**: `resources.Get` → `css.Sass`/`js.Build`/`resources.PostCSS` → `Minify`/`Fingerprint`.
- **Template lookup order**: Hugo picks the most specific layout (type/section/kind) — override selectively.
- **Params**: expose theme colors/fonts as `[params]` in `hugo.toml`, read via `.Site.Params.x`.
- **Base template**: `baseof.html` defines blocks; page templates fill them with `{{ define "main" }}`.

## Advanced Features
- **Hugo Modules**: Go-module-based dependency system for themes and shared components.
- **Render hooks**: override how Markdown links/images/headings render (`layouts/_default/_markup/`).
- **Image processing**: `.Resize`, `.Fill`, `.Fit`, WebP/AVIF conversion in templates.
- **Data-driven pages**: read `data/*.yaml` and generate content programmatically.
- **Output formats**: emit HTML + JSON + RSS + AMP from one page (`[outputs]`).
- **`GetJSON`/`GetCSV`**: fetch remote data at build time.

## Common Pitfalls & Troubleshooting
- **`css.Sass` errors** → you have the standard binary, not `hugo-extended`.
- **Page missing from build** → `draft: true`, future `date`, or `_build.render: never`.
- **Theme override ignored** → your `layouts/` path doesn't match the lookup order; mirror the theme's path exactly.
- **Broken links on subpath deploy** → use `relURL`/`.RelPermalink`, set correct `baseURL`.
- **Shortcode outputs raw text** → used `{{% %}}` vs `{{< >}}` incorrectly for the content type.
- **Slow first build after clone** → fetching theme modules; run `hugo mod get -u`.

## Integration Notes
- **Deployment**: `public/` is static — host on Netlify, Cloudflare Pages, GitHub Pages, S3/CDN.
- **CI**: single binary makes CI trivial; pin the Hugo version.
- **Content**: authored in Markdown (`goldmark` renderer) — see markdown.md.
- **Docs themes**: Docsy, Doks, Book, Hugo Learn for documentation sites.

## Best For / Avoid For
`static-sites`, `blogs`, `documentation`, `marketing-sites`, `multilingual`, `large-content` — choose Hugo for fast builds, no runtime dependency, and heavy content volumes.
Avoid for: sites needing server-side rendering or dynamic data at request time, teams unfamiliar with Go templates who prefer Liquid (jekyll.md) or Python (mkdocs.md), or code-execution docs (quarto.md, r-markdown.md).

## See Also
- `jekyll.md` — Ruby/Liquid static-site alternative
- `mkdocs.md` — Python, docs-focused, simpler
- `markdown.md` — Hugo's content authoring format
- `quarto.md` — when you need executable code in a site
- `../use-case/document-processing.md`, `../use-case/prototyping.md`
