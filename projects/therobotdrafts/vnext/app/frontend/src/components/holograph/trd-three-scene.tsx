"use client";

import { useEffect, useRef } from "react";
import * as THREE from "three";
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls.js";
import { buildTrd3dScene, type Trd3dNodeShapeKind } from "@/lib/trd-3d";
import type { GraphDocument, GraphEdge, GraphNode } from "@/lib/holograph/types";

interface TrdThreeSceneProps {
  document: GraphDocument;
  selectedId?: string | null;
  focusId?: string | null;
  tracedEdgeIds?: Set<string>;
  onSelect?: (nodeId: string) => void;
  onStatus?: (message: string) => void;
}

interface RenderNode {
  node: GraphNode;
  group: THREE.Group;
  body: THREE.Object3D;
  label: THREE.Mesh;
  farLabel: THREE.Sprite;
  baseColor: THREE.Color;
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
  if (node.kind === "database") return new THREE.Color("#5f7f9d");
  if (node.kind === "interface") return new THREE.Color("#6d8fbd");
  if (node.kind === "package") return new THREE.Color("#6a7f55");
  if (node.kind === "service") return new THREE.Color("#8262a8");
  return new THREE.Color("#4d9a8f");
}

function escapeLabel(value: string | undefined) {
  return (value ?? "").replace(/[<>]/g, "");
}

function labelTexture(node: GraphNode, compact = false) {
  const width = 768;
  const height = compact ? 192 : 448;
  const canvas = document.createElement("canvas");
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext("2d");
  if (!ctx) throw new Error("Canvas unavailable for TRD 3D label texture.");

  const bg = nodeColor(node);
  const fill = `rgb(${Math.round(bg.r * 255)}, ${Math.round(bg.g * 255)}, ${Math.round(bg.b * 255)})`;
  ctx.clearRect(0, 0, width, height);
  ctx.fillStyle = "rgba(255, 253, 248, 0.96)";
  ctx.fillRect(0, 0, width, height);
  ctx.strokeStyle = fill;
  ctx.lineWidth = 16;
  ctx.strokeRect(8, 8, width - 16, height - 16);

  ctx.fillStyle = "rgba(24, 29, 30, 0.92)";
  ctx.textAlign = "center";
  ctx.textBaseline = "top";
  ctx.font = "700 38px ui-monospace, Menlo, monospace";
  const stereotype = node.stereotype ? `<<${escapeLabel(node.stereotype)}>>` : node.uml?.elementType ?? node.kind;
  ctx.fillText(stereotype, width / 2, 32);

  ctx.font = "900 58px Inter, ui-sans-serif, system-ui";
  ctx.fillText(escapeLabel(node.label), width / 2, compact ? 94 : 88);
  if (compact) {
    const texture = new THREE.CanvasTexture(canvas);
    texture.colorSpace = THREE.SRGBColorSpace;
    texture.needsUpdate = true;
    return texture;
  }

  ctx.strokeStyle = "rgba(24, 29, 30, 0.24)";
  ctx.lineWidth = 4;
  ctx.beginPath();
  ctx.moveTo(40, 168);
  ctx.lineTo(width - 40, 168);
  ctx.stroke();

  ctx.textAlign = "left";
  ctx.font = "600 30px ui-monospace, Menlo, monospace";
  const attrs = node.uml?.attributes?.length ? node.uml.attributes : node.members ?? [];
  const ops = node.uml?.operations ?? [];
  let y = 196;
  for (const attr of attrs.slice(0, 4)) {
    ctx.fillText(escapeLabel(attr), 52, y);
    y += 36;
  }
  if (ops.length) {
    ctx.beginPath();
    ctx.moveTo(40, y + 8);
    ctx.lineTo(width - 40, y + 8);
    ctx.stroke();
    y += 28;
    for (const op of ops.slice(0, 4)) {
      ctx.fillText(escapeLabel(op), 52, y);
      y += 36;
    }
  }

  const texture = new THREE.CanvasTexture(canvas);
  texture.colorSpace = THREE.SRGBColorSpace;
  texture.needsUpdate = true;
  return texture;
}

