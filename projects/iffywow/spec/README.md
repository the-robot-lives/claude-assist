# spec/ — versioned registries (source of truth)

These YAML files are the **single source of truth** for the iffywow SDK's
enum inventories, socket geometry, and glyph shape registries.
`enums.ex` / `enums.py` / `element-names.json` (and `web/src/registry.js`,
currently a hand-written stand-in) are **generated** from these files —
never hand-edit generated outputs.

## Stability rule

> **An integer ID is never reassigned; removed elements become reserved IDs.**

New elements append the next free ID; renames keep their ID (old name becomes
an alias); removed IDs go to the file's `reserved_ids` list and are never
reused. File position is cosmetic — the `id` field is canonical.

## Sources

- Official grammar & writing system: [ithkuil.net](https://ithkuil.net/) —
  Ch. 12 "The Writing System" (Dec 2022 spec) reconciled with the
  [2023-02-15 Grammar Design v1.3.2 amendments](https://www.ithkuil.net/New_Ithkuil_design_doc_v_1_3.pdf)
- Pinned reference toolkit (MIT, not a floating authority):
  [github.com/zsakowitz/ithkuil](https://github.com/zsakowitz/ithkuil)

Shape `path` fields are currently `null` placeholders (the renderer's
deterministic generated paths stand in); each entry's `source` names the
exact toolkit key so digitizing official paths is mechanical. Swapping a
placeholder path for the official one is a rendering change, not a semantic
change.

## Verification status

| File | Count | Status |
|---|---|---|
| `sockets.yaml` | 8 | verified against `web/src/registry.js` |
| `orientations.yaml` | 4 | verified against `web/src/registry.js` |
| `geometry/attachment_points.yaml` | 13 constants | verified against `web/src/scene.js` |
| `character_classes.yaml` | 9 | verified (grammar Ch. 12/13); `numeral` inventory + `word_break` officialness: TODO |
| `bases.yaml` | 33 (28 std cores + 5 special) | verified (Ch. 12 §12.2 + toolkit `CORES`) |
| `modifiers.yaml` | 41 | verified against toolkit `EXTENSIONS`; official §12.2.1 figure order unconfirmed (images) |
| `diacritics.yaml` | 16 (+9 vowel aliases) | verified against toolkit `CORE_DIACRITICS` |
| `morphology/cases.yaml` | 68 | verified (Ch. 4 order via toolkit `ALL_CASES`) |
| `morphology/aspects.yaml` | 36 | verified |
| `morphology/biases.yaml` | 61 | verified against Ch. 8 §8.5 table (EXP is a legacy alias of MNF) |
| `morphology/valences.yaml` | 9 | verified |
| `morphology/phases.yaml` | 9 | verified |
| `morphology/effects.yaml` | 9 | verified |
| `morphology/levels.yaml` | 9 | verified |
| `morphology/moods.yaml` | 6 | verified |
| `morphology/case_scopes.yaml` | 6 | verified |
| `morphology/illocutions.yaml` | 9 | verified |
| `morphology/validations.yaml` | 9 | verified |
| `morphology/ca_categories.yaml` | 20+6+4+4+2 | verified |
| `morphology/formative_categories.yaml` | 4+2+2+4+4 | verified (STA rendered "Stative" per grammar; toolkit says "Static") |
| `morphology/affix_meta.yaml` | 3+10+6 | verified (scopes per §8.1.1; types/degrees per Ch. 7 + toolkit) |
| `morphology/registers.yaml` | 7 | verified (§8.3) |

"Verified" = checked on 2026-07-17 against ithkuil.net and/or the pinned
toolkit as noted in each file's header. Files needing follow-up carry inline
`# TODO verify against <source>` comments.
