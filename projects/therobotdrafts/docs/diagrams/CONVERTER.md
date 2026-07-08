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

# show the first differing lines for a drifting file
dotnet run --project tools/trd-converter/trd-converter.csproj -c Release -- --diff path/to/x.puml
```

Flags: `--no-recurse` (top-level only), `--check` (round-trip validation),
`--diff` (diagnostic).

## What it proves

- The interchange layer is Unity-independent (compiles + runs standalone).
- `.puml` examples are real, parseable, and produce complete native models.
- Writer/Reader are exact duals: `Write(Parse(Write(m))) == Write(m)` on all Tier 1
  examples (0 drift).

## Files

- `Assets/Scripts/Authoring/Interchange/TrdYamlWriter.cs` — `IxModel` → `.trd-yaml`
- `Assets/Scripts/Authoring/Interchange/TrdYamlReader.cs` — `.trd-yaml` → `IxModel`
- `tools/trd-converter/` — standalone project (Program.cs, DiffCheck.cs, .csproj)
