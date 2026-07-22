# SheetJS

## What
SheetJS (the `xlsx` library) is a comprehensive spreadsheet parser and writer for Excel formats (XLSX, XLS, CSV, ODS, and 20+ others) in JavaScript, with no external dependencies. It runs in both browser and Node.js; the LLM emits read/transform/write code that moves data between spreadsheets and JSON.

## How
- **LLM emits:** JS using `XLSX.readFile('data.xlsx')` → `XLSX.utils.sheet_to_json(worksheet)` to ingest, and `XLSX.utils.book_new()` / `json_to_sheet(data)` / `book_append_sheet(...)` / `XLSX.writeFile(wb, 'output.xlsx')` to emit.
- **Render path:** `npm install xlsx`. Read a workbook, pull sheets by name, convert to/from JSON, then write a new file (or generate client-side in the browser without a server round-trip).
- **Typical final artifact:** XLSX/XLS/CSV/ODS spreadsheet file (or in-memory JSON).

## Why
- **Reach for it when:** you need Excel import/export in a web app, batch spreadsheet processing, format conversion, or report generation from JSON/database data — including client-side file generation.
- **Limitations:** memory-intensive on files >100MB, limited style/formatting preservation, cannot process embedded charts/images, and no VBA-macro support.
- **Relative to siblings:** SheetJS is the tabular-data member of the document-file group — where pdfkit/jsPDF emit PDFs and Mammoth reads Word, SheetJS is the read/write bridge for spreadsheets specifically.

## Source
- Solution reference: `fim/solution/sheetjs.md`
