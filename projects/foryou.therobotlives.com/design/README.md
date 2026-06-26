# foryou.TheRobotLives.com — Design Directions

Four candidate themes for the cross-site signup / contact-preference service, each
tuned to a **different demographic** that might embed the `foryou` widget. They are
not refinements of one idea — they are deliberately divergent so we can match the
host site's audience (a developer tool, a consumer newsletter, an enterprise portal,
a hype launch page) rather than force one look everywhere.

All four inherit the same base theme (`theme-style-guide`) and override only the
facets that differ (seeds, color modes, type, radius, a few component tokens).

---

## At a glance

| | **Builder** | **Bright** | **Trust** | **Signal** |
|---|---|---|---|---|
| **Slug** | `foryou-builder` | `foryou-bright` | `foryou-trust` | `foryou-signal` |
| **Demographic** | Developers, indie hackers, technical early adopters | Mainstream consumers, newsletter & waitlist subscribers | Enterprise / B2B decision-makers | Sci-fi early adopters, robot-brand core fans |
| **Style system** | Nocturne × Minimal Tech | Consumer Playful | Corporate Enterprise | Bold Expressive |
| **Hero mode** | Dark | Light | Light | Dark |
| **Primary accent** | Electric cyan `#22d3ee` | Coral pink `#ff5c8a` | Corporate blue `#1d4ed8` | Neon magenta `#ff1f8e` |
| **Secondary / tertiary** | Indigo / lime | Violet / amber | Teal / gold | Cyan / acid |
| **Display font** | Inter | Poppins | Source Serif 4 (serif) | Space Grotesk |
| **Mono font** | JetBrains Mono | DM Mono | IBM Plex Mono | Space Mono |
| **Radius** | 6px | 16px (pill-soft) | 4px | 0px (hard) |
| **Logo treatment** | lowercase, tight | rounded bold | serif | UPPERCASE, boxed |
| **Emotional read** | precise, calm, native | friendly, inviting, easy | credible, stable, secure | electric, loud, event |
| **Risk level** | Low | Low | Low | High (intentionally) |

---

## What each one is for

### Builder — dark-native, get-out-of-the-way
The widget a developer would ship without a second thought. Dark hero surface
(`#0d1117`), cyan accent, mono-forward, 6px radius. Reads as competent and fast.
Use on `codefre.sh`, API/changelog signups, and any technical host.

### Bright — warm, rounded, zero-intimidation
Coral-pink primary, big 16px radii, Poppins, soft warm surfaces. Subscribing feels
like a treat, not a commitment. Use for consumer newsletters, launch waitlists, and
lifestyle-leaning sites where first-time visitors need reassurance.

### Trust — blue, serif, institutional
Corporate blue with a Source Serif 4 display face and restrained 4px radius. Earns
confidence before the first keystroke. Use for B2B beta-access requests, demo
bookings, and organizational contact-preference management.

### Signal — neon on near-black, hard edges
Magenta + cyan + acid on `#0a0a0f`, zero radius, uppercase Space Grotesk. Turns the
signup into an event. Use on `foryou.therobotlives.com` itself and product drop pages
where the audience is already excited — high risk by design, highest energy.

---

## Choosing a direction

```
Who embeds the widget?
├─ A developer tool / technical product .................. Builder
├─ A consumer newsletter or lifestyle waitlist ........... Bright
├─ An enterprise / B2B portal (credibility matters most) . Trust
└─ A hype launch page for the robot-brand faithful ....... Signal

Still unsure?
├─ Default to Builder — it is the safest, most reusable shell
│  and aligns with the rest of the robot-brand dev tooling.
└─ Per-host overrides can swap the theme via data-design-theme.
```

Because `foryou` is a **multi-site** service, this is not strictly an either/or:
the theme can be selected per embedding host via the `data-design-theme` attribute.
Builder is the recommended default; the other three are opt-in per audience.

### Mixing
Each theme is a complete, standalone direction — there is no 80/20 blend intended
here. If a host wants a hybrid (e.g. Builder's restraint with Trust's blue), clone
the closest theme and override its accent seeds rather than merging two themes.

---

## Preview them together

```bash
# From the project root, point the launcher at the theme directory.
# The theme picker shows all four side by side; toggle light/dark per theme.
npx @noizu/styleguide serve ./design/theme/
```

The launcher auto-copies the canonical `theme-style-guide` base into `design/theme/`
on first run — leave it in place; the four custom themes inherit from it.

---

## What's not covered yet
- Logo / wordmark (currently a text logo-text per theme)
- Real product copy, hero imagery, and the signup-form layouts themselves
- Per-attribute-type field styling (date / select / multi-select / guid pickers)
- The cross-site preference-center shell (post-login)

## Next steps
1. Review the four in the launcher and pick the **default** (recommendation: Builder).
2. Promote the chosen theme into the scaffolded app at
   `app/frontend/src/config/theme-style-guide/` (edit in place) and set
   `data-design-theme` in `layout.tsx`.
3. Generate product-management artifacts (personas → stories → screens → components)
   to drive the signup and preference-center wireframes.

## Theme directory layout
```
design/theme/
  theme-style-guide/        # base (auto-copied by the launcher; do not hand-edit)
  theme-foryou-builder/     # Builder  — dark tech
  theme-foryou-bright/      # Bright   — playful
  theme-foryou-trust/       # Trust    — corporate
  theme-foryou-signal/      # Signal   — bold neon
```
Each custom theme contains: `style-guide.meta.yaml`, `style-guide.vars.yaml`,
`branding.yaml`, `style-guide.color-modes.yaml`.
