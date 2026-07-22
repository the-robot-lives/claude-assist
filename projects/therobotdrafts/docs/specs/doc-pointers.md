# Documentation Pointers

<!-- ⟦DPTR⟧ Documentation pointer convention :: Defines hard pointer markers, pointer database generation, and markdown deeplink expansion. -->

Hard pointers give comments and docs a stable, compact target that survives renames and section
rewrites better than headings. They are for cross-document references that must keep pointing at a
specific implementation or design note.

## Marker

Use the Unicode bracket pair `⟦` and `⟧` around a four-character Unicode id:

```text
⟦ABCD⟧
```

The id is exactly four Unicode code points. Treat it as a compact base-32k-style token: use printable,
non-whitespace characters, and avoid `⟦`, `⟧`, `/`, `?`, `#`, `:`, and `%` so links stay readable.
The UUIDv5 generator emits four characters from the Egyptian Hieroglyph block, `U+13000..U+1342F`.
Generated hieroglyphic tokens are preferred for code-owned pointers. Hand-authored mnemonic ids such
as `DPTR` are valid for stable documentation/spec anchors when they are unique.

## Declaration

Declare a hard pointer in the source file or documentation line that owns the idea:

```csharp
// ⟦ABCD⟧ Pointer routing :: Centralizes non-UI pointer input for 3D diagram gestures.
```

```markdown
<!-- ⟦UX01⟧ First-run coachmark :: Entry point for the guided authoring tutorial. -->
```

Declaration grammar:

```text
⟦CODE⟧ Name :: Description
```

- `CODE` is the four-character id.
- `Name` is the short display name stored in the pointer database.
- `Description` explains the target's purpose.
- Each `CODE` must have exactly one declaration in the repository.
- Plain `⟦CODE⟧` mentions are references, not declarations.
- Declarations should be on a bare marker line or in a source/doc comment. Quoted examples inside
  prompts or fixtures are intentionally ignored by the scanner.

## Database

The generated pointer database lives at:

```text
docs/doc-pointer-db.json
```

It maps each code to the owning file, line, name, and description:

```json
{
  "ABCD": {
    "path": "Assets/Scripts/Uml/UmlCanvas.cs",
    "line": 684,
    "name": "Pointer routing",
    "description": "Centralizes non-UI pointer input for 3D diagram gestures."
  }
}
```

Regenerate it with:

```bash
make doc-pointers
```

Check without writing:

```bash
make doc-pointers-check
```

## Markdown Links

Markdown may refer to a pointer through a temporary deep link:

```markdown
[pointer routing](deeplink:ABCD)
[pointer routing](deeplink:⟦ABCD⟧)
```

The resolver expands those links to a direct file-and-line target:

```markdown
[pointer routing](Assets/Scripts/Uml/UmlCanvas.cs:684?code=⟦ABCD⟧)
```

Run the resolver before committing, or install the local pre-commit hook:

```bash
make install-doc-pointer-hook
```

The hook runs `make doc-pointers-check`. If a pointer moved or a new `deeplink:` reference was added,
run `make doc-pointers` and stage the updated Markdown/database files.

## Rules

- Use hard pointers only for durable design or implementation anchors, not every paragraph.
- Put the declaration at the line that best owns the concept.
- Keep names short enough to scan in generated reports.
- Keep descriptions stable and factual.
- Do not reuse deleted ids; leave a tombstone declaration if old links still matter.

## Retiring Pointers

If a target is removed but old references may still exist, keep one tombstone declaration in a
nearby changelog, migration note, or deleted-feature section:

```markdown
<!-- ⟦ABCD⟧ Retired pointer :: Tombstone for removed pointer routing implementation. -->
```

The tombstone keeps `deeplink:` expansion deterministic and prevents accidental id reuse.
