# UX Microcopy — the tiny functional text that runs the interface

UX microcopy is the small, functional text embedded in an interface: button labels, form
labels and helper text, validation errors, empty states, loading messages, confirmations,
toasts, tooltips, onboarding hints, and 404 pages. It is read at the exact moment a user is
deciding what to do or recovering from a problem, so it is judged by *usefulness*, not
eloquence. Good microcopy is nearly invisible — it removes friction; bad microcopy blames,
confuses, or pads. NN/g found concise, scannable, neutral copy lifted usability by up to
124%, and that unclear interface instructions caused 50% of user errors. Every word must earn
its place.

**Output form**: plain text / short strings (occasionally minimal markdown)  **Typical length**: 1 word to ~2 sentences per string
**Routed via**: `text_format: ux-microcopy` (chat-type generation)

## Genre Conventions & Structure

Microcopy is not one artifact — it is a *set of strings keyed by UI state*. The prep agent
should produce copy per state, because each state has its own rules:

- **Buttons / CTAs** — verb-first, ≤2–3 words. Name the action's outcome: `Save changes`,
  `Create account`, `Send invite`. Never generic `Submit`/`OK` when a specific verb fits.
- **Form labels** — noun phrase, sentence case, no colon needed: `Email address`, `Card number`.
- **Helper text** — one line under a field, explains format/why: `We'll only use this to send your receipt.`
- **Validation errors** — state *what's wrong* + *how to fix*, inline, next to the field.
- **Empty states** — value sentence + one primary action: `No projects yet. Create your first project to get started.` + `New project` button.
- **Loading / progress** — say what's happening, not just `Loading…`: `Uploading 3 of 5 files…`.
- **Success / confirmation** — brief, warm, past tense: `Changes saved.` `Invite sent to maria@acme.com.`
- **Toasts / snackbars** — one line, auto-dismiss; include an undo for reversible actions.
- **Destructive-action confirmations** — name the object + consequence; the confirm button
  repeats the verb (`Delete project`), never `Yes`/`OK`.
- **Tooltips** — ≤1 short sentence, no punctuation-heavy fragments; never hide critical info here.
- **Onboarding hints / coach marks** — one benefit-led sentence per step, dismissible.
- **404 / error pages** — reassure, orient, offer a route out (`Go to dashboard`, search).

Ordering within a flow: **label → helper → (on error) error → (on success) confirmation.**

## Hard Constraints

These are checkable and non-negotiable:

1. **Concision.** Buttons ≤3 words (ideally 1–2). Helper text ≤~1 line (~90 chars). Toasts
   one line. Microcopy overall is "fewer than three sentences" (NN/g).
2. **Action-orientation.** Buttons and links start with a verb describing the outcome
   (`Download report`, not `Report`). No standalone `Submit`, `OK`, `Yes`, `Click here`.
3. **Accessibility (WCAG 2.2).**
   - **Link/button purpose must be clear from the text alone** (SC 2.4.4). Ban `Click here`,
     `Read more`, `Learn more` as the *entire* link text — screen-reader users tab through a
     list of links out of context.
   - **No emoji-only or icon-only controls** without a text label or `aria-label`. An emoji is
     not a word; screen readers announce it literally (`Save 💾` is fine, `💾` alone is not).
   - Error messages must be programmatically associated with their field and not conveyed by
     color alone (SC 1.4.1) — pair color with text/icon.
   - Sentence case for readability; avoid ALL CAPS for anything beyond a short acronym.
4. **Blameless error tone.** Never accuse the user (`You entered an invalid…`) — describe the
   condition (`That email address isn't formatted correctly`).
5. **Specificity.** Errors and empty states name the actual field/object, never `An error occurred`.
6. **Localization headroom.** Write English strings assuming translation will expand them:
   German/Finnish run ~30% longer (short strings up to 2×). Don't rely on a label fitting a
   fixed pixel width; avoid packing meaning into word order that won't survive translation.

## How-To (worked recipes)

### How to write a button that survives the "list of buttons" test
Read every button on the screen as a flat list, ignoring context. Each must still make sense.
- ❌ `Submit` / `Cancel` / `OK`  → out of context these say nothing.
- ✅ `Create account` / `Discard changes` / `Send reset link`
Note: the confirm button should echo the sentence's verb — the dialog "Delete this project?"
pairs with a `Delete project` button, so the click confirms *what* is happening.

