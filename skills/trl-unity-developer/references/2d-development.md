# Unity 2D Development (Priority)

Scope: Unity **6.0 / 6.1 / 6.2 / 6.3 LTS** era. Verified against `docs.unity3d.com` 6000.x. The 2D toolchain ships as the **2D feature set** (`com.unity.feature.2d`); install via the **2D (Core)** or **Universal 2D** template, or Package Manager → Features.

> Flag: URP package version is tied to the Editor version in 6.x. Package versions below (Animation 12.x, Pixel Perfect 5.x, Tilemap Extras 8.x) correspond to Editor 6000.2 — check in-Editor Package Manager for your build.

## 1. 2D Rendering — URP 2D Renderer

Configured through a **2D Renderer Data** asset assigned to a **URP Asset**. Use the **Universal 2D** template (the bare "2D" template uses BiRP → no 2D lights).

| Concept | Detail |
|---|---|
| **2D Renderer Data** | Holds Light Blend Styles, default material type, transparency sort settings, camera sorting layer texture, post-processing. |
| **Sprite Renderer** | `sprite`, `color` (tint+alpha), `flipX/flipY`, `drawMode` (Simple/Sliced/Tiled — 9-slice needs sprite border), `maskInteraction`, `spriteSortPoint` (Center/Pivot). |
| **Sorting Layers** | *Project Settings → Tags and Layers → Sorting Layers*. Draw order = Sorting Layer → Order in Layer → distance/sort-point. Set via `SpriteRenderer.sortingLayerName`/`sortingOrder`. |
| **Transparency Sort Mode** | Per-camera or URP asset. Top-down: set **Custom Axis** `(0,1,0)` so lower-on-screen sprites draw in front. |
| **Batching** | URP SRP Batcher; same-material sprites batch. Sprite Atlas is the main draw-call reducer. |

**Sprite Masks:** `SpriteMask` restricts where sprites render; opt in via `maskInteraction` (`VisibleInsideMask`/`VisibleOutsideMask`), using the mask sprite's alpha within a sorting range.

## 2. 2D Lighting & Shadows (URP)

Works with Sprite, Tilemap, and Sprite Shape renderers. Add: *GameObject → Light → 2D → …*. Component: **`Light2D`** (`UnityEngine.Rendering.Universal`).

**Types:** **Freeform** (spline/polygon shape + Falloff), **Sprite** (uses a sprite as the light source/cookie), **Point** (Inner/Outer Radius + Inner/Outer Spot Angle for cones), **Global** (flat illumination across targeted sorting layers — only one per blend style per sorting layer).

**Shared props:** Color, Intensity, **Target Sorting Layers**, **Blend Style**, Light Order, Overlap Operation (Additive/Alpha Blend), **Shadow Strength**, Volumetric Intensity, **Normal Map Quality** (Disabled/Fast/Accurate) + Normal Map Distance.

**Light Blend Styles** are defined in the 2D Renderer Data (small fixed number). Each used blend style = one extra Light Render Texture. **Biggest perf lever: minimize blend styles — two is usually enough.**

**Normal maps for 2D:** assign a secondary normal texture (Sprite Editor → Secondary Textures as `_NormalMap`); Light2D Normal Map Quality must be enabled. **Shadows:** **`ShadowCaster2D`** casts; **Composite Shadow Caster 2D** merges casters. Lit sprites need a **Sprite-Lit** material (Sprite-Lit-Default or Shader Graph 2D-lit target).

## 3. Tilemaps

Built-in 2D Tilemap Editor; extra brushes via **2D Tilemap Extras** (`com.unity.2d.tilemap.extras` 8.x).

| Object | Role |
|---|---|
| **Grid** | Cell layout: Rectangle / Hexagonal (flat/point-top) / Isometric / Isometric Z-as-Y. |
| **Tilemap** + **Tilemap Renderer** | Child of Grid; Sort Order, Mode (Chunk vs Individual — Individual for per-tile sorting in isometric). |
| **Tile Palette** | *Window → 2D → Tile Palette*. Paint/erase/fill/pick; drag sprites in to auto-generate Tile assets. |
| **Tilemap Collider 2D** | Auto-collider; combine with **Composite Collider 2D** (+ Static Rigidbody2D) to merge into one optimized shape. |

**Tile types:** basic **Tile**; **Rule Tile** (Extras — neighbor-pattern auto-pick; Hexagonal/Isometric variants must match grid); **Animated/Random** tiles; **Scriptable Tiles** (subclass `TileBase`/`Tile`, override `GetTileData`/`RefreshTile`/`StartUp`).

## 4. Sprite Tooling

- **Sprite Editor** — slicing (Automatic / Grid by Cell Size or Count), pivot, borders (9-slice), Custom Outline, Custom Physics Shape, Secondary Textures.
- **Sprite Shape** (`com.unity.2d.spriteshape`) — spline-based 2D geometry (Profile asset + Controller + Renderer); auto-fit Edge/Polygon Collider; great for organic terrain/platforms.
- **2D PSD Importer** (`com.unity.2d.psdimporter`) — imports Photoshop **.psb**, mosaics layers, generates a Prefab with one sprite per layer (the rigged-character pipeline; use `.psb`, not `.psd`).
- **Sprite Swap** (part of 2D Animation) — runtime art switching via **Sprite Library Asset** (Categories+Labels) + **Sprite Library** + **Sprite Resolver**. Swap whole libraries for skins, or by Label for expressions/equipment.

