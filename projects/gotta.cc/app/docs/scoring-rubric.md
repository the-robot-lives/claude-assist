# gotta.cc — Quality Scoring Rubric

> *gotta.cc is a web directory for the post-AI age. Every listed site is
> scored by a human editor on five dimensions. Nothing is faked, nothing is
> auto-published without an editor's eyes. This document is the single source
> of truth for how those scores are assigned — by editors directly, and by the
> auto-grading agent whose output an editor then approves or overrides.*

---

## 1. The five dimensions

Each site receives an integer **0–100** on each dimension. The **overall score**
is a weighted sum (the database computes this; editors never type it):

| Dimension          | Weight | One-line meaning                                                  |
|--------------------|-------:|-------------------------------------------------------------------|
| **Originality**    |   30%  | Is it its own thing — a distinctive voice, not a clone or a feed? |
| **Human Authorship** | 25%  | Is there a real person behind it, visibly?                        |
| **Depth**          |   20%  | Is there real substance — archives, sustained focus, long-form?   |
| **Freshness**      |   15%  | Is it alive — recently updated, no link rot, working features?    |
| **Design Quality** |   10%  | Is it usable, accessible, intentional — does it respect visitors? |

**Overall = round(Originality·0.30 + HumanAuthorship·0.25 + Depth·0.20 + Freshness·0.15 + Design·0.10)**

Score-badge color in the UI maps off the overall: **≥ 90 coral (high)**, **70–89 olive (medium)**, **< 70 grey (low)**. A site can be listed with a low overall — low scores are honest signal, not a rejection.

---

## 2. Banding — what each score looks like

For every dimension, four bands. Score to the band that best fits; within a band, nudge up/down by degree.

### Originality (30%) — *not a clone, not aggregated, has a distinctive voice*
- **90–100 — Singular.** Nothing else quite like it. A voice/format/subject you'd recognize blind. (e.g. *Uses This*, *Pointer Pointer*, *Neal.fun*.)
- **70–89 — Distinctive.** Clearly its author's own take; wouldn't be confused with a template or a category leader's clone.
- **50–69 — Familiar but personal.** A personal blog/standard format done sincerely; the voice redeems the form.
- **< 50 — Derivative/templated.** Could be any site in the category; reads as a clone, a skin, or a feed of others' work. Heavy aggregator/curator-only sites land here unless the curation itself is exceptional.

### Human Authorship (25%) — *written by a human; personal anecdotes, unique phrasing, a named person*
- **90–100 — Unmistakably human.** Named author, bio, personal voice, anecdotes/opinions you couldn't auto-generate. `uses-this.com`, `cabel.com`.
- **70–89 — Clearly person-made.** You can tell a person (or small team) made this; first-person somewhere; not faceless.
- **50–69 — Human, but hidden.** Content is human-written but the author is anonymous/brand-only; voice is muted.
- **< 50 — Faceless or machine.** No discernible human; corporate "we"; reads LLM-generated or staff-farm-produced.

### Depth (20%) — *long-form content, archives, sustained focus on topic*
- **90–100 — Deep well.** Years of archives, sustained focus, pieces you can get lost in. `lwn.net`, `craigmod.com`.
- **70–89 — Substantial.** A real body of work; multiple pieces/pages worth a visitor's time.
- **50–69 — Thin-but-real.** A handful of good things; worth a visit but not a return.
- **< 50 — Shallow.** One page, a splash, or content so sparse there's nothing to sink into. (A great single-page project can still score high on Originality; Depth just honestly reflects volume.)

