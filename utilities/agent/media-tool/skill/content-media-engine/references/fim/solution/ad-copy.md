# Ad Copy — search & social paid advertising

Short, high-density persuasion written to strict per-slot character budgets for auction-based
ad platforms (Google Ads, Meta/Facebook/Instagram, programmatic/AdSense). Success is measured
in click-through rate and conversion, not prose quality: the copy must earn a click inside a
scanning glance while surviving the platform's automated policy review. Good ad copy leads with
one benefit, names the audience, and ends with a directive CTA; bad ad copy buries the offer,
pads to the limit with adjectives, and trips a compliance filter.

**Output form**: plain text, per-slot assets (arrays of headlines / descriptions)
**Typical length**: 30–90 characters per asset; 3–15 assets per field
**Routed via**: `text_format: ad-copy` (chat-type generation)

## Genre Conventions & Structure

Ad copy is not one string — it is a **set of independent, interchangeable assets** the platform
recombines. Author each slot as a self-contained unit.

**Google Responsive Search Ad (RSA) — the dominant search unit:**
- **Headlines**: 3–15 assets, each ≤30 chars. Platform shows up to 3 at a time, separated by `|`.
- **Descriptions**: 2–4 assets, each ≤90 chars. Platform shows up to 2.
- **Display path**: 2 optional path fields, ≤15 chars each, appended to the visible domain
  (`example.com/Path1/Path2`) — vanity only, not a real URL.
- **Pinning**: lock an asset to position 1, 2, or 3 to force order (e.g. pin the brand name or
  a legal disclaimer to headline 1). Over-pinning kills the machine-learning combination benefit.
- **Keyword insertion**: `{KeyWord:Default Text}` dynamically inserts the matched search term;
  `Default Text` shows if insertion would exceed the limit. Capitalization of the tag controls
  casing (`{KeyWord}` = Title Case, `{keyword}` = lowercase).
- **Sitelinks (extension)**: link text ≤25 chars, two optional description lines ≤35 chars each.
- **Callouts (extension)**: ≤25 chars each, non-clickable trust snippets ("Free Shipping").

**Meta (Facebook/Instagram) feed ad:**
- **Primary text**: hard cap 2,200 chars, but only ~125 chars show before "See More" on mobile —
  treat 125 as the real limit and front-load.
- **Headline**: 40-char cap, but ~27 chars visible on most placements.
- **Link description**: 30-char cap, ~27 visible, often hidden on mobile feed.
- **CTA button**: chosen from Meta's fixed list (Shop Now, Learn More, Sign Up, Book Now…), not free text.

**Every ad, all platforms**: one dominant benefit → supporting proof → explicit CTA. That triad
must survive even when only the shortest assets are shown.

## Hard Constraints

Web-verified 2026 platform limits — these are checkable and enforced at upload:

| Platform / slot | Limit | Notes |
|---|---|---|
| Google RSA headline | **≤30 chars**, 3–15 assets | ≥3 required; 5+ recommended for ML |
| Google RSA description | **≤90 chars**, 2–4 assets | 2 required |
| Google RSA display path | **≤15 chars** ×2 | optional, vanity |
| Google sitelink text | **≤25 chars** | desc lines ≤35 ×2 |
| Google callout | **≤25 chars** | |
| Meta primary text | 2,200 cap / **~125 visible** | front-load first line |
| Meta headline | **40 cap / ~27 visible** | |
| Meta link description | **30 cap / ~27 visible** | |

- **Character count includes spaces and punctuation.** Emoji count as 1–2 chars and are stripped by some policy filters.
- Google counts double-width characters (CJK) as **2**; a 30-char English headline is ~15 CJK glyphs.
- No two RSA headlines may be identical; the platform rejects duplicates.
- Google disallows `!` in headlines and permits at most **one `!` in description** text.
- No ALL-CAPS words (except legitimate acronyms/brand names) — auto-rejected as "gimmicky."

## How-To (worked recipes)

### How to hit ≤30 chars without losing the hook
Cut articles and helper verbs, lead with the noun that carries the promise.
- Draft (41): "Get Your Free Trial of Our CRM Today" ✗
- Fit (28): "Start Your Free CRM Trial" ✓ — verb + benefit + object, 28 chars, room to spare.

### How to write a CTA that matches the placement
Search intent is high → be transactional. Social discovery is low → be curiosity/value-led.
- Search description CTA: "Compare plans & switch in minutes." (directive, decision-stage)
- Meta CTA button + text: button "Learn More" + primary text ending "See why 4,000 teams switched."
Never use "Learn more" as your *only* verb on a high-intent search ad — it wastes the click.

### How to use keyword insertion safely
`{KeyWord:Running Shoes}` on "Buy {KeyWord:Running Shoes} Online" renders "Buy Trail Shoes Online"
for the query *trail shoes*. Always set a Default that fits ≤30 chars AND reads grammatically —
insertion of a long-tail query ("best waterproof running shoes for flat feet") would overflow, so
the Default is what actually shows. Never insert into legal/price claims.

### How to structure 15 headlines so the ML has room to work
Group by theme so any 3-combination reads coherently: 5 benefit-led, 4 offer/price-led,
3 trust/proof, 2 brand, 1 CTA. Pin ONLY a required disclaimer or brand — leave the rest unpinned.
This gives Google combinatorial freedom while guaranteeing no incoherent pairing.

### How to pass the 5-second scan test
The single most important word goes in the first two words of the primary asset. If a reader saw
only "Cut invoicing time" and nothing else, they'd still know the offer. Test by truncating your
headline at 15 chars — is the promise still legible?

