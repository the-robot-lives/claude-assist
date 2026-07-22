# Technical Blog — Developer tutorial / engineering article

A technical blog post teaches one idea to a technical reader through narrative plus working
code. It's the middle ground between a dry reference and a marketing blog: it has a point of
view and a voice, but it earns trust with reproducible, copy-paste-ready code and honest
trade-offs. Readers arrive from search or an aggregator with a specific problem ("how do I
debounce a React input", "why is my Postgres query slow") and a low tolerance for fluff — they
will bounce the instant the code looks fake or the intro drones. Good posts explain the
**why**, not only the **what**, and the reader can rebuild the result start to finish. This is
distinct from a marketing blog (SEO-first, product-led, conversion-oriented) — here the payoff
is the reader *learning to do the thing*.

**Output form**: markdown with prose, fenced code blocks, callouts, occasional diagrams
**Typical length**: 800–2500 words; long enough to be complete, short enough to finish
**Routed via**: `text_format: technical-blog` (chat-type generation)

## Genre Conventions & Structure

1. **Title** — specific and outcome/problem-oriented: "Debounce a search input in React
   without a library" beats "Thoughts on React performance." Say what the reader will be able
   to do.
2. **Hook / problem framing (1–3 short paragraphs)** — the concrete problem, why it matters,
   who hits it. Establish the pain fast; no history-of-computing preamble.
3. **What you'll build / prerequisites** — the end state (a screenshot, a repo link, "by the
   end you'll have X") and what the reader needs (versions, prior knowledge).
4. **Body — reproducible steps** — the walkthrough, interleaving prose and code. Each code
   block builds on the last; the reader can follow along in their own editor. Explain
   decisions ("we memoize here because…"), not just keystrokes.
5. **Callouts** — Note / Warning / Tip set apart from the flow for gotchas and asides.
6. **Why-not-just-what** — the reasoning: alternatives considered, trade-offs, when this
   approach breaks down. This is what separates a good post from a copied snippet.
7. **Conclusion** — recap the result, the key takeaway, and honest limitations.
8. **Further reading / repo** — links to the full source, docs, and deeper material.

## Hard Constraints

- **The code runs.** Every snippet is real, correct, and copy-paste-ready; snippets in sequence
  reconstruct the working result. No pseudo-code presented as runnable, no APIs that don't exist.
- **The title names a specific outcome or problem**, not a vague theme.
- **Prerequisites and versions are stated** — language/framework versions, since APIs drift and
  a post rots. Date-stamp or version-stamp anything time-sensitive.
- **Explain the why at least as much as the what** — a wall of code with no reasoning is a gist,
  not an article.
- **Show, then explain** — code block, then the paragraph unpacking it (or vice-versa), but the
  two are paired; never a page of prose then a page of code.
- **One core idea per post.** If it needs three unrelated concepts, it's three posts.
- **Honest trade-offs** — name at least one limitation or alternative. Posts that pretend the
  approach is flawless read as marketing and lose developer trust.

## How-To (worked recipes)

### How to write a hook that survives the 5-second skim
Open on the reader's concrete pain, in plain terms, then promise the payoff.
> "Type in a search box wired straight to an API and you fire a request per keystroke — 15
> requests to spell 'debounce'. Here's how to collapse that to one, in ~20 lines, no library."

*Note:* lead with the problem the reader already feels. Skip "In the ever-evolving landscape of
modern web development…" — that sentence loses more readers than any other.

### How to present code so it's copy-paste-ready and teachable
Show a complete, runnable block, then explain the load-bearing lines.
> ```jsx
> function useDebounced(value, delay = 300) {
>   const [debounced, setDebounced] = useState(value);
>   useEffect(() => {
>     const t = setTimeout(() => setDebounced(value), delay);
>     return () => clearTimeout(t);   // cancel on the next keystroke
>   }, [value, delay]);
>   return debounced;
> }
> ```
> The cleanup `clearTimeout` is the whole trick: each keystroke cancels the previous pending
> update, so only the last one — after `delay` ms of quiet — survives.

*Note:* comment the non-obvious line *in* the code, then expand the reasoning below it.

### How to explain "why, not just what"
After the working solution, justify it against the alternatives.
> You could reach for lodash's `debounce`, but a hook keeps the timing tied to React's render
> lifecycle and avoids a dependency for 20 lines. The trade-off: this recreates the timeout on
> every `value` change — fine here, but for expensive effects you'd want `useMemo` or a ref.

*Note:* naming when your approach is the *wrong* choice is what earns reader trust.

### How to use callouts for gotchas without derailing the flow
Pull the aside out of the narrative so the main thread stays clean.
> > **⚠️ Warning:** `useEffect` cleanup runs on unmount too. If `delay` is large and the
> > component unmounts fast, the final update never lands — usually what you want, occasionally not.

*Note:* Warnings for footguns, Notes for context, Tips for nice-to-haves. Don't overuse; three
callouts in a 1,000-word post is plenty.

### How to decide between a diagram and prose
Use a diagram when the relationship is spatial, sequential, or many-to-many; use prose when
it's a single fact. A request flow, a state machine, or a data pipeline earns a diagram; "the
function returns a promise" does not.
> Prose: "The hook recreates the timeout whenever `value` changes."
> Diagram: a sequence of keystroke → timeout-set → keystroke → timeout-cleared → quiet →
> update-fires, which is far clearer as a small timeline than as a paragraph.

*Note:* if you emit a diagram, describe it in text too (alt text / a sentence) — many readers
skim on mobile or with a screen reader and never see the image.

### How to sharpen a vague title (before/after)
The title is the search-result and the promise; make it name the payoff.
> ❌ "Improving React Performance" → could be anything, promises nothing specific
> ✅ "Cut re-renders 80% with one useMemo — a real profiling walkthrough"
> ❌ "Working with Postgres Indexes" → topic, not outcome
> ✅ "Why your `WHERE created_at > …` query ignores the index (and the fix)"

*Note:* a title that names the reader's exact problem out-converts a clever-but-vague one every time.

### How to close so the reader leaves with something
Recap the outcome, the one takeaway, and where to go next.
> "You now have a dependency-free debounce hook and know *why* the cleanup function is doing the
> real work. Full code is in the repo. Next: throttling (fire at most once per interval) — a
> different tool for a different job. [React docs on effects] · [repo]"

*Note:* end on the takeaway and a forward link, not "Thanks for reading!"

## Do's and Don'ts

### ✅ Do
- Title with a specific outcome or problem.
- Hook on the reader's concrete pain in the first two sentences.
- Make every snippet real, runnable, and sequential; link the full repo.
- Pair each code block with the reasoning behind it.
- State versions and prerequisites; date-stamp perishable content.
- Name trade-offs, alternatives, and when the approach fails.
- Use callouts for gotchas; use a diagram when a data/flow relationship is hard to say in prose.

### ❌ Don't
- **Open with a generic industry preamble** ("In today's fast-paced dev world…") — instant bounce.
- **Post fake code** — snippets that won't compile, invented APIs, `// ... rest of implementation`.
- **Dump code with no explanation** — that's a gist, and the reader could've found the gist.
- **Hide the trade-offs** — pretending the approach is perfect reads as a sales pitch.
- **Cover three concepts at once** — the reader wanted the one they searched for.
- **Skip prerequisites/versions** — the post breaks silently for anyone on a different version.
- **Pad for length/SEO** — a tight 900-word post beats a bloated 2,500-word one.
- **End with "Hope this helps! Like and subscribe."** — give a takeaway and a next step instead.

## Tone, Voice & Register

Knowledgeable peer, not lecturer. First person is fine ("I hit this bug last week…") and often
better — it signals real experience. Second person to instruct ("you'll notice…"). Present
tense. Confident but humble: admit what you don't know and what the approach can't do. Dry
humor is welcome; forced enthusiasm ("This is going to be AWESOME!") is not. Assume the reader
is smart and busy — respect both. Match vocabulary to the audience's level (a beginners' post
glosses `useEffect`; a systems post assumes it).