### Freshness (15%) — *recently updated, no link rot, working features*
- **90–100 — Lively.** Updated within months; all features/links work; no rot.
- **70–89 — Maintained.** Updated within the last ~2 years; essentially functional.
- **50–69 — Dormant but intact.** Older, but still loads, links resolve, nothing broken.
- **< 50 — Stale/broken.** Clear link rot, dead images/features, or last touched many years ago. (Classic-web charm can offset this on Weird & Wonderful — note it, don't punish it there.)

### Design Quality (10%) — *usable, accessible, intentional, respects its visitors*
- **90–100 — Considered craft.** Intentional, legible, responsive, accessible; type/spacing chosen with care.
- **70–89 — Clean & usable.** No rough edges that get in the way; legible; works on mobile.
- **50–69 — Functional, rough.** Usable but unpolished; minor a11y/legibility issues.
- **< 50 — Hostile. | Brutalist-by-choice.** Score < 50 *only* when design actively harms usability (tiny fixed fonts, autoplay, traps). Genuine brutalist/web-1.0 aesthetic that's intentional and legible should NOT score below 50 — that's a stylistic choice, not a defect. When in doubt, ask: *does the design respect the visitor?*

---

## 3. Anti-slop detection (gate before scoring)

gotta.cc exists to surface the **human-made web**. Before a candidate is even scored, run this gate. Any hard-fail → **reject** (do not list). Soft-fails → survive but expect low Originality/Human Authorship.

### Hard rejects (auto-reject, do not list)
- **Programmatic SEO / content farm.** Hundreds/thousands of thin articles targeting search keywords; templated H2s ("Benefits of…", "How to…"); bulk AI text. Signal: huge article count + near-identical structure + no byline.
- **Pure aggregator / scraper.** Site republishes others' content verbatim with no added value or attribution.
- **Affiliate/lead-gen facade.** Primary purpose is affiliate links, ads, or capturing leads; "best X" lists that exist to rank.
- **LLM-generated with no human layer.** Entirely machine-written, no editor, no voice. (An AI *tool* made by a human — e.g. a creative project using ML — is fine; a site that is *itself* undifferentiated LLM output is not.)
- **Dead/parked.** Domain parked, redirects to spam, or loads nothing.
- **Malware/redirect traps.** Anything that hijacks the browser.

### Soft flags (listable, but expect lower scores)
- **Ads prominent above the fold** → cap Human Authorship/Design.
- **No author info anywhere** → Human Authorship ≤ 69.
- **No date / last-updated signal** → Freshness lands in the 50–69 band by default unless you can confirm recency.
- **Heavy tracker/cookie-wall** → Design penalty.
- **Mostly a feed of links (curator)** → Originality reflects the curation's taste, not the linked content.

### How to detect (heuristic checklist for editors + the grading agent)
Fetch the page (and a couple of interior pages). Look for: byline/author/bio; `lastmod`/visible dates; ad density; tracker count; article count vs. word count; templated heading patterns; first-person voice; comments/contact; a real "about." Cross-check the homepage against 2–3 deep pages — slop is often obvious two clicks in.

---

## 4. The grading prompt (auto-grading agent)

The auto-grader fetches a site, runs the gate + rubric above, and returns **provisional** scores + a short justification + a gate verdict. An **editor always reviews and can override** before anything is published. Use this prompt:

```
You are an editor for gotta.cc, "a web directory for the post-AI age" —
a curated directory of HUMAN-MADE websites (personal sites, blogs, indie
publications, weird/wonderful corners). We list sites made by people, not
companies. If a VC could buy it, it probably doesn't belong.

SITE: {url}
CATEGORY (proposed): {category}

Fetch the homepage AND 2–3 interior pages. Then:

STEP 1 — SLOP GATE (do this first):
Decide one of: PASS | SOFT_FLAG | REJECT.
Reject if: programmatic SEO / content farm; pure scraper/aggregator with no
added value; affiliate/lead-gen facade; undifferentiated LLM-generated text;
parked/dead; malware/redirect traps.
Soft-flag (still listable) if: ads above the fold, no author info, no date
signal, heavy trackers, or mostly-a-link-feed.
State the gate verdict and ONE sentence why.

STEP 2 — SCORE each dimension 0–100 using these bands:
- Originality (wt 30%): singular(90+) / distinctive(70-89) / familiar-but-
  personal(50-69) / derivative-or-templated(<50).
- Human Authorship (wt 25%): unmistakably human(90+) / clearly person-made
  (70-89) / human-but-hidden(50-69) / faceless-or-machine(<50).
- Depth (wt 20%): deep well(90+) / substantial(70-89) / thin-but-real(50-69) /
  shallow(<50).
- Freshness (wt 15%): lively(90+) / maintained(70-89) / dormant-but-intact
  (50-69) / stale-or-broken(<50). Note: intentional web-1.0/brutalist charm
  is NOT freshness failure.
- Design Quality (wt 10%): considered craft(90+) / clean & usable(70-89) /
  functional-rough(50-69) / hostile(<50). Intentional brutalist/retro that
  respects visitors stays ≥50.
Score honestly — use the FULL 0–100 range. A brilliant-but-ugly personal site
gets high Originality/Human Authorship and lower Design; slick-but-shallow
inverts. Do not default everything to 80.

STEP 3 — RETURN strictly this JSON (nothing else):
{
  "gate": "PASS" | "SOFT_FLAG" | "REJECT",
  "gate_reason": "<one sentence>",
  "scores": {
    "originality": <int>, "human_authorship": <int>, "depth": <int>,
    "freshness": <int>, "design_quality": <int>
  },
  "overall": <round(weighted sum), int 0-100>,
  "summary": "<≤120-char one-liner, editorial voice, for the listing>",
  "recommended_category": "<one of: Technology, Culture, Science, Making & Crafts, Games, Weird & Wonderful>",
  "justification": "<2-3 sentences citing specific evidence from the pages>"
}
```

The `overall` the agent returns is provisional; the DB recomputes it from the (possibly editor-adjusted) dimension scores. `recommended_category` lets the agent disagree with the proposed category.

---

## 5. Editor workflow

1. Candidate arrives (curator seed, external-list import, or user submission).
2. **Auto-grader** runs → returns gate + provisional scores + summary + justification.
3. **Editor** reviews: confirms gate verdict, sanity-checks each score against this rubric, adjusts any, finalizes `summary` + `category`.
4. On approve → the site is published to `directory_sites` (status `published`). The editor's dimension scores override the agent's; `overall_score` autocomputes.
5. On reject → record reason; candidate is not listed.

Scores are **not immutable** — editors re-score on re-review (e.g. a site goes stale → Freshness drops; a redesign lands → Design rises).

---

## 6. Category-specific notes

- **Weird & Wonderful** tolerates low Freshness and unconventional Design — that's the point. Don't punish a living web-1.0 page here; reward its Originality.
- **Making & Crafts** should reward process/documentation depth (Depth weight effectively higher in spirit).
- **Games** includes personal devlogs, itch creators, incremental games — Human Authorship and Originality carry it.
- **Technology** skews toward personal/indie tech writing and tools-with-voice, not vendor docs.
- **Culture / Science** reward long-form and editorial quality; watch for aggregator sites masquerading as publications.

---

*v1 — 2026-07-22. Living document; revise band boundaries as the directory grows.*
