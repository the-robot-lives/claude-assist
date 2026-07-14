---
name: trl-marketing
description: >
  Product marketing and launch execution: positioning, messaging, go-to-market (GTM)
  planning, and announcement campaigns. Use this skill (or /trl-marketing) to launch a
  product, position or message it, plan a Product Hunt or Hacker News launch, write
  announcements or a press release, run a social campaign, promote a release, or write
  landing-page copy — even if they don't say "marketing." Also trigger on: launch, GTM,
  press kit, publicity, demo script, changelog marketing. NOT for SEO (trl-seo-guru),
  newsletters (trl-content-publishing), niche validation (trl-market-intelligence),
  page design (trl-user-experience-engineer), or pricing (trl-monetization-strategy).
---

# Marketing

Position, package, and launch products so the right people hear about them at the right moment — from messaging framework through launch week execution and retro.

## Overview

The Marketing skill turns a finished (or nearly finished) product into a launch: a positioning statement people repeat, announcements people share, and a launch sequence that compounds across channels instead of fizzling in one post. It is built for solo developers and small teams shipping portfolio products (codefre.sh, derobot.is, aifighter.com, gotta.cc, iotgo.io) and skills/tools-as-products. It provides:

- **Positioning & messaging frameworks** — jobs-to-be-done analysis, category point-of-view, message hierarchy from headline to feature bullet
- **Launch planning** — launch-type selection (soft launch, Product Hunt, Hacker News, community-first, staged rollout) with timeline-phased checklists
- **Announcement writing** — changelogs-as-marketing, release posts, demo scripts, and platform-native launch copy
- **Social campaign execution** — X/LinkedIn/Reddit/Discord/Bluesky content patterns, thread architecture, and cadence planning
- **Press & outreach** — press kits, embargo mechanics, and influencer/dev-advocate outreach sequences
- **Launch measurement** — activation funnels, UTM discipline, and structured launch retros that feed the next launch

## Core Philosophy

**Five Principles:**

1. **Positioning before promotion** — A launch amplifies your message; it cannot create one. If you can't state who it's for, what job it does, and why it beats the alternative in two sentences, fix that before scheduling anything.
2. **Launch is a sequence, not a day** — Momentum comes from staged beats: private beta → soft launch → community launch → main launch → follow-up wave. One-day launches waste the asset you built.
3. **Platform-native or invisible** — A press release pasted into Reddit dies. Each channel gets content shaped to its norms: show-don't-tell on HN, tagline-plus-GIF on Product Hunt, thread architecture on X.
4. **The changelog is a marketing channel** — Every release is an announcement opportunity. Small teams win by shipping visibly and narrating the work, not by big-bang campaigns.
5. **Measure the funnel, not the applause** — Upvotes and impressions are inputs. Signups, activation, and week-one retention are outputs. Every link gets a UTM; every launch gets a retro.

## When to Use This Skill

- **Positioning a new product** — You built something and need to articulate who it's for and why it matters
- **Planning a launch** — Choosing between soft launch, Product Hunt, HN Show HN, or community-first, and sequencing the beats
- **Writing announcements** — Release posts, changelog entries worth sharing, launch tweets, demo scripts
- **Running a social campaign** — Multi-day, multi-platform promotion around a launch or major release
- **Press and outreach** — Assembling a press kit, pitching newsletters/podcasts, recruiting dev advocates
- **Landing-page messaging** — Headline/subhead/CTA copy hierarchy (copy only — not page design)
- **Post-launch analysis** — Activation funnel review, UTM attribution, launch retro

> For search-engine and AI-answer-engine optimization of your launch content, see **trl-seo-guru** (`SKILL.md`).
> For newsletters, tutorials, and long-term audience building, see **trl-content-publishing** (`SKILL.md`).
> For validating that a niche or audience exists before you build and launch, see **trl-market-intelligence** (`SKILL.md`).
> For landing-page visual design, wireframes, and component implementation, see **trl-user-experience-engineer** (`references/outputs/landing-pages.md`).
> For pricing models and monetization stream selection, see **trl-monetization-strategy** (`SKILL.md`).

## Launch-Type Selection

Pick the launch type before writing a word of copy — it determines timeline, assets, and tone.

