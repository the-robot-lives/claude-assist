import assert from "node:assert/strict";
import { demoDocument } from "../holograph/fixture";
import { buildTrd3dScene, TRD_3D_NODE_CONCEPTS, TRD_3D_NODE_KINDS } from "./index";

const scene = buildTrd3dScene(demoDocument, { focusNodeId: "uml-scene" });
const rebuilt = buildTrd3dScene(demoDocument, { focusNodeId: "uml-scene" });

assert.deepEqual(TRD_3D_NODE_KINDS, [
  "system",
  "package",
  "service",
  "class",
  "interface",
  "function",
  "database",
  "agent",
]);
assert.equal(TRD_3D_NODE_CONCEPTS.class.unityConcept, "UmlClass");
assert.equal(TRD_3D_NODE_CONCEPTS.interface.shapeKind, "interface-card");

assert.equal(scene.documentId, demoDocument.id);
assert.equal(scene.nodes.length, demoDocument.nodes.length);
assert.equal(scene.edges.length, demoDocument.edges.length);
assert.deepEqual(scene.omittedEdgeIds, []);
assert.deepEqual(scene, rebuilt);

const root = scene.nodes.find((node) => node.id === "root");
assert.ok(root);
assert.equal(root.shapeKind, "compound-slab");
assert.equal(root.unityConcept, "SceneRoot");
assert.equal(root.zLayer, 0);
assert.equal(root.labelLodTier, "full");
assert.ok(root.slab.width > root.slab.height);

const umlScene = scene.nodes.find((node) => node.id === "uml-scene");
assert.ok(umlScene);
assert.equal(umlScene.zLayer, 2);
assert.equal(umlScene.position.z, 48);
assert.equal(umlScene.shapeKind, "class-box");
assert.ok(umlScene.slab.depth > 1.8);

const renderEdge = scene.edges.find((edge) => edge.id === "e-scene-node");
assert.ok(renderEdge);
assert.equal(renderEdge.routeKind, "raised-polyline");
assert.equal(renderEdge.waypoints.length, 5);
assert.ok(renderEdge.waypoints.every((point) => Number.isFinite(point.x) && Number.isFinite(point.y) && Number.isFinite(point.z)));
assert.ok(renderEdge.zLayer > renderEdge.source.zLayer);

assert.deepEqual(Object.keys(scene.cameraPresets).sort(), ["focus", "front", "isometric", "overview", "top"]);
assert.deepEqual(scene.cameraPresets.focus.target, umlScene.position);
assert.ok(scene.cameraPresets.overview.far > scene.cameraPresets.overview.near);

assert.ok(scene.bounds.span.x > 0);
assert.ok(scene.bounds.span.y > 0);
assert.ok(scene.bounds.span.z > 0);
assert.ok(scene.zLayers.length >= 3);

console.log("trd-3d scene tests passed");
