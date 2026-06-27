# The Robot Fakes It

**Text-first, theme-aware UI prototyping — from a sketch you can type to production web components a robot can drive.**

The Robot Fakes It (TRFI) is a web app **and** an MCP-managed prototyping engine. You describe screens in a compact, human- and agent-writable text DSL — closer to Balsamiq's "draw a box, label it" mental model than to hand-writing HTML — and TRFI renders them live. Flip a single switch and the same screen goes from a deliberately rough **low-fidelity** sketch to a fully themed **high-fidelity** mockup, with no rework in between. When the prototype is right, export it as framework-agnostic [Lit](https://lit.dev) web components that drop into Next.js, Vue, plain HTML, Elixir/Phoenix, or anywhere else custom elements run.

Because the whole surface is MCP-managed, an AI agent ("the robot") can author screens, mutate themes, wire interactions, and run the prototype on your behalf — faking a working product convincingly enough to test, demo, and validate before a single line of application code is written.

---

## Why it exists

Prototyping today forces a bad trade:

- **Wireframe tools** (Balsamiq, Excalidraw) are fast and disposable but throw-away — nothing you draw survives into the build.
- **Design tools** (Figma) are high-fidelity but slow, mouse-bound, hard for agents to drive, and still produce zero shippable code.
- **Hand-coded prototypes** are real but expensive to start and painful to restyle.

TRFI collapses the trade. One artifact — a text document — is simultaneously the fast sketch, the themed mockup, the interactive demo, and the source for shippable components. You never redraw; you **upvert**.

---

## Core concepts

### 1. The text DSL (the "sketch you can type")

Screens are authored as indented, declarative text. Each line is an element with a type, optional label/value, and optional attributes. Types carry sensible **defaults** that are configurable per project and per theme.

```trfi
screen "Login" {
  stack gap=lg {
    heading       "Welcome back"
    text muted    "Sign in to continue"
    field email   label="Email"      placeholder="you@example.com" aria-required=true
    field password label="Password"  type=password
    row gap=sm justify=between {
      checkbox "Remember me"
      link     "Forgot password?"
    }
    button primary "Sign in" data-action="submit"
  }
}
```

- **Element types** (`heading`, `text`, `field`, `button`, `row`, `stack`, `card`, `table`, `list`, `image`, `tabs`, …) each have themeable default classes.
- **`data-*` and `aria-*` attributes** are first-class — write `aria-required=true`, `data-action="submit"` directly on any element.
- The text form is always retained as the canonical source, even after upverting (see §4).

### 2. Style values (the styleguide layer)

A small set of seed values — fonts, color roles, spacing/gap scale, radii, and per-type form definitions — are declared in a `theme.yaml`, mirroring the syntax of `components/styleguide`. From those seeds TRFI **generates the CSS**: type ramps, spacing tokens, component classes, the lot. You write ~12 values; the engine derives hundreds.

### 3. The low-fi / high-fi toggle

A single switch changes the rendering mode of a screen — or any subtree of it:

- **Low-fi** — intentionally rough: sketch borders, placeholder grays, "lorem" affordances. Communicates *structure and intent* without bikeshedding pixels.
- **High-fi** — the CSS generated from `theme.yaml` is applied. Same elements, real type, real color, real spacing.

The toggle is **scoped and nested**. Flip it on a single card and only that card renders hi-fi; its parents stay low-fi. When multiple toggles are set in an ancestor chain, the **nearest** one wins for a given element, and the **nearest theme** in the tree supplies the CSS classes. This lets you present a mostly-sketched screen with one or two regions "brought to life," then progressively raise fidelity region by region.

### 4. Upverting (text → fine-grained format)

The text DSL is fast but coarse. When an element needs control the text form can't express, **upvert** it to a richer structured format (XHTML-like). Upverting:

- **Retains the original text implementation** as the source of record.
- Produces a fine-tunable representation that becomes the input used to generate the final Next.js / HTML / CSS / Lit output for that item.
- Supports a **hybrid mode**: upvert only a selected subset or group of elements on a page. The copied, richer config then lets you set detailed entries for just those items while the rest of the page stays in plain text form.

You raise fidelity exactly where it's needed and nowhere else.

### 5. Export targets

- **HTML** — static, self-contained.
- **Lit web components** (primary) — each widget exports as a standards-based custom element, so a prototyped component is reusable in **Vue, React/Next.js, Phoenix/Elixir (hex), Svelte, or raw HTML** without a rewrite. Lit is preferred over a Next.js-only output precisely because the components must travel everywhere.

### 6. Interactivity: FSM + integrations

A screen is not just static layout. Each prototype can define a **finite state machine** and bind transitions to real or faked side effects:

- Call **APIs / webhooks** to populate elements with live data.
- Call **LLMs** to generate or respond to content.
- React to user interaction (clicks, input, navigation) by firing transitions.
- Persist state through a built-in **key-value store**.

This is what lets the robot "fake it" convincingly — a prototype can hit a real endpoint, run a real model, and remember state across a session, so a demo behaves like the finished product.

### 7. MCP-managed

Every operation — create screen, edit element, define theme token, toggle fidelity, upvert a region, wire an FSM transition, run a prototype, export — is exposed as an MCP tool. Agents drive TRFI the same way a human does through the editor, enabling fully agent-authored prototypes and human-in-the-loop collaboration.

---

## The lifecycle

```
  type a screen ──▶ render low-fi ──▶ define theme.yaml ──▶ flip to high-fi
       (DSL)            (sketch)         (style seeds)        (themed mockup)
                                                                   │
        ┌──────────────────────────────────────────────────────────┘
        ▼
  upvert a region ──▶ fine-tune ──▶ wire FSM + APIs/LLMs ──▶ export Lit / HTML
   (hybrid, partial)   (structured)    (interactive demo)     (ship anywhere)
```

The text source is never thrown away. Every stage is an enrichment of the same artifact, not a restart.

---

## Status

Early concept / design phase. This repository currently holds the product definition, personas, user stories, and candidate visual directions:

- `README.md` — this document.
- `project-management/personas/` — target user personas.
- `project-management/user-stories/` — prioritized user stories.
- `design/theme/` — three candidate UI themes for TRFI's own interface, with example screens of the key pages.

---

## Key pages (TRFI's own UI)

| Page | Purpose |
|------|---------|
| **Editor** | Split view: text DSL on the left, live low-fi/hi-fi canvas on the right; the home of day-to-day work. |
| **Theme Studio** | Edit the `theme.yaml` seed tokens (color roles, type, spacing, radii) and watch generated CSS update live. |
| **Prototype Player** | Run the FSM-driven interactive prototype full-screen, with API/LLM/key-value wiring live. |
| **Screens / Project dashboard** | Gallery of screens in a project, fidelity status, export readiness. |
| **Export panel** | Choose targets (HTML, Lit, Next.js), select scope (whole project / page / upverted region), download or copy. |

---

## Glossary

- **DSL** — the indented text format used to author screens.
- **Low-fi / High-fi** — the two render modes; toggleable per subtree, nearest toggle wins.
- **Upvert** — convert text element(s) to a richer structured form for fine-grained control, retaining the text source.
- **Hybrid mode** — upverting only a subset of a page.
- **theme.yaml** — the seed style values from which CSS is generated.
- **The robot** — the MCP-driven agent that can author and run prototypes on your behalf.
