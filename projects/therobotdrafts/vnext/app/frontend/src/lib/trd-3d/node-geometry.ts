import * as THREE from "three";
import type { NodeSilhouette } from "@/lib/holograph/node-visuals";

/** 3D bodies for each UML element kind.
 *
 * Replaces the previous `buildBody()`, which had three outcomes (cylinder / sphere / box)
 * and sent `class`, `interface`, `package`, `system`, `service` and `agent` all through the
 * same `BoxGeometry` -- the "plain boxes" problem.
 *
 * Each builder returns the primary mesh plus the Z offset the face card should sit at, since
 * a cylinder's or hex prism's front face is nowhere near `depth / 2`. Ornaments (the folder
 * tab, the component tabs, the interface lollipop) are added as children of the primary mesh
 * and share its material, so selection and hover tinting reach them for free. The wireframe
 * outline in `makeRenderNode` is built from the primary geometry only, which keeps the
 * silhouette read clean rather than tracing every ornament. */

export interface NodeBody {
  mesh: THREE.Mesh;
  /** Where to place the face-card plane along +Z, in local units. */
  labelZ: number;
  /** Multiplier on the face card's width/height, for shapes that inscribe it. */
  labelScale: number;
}

export interface BodyDims {
  width: number;
  height: number;
  depth: number;
}

function ornament(geometry: THREE.BufferGeometry, material: THREE.Material, x: number, y: number, z = 0) {
  const mesh = new THREE.Mesh(geometry, material);
  mesh.position.set(x, y, z);
  return mesh;
}

export function buildNodeBody(silhouette: NodeSilhouette, dims: BodyDims, material: THREE.Material): NodeBody {
  const { width: w, height: h, depth: d } = dims;

  switch (silhouette) {
    /** Package: UML folder -- body rectangle with a name tab riding above its top-left.
     * Unity models the same thing as `Uml3DShape_Folder` / `PackageNode`. */
    case "namespace-slab": {
      const mesh = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), material);
      const tabW = w * 0.34;
      const tabH = h * 0.16;
      mesh.add(ornament(new THREE.BoxGeometry(tabW, tabH, d * 0.94), material, -(w - tabW) * 0.5, (h + tabH) * 0.5));
      return { mesh, labelZ: d * 0.5, labelScale: 0.94 };
    }

    /** Component: rectangle with the two tabs protruding from its left edge. */
    case "component-capsule": {
      const mesh = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), material);
      const tabW = w * 0.14;
      const tabH = h * 0.16;
      const tabGeometry = new THREE.BoxGeometry(tabW, tabH, d * 1.3);
      for (const y of [h * 0.22, -h * 0.22]) {
        mesh.add(ornament(tabGeometry, material, -(w * 0.5), y));
      }
      return { mesh, labelZ: d * 0.5, labelScale: 0.92 };
    }

    /** Interface: a thinner card than a class, plus the provided-interface lollipop --
     * a ball on a stem rising off the top edge. */
    case "interface-card": {
      const depth = d * 0.6;
      const mesh = new THREE.Mesh(new THREE.BoxGeometry(w, h, depth), material);
      const stemH = h * 0.2;
      const ballR = Math.min(w, h) * 0.09;
      mesh.add(ornament(new THREE.CylinderGeometry(ballR * 0.28, ballR * 0.28, stemH, 10), material, 0, h * 0.5 + stemH * 0.5));
      mesh.add(ornament(new THREE.SphereGeometry(ballR, 20, 12), material, 0, h * 0.5 + stemH + ballR * 0.8));
      return { mesh, labelZ: depth * 0.5, labelScale: 0.94 };
    }

    /** Datastore: upright cylinder. The previous renderer laid it on its side
     * (`rotation.z = PI/2`), which reads as a barrel rather than UML's standing drum. */
    case "database-cylinder": {
      const radius = Math.max(w, h) * 0.42;
      const mesh = new THREE.Mesh(new THREE.CylinderGeometry(radius, radius, h, 40, 1), material);
      return { mesh, labelZ: radius + 0.012, labelScale: 0.7 };
    }

    /** Operation: a true capsule, not the sphere the old renderer used. */
    case "method-pill": {
      const radius = h * 0.42;
      const length = Math.max(0.12, w - radius * 2);
      const mesh = new THREE.Mesh(new THREE.CapsuleGeometry(radius, length, 8, 20), material);
      mesh.rotation.z = Math.PI / 2;
      return { mesh, labelZ: radius + 0.012, labelScale: 0.66 };
    }

    /** Actor / agent: flat-topped hexagonal prism. The stick figure itself is drawn on the
     * face card -- a mesh stick figure disappears at any real camera distance. */
    case "actor-hex": {
      const radius = Math.max(w, h) * 0.54;
      const geometry = new THREE.CylinderGeometry(radius, radius, d, 6, 1);
      // Spin about the prism's own axis in geometry space so the hex ends up flat-topped;
      // doing this as a second Euler term on the mesh would rotate in the wrong frame.
      geometry.rotateY(Math.PI / 6);
      const mesh = new THREE.Mesh(geometry, material);
      mesh.rotation.x = Math.PI / 2;
      return { mesh, labelZ: d * 0.5 + 0.012, labelScale: 0.72 };
    }

    /** System boundary: a plain slab, drawn translucent by the caller's material. */
    case "compound-slab":
    /** Class: the canonical three-compartment rectangle. */
    case "class-box":
    default: {
      const mesh = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), material);
      return { mesh, labelZ: d * 0.5, labelScale: 0.94 };
    }
  }
}
