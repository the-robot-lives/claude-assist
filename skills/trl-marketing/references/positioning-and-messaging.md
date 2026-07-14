# Positioning and Messaging

Frameworks for deciding what to say before deciding where to say it. Output of this file: a positioning statement, a message hierarchy, and a landing-page copy block.

## Jobs-to-be-Done Intake

Positioning starts from the job the user hires the product to do — not from the feature list. Answer these before writing any copy (the fillable version is `assets/messaging-worksheet.md`):

| Question | Why It Matters | Bad Answer | Good Answer |
|----------|----------------|------------|-------------|
| What situation triggers the need? | Copy opens with the trigger, not the product | "People who want to deploy" | "It's 11pm, the side project works locally, and setting up CI feels like a second project" |
| What is the user really trying to accomplish? | The job, stated as progress | "Use our CLI" | "Get code live tonight without learning a platform" |
| What do they use today? | Your real competition — often 'nothing' or a hack | "Competitor X" | "A 40-line bash script they're afraid to touch" |
| What's wrong with that? | Your differentiation axis | "It's worse than us" | "It breaks silently and only works on one machine" |
| What would make them switch? | The switch trigger drives launch timing/angle | "Better features" | "The third time the script fails during a demo" |
| What would make them hesitate? | Objections → FAQ/objection row copy | (ignored) | "Another tool to learn; lock-in fear; is it maintained?" |

**Solo-dev shortcut:** if you can't interview users, mine evidence — GitHub issues on alternatives, Reddit/HN complaints, your own diary of why you built it. Two hours of complaint-mining beats zero interviews.

## Positioning Statement

The April Dunford-style compressed form:

```
For [target user in a situation]
who [job to be done / struggle],
[product] is a [category you choose to be judged in]
that [key benefit / job outcome].
Unlike [primary alternative — often "scripts" or "doing nothing"],
[the one differentiator you can defend].
```

**Worked example — fictional CLI `shipctl`:**

> For solo developers shipping side projects, who want code live without building a CI pipeline, shipctl is a deploy CLI that takes any repo to production in one command. Unlike GitHub Actions or hand-rolled scripts, there is no YAML, no dashboard, and nothing to maintain — the pipeline lives in your terminal.

**Category choice is a lever, not a fact.** `shipctl` could position as "a CI/CD tool" (judged against GitHub Actions — loses), "a deploy CLI" (small category, easy to lead), or "the anti-pipeline" (category POV — see below). Pick the frame where your differentiator is the buying criterion.

## Category Point-of-View

A category POV is an opinionated claim about how the world should work, which your product happens to embody. It powers launch posts, threads, and press angles far better than feature lists.

**Construction:**

1. **Enemy** — name the status quo, not a competitor: "CI config has become a second codebase."
2. **Shift** — why now: "Solo devs ship more projects than ever; each one can't carry a pipeline."
3. **New way** — the belief: "Deployment should be a verb, not an infrastructure project."
4. **Proof** — your product as evidence: "shipctl: `shipctl up` and you're live."

**POV headline examples:**
- "CI/CD is enterprise cosplay for side projects"
- "Your deploy pipeline shouldn't have more lines than your app"
- "Deployment is a verb, not a YAML file"

Use the POV for HN/Reddit/X where feature claims get discounted; use the positioning statement for landing pages and PH where clarity wins.

## Message Hierarchy

Every campaign uses one hierarchy so all copy agrees:

| Level | Length | Where Used | shipctl Example |
|-------|--------|------------|-----------------|
| **Tagline** | ≤7 words | PH tagline, X bio, og:title | "One-command deploys. Zero YAML." |
| **One-liner** | 1 sentence | Headlines, tweet openers, elevator | "shipctl takes any repo to production in one command — no CI config, no dashboard." |
| **Paragraph** | 3-4 sentences | README top, release post intro, PH first comment | One-liner + who it's for + how it works + differentiator |
| **Benefit pillars** | 3 × (label + sentence) | Landing sections, thread body | "Zero config / Runs anywhere / Rollback built-in" |
| **Proof points** | Numbers, quotes, demos | Everywhere claims appear | "Deployed 40 projects in beta; median first deploy: 90 seconds" |

**Rule:** never invent new phrasing mid-campaign. If the tweet says "zero YAML" and the landing page says "no configuration files," you've split your message.

## Landing-Page Copy Hierarchy

Copy only — hand structure to trl-user-experience-engineer for design.

| Slot | Job | Pattern | shipctl Example |
|------|-----|---------|-----------------|
| **Headline** | Pass the 3-second test: what + for whom | Outcome, not category | "Ship your side project tonight" |
| **Subhead** | De-risk the headline with mechanism | "[How] — without [pain]" | "One command deploys any repo to production — no CI config, no dashboard, no lock-in" |
| **Primary CTA** | One action, low friction, specific | Verb + object (+ qualifier) | "Install in 30 seconds" (not "Get Started") |
| **Secondary CTA** | Catch the not-ready | Lower commitment | "Watch the 90-second demo" |
| **Benefit block ×3** | One pillar each: label, sentence, proof | Claim → mechanism → evidence | "Zero config — shipctl reads your repo and infers the build. 40 frameworks detected automatically." |
| **Social proof** | Borrowed trust | Names/numbers/logos, never fake | "1,200 deploys in public beta" |
| **Objection row** | Kill top 3 hesitations | Q → direct answer | "Lock-in? shipctl emits a plain Dockerfile you keep." |
| **Final CTA** | Repeat primary + urgency if honest | Same verb as primary | "Install in 30 seconds — free while in beta" |

**Headline quality bar** — reject any headline that:
- Could describe a competitor unchanged ("Deploy with confidence")
- Names the category but not the outcome ("A modern deployment CLI")
- Needs the subhead to be understood at all

## Audience-Awareness Calibration

Before finalizing, check the message against the Message-Market Fit Matrix in SKILL.md. The most common solo-dev error is writing solution-aware copy ("like X but Y") for a problem-unaware audience that has never heard of X. When in doubt, lead with the job outcome — it works at every awareness level.

## Deliverable Template

`marketing/{product}/positioning.md` should contain, in order:

1. JTBD summary (trigger, job, alternatives, switch trigger, objections)
2. Positioning statement (Dunford form)
3. Category POV (enemy / shift / new way / proof)
4. Message hierarchy table (tagline → proof points)
5. Landing-page copy block (all eight slots, final copy)
