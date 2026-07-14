# Worked Example: 2D Lit Pixel-Art Platformer (Unity 6 / URP 2D)

End-to-end demonstration of the skill applied to a 2D game. Shows the decision → setup → code → gotcha flow an agent should follow.

## Request
> "I want to build a 2D pixel-art platformer in Unity with dynamic lighting (a lantern the player carries) and tilemap levels. Crisp pixels, no blur."

## Step 1 — Scope & pipeline (Workflow 1)
- Domain: 2D game. Target: desktop/Switch-class. Fidelity: pixel-art, dynamic 2D lights → **needs URP 2D Renderer** (BiRP/`2D` template has no 2D lights).
- **Decision:** Unity 6 (`6000.x`), **Universal 2D** template, packages: `com.unity.feature.2d`, `2d.tilemap.extras`, `2d.pixel-perfect`. (Verify versions in Package Manager.)

## Step 2 — Project setup
1. New project → **Universal 2D** template (wires URP Asset + 2D Renderer Data).
2. *Project Settings → Editor → Sprite Atlas → Mode = Sprite Atlas V2*.
3. Import all pixel sprites with: **Filter Mode = Point**, **Compression = None**, consistent **Pixels Per Unit** (say 16), Mip Maps off.
4. Add a **Sprite Atlas** (`Assets → Create → 2D → Sprite Atlas`), drag the sprite folders into Packables, Padding 4, Alpha Dilation on.

## Step 3 — Pixel-perfect camera
Add **Pixel Perfect Camera** to Main Camera:
- Assets Pixels Per Unit = **16** (must match sprites).
- Reference Resolution = **320×180**.
- **Upscale Render Texture = on** (crisp integer scaling), Pixel Snapping on, Crop Frame = Pillarbox/Letterbox.

## Step 4 — Tilemap level
1. `GameObject → 2D Object → Tilemap → Rectangular` (creates Grid + Tilemap).
2. `Window → 2D → Tile Palette`; drag tile sprites in → auto-generates Tile assets.
3. For auto-bordering terrain, create a **Rule Tile** (Extras): `Assets → Create → 2D → Tiles → Rule Tile`.
4. Add **Tilemap Collider 2D** + **Composite Collider 2D** (+ Rigidbody2D = Static) on the ground tilemap to merge colliders into one optimized shape.

## Step 5 — Lighting (the lantern)
1. `GameObject → Light → 2D → Global Light 2D` — set **Target Sorting Layers = All** at low intensity (ambient).
2. Child a **Point/Spot Light 2D** under the player (the lantern): Inner/Outer Radius, warm color, Target Sorting Layers = the gameplay layers.
3. Convert sprites to receive light: assign the **Sprite-Lit-Default** material (or a Shader Graph Sprite-Lit material). Add normal maps via Sprite Editor → Secondary Textures (`_NormalMap`) and set the lantern's **Normal Map Quality = Accurate** for relief.
4. **Keep light blend styles ≤ 2** in the 2D Renderer Data (each used style = an extra render texture).

## Step 6 — Player movement (Box2D v3 + Input System)
```csharp
using UnityEngine;
using UnityEngine.InputSystem;

[RequireComponent(typeof(Rigidbody2D))]
public class PlatformerController : MonoBehaviour {
    [SerializeField] float moveSpeed = 6f, jumpForce = 12f;
    [SerializeField] LayerMask groundMask;
    Rigidbody2D _rb;
    float _moveX;

    void Awake() => _rb = GetComponent<Rigidbody2D>();

    // Wired via PlayerInput (Send Messages) or a generated actions class
    public void OnMove(InputValue v) => _moveX = v.Get<Vector2>().x;
    public void OnJump(InputValue v) {
        if (v.isPressed && IsGrounded())
            _rb.linearVelocity = new Vector2(_rb.linearVelocity.x, jumpForce);
    }

    void FixedUpdate() =>   // physics in FixedUpdate
        _rb.linearVelocity = new Vector2(_moveX * moveSpeed, _rb.linearVelocity.y);

    bool IsGrounded() {
        // RaycastCommand for batches; single cast fine here
        return Physics2D.Raycast(transform.position, Vector2.down, 0.6f, groundMask);
    }
}
```
> Note `linearVelocity` (Unity 6 renamed `velocity`). Set *Project Settings → Player → Active Input Handling = Both* during migration.

## Step 7 — Gotchas hit along the way
- **Sprites render black** → no Global light, or sorting layer missing from the light's Target Sorting Layers, or sprite not on a Sprite-Lit material. (All three are common.)
- **Pixel shimmer when moving** → a sprite slipped through with Bilinear filtering or compression on, or camera isn't pixel-perfect. Audit all four import settings.
- **Tile seams at zoom** → atlas padding + Alpha Dilation + Point filter; Pixel Perfect Camera handles non-integer zoom.
- **Jitter on the lantern light** → enable Rigidbody2D **Interpolate** on the player.

## Result
A crisp pixel-art platformer: Universal 2D + Sprite Atlas V2, pixel-perfect camera, Rule-Tile levels with a composite collider, a carried 2D point light with normal-mapped relief, and Box2D-v3 movement on the Input System. Performance levers applied: ≤2 blend styles, atlasing, composite collider, point-filtered imports.
