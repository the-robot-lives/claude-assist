# SheetJS (xlsx) — Spreadsheet Parsing & Writing

SheetJS ("xlsx") is a JavaScript library for **reading, transforming, and writing** spreadsheets across dozens of formats — XLSX/XLSM, XLS, CSV, TXT, ODS, and HTML tables — in Node, the browser, and other JS runtimes with no native dependencies. Its data model is a workbook of worksheets, each an A1-addressed grid of cell objects. Utility functions convert between worksheets and arrays-of-objects/arrays-of-arrays, so it's equally a parser, a report generator, and a format converter.

**Current Version**: xlsx (SheetJS CE) 0.20.x (current)  **License**: Apache-2.0 (Community Edition)  **Runtime**: Node, browsers, Deno, Bun — pure JS.

> SheetJS now distributes primarily from its **own CDN/registry** rather than npm. The classic `npm install xlsx` still resolves an older build; prefer the documented tarball/CDN for current releases.

## Official Resources & Documentation
- Docs: https://docs.sheetjs.com/
- Data model / cells: https://docs.sheetjs.com/docs/csf/
- Home: https://sheetjs.com/
- GitHub: https://github.com/SheetJS/sheetjs

## Installation & Setup

### Package manager / CDN
```bash
npm install xlsx    # classic path (older CE build)
# current CE (recommended by SheetJS):
npm install https://cdn.sheetjs.com/xlsx-0.20.3/xlsx-0.20.3.tgz
```
```html
<script src="https://cdn.sheetjs.com/xlsx-0.20.3/package/dist/xlsx.full.min.js"></script>
```

### Import styles
```javascript
import * as XLSX from 'xlsx';         // ESM
const XLSX = require('xlsx');         // CJS
// Node file I/O needs the fs helper wired up in some builds:
import * as XLSX from 'xlsx';
import * as fs from 'fs'; XLSX.set_fs(fs);
```

## The Data Model (Common Spreadsheet Format)
- **Workbook**: `{ SheetNames: string[], Sheets: { [name]: Worksheet } }`
- **Worksheet**: map of A1 addresses → cell objects, plus a `!ref` range and metadata (`!cols`, `!rows`, `!merges`).
- **Cell**: `{ v, t, f, w, z, s }`
  - `v` raw value, `t` type (`n` number, `s` string, `b` boolean, `d` date, `e` error), `f` formula (no `=`), `w` formatted text, `z` number format, `s` style (Pro).

```javascript
worksheet['B2'];            // { t:'n', v:42, w:'42' }
XLSX.utils.encode_cell({ r: 1, c: 1 });  // 'B2'  (0-indexed row/col)
XLSX.utils.decode_range('A1:C10');       // { s:{r,c}, e:{r,c} }
```

## Core API Reference

### Reading
```javascript
const wb = XLSX.readFile('data.xlsx', { cellDates: true });   // Node
const wb = XLSX.read(arrayBuffer, { type: 'array', cellDates: true }); // browser/Buffer
// type: 'array' | 'buffer' | 'binary' | 'base64' | 'string'
const ws = wb.Sheets[wb.SheetNames[0]];
```

### Worksheet → data
```javascript
const objs = XLSX.utils.sheet_to_json(ws);                    // [{Col1:..,Col2:..}] using header row
const rows = XLSX.utils.sheet_to_json(ws, { header: 1 });     // [[...],[...]] raw grid
const csv  = XLSX.utils.sheet_to_csv(ws, { FS: ',', RS: '\n' });
const txt  = XLSX.utils.sheet_to_txt(ws);                     // tab-separated, UTF-16
const html = XLSX.utils.sheet_to_html(ws);
const withBlanks = XLSX.utils.sheet_to_json(ws, { defval: null, raw: false }); // keep empties, formatted text
```

### Data → worksheet
```javascript
const ws1 = XLSX.utils.json_to_sheet([{ name: 'A', qty: 3 }, { name: 'B', qty: 7 }]);
const ws2 = XLSX.utils.aoa_to_sheet([['Name', 'Qty'], ['A', 3], ['B', 7]]);
const ws3 = XLSX.utils.table_to_sheet(document.getElementById('myTable'));
```

