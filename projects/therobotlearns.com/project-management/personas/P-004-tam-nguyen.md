---
id: P-004
name: "Tam Nguyen"
slug: tam-nguyen
archetype: "The Curator"
segment: secondary
tags: [team-lead, learning-plans, cloud-sync, deck-sharing, occasional-user]
---

# P-004: Tam Nguyen

## Demographics

| Attribute | Value |
|-----------|-------|
| Age | 45 |
| Occupation | Engineering Team Lead (manages 8 engineers) |
| Location | Seattle, WA, USA |
| Tech comfort | high |

## Bio
Tam spends most of their week in meetings, code review, and roadmap planning rather than heads-down building, so their own personal `/query` usage is occasional — a curiosity check here, a refresher there. Where Tam actually gets value is thinking about how their whole team learns: onboarding new hires, leveling up juniors, making sure institutional knowledge doesn't live only in senior engineers' heads. Tam thinks in terms of team capability, not just personal mastery.

## Goals
- Curate learning plans and flashcard decks that the whole team can benefit from, not just themself.
- Export and hand off study material (decks, learning plans, KB articles) to team members today, even without a shared backend.
- Reduce the "tribal knowledge" problem — get what senior engineers know into a form junior engineers can study.
- Be an early, informed voice on whether the future therobotlearns.com cloud sync and team-learning features are worth adopting for the team.

## Frustrations
- Right now, sharing anything useful means manually copying files (decks, `learning-plan.yaml`, KB articles) between people's local setups — workable but clunky.
- No visibility into whether teammates who received a shared deck or plan are actually using it or making progress.
- Onboarding docs go stale fast; there's no mechanism today to keep a shared knowledge base current across multiple contributors.
- As a lead, Tam's own study time is thin, so any tool that assumes daily deep engagement doesn't fit their actual usage pattern.

## Behaviors
- Uses `/learning-plan` less for personal study and more as a template-generation exercise — building a plan structure, then adapting and exporting it for a junior engineer's onboarding.
- Periodically runs `robot-learns` to spot-check a technology the team is adopting, more to build a KB article to hand off than for personal retention.
- Manually copies generated flashcard decks and KB articles into a shared team drive or repo today, since there's no sync feature yet.
- Watches for any mention of shared KBs or team learning in release notes; would be an early adopter/champion of the cloud phase if it lands well, and an equally vocal skeptic if it feels heavyweight.

## Job to Be Done
> "When I need to level up my team rather than just myself, I want to curate and hand off learning plans, decks, and KB articles built by the tool, so I can scale what senior engineers know without writing onboarding docs from scratch."

## Relationship to Product
Tam is a secondary, lower-frequency user personally, but a strategically important one: they represent the bridge persona between the local-first v1 product and the future therobotlearns.com cloud phase (shared KBs, team learning). Product decisions about export formats, file portability, and how cleanly a `learning-plan.yaml` or flashcard deck can be handed to someone else matter disproportionately to Tam even before cloud sync exists. Their adoption (or public skepticism) of the eventual team features will meaningfully shape how other engineering leads perceive the product.

## Scenarios
- **Scenario 1: Onboarding Template** — A new junior engineer joins Tam's team. Tam runs `/learning-plan` against the team's core stack, edits the generated plan to match the new hire's ramp-up timeline, and hands them the `learning-plan.yaml` plus a starter flashcard deck instead of writing an onboarding doc from scratch.
- **Scenario 2: Tribal Knowledge Capture** — After a senior engineer explains a gnarly piece of the codebase in a design review, Tam runs `/query` to explore it further and asks the `doc-writer` agent to produce a KB article, then manually copies it into the team's shared docs repo so it doesn't stay locked in one person's head.
- **Scenario 3: Cloud Feature Evaluation** — When therobotlearns.com's shared-KB beta becomes available, Tam is among the first to try syncing a deck to a teammate, closely evaluating whether it actually reduces the manual copy-paste workflow they've been running — and is prepared to say publicly if it doesn't.
