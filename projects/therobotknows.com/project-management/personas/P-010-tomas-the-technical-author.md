---
id: P-010
name: "Tomás Reyes"
slug: "tomas-the-technical-author"
archetype: "The Technical Book Author"
segment: "secondary"
tags: [technical-book, long-form, running-example, version-pinning, glossary, publishing]
---

# Tomás Reyes — The Technical Book Author

## Demographics

| Field | Value |
|-------|-------|
| **Age** | 36-50 |
| **Role** | Senior engineer writing a technical book under contract (O'Reilly / Manning / Pragmatic) |
| **Technical Level** | Expert |
| **Industry** | Software engineering + technical publishing |
| **Location** | Barcelona, Spain |

## Bio

Tomás is nine months into a 420-page book on a framework that ships a minor release every six weeks. Fourteen chapters share one running example application, one pinned dependency baseline, and a glossary he started in chapter 3 and stopped maintaining around chapter 8. He writes evenings and weekends around a full-time job, which means chapter 9 was written five months after chapter 2 — and against a different version of the framework.

## Goals

1. Keep fourteen chapters agreeing with each other about the running example, the versions, and the vocabulary
2. Catch contradictions before his tech reviewers do, because reviewer rounds are expensive and slow
3. Stop deferring the connective tissue — glossary entries, appendix cross-references, "as we saw in chapter 4" callbacks — that he keeps pushing to the end

## Frustrations

1. Chapter 2 pins a version; chapter 9 uses an API that only exists in a later one. Both were correct when written. The reader hits the wall, not him.
2. He's defined the same term three slightly different ways in three chapters and only knows because a reviewer said so
3. The manuscript lives in AsciiDoc, the example code in a git repo, and his notes in Obsidian — nothing connects a paragraph to the code listing it describes
4. When the framework ships a breaking change mid-writing, he has no way to scope the blast radius across chapters he wrote months ago

## Behaviors

- Writes in 2-3 hour evening blocks; loses context between sessions and re-reads old chapters to reload it
- Keeps the example app in a git repo with a branch per chapter
- Submits chapters to the publisher in batches; reviewer feedback arrives weeks later
- Maintains a "fix later" list that grows faster than it shrinks
- Re-checks every code listing manually before final submission — the single most dreaded task in the project

## Job to Be Done

> "When I write chapter 9 five months after chapter 2, I want the system to tell me where the two disagree about versions, terminology, and the running example, so my tech reviewer finds craft problems instead of contradictions."

## Relationship to Product

Tomás would find the Knowledge Base through a publisher's author community, a technical writing newsletter, or another author. He'd onboard by ingesting his existing chapter drafts and the example repo, treating the outline, the dependency baseline, and the glossary as canon. His value is concentrated in the consistency engine and the graph — generation matters less to him than to other personas, because his publisher's contract and his own reputation make AI-written prose a non-starter for the body text. He'd use generation for glossary stubs, appendix cross-references, and exercises, and he needs the generated tag to be unambiguous so nothing unreviewed reaches the manuscript. He'd churn if ingesting AsciiDoc or Markdown chapters mangles his structure, or if it can't express "this paragraph depends on that code listing."

## Scenarios

1. **Cross-chapter version check** — Before submitting chapters 8-11, Tomás runs the consistency checker across the whole book. It flags that chapter 9's code sample calls an API introduced after the version chapter 2 pins, and that "handler" and "processor" are used interchangeably for the same concept in chapters 5 and 10. He fixes both before the batch goes to review.
2. **Closing the connective tissue** — With the draft complete, Tomás generates glossary entries for every concept entry that lacks one and appendix cross-references from the graph's existing edges. He reviews the batch, discards a handful as redundant, edits the rest for voice, and promotes them — finishing in an evening a task he'd been deferring for four months.