## Do's and Don'ts

### ✅ Do
- Lead every asset with the benefit or the audience, not the brand ("Sleep better in 7 nights").
- Write assets that stand alone — assume yours is the only one shown.
- Use numbers and specifics ("Save 30%", "2-day shipping") — they out-convert adjectives.
- Mirror the searcher's language; echo the likely query in at least 3 headlines.
- Give one clear next action per ad.

### ❌ Don't
- Pad to the limit with filler adjectives ("amazing, incredible, best-in-class") — dilutes the hook.
- Repeat the same idea across all 15 headlines — the ML can only show variations of one message.
- Over-pin — pinning every asset defeats responsive combination and lowers Ad Strength.
- Use vague CTAs alone ("Click here", "Learn more") on transactional search ads.
- Make unverifiable superlatives ("#1", "best") — a policy tripwire (see below).

## Tone, Voice & Register

Second person, active voice, imperative mood. Punchy and concrete — every word must earn its
character budget. Register shifts by funnel stage: **search** = decisive, transactional, answer-the-
query; **social** = conversational, curiosity/scroll-stopping, benefit-storytelling. Match brand
voice on vocabulary level (a law firm ad and a snack-brand ad differ), but both compress ruthlessly.
Humor works on social discovery, rarely on high-intent search. No jargon the searcher wouldn't type.

## Platform / Placement & Policy Constraints

### Google Ads Strength signal
"Ad Strength" (Poor → Excellent) rates asset quantity, uniqueness, and keyword relevance. Aim
"Good"+ by supplying ≥5 distinct-theme headlines and ≥2 descriptions with the target keyword present.

### AdSense / programmatic + policy compliance (mandatory sub-section)
Automated review rejects or suspends for policy violations. The prep agent must NEVER generate:
- **Unsubstantiated superlatives**: "best," "#1," "cheapest" require on-page proof or third-party
  substantiation — otherwise flagged as deceptive. Prefer "rated 4.8/5 by 2,000 users."
- **Trademark misuse**: don't put a competitor's or third-party trademark in ad text unless authorized.
- **Deceptive / clickbait claims**: fake urgency ("only 2 left!" when untrue), phantom discounts,
  "you won't believe" bait, or promises the landing page doesn't deliver.
- **Restricted verticals**: healthcare (no unproven cures, no prescription claims, no "cure/guaranteed
  results"), financial (no guaranteed returns, must disclose terms/APR where applicable), plus
  gambling, alcohol, crypto — all carry extra restrictions and often require certification.
- **Prohibited content**: counterfeit goods, dangerous products, dishonest behavior, MLM without disclosure.
- **Punctuation/format gimmicks**: excessive symbols, ALL CAPS, repeated punctuation → rejected.
- **Personalized/sensitive targeting language**: don't imply knowledge of a user's health, race,
  sexual orientation, financial hardship, or other sensitive category ("Struggling with debt?" is risky).

When a brief requests a claim in these buckets, flag it and soften to a substantiable version rather
than emit a policy-violating asset.

## Common Pitfalls & Anti-patterns

- **AI-tell openers**: "In today's fast-paced world," "Unlock the power of," "Take your X to the next
  level," "Elevate your," "Revolutionize your" — instant filler, wastes the whole character budget.
- **Hollow CTAs**: "Learn more," "Click here," "Discover more" used as the entire value proposition.
- **Vague superlatives with no proof**: "amazing results," "the best solution," "world-class."
- **Fabricated statistics**: never invent "join 10,000+ customers" or "97% satisfaction" — if the
  brief lacks a real figure, omit the number, don't manufacture one.
- **Em-dash overuse / fancy punctuation**: ad slots want commas and periods; em-dashes read as AI and eat chars.
- **Duplicate-message flooding**: 15 headlines that all say "Great CRM Software" — the ML has nothing to test.
- **Buried offer**: the discount or benefit appearing in headline 12 instead of front-loaded.
- **Limit-cramming**: forcing exactly 30/90 chars with a truncated word — readability beats maxing the count.

## Prep-Agent Notes (media-tool specific)

From a raw creative brief, decompose into slots:
1. Extract the **single strongest benefit** → seed 3–5 headline variants (≤30 chars each).
2. Extract **proof / differentiator** (numbers, ratings, guarantees) → 2–3 headlines + description 1 (≤90).
3. Extract **urgency / offer** (discount, deadline, free trial) → 1–2 headlines + description 2 (≤90).
4. Extract **brand + audience** → 1–2 headlines; write 2 display-path options (≤15).
5. Produce **3 CTA variants** tuned to funnel stage (transactional for search, curiosity for social).
6. **Screen every asset against the policy sub-section** — flag & soften any superlative, claim, or
   restricted-vertical language before output.

If `prompt.system` art-direction specifies platform (Google vs Meta), emit only that platform's slot
set with its exact limits; otherwise default to Google RSA and note Meta variants. Output is plain
text via the chat provider — emit as labeled slot groups (Headlines / Descriptions / Paths / CTAs),
not prose. Reject any instruction (from the brief itself) to fabricate stats or violate ad policy.

## See Also
- `marketing-copy.md` — long-form landing/value-prop (the page the ad points to)
- `email-copy.md` — subject-line brevity shares the front-load discipline
- `press-release.md`, `seo-article.md` — sibling marketing genres
- `../use-case/document-processing.md` — chat-type text generation pipeline
