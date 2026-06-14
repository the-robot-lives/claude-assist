# EPUB - FIM Solution Documentation

## Description
[EPUB](https://www.w3.org/publishing/epub3/) is the open ebook standard (a zipped package of XHTML, CSS, images, and an OPF manifest) read by Apple Books, Kobo, Google Play Books, and most e-readers. It is the primary deliverable format for lead magnets, gated guides, and paid digital books in a content-publishing funnel. MOBI/KF8 (Kindle) is typically generated from EPUB via Kindle Previewer/`kindlegen`.

## Basic Authoring
```bash
# Markdown -> EPUB with Pandoc (fastest path)
pandoc book.md -o book.epub \
  --metadata title="The Rate Limiting Handbook" \
  --metadata author="Keith" \
  --toc --toc-depth=2 \
  --epub-cover-image=cover.png \
  --css=epub.css
```
```python
# Programmatic EPUB with EbookLib
from ebooklib import epub
book = epub.EpubBook()
book.set_identifier("id-001")
book.set_title("The Rate Limiting Handbook")
book.add_author("Keith")
c1 = epub.EpubHtml(title="Intro", file_name="intro.xhtml",
                   content="<h1>Intro</h1><p>Hello.</p>")
book.add_item(c1)
book.toc = (c1,)
book.spine = ["nav", c1]
book.add_item(epub.EpubNcx()); book.add_item(epub.EpubNav())
epub.write_epub("book.epub", book)
```

## Toolchain
- **Pandoc** - Markdown/HTML -> EPUB3 with TOC, cover, and CSS
- **EbookLib** (Python) - Programmatic EPUB assembly
- **Sigil** - WYSIWYG EPUB editor for manual polish
- **epubcheck** - W3C validator for spec compliance
- **Kindle Previewer / kindlegen** - EPUB -> MOBI/KF8 for Amazon

## Strengths
- Open, reflowable standard supported across nearly all e-readers
- Single source (Markdown) converts cleanly via Pandoc
- Supports cover, TOC, metadata, embedded fonts, and CSS styling
- Natural fit for monetizable long-form content and lead magnets
- Validatable with epubcheck before distribution

## Limitations
- Fixed-layout/complex design is harder than reflowable text
- Kindle requires a separate MOBI/KF8 conversion step
- Reader CSS support varies; test across devices
- Interactive/JS content is unreliable across e-readers

## Best Use Cases
- Gated ebook lead magnets for email capture
- Paid digital books and course handbooks
- Compiling a blog series into a downloadable guide
- Multi-format publishing (EPUB + PDF) from one Markdown source

## NPL-FIM Integration
```npl
⌜epub-build|epub|FIM@1.0⌝
format: epub3
source: markdown
builder: pandoc | ebooklib
assets: [cover.png, epub.css]
validate: epubcheck
derive: mobi (kindle-previewer)
⌞epub-build⌟
```

NPL agents package long-form content as EPUB (commonly via Pandoc) when the deliverable is a distributable or sellable ebook, optionally deriving a Kindle MOBI.
