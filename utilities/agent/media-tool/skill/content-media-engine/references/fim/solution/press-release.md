# Press Release — newsworthy announcement for media distribution

A formal, journalist-facing document announcing something genuinely newsworthy (a launch, funding
round, partnership, hire, milestone, or event) in a structure editors can lift verbatim. It is
written in third person, follows AP style, and uses the **inverted pyramid**: the most important
facts first, decreasing in importance, so an editor can cut from the bottom without losing the story.
Good press releases lead with a real news hook and read like a news article; bad ones read like an
ad, bury the news under hype, and get deleted unread.

**Output form**: plain text / lightly structured (headline, dateline, body, boilerplate)
**Typical length**: 400–600 words, one page
**Routed via**: `text_format: press-release` (chat-type generation)

## Genre Conventions & Structure

In strict top-to-bottom order:

1. **FOR IMMEDIATE RELEASE** — flush left at top (or "EMBARGOED UNTIL [date/time]" if held).
2. **Headline** — the news in one line, title case or sentence case, active voice, ~10–15 words.
   States what happened, not a clever pun.
3. **Subheadline (optional)** — one line adding a supporting fact or the "why it matters."
4. **Dateline** — `CITY, State — Month Day, Year —` immediately opening the first paragraph
   (AP: city in CAPS, state abbreviated AP-style, em-dash into the lede).
5. **Lede (paragraph 1)** — the inverted-pyramid apex: the **5 Ws** (who, what, when, where, why)
   in 1–2 sentences. A reader who stops here still has the whole story.
6. **Body (paragraphs 2–4)** — supporting detail in descending importance: context, how it works,
   what's new, market significance. Each paragraph one idea, ~2–4 sentences.
7. **Quote(s)** — at least one attributed quote from a named executive/spokesperson (title + company).
   Quotes carry opinion, vision, and emotion the factual body can't. A second quote from a customer
   or partner adds third-party credibility.
8. **Boilerplate** — "About [Company]": a fixed 3–5 sentence paragraph describing the company, its
   mission, and a URL. Reused unchanged across releases.
9. **Media contact** — name, title, email, phone.
10. **End mark** — `###` (or `-30-`) centered, signaling "end of release" to editors.

## Hard Constraints

- **Inverted pyramid is mandatory** — most newsworthy fact in the lede; nothing critical below the fold.
- **Lede must contain the 5 Ws** and stand alone as a complete micro-story.
- **Third person only** — no "we," "our," "I" outside of quoted speech.
- **AP style**: numbers one–nine spelled out, 10+ as numerals; dates `Month Day, Year` (abbreviate
  Jan., Feb., Aug.–Dec.; spell March–July); `percent` or `%` per current AP (either accepted, be
  consistent); Oxford comma **omitted** in AP style; titles capitalized before a name, lowercase after.
