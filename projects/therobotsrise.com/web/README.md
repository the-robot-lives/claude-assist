# styleguide-starter

Minimal Next.js app with YAML-driven CSS generation. Copy to your project and customize.

Components and CSS generation come from `@the-robot-lives/styleguide` (published to GitHub Packages).

## Quick Start

```bash
npm install
npm run regen    # Generate CSS from all theme-* configs
npm run dev      # Start dev server
```

## Setup

Requires a `.npmrc` with GitHub Packages auth (included in this template):
```
@the-robot-lives:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=${GITHUB_TOKEN}
```

Set `GITHUB_TOKEN` env var to a PAT with `read:packages` scope.

## Customizing

1. Add a `src/config/theme-{name}/` directory with your design tokens
2. Edit `src/app/page.tsx` — your pages
3. Run `npm run regen` to rebuild CSS
4. Visit `/styleguide` for the interactive style guide viewer

## Components

```tsx
import { StyleGuideBtn, StyleGuideCard } from "@the-robot-lives/styleguide/components";
import { ThemeConfigProvider, ButtonShowcase } from "@the-robot-lives/styleguide/viewer";
import type { StyleGuideConfig } from "@the-robot-lives/styleguide/types";
```

## Themes

Drop `theme-*` directories in `src/config/`. Each needs at minimum:
- `style-guide.meta.yaml` — name, slug, base-theme
- `style-guide.vars.yaml` — design token seeds
- `branding.yaml` — brand identity

`theme-style-guide` is the base theme (provides defaults). Your themes inherit from it.

## Copying to a Portfolio Project

```bash
cp -r styleguide-starter portfolio-projects/{name}/web
cd portfolio-projects/{name}/web
npm install && npm run regen && npm run dev
```
