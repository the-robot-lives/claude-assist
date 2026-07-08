# SEO Article — search-optimized long-form content

A long-form web article written to rank in search results and satisfy the searcher's intent while
reading as genuinely helpful content — not keyword-stuffed filler. Modern SEO rewards content that
matches search intent, demonstrates real expertise (E-E-A-T), and is structured for both skimming
humans and answer engines (Google AI Overviews, featured snippets). Good SEO articles answer the
query fast, use a clean header hierarchy, and earn the ranking on usefulness; bad ones stuff keywords,
pad word count, and bury the answer under an "In this article we will discuss…" preamble.

**Output form**: markdown (H1/H2/H3, lists, tables) + meta title & description
**Typical length**: 1,000–2,500 words depending on intent (how-to shorter, pillar longer)
**Routed via**: `text_format: seo-article` (chat-type generation)

## Genre Conventions & Structure

### On-page SEO scaffolding (the checkable frame)
- **Title tag / H1**: primary keyword near the front; compelling, not just the raw keyword.
- **Meta description**: ~150–160 chars, includes the keyword, written as a click-earning summary (not
  a ranking factor directly, but drives click-through).
- **URL slug**: short, keyword-bearing, hyphenated, lowercase.
- **First 100 words**: primary keyword appears naturally and the article answers/frames the query.
- **Header hierarchy**: one H1, then H2 sections, H3 subsections — logical outline, keyword-relevant
  H2s that map to sub-questions and searches.
- **Internal links**: 2–5 contextual links to related pages on the same site (spreads authority,
  keeps readers on-site); descriptive anchor text, not "click here."
- **External links**: to authoritative sources where it supports a claim (signals E-E-A-T).
- **Alt text** for images; **schema/structured data** where applicable (FAQ, HowTo, Article).

### Search-intent match (the strategy)
Classify the query and structure to its intent:
- **Informational** ("what is X") → definition-first, explanatory, snippet-friendly.
- **Commercial** ("best X for Y") → comparison, criteria, tables, pros/cons.
- **Transactional** ("buy X") → concise, product-led, clear next step.
- **Navigational** ("brand X login") → direct answer, don't pad.
Mismatched intent = no ranking, regardless of keyword density.

### Featured-snippet / AI-Overview friendliness
- Answer the core question in a **40–60 word** paragraph directly under the relevant H2.
- Use **definition blocks, numbered steps, and tables** — the formats engines lift into snippets.
- Structure sub-questions as H2/H3 that mirror "People Also Ask" phrasing.

## Hard Constraints

Web-verified 2026 conventions — checkable:
- **Meta description**: aim **155–160 chars** desktop (~920 px), **110–120 chars** mobile (~680 px);
  include the keyword; write it as a summary, don't let Google auto-truncate a random sentence.
- **Title tag**: **50–60 chars** (~580 px desktop, ~480 px mobile) to avoid SERP truncation.
- **One H1 per page**; H2/H3 nest logically (no skipping H2→H4).
- **Primary keyword in**: title, H1, first 100 words, at least one H2, and the meta description.
- **Keyword density**: natural — roughly **0.5–1.5%**; there is no magic number, and over-optimization
  is penalized. Use synonyms/entities, not repetition.
- **Readability**: grade 6–9 for general audiences; short paragraphs (≤3–4 sentences); use lists/tables.
- **Every factual claim** should be supportable; cite sources for statistics.

## How-To (worked recipes)

### How to match search intent before writing a word
Search the target keyword, read the current top 5 results, note their format (list? guide? comparison?).
Google has already told you what satisfies the intent. Match the *dominant format* and then beat it on
depth/clarity — don't publish a listicle where the SERP rewards a step-by-step tutorial.

### How to win a featured snippet
Put the question as an H2 and answer it immediately in 40–60 words, self-contained.
- H2: "How long should a meta description be?"
- Answer: "A meta description should be 155–160 characters on desktop and 110–120 on mobile. Google
  displays roughly 920 pixels of text before truncating, so front-load the key message and include
  your primary keyword within the first sentence." ← liftable verbatim.

### How to write a meta description that earns the click
Summarize the payoff + include the keyword + imply a benefit, within ~155 chars.
- "Learn the exact meta description length for 2026 (155–160 chars), plus a copy-paste template and the
  3 mistakes that get yours rewritten by Google." (148 chars) ✓

### How to demonstrate E-E-A-T without a byline
Show first-hand experience (specific examples, real numbers, screenshots-worthy detail), cite
authoritative sources, be accurate and current, and avoid unsupported claims. Depth and specificity
*are* the expertise signal — vague generic advice reads as low-effort AI content that engines demote.

