# PlantUML → .trd-yaml converter

Standalone .NET tool that converts `.puml` source into TheRobotDrafts' native
`.trd-yaml` model files — **no Unity required**. Uses the project's own pipeline:
`PlantUmlReader.Parse` → `IxModel` → `TrdYamlWriter.Write`.

## Build

```bash
dotnet build tools/trd-converter/trd-converter.csproj -c Release
```

Pure C# / BCL only. Globs the interchange layer + YamlLite in place (single source
of truth). Targets `net10.0`. Zero `UnityEngine` references.

## Usage

```bash
# convert one file → sibling .trd-yaml
dotnet run --project tools/trd-converter/trd-converter.csproj -c Release -- path/to/x.puml

# convert every .puml under a directory (recursive)
dotnet run --project tools/trd-converter/trd-converter.csproj -c Release -- docs/diagrams

# validate: round-trip check, no files written (exit 2 if any drift)
dotnet run --project tools/trd-converter/trd-converter.csproj -c Release -- --check docs/diagrams

# coverage probe: element/edge-type histogram per family, flags Unknown/empty (no files written)
dotnet run --project tools/trd-converter/trd-converter.csproj -c Release -- --stats docs/diagrams

# show the first differing lines for a drifting file
dotnet run --project tools/trd-converter/trd-converter.csproj -c Release -- --diff path/to/x.puml
```

Flags: `--no-recurse` (top-level only), `--check` (round-trip validation),
`--stats` (coverage/fidelity audit), `--diff` (drift diagnostic). Exit 0 ok, 1 usage, 2 failures.

## Status (verified by running the tool)

- **168 / 168 files convert, 0 skipped, 0 parse errors, 0 empty.** (2300 elements, 1575 edges)
- **168 / 168 round-trip stable, 0 drift.** `Write(Parse(Write(m))) == Write(m)` on every file.
- The interchange layer is Unity-independent (compiles + runs standalone, 0/0 build).
- First-class element types for SysML (`Block`, `ValueType`, `Constraint`, `Requirement`,
  `TestCase`), BPMN (`BpmnEvent/Activity/Gateway/DataObject/Pool/Lane`), and DMN
  (`DmnDecision`, `InputData`, `KnowledgeSource`, `BusinessKnowledge`) are promoted from
  stereotypes. Traceability edges (`Satisfy`, `Verify`, `Derive`, `Refine`, `Trace`, `Copy`)
  and BPMN flow edges (`SequenceFlow`, `MessageFlow`) are promoted from edge stereotypes /
  BPMn-element context.
- Timing diagrams (`robust`/`concise`) parse to lifelines + transition edges. Salt wireframes
  parse to `Screen`/`Panel`/widget elements for the supported UI vocabulary; unsupported Salt rows
  are preserved as raw `UiWidget` nodes so batch conversion never blocks.

## Extending the IR

Adding a first-class type is now a two-line change: add the enum value to
`IxElementType`/`IxEdgeType`, then map a stereotype to it in `PlantUmlReader`
(element stereotypes near the `«table»` rule; edge stereotypes in the arrow
classifier). The writer + reader serialize arbitrary enum values generically
(`.ToString()` / `Enum.TryParse`), so round-trip is automatic — verify with `--check`.

## Files

- `Assets/Scripts/Authoring/Interchange/InterchangeModel.cs` — the IR (enums + types)
- `Assets/Scripts/Authoring/Interchange/TrdYamlWriter.cs` — `IxModel` → `.trd-yaml`
- `Assets/Scripts/Authoring/Interchange/TrdYamlReader.cs` — `.trd-yaml` → `IxModel`
- `tools/trd-converter/` — standalone project (Program.cs, Stats.cs, DiffCheck.cs, .csproj)
