# Priya Nair — Frontend Engineer (Design System)

**Tagline:** "Give me standards-based components I can drop into any framework without a rewrite."

## Demographics / context
- 29, frontend platform engineer maintaining a shared component library.
- Consumers of her library span React/Next.js, a legacy Vue app, and a Phoenix/Elixir admin.
- Cares deeply about Shadow DOM encapsulation, a11y conformance, and bundle size.
- Reviews PRs against the design system; allergic to one-off bespoke CSS.

## Goals
- Ship one component implementation that works in every framework her org uses.
- Keep components encapsulated, accessible, and tokenized — no global CSS leakage.
- Turn designer mockups into real, testable web components fast.
- Avoid maintaining parallel React/Vue/Phoenix copies of the same widget.

## Frustrations / pain points with current tools
- "Reusable" component libraries are framework-locked; she ports the same button 3x.
- Designer prototypes give her pictures, not structured, themeable markup.
- Token systems live in a design tool and must be hand-mirrored into CSS.
- Accessibility attributes get bolted on late instead of being authored in.

## How she'd use TRFI specifically
- Takes a designer's screen, **upverts** the components she'll own into the structured XHTML-like form for precise control.
- Maps **theme.yaml** seed tokens to her existing CSS-variable contract so generated CSS matches the design system.
- **Exports Lit web components** and consumes them unchanged in React, Vue, and Phoenix.
- Verifies `aria-*` roles/states carried through from the DSL into the exported element.
- Uses **MCP** to script bulk regeneration when tokens change across many components.

## Key features she cares about
- **Lit export (primary)** — one custom element, every framework, no rewrite.
- **Upvert (structured form)** — fine-grained, generation-quality markup she can trust.
- **theme.yaml → generated CSS** — tokens become real, encapsulated styles.
- **aria-/data- first-class** — a11y baked in at authoring time.
- **MCP-managed** — scriptable, repeatable regeneration of the component set.

## Representative quote
> "If it isn't a real custom element that runs in Vue *and* Phoenix, it isn't reusable — it's a screenshot with extra steps."

## Success looks like
She publishes one Lit component from a TRFI export and three teams in three frameworks consume it as-is, tokens intact, a11y conformant, no fork.
