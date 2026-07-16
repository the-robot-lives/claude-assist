---
id: P-002
name: "Diego Ramírez"
slug: diego-ramirez
archetype: "The Sprinter"
segment: primary
tags: [certification-prep, flashcards, streaks, learning-plan, job-search]
---

# P-002: Diego Ramírez

## Demographics

| Attribute | Value |
|-----------|-------|
| Age | 29 |
| Occupation | Mid-level Software Developer (web/backend) |
| Location | Austin, TX, USA |
| Tech comfort | high |

## Bio
Diego is three years into his career and pushing hard for the next rung: a cloud certification he's convinced will unlock better job offers, and a round of interviews he's actively prepping for. He's competitive with himself, likes visible progress, and treats learning like training for a race — reps, streaks, measurable output. He's comfortable in a terminal but not married to it; he'll use whatever tool gets him graded fastest.

## Goals
- Pass a specific cloud certification exam within a defined window (weeks, not months).
- Walk into interviews with system-design and language-fundamentals recall that's fast and confident, not "let me think about that."
- See concrete evidence of progress — streaks, deck mastery percentages, quiz scores trending up.
- Convert scattered study material (docs, course notes, past interview questions) into a structured, spaced-repetition study plan instead of re-reading the same PDF five times.

## Frustrations
- Traditional flashcard apps (Anki, Quizlet) require him to manually author every card, which eats the time he should be spending studying.
- Generic study plans aren't tied to what he's actually retaining — they assume linear progress and don't adapt when he's clearly forgotten something.
- He loses motivation when there's no visible feedback loop; a study session that doesn't end in a score or a streak feels wasted.
- Interview prep material and cert material live in different silos with no shared plan tying them together.

## Behaviors
- Sets up a `/learning-plan` at the start of each study block with a hard deadline (exam date, interview date) and checks it almost daily.
- Runs `/flashcard` sessions every morning before work — small, disciplined SM-2 review reps rather than long cram sessions.
- Uses `/quiz` heavily, both the terminal runner for quick reps and the React SPA when he wants a more "exam-like" full-screen experience the night before a real test.
- Tracks his own streak obsessively; a broken streak visibly affects his mood and next-day intensity.
- Occasionally uses `/simulate` for behavioral and system-design interview role-play, treating the agent as a mock interviewer.

## Job to Be Done
> "When I'm racing toward a certification deadline or an interview date, I want a spaced-repetition study system that turns my study material into decks and quizzes automatically and shows me measurable progress, so I can trust I'm ready instead of guessing."

## Relationship to Product
Diego is the primary user validating the SM-2 flashcard engine, the `/quiz` experiences (both terminal and SPA), and the `/learning-plan` goal-tracking loop under real time pressure. He's less interested in the slow-burn "grow a personal wiki" story that drives Maya and more interested in the product as a training regimen with a finish line. He is highly sensitive to friction — if generating a deck from a topic takes more than a couple of commands, he'll abandon it mid-plan and fall back to Anki. He is a plausible early word-of-mouth referrer if the cert-prep flow works, since he's vocal in developer communities about tools that got him hired.

## Scenarios
- **Scenario 1: The 30-Day Countdown** — Diego sets a `/learning-plan` with his exam date as the target. The plan breaks his weak domains into a checkpoint schedule, and `kb-flashcard-generator` builds decks from the official exam guide topics he feeds it, so day one is already reviewing cards instead of authoring them.
- **Scenario 2: Streak on the Line** — It's day 22 of a study streak and Diego is exhausted after a long on-call shift. He opens the terminal quiz runner for a five-minute review instead of the full SPA session, keeping the streak alive with minimal friction — exactly the low-effort path that keeps him from quitting the plan.
- **Scenario 3: Mock Interview Night** — The night before a system-design interview, Diego runs `/simulate` for a role-play scenario modeled on the interview format, gets pushed on follow-up questions in real time, and afterward reviews the session log to see exactly where he hesitated.