### How to structure for skim + depth simultaneously
Lead each H2 with the answer (for skimmers and snippets), then expand (for deep readers). Use a table
of contents for long pieces, bold the key takeaway per section, and put comparisons in tables. The
skimmer gets value in 30 seconds; the researcher gets the full case.

## Do's and Don'ts

### ✅ Do
- Answer the query in the first screen — respect the searcher's time.
- Use descriptive, keyword-relevant H2s that map to real sub-questions.
- Add tables, numbered steps, and definition blocks (snippet + AI-Overview bait).
- Link internally with descriptive anchors; cite authoritative external sources.
- Write for the human first; the ranking follows genuine usefulness.

### ❌ Don't
- Keyword-stuff or repeat the exact phrase unnaturally — it's demoted, not rewarded.
- Pad word count with "In this article, we will explore…" preambles and restated conclusions.
- Write a title that's just the raw keyword with no click appeal.
- Bury the answer beneath history/background the searcher didn't ask for.
- Fabricate statistics or cite sources you didn't verify.

## Tone, Voice & Register

Helpful, clear, authoritative-but-accessible. Usually second person for how-to ("you'll want to…"),
third person for informational reference. Active voice, plain language, short sentences. Confident and
specific — expertise shows in concrete detail, not in adjectives. Neutral where the topic is factual;
a light brand voice is fine but never at the cost of clarity or trust.

## Platform / Placement Constraints

- **SERP rendering**: title and meta description are what a searcher sees before clicking — treat them
  as ad copy with a keyword. Truncation limits above are hard.
- **AI answer engines** (Google AI Overviews, Perplexity, ChatGPT search): favor clearly-structured,
  factual, well-sourced content with extractable definitions, lists, and tables. Structure for
  *extraction*, not just reading.
- **Mobile-first indexing**: Google ranks the mobile version — short paragraphs and fast-loading,
  scannable structure matter more, not less.
- **Markdown output**: emit clean H1/H2/H3, lists, and tables so the CMS renders proper semantic HTML.

## Common Pitfalls & Anti-patterns

- **AI-tell openers**: "In today's fast-paced digital world," "In the ever-evolving landscape of," "In
  this article, we will delve into," "Let's dive in," "In conclusion" — engines and readers pattern-
  match these as low-value AI filler.
- **The word "delve"** and its cohort ("tapestry," "realm," "navigate the complexities," "in the realm
  of," "it's worth noting," "a testament to") — canonical AI-tells that erode E-E-A-T.
- **Keyword stuffing**: the exact phrase jammed into every other sentence — over-optimization penalty.
- **Word-count padding**: 2,500 words of fluff to "hit length" when the query needs 800 — dwell time
  and helpfulness signals punish it.
- **Buried answer**: 400 words of preamble before the how-to actually starts.
- **Fabricated stats / fake citations**: inventing "73% of marketers say…" with no source — an E-E-A-T
  and trust killer; omit or mark `[TK: cite]` instead.
- **Generic vagueness**: advice that could apply to any topic = the hallmark of demoted AI content.
- **Repetitive AI rhythm**: uniform sentence length, "Not only… but also," tricolon spam, em-dash overuse.
- **Conclusion that restates the intro**: adds length, no value; end on a next step or fresh insight.

## Prep-Agent Notes (media-tool specific)

From a raw brief:
1. Extract or infer the **primary keyword + search intent**; classify (informational/commercial/
   transactional/navigational) and choose the matching format.
2. Draft the **title (≤60 chars)** and **meta description (~155 chars)** with the keyword front-loaded.
3. Outline **H2 sections mapping to sub-questions** ("People Also Ask" style); plan one snippet-target
   40–60 word answer per key H2.
4. Ensure the **primary keyword lands in title, H1, first 100 words, ≥1 H2, meta description** naturally.
5. Plan **internal-link anchors, external authoritative citations, and any table/list** for snippet bait.
6. Write for the human; verify no fabricated stats — mark unverifiable claims `[TK: cite]`.

If `prompt.system` supplies target keyword, audience, or word count, honor it; otherwise infer intent
from the brief and default to grade 6–9 informational. Emit clean markdown plus a leading metadata
block (title + meta description). Output is plain markdown via the chat provider. Never keyword-stuff
or fabricate statistics to inflate authority.

## See Also
- `marketing-copy.md` — conversion copy for the page the article may link to
- `press-release.md` — the announcement version of newsworthy content
- `email-copy.md`, `ad-copy.md` — sibling marketing genres
- `../use-case/document-processing.md` — chat-type text generation pipeline
