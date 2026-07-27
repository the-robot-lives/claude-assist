"use client";

import { type MutableRefObject, useEffect, useRef } from "react";
import * as THREE from "three";
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls.js";
import { buildTrd3dScene, type Trd3dNodeShapeKind } from "@/lib/trd-3d";
import { buildNodeBody } from "@/lib/trd-3d/node-geometry";
import { nodeVisual, type NodeSilhouette } from "@/lib/holograph/node-visuals";
import { paintNodeFace } from "@/lib/holograph/node-face";
import type { GraphDocument, GraphEdge, GraphNode } from "@/lib/holograph/types";

export interface TrdCameraPose {
  yaw: number;
  pitch: number;
  roll: number;
  pivot: { x: number; y: number; z: number };
  distance: number;
}

export interface TrdSceneHandle {
  getCameraPose(): TrdCameraPose;
  setCameraPose(pose: TrdCameraPose): void;
  resetCamera(): void;
  /** Project a screen point onto the scene's placement plane (z = orbit target z, camera-facing
   * fallback). Returns null when the point is outside the canvas. */
  dropPointAt(clientX: number, clientY: number): { x: number; y: number; z: number } | null;
}

interface TrdThreeSceneProps {
  document: GraphDocument;
  selectedId?: string | null;
  focusId?: string | null;
  tracedEdgeIds?: Set<string>;
  onSelect?: (nodeId: string) => void;
  onStatus?: (message: string) => void;
  handleRef?: MutableRefObject<TrdSceneHandle | null>;
}

interface RenderNode {
  node: GraphNode;
  group: THREE.Group;
  body: THREE.Object3D;
  label: THREE.Mesh;
  farLabel: THREE.Sprite;
  handles: THREE.Group;
  baseColor: THREE.Color;
}

interface EdgeRender {
  edge: GraphEdge;
  line: THREE.Line;
  cone: THREE.Mesh | null;
  baseColor: THREE.Color;
  baseOpacity: number;
  traced: boolean;
}

const defaultDimensions = { width: 2.8, height: 1.45, depth: 0.22 };
const tempBox = new THREE.Box3();
const tempSphere = new THREE.Sphere();

function shapeHint(shapeKind: Trd3dNodeShapeKind): NonNullable<GraphNode["trd3d"]>["shape"] {
  if (shapeKind === "database-cylinder") return "cylinder";
  if (shapeKind === "method-pill") return "sphere";
  if (shapeKind === "namespace-slab") return "package";
  if (shapeKind === "component-capsule") return "component";
  if (shapeKind === "interface-card") return "interface";
  if (shapeKind === "actor-hex") return "actor";
  return "slab";
}

function nodePosition(node: GraphNode) {
  const p = node.trd3d?.position;
  return new THREE.Vector3(p?.x ?? 0, p?.y ?? 0, p?.z ?? 0);
}

function nodeDimensions(node: GraphNode) {
  return node.trd3d?.dimensions ?? defaultDimensions;
}

function nodeColor(node: GraphNode) {
  if (node.trd3d?.color) return new THREE.Color(node.trd3d.color);
  return new THREE.Color(nodeVisual(node.kind).body);
}

/** Explicit `trd3d.shape` hints override the kind's default silhouette. The hint union is
 * coarser than the silhouette vocabulary, so unmapped values fall back to the kind default
 * rather than collapsing to a box -- which is what the old `buildBody` did with `actor`
 * and `interface`. */
const SHAPE_HINT_SILHOUETTE: Partial<Record<NonNullable<GraphNode["trd3d"]>["shape"] & string, NodeSilhouette>> = {
  package: "namespace-slab",
  component: "component-capsule",
  cylinder: "database-cylinder",
  sphere: "method-pill",
  actor: "actor-hex",
  interface: "interface-card",
};

function nodeSilhouette(node: GraphNode): NodeSilhouette {
  // `"slab"` is deliberately absent above: `shapeHint()` funnels both `class-box` and
  // `compound-slab` into it, so honouring it would strip `system` of its compound form.
  // Every other hint is unambiguous and wins over the kind default.
  const hint = node.trd3d?.shape;
  return (hint && SHAPE_HINT_SILHOUETTE[hint]) || nodeVisual(node.kind).silhouette;
}

