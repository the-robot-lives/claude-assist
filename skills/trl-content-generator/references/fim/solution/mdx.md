# MDX - FIM Solution Documentation

## Description
[MDX](https://mdxjs.com) is an authorable format that lets you write JSX (React/Preact/Vue components) directly inside Markdown. It is the de facto standard for modern developer blogs and documentation sites built with Next.js, Astro, Docusaurus, and Gatsby, enabling interactive, component-driven articles that still read as plain Markdown.

## Basic Syntax
```mdx
---
title: Building a Rate Limiter
date: 2026-06-14
tags: [systems, node]
---

import { Callout } from '@/components/Callout'
import Chart from '@/components/Chart'

# Building a Rate Limiter

Standard Markdown still works: **bold**, `code`, [links](https://example.com).

<Callout type="warning">
  Token buckets drift under clock skew — pin to a monotonic source.
</Callout>

Here is a live chart rendered from frontmatter data:

<Chart data={[1, 4, 9, 16]} />
```

## Toolchain
- **@mdx-js/mdx** - Core compiler (MDX -> JS module)
- **@next/mdx** / **next-mdx-remote** - Next.js integration (build-time or runtime)
- **Astro** - First-class `.mdx` pages via `@astrojs/mdx`
- **Docusaurus** - Docs sites with MDX as the default content format
- **remark / rehype plugins** - `remark-gfm`, `rehype-pretty-code`, `remark-frontmatter` for tables, syntax highlighting, and metadata

## Strengths
- Embed interactive components (charts, tabs, live code) inline in prose
- Reuses the entire React/Vue component ecosystem
- Build-time compilation = fast, statically rendered output
- Frontmatter-driven metadata for SEO and listings
- Git-friendly plain-text source

## Limitations
- Requires a JS build pipeline (not portable to plain Markdown renderers)
- Components must exist in scope; broken imports fail the build
- Heavier authoring model than CommonMark for non-interactive posts
- Runtime MDX (`next-mdx-remote`) has a security/perf cost vs build-time

## Best Use Cases
- Interactive technical blog posts (Dev.to-style content upgraded for an owned site)
- Product/API documentation with embedded live demos
- Design-system docs where examples render the actual components
- Newsletter web archives that need richer-than-Markdown layout

## NPL-FIM Integration
```npl
⌜mdx-author|mdx|FIM@1.0⌝
format: mdx
runtime: next.js | astro | docusaurus
plugins: [remark-gfm, rehype-pretty-code, remark-frontmatter]
components: [Callout, Chart, CodeTabs]
output: react-module | static-html
⌞mdx-author⌟
```

NPL agents emit MDX when an article needs interactive components, mapping abstract "media blocks" to imported React components while keeping prose in portable Markdown.
