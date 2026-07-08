# packetdiag — Packet / byte-field header diagram generator from text

packetdiag renders protocol packet-format diagrams (the RFC-style bit/byte grids) from a compact text grammar: you declare each field as a bit range (`0-15: Source Port`) and packetdiag lays out the rows, bit rulers, and field boxes automatically. It is part of the *blockdiag family* and ships inside the `nwdiag` package, sharing the `{ }` block grammar. Output is PNG, SVG, or PDF via a Python CLI.

**Current Version**: packetdiag 3.x (ships with nwdiag 3.0.0+)  **License**: Apache 2.0  **Runtime**: Python 3.7+ CLI (no browser)

## Official Resources & Documentation
- Home / docs: http://blockdiag.com/en/nwdiag/packetdiag-examples.html
- GitHub: https://github.com/blockdiag/nwdiag
- PyPI (bundled): https://pypi.org/project/nwdiag/
- Sphinx extension: https://pypi.org/project/sphinxcontrib-nwdiag/

## Installation & Setup
```bash
pip install nwdiag                     # provides packetdiag (+ nwdiag, rackdiag)
pip install "nwdiag[pdf]"              # reportlab-backed PDF output
pip install sphinxcontrib-nwdiag       # Sphinx directives (packetdiag directive included)
```
CLI rendering (command is `packetdiag`):
```bash
packetdiag tcp.diag                    # -> tcp.png
packetdiag tcp.diag -T svg -o tcp.svg  # SVG
packetdiag tcp.diag -T pdf -o tcp.pdf  # PDF (needs [pdf] extra)
packetdiag -f /path/Font.ttf tcp.diag  # embed a TTF for non-ASCII labels
```

## Shared blockdiag-family Grammar
packetdiag wraps its body in `packetdiag { … }`. These diagram-level attributes come from the family; packetdiag-specific field syntax follows.

**Comments**: `// line` and `# line`.

**Diagram-level attributes**:
| attr | note |
|------|------|
| `colwidth` | **bits per row** (the row width); `32` is the standard IETF layout |
| `node_height` | height in px of each field row |
| `default_fontsize` | base label font size |
| `default_textcolor` | base label color |
| `default_node_color` | default field fill |
| `scale` | overall scale multiplier (rarely needed) |

**Field (node) attributes** — inside `[ ]` after a field: `color`, `textcolor`, `colheight` (make a field span N rows tall), `rotate` (rotate label, e.g. `270` for vertical text in a narrow single-bit field). Colors accept CSS names or `#rrggbb`.

**Classes** bundle reusable attributes: `class ctl [color = "#f4cccc"];` then `0-3: Flags [class = "ctl"];`.

## Core Syntax / packetdiag Fields
Each statement declares a field as a **bit range** followed by a label. Ranges are inclusive and must not overlap; they should tile the header contiguously from bit 0. A single-bit field uses one number.

```
start-end: Field Name [attr = value];   // multi-bit field
N: Field Name [attr = value];           // single-bit field
```

With `colwidth = 32`, bits 0–31 fill one row, 32–63 the next, and so on. packetdiag wraps automatically at the `colwidth` boundary and draws the bit ruler across the top.

```packetdiag
packetdiag {
  colwidth = 32;
  node_height = 72;
  default_fontsize = 12;

  0-15: Source Port;
  16-31: Destination Port;
  32-63: Sequence Number;      // spans a full row
  64-95: Ack Number;
}
```

**Single-bit fields** (control flags) each get one bit; rotate the label so it fits:
```packetdiag
packetdiag {
  colwidth = 32;
  96-99: Data Offset;
  100-105: Reserved;
  106: URG [rotate = 270];
  107: ACK [rotate = 270];
  108: PSH [rotate = 270];
  109: RST [rotate = 270];
  110: SYN [rotate = 270];
  111: FIN [rotate = 270];
  112-127: Window;
}
```

