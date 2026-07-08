# User Manual — Task-oriented product documentation (user guide / instruction manual)

A user manual (a.k.a. user guide, instruction manual, product documentation) teaches a
real person to accomplish real goals with a product. It lives in help centers, printed
booklets, in-app help, and PDF downloads. Good manuals are **task-oriented** — organized
around what the user is trying to *do*, not around the product's feature list. Bad manuals
are feature-oriented tours ("The Settings Screen has six buttons…") that leave the reader
knowing what exists but not how to succeed. The reader arrives frustrated, mid-task, often
skimming — write for that person.

**Output form**: markdown (or HTML) with headings, numbered steps, tables, callouts
**Typical length**: a topic/page is 300–1500 words; a full manual is many linked topics
**Routed via**: `text_format: user-manual` (chat-type generation)

## Genre Conventions & Structure

A manual is a set of **topics**, each of exactly one type. The industry splits topics three
ways (DITA's information-typing; Diátaxis maps the same idea to reference/how-to/explanation):

- **Concept** — background the reader needs to understand *why/what*. No steps. ("What is a
  workspace?") Keep short; concepts support tasks, they don't replace them.
- **Task** — a numbered procedure that gets one goal done. The workhorse of a manual.
- **Reference** — lookup tables: settings, keyboard shortcuts, error codes, field
  definitions. Neutral, exhaustive, scannable — not read start-to-finish.

Never blend types in one topic. A task topic that stops to explain theory loses the reader
mid-step; move the theory to a linked concept.

**Anatomy of a task topic (the required backbone):**
1. **Title** — a gerund or imperative naming the goal: "Exporting a report" / "Reset your password". Not "The Export Dialog".
2. **Short intro (1–2 sentences)** — what this accomplishes and when you'd do it.
3. **Prerequisites** — accounts, permissions, prior steps, hardware, files. State them
   *before* step 1 so the reader isn't stopped at step 4 by a missing thing.
4. **Numbered steps** — one action per step, imperative mood, in click-order.
5. **Expected result** — after key steps and at the end: "A confirmation banner appears."
   This lets the reader confirm they're on track and self-diagnose when they aren't.
6. **Screenshot / callout placement** — mark where a visual belongs: `[SCREENSHOT: export
   dialog with Format dropdown highlighted]`. Callouts (Note / Tip / Warning / Caution)
   sit adjacent to the relevant step, never in a wall at the top.
7. **Related links / Next steps** — where to go after success.

**Whole-manual scaffolding**: title page → intro & audience → getting-started → task topics
(grouped by user goal) → reference section → troubleshooting → glossary → index. Front-load
the tasks a first-timer needs; bury edge cases deeper (**progressive disclosure**).

## Hard Constraints

- **Every procedure is numbered; every step is one imperative action.** "Click **Save**." not
  "You should now be able to save by clicking the Save button, which will…".
- **Prerequisites appear before step 1.** No mid-procedure surprises.
- **Reading level: grade 8 or below** for consumer/general-public products (per
  plainlanguage.gov); grades 9–11 acceptable for professional-tool audiences. Aim Flesch
  Reading Ease 60–70 for public-facing text. Short sentences (avg ≤ 20 words), common words.
- **Second person, present tense, active voice, imperative for instructions.** "Select the
  file" — never "The file should be selected" or "The user selects the file".
- **UI labels reproduced verbatim** and set off in **bold**: the button that says "Log In"
  is written "**Log In**", not "login" or "Sign In".
- **One task = one goal.** If a procedure exceeds ~9 steps, split it or add subheadings.
- **Terminology is consistent.** Pick one word per concept ("folder", not folder/directory/
  location interchangeably) and use it everywhere; define it once in the glossary.
- **Warnings precede the danger.** A Warning about data loss goes *before* the destructive
  step, not after — the reader has already clicked by then.

## How-To (worked recipes)

### How to convert a feature into a task
The brief says "document the Export panel." Don't describe the panel — ask *what does the
user want to accomplish with it* and title the topic that way.
> ❌ "The Export Panel" → describes each control
> ✅ "Export a report as PDF"
>    **Prerequisites:** A saved report; Viewer role or higher.
>    1. Open the report you want to export.
>    2. Click **File ▸ Export**.
>    3. In the **Format** list, select **PDF**.
>    4. Click **Export**.
>    **Result:** Your browser downloads `report.pdf`. A green "Export complete" banner appears.

*Note:* one feature often yields several task topics (export as PDF, as CSV, on a schedule).

### How to write a step that survives a UI the reader can't see clearly
Anchor each step to a **label + location + action** so it works with or without the
screenshot.
> "In the top-right corner, click your **avatar**, then select **Settings**."

*Note:* location words ("top-right", "in the sidebar") rescue readers when your screenshot is
stale or their theme differs.

### How to build a troubleshooting table
Readers hit troubleshooting already annoyed. Give a scannable symptom → cause → fix table,
symptom first (that's what they know).

| Symptom | Likely cause | Fix |
|---|---|---|
| Export button is greyed out | Report has unsaved changes | Click **Save**, then export |
| Download never starts | Pop-ups blocked | Allow pop-ups for this site, retry |
| PDF is blank | Report has no rows in range | Widen the date filter |

*Note:* order rows by frequency — the most common problem is what most readers came for.

### How to place a screenshot callout without shipping the image
You generate text; a human (or a later pipeline step) supplies the image. Emit an explicit,
self-describing placeholder the illustrator can fulfill and mark what to highlight.
> `[SCREENSHOT: Settings page — highlight the "Two-factor authentication" toggle, top of the Security section]`

*Note:* describe the *annotation* (highlight/arrow/callout number), not just the frame — that's
the part a raw screenshot can't convey.

### How to write a prerequisites block that actually prevents failure
List everything the reader must have or have done, as a checklist, in the order they'll need it.
> **Before you begin**
> - You have an Admin or Owner role.
> - Billing is set up (Settings ▸ Billing).
> - You've installed the CLI (see *Install the CLI*).

*Note:* link each prerequisite that is itself a task; don't re-explain it inline.

## Do's and Don'ts

### ✅ Do
- Organize by user goal; title topics with the goal ("Reset your password").
- Use one imperative action per numbered step.
- State prerequisites up front and expected results throughout.
- Keep concept, task, and reference content in separate topics.
- Reuse exact UI labels in bold; keep terminology consistent across the whole manual.
- Put warnings *before* the risky action; use Note/Tip/Warning callouts sparingly and adjacently.
- Include a glossary and a symptom-first troubleshooting table.
- Write at grade 8 or below for general audiences; short sentences, plain words.

### ❌ Don't
- **Feature-tour the UI** ("This screen contains…") — the reader learns geography, not how to succeed.
- **Bury the lead** with a long "Introduction to Widgets" before the first actionable step.
- **Mix theory into steps** — it breaks momentum; link a concept topic instead.
- **Use passive voice or third person** ("The button is clicked by the user") — it obscures who acts.
- **Assume prior steps silently** — the reader may have jumped straight to this topic from search.
- **Vary terminology** (folder/directory/location) — every synonym is a new thing to the reader.
- **Stack all callouts at the top** — a Warning is useless three steps above the danger… or below it.
- **Screenshot every step** — over-illustration bloats the doc and rots fastest; illustrate decisions and destinations.

## Tone, Voice & Register

Instructional, calm, and direct. Second person ("you"), present tense, active voice.
Imperative for every instruction. Neutral-friendly — helpful without cutesiness; no jokes in
a Warning. Vocabulary is plain and concrete; expand an acronym on first use, then use it.
Respect the reader's intelligence and their time: assume competence, not expertise. The reader
is mid-task and possibly stressed — brevity is kindness.

## Platform / Placement Constraints

- **Web help center**: markdown/HTML; readers arrive by search, so each topic must stand alone
  (repeat/link prerequisites — never "as described above"). Short lines; scannable headings.
- **In-app / tooltip help**: severe space limits; link out to the full topic.
- **Print / PDF**: no hyperlinks the reader can click — use "see *Chapter 4: Billing*" with a
  cross-reference and page number; screenshots must be legible in grayscale.
- **Localization**: sentences that will be translated must avoid idiom, contractions-as-jokes,
  and UI text baked into images (translators can't edit a PNG). Keep source segments short.
- **Accessibility**: every screenshot needs alt text describing its instructional point; don't
  rely on color alone ("click the red button" fails for color-blind readers — say "click
  **Delete**").

## Common Pitfalls & Anti-patterns

- **Feature-oriented instead of task-oriented** — the single biggest failure; documents the
  product, not the reader's goals.
- **Missing prerequisites** — reader is blocked at step 4 by an unmentioned permission or setup.
- **No expected-result statements** — reader can't tell success from a silent failure.
- **Wall-of-callouts** or a Warning placed *after* the destructive step.
- **Inconsistent terminology** and unexplained acronyms.
- **AI-tells**: "In today's fast-paced digital landscape…", "This comprehensive guide will
  delve into…", "Simply…" / "just" (nothing is simple to a stuck reader), "seamlessly",
  "robust", em-dash overuse, and a bloated three-paragraph intro before the first step.
  Fake UI labels invented to sound plausible ("click the **Quantum Sync** button") are the
  most dangerous tell — every label must be real. Cut throat-clearing; start with the task.

## Prep-Agent Notes (media-tool specific)

Given a raw creative brief, the prep agent should:
1. **Identify the audience and its reading level** (consumer → grade 8; professional →
   grades 9–11) and set the register accordingly.
2. **Decompose the product into user goals**, not features — produce a task list, one topic
   per goal, titled as goals.
3. **Per task, extract**: prerequisites, ordered steps, expected results, and any risks
   (→ Warnings placed before the risky step).
4. **Separate** concept/reference material into their own topics; link, don't inline.
5. **Emit screenshot placeholders** (`[SCREENSHOT: …highlight…]`) at decision points and
   destinations, describing the annotation.
6. **Normalize terminology** — build a one-term-per-concept glossary and apply it throughout.
7. Preserve any UI labels the brief supplies **verbatim**; if labels are unknown, instruct the
   generator to use placeholders and flag them rather than invent plausible-sounding ones.
8. Fold `prompt.system` art-direction (brand voice, formality, "friendly startup" vs
   "regulated medical device") into the register, but never at the cost of the imperative,
   step-per-action structure. Output is plain text/markdown via the chat provider path.

## See Also
- `getting-started.md` — the onboarding subset (first success fast); a manual's front door
- `api-reference.md` — the reference-topic type taken to its extreme
- `technical-blog.md` — narrative teaching vs. procedural teaching
- `readme.md` — the one-page billboard that points into the manual
- `../use-case/document-processing.md` — multi-format publication pipeline (PDF/HTML/DOCX)