function buildBody(node: GraphNode, dims: { width: number; height: number; depth: number }, material: THREE.Material) {
  const shape = node.trd3d?.shape;
  if (shape === "cylinder" || node.kind === "database") {
    const geometry = new THREE.CylinderGeometry(dims.width * 0.42, dims.width * 0.42, dims.height, 36, 1);
    const mesh = new THREE.Mesh(geometry, material);
    mesh.rotation.z = Math.PI / 2;
    return mesh;
  }

  if (shape === "sphere" || node.kind === "function") {
    return new THREE.Mesh(new THREE.SphereGeometry(Math.max(dims.width, dims.height) * 0.42, 36, 18), material);
  }

  const geometry =
    shape === "component" || node.kind === "service"
      ? new THREE.BoxGeometry(dims.width, dims.height, dims.depth, 1, 1, 1)
      : new THREE.BoxGeometry(dims.width, dims.height, dims.depth);
  return new THREE.Mesh(geometry, material);
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

  const body = buildBody(node, dims, material);
  body.userData.nodeId = node.id;
  group.add(body);

  const outline = new THREE.LineSegments(
    new THREE.EdgesGeometry((body as THREE.Mesh).geometry),
    new THREE.LineBasicMaterial({ color: baseColor.clone().lerp(new THREE.Color("#080b0d"), 0.45), linewidth: 1 }),
  );
  body.add(outline);

  const faceTexture = labelTexture(node);
  const label = new THREE.Mesh(
    new THREE.PlaneGeometry(dims.width * 0.94, dims.height * 0.9),
    new THREE.MeshBasicMaterial({ map: faceTexture, transparent: true, depthTest: true }),
  );
  label.position.z = dims.depth * 0.5 + 0.012;
  label.userData.nodeId = node.id;
  group.add(label);

  const farTexture = labelTexture(node, true);
  const farLabel = new THREE.Sprite(new THREE.SpriteMaterial({ map: farTexture, transparent: true, depthTest: false }));
  farLabel.scale.set(Math.max(1.8, dims.width * 0.92), Math.max(0.45, dims.height * 0.28), 1);
  farLabel.position.set(0, dims.height * 0.66, 0);
  farLabel.visible = false;
  farLabel.userData.nodeId = node.id;
  group.add(farLabel);

  return { node, group, body, label, farLabel, baseColor };
}

function edgeColor(edge: GraphEdge, traced: boolean) {
  if (traced) return new THREE.Color("#ffd36b");
  if (edge.uml?.relationship === "composition") return new THREE.Color("#f2f0e8");
  if (edge.uml?.relationship === "realization") return new THREE.Color("#8ed7d1");
  if (edge.kind === "patches") return new THREE.Color("#d5a0ff");
  return new THREE.Color("#9ab0ba");
}

function addEdge(scene: THREE.Scene, edge: GraphEdge, nodes: Map<string, RenderNode>, traced: boolean) {
  const source = nodes.get(edge.sourceId);
  const target = nodes.get(edge.targetId);
  if (!source || !target) return null;

  const points = edge.trd3d?.waypoints?.map((p) => new THREE.Vector3(p.x, p.y, p.z)) ?? [
    source.group.position,
    source.group.position.clone().lerp(target.group.position, 0.5).add(new THREE.Vector3(0, 0.7, 0.5)),
    target.group.position,
  ];

  const color = edgeColor(edge, traced);
  const dashed = edge.uml?.dashed || edge.kind === "depends_on";
  const material = dashed
    ? new THREE.LineDashedMaterial({ color, dashSize: 0.24, gapSize: 0.14, transparent: true, opacity: traced ? 1 : 0.72 })
    : new THREE.LineBasicMaterial({ color, transparent: true, opacity: traced ? 1 : 0.68 });

  const line = new THREE.Line(new THREE.BufferGeometry().setFromPoints(points), material);
  line.name = `Edge:${edge.id}`;
  line.userData.edgeId = edge.id;
  if (dashed) line.computeLineDistances();
  scene.add(line);

  if (edge.uml?.arrow !== "none") {
    const end = points[points.length - 1];
    const prev = points[points.length - 2];
    const dir = end.clone().sub(prev).normalize();
    const cone = new THREE.Mesh(
      new THREE.ConeGeometry(edge.uml?.arrow === "diamond" ? 0.18 : 0.13, edge.uml?.arrow === "diamond" ? 0.34 : 0.28, 4),
      new THREE.MeshStandardMaterial({ color, roughness: 0.55 }),
    );
    cone.position.copy(end).sub(dir.clone().multiplyScalar(0.18));
    cone.quaternion.setFromUnitVectors(new THREE.Vector3(0, 1, 0), dir);
    cone.userData.edgeId = edge.id;
    scene.add(cone);
    return [line, cone];
  }

  return [line];
}