- **`###` end mark required** at the bottom.
- **One page / ~400–600 words** — editors won't read a two-page release.
- **Every claim attributed or factual** — opinion belongs only inside quotation marks.
- **A real news hook** — if there's no genuine news, it's not a press release (it's an ad; reroute).

## How-To (worked recipes)

### How to write a lede that passes the editor's 5-second test
Cram the 5 Ws into the first sentence, lead with the most surprising/important one.
- "SAN FRANCISCO, Calif. — March 4, 2026 — Acme Robotics today launched Orbit, the first warehouse
  robot that unloads a shipping container in under 20 minutes, cutting dock labor costs by half."
- Who (Acme) / what (launched Orbit) / when (today) / where (SF) / why-it-matters (half the cost) — done.

### How to write a usable quote
A quote should sound like a person and add vision or context, not restate the lede.
- Weak: "We are excited to announce this innovative product." ✗ (says nothing, unprintable)
- Strong: "Dock work is the last un-automated link in the supply chain," said Dana Ruiz, CEO of Acme.
  "Orbit removes it — and gives that labor back to higher-value tasks." ✓

### How to write boilerplate once and reuse it
Answer: who they are, what they do, for whom, since when, and where to learn more — no adjectives.
- "About Acme Robotics: Founded in 2019, Acme Robotics builds autonomous material-handling robots for
  warehouses and distribution centers across North America. Learn more at acme.example."

### How to find the newsworthy angle in a promotional brief
Editors run *news*, not ads. Ask: is it a first, a milestone, a large number, a notable partner, a
timely tie-in, or genuine impact? Lead with that. "New feature" is not news; "feature that cuts X by
half, used by [named customer]" is. If nothing qualifies, flag that the brief lacks a news hook.

### How to order the body by the inverted pyramid
After the lede, rank the remaining facts by "what would an editor keep if they could publish only two
more sentences?" Context and significance first, mechanism second, forward-looking detail last. A
reader who stops after any paragraph should still have a coherent, if shorter, story.

## Worked Example — a complete press release

A real-form release for a fictional-but-plausible launch. Note every required mechanic.

```
FOR IMMEDIATE RELEASE

Acme Robotics Unveils Orbit, the First Robot to Unload a Shipping Container in Under 20 Minutes
New autonomous system cuts dock labor costs by half; DHL begins pilot at three U.S. hubs

SAN FRANCISCO, Calif. — March 4, 2026 — Acme Robotics today launched Orbit, an autonomous
warehouse robot that unloads a standard 40-foot shipping container in under 20 minutes — a task
that typically takes a two-person crew more than an hour. Logistics giant DHL has begun piloting
Orbit at three U.S. distribution hubs, with a national rollout planned for 2027.

Container unloading remains one of the most labor-intensive and injury-prone jobs in logistics.
Orbit uses a vision-guided arm and a self-adjusting conveyor to empty a container without human
entry, reducing both cost and workplace injury risk. Early pilots showed a 51% reduction in
per-container labor cost and zero unloading-related injuries over 4,000 containers.

"Dock work is the last un-automated link in the supply chain," said Dana Ruiz, CEO of Acme
Robotics. "Orbit removes it — and gives that labor back to higher-value tasks."

"We move millions of containers a year, and unloading has always been our hardest bottleneck,"
said Marcus Feld, VP of Operations at DHL North America. "Orbit paid for itself in the first pilot."

Orbit ships to enterprise customers in Q3 2026. Pricing is available on request.

About Acme Robotics: Founded in 2019, Acme Robotics builds autonomous material-handling robots for
warehouses and distribution centers across North America. Learn more at acme.example.

Media Contact:
Jordan Lee, Director of Communications
press@acme.example · (415) 555-0142

###
```

Why it works: lede answers all 5 Ws with a real number; body descends by importance; two attributed
quotes (vision + third-party proof) say something; AP dates/numerals; boilerplate, contact, and `###`
present. Every figure is a placeholder the human confirms — none invented as fact by the agent.

## Do's and Don'ts

### ✅ Do
- Lead with the single most newsworthy fact; make the lede self-sufficient.
- Attribute every opinion to a named person with title and company.
- Write in clean AP-style news prose an editor could publish untouched.
- Include a concrete, verifiable hook (number, first, named partner, date).
- Close with real boilerplate, media contact, and `###`.

### ❌ Don't
- Open with hype or the company's history instead of the news.
- Use first person or salesy second person ("You'll love…") outside quotes.
- Stuff the lede with adjectives ("revolutionary, groundbreaking, world-class").
- Write quotes that just restate facts or gush ("We're thrilled to…").
- Fabricate quotes, statistics, or endorsements — a fireable, litigable offense.

## Tone, Voice & Register

Objective, factual, third-person news register — as if a wire-service reporter wrote it. Neutral and
credible in the body; the *only* place for enthusiasm or vision is inside a quotation. Vocabulary is
plain and professional; avoid marketing superlatives, avoid jargon an editor's general audience
wouldn't know. Present/past tense factual reporting ("today announced," "will ship in Q3").

## Platform / Placement Constraints

- **Wire services / newsrooms** (PR Newswire, Business Wire, direct pitches) expect the exact
  structure above; deviation signals amateur and gets ignored.
- **Embargo**: if held, replace the release line with "EMBARGOED UNTIL [date/time TZ]" — respect it absolutely.
- **Plain text / minimal formatting** — no fancy layout; editors copy into their CMS. Emit clean text
  or light markdown (bold headline, plain body).
- **Length**: one page. Multi-page releases lose editors; put extra detail in a linked media kit.
- **SEO note**: an online release benefits from the primary keyword in the headline and first
  paragraph, but never at the cost of news readability.

## Common Pitfalls & Anti-patterns

- **AI-tell / PR-cliché openers**: "In today's fast-paced world," "is proud to announce," "is excited
  to announce," "is thrilled to announce," "leading provider of," "revolutionary/groundbreaking/
  game-changing solution," "cutting-edge technology" — all instantly mark it as non-news filler.
- **Empty gush quotes**: "We are excited/thrilled/proud to…" — say nothing; editors cut them.
- **Buried lede**: the actual news appearing in paragraph 3 after two paragraphs of company background.
- **Ad voice**: second-person selling, exclamation points, "Buy now," pricing pitches.
- **Fabricated numbers/quotes**: inventing "40% growth" or a customer testimonial — never do this;
  if the brief lacks real figures, write the release without them.
- **Adjective-stuffed lede**: three superlatives before the verb; news wants nouns and verbs.
- **Missing mechanics**: no dateline, no boilerplate, no contact, no `###` — reads unfinished.
- **Em-dash overuse** beyond the dateline convention.

## Prep-Agent Notes (media-tool specific)

From a raw brief:
1. Find the **news hook** — the one genuinely newsworthy fact (first/milestone/number/partner/date).
   If none exists, flag it: a press release without news should reroute to `marketing-copy` or `ad-copy`.
2. Assemble the **5 Ws** → draft the lede.
3. Order remaining facts by **descending importance** → body paragraphs (inverted pyramid).
4. Draft **1–2 attributed quotes** — one exec (vision), optionally one customer/partner (proof) — that
   add meaning beyond the facts. Use only quotes/attributions the brief supplies or plausibly authorizes;
   never invent a named person's words as fact — mark placeholders clearly if the brief lacks them.
5. Add **boilerplate**, **media contact**, and **`###`**.
6. Enforce **AP style** and third person throughout.

If `prompt.system` sets an embargo, city, or spokesperson, honor it exactly. Output is plain text via
the chat provider. Never fabricate statistics or quotations — surface missing facts as `[TK: figure]`
placeholders for the human to fill rather than manufacturing them.

## See Also
- `marketing-copy.md`, `ad-copy.md` — promotional siblings (reroute here if there's no real news)
- `seo-article.md` — for the online/blog version of an announcement
- `email-copy.md` — the media-pitch email that accompanies a release
- `../use-case/document-processing.md` — chat-type text generation pipeline
