---
id: P-011
name: "The Moderator"
slug: "the-moderator"
archetype: "Trust & Safety operator"
segment: "edge-case"
tags: [operational, moderation, trust-and-safety, admin, cross-client-contractor]
---

# Persona 11: The Moderator

**Name:** Priya Nair
**Age:** 29
**Location:** Austin, TX (remote contractor)
**Occupation:** Trust & Safety contractor (part-time, splits hours across 3 mobile game studio clients)
**Device:** Laptop for the moderation dashboard; keeps the game installed on her phone to check reported content in context
**Income:** $28/hour contract, ~20 hrs/week split across clients

---

## Profile

Priya reviews flagged content for several mobile games through a Trust & Safety agency roster. AI Fighter is one of her smaller accounts — about 3 hours a week in its moderation queue, squeezed between larger clients with higher volume. She's never played competitively and doesn't need to; her job is judging context fast — is this fighter name a slur spelled around a filter, or an edgy-but-harmless joke? She works across queues with different tools and conventions, so she needs AI Fighter's queue to be fast and legible on first look, not something she has to relearn each session.

## Goals

1. Clear the queue within SLA without missing genuinely harmful content
2. Get enough context per report (reason category, content history, reporter pattern) to decide confidently without escalating everything
3. Trust that an approve/reject decision is actually enforced in production, not just marked in the admin view
4. Not become the single point of failure for classroom-safe (COPPA) and Family Mode accounts that depend on her queue staying current

## Frustrations

1. Undifferentiated queues with no severity or category sorting — everything read top-to-bottom regardless of urgency
2. No confirmation that a rejection actually removed content client-side versus just flagging a database row
3. Repeat offenders re-appearing under new accounts with no persistent reputation signal to catch them faster
4. Being asked to make legal-adjacent calls (COPPA-adjacent content, under-13 data exposure) with no clear escalation path to someone with authority to own that decision

## Behaviors

- Works the queue in 20-30 minute blocks between other clients' queues, oldest-by-SLA first
- Triages by categorized report reason rather than reading every report in full detail
- Escalates instead of guessing when written policy doesn't clearly cover a case
- Spot-checks "Classroom Approved" designations ahead of back-to-school periods, since Educator complaints spike then

## Job to Be Done

> "When a player reports a build, guide, or fighter name as inappropriate, I want to review it against clear categorized policy with enough context to decide fast, so I can hold the 24-hour SLA and keep classroom and family accounts safe without becoming the bottleneck."

## Relationship to Product

Priya reaches AI Fighter through her agency's client roster, not by choosing to play it — adoption is assigned, not opted into. The features that matter most to her: categorized report reasons, SLA-age visibility, a moderation history/audit trail, and the "Classroom Approved" badge workflow. She'd ask her agency to reassign the account (her version of churn) if report volume outgrew the 24-hour SLA, or if she lost confidence that a "rejected" decision was actually being enforced client-side.

## Scenarios

1. **Daily queue triage** — Opens the Content Moderation Queue, sorts by SLA age, and works the classroom-flagged batch first since those carry a live 24-hour promise to a teacher.
2. **Family Mode escalation** — A parent reports a fighter name; Priya checks the reporter's history, confirms a policy violation, rejects it, and the reporter gets a "Rejected — policy reason" notification inside the SLA window.
3. **Classroom season prep** — Ahead of a fall semester start, she works through a batch of community builds and grants "Classroom Approved" badges to grade-appropriate content before an Educator's students arrive.

## Design Implications

- Queue needs severity/category and SLA-age sorting, not chronological order — Priya works a portfolio of clients and can't read every report in full
- Moderation actions need a visible, confirmed enforcement state, not just an admin-side status flip — she needs to trust that "rejected" actually removes it
- An audit trail / moderation history view is required so she (or the next moderator on the account) can catch repeat offenders across accounts
- An escalation path is needed for ambiguous, legal-adjacent calls (COPPA-adjacent content) rather than forcing a unilateral judgment call