### Assembling & writing
```javascript
const wb = XLSX.utils.book_new();
XLSX.utils.book_append_sheet(wb, ws1, 'Items');       // sheet name ≤ 31 chars, no []*?/\:
XLSX.writeFile(wb, 'out.xlsx');                       // Node download / browser save
XLSX.writeFile(wb, 'out.csv');                        // format inferred from extension
const buf = XLSX.write(wb, { type: 'array', bookType: 'xlsx' }); // -> ArrayBuffer for upload/Blob
```
`bookType`: `xlsx | xlsm | xlsb | xls | csv | txt | html | ods`.

### Editing cells & ranges
```javascript
XLSX.utils.sheet_add_aoa(ws, [['Total', 10]], { origin: -1 });  // append at end
XLSX.utils.sheet_add_json(ws, moreRows, { origin: 'A5', skipHeader: true });
ws['C1'] = { t: 's', v: 'Note' };
ws['!merges'] = [XLSX.utils.decode_range('A1:C1')];             // merge header
ws['!cols'] = [{ wch: 20 }, { wch: 8 }];                        // column widths (chars)
```

### Formulas
```javascript
ws['C2'] = { t: 'n', f: 'A2*B2' };                 // set a formula (cached value optional in v)
const wb = XLSX.readFile('f.xlsx', { cellFormula: true }); // read formulas
```
SheetJS **stores and round-trips** formulas; it does not recalculate them — Excel computes cached results on open.

## Supported Formats
Read & write: **XLSX, XLSM, XLSB, XLS, CSV, TXT, ODS, HTML** (+ more on read: DBF, DIF, SYLK, Lotus, Numbers read). Autodetected on read; chosen by extension or `bookType` on write.

## How-To (worked recipes)

### How to parse an uploaded file in the browser
```javascript
input.addEventListener('change', async (e) => {
  const buf = await e.target.files[0].arrayBuffer();
  const wb = XLSX.read(buf, { type: 'array', cellDates: true });
  const rows = XLSX.utils.sheet_to_json(wb.Sheets[wb.SheetNames[0]]);
  console.table(rows);
});
```

### How to export JSON/DB rows to a styled-ish XLSX
```javascript
const data = await db.query('SELECT sku, name, qty, price FROM items');
const ws = XLSX.utils.json_to_sheet(data);
ws['!cols'] = [{ wch: 10 }, { wch: 28 }, { wch: 6 }, { wch: 10 }];
ws['!autofilter'] = { ref: ws['!ref'] };                 // header dropdowns
const wb = XLSX.utils.book_new();
XLSX.utils.book_append_sheet(wb, ws, 'Inventory');
XLSX.writeFile(wb, 'inventory.xlsx');
```
Rich cell styling (fills, fonts, borders) is a **Pro** feature; CE writes values, number formats, widths, merges, and autofilters.

### How to convert XLSX → CSV (all sheets)
```javascript
const wb = XLSX.readFile('book.xlsx');
wb.SheetNames.forEach(name => {
  const csv = XLSX.utils.sheet_to_csv(wb.Sheets[name]);
  fs.writeFileSync(`${name}.csv`, csv);
});
```

### How to control types, dates, and blank handling
```javascript
XLSX.utils.sheet_to_json(ws, {
  raw: false,      // return formatted strings (w) instead of raw values
  defval: '',      // fill missing cells instead of omitting keys
  dateNF: 'yyyy-mm-dd',
  header: ['id', 'name', 'created'],   // force column keys, ignore sheet header
  range: 1,        // skip the first row
});
```

## Do's and Don'ts

### ✅ Do
- Pass `cellDates: true` on read so date cells come back as JS `Date`, not serial numbers.
- Use `{ header: 1 }` when the sheet has no clean header row or you need positional access.
- Keep sheet names ≤ 31 chars and free of `[ ] * ? / \ :` — Excel rejects invalid names.
- Stream or chunk very large exports; build worksheets incrementally with `sheet_add_aoa`.
- Choose output by `bookType` explicitly when writing to a Buffer (extension inference only works with `writeFile`).

