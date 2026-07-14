# Worked Example: Launching a Developer Tool

End-to-end launch of **shipctl** — a fictional open-source CLI that deploys any repo to production in one command — from positioning through launch week and retro. Operator: solo developer, ~800 X followers, no press contacts, 4 weeks of runway before wanting traffic.

## Starting State

- Product: `shipctl` works; README exists; 6 friends have used it
- No landing page copy, no positioning, no launch plan
- Goal: 500 installs and evidence the message lands, within launch month

## Phase 0: Positioning (Week 1, ~4 hours)

**Messaging worksheet highlights** (mined from 2h of Reddit/HN complaint threads on CI complexity + the operator's own diary):

| Field | Answer |
|-------|--------|
| Trigger | "Side project works locally at 11pm; setting up deploy feels like a second project" |
| Job | Get code live tonight without learning a platform |
| Alternatives | Hand-rolled bash scripts; copy-pasted GitHub Actions; "just run it on my laptop" |
| What's wrong | Scripts break silently, only work on one machine; Actions YAML is write-only |
| Switch trigger | Script fails during a demo / third project means third copy of the script |
| Objections | Another tool to learn; lock-in; single-maintainer risk |

**Positioning statement:**

> For solo developers shipping side projects, who want code live without building a CI pipeline, shipctl is a deploy CLI that takes any repo to production in one command. Unlike GitHub Actions or hand-rolled scripts, there's no YAML and nothing to maintain — and it emits a plain Dockerfile you keep, so there's no lock-in.

**Category decision:** "deploy CLI" (small category, leadable) with anti-pipeline POV for HN/X: *"Deployment is a verb, not a YAML file."*

**Message hierarchy:**

| Level | Copy |
|-------|------|
| Tagline | One-command deploys. Zero YAML. |
| One-liner | shipctl takes any repo to production in one command — no CI config, no dashboard. |
| Pillars | Zero config (build inference) / No lock-in (emits plain Dockerfile) / Instant rollback (5s) |
| Proof | PROOF NEEDED at this point — to be earned in soft launch |

**Landing copy (excerpt):** Headline "Ship your side project tonight" / Subhead "One command deploys any repo to production — no CI config, no dashboard, no lock-in" / CTA "Install in 30 seconds" / Objection row includes "Lock-in? shipctl emits a plain Dockerfile you keep."

## Phase 1: Plan (Week 1, ~2 hours)

**Decision tree walk:** demoable in <5 min ✓ → technical audience ✓ → strong technical story (build inference) ✓ → **Show HN main launch**, preceded by soft launch and a community beat. PH deferred to a future 1.0 beat.

**Channels:** X (primary — existing 800 followers), Reddit r/selfhosted + r/webdev (primary), Bluesky (experimental cross-post). LinkedIn skipped — no B2B angle, limited hours.

**Funnel definition:** Activation event = first successful `shipctl up` (CLI pings a counter, opt-out documented). Targets: 2,000 visits / 500 installs / 40% activation.

**UTM scheme:** `utm_campaign=launch-2026-08`, sources `x|reddit|bluesky`; HN gets a bare URL (referrer attribution).

**Timeline:** T-30 build-in-public starts; T-21 soft launch; T-7 community beat; T-0 (Tuesday) Show HN; T+7 retro.

## Phase 2: Soft Launch (Weeks 2-3)

- 22 users recruited from X + friends; Discord opened for feedback
- Watched 3 strangers onboard: 2 failed on monorepos → shipped `--filter`, cut first-deploy from 4 min to 90s
- Banked proof: "412 deploys by 22 beta users; median first deploy 90 seconds" + 4 permissioned quotes, including: *"Deleted 200 lines of bash after trying this."*
- Build-in-public posts 3x/week; the failure post ("build inference broke on every monorepo, here's how I fixed it") outperformed everything — 40+ replies, +150 followers

## Phase 3: Community Beat (T-7)

Reddit post to r/selfhosted (operator had answered questions there for 3 weeks):

> **Title:** I got tired of 40-line deploy scripts for side projects, so I built a one-command deploy CLI (OSS)
>
> Body: the 11pm trigger story → what shipctl does and how inference works → honest limitations ("monorepo support is a week old; only Ubuntu/Debian targets so far") → link in comments per sub norms.

Result: 340 upvotes, 90 comments, 1,100 visits (`utm_source=reddit`), 210 installs. Two comment threads about lock-in confirmed the objection row was the right call — the "emits a plain Dockerfile" answer got quoted approvingly.

## Phase 4: Show HN (T-0, Tuesday 8am ET)

> **Show HN: shipctl – one-command deploys without CI config**
>
> I built shipctl after my deploy scripts across five side projects totaled more lines than one of the projects. `shipctl up` inspects the repo, infers the build, and deploys to your own VPS or Fly. It emits a plain Dockerfile you keep — no lock-in, no runtime agent. Build inference was the hard part and monorepos are still rough (notes in README). 22 beta users, 412 deploys, median first deploy 90s. Would love feedback on the rollback model.

- Operator's anchor comment: architecture of build inference + rollback tradeoffs
- Stayed in thread 10 hours; answered the predicted questions (vs. Actions, vs. Kamal, security of inference, sustainability) — the prepared objection answers were reused nearly verbatim
- Simultaneous X launch thread (hook: the 40-lines-of-bash pain + demo GIF); link posted bare on Bluesky

**Result:** 176 points, front page ~6 hours, #8 peak. 5,400 visits, 730 installs day one.

## Phase 5: Amplify + Sustain (T+1 → T+14)

- T+1 X post: "24 hours after Show HN: 730 installs, 61% ran their first deploy. Three things I got wrong…" — second-best post of the campaign
- T+2 results-pitch to 12 newsletters ("front page of HN yesterday; 90-second demo attached") → 3 replies, 1 feature in a self-hosting newsletter (+400 visits, `utm_source=newsletter-selfhostweekly`)
- Changelog cadence began: v0.9.1 rollback fix announced as "Rollbacks now survive server reboots — thanks HN commenter dang_ops for the failure case"

## Phase 6: Retro (T+7, filed as retro-2026-08-11.md)

| Stage | Target | Actual | Delta |
|-------|--------|--------|-------|
| Visits | 2,000 | 7,900 | +295% |
| Installs | 500 | 1,240 | +148% |
| Activation | 40% | 58% | +18pts (soft-launch onboarding fixes) |
| 7-day retention | — | 31% | baseline set |

| Channel | Installs | Effort (h) | Verdict |
|---------|----------|-----------|---------|
| HN | 640 | 14 | KEEP (save for 1.0) |
| Reddit | 260 | 8 (+3wk participation) | KEEP |
| X | 250 | 12 | KEEP — failure posts + metrics posts only |
| Bluesky | 55 | 1 | KEEP (cheap cross-post) |
| Newsletter outreach | 35 | 4 | CHANGE — pitch *after* results, skip pre-launch pitching |

**Message check:** strangers quoted "zero YAML" and "emits a Dockerfile you keep" back — hierarchy confirmed. "No dashboard" drew confusion (some wanted one) → demoted from pillar to FAQ.

**Decisions:** KEEP the soft→community→HN sequence; CHANGE pillar 2 phrasing to lead with "no lock-in"; TRY Product Hunt at v1.0 with the rollback GIF as gallery lead.

## What This Example Demonstrates

1. Positioning produced *before* any copy — every later asset reused the hierarchy verbatim
2. Soft launch converted into launch assets: proof points, quotes, and an activation rate worth bragging about
3. Each beat seeded the next (beta quotes → Reddit post → HN credibility → newsletter results-pitch)
4. Objection prep (lock-in) paid off twice — landing page and comment threads
5. The retro changed the positioning (pillar demotion) — launches are positioning experiments
