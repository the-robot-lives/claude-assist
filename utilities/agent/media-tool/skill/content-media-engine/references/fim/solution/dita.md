# DITA — Darwin Information Typing Architecture

DITA is an OASIS XML standard for authoring modular, topic-based technical documentation with strong reuse and multi-channel publishing. Content is written as small, typed **topics** (concept/task/reference) organized by **maps**, then transformed by the **DITA Open Toolkit (DITA-OT)** into PDF, HTML5, EPUB, Markdown, and more. Its defining features are content reuse (conref/keyref), conditional processing, and specialization.

**Current Version**: DITA 1.3 (widely deployed) · DITA 2.0 (published, adoption growing)  **License**: OASIS open standard  **Runtime**: DITA Open Toolkit (Java); editors: Oxygen XML, XMLmind, FrameMaker

## Official Resources & Documentation
- **DITA-OT**: https://www.dita-ot.org/
- **OASIS DITA spec**: https://docs.oasis-open.org/dita/
- **DITA-OT docs**: https://www.dita-ot.org/dev/
- **LearningDITA (free courses)**: https://learningdita.com/
- **Oxygen DITA authoring**: https://www.oxygenxml.com/
- **DITA-OT download**: https://www.dita-ot.org/download

## Installation & Setup
```bash
# Download and unpack DITA-OT (requires Java 17+)
curl -LO https://github.com/dita-ot/dita-ot/releases/download/3.7.4/dita-ot-3.7.4.zip
unzip dita-ot-3.7.4.zip
export PATH="$PWD/dita-ot-3.7.4/bin:$PATH"

dita --version
# Build a deliverable:
dita --input=myguide.ditamap --format=html5  --output=out/html
dita --input=myguide.ditamap --format=pdf    --output=out/pdf
dita --input=myguide.ditamap --format=markdown_gitbook --output=out/md
```

## Core Concepts & Syntax

### Topic types (information typing)
DITA's premise: classify each unit of content by *what kind of information it is*.
- **Concept** — explanatory ("what is / why").
- **Task** — step-by-step procedure ("how to").
- **Reference** — structured lookup (APIs, parameters, specs).
- **Glossary entry** — term + definition.
- **Troubleshooting** — condition/cause/remedy (DITA 1.3+).

### Concept topic
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE concept PUBLIC "-//OASIS//DTD DITA Concept//EN" "concept.dtd">
<concept id="what-is-widget">
  <title>What is a Widget?</title>
  <shortdesc>A widget is the core unit of the system.</shortdesc>
  <conbody>
    <p>Widgets encapsulate <term>state</term> and behavior.</p>
    <note type="tip">Widgets are reusable across products.</note>
  </conbody>
</concept>
```

### Task topic (procedures)
```xml
<!DOCTYPE task PUBLIC "-//OASIS//DTD DITA Task//EN" "task.dtd">
<task id="install-widget">
  <title>Installing the Widget</title>
  <taskbody>
    <prereq>Ensure you have admin rights.</prereq>
    <steps>
      <step><cmd>Download the installer.</cmd>
        <info>Get it from the downloads page.</info>
      </step>
      <step><cmd>Run <userinput>setup.exe</userinput>.</cmd>
        <stepresult>The wizard opens.</stepresult>
      </step>
    </steps>
    <result>The widget is installed.</result>
  </taskbody>
</task>
```
`<steps>`/`<step>`/`<cmd>` is the strict task model; `<cmd>` (the imperative action) is required in each step.

### Reference topic
```xml
<!DOCTYPE reference PUBLIC "-//OASIS//DTD DITA Reference//EN" "reference.dtd">
<reference id="widget-api">
  <title>Widget API</title>
  <refbody>
    <properties>
      <property><proptype>timeout</proptype><propvalue>30s</propvalue>
        <propdesc>Connection timeout.</propdesc></property>
    </properties>
  </refbody>
