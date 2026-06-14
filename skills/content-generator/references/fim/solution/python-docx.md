# python-docx - FIM Solution Documentation

## Description
[python-docx](https://python-docx.readthedocs.io) generates and edits Microsoft Word `.docx` files programmatically — headings, styled paragraphs, tables, images, page breaks, and sections. It is the authoring counterpart to `mammoth_js` (which only reads DOCX -> HTML), closing the gap for producing Word deliverables like reports, whitepapers, and client-ready documents.

## Basic Syntax
```python
from docx import Document
from docx.shared import Pt, Inches

doc = Document()
doc.add_heading("Rate Limiting Handbook", level=0)
doc.add_heading("Overview", level=1)
p = doc.add_paragraph("A rate limiter controls request flow. ")
p.add_run("Essential for APIs.").bold = True

table = doc.add_table(rows=1, cols=2)
table.style = "Light Grid Accent 1"
hdr = table.rows[0].cells
hdr[0].text, hdr[1].text = "Algorithm", "Burst"
row = table.add_row().cells
row[0].text, row[1].text = "Token bucket", "yes"

doc.add_picture("diagram.png", width=Inches(5))
doc.save("handbook.docx")
```

## Toolchain
- **python-docx** - Core create/edit library
- **docxtpl** - Jinja2 templating over a `.docx` template for mail-merge style fills
- **Pandoc** - Markdown/HTML -> DOCX as an alternative path
- **docxcompose** - Merge multiple documents
- **Styles** - Apply built-in or template-defined Word styles for branding

## Strengths
- Native, editable `.docx` output (not a PDF render)
- Full control over headings, tables, images, sections, and styles
- Template-driven generation via docxtpl for repeatable reports
- Pairs with corporate Word templates for on-brand deliverables
- Pure Python — easy to automate in pipelines

## Limitations
- No reliable rendering/preview (must open in Word/LibreOffice)
- Complex layout (text boxes, advanced floats) is limited
- Does not convert to PDF itself (needs LibreOffice/Word)
- Style fidelity depends on the base template

## Best Use Cases
- Client-ready reports, whitepapers, and proposals as Word files
- Templated/merge documents (per-customer one-pagers)
- Converting validated article abstracts into editable DOCX
- Deliverables where the recipient expects to edit in Word

## NPL-FIM Integration
```npl
⌜docx-author|docx|FIM@1.0⌝
format: docx
builder: python-docx | docxtpl | pandoc
template: corporate.dotx
assets: [images, tables]
output: editable-word-doc
⌞docx-author⌟
```

NPL agents author DOCX (via python-docx or a docxtpl template) when the deliverable must be an editable Word document rather than a fixed PDF.
