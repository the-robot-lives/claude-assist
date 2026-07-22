/**
 * One-shot: re-SSR broken Tailwind Plus demos into hologram static HTML.
 * Uses happy-dom + esbuild + react-dom/server.
 */
import * as esbuild from 'esbuild'
import { createRequire } from 'module'
import { writeFileSync, mkdirSync, existsSync } from 'fs'
import { dirname, join, basename } from 'path'
import { tmpdir } from 'os'
import { Window } from 'happy-dom'

const require = createRequire(import.meta.url)

const APP = '/home/keithbrings/Work/Space/Infra/Noizu/components/styleguide/app'
const OUT = join(APP, '../hologram/priv/static/twp/demos')
const SRC = join(APP, 'src/components/tailwind-plus')

// Browser environment for Headless UI
const window = new Window({ url: 'http://localhost/' })
const { document } = window
const g = {
  window,
  document,
  HTMLElement: window.HTMLElement,
  Element: window.Element,
  Node: window.Node,
  DocumentFragment: window.DocumentFragment,
  CustomEvent: window.CustomEvent,
  MutationObserver: window.MutationObserver,
  ResizeObserver: window.ResizeObserver || class { observe(){} disconnect(){} unobserve(){} },
  IntersectionObserver: window.IntersectionObserver || class { observe(){} disconnect(){} unobserve(){} },
  requestAnimationFrame: (cb) => setTimeout(() => cb(Date.now()), 0),
  cancelAnimationFrame: (id) => clearTimeout(id),
  getComputedStyle: (...a) => window.getComputedStyle(...a),
  matchMedia: (q) => window.matchMedia(q),
  location: window.location,
  self: window,
  top: window,
  parent: window,
  Window: window.constructor,
}
for (const [k, v] of Object.entries(g)) {
  try { globalThis[k] = v } catch { /* read-only */ }
}
try {
  Object.defineProperty(globalThis, 'navigator', { value: window.navigator, configurable: true })
} catch { /* ok */ }

const React = require('react')
const { renderToStaticMarkup } = require('react-dom/server')

const SHELL = (title, body) => `<!DOCTYPE html>
<html lang="en" class="h-full">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>${title}</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <script>
    tailwind.config = { darkMode: 'class', theme: { extend: {} } }
  </script>
  <style>
    html, body { margin: 0; min-height: 100%; }
    body { background: #fff; color: #111; }
    html.dark body { background: #0a0a0a; color: #f5f5f5; }
    .twp-root { padding: 1.5rem; min-height: 100%; box-sizing: border-box; min-height: 24rem; }
    /* Force Headless UI closed panels visible for design review */
    [data-closed], [data-headlessui-state~="closed"] {
      opacity: 1 !important;
      transform: none !important;
      display: block !important;
      visibility: visible !important;
      pointer-events: auto !important;
    }
    /* Keep dialogs in document flow inside the iframe */
    .twp-root .fixed { position: absolute !important; }
    .twp-root { position: relative; }
  </style>
  <script>
    (function(){
      try {
        var m = matchMedia('(prefers-color-scheme: dark)').matches;
        var c = parent !== window ? null : localStorage.getItem('color-mode');
        if (c === 'dark' || (!c && m)) document.documentElement.classList.add('dark');
      } catch (e) {}
    })();
  </script>
</head>
<body class="h-full">
  
  <div class="twp-root">
    ${body}
  </div>
</body>
</html>
`

const TARGETS = [
  'app-ui/navigation/command-palettes/Simple01',
  'app-ui/navigation/command-palettes/SimpleWithPadding02',
  'app-ui/navigation/command-palettes/WithPreview03',
  'app-ui/navigation/command-palettes/WithImagesAndDescriptions04',
  'app-ui/navigation/command-palettes/WithIcons05',
  'app-ui/navigation/command-palettes/SemiTransparentWithIcons06',
  'app-ui/navigation/command-palettes/WithGroups08',
  'app-ui/navigation/command-palettes/WithFooter09',
  'ecommerce/components/product-quickviews/WithColorSelectorSizeSelectorAndDetailsLink01',
  'ecommerce/components/product-quickviews/WithColorAndSizeSelector02',
  'ecommerce/components/product-quickviews/WithLargeSizeSelector03',
  'ecommerce/components/product-quickviews/WithColorSelectorAndDescription04',
  'marketing/page-examples/pricing-pages/WithComparisonTable02',
]

async function bundleAndLoad(relPath) {
  const entry = join(SRC, relPath + '.tsx')
  if (!existsSync(entry)) throw new Error('missing ' + entry)
  // Write under app so require('react') resolves from local node_modules
  const outfile = join(APP, '.tmp-ssr', relPath.replace(/\//g, '_') + '.cjs')
  mkdirSync(dirname(outfile), { recursive: true })
  await esbuild.build({
    entryPoints: [entry],
    bundle: true,
    platform: 'node',
    format: 'cjs',
    outfile,
    jsx: 'automatic',
    loader: { '.tsx': 'tsx', '.ts': 'ts', '.js': 'js', '.jsx': 'jsx' },
    define: { 'process.env.NODE_ENV': '"production"' },
    logLevel: 'error',
    // Share one React with renderToStaticMarkup (avoid dual React)
    external: ['react', 'react-dom', 'react/jsx-runtime', 'react/jsx-dev-runtime'],
  })
  delete require.cache[require.resolve(outfile)]
  return require(outfile)
}

function pickComponent(mod, exportName) {
  if (mod[exportName]) return mod[exportName]
  if (mod.default) return mod.default
  const showcase = Object.keys(mod).find((k) => k.endsWith('Showcase'))
  if (showcase) return mod[showcase]
  const keys = Object.keys(mod).filter((k) => typeof mod[k] === 'function')
  if (keys.length === 1) return mod[keys[0]]
  throw new Error('no component in exports: ' + keys.join(','))
}

let ok = 0
let fail = 0
for (const rel of TARGETS) {
  const exportName = basename(rel)
  try {
    const mod = await bundleAndLoad(rel)
    const Comp = pickComponent(mod, exportName)
    let markup = renderToStaticMarkup(React.createElement(Comp))
    markup = markup.replace(/<!-- -->/g, '')
    const textish = markup.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim()
    if (textish.length < 5 && !markup.includes('<img')) {
      console.log('WARN empty:', rel, 'markup', markup.length)
    }
    const outPath = join(OUT, rel + '.html')
    mkdirSync(dirname(outPath), { recursive: true })
    writeFileSync(outPath, SHELL(exportName, markup))
    console.log('OK', rel, markup.length, 'chars, text', textish.length)
    ok++
  } catch (e) {
    console.error('FAIL', rel, e.message)
    fail++
  }
}
console.log({ ok, fail })
await window.happyDOM.close()
