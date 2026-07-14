# Social Campaign Patterns

Platform-native content patterns and campaign cadence for launch windows. Current as of mid-2026. Rule zero: one message hierarchy, many surface forms — never paste identical copy across platforms.

## Campaign Shape

A launch campaign is a 2-week arc around T-0, not a single post:

```
T-7 → T-1   Tease/build:   problem posts, behind-the-scenes, "shipping next week"
T-0         Launch beat:   thread + cross-posts + community posts, founder online all day
T+1 → T+3   Amplify:       metrics post ("24h later…"), best replies quoted, FAQ post
T+4 → T+14  Sustain:       use-case posts, user shoutouts, lesson-learned post
```

Pick 2 primary platforms + 1 experimental (SKILL.md channel table). Below are the per-platform patterns.

## X (Twitter)

Still the default dev/indie-hacker channel in 2026. Threads and native video/GIF outperform links; external links are algorithmically dampened — put the link in a reply or use a link-in-first-post sparingly on launch day only.

**Launch thread architecture (5-8 posts):**

| Post | Job | Pattern |
|------|-----|---------|
| 1 | Hook — 80% of effort here | Pain or bold claim + demo GIF. No link yet. |
| 2 | What it is | One-liner + who it's for |
| 3-5 | One pillar each | Claim + proof (screenshot/number/snippet) |
| 6 | Objection kill | Preempt the top skeptic reply |
| 7 | CTA + link | Install command / URL (UTM'd) |
| 8 | Personal note | Why you built it; ask for RT of post 1 |

**Hook examples (fictional `shipctl`):**
- Pain: "Your deploy script has more lines than your app. Mine had 40 per project. So I fixed it. [GIF]"
- Claim: "I deleted every CI pipeline I own. One command replaced them all. [GIF]"
- Numbers: "90 seconds from `git init` to production URL. Watch: [GIF]"

**Cadence:** launch day = thread + 2-3 standalone posts + reply to everyone. Rest of window = 1/day. Quote-repost your own thread at a different time zone peak (+8-10h) once.

## LinkedIn

B2B reach and non-dev stakeholders. Narrative beats features; the algorithm rewards dwell time (longer posts that get expanded) and comments.

**Post pattern (150-250 words):**
```
Line 1: Hook sentence, standalone (shows before the "…see more" fold).
Then:   Personal story arc — struggle → insight → what you built.
Then:   3 short lines of what it does (not a feature dump).
Close:  One question to the audience (drives comments).
Link:   First comment, not post body (link dampening).
```

**Example opener:** "I spent more time maintaining deploy scripts last year than writing product code. That's embarrassing to admit — here's what I did about it."

**Cadence:** 2-3 posts across the launch window (tease, launch, retro). LinkedIn punishes >1/day.

## Reddit

Highest-skepticism, highest-conversion channel when done right. See the 90-day participation rule in `launch-playbook.md`.

| Do | Don't |
|----|-------|
| Lessons-first titles: "What I learned building a deploy CLI solo" | "Check out my new tool!" |
| Post as a person, admit limitations | Marketing voice, superlatives |
| Link in comments if sub norms prefer | Link-post to your landing page in discussion subs |
| Answer every comment for 24h | Post and ghost |
| One sub per day, tailored post each | Cross-post identical text to 5 subs in an hour (spam filter + ban) |

**Sub selection for dev tools:** the problem's home (r/devops, r/selfhosted, r/webdev), not the promo dumps. Read each sub's top-10 "I built" posts first and mirror the tone that survived.

## Hacker News

Not a campaign channel — a single high-stakes beat. Full treatment in `launch-playbook.md` (Show HN section). Campaign interaction rule: do NOT drive your X audience to upvote (voting-ring detection); do quote/screenshot good HN comments back onto X afterward.

## Discord / Slack Communities

Continuous-presence channel; promotion is earned by participation.

- Use designated channels: #showcase, #show-and-tell, #i-made-this. Never #general.
- Format: 2-3 sentences + GIF + link. Long-form belongs elsewhere.
- Best pattern: answer someone's problem, then "I actually built a tool for this" with link — only when genuinely relevant.
- Run your own Discord? Launch-day event: "launch party" voice/stage + live demo converts lurkers to advocates.

## Bluesky / Threads / Mastodon

X-diaspora channels; worth cross-posting with light adaptation, rarely worth primary investment for launches (as of 2026):

| Platform | Adaptation |
|----------|-----------|
| Bluesky | Tech-heavy early-adopter crowd; links are NOT dampened — post the link directly; friendlier reply culture, less thread-centric |
| Threads | Compress threads to 1-3 posts; conversational tone; strongest if you have Instagram presence |
| Mastodon | No algorithm — hashtags do discovery (#buildinpublic, #selfhosted); marketing voice is community-hostile — post like a human or skip |

## Build-in-Public (Pre-Launch Compounding)

The cheapest launch amplifier is an audience that watched you build. If launch is 4+ weeks out, post 2-3x/week: progress screenshots, decisions ("SQLite or Postgres? here's why I chose…"), metrics, failures. Failure posts consistently outperform success posts on engagement. This backfills the tease phase and warms the launch thread's first hour.

## Campaign Tracker Row

Log every post in `assets/project-tracker.md`:

```
| Date | Platform | Piece | Link | Impressions | Engagements | Clicks (UTM) | Signups |
```

Kill signals (per SKILL.md channel table) get evaluated at the T+7 retro — drop the channel, don't limp.
