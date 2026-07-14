# OG / Social Card Images - FIM Solution Documentation

## Description
Open Graph and Twitter/X card images are the preview thumbnails shown when a link is shared. Generating them programmatically — from article title, author, and tags — dramatically improves click-through in the discovery funnel. The modern stack renders JSX/HTML to PNG with [Satori](https://github.com/vercel/satori) + resvg (`@vercel/og`), and code-screenshot tools (Carbon/Silicon) turn snippets into shareable images.

## Basic Syntax
```jsx
// @vercel/og (Satori under the hood) - edge/runtime PNG from JSX
import { ImageResponse } from '@vercel/og'

export default function handler(req) {
  const title = new URL(req.url).searchParams.get('title')
  return new ImageResponse(
    (
      <div style={{ display: 'flex', flexDirection: 'column', width: '100%',
        height: '100%', padding: 64, background: '#0b0b0b', color: '#fff' }}>
        <div style={{ fontSize: 64, fontWeight: 700 }}>{title}</div>
        <div style={{ marginTop: 'auto', fontSize: 28 }}>noizu.com</div>
      </div>
    ),
    { width: 1200, height: 630 }
  )
}
```
```bash
# Code snippet -> image (no browser) with Silicon
silicon rate_limiter.rs -o card.png --theme "Dracula" --background "#0b0b0b"
```

## Toolchain
- **@vercel/og / Satori** - JSX/HTML+CSS -> SVG -> PNG (no headless browser)
- **resvg-js** - Rasterize the SVG that Satori produces
- **Silicon** (Rust) / **Carbon** (web) - Code snippet -> styled image
- **Playwright/Puppeteer** - Screenshot an HTML template as a fallback
- **sharp** - Post-process/resize generated PNGs (see `sharp.md`)

## Strengths
- Automated, on-brand previews for every article at scale
- Satori path needs no headless browser (fast, edge-deployable)
- Templated from metadata (title, author, tag, reading time)
- Code-to-image tools produce share-ready snippets for social
- Boosts CTR on Dev.to/Twitter/LinkedIn shares

## Limitations
- Satori supports a CSS subset (flexbox, limited features)
- Font loading/embedding must be handled explicitly
- Browser-screenshot fallback is slower and heavier
- 1200x630 is convention; some platforms crop differently

## Best Use Cases
- Auto-generated OG/Twitter cards per published article
- Code-snippet images for X/LinkedIn promotion
- Branded thumbnails for newsletter and series headers
- Dynamic cards driven by query params (title, tag)

## NPL-FIM Integration
```npl
⌜og-image|og|FIM@1.0⌝
format: png (1200x630)
render: satori+resvg | playwright-screenshot
code_cards: silicon | carbon
post: sharp
output: social-preview-image
⌞og-image⌟
```

NPL agents generate OG/social images (Satori for layout cards, Silicon/Carbon for code) to maximize share CTR in the discovery stage of the funnel.
