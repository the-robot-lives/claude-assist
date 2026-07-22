# Launch Playbook

Per-launch-type execution guides. Prerequisite: a completed positioning brief (`positioning-and-messaging.md`). Fillable timeline: `assets/launch-checklist.md`.

## Launch-Type Decision Tree

```
Is the product demoable end-to-end by a stranger in <5 minutes?
├─ NO → Soft launch first. Fix onboarding. Nothing else matters yet.
└─ YES
   Is the core audience technical (devs, ops, hackers)?
   ├─ YES
   │   Is there a strong technical story (novel approach, OSS, benchmark)?
   │   ├─ YES → Show HN main launch (community-first warmup)
   │   └─ NO  → Community-first launch (Reddit/Discord), PH optional
   └─ NO (prosumer/consumer)
       Is it visual/demo-friendly (GIF sells it)?
       ├─ YES → Product Hunt main launch
       └─ NO  → Staged rollout + earned media (newsletters/podcasts)

Capacity-limited or activation-fragile? → wrap ANY of the above in a staged rollout.
Already launched before? → changelog cadence + save big beats for majors.
```

**Sequencing rule:** launches stack. A typical portfolio-product arc is Soft (week 1-2) → Community (week 3) → Show HN or PH (week 4) → Changelog cadence thereafter. Each beat seeds proof for the next: soft-launch testimonials go into the PH first comment; PH results go into the newsletter pitch.

## Soft Launch

**Goal:** real usage, testimonials, and onboarding fixes — not traffic.

| Step | Action | Done When |
|------|--------|-----------|
| 1 | Recruit 10-30 users from your own network + 1-2 communities where you already participate | 10+ people have credentials/install |
| 2 | Open a direct feedback channel (Discord, DM, or a `feedback@`) | First unsolicited message arrives |
| 3 | Watch first-run experience — ask 3 users to screen-share or send their terminal output | You've seen 3 strangers onboard |
| 4 | Fix the top 3 onboarding failures | Median time-to-first-value < 5 min |
| 5 | Collect 3-5 quotable reactions (ask permission to quote) | Quotes banked for launch assets |

**Anti-pattern:** treating soft launch as a mini public launch. No announcement posts. The asset produced here is *readiness*, not reach.

## Show HN

**Goal:** front-page conversation with technical early adopters. One shot per product per ~6-12 months — spend it well.

**Prep (T-7 → T-1):**
- Title format: `Show HN: shipctl – one-command deploys without CI config`. Plain, factual, no superlatives, no emoji. Name the thing and what it does.
- Text post: 2-4 short paragraphs — why you built it, how it works technically, what's hard/unsolved, what feedback you want. HN rewards honesty about limitations more than polish.
- Kill the signup wall for launch day if at all possible. HN bounces off email gates.
- Prepare answers for the predictable comments: "how is this different from X", "what's the business model", "why not just use Y", the security question specific to your domain.

**Launch day (T-0):**
- Post Tuesday–Thursday, 7-9am ET (peak US morning overlap with EU afternoon).
- Do NOT solicit upvotes — HN's voting-ring detection penalizes it. Sharing the link with "I posted this" (no vote request) is acceptable.
- Stay in the thread 8+ hours. Answer everything, especially criticism. Founder responsiveness is the difference between 20 and 200 points.
- First comment: post your own comment expanding on tradeoffs/architecture — it anchors the discussion technically.

**Example post opener:**
> Show HN: shipctl – one-command deploys without CI config
>
> I built shipctl after realizing my deploy scripts across five side projects totaled more lines than one of the projects. `shipctl up` inspects the repo, infers the build, and deploys to your own VPS or Fly. Under the hood it generates a plain Dockerfile you keep — there's no lock-in and no runtime agent. Hardest part was build inference for monorepos, which is still rough (details in the README). Would love feedback on the rollback model.

## Product Hunt

**Goal:** ranked visibility with prosumer early adopters + a durable backlink/badge.

**Prep (T-21 → T-1):**