function labelTexture(node: GraphNode, compact = false) {
  const texture = new THREE.CanvasTexture(paintNodeFace(node, compact));
  texture.colorSpace = THREE.SRGBColorSpace;
  texture.needsUpdate = true;
  return texture;
}

function makeRenderNode(node: GraphNode) {
  const dims = nodeDimensions(node);
  const baseColor = nodeColor(node);
  const isRootShell = node.kind === "system";
  const material = new THREE.MeshStandardMaterial({
    color: baseColor,
    roughness: isRootShell ? 0.56 : 0.68,
    metalness: 0.02,
    emissive: baseColor.clone().multiplyScalar(isRootShell ? 0.2 : 0.1),
    emissiveIntensity: isRootShell ? 0.38 : 0.18,
    transparent: isRootShell,
    opacity: isRootShell ? 0.46 : 1,
  });

  const group = new THREE.Group();
  group.name = `TRD:${node.id}`;
  group.position.copy(nodePosition(node));
  group.userData.nodeId = node.id;
  const r = node.trd3d?.rotation;
  if (r) group.rotation.set(THREE.MathUtils.degToRad(r.x), THREE.MathUtils.degToRad(r.y), THREE.MathUtils.degToRad(r.z));

  const { mesh: body, labelZ, labelScale } = buildNodeBody(nodeSilhouette(node), dims, material);
  body.userData.nodeId = node.id;
  for (const child of body.children) child.userData.nodeId = node.id;
  group.add(body);

  const outline = new THREE.LineSegments(
    new THREE.EdgesGeometry(body.geometry),
    new THREE.LineBasicMaterial({ color: baseColor.clone().lerp(new THREE.Color("#080b0d"), 0.45), linewidth: 1 }),
  );
  body.add(outline);

  const faceTexture = labelTexture(node);
  const label = new THREE.Mesh(
    new THREE.PlaneGeometry(dims.width * labelScale, dims.height * labelScale * 0.96),
    new THREE.MeshBasicMaterial({ map: faceTexture, transparent: true, depthTest: true }),
  );
  label.position.z = labelZ + 0.012;
  label.userData.nodeId = node.id;
  group.add(label);

  const farTexture = labelTexture(node, true);
  const farLabel = new THREE.Sprite(new THREE.SpriteMaterial({ map: farTexture, transparent: true, depthTest: false }));
  farLabel.scale.set(Math.max(1.8, dims.width * 0.92), Math.max(0.45, dims.height * 0.28), 1);
  farLabel.position.set(0, dims.height * 0.66, 0);
  farLabel.visible = false;
  farLabel.userData.nodeId = node.id;
  group.add(farLabel);

  // Connection handles on the four side midpoints; shown only while selected.
  const handles = new THREE.Group();
  handles.visible = false;
  const handleMaterial = new THREE.MeshBasicMaterial({ color: "#63c7ff", depthTest: false, transparent: true, opacity: 0.95 });
  const handleOffsets = [
    new THREE.Vector3(dims.width * 0.5 + 0.14, 0, 0),
    new THREE.Vector3(-(dims.width * 0.5 + 0.14), 0, 0),
    new THREE.Vector3(0, dims.height * 0.5 + 0.14, 0),
    new THREE.Vector3(0, -(dims.height * 0.5 + 0.14), 0),
  ];
  for (const offset of handleOffsets) {
    const handle = new THREE.Mesh(new THREE.OctahedronGeometry(0.11), handleMaterial);
    handle.position.copy(offset);
    handle.userData.nodeId = node.id;
    handle.renderOrder = 3;
    handles.add(handle);
  }
  group.add(handles);

  return { node, group, body, label, farLabel, handles, baseColor };
}

function edgeColor(edge: GraphEdge, traced: boolean) {
  if (traced) return new THREE.Color("#ffd36b");
  if (edge.uml?.relationship === "composition") return new THREE.Color("#f2f0e8");
  if (edge.uml?.relationship === "realization") return new THREE.Color("#8ed7d1");
  if (edge.kind === "patches") return new THREE.Color("#d5a0ff");
  return new THREE.Color("#9ab0ba");
}

