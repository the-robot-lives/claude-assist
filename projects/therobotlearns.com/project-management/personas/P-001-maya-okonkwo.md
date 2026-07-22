---
id: P-001
name: "Maya Okonkwo"
slug: maya-okonkwo
archetype: "The Deep Diver"
segment: primary
tags: [terminal-native, expertise-calibration, daily-user, knowledge-base-growth]
---

# P-001: Maya Okonkwo

## Demographics

| Attribute | Value |
|-----------|-------|
| Age | 38 |
| Occupation | Staff Backend Engineer (distributed systems) |
| Location | Originally Lagos, Nigeria; now London, UK (fully remote) |
| Tech comfort | high |

## Bio
Maya has spent 15 years going deep on backend systems — Postgres internals, Kafka, Kubernetes networking, Rust performance work. She lives in the terminal by choice: tmux, vim, and a shell prompt are more "home" to her than any GUI ever was. She reads primary sources (RFCs, source code, changelogs) before she trusts a blog post, and she expects any tool she uses daily to respect that she already knows the basics.

## Goals
- Get answers to technical questions calibrated to her actual (senior/staff) level — no "first, let's talk about what a hash table is."
- Build a durable, searchable personal knowledge base out of the questions she's already asking, without extra manual curation effort.
- Stop re-deriving or re-Googling things she is certain she understood a year ago.
- Keep her KB accurate as tools and versions she depends on evolve.

## Frustrations
- General-purpose search and chatbots give her answers pitched at a generic mid-level developer, forcing her to wade through preamble to get to the part she didn't know.
- Nothing she's used actually remembers what she's already learned — every session starts from zero.
- Bookmarks, gists, and scattered notes files have become a graveyard she never revisits.
- Documentation tools that require dedicated "writing time" she doesn't have; she wants retention to be a side effect of doing her job, not a second job.

## Behaviors
- Runs `robot-learns` from her terminal multiple times a day, often mid-debugging-session, to ask a pointed technical question via `/query`.
- Skims generated `knowledge/` articles for accuracy and occasionally edits them directly rather than asking the agent to redo them.
- Rarely touches the quiz SPA; when she reviews retention it's almost always via the CLI quiz runner because it's one keystroke away from her existing workflow.
- Has strong opinions about her `user-profile.yaml` expertise levels and tunes them per-domain (staff-level on distributed systems, intermediate on frontend, since she doesn't touch it often).

## Job to Be Done
> "When I hit a real technical question mid-task, I want an answer pitched at my actual expertise level that also gets captured into my own knowledge base automatically, so I can stop re-learning things I've already paid the cost to learn once."

## Relationship to Product
Maya is the archetypal power user this product is built for: a technical professional who already has deep expertise and wants a system that respects it rather than re-explaining fundamentals. She is the primary driver of the `/query` calibration requirement and the auto-building `doc-writer`/`topic-expander` agents — her daily usage is what proves those flows work under real, unscripted questions rather than curated demo prompts. She is unlikely to ever touch the future therobotlearns.com cloud sync unless it's genuinely useful for a personal multi-machine setup, since she is skeptical of anything that adds a server between her and her notes.

## Scenarios
- **Scenario 1: Mid-Debug Detour** — Maya is debugging a Kafka consumer group rebalance storm at 11pm. She runs `robot-learns why does cooperative-sticky assignor still trigger a full rebalance on partition count change`, gets an answer pitched at staff level (no assignor-101 preamble), and by the time she's back in her editor a new `knowledge/kafka/rebalancing/cooperative-sticky-edge-cases.md` article has been auto-drafted from the exchange.
- **Scenario 2: The Forgotten Fact** — Six months after learning something about Postgres `VACUUM` internals, Maya runs `/quiz` on her Postgres deck via the CLI runner and gets flagged on a card she's clearly forgotten. She's annoyed at herself but relieved the SM-2 scheduling caught it before it cost her in production.
- **Scenario 3: Curating the Curator** — Maya notices the `topic-expander` agent generated a KB article with an outdated claim about a tool version she's since upgraded. She opens the file directly in vim, corrects it, and expects the machine-profile-aware answers going forward to reflect the current version rather than needing to re-teach the agent from scratch.
