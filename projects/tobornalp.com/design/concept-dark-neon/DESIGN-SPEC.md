# tobornalp — dark-neon console design spec

Source of truth: `tobornalp-ui-concept.html` (interactive, 6 screens: today, board,
item detail, okrs, agents, wiki). This doc extracts the tokens and recipes for
implementation. Direction: theme-terminal dominant + rounded/neon treatment.
**Dark-only** — the app commits to this visual world; no light mode.

## Tokens (CSS custom properties)

```css
--bg:#000000;            /* page ground — true black */
--panel:#0D0D10;         /* panel surface */
--panel2:#16161B;        /* elevated card / header strip */
--line:#1F1F26;          /* default border */
--line2:#31313B;         /* stronger border / input border */
--ink:#EDEDF2;           /* primary text */
--mut:#9C9CA8;           /* secondary text */
--faint:#64646F;         /* tertiary / keys / timestamps */
--acc:#3EF2A6;           /* neon mint — THE accent (buttons, active nav, agents, progress, [OK]) */
--acc-hi:#93FAD2;        /* accent hover */
--acc-bg:rgba(62,242,166,.10);
--acc-line:rgba(62,242,166,.45);
--warn:#FFC24D;  --warn-bg:rgba(255,194,77,.12);   /* [WARN], stale, wip-over-limit */
--err:#FF6E61;   --err-bg:rgba(255,110,97,.13);    /* [ERR], bugs, overdue, blocks */
--info:#53D6FF;  --info-bg:rgba(83,214,255,.12);   /* stories, humans-in-feeds, [INFO] */
--vio:#C792FF;   --vio-bg:rgba(199,146,255,.13);   /* epics / special */
--sel:rgba(62,242,166,.06);                        /* hover/selected row wash */
--r:14px; --r-sm:10px; --r-pill:999px;             /* radius scale */
--card-shadow:0 2px 10px rgba(0,0,0,.35);
```

Fonts: mono is the UI voice — `ui-monospace,"SF Mono","Cascadia Code","JetBrains Mono",Menlo,Consolas,monospace`
for nav, labels, keys, data, headers, logs. System sans only for long prose
(descriptions, wiki body). Base UI size 13px, meta 11–12px, tabular-nums on digits.

## Component recipes (match the mockup exactly)

- **panel**: `bg --panel; border 1px --line; radius --r; overflow hidden; --card-shadow`.
  Header row: 10px/16px padding, bottom 1px --line, title = 12px uppercase mono
  letterspaced bold; optional `.sub` faint + right-aligned meta.
- **card** (board): `bg --panel2; border 1px --line; radius --r-sm`; selected =
  accent border + mint glow `0 0 0 1px acc, 0 4px 18px rgba(62,242,166,.14)`.
- **chip**: pill, 10px text, 1px border. Variants: bug=err, story=info, epic=vio,
  agent=mint **dashed** border, scope=panel2 bg, default=mut/line2.
- **btn**: pill; default panel2/line2; primary = solid mint w/ **#000 text**.
- **avatar**: humans = 22px circle w/ initials; agents = 22px **8px-radius squircle,
  dashed mint border, ▣ glyph**. Never blur the human/agent distinction.
- **statusline**: full-width strip under topbar; terse mono segments prefixed
  `[OK]`(mint) `[WARN]`(amber) `[ERR]`(coral) `[INFO]`(cyan).
- **rail** (sidebar 212px): org selector card top; nav links rounded-8, active =
  mint text on --acc-bg; section labels 10px uppercase faint; badge = mint pill.
- **progress bar**: 7px pill track panel2/line, mint fill (amber when behind).
- **priority dot**: 8px circle — err(hi, subtle glow)/warn(md)/line2(lo).
- **pipeline stepper**: capsule (pill, overflow hidden), segments uppercase 11px;
  done=panel2/mut, current=solid mint/#000, future=faint.
- **log lines** (history/audit): mono 11.5px rows, faint timestamp, mint actor tag
  (cyan for humans), hover --sel.
- **tables**: header cells on --panel2 strip, 10px uppercase faint letterspaced;
  row hover --sel; 1px --line row borders.

## Voice

Terse, lowercase microcopy ("edit plan", "view all →", "awaiting pickup").
Item keys `TRP-NNN` mono faint. Status language via `[OK]/[WARN]/[ERR]/[INFO]`.

## Wiki specifics (see ADR-002)

Markdown-native: frontmatter renders as dashed-border mono block; headings keep faint
`#`/`##` marks; `[[wikilinks]]` mint w/ dashed underline (cyan for item targets);
inline db = bordered block w/ header strip + view pill-tabs; code fences on --bg.