### ❌ Don't
- Don't expect formulas to be **evaluated** — SheetJS stores `f`; the spreadsheet app recalculates.
- Don't expect charts, images, pivot tables, or VBA macros to survive — CE ignores embedded objects.
- Don't rely on full style fidelity in CE — advanced formatting needs SheetJS Pro.
- Don't load 100 MB+ files naively in the browser — parse in a Worker and watch memory.
- Don't confuse `v` (raw) with `w` (display text); dates especially differ.

### How to build a multi-sheet workbook with a summary tab
```javascript
const wb = XLSX.utils.book_new();
XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(orders),   'Orders');
XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(refunds),  'Refunds');
const summary = XLSX.utils.aoa_to_sheet([
  ['Metric', 'Value'],
  ['Orders', orders.length],
  ['Refunds', refunds.length],
  ['Net', orders.length - refunds.length],
]);
summary['B4'] = { t: 'n', f: 'B2-B3' };            // live formula in the summary
XLSX.utils.book_append_sheet(wb, summary, 'Summary');
wb.SheetNames.unshift(wb.SheetNames.pop());        // move Summary to front
XLSX.writeFile(wb, 'report.xlsx');
```

### How to stream a large CSV without loading it all
```javascript
// Node: the stream helpers avoid holding the whole workbook in memory
import { stream } from 'xlsx';
const out = fs.createWriteStream('big.csv');
const csvStream = stream.to_csv(worksheet);
csvStream.pipe(out);
// For reads of huge files, prefer parsing CSV line-by-line with a dedicated CSV parser.
```

## Number Formats & Cell Types
Set `z` (a format code) to control display without changing the raw value:
```javascript
ws['B2'] = { t: 'n', v: 1234.5, z: '#,##0.00' };     // 1,234.50
ws['C2'] = { t: 'n', v: 0.184,  z: '0.0%' };          // 18.4%
ws['D2'] = { t: 'd', v: new Date(), z: 'yyyy-mm-dd' };
```
Common codes: `'0'`, `'#,##0'`, `'#,##0.00'`, `'0%'`, `'0.0%'`, `'$#,##0.00'`, `'yyyy-mm-dd'`, `'h:mm:ss'`.

## Integration Notes
- **Browser download**: `writeFile` in a browser triggers a save via a synthesized anchor; for uploads use `write(wb, { type: 'array' })` → `new Blob([buf])`.
- **Web Workers**: parse large files off the main thread; pass the `ArrayBuffer` in, post rows out.
- **React/Vue**: keep the workbook out of component state (it's large/non-serializable); store only the derived rows.
- **Node ESM**: some builds need `XLSX.set_fs(fs)` and `XLSX.stream` wired before `readFile`/stream helpers work.

## Common Pitfalls & Troubleshooting
- *Dates show as 45000-ish numbers* → add `cellDates: true` (read) or a `z` number format (write).
- *`sheet_to_json` drops columns* → those rows had blank cells; add `defval`.
- *Formulas gone after round-trip* → read with `cellFormula: true`; note cached values may be stale until recalc.
- *`readFile` fails in the browser* → there's no filesystem; use `read` with an ArrayBuffer.
- *Garbled CSV in Excel* → prepend a UTF-8 BOM or use `sheet_to_txt` (UTF-16) for non-ASCII.

## Best For / Avoid For
`xlsx-parse`, `csv-parse`, `report-export`, `format-conversion`, `data-import`, `client-side-excel` — the standard for spreadsheet I/O in JS.
Avoid for: pixel-accurate Excel styling/charts in CE, formula computation, or embedded-object preservation.

## See Also
- `mammoth_js.md` — the DOCX (word-processing) analog for documents-as-data
- `html.md` — `sheet_to_html` / `table_to_sheet` bridge between tables and pages
- `pdfkit.md` / `jspdf.md` — render spreadsheet-derived data into PDF reports
- `../use-case/data-processing.md`, `../use-case/document-generation.md`
