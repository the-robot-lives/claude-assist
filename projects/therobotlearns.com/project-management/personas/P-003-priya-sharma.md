---
id: P-003
name: "Priya Sharma"
slug: priya-sharma
archetype: "The Context Switcher"
segment: primary
tags: [sre, machine-profile, simulations, incident-response, polymath]
---

# P-003: Priya Sharma

## Demographics

| Attribute | Value |
|-----------|-------|
| Age | 34 |
| Occupation | Site Reliability Engineer / DevOps generalist |
| Location | Bengaluru, India |
| Tech comfort | high |

## Bio
Priya's job is breadth: she moves between Kubernetes, Terraform, three different cloud providers, a half-dozen observability stacks, and whatever legacy tool the on-call rotation forces her to relearn at 3am. No two of her clusters run the same tool versions, and "it depends on your setup" is the most common true sentence in her professional life. She's precise about environment details because vague advice has burned her in production before.

## Goals
- Get answers that account for the exact OS, tool, and version combination on the machine or cluster she's currently working against, not generic advice that assumes the latest version.
- Rehearse incident-response scenarios before they happen for real, so muscle memory exists under pressure.
- Keep a working knowledge base that spans dozens of tools without needing a separate mental model for each one.
- Avoid the trap of relearning the same tool's quirks every time she context-switches back to it after months away.

## Frustrations
- Most documentation and AI answers assume the newest version of a tool; her reality is a fleet running three different versions of the same thing depending on the cluster.
- Context-switching cost is brutal — by the time she remembers a tool's edge cases, she's already switched to the next fire.
- Incident postmortems capture what happened but rarely turn into something she can rehearse before the next incident.
- Generic quiz apps don't understand operational scenarios; they test facts, not decision-making under simulated pressure.

## Behaviors
- Keeps her `machine-profile.yaml` scrupulously up to date across her different working contexts and expects `/query` answers to differ accordingly (e.g., a `kubectl` flag that's deprecated on one cluster's version but required on another).
- Uses `/simulate` specifically for incident-response role-play — practicing triage decisions, escalation calls, and postmortem framing in a low-stakes terminal environment.
- Builds KB articles less from idle curiosity and more from real incidents: after a postmortem, she'll explicitly ask the agent to turn the root-cause narrative into a durable article.
- Jumps between dozens of topic areas per week; relies on the KB's search/index rather than browsing, since she can't hold the full tree in her head.

## Job to Be Done
> "When I'm working against a specific, versioned environment under time pressure, I want answers and rehearsal scenarios that match my actual machine profile, so I can act correctly the first time instead of debugging advice that assumed a different setup."

## Relationship to Product
Priya is the primary pressure-test for machine-profile-aware answer calibration — if `/query` ever gives version-agnostic advice, it fails her specifically and visibly. She's also the core validator for `/simulate` as an operational rehearsal tool rather than a purely academic exercise; incident-response role-play with realistic escalation dynamics is a distinct use case from Diego's interview prep, even though they share the same command. She's a heavy but selective KB contributor: she wants postmortem-derived articles to persist so the next on-call engineer (possibly her, six months from now) doesn't relearn the same lesson.

## Scenarios
- **Scenario 1: Version-Specific Fix** — Priya asks `/query` how to work around a known bug in a specific ingress controller. Because her `machine-profile.yaml` records the exact chart version deployed on this cluster, the answer correctly tells her the workaround needed for that version rather than pointing her at a fix already merged upstream but not yet in her deployed release.
- **Scenario 2: Rehearsed Incident** — Before an on-call rotation starts, Priya runs `/simulate` for a "database connection pool exhaustion under traffic spike" scenario. The terminal role-play pushes her through triage decisions in real time; she flags one place where her instinct was wrong and turns it into a flashcard.
- **Scenario 3: Postmortem to Permanent Knowledge** — After resolving a real incident, Priya asks the agent to convert her postmortem notes into a KB article via `doc-writer`, tagged to the specific tool and version combination involved, so a future search against that exact context surfaces the fix immediately.
