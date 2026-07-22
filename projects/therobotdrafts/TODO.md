# TRD vnext — Task List

Source: [tomorrow.md](tomorrow.md) · App: `vnext/app/frontend` · Baseline: `b9f4dfee691` · Last prod run: `http://127.0.0.1:3021`

## 1. Authoring parity (beyond menu stubs)

- [x] Connect mode with source/target picking in the 3D scene
- [x] Relationship type selector: association, dependency, generalization, realization, composition, aggregation, deployment, trace
- [x] Delete/copy/paste/undo/redo preserve selection (no reset to first node)
- [x] Drag-to-place elements from palette/toolbar onto the 3D scene (added 2026-07-23; click still adds at auto-layout)

## 2. File roundtrip

- [x] Native `.trd-yaml` reader/writer compatible with Unity/C# tooling
- [x] Expand PlantUML parsing: class members, visibility, packages, inheritance, realization, composition, multiplicity
- [x] Language-selectable exported code skeletons (C#, TypeScript, Python, Java, Go)

## 3. Inspector editing

- [x] Editable: name, stereotype, package, attributes, operations, metrics, status, notes
- [x] Persist inspector edits through autosave and TRD JSON export

## 4. 3D surface Unity parity

- [x] Visible selected-node connection handles
- [x] Edge hover/select feedback + camera-scaled hit targets
- [x] Camera form: yaw, pitch, roll, pivot, distance, reset/apply
- [x] Fog stays extremely low; lighting/grid/depth cues instead of hiding distant nodes

## 5. Verification gate (before finishing — blocked by all of the above)

- [x] `npm exec tsc -- --noEmit --pretty false`
- [x] `npm exec tsx src/lib/holograph/document-io.test.ts` (+ new `trd-yaml.test.ts`)
- [x] `npm exec tsx src/lib/trd-3d/scene.test.ts`
- [x] `npm run test:e2e:types`
- [x] `npm run build`
- [x] Restart standalone server; Playwright screenshots + menu/context interaction checks (19/19)

## Standing constraints (guardrails, not tasks)

- No 2D/SVG graph regression — flat diagrams are projections/exports only
- Keep Unity-style chrome: menu bar, tab strip, left palette/verb rail, central 3D scene, right inspector
- Do not touch unrelated dirty files in the monorepo
- Run Git from monorepo root with `projects/therobotdrafts` pathspec (mount boundary)
