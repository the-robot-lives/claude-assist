# Launch Metrics

Instrumentation and analysis for launches: the activation funnel, UTM discipline, and the T+7 retro. Principle: applause metrics (upvotes, impressions) are diagnostic inputs; the funnel is the outcome.

## The Launch Funnel

Define these five stages *before* T-0, with a concrete event for each:

| Stage | Definition (make it binary) | shipctl Example | Typical Launch-Week Rate |
|-------|----------------------------|-----------------|--------------------------|
| **Reach** | Saw a launch asset | Impressions across channels | — (baseline) |
| **Visit** | Landed on your page | Unique visitors to site | 1-5% of reach |
| **Signup** | Gave you something (email, install, star) | `brew install shipctl` or account created | 3-10% of visits |
| **Activation** | Experienced core value once | First successful `shipctl up` | 20-50% of signups |
| **Retention** | Came back within 7 days | Second deploy within 7 days | 20-40% of activated |

**The metric that matters most for a first launch is activation rate.** High signups + low activation means the launch worked and the onboarding didn't — a fixable, valuable finding. Define your activation event now, in writing, in the launch plan.

**Minimum viable instrumentation (solo-dev):** a privacy-respecting analytics tool (Plausible/Umami/PostHog) on the site + one server-side or CLI-side counter for the activation event + a spreadsheet. Do not build a dashboard during launch week.

## UTM Discipline

Every link you place gets UTM parameters, or channel attribution is guesswork forever.

**Scheme (lowercase, hyphenated, no spaces):**

```
?utm_source=<platform>      x | linkedin | reddit | hn | producthunt | discord |
                            bluesky | newsletter-<name> | podcast-<name>
&utm_medium=<placement>     social | community | email | referral | press
&utm_campaign=<beat>        launch-2026-07 | v2-release | ph-launch
&utm_content=<variant>      thread-post-7 | first-comment | bio-link  (optional)
```

**Examples:**
- X thread CTA post: `?utm_source=x&utm_medium=social&utm_campaign=launch-2026-07&utm_content=thread-post-7`
- PH first comment: `?utm_source=producthunt&utm_medium=community&utm_campaign=launch-2026-07`
- Newsletter pitch win: `?utm_source=newsletter-console&utm_medium=press&utm_campaign=launch-2026-07`

**Rules:**
- Maintain the link table in `assets/project-tracker.md` — one row per placed link, created *when you place it*.
- Never UTM internal links (it overwrites the original attribution).
- HN caveat: many HN users strip UTMs, and Show HN links should be clean anyway — post the bare URL and attribute HN by referrer instead.
- Shorten long UTM'd links where platforms truncate, but keep params intact.

**Attribution honesty:** dark social (Discord DMs, copy-paste) will show as "direct." Referrer + UTM + a "how did you hear about us?" question at signup triangulates well enough. Don't over-engineer.

## Launch-Day Dashboard (Manual Is Fine)

Track at T+4h, T+12h, T+24h, T+72h — a table in the tracker:

| Checkpoint | Reach | Visits | Signups | Activated | Top Source | Note |
|-----------|-------|--------|---------|-----------|------------|------|
| T+4h | | | | | | |
| T+24h | | | | | | |
| T+72h | | | | | | |

Watching in real time is only allowed to serve one purpose: doubling down on the channel that's working *today* (e.g., HN comment thread is hot → stay there, cancel the afternoon LinkedIn post).

## The T+7 Retro

One hour, written, filed as `marketing/{product}/retro-{date}.md`. Skipping the retro forfeits the launch's second-most-valuable output.

**Template:**

```markdown
# Launch Retro — {product} — {date}

## Numbers vs. Expectations
| Stage | Target | Actual | Delta |
|-------|--------|--------|-------|
| Visits | | | |
| Signups | | | |
| Activation | | | |
| 7-day retention | | | |

## Channel Attribution
| Channel | Visits | Signups | Activated | Effort (hrs) | Verdict (keep/change/drop) |
|---------|--------|---------|-----------|--------------|---------------------------|

## What Worked (top 3, with evidence)
## What Failed (top 3, with evidence)
## Surprises (unplanned wins/losses — dark-social spikes, unexpected audience)
## Message Check
- Which phrasing got quoted back by strangers? (that's your real tagline)
- Which claim drew skepticism? (needs proof or removal)
## Decisions for Next Beat
- KEEP: ...
- CHANGE: ...
- TRY: ...
## Next beat + date:
```

**Retro rules:**
- Evidence over vibes: every "worked/failed" claim cites a number or a quote.
- Effort column is mandatory — a channel with 10 signups at 1 hour beats one with 30 at 20 hours.
- The "message check" feeds `positioning-and-messaging.md` revisions: launches are positioning experiments.

## Benchmarks for Calibration (Solo Dev, 2026)

| Outcome | Modest | Solid | Exceptional |
|---------|--------|-------|-------------|
| Show HN | <10 pts, page 2 | 50-150 pts, front page hours | 300+ pts, #1 slot |
| Product Hunt | <100 upvotes | 200-500, top-10 day | 800+, top-3 + newsletter feature |
| Launch-week signups | <50 | 100-500 | 1,000+ |
| Newsletter pitch response | <5% | 10-20% | 30%+ |

A "modest" launch with a good retro outperforms a "solid" launch with no retro over three launch cycles — the compounding is in the learning.