## Platform / Placement Constraints

- **Dev blog / personal site**: markdown with syntax highlighting; code blocks tagged with the
  language. Include a canonical repo link so readers get the full, tested source.
- **Dev.to / Hashnode / Medium**: markdown-ish; front-matter tags matter for reach, but don't
  keyword-stuff the prose. Cover image + a specific title drive click-through.
- **Company engineering blog**: same craft, but tie back to real production experience; avoid
  turning it into a product ad (that's marketing-copy's job).
- **Cross-posting**: set a canonical URL to avoid SEO self-competition.
- **Perishability**: framework posts rot — state versions prominently and consider a "last
  tested against vX.Y (2026-07)" line near the top.

## Common Pitfalls & Anti-patterns

- **Fake/broken code** — the fastest way to lose a technical reader permanently.
- **Buried lead** — three paragraphs of throat-clearing before the actual problem.
- **What-without-why** — a transcript of keystrokes with no reasoning.
- **No trade-offs** — reads as marketing, not engineering.
- **Version drift** — unversioned code that no longer runs; broken repo link.
- **Scope sprawl** — trying to teach everything, teaching nothing.
- **AI-tells**: "In today's fast-paced digital landscape…", "Let's delve into…", "It's worth
  noting that…", "In conclusion, we have explored…", relentless em-dashes, tri-colon list
  sentences ("fast, reliable, and scalable"), hollow enthusiasm, and — most damaging —
  plausible-looking code with a non-existent method or a subtly wrong signature. If a snippet
  can't be verified, mark it and say so rather than shipping confident-but-wrong code. Cut the
  preamble; start where the problem starts.

## Prep-Agent Notes (media-tool specific)

Given a raw creative brief, the prep agent should:
1. **Pin the single core idea** and rewrite the title as a specific outcome/problem.
2. **Draft the hook** from the reader's concrete pain; strip any generic-landscape preamble.
3. **Sequence the walkthrough** so code blocks build on each other and each is paired with its
   "why"; ensure the final blocks reconstruct a working result.
4. **Demand real code** — instruct the generator to use only APIs it can stand behind, tag each
   block with its language, and flag any snippet it can't verify rather than fabricate one.
5. **Surface trade-offs** — prompt for at least one alternative and one limitation.
6. **State versions/prerequisites** and add a "tested against" stamp for perishable topics.
7. **Add a conclusion + further-reading/repo** block.
8. Fold `prompt.system` voice (house style, first-vs-third person, audience level) into tone;
   keep code correctness non-negotiable. Output is plain text/markdown via the chat provider path.

## See Also
- `getting-started.md` — bare-minimum path vs. this explained narrative walkthrough
- `api-reference.md` — the neutral spec a tutorial teaches the reader to use
- `user-manual.md` — procedural product docs vs. a standalone teaching article
- `marketing-copy.md` — the product-led, conversion-first cousin (sibling genre file)
- `../use-case/document-processing.md` — publishing the article across formats