## 5. 2D Animation

1. **Frame-by-frame** — `Animator` + `AnimationClip` keyframing `SpriteRenderer.sprite`. No extra packages.
2. **Skeletal / bone** (`com.unity.2d.animation` 12.x) — **Skinning Editor** (bones, auto-weighted mesh, weight painting); **Sprite Skin** runtime deformer; companions **PSD Importer**, **2D IK** (`com.unity.2d.ik` — `IKManager2D` with Limb/CCD/FABRIK solvers), **2D Aseprite Importer** (`com.unity.2d.aseprite` — imports `.ase/.aseprite` layers + frame animation directly).

## 6. 2D Physics — Box2D v3 (major Unity 6 change)

**Unity 6's 2D physics is now backed by Box2D version 3** (rewrite from Box2D 2.x), with large performance + determinism gains.

**Classic component layer (unchanged API):** **Rigidbody2D** (`bodyType` Dynamic/Kinematic/Static, `gravityScale`, `interpolation`, `collisionDetection`); **Collider2D** (Box/Circle/Capsule/Polygon/Edge/Composite/Tilemap/Custom); **Effector2D** (Area/Point/Platform-one-way/Surface-conveyor/Buoyancy); **Joint2D** (Hinge/Spring/Distance/Slider/Wheel/Fixed/Friction/Relative/Target); `PhysicsMaterial2D`, `ConstantForce2D`.

**New Physics Core 2D / LowLevelPhysics2D API** (namespace **`Unity.U2D.Physics`**): a separate, struct-based, GameObject-free system that **does not interact with Rigidbody2D/Collider2D**. Fully deterministic; parallel across **up to 64 CPU cores**; **DOTS/Jobs/Burst friendly**; **64** collision layers (vs 32). Create unlimited bodies/shapes in code. Use for huge-entity-count sims, headless deterministic sims, or DOTS; keep classic components for standard MonoBehaviour gameplay.

> Flag: low-level type names (`PhysicsWorld`, `PhysicsBody`, `PhysicsShape`) stabilizing across 6.1→6.3; verify in the Physics Core 2D API manual for your editor.

## 7. Pixel-Perfect

**Pixel Perfect Camera** (`com.unity.2d.pixel-perfect` 5.x; a Renderer Feature / camera component in URP). Key props: **Assets Pixels Per Unit** (must equal sprite PPU), **Reference Resolution** (e.g. 320×180), **Upscale Render Texture** (render at ref res then upscale → crisp), **Pixel Snapping**, **Crop Frame** (None/Pillarbox/Letterbox/Windowbox/Stretch Fill). Pixel-art import: Filter Mode = **Point**, **Compression = None**, consistent PPU, disable Mip Maps.

## 8. Sprite Atlas (V2)

Unity 6.x uses **Sprite Atlas V2** by default (*Project Settings → Editor → Sprite Atlas → Mode = V2*). Create: *Assets → Create → 2D → Sprite Atlas*. Type **Master**/**Variant**; drag sprites/folders into **Packables**; packing settings (Allow Rotation, Tight Packing, Alpha Dilation, Padding). **Include in Build** off → load at runtime (`SpriteAtlasManager.atlasRequested`). V2 is asset-database-driven (deterministic, better for VCS + Addressables/late binding).

```csharp
SpriteAtlasManager.atlasRequested += (tag, cb) =>
    cb(Addressables.LoadAssetAsync<SpriteAtlas>(tag).WaitForCompletion());
```

## 9. Setup, Gotchas & Black Magic

- **Template:** use **Universal 2D** (URP + 2D Renderer Data pre-wired).
- **Unlit sprites stay black under 2D lights** if there's no Global light, the sorting layer isn't in the light's Target Sorting Layers, or the sprite isn't using a Sprite-Lit material.
- **Sorting flicker/wrong depth (top-down):** Transparency Sort Mode = Custom Axis `(0,1,0)` + Sprite Sort Point = Pivot.
- **Tilemap seams/bleeding:** Filter Mode = Point, add atlas padding + Alpha Dilation; Pixel Perfect Camera for non-integer zoom.
- **Perf order:** minimize **light blend styles** → **Sprite Atlas** → **Composite Collider 2D** for tilemaps → Tilemap Renderer Chunk mode → bake static shadow casters.
- **Pixel-art shimmer** = Filter Mode ≠ Point, compression ≠ None, mismatched PPU, or camera not pixel-perfect. Fix all four.
- **Box2D v3 migration:** stacking/restitution/contacts may differ subtly when upgrading old projects — re-tune physics materials and joint stiffness.

**Key packages (6000.2 baseline):** `com.unity.feature.2d` · `2d.animation` 12.x · `2d.pixel-perfect` 5.x · `2d.tilemap.extras` 8.x · `2d.spriteshape` · `2d.psdimporter` · `2d.aseprite` · `2d.ik` · `2d.common` · URP (pinned to Editor) · 2D physics (classic + `Unity.U2D.Physics`, Box2D v3).
