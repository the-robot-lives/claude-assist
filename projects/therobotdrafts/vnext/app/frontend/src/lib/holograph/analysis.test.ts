import assert from "node:assert/strict";
import { demoDocument } from "./fixture";
import {
  filterByKind,
  filterByRisk,
  filterByStatus,
  graphMetrics,
  riskBandFor,
  searchNodes,
  shortestPath,
  traceNeighbors,
} from "./analysis";

assert.deepEqual(
  searchNodes(demoDocument, "Uml3DScene").map((node) => node.id),
  ["uml-scene", "pkg-uml3d"],
);

assert.deepEqual(
  searchNodes(demoDocument, "camera", { kinds: "class" }).map((node) => node.id),
  ["camera-rig", "uml-scene"],
);

assert.deepEqual(
  filterByKind(demoDocument, ["database", "interface"]).map((node) => node.id),
  ["plantuml-exporter", "model-store"],
);

assert.deepEqual(
  filterByStatus(demoDocument, "hot").map((node) => node.id),
  ["pkg-uml3d", "uml-node"],
);

assert.deepEqual(
  filterByRisk(demoDocument, { min: 30 }).map((node) => node.id),
  ["root", "pkg-uml3d", "pkg-ai", "uml-node", "patch-review"],
);

assert.equal(riskBandFor(34), "low");
assert.equal(riskBandFor(35), "medium");
assert.equal(riskBandFor(60), "high");

const trace = traceNeighbors(demoDocument, "uml-scene");
assert.equal(trace.origin?.id, "uml-scene");
assert.deepEqual(trace.nodeIds, ["uml-scene", "uml-node", "uml-edge", "camera-rig", "diagram-model", "model-store"]);
assert.deepEqual(trace.edgeIds, [
  "e-scene-node",
  "e-scene-edge",
  "e-scene-camera",
  "e-model-scene",
  "e-scene-store",
]);
assert.equal(trace.depthByNodeId["uml-scene"], 0);
assert.equal(trace.depthByNodeId["uml-node"], 1);

const directedPath = shortestPath(demoDocument, "diagram-model", "uml-node", { direction: "outgoing" });
assert.deepEqual(directedPath?.nodeIds, ["diagram-model", "uml-scene", "uml-node"]);
assert.deepEqual(directedPath?.edgeIds, ["e-model-scene", "e-scene-node"]);
assert.equal(directedPath?.distance, 2);

const crossLanePath = shortestPath(demoDocument, "patch-review", "uml-scene");
assert.deepEqual(crossLanePath?.nodeIds, ["patch-review", "diagram-model", "uml-scene"]);
assert.deepEqual(crossLanePath?.edgeIds, ["e-ai-model", "e-model-scene"]);

assert.equal(shortestPath(demoDocument, "missing", "root"), null);

const metrics = graphMetrics(demoDocument);
assert.equal(metrics.nodeCount, 13);
assert.equal(metrics.edgeCount, 14);
assert.equal(metrics.laneCount, 4);
assert.equal(metrics.crossLaneEdgeCount, 5);
assert.deepEqual(metrics.rootNodeIds, ["root"]);
assert.deepEqual(metrics.orphanNodeIds, []);
assert.deepEqual(metrics.danglingEdgeIds, []);
assert.equal(metrics.kindCounts.class, 6);
assert.equal(metrics.statusCounts.draft, 3);
assert.equal(metrics.hotNodeCount, 2);
assert.equal(metrics.lanes.find((lane) => lane.id === "pkg-uml3d")?.nodeCount, 6);

console.log("holograph analysis tests passed");
