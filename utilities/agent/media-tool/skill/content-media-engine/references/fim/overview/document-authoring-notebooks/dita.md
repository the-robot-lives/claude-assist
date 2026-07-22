# DITA

## What
DITA (Darwin Information Typing Architecture) is an XML-based OASIS standard for authoring, managing, and publishing modular technical documentation. Content is organized into typed topics (Concept, Task, Reference, Glossary) assembled by maps into deliverables.

## How
- The LLM emits DITA XML: typed topic elements such as `<task>` / `<taskbody>` / `<steps>` / `<step><cmd>`, organized via ditamaps.
- Rendered by the DITA Open Toolkit (DITA-OT), which transforms source topics and maps into deliverables.
- Final artifact: PDF, HTML5, EPUB, Markdown, or Word.

## Why
- Reach for DITA for enterprise-scale documentation with strong single-source reuse (conref/keyref), conditional/audience-specific processing, and localization — common in multi-product suites and regulated industries (aerospace, medical).
- Tradeoffs: steep learning curve, verbose XML, specialized editors/tooling required, significant initial infrastructure cost, and strict typing can constrain authoring.
- Versus DocBook both are XML single-source standards; DITA emphasizes topic typing and modular reuse, DocBook emphasizes narrative book/manual structure.

## Source
- Solution reference: `fim/solution/dita.md`
