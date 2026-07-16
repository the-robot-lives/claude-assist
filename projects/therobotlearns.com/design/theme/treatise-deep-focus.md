---
slug: deep-focus
base_theme: theme-style-guide
status: sketch
revision: 1
---

# Theme Treatise — Deep Focus

Theme: `theme-deep-focus/` · Base: `theme-style-guide` · Status: sketch

> **Reverse-engineered** from the shipped `theme-deep-focus/` YAML (Stage A). This treatise
> explains and justifies the values already on disk; where a value looks arbitrary it is
> flagged, not rationalized. **Surface note:** the product is a terminal agent, so Stage C
> renders this theme onto a mocked terminal window — its dark navy canvas and teal accent
> map naturally to a calm dark terminal.

## 1. Identity

- **Intent:** A distraction-free dark environment that makes deep study sessions feel
  effortless — dark as the canvas the work sits *in*, not an inverted light mode.
- **Perception:** "Focused, immersive, calm — a quiet study room at 2 AM where everything
  clicks." Depth and stillness, never gloom or neon energy.
- **Audience:** Night owls and deep workers who do their best thinking in dark mode and run
  long, uninterrupted sessions.
- **Tone:** Understated, focused, zen — minimal words, maximum signal (from `branding.yaml`
  verbatim intent).
- **Keywords:** immersive, focused, nocturnal, calm, depth
- **Relationship to base:** inherits `theme-style-guide` structure; the delta is a dark-
  primary navy palette with a single teal accent and a soft-technical 6px radius. Its close
  sibling in this project is `scholar` (both neutral, sans-only, developer-facing); Deep
  Focus splits off by being **dark-native and teal**, where scholar is light-native and
  indigo.

## 2. References & Anchors

