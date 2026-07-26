//
//  Shaders.metal
//  Carpet Grand Prix
//
//  The diorama is flat geometry with a height field. Every vertex knows how far
//  off the carpet it sits; the vertex shader displaces it along `viewVector`,
//  which is derived from the handset's gravity vector. Tilt the phone and the
//  raised surfaces slide across the floor by an amount proportional to their
//  height — correct positional parallax, no perspective matrix involved.
//

#include <metal_stdlib>
#include "ShaderTypes.h"

using namespace metal;

// MARK: - Shared projection

/// Height of the track deck above the carpet at a given physical elevation.
///
/// Deck height is expressed *relative to the camera's elevation*, so track ahead
/// of the car (lower) sinks toward the floor and track behind (higher) rises.
/// That is what makes gradient readable at a glance.
static inline float deckHeight(float elevation, constant CGPUniforms &u) {
    return clamp(u.baseHeight + (elevation - u.cameraElevation) * u.gradeRead, 8.0f, 210.0f);
}

/// World point + height -> screen point, in points.
static inline float2 projectPoint(float2 world, float height, constant CGPUniforms &u) {
    float2 p = (world - u.cameraXY) * u.scale + u.viewportCentre;
    return p + height * u.scale * u.viewVector;
}

/// Screen point (points, y-down) -> clip space.
static inline float4 toClip(float2 p, constant CGPUniforms &u) {
    float2 ndc = float2(p.x / u.viewportSize.x * 2.0f - 1.0f,
                        1.0f - p.y / u.viewportSize.y * 2.0f);
    return float4(ndc, 0.0f, 1.0f);
}

// MARK: - Diorama (track deck, rails, posts, shadow)

struct DioramaInOut {
    float4 position [[position]];
    float4 colour;
    float2 uv;
    float  shade;
};

vertex DioramaInOut diorama_vertex(uint vid [[vertex_id]],
                                   const device CGPDioramaVertex *verts [[buffer(CGPBufferVertices)]],
                                   constant CGPUniforms &u [[buffer(CGPBufferUniforms)]])
{
    CGPDioramaVertex v = verts[vid];

    float deck = deckHeight(v.elevation, u);
    // floorPinned surfaces (the cast shadow, the feet of the support posts) stay
    // on the carpet at height 0 and therefore never parallax.
    float height = mix(deck + v.heightOffset, 0.0f, v.floorPinned);

    float2 screen = projectPoint(v.position, height, u);

    DioramaInOut out;
    out.position = toClip(screen, u);
    out.colour   = v.colour;
    out.uv       = v.uv;
    out.shade    = v.shade;
    return out;
}

fragment float4 diorama_fragment(DioramaInOut in [[stage_in]],
                                 constant CGPUniforms &u [[buffer(CGPBufferUniforms)]])
{
    float4 c = in.colour;
    c.rgb *= in.shade;
    c.rgb *= u.ambient.rgb;
    return c;
}

// MARK: - Animated surfaces (boost chevrons)

fragment float4 boost_fragment(DioramaInOut in [[stage_in]],
                               constant CGPUniforms &u [[buffer(CGPBufferUniforms)]])
{
    // Chevrons scrolling along the strip's V axis.
    float v     = fract(in.uv.y * 3.0f - u.time * 1.6f);
    float band  = smoothstep(0.45f, 0.5f, v) * (1.0f - smoothstep(0.92f, 0.97f, v));
    float edge  = 1.0f - smoothstep(0.30f, 0.50f, abs(in.uv.x - 0.5f));

    float4 c = in.colour;
    c.a *= band * edge;
    c.rgb *= in.shade * u.ambient.rgb;
    return c;
}

// MARK: - Carpet

struct CarpetInOut {
    float4 position [[position]];
    float2 uv;
};

/// Full-screen triangle. The carpet lies at height 0, so it does not parallax —
/// it is the fixed ground the diorama slides over.
vertex CarpetInOut carpet_vertex(uint vid [[vertex_id]],
                                 constant CGPUniforms &u [[buffer(CGPBufferUniforms)]])
{
    // Oversized triangle covering the viewport.
    float2 ndc = float2((vid == 2) ? 3.0f : -1.0f,
                        (vid == 1) ? -3.0f : 1.0f);

    float2 screen = (ndc * float2(0.5f, -0.5f) + 0.5f) * u.viewportSize;
    float2 world  = (screen - u.viewportCentre) / u.scale + u.cameraXY;

    CarpetInOut out;
    out.position = float4(ndc, 0.0f, 1.0f);
    out.uv       = world / 220.0f;   // carpet texture is ~220 world units per tile
    return out;
}

fragment float4 carpet_fragment(CarpetInOut in [[stage_in]],
                                constant CGPUniforms &u [[buffer(CGPBufferUniforms)]],
                                texture2d<float> albedo [[texture(CGPTextureAlbedo)]],
                                sampler samp [[sampler(0)]])
{
    float4 c = albedo.sample(samp, in.uv);
    c.rgb *= u.ambient.rgb;

    // Radial vignette so the floor recedes into the room.
    float2 d = (in.position.xy / u.viewportSize - float2(0.5f, 0.55f));
    d.x *= u.viewportSize.x / u.viewportSize.y;
    float vig = 1.0f - smoothstep(0.18f, 0.80f, length(d)) * u.vignette;
    c.rgb *= vig;
    return c;
}

// MARK: - Sprites (car, ghost, shadows)

struct SpriteInOut {
    float4 position [[position]];
    float2 uv;
    float4 tint;
};

vertex SpriteInOut sprite_vertex(uint vid                      [[vertex_id]],
                                 uint iid                      [[instance_id]],
                                 const device CGPSpriteInstance *instances [[buffer(CGPBufferInstances)]],
                                 constant CGPUniforms &u       [[buffer(CGPBufferUniforms)]])
{
    // Unit quad as two triangles.
    const float2 corners[6] = {
        float2(-1.0f, -1.0f), float2( 1.0f, -1.0f), float2( 1.0f,  1.0f),
        float2(-1.0f, -1.0f), float2( 1.0f,  1.0f), float2(-1.0f,  1.0f)
    };
    float2 corner = corners[vid];

    CGPSpriteInstance inst = instances[iid];

    float  s = sin(inst.rotation);
    float  c = cos(inst.rotation);
    float2 local = float2(corner.x * c - corner.y * s,
                          corner.x * s + corner.y * c) * inst.size;

    float deck   = deckHeight(inst.elevation, u);
    float height = deck + inst.heightOffset;

    float2 screen = projectPoint(inst.position + local, height, u);

    SpriteInOut out;
    out.position = toClip(screen, u);
    out.uv       = corner * 0.5f + 0.5f;
    out.tint     = inst.tint;
    return out;
}

fragment float4 sprite_fragment(SpriteInOut in [[stage_in]],
                                constant CGPUniforms &u [[buffer(CGPBufferUniforms)]],
                                texture2d<float> albedo [[texture(CGPTextureAlbedo)]],
                                sampler samp [[sampler(0)]])
{
    float4 c = albedo.sample(samp, in.uv);
    c *= in.tint;
    c.rgb *= u.ambient.rgb;
    return c;
}

/// Soft elliptical blob used for the car's shadow on the deck.
fragment float4 shadow_fragment(SpriteInOut in [[stage_in]])
{
    float d = length(in.uv - 0.5f) * 2.0f;
    float a = (1.0f - smoothstep(0.55f, 1.0f, d)) * in.tint.a;
    return float4(0.0f, 0.0f, 0.0f, a);
}