### How to turn a blaming, vague error into a calm, specific one
Formula: **[what's wrong], [how to fix it]** — neutral voice, at the field.
- ❌ `Error: Invalid input.`
- ❌ `You forgot to enter a valid password!`
- ✅ `Password must be at least 8 characters and include a number.`
- ✅ `We couldn't find an account with that email. Check the spelling or create one.`
Note: put it inline next to the field, on blur, not in a top-of-page block after submit.

### How to write an empty state that drives the next action
Lead with the *value* of filling the space, then give exactly one primary action.
- ❌ `No data.`
- ✅ Heading: `No invoices yet`  Body: `When you send an invoice, it'll show up here.`
  Button: `Create invoice`
Note: empty states are prime onboarding real estate — one benefit sentence, one CTA, no wall of tips.

### How to write a destructive-action confirmation that prevents mistakes
Name the object, state the consequence, make the irreversible-ness explicit, and label the
button with the verb (not `Yes`).
- ✅ Title: `Delete "Q3 Roadmap"?`  Body: `This permanently deletes the board and its 42 cards. This can't be undone.`
  Buttons: `Cancel` (secondary) · `Delete board` (destructive)
Note: for *reversible* actions prefer an action + undo toast over a modal — modals should be
reserved for the genuinely destructive.

### How to write a loading/progress message that reduces anxiety
Say what is happening and, when possible, how much is left.
- ❌ `Loading…` (for a 20-second export)
- ✅ `Preparing your export — this can take up to a minute.`
- ✅ `Uploading 3 of 5 photos…`
Note: for >~10s operations, name the operation; for indeterminate waits, set an expectation.

### How to write a success confirmation that's warm but not chatty
Past tense, one clause, no exclamation pile-up.
- ❌ `Success! Your operation was completed successfully! 🎉🎉`
- ✅ `Changes saved.`  ✅ `Invite sent to maria@acme.com.`  ✅ `Password updated.`
Note: confirm the *specific* thing that happened; echo the object so the user trusts it worked.

### How to write an accessible link that isn't "Click here"
The link text alone must reveal its destination (WCAG 2.4.4). Rewrite so the meaningful words
*are* the link.
- ❌ `To read the docs, click here.`
- ❌ `Learn more` (as the entire link)
- ✅ `Read the API documentation` (whole phrase is the link)
- ✅ `See the pricing page` / `Download the 2026 report (PDF, 2 MB)`
Note: if a design demands a bare `Learn more`, give it an `aria-label` that names the target
(`aria-label="Learn more about billing"`) — but prefer visible descriptive text.

### How to write an onboarding hint that helps instead of nagging
One dismissible sentence, benefit-led, tied to the element it points at.
- ❌ `Welcome! This is the dashboard. Here you can do many things. Click around to explore!`
- ✅ `Pin the reports you check daily — they'll stay at the top.` (coach mark on the pin icon)
Note: one hint per step, always dismissible, never block the primary task behind it.

## Do's and Don'ts

### ✅ Do
- Front-load the key word; users scan, they don't read.
- Use **sentence case** and plain, human words (`Turn on`, not `Enable feature toggle`).
- Match the **button verb to the user's goal**, not the system's process.
- Keep error tone **calm and specific**; keep success tone **brief and warm**.
- Offer an **undo** for reversible actions instead of a confirmation modal.
- Write the **error and empty state first** when designing a field — they're where users get stuck.
- Leave **length headroom** for translation (design to ~2× for short strings).

### ❌ Don't
- Don't use `Click here` / `Read more` as the whole link — fails WCAG 2.4.4 and reads as nothing out of context.
- Don't ship **icon-only or emoji-only** controls without a label/`aria-label` — invisible to screen readers.
- Don't blame the user (`You entered…`, `Invalid`) — it raises stress and abandonment (79% leave on error).
- Don't write **robot voice** (`The operation was completed successfully`, `Entity not found`) — surface DB/HTTP internals never reach the user.
- Don't pad errors with faux-cheer (`Oops! Something went wrong on our end 😬`) — it delays the fix and hides the cause.
- Don't rely on **color alone** to signal an error (fails SC 1.4.1).
- Don't use ALL CAPS for sentences or exclamation-mark spam.

## Tone, Voice & Register

- **Register:** plain, direct, second person ("you"), active voice. Conversational but not cute.
- **Tone flexes by state (this is the core craft):**
  - *Error* → **calm, specific, blameless.** Lower the temperature: no `!`, no `Oops`, no jokes.
  - *Success* → **brief and warm.** A period, not three exclamation marks.
  - *Empty* → **encouraging, forward-looking.** Point at the next action.
  - *Destructive confirm* → **serious and unambiguous.** No humor near irreversible actions.
  - *Onboarding* → **welcoming, benefit-led,** never condescending.
- **Person/voice:** address the user as "you"; refer to the product as "we" sparingly (mostly in
  helper/confirmation: "We'll email you a receipt"). Prefer the imperative for actions the user
  takes (`Choose a plan`).
- **Humor:** allowed only in low-stakes, non-blocking states (playful 404, friendly empty state).
  Never in errors, payment, security, or destructive flows.
- **Vocabulary:** aim ~6th–8th-grade reading level; expand or drop jargon and acronyms on first use.

## Platform / Placement Constraints

- **Native mobile (iOS HIG / Android Material):** buttons are short by necessity; iOS favors
  Title Case for some controls, Android/Material favors sentence case and often ALL-CAPS-styled
  buttons *rendered by the system* (write sentence case; let the style layer transform it).
- **Toasts/snackbars:** single line, brief timeout; put any action (Undo) in the toast, not a
  second dialog. Don't put critical, must-read info in an auto-dismissing toast.
- **Tooltips:** never the only place important info lives; not keyboard/touch reliable for
  discovery. Keep to one short sentence.
- **Responsive width:** a label that fits on desktop may wrap or truncate on mobile — keep
  labels tight and test wrapping.
- **Localization slots:** any string in a fixed-width control needs ~30% (short strings up to
  2×) expansion headroom for German, Finnish, Dutch, Russian; contraction for CJK. Avoid
  concatenating fragments ("You have " + n + " items") — it breaks grammar/gender/plurals in
  other languages; use full templated strings with plural rules.
- **Screen readers:** buttons/links carry their own accessible name; decorative icons get
  `aria-hidden`. Live regions (`aria-live="polite"`) announce toasts and inline validation.

## Common Pitfalls & Anti-patterns (incl. AI-tells)

**General microcopy failures**
- Generic `Submit` / `OK` / `Cancel` where a specific verb fits.
- Vague errors: `An error occurred`, `Invalid input`, `Something went wrong`.
- Buried lead in helper text — the reason comes after the instruction.
- Duplicated meaning: heading + body + button all saying the same thing.
- Exclamation-mark and emoji spam in confirmations.

**AI-tells (LLMs generate these constantly — strip them):**
- **Verbose faux-friendly errors:** "Oops! Something went wrong on our end. Please try again
  later." → says nothing, blames "our end," delays the fix. Replace with the specific cause +
  action: `We couldn't save your changes — check your connection and try again.`
- **Robot / system voice:** "The operation was completed successfully.", "Entity not found.",
  "Request processed." — leaks backend framing. → `Saved.` / `We couldn't find that page.`
- **Emoji-only or emoji-padded buttons:** `💾`, `Save ✅✨` — inaccessible and noisy.
- **`Click here` / `Learn more` links** as the entire link text — the single most common AI
  accessibility miss.
- **Over-apologizing / over-cheering:** "We sincerely apologize for any inconvenience this may
  have caused" in a toast; "Awesome! You're all set! 🎉" everywhere.
- **Marketing voice bleeding into UI:** "Unlock the full power of your workflow" on a *button*.
  Buttons describe the click, not the brand promise.
- **Filler openers:** "In order to…", "Please note that…", "Simply…", "Just…". Cut them; the
  action word should lead.
- **Inflated word choice:** "utilize", "leverage", "seamless", "effortlessly", "delve" — plain
  verbs win (`use`, not `utilize`).
- **Fabricated specifics:** an LLM inventing exact counts/times it can't know
  ("This will take exactly 30 seconds"). Use ranges or the real value from the system.

## Prep-Agent Notes (media-tool specific)

Output is a **set of state-keyed strings**, produced via the chat provider path as plain text.
When `text_format: ux-microcopy`, replace static guidance with this file, then:

1. **Identify the UI states in scope** from the brief (button? error? empty state? whole
   flow?). If the brief only says "write the error message," produce just that string plus the
   matched success/helper if they're implied — don't invent unrelated states.
2. **Extract the object and action** from the brief: what is the user acting on, and what
   happens? Feed that into the verb-first button and the specific error/confirmation.
3. **Generate per-state variants** where useful (e.g. 2–3 button options, an error + its
   recovery hint), each obeying the hard constraints (length, verb-first, blameless).
4. **Enforce the checklist before emitting:** button ≤3 words & verb-first; error =
   what+how, blameless, inline; no `Click here`; no emoji-only control; success brief+past
   tense; length headroom noted for i18n.
5. **Honor `prompt.system` art-direction** for voice (e.g. "playful", "enterprise-formal",
   "terse") — but *never* let voice override the accessibility and blameless-error hard
   constraints. A "playful" brand still gets a calm, specific payment error.
6. **State the placement** if it constrains length (toast vs modal vs inline) and flag any
   string that needs an `aria-label` because it's icon/emoji-driven.
7. Keep it plain text; only use light markdown (a `-` list) when returning multiple labeled
   strings so the caller can map them to states.

## See Also
- `marketing-copy.md`, `ad-copy.md`, `email-copy.md` — persuasive copy (different rules: microcopy is functional, not persuasive)
- `getting-started.md`, `user-manual.md` — onboarding/instructional prose that microcopy hints hand off to
- `readme.md`, `api-reference.md` — sibling docs genres
- `../use-case/document-processing.md` — choosing a text genre/format