**Tall fields** spanning multiple rows use `colheight`:
```packetdiag
packetdiag {
  colwidth = 32;
  0-31: Header;
  32-159: Payload [colheight = 4];   // one box, 4 rows tall
}
```

**Colors per field**:
```packetdiag
packetdiag {
  colwidth = 32;
  0-15: Source Port [color = "#cfe2f3"];
  16-31: Destination Port [color = "#cfe2f3"];
  32-63: Sequence Number [color = "#d9ead3"];
  64-95: Ack Number [color = "#d9ead3"];
}
```

**Row width via `colwidth`** — set bits-per-row to match the protocol convention:
```packetdiag
packetdiag {
  colwidth = 16;        // 16-bit rows for a narrow protocol
  0-7: Type;
  8-15: Code;
  16-31: Checksum;      // wraps onto the next 16-bit row
}
```

## Diagram / Output Types — worked example (TCP header)
A complete RFC 793 TCP header. Note the 32-bit rows, the single-bit flag fields with rotated labels, and the color grouping by section.

```packetdiag
packetdiag {
  colwidth = 32;
  node_height = 72;
  default_fontsize = 11;

  // Ports
  0-15: Source Port [color = "#cfe2f3"];
  16-31: Destination Port [color = "#cfe2f3"];

  // Sequencing
  32-63: Sequence Number [color = "#d9ead3"];
  64-95: Acknowledgment Number [color = "#d9ead3"];

  // Offset / reserved / flags
  96-99: Data Offset [color = "#fff2cc"];
  100-105: Reserved [color = "#eeeeee"];
  106: URG [rotate = 270, color = "#f4cccc"];
  107: ACK [rotate = 270, color = "#f4cccc"];
  108: PSH [rotate = 270, color = "#f4cccc"];
  109: RST [rotate = 270, color = "#f4cccc"];
  110: SYN [rotate = 270, color = "#f4cccc"];
  111: FIN [rotate = 270, color = "#f4cccc"];
  112-127: Window [color = "#fce5cd"];

  // Integrity + options
  128-143: Checksum [color = "#d9d2e9"];
  144-159: Urgent Pointer [color = "#d9d2e9"];
  160-191: Options and Padding [color = "#e6f4ea"];
}
```

packetdiag targets **fixed-format binary headers**: TCP, UDP, IPv4/IPv6, ICMP, Ethernet, DNS, and any custom on-the-wire structure. For the network topology of those protocols use nwdiag (same package).

## How-To

### How to add colors, styling & themes
Group logically related fields under one color, factor repeats into a `class`, and set a baseline with `default_*`.
```packetdiag
packetdiag {
  colwidth = 32;
  node_height = 64;
  default_fontsize = 11;
  default_textcolor = "#1a1a2e";

  class addr [color = "#e0f2f1"];
  class ctrl [color = "#f4cccc"];

  0-15: Source Port [color = "#cfe2f3"];
  16-31: Destination Port [color = "#cfe2f3"];
  32-63: Source Address [class = "addr"];
  64-95: Destination Address [class = "addr"];
  96: SYN [rotate = 270, class = "ctrl"];
  97: ACK [rotate = 270, class = "ctrl"];
  98-127: Reserved [color = "#eeeeee"];
}
```

### How to lay out single-bit control flags
Give each flag one bit and `rotate = 270` so the label reads vertically in the narrow cell.
```packetdiag
packetdiag {
  colwidth = 32;
  0-15: Identification;
  16: QR [rotate = 270];
  17-20: Opcode;
  21: AA [rotate = 270];
  22: TC [rotate = 270];
  23: RD [rotate = 270];
  24: RA [rotate = 270];
  25-27: Z;
  28-31: RCODE;
}
```

### How to represent a large payload / address block compactly
Use `colheight` to draw one tall box instead of many identical rows.
```packetdiag
packetdiag {
  colwidth = 32;
  0-31: Header;
  32-159: Source Address (128 bits) [colheight = 4, color = "#e0f2f1"];
}
```