function addEdge(scene: THREE.Scene, edge: GraphEdge, nodes: Map<string, RenderNode>, traced: boolean): EdgeRender | null {
  const source = nodes.get(edge.sourceId);
  const target = nodes.get(edge.targetId);
  if (!source || !target) return null;

  const points = edge.trd3d?.waypoints?.map((p) => new THREE.Vector3(p.x, p.y, p.z)) ?? [
    source.group.position,
    source.group.position.clone().lerp(target.group.position, 0.5).add(new THREE.Vector3(0, 0.7, 0.5)),
    target.group.position,
  ];

  const color = edgeColor(edge, traced);
  const baseOpacity = traced ? 1 : 0.72;
  const dashed = edge.uml?.dashed || edge.kind === "depends_on";
  const material = dashed
    ? new THREE.LineDashedMaterial({ color, dashSize: 0.24, gapSize: 0.14, transparent: true, opacity: baseOpacity })
    : new THREE.LineBasicMaterial({ color, transparent: true, opacity: traced ? 1 : 0.68 });

  const line = new THREE.Line(new THREE.BufferGeometry().setFromPoints(points), material);
  line.name = `Edge:${edge.id}`;
  line.userData.edgeId = edge.id;
  if (dashed) line.computeLineDistances();
  scene.add(line);

  let cone: THREE.Mesh | null = null;
  if (edge.uml?.arrow !== "none") {
    const end = points[points.length - 1];
    const prev = points[points.length - 2];
    const dir = end.clone().sub(prev).normalize();
    cone = new THREE.Mesh(
      new THREE.ConeGeometry(edge.uml?.arrow === "diamond" ? 0.18 : 0.13, edge.uml?.arrow === "diamond" ? 0.34 : 0.28, 4),
      new THREE.MeshStandardMaterial({ color, roughness: 0.55 }),
    );
    cone.position.copy(end).sub(dir.clone().multiplyScalar(0.18));
    cone.quaternion.setFromUnitVectors(new THREE.Vector3(0, 1, 0), dir);
    cone.userData.edgeId = edge.id;
    scene.add(cone);
  }

  return { edge, line, cone, baseColor: color.clone(), baseOpacity, traced };
}