| Launch Type | Best For | Timeline | Key Asset | Risk |
|-------------|----------|----------|-----------|------|
| **Soft launch** | Unproven product, need real-usage feedback | 1-2 weeks | Working onboarding + feedback channel | Low — quiet by design |
| **Show HN** | Dev tools, technical products, open source | 1 day + 1 week prep | Honest technical post + live demo | Comment scrutiny; no do-overs for 6-12 months |
| **Product Hunt** | Consumer/prosumer SaaS, visual products | 1 day + 3 weeks prep | Tagline, gallery, first-comment story | Algorithm/timing variance; needs upvote network |
| **Community-first** | Products serving an existing community (Reddit/Discord) | 2-4 weeks | Genuine participation history + value post | Ban risk if you skip the participation |
| **Staged rollout** | Products with capacity limits or activation risk | 4-8 weeks | Waitlist + invite-wave comms | Momentum loss between waves |
| **Changelog cadence** | Existing product, continuous releases | Ongoing | Release posts worth sharing | Requires shipping rhythm |

Most portfolio products should run **soft launch → community launch → Show HN or PH main launch**, in that order. Details, decision tree, and per-type playbooks: `references/launch-playbook.md`.

## Channel Selection

| Channel | Audience | Format That Works | Cadence | Kill Signal |
|---------|----------|-------------------|---------|-------------|
| **X (Twitter)** | Dev/indie-hacker, fast-moving | Build-in-public threads, demo GIFs, launch thread | 3-5x/week during launch window | <1% engagement after 10 posts |
| **LinkedIn** | B2B, hiring managers, enterprise | Narrative posts (lesson + product), native video | 2-3x/week | No comments from target buyers |
| **Reddit** | Niche communities, skeptics | Value-first posts, honest "I built X" with lessons | Per-subreddit rules; sparse | Downvotes / mod removal |
| **Hacker News** | Technical early adopters | Show HN, substantive technical writeups | Rare — save for launches | Front-page miss is fine; flagged is not |
| **Discord/Slack communities** | Engaged niche users | Show-and-tell channels, genuine help + soft mention | Continuous participation | Called out for drive-by promo |
| **Bluesky/Threads/Mastodon** | Early-adopter tech, X-diaspora | Same as X, less thread-centric | Cross-post from X, adapt | Negligible traffic after 4 weeks |
| **Newsletters/podcasts (earned)** | Whoever the operator reaches | Pitch + press kit + exclusive angle | Per-launch outreach | <10% pitch response after 20 sends |

Pick 2 primary + 1 experimental channel per launch. Platform-native copy patterns: `references/social-campaign-patterns.md`.

## Message-Market Fit Matrix

Match message emphasis to how aware the audience is of the problem and of you:

| Audience State | Lead With | Headline Pattern | Example (fictional CLI `shipctl`) |
|----------------|-----------|------------------|-----------------------------------|
| **Unaware of problem** | The pain, dramatized | "You're doing X wrong" / cost framing | "Your deploy scripts are 40 lines of duct tape" |
| **Problem-aware** | The job to be done | "Finally, [outcome] without [pain]" | "One-command deploys without writing CI YAML" |
| **Solution-aware** | Differentiation vs. category | "[Category], but [key difference]" | "Like a deploy pipeline, but it lives in your terminal" |
| **Product-aware** | Proof + urgency | Numbers, testimonials, what's new | "shipctl 2.0: deploys 3x faster, now with rollbacks" |
| **Existing users** | Momentum + insider status | Changelog narrative, roadmap | "What we shipped this month (and what's next)" |

Full framework with jobs-to-be-done intake and message hierarchy: `references/positioning-and-messaging.md`.

## Launch Workflow

```
Phase 0: Position     Phase 1: Prepare      Phase 2: Soft       Phase 3: Main         Phase 4: Sustain
(1 week)              (T-30 → T-7)          (T-7 → T-0)         (T-0 → T+3)           (T+7 →)
─────────────         ─────────────         ─────────────       ─────────────         ─────────────
JTBD interviews/      Launch type chosen    Private/beta users  Announcement live     Retro (T+7)
 self-audit           Assets drafted        Feedback loop       Founder present in    Changelog cadence
Positioning stmt      Press kit built       Fix onboarding       comments all day     Follow-up content
Message hierarchy     Outreach list warm    Seed testimonials   Cross-post wave       Next-beat planning
Landing copy          UTMs assigned         Dry-run demo        Metrics live
```