### How to change the bits-per-row for a non-32-bit protocol
```packetdiag
packetdiag {
  colwidth = 8;         // byte-per-row view
  0-7: Version;
  8-15: Type;
  16-23: Length;
  24-31: Flags;
}
```

## Do's and Don'ts

### ✅ Do
- Tile the header contiguously from bit 0 with **non-overlapping, inclusive** ranges.
- Match `colwidth` to the protocol convention (`32` for IETF headers, `16`/`8` for narrower formats).
- Use `rotate = 270` on single-bit flag labels so they fit the cell.
- Use `colheight` for big payload/address regions instead of repeating rows.
- Color fields by logical section (ports, sequence, flags) for readability.

### ❌ Don't
- Don't overlap ranges — `0-15` then `10-25` double-claims bits 10–15 and errors/renders wrong.
- Don't leave gaps unless intentional — a jump from `0-7` to `16-23` leaves bits 8–15 undrawn.
- Don't exceed a row boundary within one field unless you mean it to wrap; keep field widths ≤ `colwidth` unless using `colheight`.
- Don't run `blockdiag` on a packet file — use the `packetdiag` command.
- Don't forget quotes are optional for single-word labels but required only when the label contains a colon or comma; multi-word labels render fine unquoted (e.g. `Source Port`), but quote anything with punctuation.

## Styling, Theming & Customization
Theming is inline: `default_*` diagram attributes set the baseline; per-field `color`/`textcolor` and `class` bundles color by section. A conventional RFC-style scheme keeps the grid mostly white with a few tinted bands (flags in red, addresses in teal, ports in blue) so the structure — not the color — carries the meaning. `node_height` and `default_fontsize` tune density for print vs slides.

## Advanced Features
- **`colheight`**: one field box spanning several rows (payloads, 128-bit addresses).
- **`rotate`**: vertical labels (`270`) for narrow single-bit fields.
- **`colwidth`**: reflow the whole diagram to a different bits-per-row grid.
- **Bundled tools**: the same `pip install nwdiag` also gives `nwdiag` and `rackdiag`.
- **Sphinx**: `.. packetdiag::` directive (via sphinxcontrib-nwdiag) renders inline in docs.

## Common Pitfalls & Troubleshooting
- **Fields misaligned / overlapping boxes**: check for overlapping bit ranges; ranges must be disjoint and inclusive.
- **Unexpected blank cells**: a gap in bit coverage — add the missing range or extend a neighbor.
- **Flag labels overflow the cell**: add `rotate = 270`, or widen with a multi-bit range.
- **Wrong number of columns**: `colwidth` sets bits per row — set it to 32 for standard headers.
- **PDF fails**: install `"nwdiag[pdf]"`.
- **Non-ASCII labels are boxes**: pass `-f /path/Font.ttf`.

## Integration Notes
- **Sphinx**: `sphinxcontrib-nwdiag` provides the `.. packetdiag::` directive.
- **Kroki**: https://kroki.io renders packetdiag server-side — POST the source to `https://kroki.io/packetdiag/svg` with no local install.
- **MkDocs / Markdown**: embed via the `mkdocs-kroki-plugin` or a Kroki fenced block.
- **CI**: `.diag` sources diff cleanly; render to SVG in a build step or via Kroki on demand.

## Best For / Avoid For
`packet-formats`, `protocol-headers`, `rfc-diagrams`, `bit-field-layouts`, `wire-format-docs` — choose packetdiag for precise bit/byte header grids from text. Avoid for network topology (use nwdiag), rack layouts (rackdiag), timing/sequence (seqdiag), or general diagrams (blockdiag/graphviz/mermaid).

## See Also
- Family siblings: `nwdiag.md` (network topology), `rackdiag.md` (server racks), `blockdiag.md` (core blocks/flow), `seqdiag.md` (sequence), `actdiag.md` (activity)
- Alternatives: `mermaid.md` (Markdown diagrams), `graphviz.md` (DOT graph layout)
- Use cases: `../use-case/networks-graphs.md`, `../use-case/diagram-generation.md`
