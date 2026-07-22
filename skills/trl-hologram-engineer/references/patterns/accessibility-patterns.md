# Hologram Accessibility Patterns

Hologram emits **plain semantic HTML** and does nothing for accessibility automatically — **it is your responsibility.** Because state lives client-side and navigation/content swaps happen without full page loads, the two hardest problems are **focus management** and **announcing dynamic changes**. This guide covers both, plus keyboard and forms.

## Baseline: semantic HTML

Use real elements, not `<div>` soup. The template is HTML — there is no excuse not to.

- `<button>` for actions (not `<div $click>`). Buttons are focusable and keyboard-activatable for free.
- `<a>` / `<Hologram.UI.Link>` for navigation.
- Landmarks: `<header>`, `<nav>`, `<main>`, `<footer>`, `<aside>`.
- `<h1>`–`<h6>` in order; one `<h1>` per page.
- `<ul>/<ol>/<li>`, `<table>`, `<form>`, `<label>` — use them for their semantics.

```elixir
# Good: a real button, keyboard-accessible automatically
~HOLO"""<button $click={:toggle}>Toggle</button>"""

# Avoid: a div with a click handler (not focusable/operable by keyboard)
# ~HOLO"""<div $click={:toggle}>Toggle</div>"""
```

If you *must* make a non-interactive element interactive, add `role`, `tabindex="0"`, and a `$key_down.enter` / `$key_down.space` handler mirroring the click — but prefer the native element.

## Focus management on client-side transitions

Client navigation (`Hologram.UI.Link`, `put_page`) and content swaps do **not** move focus or reset the screen-reader's reading position the way a full page load does. Manage it explicitly.

- **After navigation:** move focus to the new page's `<h1>` (give it `tabindex="-1"` and focus it) or to a skip target, so keyboard/SR users start at the top of the new content.
- **Opening a dialog/menu/palette:** move focus into it; trap focus while open; restore focus to the trigger on close.
- **Closing overlays:** return focus to the element that opened them.
- **Removing the focused element** (e.g. deleting the focused list item): move focus to a sensible neighbor first.

Focus moves are done through JS interop (focus is a browser API). Keep the interop call in an action-reachable path (it is a no-op during SSR). Pattern:

```elixir
def action(:open_dialog, _params, component) do
  component
  |> put_state(:dialog_open, true)
  |> put_action(:focus_dialog)      # a follow-up action that calls the focus interop
end
```

Verify the exact interop call for `element.focus()` against `/docs/javascript-interop` for your version.

## Announcing dynamic content: ARIA live regions

When state changes update the DOM without a navigation, screen readers won't announce it unless the region is a **live region**.

- `role="status"` / `aria-live="polite"` — non-urgent updates (search result counts, "Saved", loading). Announced when the user is idle.
- `role="alert"` / `aria-live="assertive"` — urgent (form errors, failures). Interrupts.
- Keep the live region **present in the DOM from first render** and change its text content; injecting the region and its text at the same time can fail to announce.

```elixir
~HOLO"""
<p role="status" aria-live="polite">
  {%if @loading}Loading…{%else}{length(@results)} results{/if}
</p>

{%if @error}
  <p role="alert">{@error}</p>
{/if}
"""
```

## Keyboard interaction

Hologram's `$key_down` filters make keyboard support declarative.

- **Escape** closes overlays: `$key_down.escape={:close}`.
- **Enter/Space** activate custom widgets: `$key_down.enter`, `$key_down.space`.
- **Arrow keys** move within composite widgets (menus, listboxes, tabs): `$key_down.arrow_down`, `$key_down.arrow_up`.
- **Global shortcuts** on `<window>`: `<window $key_down.ctrl+k.prevent_default={:palette} />` — always `.prevent_default` to avoid clobbering browser defaults where appropriate.

```elixir
~HOLO"""
<ul role="listbox" tabindex="0"
    $key_down.arrow_down={:next_option}
    $key_down.arrow_up={:prev_option}
    $key_down.enter={:select_option}
    $key_down.escape={:close}>
  {%for o <- @options}
    <li role="option" aria-selected={o.id == @active}>{o.label}</li>
  {/for}
</ul>
"""
```

## Accessible forms

- Every input has a programmatic label: wrap in `<label>` or use `for`/`id`.
- Errors: associate with `aria-describedby`, mark invalid with `aria-invalid`, and surface them in a `role="alert"` region.
- Because validation is isomorphic, you can show accessible inline errors instantly (client action) and reconcile with server errors from the command.

```elixir
~HOLO"""
<label for="email">Email</label>
<input id="email" type="email" value={@email} $change={:set_email}
       aria-invalid={@errors[:email] != nil} aria-describedby="email-err" />
{%if @errors[:email]}
  <p id="email-err" role="alert">{@errors[:email]}</p>
{/if}
"""
```

## Dialogs / modals

```elixir
~HOLO"""
{%if @open}
  <div class="backdrop" $click={:close}></div>
  <div role="dialog" aria-modal="true" aria-labelledby="dlg-title"
       $key_down.escape={:close} $click_outside={:close}>
    <h2 id="dlg-title">Confirm</h2>
    <slot />
  </div>
{/if}
"""
```

Pair the markup with focus trapping + restore (above). `aria-modal="true"` and a labelled dialog are the minimum.

## Review checklist

- [ ] Interactive elements are native (`button`, `a`) or fully ARIA + keyboard equipped
- [ ] Landmarks and heading order are correct; one `<h1>`
- [ ] Focus moves to new content after client navigation
- [ ] Overlays trap focus and restore it on close
- [ ] Dynamic updates live in a persistent `role="status"`/`role="alert"` region
- [ ] Escape/Enter/Space/Arrow keys behave per WAI-ARIA patterns
- [ ] Form inputs are labelled; errors are associated and announced
- [ ] Color is not the only signal; contrast meets WCAG AA
