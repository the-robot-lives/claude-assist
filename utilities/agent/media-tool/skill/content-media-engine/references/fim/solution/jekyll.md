# Jekyll — Ruby static site generator with Liquid templating

Jekyll is a Ruby-based static site generator that transforms Markdown + Liquid templates + YAML front matter into static HTML. Created by GitHub's co-founder, it powers **GitHub Pages** natively (no CI needed), making it the default for project sites, blogs, and portfolios. Its blog-awareness (posts, categories, tags), collections, and includes make it a mature, well-documented choice.

**Current Version**: Jekyll 4.x (current major)  **License**: MIT  **Runtime**: Ruby + Bundler; templating via **Liquid**

## Official Resources & Documentation
- **Website**: https://jekyllrb.com/
- **Docs**: https://jekyllrb.com/docs/
- **Liquid reference**: https://shopify.github.io/liquid/
- **Front matter**: https://jekyllrb.com/docs/front-matter/
- **GitHub Pages + Jekyll**: https://docs.github.com/en/pages
- **Themes**: https://jekyllrb.com/docs/themes/
- **GitHub**: https://github.com/jekyll/jekyll

## Installation & Setup
```bash
gem install bundler jekyll
jekyll new my-site
cd my-site
bundle install
bundle exec jekyll serve            # dev server at http://127.0.0.1:4000
bundle exec jekyll build            # output to _site/
bundle exec jekyll serve --drafts   # include _drafts/
```
`Gemfile` pins Jekyll and plugins; always run through `bundle exec` for reproducible builds.

## Project Structure
```
my-site/
├── _config.yml       # site configuration
├── Gemfile           # Ruby dependencies
├── _posts/           # blog posts: YYYY-MM-DD-title.md
├── _drafts/          # unpublished drafts (no date)
├── _layouts/         # page templates (default.html, post.html)
├── _includes/        # reusable partials (header.html, footer.html)
├── _data/            # data files (YAML/JSON/CSV) -> site.data
├── _sass/            # Sass partials
├── assets/           # CSS, JS, images
├── _collections/     # custom collections (e.g. _docs/)
├── index.md          # homepage
└── about.md
```

## Core Concepts & Syntax

### Front matter (required to trigger processing)
```yaml
---
layout: post
title: "Welcome"
date: 2024-06-01 10:00:00 -0700
categories: [jekyll, tutorial]
tags: [static-site, ruby]
author: Me
permalink: /welcome/
---
```
A file **must have front matter** (even empty `---\n---`) for Liquid/Markdown processing; otherwise it's copied verbatim. `_posts` filenames must be `YYYY-MM-DD-slug.md`.

### Configuration (_config.yml)
```yaml
title: My Site
description: A Jekyll site
baseurl: ""                 # subpath, e.g. "/blog"
url: "https://example.com"
markdown: kramdown
permalink: /:categories/:year/:month/:title/

collections:
  docs:
    output: true
    permalink: /docs/:path/

defaults:
  - scope: {path: "", type: posts}
    values: {layout: post}

plugins:
  - jekyll-seo-tag
  - jekyll-feed
  - jekyll-sitemap
```
Note: changes to `_config.yml` require a **server restart** (not hot-reloaded).

### Liquid templating
```liquid
{% raw %}<h1>{{ page.title }}</h1>
<ul>
{% for post in site.posts limit:5 %}
  <li>
    <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
    <time>{{ post.date | date: "%b %-d, %Y" }}</time>
  </li>
{% endfor %}
</ul>

{% if page.author %}<p>By {{ page.author }}</p>{% endif %}{% endraw %}
```
Liquid has **objects** (`{{ }}`), **tags** (`{% %}`), and **filters** (`| filter`). Key globals: `site`, `page`, `content`, `paginator`. Common filters: `relative_url`, `date`, `where`, `sort`, `markdownify`, `slugify`, `jsonify`.

### Layouts & includes
```liquid
{% raw %}<!-- _layouts/default.html -->
<!doctype html><html><head>{% include head.html %}</head>
<body>{{ content }}{% include footer.html %}</body></html>

<!-- _layouts/post.html -->
---
layout: default
---
<article><h1>{{ page.title }}</h1>{{ content }}</article>

<!-- use an include with parameters -->
{% include figure.html src="/img/a.png" caption="Diagram" %}{% endraw %}
```
Layouts nest via their own front matter (`layout:`); `{{ content }}` injects the child. Includes live in `_includes/` and accept parameters accessible as `include.param`.

### Collections
```liquid
{% raw %}{% for doc in site.docs %}
  <a href="{{ doc.url | relative_url }}">{{ doc.title }}</a>
{% endfor %}{% endraw %}
```
Collections (declared in `_config.yml`) group related documents (docs, team members, products) beyond the built-in `posts`.

### Data files
```liquid
{% raw %}{% for member in site.data.team %}
  <li>{{ member.name }} — {{ member.role }}</li>
{% endfor %}{% endraw %}
```
`_data/team.yml` becomes `site.data.team` — a clean way to drive content from structured data.

## How-To (worked recipes)

