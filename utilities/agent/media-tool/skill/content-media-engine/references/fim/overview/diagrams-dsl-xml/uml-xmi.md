# XMI (XML Metadata Interchange)

## What
XMI is a standards-based (OMG) XML format for exchanging UML models and metamodels between modeling tools, built on MOF-based metadata serialization (current stable version 2.5.1). Its primary consumers are UML modeling tools — StarUML, Enterprise Architect, MagicDraw, Visual Paradigm, ArgoUML, Eclipse UML2, and IBM Rational Software Architect.

## How
- The LLM emits XMI XML — an `<xmi:XMI>` root with the required OMG/UML namespaces wrapping a `<uml:Model>`, `packagedElement` entries for packages/classes/associations, and `ownedAttribute`/`ownedOperation` members.
- That XML is turned into a viewable/editable artifact by importing it into an XMI-supporting UML tool (the tool renders diagrams and can round-trip the model back out).
- Typical final artifact: an interchange `.xmi` model file consumed by modeling tools, or diagrams/analysis derived from it once imported.

## Why
- Reach for XMI when the goal is tool interoperability and model exchange rather than a single rendered picture — best for MDA (Model Driven Architecture), model repositories/version control, tool-integration toolchains, and programmatic model analysis.
- Limitations: verbose XML with large file sizes, vendor-specific dialects that reduce portability, frequent loss of diagram layout/visual positioning, version incompatibilities across XMI revisions, and slow parsing of large files.
- Relative to the DSL siblings in this category: XMI is a machine-oriented interchange format with full metamodel coverage, not a human-authored diagram DSL — you reach for it to move models between tools, not to sketch quickly.

## Source
- Solution reference: `fim/solution/uml-xmi.md`
