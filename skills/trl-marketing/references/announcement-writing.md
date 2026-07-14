# Announcement Writing

How to write the announcement set: release posts, changelogs-as-marketing, and demo scripts. All copy derives from the message hierarchy in `positioning-and-messaging.md` — never invent new framing here.

## The Announcement Set

A launch or major release ships a *set*, not a post. Standard set:

| Piece | Length | Home | Derived From |
|-------|--------|------|--------------|
| Release post | 400-800 words | Blog / product site | Paragraph + pillars + proof |
| Changelog entry | 50-150 words | /changelog, GitHub Releases | Release post, compressed |
| X launch thread | 5-8 posts | X | Pillars, one per post |
| LinkedIn post | 150-250 words | LinkedIn | POV + story angle |
| Community post | Per-community norms | Reddit/Discord | Story + lessons angle |
| Demo script | 60-120 seconds | Video/GIF for all of the above | Core loop only |

## Release Post Structure

The release post is the canonical artifact — everything else links back to it (with UTMs).

```
1. Lede (2-3 sentences)   — What shipped + the job outcome. No throat-clearing,
                            no "we're excited to announce."
2. Why (1 paragraph)      — The trigger/pain, in the user's words (from JTBD intake).
3. What it does (3 blocks)— One per benefit pillar: claim → 2-3 sentences of
                            mechanism → screenshot/GIF/code block as proof.
4. How to try it (1 block)— Exact commands or steps. Copy-pasteable. <60 seconds
                            to first value.
5. What's next + ask      — 2-3 roadmap items and one specific feedback request.
```

**Lede examples (fictional CLI `shipctl` v2.0):**

Bad: "We're thrilled to announce shipctl 2.0, our biggest release yet, packed with features our community has been asking for."

Good: "shipctl 2.0 adds instant rollbacks: `shipctl rollback` returns your app to any previous deploy in under five seconds. It also cuts median deploy time from 90 to 30 seconds and adds monorepo support."

The bad lede contains zero information. The good lede is quotable by a newsletter without edits — write ledes that do journalists' work for them.

## Changelog as Marketing

Changelogs are read by your most engaged users and skimmed by evaluators checking if the project is alive. Rules:

| Rule | Bad | Good |
|------|-----|------|
| Lead with user outcome, not internals | "Refactored deploy queue to use worker pools" | "Deploys are 3x faster — median 30s, down from 90s" |
| Name who it's for when scoped | "Added --filter flag" | "Monorepo users: deploy a single package with `shipctl up --filter api`" |
| Show, inline | prose only | one-line code sample or 5s GIF per notable item |
| Credit reporters | (silence) | "Fixes #214 — thanks @user for the repro" |
| Date + version every entry | rolling undated blob | "## v2.1.0 — 2026-07-15" |

**Cadence trick for small teams:** a monthly "What shipped in [Month]" roundup post is a full marketing beat assembled from changelog entries you already wrote — near-zero marginal cost, signals momentum, and gives existing users share-fodder.

## Demo Script (60-120s)

The demo GIF/video is the highest-leverage launch asset — it's the PH gallery lead, the X thread anchor, and the landing-page hero.

```
0:00-0:05  Cold open on the pain: the 40-line deploy script scrolling past.
0:05-0:10  Title card / one-liner: "One command. Zero YAML."
0:10-0:50  The core loop, real-time, no cuts: `shipctl up` → build output →
           live URL opens in browser. Real-time matters — speed IS the pitch.
0:50-1:10  One differentiator moment: `shipctl rollback` → app reverts in 5s.
1:20       End card: install command + URL. Nothing else.
```

**Rules:**
- One loop, not a tour. Feature tours are for docs.
- If the real flow takes >90s, your demo problem is a product problem.
- Terminal demos: large font (16pt+), high contrast, `--no-color` off, trim dead air but label any cuts ("2 min build, trimmed").
- Export a <10MB GIF of the 0:10-0:50 segment for X/PH/README; keep full video for the release post and YouTube.

## Platform Copy Derivations

From one release post, derive (details per-platform in `social-campaign-patterns.md`):

**X thread opener** (the only post most people see — spend 80% of thread time here):
> Your deploy script has more lines than your app.
>
> shipctl 2.0 is out: one-command deploys, now with 5-second rollbacks and monorepo support. [GIF]

**PH tagline + first-comment opener:**
> Tagline: "One-command deploys. Zero YAML."
> First comment: "I built shipctl after counting 200+ lines of deploy scripts across my side projects…"

**LinkedIn opener (story-first):**
> I shipped five side projects last year. Every one of them had the same 40 lines of fragile deploy scripting. So I built the tool I wanted…

## Announcement Quality Checklist

- [ ] Lede is quotable verbatim by a third party
- [ ] Every claim has a number, demo, or quote attached
- [ ] Try-it block is copy-pasteable and <60s to value
- [ ] All phrasing matches the message hierarchy (no new taglines invented)
- [ ] Every link carries UTMs (`launch-metrics.md`)
- [ ] One specific ask, not "let us know what you think"
- [ ] No "excited to announce," "game-changer," "revolutionize," or emoji walls