</reference>
```

### Maps (organize topics into deliverables)
```xml
<!DOCTYPE map PUBLIC "-//OASIS//DTD DITA Map//EN" "map.dtd">
<map>
  <title>Widget Guide</title>
  <topicref href="concepts/what-is-widget.dita"/>
  <topicref href="tasks/install-widget.dita">
    <topicref href="tasks/configure-widget.dita"/>   <!-- nested = hierarchy -->
  </topicref>
  <topicref href="reference/widget-api.dita" toc="yes"/>
</map>
```
Maps carry **no content** — they assemble topics into a TOC/hierarchy and set relationships. A **bookmap** adds front/back matter, chapters, and appendices for book output.

## Reuse Mechanisms (the core value)

### Content reference (conref)
```xml
<!-- Define reusable content once (warehouse topic) -->
<note id="admin-warning" type="warning">Requires administrator privileges.</note>

<!-- Pull it in anywhere by id -->
<note conref="warehouse.dita#warehouse/admin-warning"/>
```
`conref` transcludes a single element from another topic — edit once, update everywhere.

### Keys and key references (indirection)
```xml
<!-- In the map: bind a key to a resource/value -->
<map>
  <keydef keys="product-name"><topicmeta><keywords><keyword>Acme Cloud</keyword></keywords></topicmeta></keydef>
  <keydef keys="download-url" href="https://example.com/dl"/>
</map>

<!-- In topics: reference by key, not by path -->
<p>Welcome to <keyword keyref="product-name"/>.</p>
<xref keyref="download-url">the download page</xref>
```
Keys decouple references from targets — swap product names or URLs per build without touching topics. This is DITA's most powerful reuse feature.

### Conditional processing (filtering)
```xml
<p audience="admin">Admin-only paragraph.</p>
<p product="pro">Pro edition feature.</p>
<step platform="windows"><cmd>Run setup.exe</cmd></step>
```
```xml
<!-- filter.ditaval -->
<val>
  <prop att="audience" val="admin" action="exclude"/>
  <prop att="product"  val="pro"   action="include"/>
</val>
```
```bash
dita --input=guide.ditamap --format=pdf --args.filter=filter.ditaval
```
`@audience`/`@product`/`@platform`/`@rev` metadata + a `.ditaval` file produce audience-specific deliverables from one source.

## How-To (worked recipes)

### How to style / add colors to output
DITA source is presentation-free; styling happens in the **DITA-OT plugin / XSLT / CSS layer**. For HTML5, supply a custom CSS via a plugin or the `args.css` parameter:
```bash
dita --input=guide.ditamap --format=html5 \
     --args.css=brand.css --args.copy.css=yes --args.cssroot=styles