export function TrdThreeScene({ document, selectedId, focusId, tracedEdgeIds, onSelect, onStatus }: TrdThreeSceneProps) {
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
    const renderDocument: GraphDocument = {
      ...document,
      nodes: document.nodes.map((node) => {
        const sceneNode = sceneNodeById.get(node.id);
        if (!sceneNode) return node;
        return {
          ...node,
          trd3d: {
            ...node.trd3d,
            position: sceneNode.position,
            dimensions: sceneNode.slab,
            layer: sceneNode.zLayer,
            shape: shapeHint(sceneNode.shapeKind),
          },
        };
      }),
      edges: document.edges.map((edge) => {
        const sceneEdge = sceneEdgeById.get(edge.id);
        if (!sceneEdge) return edge;
        return {
          ...edge,
          trd3d: {
            ...edge.trd3d,
            waypoints: sceneEdge.waypoints,
            layer: sceneEdge.zLayer,
          },
        };
      }),
    };

    const scene = new THREE.Scene();
    scene.background = new THREE.Color("#162022");
    scene.fog = new THREE.FogExp2("#162022", 0.0012);

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
      pickTargets.push(renderNode.body);
      scene.add(renderNode.group);
    }

    const edgeObjects: THREE.Object3D[] = [];
    for (const edge of renderDocument.edges) {
      const created = addEdge(scene, edge, renderNodes, Boolean(tracedEdgeIds?.has(edge.id)));
      if (created) edgeObjects.push(...created);
    }

    const raycaster = new THREE.Raycaster();
    const pointer = new THREE.Vector2();
    let hoverId: string | null = null;

    function frame(nodeId?: string | null) {
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
      onStatus?.(nodeId ? `Framed ${renderNodes.get(nodeId)?.node.label}` : "Framed whole 3D UML model");
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
      }
    }

    function updatePointer(event: PointerEvent) {
      const rect = renderer.domElement.getBoundingClientRect();
      pointer.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
      pointer.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;
      raycaster.setFromCamera(pointer, camera);
      const hit = raycaster.intersectObjects(pickTargets, false)[0];
      hoverId = hit?.object.userData.nodeId ?? null;
      renderer.domElement.style.cursor = hoverId ? "pointer" : "grab";
      paintSelection();
    }

    function click() {
      if (!hoverId) return;
      onSelect?.(hoverId);
      onStatus?.(`Selected 3D UML node ${renderNodes.get(hoverId)?.node.label ?? hoverId}`);
    }

    const pressed = new Set<string>();
    function keyDown(event: KeyboardEvent) {
      if (["KeyW", "KeyA", "KeyS", "KeyD", "KeyR", "KeyQ", "KeyE"].includes(event.code)) pressed.add(event.code);
      if (event.code === "KeyF") {
        event.preventDefault();
        frame(selectedId);
      }
      if (event.code === "Home") {
        event.preventDefault();
        frame(null);
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

    frame(selectedId ?? focusId ?? null);

    return () => {
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
      for (const object of edgeObjects) {
        const mesh = object as THREE.Mesh | THREE.Line;
        mesh.geometry?.dispose?.();
        const material = mesh.material;
        if (Array.isArray(material)) material.forEach((m) => m.dispose());
        else material?.dispose?.();
      }
      renderer.dispose();
      host.replaceChildren();
    };
  }, [document, focusId, onSelect, onStatus, selectedId, tracedEdgeIds]);

  return <div ref={hostRef} className="trd-three-scene" aria-label="Interactive 3D UML scene" />;
}
