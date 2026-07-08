# Getting Started — Quickstart / onboarding to first success

A getting-started guide (quickstart, onboarding, "get up and running") has exactly one job:
carry a brand-new user from nothing to their **first real success** as fast as possible —
ideally under 10 minutes. It is the most-read page a product has and the one that decides
whether the user stays. It is *not* a manual: it deliberately omits almost everything so the
newcomer isn't buried. The measure of a quickstart is **time-to-first-value (TTFV)** — how
long until the reader sees the thing work. Every sentence that doesn't move them toward that
moment is a sentence that loses readers.

**Output form**: markdown with numbered steps and copy-paste code blocks
**Typical length**: 200–800 words; a screen or two — if it scrolls forever, it's a manual
**Routed via**: `text_format: getting-started` (chat-type generation)

## Genre Conventions & Structure

A quickstart is a single **happy-path** procedure. The structure:

1. **One-line what & why** — "Send your first email with the API in 5 minutes." Sets the goal
   and the time budget in the first line.
2. **Assumptions / prerequisites, stated upfront and minimal** — "You'll need Node 18+ and an
   API key." Keep the list ruthlessly short; anything not needed for *first* success is cut.
3. **The minimal path** — the fewest numbered steps from install to a visible result. Each
   step is copy-paste-ready. No branches, no options, no "alternatively you could…".
4. **The success moment** — an explicit, observable payoff: "You'll see `{"status":"sent"}`
   in your terminal." This is the whole point; make it unmissable.
5. **Next steps** — 2–4 links to where the reader goes now (full tutorial, API reference,
   examples). This is where you offload everything you deliberately skipped.

Think **"hello world"**: the smallest complete thing that proves the product works in the
reader's own environment. One path, one outcome, one moment of "it works!"

## Hard Constraints

- **First success in ≤ 10 minutes** (many aim ≤ 5). If the honest path is longer, shrink the
  goal — pick a smaller first success, not a longer guide.
- **Happy path only.** No conditional branches, OS-matrix forks, or "if you prefer X" asides.
  Pick sensible defaults and commit. (Platform variants → tabs or separate short guides.)
- **Every command/code block is copy-paste-runnable as-is**, in order, with no edits beyond
  filling one obvious placeholder (an API key). No pseudo-code, no `...` elisions in a block
  the reader must run.
- **Prerequisites stated before step 1**, and only the ones truly required for first success.
- **An explicit, observable success signal** — the reader must be able to confirm it worked
  without asking anyone.
- **Ends with next-steps links**, not with the last command. Never leave the reader at a dead end.
- **No feature tour, no architecture, no "why we built this".** Save it for the docs.
- **First success must not require production credentials, real payment, or a long build.** Use
  a sandbox/test key, sample data, or a prebuilt template so the payoff is safe and fast.
- **Total scannable length ≤ ~2 screens.** If it scrolls forever, the scope is wrong — shrink
  the goal, don't shrink the type size.

## How-To (worked recipes)

### How to choose the *right* first success
Pick the smallest task that is still genuinely valuable and unmistakably "the product working."
> For an email API: "receive a test email in your inbox," not "understand the SMTP fallback config."
> For a CLI: "run `tool init` and see the generated project," not "configure all 12 flags."

*Note:* if first success needs a credit card, real data, or a 20-minute build, redesign it —
use a sandbox key, sample data, or a prebuilt template so the payoff comes fast.

### How to write a copy-paste block the reader can actually run
Give a complete, runnable snippet and show the expected output right after it.
> ```bash
> curl -X POST https://api.example.com/v1/send \
>   -H "Authorization: Bearer $API_KEY" \
>   -d '{"to":"you@example.com","subject":"Hi","body":"It works!"}'
> ```
> You should see:
> ```json
> {"id":"msg_01","status":"queued"}
> ```

*Note:* show how to set `$API_KEY` in a prior step; never assume an env var exists. Expected
output *is* the success signal — always include it.

