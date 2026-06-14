# MediaWiki (Wikitext) - FIM Solution Documentation

## Description
[Wikitext](https://www.mediawiki.org/wiki/Wikitext) is the markup language used by MediaWiki, the engine behind Wikipedia and most corporate/community wikis. It supports templates, transclusion, categories, infoboxes, and reference footnotes, making it the target format for publishing into wiki knowledge bases.

## Basic Syntax
```mediawiki
== Overview ==
A '''rate limiter''' controls request flow. It is ''essential'' for APIs.

* Bullet item
*# Nested numbered item

[[Token bucket]] and [[Leaky bucket]] are common algorithms.<ref>RFC 6585</ref>

{| class="wikitable"
! Algorithm !! Burst
|-
| Token bucket || yes
|}

[[Category:Systems Design]]
== References ==
<references/>
```

## Toolchain
- **MediaWiki API** (`action=edit`) - Programmatic page creation/updates
- **Pandoc** - Converts Markdown/HTML <-> MediaWiki markup
- **mwparserfromhell** (Python) - Parse and manipulate wikitext/templates
- **Pywikibot** - Bot framework for bulk publishing and edits
- **wikitextparser** - Lightweight Python wikitext parsing

## Strengths
- Native format for Wikipedia and Confluence-alternative wikis
- Powerful templating and transclusion for reusable content blocks
- Built-in categories, references, and cross-linking
- Mature bot/API ecosystem for automated publishing
- Pandoc bridge from Markdown lowers authoring friction

## Limitations
- Idiosyncratic syntax (tables, templates) with a learning curve
- Behavior depends on installed extensions and templates per wiki
- Poor fit for component-driven or interactive content
- Round-tripping complex templates via Pandoc is lossy

## Best Use Cases
- Publishing documentation into MediaWiki/Wikipedia-style knowledge bases
- Internal engineering wikis with templated runbooks
- Syndicating Markdown articles to a wiki via Pandoc conversion
- Bulk page generation/updates through the MediaWiki API

## NPL-FIM Integration
```npl
⌜mediawiki-publish|wikitext|FIM@1.0⌝
format: wikitext
convert_from: markdown (pandoc)
publish: mediawiki-api | pywikibot
features: [templates, categories, references]
⌞mediawiki-publish⌟
```

NPL agents emit wikitext (often via Pandoc from Markdown) when the distribution target is a MediaWiki-based knowledge base.