### How to theme & add colors (Sass pipeline)
Jekyll has a built-in Sass/SCSS processor; put partials in `_sass/` and a main file in `assets/`:
```scss
// _sass/_variables.scss
$brand: #1e6fba;
$bg: #ffffff;
```
```scss
---
# assets/css/main.scss  (front matter required so Jekyll processes it)
---
@import "variables";
body { background: $bg; color: #222; }
a { color: $brand; }
.callout { border-left: 4px solid $brand; background: lighten($brand, 55%); }
```
The empty `--- ---` front matter at the top of `main.scss` is **required** — it tells Jekyll to run the file through the Sass converter. Expose theme colors as Sass variables (or `_config.yml` params) for easy retheming.

### How to add a custom include with parameters
```liquid
{% raw %}<!-- _includes/callout.html -->
<div class="callout callout-{{ include.type }}">
  {{ include.body | markdownify }}
</div>

<!-- usage in a page -->
{% include callout.html type="warning" body="Watch out for this." %}{% endraw %}
```

### How to enable syntax highlighting
```yaml
# _config.yml
markdown: kramdown
highlighter: rouge
kramdown:
  syntax_highlighter: rouge
```
Fenced code blocks are highlighted at build time by **Rouge**; pair with a Rouge CSS theme (`rougify style github > assets/css/syntax.css`).

### How to paginate the blog
```yaml
# _config.yml
plugins: [jekyll-paginate]
paginate: 10
paginate_path: "/page:num/"
```
```liquid
{% raw %}{% for post in paginator.posts %}{{ post.title }}{% endfor %}
{% if paginator.next_page %}<a href="{{ paginator.next_page_path }}">Next</a>{% endif %}{% endraw %}
```

## Do's and Don'ts

### ✅ Do
- Always run via **`bundle exec`** so the pinned Jekyll/plugin versions are used.
- Give every processed file **front matter** (even empty) — no front matter means no Liquid.
- Name posts **`YYYY-MM-DD-title.md`** exactly, or they won't appear in `site.posts`.
- Use **`relative_url`/`absolute_url`** filters so `baseurl` subpath deploys work.
- Restart the server after **`_config.yml`** changes.

### ❌ Don't
- Don't use **unsupported plugins on GitHub Pages** — GH Pages runs a safe-mode allowlist; use GitHub Actions to build if you need arbitrary plugins.
- Don't expect drafts/future posts to publish without `--drafts`/`--future`.
- Don't forget the **empty front matter on `.scss`** files — without it Sass isn't processed.
- Don't hardcode absolute paths in templates — respect `baseurl`.
- Don't put logic-heavy code in Liquid; precompute in `_data/` or a plugin instead.

## Styling, Theming & Templates
- **Sass**: `_sass/` partials + a front-matter'd main `.scss` in `assets/`; `sass:` config sets `style: compressed`.
- **Themes**: gem-based themes (`minima`, `minimal-mistakes`) installed via Gemfile; override any theme file by placing a same-named file in your project (theme layering).
- **Liquid layouts/includes**: the templating substrate for all HTML.
- **Front-matter defaults** (`defaults:` in config): apply layouts/values by path or type without repeating them.

## Advanced Features
- **Plugins** (local `_plugins/` or gems): generators, converters, tags, filters — extend the build.
- **`jekyll-seo-tag`, `jekyll-feed`, `jekyll-sitemap`, `jekyll-archives`**: near-standard SEO/blog plugins.
- **Hooks**: Ruby callbacks at build lifecycle points.
- **Incremental build** (`--incremental`): faster rebuilds for large sites (experimental).
- **Custom generators**: programmatically create pages from data.
- **Liquid `where`/`group_by`/`sort`**: query collections in templates.

## Common Pitfalls & Troubleshooting
- **File output verbatim (not processed)** → missing front matter.
- **Post not showing** → wrong filename format, `published: false`, or future date.
- **Plugin ignored on GitHub Pages** → not on the allowlist; switch to a GitHub Actions build.
- **Sass not compiling** → main `.scss` lacks the empty front-matter block, or partials belong in `_sass/`.
- **Config change no effect** → server not restarted.
- **Slow builds (1000+ pages)** → try `--incremental`, reduce plugins, or migrate to Hugo (see hugo.md).

## Integration Notes
- **GitHub Pages**: push and it builds automatically (with the safe plugin set); or build with Actions for full control.
- **Content**: Markdown via `kramdown` (see markdown.md); front matter is YAML.
- **Netlify/Cloudflare Pages**: run `jekyll build` in CI and deploy `_site/`.

## Best For / Avoid For
`github-pages`, `blogs`, `portfolios`, `project-sites`, `documentation` — choose Jekyll for GitHub-Pages-native hosting, mature blog features, and Liquid familiarity.
Avoid for: very large sites where build speed matters (use hugo.md), Python-centric doc teams (mkdocs.md, sphinx.md), or sites needing executable code (quarto.md).

## See Also
- `hugo.md` — faster Go alternative
- `mkdocs.md` — Python documentation generator
- `markdown.md` — Jekyll's content format
- `../use-case/document-processing.md`, `../use-case/prototyping.md`