export function TrdThreeScene({ document, selectedId, focusId, tracedEdgeIds, onSelect, onStatus, handleRef }: TrdThreeSceneProps) {
  const hostRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    const host = hostRef.current;
    if (!host) return;

    const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false });
    renderer.outputColorSpace = THREE.SRGBColorSpace;
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.setSize(host.clientWidth, host.clientHeight);
    host.replaceChildren(renderer.domElement);

    const trdScene = buildTrd3dScene(document, { focusNodeId: focusId ?? selectedId });
    const sceneNodeById = new Map(trdScene.nodes.map((node) => [node.id, node]));
    const sceneEdgeById = new Map(trdScene.edges.map((edge) => [edge.id, edge]));
    // Hand-placed nodes (trd3d.authored) keep their document position; everything else uses
    // the synthesized layout. Edges touching a hand-placed node drop their synthesized
    // waypoints so they anchor to the live node positions instead.
    const authoredIds = new Set(
      document.nodes.filter((node) => node.trd3d?.authored && node.trd3d.position).map((node) => node.id),
    );
    const renderDocument: GraphDocument = {
      ...document,
      nodes: document.nodes.map((node) => {
        const sceneNode = sceneNodeById.get(node.id);
        if (!sceneNode) return node;
        return {
          ...node,
          trd3d: {
            ...node.trd3d,
            position: authoredIds.has(node.id) && node.trd3d ? node.trd3d.position : sceneNode.position,
            dimensions: sceneNode.slab,
            layer: sceneNode.zLayer,
            shape: shapeHint(sceneNode.shapeKind),
          },
        };
      }),
      edges: document.edges.map((edge) => {
        const sceneEdge = sceneEdgeById.get(edge.id);
        if (!sceneEdge) return edge;
        const touchesAuthored = authoredIds.has(edge.sourceId) || authoredIds.has(edge.targetId);
        return {
          ...edge,
          trd3d: {
            ...edge.trd3d,
            waypoints: touchesAuthored ? undefined : sceneEdge.waypoints,
            layer: sceneEdge.zLayer,
          },
        };
      }),
    };

    const scene = new THREE.Scene();
    scene.background = new THREE.Color("#162022");
    // Fog stays extremely low: depth is communicated by lighting, grid, and layer tinting,
    // never by hiding distant nodes.
    scene.fog = new THREE.FogExp2("#162022", 0.0005);

    const camera = new THREE.PerspectiveCamera(50, Math.max(1, host.clientWidth) / Math.max(1, host.clientHeight), 0.05, 1200);
    const preset = trdScene.cameraPresets.focus ?? trdScene.cameraPresets.overview;
    const target = new THREE.Vector3(preset.target.x, preset.target.y, preset.target.z);
    camera.position.set(preset.position.x, preset.position.y, preset.position.z);
    camera.fov = preset.fov;
    camera.near = preset.near;
    camera.far = preset.far;
    camera.updateProjectionMatrix();
    camera.lookAt(target);

    const controls = new OrbitControls(camera, renderer.domElement);
    controls.target.copy(target);
    controls.enableDamping = true;
    controls.dampingFactor = 0.08;
    controls.screenSpacePanning = true;
    controls.minDistance = 1.2;
    controls.maxDistance = 420;

    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1.35;

    scene.add(new THREE.AmbientLight("#c7d8d4", 0.95));
    scene.add(new THREE.HemisphereLight("#fff4df", "#53636e", 1.55));
    const key = new THREE.DirectionalLight("#fff6e8", 2.45);
    key.position.set(5, 10, 9);
    scene.add(key);
    const fill = new THREE.DirectionalLight("#89d4cb", 1.1);
    fill.position.set(-7, 3, 8);
    scene.add(fill);
    const rim = new THREE.DirectionalLight("#95bdff", 1.05);
    rim.position.set(-8, 4, -5);
    scene.add(rim);

    const grid = new THREE.GridHelper(18, 18, "#38525c", "#24343a");
    grid.position.y = -7.9;
    scene.add(grid);
    const axes = new THREE.AxesHelper(1.6);
    axes.position.set(-8.4, -7.7, 4);
    scene.add(axes);

    const renderNodes = new Map<string, RenderNode>();
    const pickTargets: THREE.Object3D[] = [];
    for (const node of renderDocument.nodes) {
      const renderNode = makeRenderNode(node);
      const layer = node.trd3d?.layer ?? 0;
      const material = (renderNode.body as THREE.Mesh).material as THREE.MeshStandardMaterial;
      const depthTint = Math.min(0.58, Math.max(0, Math.abs(layer) * 0.18));
      material.color.copy(renderNode.baseColor.clone().lerp(new THREE.Color("#70777c"), depthTint));
      renderNodes.set(node.id, renderNode);
      // Body plus both labels are pickable, so distant nodes offer large camera-scaled
      // hit targets via their sprite labels.
      pickTargets.push(renderNode.body, renderNode.label, renderNode.farLabel);
      scene.add(renderNode.group);
    }

    const edgeRenders = new Map<string, EdgeRender>();
    const edgePickables: THREE.Line[] = [];
    for (const edge of renderDocument.edges) {
      const created = addEdge(scene, edge, renderNodes, Boolean(tracedEdgeIds?.has(edge.id)));
      if (created) {
        edgeRenders.set(edge.id, created);
        edgePickables.push(created.line);
      }
    }

    const raycaster = new THREE.Raycaster();
    const pointer = new THREE.Vector2();
    let hoverId: string | null = null;
    let hoverEdgeId: string | null = null;
    let selectedEdgeId: string | null = null;

    function paintEdges() {
      for (const item of edgeRenders.values()) {
        const lineMaterial = item.line.material as THREE.LineBasicMaterial | THREE.LineDashedMaterial;
        const coneMaterial = item.cone?.material as THREE.MeshStandardMaterial | undefined;
        const isSelected = item.edge.id === selectedEdgeId;
        const isHovered = item.edge.id === hoverEdgeId;
        const color = isSelected
          ? new THREE.Color("#ffd36b")
          : isHovered
            ? item.baseColor.clone().lerp(new THREE.Color("#ffffff"), 0.55)
            : item.baseColor;
        lineMaterial.color.copy(color);
        lineMaterial.opacity = isSelected || isHovered ? 1 : item.baseOpacity;
        if (coneMaterial) coneMaterial.color.copy(color);
      }
    }

    function frame(nodeId?: string | null, announce = false) {
      tempBox.makeEmpty();
      if (nodeId) {
        const node = renderNodes.get(nodeId);
        if (node) tempBox.setFromObject(node.group);
      } else {
        for (const node of renderNodes.values()) tempBox.expandByObject(node.group);
      }
      if (tempBox.isEmpty()) return;
      tempBox.getBoundingSphere(tempSphere);
      controls.target.copy(tempSphere.center);
      const radius = Math.max(1, tempSphere.radius);
      const dir = camera.position.clone().sub(controls.target).normalize();
      camera.position.copy(tempSphere.center.clone().add(dir.multiplyScalar(radius * 2.4)));
      camera.near = Math.max(0.03, radius / 80);
      camera.far = Math.max(1000, radius * 80);
      camera.updateProjectionMatrix();
      controls.update();
      // Only explicit framing (F / Home) announces; silent on scene rebuilds so commit
      // status messages ("Renamed ...", "Connected ...") are not stomped.
      if (announce) onStatus?.(nodeId ? `Framed ${renderNodes.get(nodeId)?.node.label}` : "Framed whole 3D UML model");
    }

    function paintSelection() {
      for (const item of renderNodes.values()) {
        const material = (item.body as THREE.Mesh).material as THREE.MeshStandardMaterial;
        const selected = item.node.id === selectedId || item.node.id === focusId;
        const hovered = item.node.id === hoverId;
        const baseGlow = item.node.kind === "system" ? 0.38 : 0.18;
        material.emissive.copy(
          selected
            ? new THREE.Color("#2e7890")
            : hovered
              ? new THREE.Color("#586a39")
              : item.baseColor.clone().multiplyScalar(item.node.kind === "system" ? 0.2 : 0.1),
        );
        material.emissiveIntensity = selected ? 0.85 : hovered ? 0.42 : baseGlow;
        item.group.scale.setScalar(selected ? 1.055 : hovered ? 1.025 : 1);
        item.handles.visible = item.node.id === selectedId;
      }
    }

    function updatePointer(event: PointerEvent) {
      const rect = renderer.domElement.getBoundingClientRect();
      pointer.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
      pointer.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;
      raycaster.setFromCamera(pointer, camera);
      const hit = raycaster.intersectObjects(pickTargets, false)[0];
      hoverId = hit?.object.userData.nodeId ?? null;
      if (hoverId) {
        hoverEdgeId = null;
      } else {
        // Edge hit tolerance grows with camera distance so thin lines stay clickable from afar.
        const cameraDistance = camera.position.distanceTo(controls.target);
        raycaster.params.Line = { threshold: THREE.MathUtils.clamp(cameraDistance * 0.014, 0.06, 1.4) };
        const edgeHit = raycaster.intersectObjects(edgePickables, false)[0];
        hoverEdgeId = edgeHit?.object.userData.edgeId ?? null;
      }
      renderer.domElement.style.cursor = hoverId || hoverEdgeId ? "pointer" : "grab";
      paintSelection();
      paintEdges();
    }

    function click() {
      if (hoverId) {
        if (selectedEdgeId) {
          selectedEdgeId = null;
          paintEdges();
        }
        onSelect?.(hoverId);
        return;
      }
      if (hoverEdgeId) {
        selectedEdgeId = hoverEdgeId;
        const edge = edgeRenders.get(hoverEdgeId)?.edge;
        onStatus?.(`Selected edge ${edge?.label ?? hoverEdgeId}${edge?.uml?.relationship ? ` (${edge.uml.relationship})` : ""}`);
        paintEdges();
      }
    }

    const pressed = new Set<string>();
    function keyDown(event: KeyboardEvent) {
      if (["KeyW", "KeyA", "KeyS", "KeyD", "KeyR", "KeyQ", "KeyE"].includes(event.code)) pressed.add(event.code);
      if (event.code === "KeyF") {
        event.preventDefault();
        frame(selectedId, true);
      }
      if (event.code === "Home") {
        event.preventDefault();
        frame(null, true);
      }
    }
    function keyUp(event: KeyboardEvent) {
      pressed.delete(event.code);
    }

    renderer.domElement.addEventListener("pointermove", updatePointer);
    renderer.domElement.addEventListener("click", click);
    window.addEventListener("keydown", keyDown);
    window.addEventListener("keyup", keyUp);

    const clock = new THREE.Clock();
    function animate() {
      const dt = Math.min(0.04, clock.getDelta());
      const speed = controls.target.distanceTo(camera.position) * dt * 0.85;
      const direction = new THREE.Vector3();
      camera.getWorldDirection(direction);
      const right = new THREE.Vector3().crossVectors(direction, camera.up).normalize();
      if (pressed.has("KeyW")) {
        camera.position.addScaledVector(direction, speed);
        controls.target.addScaledVector(direction, speed);
      }
      if (pressed.has("KeyS")) {
        camera.position.addScaledVector(direction, -speed);
        controls.target.addScaledVector(direction, -speed);
      }
      if (pressed.has("KeyA")) {
        camera.position.addScaledVector(right, -speed);
        controls.target.addScaledVector(right, -speed);
      }
      if (pressed.has("KeyD")) {
        camera.position.addScaledVector(right, speed);
        controls.target.addScaledVector(right, speed);
      }
      if (pressed.has("KeyR")) {
        camera.position.y += speed;
        controls.target.y += speed;
      }
      if (pressed.has("KeyQ") || pressed.has("KeyE")) {
        camera.up.applyAxisAngle(direction, (pressed.has("KeyQ") ? 1 : -1) * dt);
      }

      for (const item of renderNodes.values()) {
        const dist = camera.position.distanceTo(item.group.position);
        item.label.visible = dist < 22;
        item.farLabel.visible = dist >= 14;
        item.farLabel.quaternion.copy(camera.quaternion);
      }
      paintSelection();
      controls.update();
      renderer.render(scene, camera);
    }
    renderer.setAnimationLoop(animate);

    const observer = new ResizeObserver(() => {
      const width = Math.max(1, host.clientWidth);
      const height = Math.max(1, host.clientHeight);
      renderer.setSize(width, height);
      camera.aspect = width / height;
      camera.updateProjectionMatrix();
    });
    observer.observe(host);

    const worldUp = new THREE.Vector3(0, 1, 0);
    if (handleRef) {
      handleRef.current = {
        getCameraPose() {
          const offset = camera.position.clone().sub(controls.target);
          const distance = Math.max(offset.length(), 1e-6);
          const yaw = THREE.MathUtils.radToDeg(Math.atan2(offset.x, offset.z));
          const pitch = THREE.MathUtils.radToDeg(Math.asin(THREE.MathUtils.clamp(offset.y / distance, -1, 1)));
          const dir = offset.clone().negate().normalize();
          const right0 = new THREE.Vector3().crossVectors(dir, worldUp);
          let roll = 0;
          if (right0.lengthSq() > 1e-8) {
            right0.normalize();
            const up0 = new THREE.Vector3().crossVectors(right0, dir).normalize();
            const upProj = camera.up.clone().projectOnPlane(dir);
            if (upProj.lengthSq() > 1e-8) {
              upProj.normalize();
              roll = THREE.MathUtils.radToDeg(Math.acos(THREE.MathUtils.clamp(up0.dot(upProj), -1, 1)));
              if (right0.dot(upProj) > 0) roll = -roll;
            }
          }
          return {
            yaw,
            pitch,
            roll,
            pivot: { x: controls.target.x, y: controls.target.y, z: controls.target.z },
            distance,
          };
        },
        setCameraPose(pose) {
          const pivot = new THREE.Vector3(pose.pivot.x, pose.pivot.y, pose.pivot.z);
          const distance = Math.max(0.5, pose.distance);
          const yawR = THREE.MathUtils.degToRad(pose.yaw);
          const pitchR = THREE.MathUtils.degToRad(THREE.MathUtils.clamp(pose.pitch, -89, 89));
          const offset = new THREE.Vector3(
            Math.sin(yawR) * Math.cos(pitchR),
            Math.sin(pitchR),
            Math.cos(yawR) * Math.cos(pitchR),
          ).multiplyScalar(distance);
          controls.target.copy(pivot);
          camera.position.copy(pivot.clone().add(offset));
          const dir = offset.clone().negate().normalize();
          const right0 = new THREE.Vector3().crossVectors(dir, worldUp);
          if (right0.lengthSq() > 1e-8) {
            right0.normalize();
            const up0 = new THREE.Vector3().crossVectors(right0, dir).normalize();
            camera.up.copy(up0.applyAxisAngle(dir, THREE.MathUtils.degToRad(-pose.roll)));
          } else {
            camera.up.set(0, 0, pose.pitch > 0 ? -1 : 1);
          }
          camera.lookAt(pivot);
          controls.update();
        },
        resetCamera() {
          camera.up.copy(worldUp);
          frame(null);
        },
        dropPointAt(clientX, clientY) {
          const rect = renderer.domElement.getBoundingClientRect();
          if (clientX < rect.left || clientX > rect.right || clientY < rect.top || clientY > rect.bottom) return null;
          const point = new THREE.Vector2(
            ((clientX - rect.left) / rect.width) * 2 - 1,
            -((clientY - rect.top) / rect.height) * 2 + 1,
          );
          raycaster.setFromCamera(point, camera);
          const out = new THREE.Vector3();
          // Placement plane: z = orbit target z (the layer plane the user is looking at).
          const layerPlane = new THREE.Plane(new THREE.Vector3(0, 0, 1), -controls.target.z);
          let hit = raycaster.ray.intersectPlane(layerPlane, out);
          if (!hit) {
            const facing = new THREE.Plane().setFromNormalAndCoplanarPoint(
              camera.getWorldDirection(new THREE.Vector3()).negate(),
              controls.target,
            );
            hit = raycaster.ray.intersectPlane(facing, out);
          }
          if (!hit) return null;
          const round = (value: number) => Math.round(value * 100) / 100;
          return { x: round(out.x), y: round(out.y), z: round(out.z) };
        },
      };
    }

    frame(selectedId ?? focusId ?? null);

    return () => {
      if (handleRef) handleRef.current = null;
      observer.disconnect();
      renderer.setAnimationLoop(null);
      renderer.domElement.removeEventListener("pointermove", updatePointer);
      renderer.domElement.removeEventListener("click", click);
      window.removeEventListener("keydown", keyDown);
      window.removeEventListener("keyup", keyUp);
      controls.dispose();
      for (const item of renderNodes.values()) {
        item.group.traverse((object) => {
          const mesh = object as THREE.Mesh;
          mesh.geometry?.dispose?.();
          const material = mesh.material;
          if (Array.isArray(material)) material.forEach((m) => m.dispose());
          else material?.dispose?.();
        });
      }
      for (const item of edgeRenders.values()) {
        for (const object of [item.line, item.cone]) {
          if (!object) continue;
          const mesh = object as THREE.Mesh | THREE.Line;
          mesh.geometry?.dispose?.();
          const material = mesh.material;
          if (Array.isArray(material)) material.forEach((m) => m.dispose());
          else material?.dispose?.();
        }
      }
      renderer.dispose();
      host.replaceChildren();
    };
  }, [document, focusId, handleRef, onSelect, onStatus, selectedId, tracedEdgeIds]);

  return <div ref={hostRef} className="trd-three-scene" aria-label="Interactive 3D UML scene" />;
}