## Quick Start Guides

### Path 1: "I built something, help me launch it" (full launch, ~4 weeks)
1. Fill out `assets/messaging-worksheet.md` — product, audience, job-to-be-done, alternatives
2. Draft positioning statement and message hierarchy (`references/positioning-and-messaging.md`)
3. Select launch type from the Launch-Type Selection table; copy `assets/launch-checklist.md` and set dates
4. Write the announcement set — release post, launch thread, platform posts (`references/announcement-writing.md`)
5. Execute launch week per the checklist; run the retro at T+7 (`references/launch-metrics.md`)

### Path 2: "Announce this release" (single announcement, ~1 day)
1. Identify the audience state (Message-Market Fit Matrix) — usually product-aware or existing users
2. Write changelog-as-marketing entry + one platform-native post per active channel (`references/announcement-writing.md`)
3. Add UTM tags, post, engage with replies for 24 hours, log metrics in `assets/project-tracker.md`

### Path 3: "Write my landing-page copy" (~half day)
1. Complete the positioning sections of `assets/messaging-worksheet.md`
2. Build the copy hierarchy — headline, subhead, CTA, three benefit blocks, objection row (`references/positioning-and-messaging.md`, "Landing-Page Copy Hierarchy")
3. Hand copy to **trl-user-experience-engineer** for page design and implementation

## Reference Guide

### When to Read Each Reference

| Task | Read These |
|------|-----------|
| **Position or message a product; landing copy** | `positioning-and-messaging.md` |
| **Choose launch type; plan the sequence** | `launch-playbook.md` |
| **Write release posts, changelogs, demo scripts** | `announcement-writing.md` |
| **Plan platform posts, threads, cadence** | `social-campaign-patterns.md` |
| **Build press kit; pitch newsletters/advocates** | `press-and-outreach.md` |
| **Set up funnels, UTMs; run the retro** | `launch-metrics.md` |
| **See it all end-to-end** | `worked-example-devtool-launch.md` |
| **Run a workflow as an agent** | `agent-playbook.claude-code.md` |

All reference paths are relative to `references/`.

## Related Skills

- **trl-seo-guru** — Optimizes launch content and landing pages for search and AI answer engines; hand off announcement URLs post-launch
- **trl-content-publishing** — Long-term audience building via newsletters and articles; the launch audience becomes its subscriber base
- **trl-market-intelligence** — Validates the niche and audience *before* you position; feeds the messaging worksheet
- **trl-user-experience-engineer** — Designs and implements the landing page this skill writes copy for
- **trl-monetization-strategy** — Chooses pricing and revenue streams; pricing appears in messaging but is decided there
- **trl-conversion-engineer** — Sequences marketing efforts across multiple products/streams

## Bundled Resources

### References
- [agent-playbook.claude-code.md](references/agent-playbook.claude-code.md) — Agent role + executable workflows (position, plan launch, write announcements, run campaign)
- [positioning-and-messaging.md](references/positioning-and-messaging.md) — JTBD intake, positioning statements, category POV, landing-page copy hierarchy
- [launch-playbook.md](references/launch-playbook.md) — Per-launch-type playbooks, timelines, decision tree
- [announcement-writing.md](references/announcement-writing.md) — Release posts, changelog-as-marketing, demo scripts, launch copy
- [social-campaign-patterns.md](references/social-campaign-patterns.md) — Platform-native patterns for X, LinkedIn, Reddit, Discord, HN, Bluesky/Threads
- [press-and-outreach.md](references/press-and-outreach.md) — Press kits, embargoes, influencer/dev-advocate outreach
- [launch-metrics.md](references/launch-metrics.md) — Activation funnels, UTM discipline, launch retro template
- [worked-example-devtool-launch.md](references/worked-example-devtool-launch.md) — End-to-end launch of a fictional CLI product

### Assets
- [project-tracker.md](assets/project-tracker.md) — Launch pipeline and metrics tracking template
- [launch-checklist.md](assets/launch-checklist.md) — Fillable T-30/T-7/T-0/T+7 launch checklist
- [messaging-worksheet.md](assets/messaging-worksheet.md) — Positioning intake form (product, audience, JTBD, alternatives, proof)
