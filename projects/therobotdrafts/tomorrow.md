# Tomorrow Prompt

Resume work on The Robot Draft vnext web app in `projects/therobotdrafts/vnext/app/frontend`.

Current state:
- Local production server was last run at `http://127.0.0.1:3021`.
- Recent commit: `b9f4dfee691` (`Polish TRD vnext workspace chrome`).
- TRD vnext is now framed as a 3D UML tool, not a 2D graph.
- The root editor defaults to an empty 3D UML workspace with a real app menu, right-click context menu, autosave, TRD JSON open/save, PlantUML import/export, Mermaid/DOT export, and source-file import to UML stubs.
- The cookie banner is suppressed on `/` so it does not block the editor.

Next work:
1. Implement true authoring parity beyond menu stubs:
   - Connect mode with source/target picking in the 3D scene.
   - Relationship type selector for association, dependency, generalization, realization, composition, aggregation, deployment, and trace.
   - Delete, copy, paste, undo, and redo should preserve selection and not reset to the first node.
2. Improve file roundtrip:
   - Add a native `.trd-yaml` reader/writer compatible with the Unity/C# tooling.
   - Expand PlantUML parsing to recover class members, visibility, packages, inheritance, realization, composition, and multiplicity.
   - Make exported code skeletons language-selectable instead of C# only.
3. Add inspector editing:
   - Editable element name, stereotype, package, attributes, operations, metrics, status, and notes.
   - Persist edits through autosave and TRD JSON export.
4. Make the 3D surface closer to Unity parity:
   - Visible selected-node connection handles.
   - Edge hover/select feedback and larger camera-scaled hit targets.
   - Camera form with yaw, pitch, roll, pivot, distance, and reset/apply controls.
   - Keep fog extremely low; use lighting/grid/depth cues instead of hiding distant nodes.
5. Verification before finishing:
   - `npm exec tsc -- --noEmit --pretty false`
   - `npm exec tsx src/lib/holograph/document-io.test.ts`
   - `npm exec tsx src/lib/trd-3d/scene.test.ts`
   - `npm run test:e2e:types`
   - `npm run build`
   - Restart the standalone server and verify with Playwright screenshots plus menu/context interaction checks.

Important constraints:
- Do not regress into a 2D/SVG graph experience. Flat diagrams are projections/exports only.
- Keep the Unity-style app chrome: menu bar, tab strip, left palette/verb rail, central 3D scene, right inspector.
- Do not touch unrelated dirty files in the monorepo.
