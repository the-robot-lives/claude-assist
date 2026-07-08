# Jekyll

## What
Jekyll is a Ruby-based static site generator with built-in support for GitHub Pages. It transforms plain text into static websites and blogs using Markdown, Liquid templates, and YAML front matter, with native blog awareness (posts, categories, tags).

## How
- The LLM emits Markdown/HTML content with YAML front matter, Liquid templates (`_layouts`, `_includes`), and `_config.yml`.
- Built with the `jekyll` CLI: `gem install bundler jekyll`, `jekyll new my-site`, then `bundle exec jekyll serve` to build and serve locally; Sass/SCSS preprocessing is built in.
- Final artifact: a static HTML site, deployable directly to GitHub Pages without CI/CD.

## Why
- Reach for Jekyll when you want zero-config GitHub Pages hosting, a rich plugin ecosystem (jekyll-seo-tag, jekyll-feed), and built-in blog structure — good for project pages, technical blogs, and portfolios.
- Tradeoffs: Ruby dependency can complicate deployment, build times slow on large sites (1000+ pages), GitHub Pages restricts you to safe plugins, and Liquid has a learning curve.
- Versus Hugo: Jekyll trades raw build speed for Ruby-ecosystem plugin maturity and first-class GitHub Pages integration.

## Source
- Solution reference: `fim/solution/jekyll.md`
