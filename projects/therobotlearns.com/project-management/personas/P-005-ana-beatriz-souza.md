---
id: P-005
name: "Ana Beatriz Souza"
slug: ana-beatriz-souza
archetype: "The Newcomer"
segment: secondary
tags: [beginner-calibration, career-switcher, non-native-speaker, encouraging-tone, structured-plans]
---

# P-005: Ana Beatriz Souza

## Demographics

| Attribute | Value |
|-----------|-------|
| Age | 26 |
| Occupation | Junior Developer (career switcher, ~10 months into first dev role) |
| Location | São Paulo, Brazil |
| Tech comfort | medium |

## Bio
Ana switched into software development from a marketing career less than a year ago, via an intensive bootcamp. She's capable and motivated but still building the vocabulary and mental models that more experienced developers take for granted. Portuguese is her first language; she reads and writes technical English comfortably but dense, jargon-heavy documentation slows her down and sometimes makes her doubt whether she belongs in the room.

## Goals
- Get explanations calibrated to where she actually is — willing to be told she's a beginner in a given domain, but wants that reflected in the answer instead of assumed-context jargon.
- Build confidence through structured, incremental learning plans rather than an overwhelming "read everything" approach.
- Retain fundamentals long enough that they become second nature instead of things she has to look up every time.
- Feel like the tool is on her side — encouraging, patient, and non-judgmental about gaps in her knowledge.

## Frustrations
- Senior-oriented documentation and Stack Overflow answers frequently assume context she doesn't have yet, and rarely define terms inline.
- Some technical material she's found is dense enough that translating the jargon in her head slows her down even when her English comprehension is otherwise strong.
- Generic "here's everything about X" answers are overwhelming; she wants scoped, sequenced explanations she can build on.
- She's occasionally been made to feel unwelcome asking "basic" questions in professional forums, which makes her hesitant to ask in the first place.

## Behaviors
- Sets her `user-profile.yaml` expertise levels honestly low in most domains and pays close attention to whether `/query` answers actually respect that — she notices immediately when an answer assumes too much.
- Leans heavily on `/learning-plan` to get a sequenced path through a topic rather than jumping in unguided.
- Uses `/flashcard` and `/quiz` consistently as confidence-building checkpoints — seeing a rising score matters to her not just as data but as reassurance.
- Re-reads generated KB articles more than once, sometimes asking follow-up `/query` questions on the same article until a concept fully clicks.
- Appreciates when the agent's tone is patient and encouraging rather than terse; a curt answer reads to her as impatience, even when it isn't intended that way.

## Job to Be Done
> "When I'm learning something genuinely new to me, I want explanations pitched at my real beginner level with a clear, structured path forward, so I can build real understanding and confidence instead of feeling lost or embarrassed."

## Relationship to Product
Ana is the essential counterweight to Maya: if the product only ever validates against an expert user, it will quietly fail beginners by defaulting to jargon or skipping foundational steps. Her usage is the test case for whether expertise calibration genuinely works at the low end of the scale, and whether the tone of generated answers and KB articles stays encouraging rather than curt. She is a heavy, faithful user of `/learning-plan`, `/flashcard`, and `/quiz` specifically because structure and visible progress are what keep her motivated through the discomfort of being new. Her success (or frustration) is a strong leading indicator of whether the product works for the broad population of developers early in their careers, not just senior specialists.

## Scenarios
- **Scenario 1: Respecting the Beginner Flag** — Ana asks `/query` what a race condition is. Because her `user-profile.yaml` marks concurrency as beginner-level, the answer defines terms inline, uses a concrete small example, and avoids assuming she already knows what a thread or a mutex is — unlike the last three blog posts she tried to read.
- **Scenario 2: A Plan She Can Trust** — Overwhelmed by everything she feels she needs to learn about testing, Ana runs `/learning-plan` and gets a sequenced, checkpointed plan that starts with the absolute basics of unit testing before moving to mocking and integration tests — she finally has a path instead of an undifferentiated pile of topics.
- **Scenario 3: Quiz as Confidence Check** — After a week studying async/await fundamentals via generated flashcards, Ana takes a `/quiz` in the React SPA and scores well enough to feel, for the first time, like the concept has actually stuck — a small but meaningful confidence milestone in her career switch.