| Asset | Spec | shipctl Example |
|-------|------|-----------------|
| Tagline | ≤60 chars, outcome-first | "One-command deploys. Zero YAML." |
| Gallery | 4-6 images/GIFs; first one must demo the core loop in <10s | Terminal GIF: `shipctl up` → live URL |
| First comment | Maker story: trigger → what it does → what's next → ask | 150-250 words, ends with a question to the community |
| Hunter/supporters | 20-40 people warned 48h ahead who will genuinely engage (comments > upvotes) | DM list built from soft-launch users |
| Launch-day offer | Optional but effective | "Free Pro during launch week for PH users" |

**Launch day:**
- Launches go live at 12:01am PT; ranking is a 24-hour window. Post at 12:01am PT to get the full day.
- Tuesday–Thursday are highest-traffic; Sunday/Monday are lower-competition alternatives for smaller products.
- Never buy upvotes or run upvote-exchange pods — PH detects and derank/bans.
- Reply to every comment same-day. Cross-post "we're live on PH" to X/LinkedIn/Discord with the direct link.

## Community-First Launch (Reddit / Discord / Slack)

**Goal:** adoption inside the communities that already gather around the problem.

**The 90-day rule:** communities smell drive-by promotion. Ideal: 4+ weeks of genuine participation before any product mention. Minimum viable: 2 weeks of answering questions in the target subreddit/Discord.

| Step | Action |
|------|--------|
| 1 | Pick 2-3 communities where the *problem* is discussed (not "startup" subs) |
| 2 | Read each community's self-promo rules; some have Show-off Saturday-style threads — use them |
| 3 | Participate: answer questions in your domain, no links to your product |
| 4 | Launch post format: "I built [X] because [genuine story]. Here's what I learned" — lessons first, link second or in comments per sub norms |
| 5 | Stay in-thread; accept criticism without defensiveness |

**Reddit launch post skeleton (r/selfhosted-style):**
> **I got tired of 40-line deploy scripts for side projects, so I built a one-command deploy CLI**
>
> [3 paragraphs: the pain, what you tried, what you built and how it works]
> [1 paragraph: honest limitations]
> It's free/OSS: [link]. Happy to answer anything about the build-inference approach.

## Staged Rollout

**Goal:** control load and protect activation quality while converting scarcity into narrative.

| Wave | Size | Comms Beat |
|------|------|-----------|
| Private beta | 10-30 | Personal invites; "you're in the first 20" |
| Waitlist wave 1 | 100-300 | "First wave of invites going out" post + email |
| Waitlist wave 2+ | grow ×3 per wave | Changelog of what wave-1 feedback fixed |
| General availability | open | This IS your main launch beat — run Show HN/PH here |

Each wave email includes: what's new since last wave, one activation nudge ("your first deploy takes 90 seconds"), and a referral hook ("invite 2 friends, skip the queue") if the mechanics support it.

## Changelog Cadence (Post-Launch)

Every meaningful release is a micro-launch. See `announcement-writing.md` for changelog-as-marketing patterns. Cadence guidance:

| Release Size | Beats |
|-------------|-------|
| Patch/minor | Changelog entry + 1 X post |
| Notable feature | Changelog + release post + thread + Discord/community mention |
| Major version | Full announcement set; consider a second PH launch (allowed for major versions) or "Show HN: shipctl 2.0" if genuinely newsworthy |

## Failure Modes

| Symptom | Cause | Fix |
|---------|-------|-----|
| Launch traffic, zero signups | Landing copy fails 3-second test, or signup friction | Rework headline/CTA (`positioning-and-messaging.md`); remove email gate |
| Signups, zero activation | Onboarding broken — you skipped soft launch | Pause promotion; run soft-launch steps 3-4 |
| HN post sinks in an hour | Timing, title, or no traction luck | Fine — repost is allowed after a substantial revision months later; redirect energy to community channel |
| PH mid-pack finish | Weak first-hour engagement | Expected without a network; harvest the badge/backlink, move on |
| Community post removed | Skipped participation or sub rules | Apologize to mods, participate 4 weeks, use designated promo threads |