- **Anchor — dark-native editor themes (Tokyo Night / Nord's darker end):** borrow the
  layered-navy elevation (canvas → surface → raised by lightness, not lines) evident in the
  `#0a0e1a → #0f1629` surface steps.
- **Anchor — a calm reading app in dark mode (iA Writer night):** borrow the low-ornament,
  content-first restraint — one accent, generous line-height, nothing competing with the text.
- **Anchor — teal instrument accents:** the `#14b8a6` teal reads as a single calm signal
  light, borrowed as the one saturated element.
- **Anti-reference — pitch-black OLED (#000) themes:** the canvas is navy `#0a0e1a`, not pure
  black; a true-black void would kill the sense of a *room* and flatten the elevation steps.
- **Anti-reference — cyberpunk neon dark:** teal here is calm and desaturated toward slate,
  not an electric glow; no more than one saturated hue on screen at once.
- **Anti-reference — low-contrast gray-on-gray "dark" themes:** body text is a bright slate
  `#cbd5e1`, not a fatiguing mid-gray; calm does not mean dim.

## 3. Color Story

- **Temperature & register:** Cool and dark-primary. Neutrals are blue-slate (the `#e2e8f0`/
  `#0a0e1a` seeds sit ≈215–222°); saturation is spent almost entirely on the single teal.
- **Hue relationships:** Slate monochrome + one teal accent `#14b8a6` (≈173°). The `blue`
  seed `#38bdf8` doubles as semantic info rather than a second brand hue, keeping the accent
  count at one.
- **Neutral strategy:** Cool slate, not pure gray — every surface and text step carries a
  blue tint. Canvas `#0a0e1a` (navy-black), surface-alt `#0f1629`, borders `#1e293b`/
  `#334155`. Pure gray never appears.
- **Semantic mapping:** Harmonize, cool-leaning. Success is mint `#34d399`, info sky
  `#38bdf8`, error a *soft rose* `#fb7185` (deliberately softened from a hard red so it warns
  without alarm — consistent with the calm tone), and warning amber `#fbbf24` is the single
  permitted warm break. Collision rule: rose error and teal accent are far apart in hue, so
  no confusion; the amber warning is the only warmth and must stay reserved for warnings.
- **Contrast stance:** Crisp for content, soft for chrome. Body `#cbd5e1` on `#0a0e1a` ≈ 13:1;
  borders may sit near 1.5:1 because structure comes from surface tone-layering, not lines.
- **Mode strategy:** **Dark is primary and the design target.** A light mode exists as a
  faithful translation (canvas `#f1f5f9`, text `#0f172a`, teal darkened to `#0d9488` so it
  clears AA on the pale surface) but receives no independent design decisions. No high-
  contrast mode in v1 — the dark palette already passes AA with margin.

## 4. Typographic Voice

- **Families:** UI sans is IBM Plex Sans (humanist-but-neutral, calm, high legibility at
  small sizes); code/data mono is IBM Plex Mono (a matched family, so switching to a literal
  value is quiet). Rationale: the single Plex superfamily keeps the type unobtrusive — the
  personality is in the darkness and the teal, not the letterforms. No serif, no display face.
- **Scale character:** Tight, ≈1.2 ratio — a study tool, not a marketing page. Headings
  separate by weight and space more than size.
- **Weight usage:** 400 body, 500 emphasized labels, 600 headings and the active nav item.
  Never bold whole paragraphs.
- **Rhythm:** Body line-height ≈1.6 for long reading; mono ≈1.5. Measure capped ≈70ch in
  article/reading panes. Mono appears for code, IDs, and literal values — never headings.

## 5. Space & Density

- **Spacing philosophy:** 8px base unit (inherited). Generosity leans airy for a reading tool
  — comfortable padding inside surfaces, room to breathe between blocks; calm over compact.
- **Density target:** Reference screen is the knowledge-article viewer (`02`): a single column
  of long-form text plus a slim nav rail, comfortable on a standard terminal without feeling
  crowded. Looser than cockpit, denser than a landing page.
- **Responsive stance:** Under width pressure the nav rail collapses first; the reading measure
  and body font size are protected — never compress legibility to fit more chrome.

## 6. Shape & Surface

- **Radius language:** 6px base — soft-technical, the second-softest of this project's themes
  (only spark is rounder). Applies to cards, inputs, buttons; no pills.
- **Borders:** Sparse. Surfaces separate primarily by tone (each elevation step a slightly
  lighter navy); 1px borders `#1e293b` mark only interactive or explicitly divided regions.
- **Elevation:** Tonal, three steps (canvas `#0a0e1a` → surface `#0f1629` → raised, by
  lightness). Shadows exist only under overlays (`rgba(0,0,0,0.4)`), soft and large-radius,
  never crisp.
- **Texture & gradient policy:** None. No gradients, noise, or glow — calm is achieved by flat
  navy layering, and any gradient would read as energy the theme rejects.

## 7. Motion & Feedback

- **Animation character:** Calm and confirmatory — motion exists only to acknowledge a change,
  never to entertain.
- **Duration & easing:** Transitions 150–220ms ease-in-out; micro-feedback ~120ms; nothing
  exceeds 250ms. No spring or bounce easing.
- **Interaction states:** Hover lightens the surface one tonal step (no hue shift); active
  compresses subtly; focus is a 2px teal ring (`rgba(20,184,166,0.3)`, offset 2px); disabled
  drops to ~45% opacity. State changes pair tone with the teal ring — never the teal hue alone.

## 8. Component Inflections

- **Buttons:** Primary is the only saturated-fill element on a screen — teal fill, navy text.
  Secondary is a ghost: 1px slate border, slate text, transparent fill.
- **Inputs:** Recessed one tonal step below their surface (darker), reading as cut into the
  navy; focus swaps the recessed border for the teal ring. Placeholder holds the 4.5:1 floor.
- **Cards:** One tonal step up from canvas, 6px radius, generous padding, borderless unless
  interactive — the calm reading surface.
- **Navigation:** Rail on canvas (step 0), content on surface (step 1); active item is 600
  weight + a 2px teal left rail, no filled background.
- **At base defaults (deliberately untouched):** tables, toasts, breadcrumbs, and modal
  structure inherit `theme-style-guide`, recolored through the navy+teal tokens.

## 9. Accessibility Commitments

- **WCAG target:** 2.2 AA across both modes; body text targets AAA (7:1) in dark mode, since
  long-session legibility is the product promise.
- **Contrast minimums:** Body `#cbd5e1` on `#0a0e1a` ≈ 13:1 (pass with margin). Near-the-line
  pairs to verify: **text-secondary `#64748b` on canvas ≈ 4.3:1 — right at the AA edge; keep
  it for large/secondary text, and treat text-muted `#475569` (≈3:1) as decorative/disabled
  only, never body.** Teal `#14b8a6` as text on navy ≈ 5:1 (safe for large/UI, verify if used
  body-size).
- **Focus visibility:** 2px teal ring, 2px offset, on every focusable element; exceeds 3:1
  against all three navy surface steps. Never removed, only restyled.
- **Reduced motion:** `prefers-reduced-motion` drops all transitions over 100ms to instant
  state swaps; hover tone changes survive as immediate swaps.

## 10. Facet Mapping Appendix

| Treatise section | Engine facet | Seed hints |
|---|---|---|
| §1 | `branding.yaml` | name "The Robot Learns" (Deep Focus); intent/perception/audience/tone verbatim; keywords: immersive, focused, nocturnal, calm, depth |
| §3 neutrals | `style-guide.vars.yaml` Surfaces | white `#e2e8f0`, black `#0a0e1a` (slate seeds → cool ramp) |
| §3 accent | `style-guide.vars.yaml` Brand | single teal `#14b8a6`; `blue #38bdf8` serves info, not a 2nd brand hue |
| §3 semantics | `style-guide.vars.yaml` Semantic | success `#34d399`, warning `#fbbf24`, error `#fb7185` (soft rose), info `#38bdf8` |
| §3 modes | `style-guide.color-modes.yaml` | dark primary (canvas `#0a0e1a`, text `#cbd5e1`); light: canvas `#f1f5f9`, text `#0f172a`, teal `#0d9488` |
| §4 | `style-guide.vars.yaml` Typography | font-sans `'IBM Plex Sans', -apple-system, sans-serif`; font-mono `'IBM Plex Mono', 'Menlo', monospace`; ~1.2 scale |
| §5 | `style-guide.vars.yaml` Layout | 8px unit (inherit); airy reading padding; ~70ch measure |
| §6 | `style-guide.vars.yaml` radius | radius `6px`; tonal 3-step elevation; overlay shadow only |
| §7 | `style-guide.scoped-vars.yaml` | `--motion: 180ms` ease-in-out; reduced-motion guard |
| §8 | `style-guide.semantic-classes.yaml` | teal primary fill, recessed inputs, borderless cards, teal-rail active nav |
| §9 | verification across facets | recheck `#64748b`/`#475569` steps and teal-as-text on any canvas change |