```
```css
/* styles/brand.css */
.topictitle1 { color: #1e6fba; }
.note_tip { border-left: 4px solid #1e6fba; background: #eef5fb; }
pre.pre { background: #f5f7fa; padding: .5rem; }
```
For **PDF**, override the PDF2/PDF-CSS plugin: DITA-OT 3.x supports a **CSS-based PDF** (`--format=pdf --args.css=brand.css`) as well as the classic XSL-FO customization. Colors, fonts, and page geometry are set in that plugin's CSS/attribute-sets — never in the topics.

### How to build a reusable warning once and transclude it
```xml
<!-- warehouse/notes.dita -->
<concept id="notes"><title>Notes</title><conbody>
  <note id="beta" type="caution">This feature is in beta.</note>
</conbody></concept>

<!-- any topic -->
<note conref="../warehouse/notes.dita#notes/beta"/>
```

### How to produce two audiences from one source
```xml
<section audience="internal">Internal deployment steps…</section>
<section audience="customer">Customer setup steps…</section>
```
```bash
dita -i guide.ditamap -f html5 --args.filter=internal.ditaval -o out/internal
dita -i guide.ditamap -f html5 --args.filter=customer.ditaval -o out/customer
```

### How to specialize a new topic type
Create a DTD/RNG that constrains or extends an existing type (e.g. an `apiReference` specialized from `reference`), plus a processing override. Specialization lets an organization add domain-specific structure while staying DITA-compatible and reusing the base processing. (Requires DTD/schema authoring — an architect-level task.)

## Do's and Don'ts

### ✅ Do
- **Type your topics** correctly (concept/task/reference) — the model enforces good structure and enables filtered/targeted output.
- Use **keyref** for product names, URLs, and cross-topic links so builds are portable and rebrandable.
- Keep **maps content-free** — they organize; topics hold content.
- Author in a **DITA-aware editor** (Oxygen, XMLmind) — hand-editing DITA XML is error-prone.
- Manage variants with **`.ditaval` conditions**, not copy-paste.

### ❌ Don't
- Don't put presentation/formatting in topics — style in the DITA-OT plugin/CSS.
- Don't overuse deep **conref chains** — they become hard to trace; prefer keyref where possible.
- Don't skip the **DOCTYPE / schema binding** — validation and specialization depend on it.
- Don't treat a `<task>` like free prose — each `<step>` needs a `<cmd>`; the schema is strict.
- Don't underestimate setup — DITA needs tooling, a CMS/CCMS at scale, and author training.

## Styling, Theming & Customization
- **DITA-OT plugins**: the unit of customization — bundle CSS/XSLT/params and install with `dita install`.
- **HTML5 transform**: `args.css`, custom XSLT overrides, header/footer injection.
- **PDF**: classic **PDF2** (XSL-FO attribute-sets) or modern **CSS-based PDF** (`org.dita.pdf` with CSS via a Prince/AntennaHouse/PDF processor).
- **Templates**: many orgs maintain a house plugin encapsulating brand fonts, colors, cover pages.

## Advanced Features
- **Specialization** — derive custom, still-compatible topic/domain types from base types.
- **Chunking** — merge/split topics into deliverable files (`@chunk`).
- **Relationship tables (reltables)** — define related-links between topics in the map, not inline.
- **Subject scheme maps** — controlled vocabularies for conditional-processing values.
- **Branch filtering (DITA 1.3)** — apply different `.ditaval` filters to different map branches in one build.
- **Metadata & indexing** — `<indexterm>`, `<keywords>`, prolog metadata for search/index.

## Common Pitfalls & Troubleshooting
- **Build fails on validation** → a topic violates its DTD/schema; open in a DITA editor to locate.
- **conref/keyref not resolving** → wrong id path, key not defined in the (root) map, or the map isn't the build input.
- **Condition not applied** → `.ditaval` not passed via `--args.filter`, or attribute value mismatch.
- **PDF looks unstyled** → no custom plugin; the default PDF2 output is plain — build a customization.
- **Java/DITA-OT errors** → wrong Java version; DITA-OT 3.7+ needs Java 17+.
- **Overwhelming setup** → start from the DITA-OT sample project + Oxygen; adopt a CCMS only when reuse scale demands it.

## Integration Notes
- **CCMS**: enterprise DITA usually pairs with a Component Content Management System (Tridion Docs, Paligo, easyDITA/Heretto) for reuse at scale.
- **Markdown bridge**: DITA-OT can ingest **Markdown/MDITA** (Lightweight DITA) and emit Markdown — a lower-barrier on-ramp.
- **Pandoc**: limited DITA support; DITA-OT is the canonical toolchain.
- **DocBook**: the main structured-XML alternative — DocBook is document-oriented, DITA is topic/reuse-oriented (see docbook.md).

## Best For / Avoid For
`enterprise-docs`, `topic-reuse`, `multi-product-docs`, `regulated-industries`, `localization-heavy`, `multi-channel-publishing` — choose DITA when reuse, conditional variants, and structured typing across large doc sets justify the tooling investment.
Avoid for: small projects, blogs, or READMEs (markdown.md, mkdocs.md), teams without XML tooling/authoring support, or document-centric books better served by DocBook (see docbook.md) or AsciiDoc (asciidoc.md).

## See Also
- `docbook.md` — the document-oriented structured-XML alternative
- `asciidoc.md`, `markdown.md` — lighter authoring (Markdown/MDITA can feed DITA-OT)
- `pandoc.md` — format conversion
- `../use-case/document-processing.md`