### How to state assumptions without scaring the reader off
One short block, only hard requirements, with the fastest way to satisfy each.
> **Before you start:** Node 18+ (`node --version`) and a free API key from the
> [dashboard](#). That's it.

*Note:* "That's it." reassures. If the list has eight items, your first success is too big.

### How to decide what to SKIP
Everything that isn't on the single shortest path to first success is skipped and linked.
> Skip: auth options beyond the one, error handling, config files, all but one language SDK,
> "how it works" theory, edge cases, production hardening.
> Link them under **Next steps**.

*Note:* the discipline of a quickstart is subtraction. When in doubt, cut it and add a link.

### How to handle the credential step without a security footgun
The one placeholder the reader must fill is usually a key. Guide it safely: read from an env
var, never hard-code, and point to where the key comes from.
> 1. Get a **test** API key from your [dashboard](#) (test keys are safe to experiment with).
> 2. Export it:
>    ```bash
>    export API_KEY="sk_test_…"
>    ```
> Now the commands below read `$API_KEY` — you never paste the key into a file.

*Note:* default to a **sandbox/test** credential so a newcomer can't touch production or spend
real money on step one. Never show a real-looking secret inline as if to copy.

### How to end so the reader keeps going
Close with a short, curated set of next moves — momentum, not a menu.
> **Next steps**
> - Build a real integration → *Tutorial: Your first campaign*
> - Look up every endpoint → *API reference*
> - See working examples → *Examples repo*

*Note:* 2–4 links max. A wall of 20 links is as paralyzing as none.

### How to fix a quickstart that's secretly a manual (before/after)
If the draft branches, tours features, and has no payoff, cut it to the spine.
> **Before:** 1,800 words — intro to the product philosophy, a feature matrix, three install
> methods, config reference, then (finally) a snippet with no expected output.
> **After:** goal line → 3 prerequisites → 4 commands → `{"status":"sent"}` → 3 next-steps links.
> ~250 words, first success in 4 minutes.

*Note:* the edit is almost entirely deletion. A quickstart is defined by what you leave out.

## Do's and Don'ts

### ✅ Do
- Put the goal and the time budget in the first line.
- List only the prerequisites needed for *first* success, before step 1.
- Give one linear happy path with copy-paste-ready commands.
- Show expected output as the explicit success signal.
- Use sensible defaults; make every decision *for* the reader.
- End with 2–4 curated next-steps links.
- Test the path yourself, top to bottom, on a clean machine (mentally, for the generator: verify each command is self-sufficient).

### ❌ Don't
- **Dump every feature** — that's the manual's job; a quickstart is a demo, not a catalog.
- **Branch** ("on Windows do X, on Mac do Y, or if using Docker…") — fork into tabs/pages instead.
- **Bury the first command** under a mission statement or architecture diagram.
- **Ship un-runnable snippets** with `...`, pseudo-code, or undefined variables.
- **Omit the success signal** — the reader can't tell "done" from "silently broken."
- **Require heavy setup** (compile, real billing, prod credentials) before any payoff.
- **End on the last command** with no direction to go next.
- **Pad the intro** — "Welcome! We're so excited…" costs you readers before they've started.

## Tone, Voice & Register

Encouraging, brisk, confident. Second person, present/imperative. Short sentences and short
paragraphs — the reader is scanning while alternating between the doc and their terminal.
Optimistic but honest: don't promise "in seconds" if it takes five minutes. Zero jargon the
newcomer hasn't met yet; if a term is unavoidable, gloss it in four words or link it. The vibe
is a friendly expert sitting beside the reader saying "do this, now this — see? it works."

## Platform / Placement Constraints

- **Docs site landing / "Start here"**: often the #1 entry page; assume the reader has zero
  context and arrived from a search or the homepage CTA.
- **README quickstart section**: even tighter — a handful of lines (see `readme.md`); link to
  the full guide.
- **In-product onboarding**: steps become UI checklists/tooltips; the same TTFV discipline
  applies, with even less text per step.
- **Multi-platform products**: use tabbed code blocks (npm/yarn/pnpm; curl/JS/Python) so the
  single narrative path stays linear while each reader sees only their variant.

## Common Pitfalls & Anti-patterns

- **Manual-in-disguise** — the "quickstart" is 3,000 words and covers every option (TTFV blown).
- **Prerequisite ambush** — a required tool or account surfaces at step 6.
- **No success moment** — the guide ends and the reader doesn't know if it worked.
- **Branch paralysis** — too many "if you're using…" forks on the primary path.
- **Broken snippets** — copied commands fail because a variable/step was assumed.
- **AI-tells**: "In today's fast-paced world…", "Let's dive in!", "Simply run…" (it's rarely
  simple), "seamlessly integrate", "Welcome to the exciting world of…", a gushing intro
  paragraph, and em-dash-laden filler. Also: inventing a plausible but wrong install command
  or endpoint — a quickstart that doesn't run is worse than none. Start with the goal line and
  the first real command; delete the throat-clearing.

## Prep-Agent Notes (media-tool specific)

Given a raw creative brief, the prep agent should:
1. **Define the single first-success goal** — the smallest genuinely-valuable "it works"
   moment — and put it, plus a time budget, in the opening line.
2. **Extract the minimal prerequisite set** (only what first success needs) and front-load it.
3. **Reduce to one linear happy path**; discard branches and options into a Next-steps list.
4. **Ensure every code block is complete and runnable**; pair each with its expected output as
   the success signal. If the brief lacks exact commands/endpoints, instruct the generator to
   mark placeholders and flag them rather than fabricate runnable-looking-but-wrong code.
5. **Curate 2–4 next-steps links** pointing to the tutorial, reference, and examples.
6. Apply `prompt.system` voice (brand friendliness, formality) to tone only — never let it
   expand scope or add a feature tour. Output is plain text/markdown via the chat provider path.

## See Also
- `user-manual.md` — the full task documentation a quickstart deliberately defers to
- `readme.md` — hosts a minimal quickstart section and links here
- `api-reference.md` — the "look up everything" destination for Next steps
- `technical-blog.md` — a longer narrative walkthrough vs. this bare-minimum path
- `../use-case/document-processing.md` — publishing the guide across formats
