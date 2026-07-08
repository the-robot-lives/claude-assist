# DocBook — XML schema for technical documentation

DocBook is an OASIS-standard XML vocabulary for authoring books, articles, and technical manuals with rich semantic markup. Content is written as validated XML and transformed via XSLT stylesheets into HTML, PDF (through XSL-FO), EPUB, and man pages — the archetypal single-source publishing pipeline. Long dominant in open-source and enterprise documentation (Linux kernel, O'Reilly, GNOME historically).

**Current Version**: DocBook 5.1 (RELAX NG schema; 5.2 in progress)  **License**: OASIS open standard  **Runtime**: any XML/XSLT toolchain — `xsltproc` + docbook-xsl, `fop` (PDF), Saxon; or `dblatex`

## Official Resources & Documentation
- **DocBook.org**: https://docbook.org/
- **"DocBook: The Definitive Guide"**: https://tdg.docbook.org/
- **Schema (5.1)**: https://docbook.org/xml/5.1/
- **XSLT stylesheets**: https://github.com/docbook/xslt10-stylesheets
- **DocBook XSL-NS (namespaced)**: https://github.com/docbook/wiki/wiki
- **Apache FOP (PDF)**: https://xmlgraphics.apache.org/fop/
- **dblatex (PDF via LaTeX)**: https://dblatex.sourceforge.net/

## Installation & Setup
```bash
# Debian/Ubuntu
apt-get install docbook-xsl docbook5-xml xsltproc fop

# macOS
brew install docbook docbook-xsl fop

# Validate against the RELAX NG schema
xmllint --noout --relaxng docbook.rng document.xml
jing docbook.rng document.xml        # alternative RELAX NG validator
```

## Document Structure

### Article vs book
```xml
<?xml version="1.0" encoding="UTF-8"?>
<book xmlns="http://docbook.org/ns/docbook" version="5.1" xml:lang="en">
  <info>
    <title>Administration Guide</title>
    <author><personname><firstname>Ada</firstname><surname>Lovelace</surname></personname></author>
    <pubdate>2024-06-01</pubdate>
  </info>

  <chapter xml:id="intro">
    <title>Introduction</title>
    <para>Welcome to the <emphasis>guide</emphasis>.</para>

    <section xml:id="install">
      <title>Installation</title>
      <para>Run the installer.</para>
    </section>
  </chapter>
</book>
```
Top-level elements: `<book>` (chapters), `<article>` (sections, no chapters), `<set>` (collection of books). Every division carries a `<title>`; `xml:id` enables cross-references. DocBook 5 lives in the `http://docbook.org/ns/docbook` namespace (unlike DocBook 4).

### Inline semantic markup
```xml
<para>
  Use <command>ls</command> to list files. The
  <function>malloc()</function> call returns a
  <type>void*</type>. Set the <envar>PATH</envar> variable to
  <filename>/usr/local/bin</filename>. Press
  <keycap>Enter</keycap>. Visit <link xlink:href="https://example.com">the site</link>.
  A <emphasis role="strong">strong</emphasis> point.
</para>
```
DocBook's value is its **semantic inline vocabulary**: `<command>`, `<function>`, `<varname>`, `<option>`, `<filename>`, `<guimenu>`, `<keycap>`, `<userinput>`, `<replaceable>`, `<classname>`, `<type>` — markup describes *what* text is, not how it looks.

### Code, admonitions, lists
```xml
<programlisting language="python"><![CDATA[
def example():
    return "code sample"
]]></programlisting>

<note><para>Informational aside.</para></note>
<warning><para>Critical caution.</para></warning>
<tip><para>Helpful hint.</para></tip>

<itemizedlist>
  <listitem><para>Bullet item</para></listitem>
</itemizedlist>
<orderedlist>
  <listitem><para>Numbered item</para></listitem>
</orderedlist>
<variablelist>
  <varlistentry><term>Term</term><listitem><para>Definition</para></listitem></varlistentry>
</variablelist>
```
Use `<![CDATA[...]]>` around code so `<`, `>`, `&` don't need escaping. Admonition types: `note`, `tip`, `important`, `caution`, `warning`.

### Media, tables, cross-references
```xml
<figure xml:id="fig-arch">
  <title>Architecture</title>
  <mediaobject>
    <imageobject><imagedata fileref="arch.png" width="600"/></imageobject>
    <textobject><phrase>Architecture diagram</phrase></textobject>
  </mediaobject>
</figure>

<table xml:id="tab-pricing" frame="all">
  <title>Pricing</title>
  <tgroup cols="2">
    <thead><row><entry>Item</entry><entry>Price</entry></row></thead>
    <tbody>
      <row><entry>Widget</entry><entry>9.99</entry></row>
    </tbody>
  </tgroup>
</table>

<para>See <xref linkend="fig-arch"/> and <xref linkend="tab-pricing"/>.</para>
<para>As explained in <link linkend="install">Installation</link>.</para>
```
`<xref linkend="id"/>` auto-generates "Figure 1"/"Table 2" text; `<link linkend="id">` uses custom text. Tables use the CALS model (`<tgroup>`/`<row>`/`<entry>`).

### Modular composition (XInclude)
```xml
<book xmlns="http://docbook.org/ns/docbook"
      xmlns:xi="http://www.w3.org/2001/XInclude" version="5.1">
  <xi:include href="chapters/intro.xml"/>
  <xi:include href="chapters/install.xml"/>
</book>
```
XInclude assembles a master document from per-chapter files — the DocBook approach to large-doc modularity.

## Transformation Pipeline

### HTML
```bash
xsltproc --output out.html \
  /usr/share/xml/docbook/stylesheet/docbook-xsl-ns/html/docbook.xsl document.xml

# Chunked (one file per chapter)
xsltproc --output out/ \
  .../html/chunk.xsl document.xml
```
### PDF (via XSL-FO + FOP)
```bash
xsltproc --output document.fo .../fo/docbook.xsl document.xml
fop -fo document.fo -pdf document.pdf
# Or the simpler dblatex path:
dblatex document.xml            # -> document.pdf (via LaTeX)
```
### EPUB
```bash
xsltproc .../epub3/chunk.xsl document.xml
```

## How-To (worked recipes)

### How to style / add colors to output
DocBook output styling is done through the **XSLT/CSS layer**, not the source (semantic markup stays presentation-free). For HTML, attach a stylesheet and set params:
```bash
xsltproc --stringparam html.stylesheet "custom.css" \
         --stringparam admon.graphics 1 \
         --output out.html .../html/docbook.xsl document.xml
```
```css
/* custom.css paired with the HTML output */
.programlisting { background: #f5f7fa; border-left: 3px solid #1e6fba; padding: .5rem; }
.note { border-left: 4px solid #1e6fba; background: #eef5fb; }
h1.title, h2.title { color: #1e6fba; }
```
For PDF, override XSL-FO attribute-sets in a **customization layer** stylesheet:
```xml
<!-- custom-fo.xsl -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fo="http://www.w3.org/1999/XSL/Format" version="1.0">
  <xsl:import href=".../fo/docbook.xsl"/>
  <xsl:attribute-set name="section.title.level1.properties">
    <xsl:attribute name="color">#1e6fba</xsl:attribute>
  </xsl:attribute-set>
</xsl:stylesheet>
```
The customization-layer pattern (import the stock stylesheet, override attribute-sets/params) is the canonical way to restyle DocBook output.

### How to build a customization layer for parameters
```xml
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:import href=".../html/docbook.xsl"/>
  <xsl:param name="section.autolabel" select="1"/>   <!-- number sections -->
  <xsl:param name="toc.section.depth" select="3"/>
  <xsl:param name="generate.toc">book toc,title</xsl:param>
</xsl:stylesheet>
```
Never edit the stock stylesheets; always import and override.

### How to cross-reference and auto-number
```xml
<section xml:id="config"><title>Configuration</title>...</section>
...
<para>Refer to <xref linkend="config"/>.</para>
```
`section.autolabel=1` makes `<xref>` render "Section 2.1"; without it you get the title text.

### How to author reusable content
```xml
<!-- Define once, reference by id -->
<para><phrase xml:id="product">Acme Cloud</phrase></para>
...
<!-- Pull via XInclude/xpointer or entity for shared snippets -->
<xi:include href="shared/legal.xml" xpointer="element(disclaimer)"/>
```

## Do's and Don'ts

### ✅ Do
- **Validate** against the RELAX NG schema (`jing`/`xmllint`) before transforming — DocBook's strictness is the point.
- Use the **most specific semantic element** (`<command>`, `<filename>`) rather than generic `<emphasis>`.
- Build a **customization layer** (import + override) instead of editing stock XSL.
- Wrap code in **`<![CDATA[...]]>`** to avoid escaping.
- Use **`xml:id` + `<xref>`** for numbered, maintainable cross-references.

### ❌ Don't
- Don't mix **DocBook 4 (no namespace) and 5 (namespaced)** markup — the toolchains differ (`docbook-xsl` vs `docbook-xsl-ns`).
- Don't put presentation in the source — color/layout belong in XSLT/CSS.
- Don't hand-edit the shipped stylesheets — upgrades will clobber your changes.
- Don't forget the **namespace declaration** on the root element in DocBook 5.
- Don't nest block elements where the schema forbids it — validate to catch it early.

## Styling, Theming & Customization
- **HTML**: `html.stylesheet` param + CSS; `admon.graphics`, `chunk.section.depth`, `generate.toc`.
- **PDF (FO)**: override `*.properties` attribute-sets (fonts, colors, margins, page-masters) in a customization layer.
- **PDF (dblatex)**: simpler LaTeX-based path with its own style options.
- **Params**: hundreds of documented XSL params control numbering, TOC, labeling, callouts.
- **Custom elements**: extend via schema customization (adding/restricting elements).

## Advanced Features
- **Profiling (conditional text)**: `<para condition="pro">` + `--stringparam profile.condition pro` for audience-specific builds.
- **Callouts**: `<co>`/`<calloutlist>` annotate code lines with numbered markers.
- **Olink**: cross-document linking across separately built DocBook sets.
- **CALS + HTML tables**: two table models supported.
- **Bibliographies, glossaries, indexes**: first-class elements (`<bibliography>`, `<glossary>`, `<indexterm>`).
- **MathML/SVG**: embeddable for equations and vector graphics.

## Common Pitfalls & Troubleshooting
- **"element not allowed here"** → schema violation; validate and fix nesting.
- **Namespace errors / empty output** → DocBook 5 doc processed with DocBook 4 (non-NS) stylesheets; use the `-ns` stylesheets.
- **Broken image in PDF** → FOP needs a supported format/path; check `fileref` and image plugins.
- **`<xref>` shows title, not number** → set `section.autolabel=1`.
- **Fonts missing in PDF** → configure FOP's font metrics/config file.
- **Slow/complex builds** → the XSLT pipeline is heavy; consider AsciiDoc → DocBook authoring (see asciidoc.md) to avoid hand-writing XML.

## Integration Notes
- **AsciiDoc** converts to DocBook (`asciidoctor -b docbook5`), giving a friendlier authoring front-end (see asciidoc.md).
- **Pandoc** reads/writes DocBook for migration (see pandoc.md).
- **Publican / DAPS** are higher-level DocBook build systems (Red Hat / SUSE).
- **DITA** is the main structured-XML alternative (see dita.md).

## Best For / Avoid For
`enterprise-docs`, `books`, `technical-manuals`, `single-source-publishing`, `archival`, `regulated-industries` — choose DocBook when you need validated, semantic, long-lived XML with multi-format output and strong tooling.
Avoid for: quick docs or blogs (markdown.md, mkdocs.md), teams unwilling to author XML (use asciidoc.md → DocBook), or topic-oriented reuse-heavy content where DITA fits better (see dita.md).

## See Also
- `asciidoc.md` — friendlier authoring that outputs DocBook
- `dita.md` — the other enterprise structured-XML standard
- `pandoc.md` — convert DocBook to/from other formats
- `latex.md` — dblatex PDF backend relies on it
- `../use-case/document-processing.md`
