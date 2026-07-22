# Marketing Copy — long-form persuasion (landing pages, value props)

Longer-form conversion writing that lives on a page rather than in an ad slot: landing-page heroes,
value-proposition blocks, benefit sections, and sales narratives. Unlike ad copy (which buys the
click), marketing copy earns the *conversion* once the reader arrives — it has room to build a case,
handle objections, and stack proof. Good marketing copy is benefit-led, scannable, and moves the
reader through a persuasion arc; bad marketing copy is a wall of feature bullets, hedged claims, and
generic enthusiasm that could describe any competitor.

**Output form**: markdown or structured (hero / sections / CTA blocks)
**Typical length**: hero 15–60 words; full landing page 300–1,200 words in labeled blocks
**Routed via**: `text_format: marketing-copy` (chat-type generation)

## Genre Conventions & Structure

### Landing-page hero (above the fold — the highest-value real estate)
- **Headline**: the single clearest promise, 6–12 words. States the outcome, not the product category.
- **Subhead**: 1–2 sentences that add the *how* or *for whom*, and pre-empt the first objection.
- **Primary CTA**: one action verb button ("Start free trial", "Book a demo").
- **Optional trust strip**: logos, rating, or a one-line social-proof stat directly under the CTA.

### Proven persuasion frameworks (pick one as the page spine)
- **AIDA** — Attention (headline hook) → Interest (relevant benefit) → Desire (proof + emotion) → Action (CTA).
- **PAS** — Problem (name the pain) → Agitate (make it vivid/costly) → Solve (your product as the resolution).
- **BAB** — Before (current struggle) → After (desired state) → Bridge (your product connects them).
- **FAB** — Feature → Advantage → Benefit, per capability block (always end on the benefit).

### Value-proposition block
A value prop answers "why you, why now, over the alternative." Structure: **headline benefit** +
**2–4 sub-benefits** (each benefit-over-feature) + **differentiator** (what only you do).

### Standard landing-page section order
1. Hero (headline/subhead/CTA) → 2. Social proof strip → 3. Problem/agitation → 4. Solution + core
benefits → 5. Feature-to-benefit blocks → 6. Objection handling / FAQ → 7. Testimonials/case proof →
8. Pricing or offer → 9. Final CTA (restate the promise). Repeat the CTA every ~1.5 screens.

## Hard Constraints

Marketing copy has fewer *hard* character caps than ad slots, but these conventions are checkable:
- **Hero headline**: ≤12 words / ~70 chars — longer and it stops scanning as a headline.
- **CTA button label**: 2–5 words, starts with a verb; never a full sentence.
- **Reading level**: target US **grade 6–8** (Flesch-Kincaid) for broad B2C; grade 9–11 acceptable
  for technical B2B. Above grade 12 depresses conversion.
- **Paragraphs**: ≤3 sentences on landing pages (scannability). Sentences average ≤20 words.
- **One primary CTA action** per page (secondary/ghost CTA allowed, but a single conversion goal).
- **Benefit-before-feature**: every feature claim must resolve to a reader outcome in the same block.

## How-To (worked recipes)

### How to turn a feature into a benefit
Apply the "so what?" test until you reach an outcome the reader feels.
- Feature: "256-bit AES encryption." → so what? → "Your customer data is unreadable to attackers." →
  so what? → **"Sleep at night knowing a breach can't expose your customers."** ← ship this.

### How to write a PAS section that doesn't feel manipulative
Name a real, specific pain; agitate with consequence, not fear-mongering; solve with a concrete mechanism.
- P: "Your team rebuilds the same report every Monday."
- A: "That's 4 hours a week — 200 hours a year — spent copying cells instead of deciding anything."
- S: "AcmeReports refreshes it automatically at 6 a.m. You open Monday to a finished dashboard."

### How to write a hero that passes the 5-second test
A first-time visitor must answer three questions in five seconds: *What is it? Is it for me? What do I
do next?* Draft: headline = outcome, subhead = for-whom + how, CTA = next step.
- Headline: "Ship your app 2× faster." Subhead: "The CI/CD platform built for small teams that can't
  afford a DevOps hire." CTA: "Start free — no card required."

### How to place social proof where it defeats the objection
Put proof adjacent to the claim it supports, not in a lonely testimonial ghetto. A pricing objection
gets a "cancel anytime, 30-day refund" line at the CTA; a trust objection gets the logo strip in the
hero; an efficacy objection gets the outcome-stat testimonial beside the benefit.

### How to handle an objection without raising it awkwardly
Pre-empt in the subhead or a mini-FAQ. Objection "too hard to switch" → subhead adds "migrate your
data in one click." Convert the top 3 sales objections into affirmative benefit lines or FAQ entries.

### How to write a benefit stack that builds instead of listing
Order benefits by emotional weight, not feature order. Lead with the outcome the reader most wants,
support with the one that removes their biggest fear, close with the one that makes it feel easy.
- 1. "Get paid 9 days faster." (the want) → 2. "Never chase an invoice again." (the pain removed) →
  3. "Set it up in an afternoon." (the friction removed). Each line earns the next.

## Worked Example — a landing page in blocks

A real-form landing page for a fictional invoicing tool, emitted as labeled markdown blocks the
renderer maps to page components. PAS spine, one CTA, proof beside the claim.

```markdown
# HERO
## Get paid 9 days faster — without chasing a single invoice
AcmeInvoice sends, tracks, and follows up on every invoice automatically, so freelancers and small
studios stop doing collections and get back to the work they're actually paid for.
[ Start free — no card required ]
★ 4.8/5 from 3,000+ freelancers

# PROOF STRIP
Trusted by studios at Pentagram, Huge, and 3,000 independent designers.

# PROBLEM (P)
You finished the work weeks ago. The invoice is still unpaid. Now you're writing an awkward
"just following up" email instead of starting the next project.

# AGITATE (A)
The average freelancer waits 34 days to get paid and spends 5 hours a month chasing invoices —
that's 60 hours a year of unpaid admin, and the client relationship gets tense every time.

# SOLVE (S)
AcmeInvoice sends the invoice, tracks when it's opened, and sends polite, on-brand reminders on a
schedule you set. You never send another follow-up. Most users are paid 9 days sooner.

# BENEFITS
- **Get paid faster** — automated reminders cut payment time by an average of 9 days.
- **Never chase again** — the awkward follow-up email writes and sends itself.
- **Set it up in an afternoon** — import clients, pick a reminder cadence, done.

# OBJECTIONS (mini-FAQ)
- *Will my clients feel nagged?* Reminders are polite, on-brand, and stop the moment they pay.
- *Hard to switch?* Import your client list in one click; keep your existing bank and accounting tool.

# CLOSING CTA
## Stop chasing. Start getting paid.
[ Start free — no card required ]  ·  Cancel anytime · 30-day refund
```

Why it works: hero passes the 5-second test (what/for-whom/next step); PAS builds tension then resolves
it; every benefit is an outcome; proof sits in the hero and the benefit line; objections pre-empted; one
CTA repeated; no fabricated stats — the numbers are placeholders the human confirms.

## Do's and Don'ts

### ✅ Do
- Lead with the reader's outcome; make them the hero, your product the guide.
- Use "you/your" far more than "we/our" — customer-centric beats company-centric.
- Anchor every benefit in something concrete: a number, a time saved, a before/after.
- Keep one conversion goal per page; make the CTA impossible to miss and repeat it.
- Write scannably: short paragraphs, subheads, bulleted benefits, bold key phrases.

### ❌ Don't
- List features without translating each to a benefit — readers buy outcomes, not specs.
- Hedge with "may," "could help," "designed to" — weak modality kills persuasion.
- Bury the CTA or offer 5 competing actions — decision paralysis lowers conversion.
- Write company-first ("We are a leading provider of…") — nobody arrives caring about you.
- Pad with adjectives instead of proof ("powerful, innovative, seamless" prove nothing).

## Tone, Voice & Register

Second person, confident, active voice, present tense. Warmer and more narrative than ad copy — you
have room for a sentence of story — but never rambling. Register tracks the brand and audience: B2B
SaaS is credible-and-crisp, DTC lifestyle is intimate-and-aspirational, enterprise is authoritative-
and-proof-heavy. Emotion is a tool: name the frustration or the aspiration in the reader's own words.
Confidence without arrogance; specificity without jargon.

## Platform / Placement Constraints

- **Above the fold**: hero must fully deliver its promise before any scroll; assume the reader never scrolls.
- **Mobile-first**: ~50%+ of traffic is mobile — headlines wrap, so front-load; CTA must be thumb-reachable.
- **Markdown vs HTML rendering**: emit clean markdown (H1 hero, H2 sections, bullet benefits) so the
  downstream renderer maps blocks to page components; don't hand-code layout.
- **Scannability budget**: readers consume in an F-pattern — first two words of each line and each
  subhead carry the load. Design copy for skimming, reward deep reading.
- **Localization**: English is compact; German/French run ~20–30% longer — leave headline headroom.

## Common Pitfalls & Anti-patterns

- **AI-tell openers**: "In today's fast-paced/digital world," "In an era of," "Imagine a world where,"
  "We live in a time when" — delete on sight; start with the reader's benefit.
- **Corporate-hype vocabulary**: "cutting-edge," "state-of-the-art," "seamless," "robust," "leverage,"
  "synergy," "best-in-class," "game-changing," "revolutionary," "unlock/unleash the power of."
- **Feature-dump with no benefit**: bullet lists of specs that never answer "so what for me?"
- **Vague superlatives / fabricated stats**: "trusted by thousands" with no source; invented percentages.
- **Hollow CTAs**: "Learn more," "Get started" with no value context; or five CTAs competing.
- **Em-dash overuse and tricolon spam**: "fast, simple, and powerful" repeated in every block reads as AI.
- **Symmetrical AI rhythm**: every sentence the same length; "It's not just X, it's Y" construction.
- **Hedged claims**: "designed to potentially help improve" — commit or cut.

## Prep-Agent Notes (media-tool specific)

From a raw creative brief:
1. Identify the **one core value proposition** → hero headline + subhead + primary CTA.
2. Extract the **audience + top pain** → choose framework (PAS if pain-led, AIDA if discovery-led,
   BAB if transformation-led) and build the page spine.
3. Map each **feature** through the "so what?" test → benefit blocks (feature-to-benefit).
4. Collect **proof assets** (stats, logos, testimonials, guarantees) → place each beside the claim it defends.
5. Enumerate the **top 3 objections** → convert to affirmative lines or a short FAQ.
6. Restate the promise at a **closing CTA**.

If `prompt.system` art-direction sets brand voice or reading level, honor it; otherwise default to
grade 6–8, second person, benefit-led. Emit labeled markdown blocks (Hero / Proof / Problem / Solution /
Benefits / Objections / CTA) so the renderer can assemble a page. Output is plain markdown via the
chat provider. If the brief supplies no real proof numbers, write benefit copy that doesn't rely on
fabricated stats rather than inventing them.

## See Also
- `ad-copy.md` — the ad that drives traffic to this page (message-match the hero to the ad)
- `email-copy.md` — nurture copy sharing the benefit-led discipline
- `seo-article.md`, `press-release.md` — sibling marketing genres
- `../use-case/document-processing.md` — chat-type text generation pipeline
