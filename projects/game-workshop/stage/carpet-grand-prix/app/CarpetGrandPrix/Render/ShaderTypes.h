//
//  ShaderTypes.h
//  Types shared between Swift and Metal Shading Language.
//
//  Included from Swift via BridgingHeader.h and from Shaders.metal directly,
//  so every field layout is guaranteed identical on both sides.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

// MARK: - Binding indices

typedef enum CGPBufferIndex {
    CGPBufferVertices  = 0,
    CGPBufferUniforms  = 1,
    CGPBufferInstances = 2
} CGPBufferIndex;

typedef enum CGPTextureIndex {
    CGPTextureAlbedo = 0
} CGPTextureIndex;

// MARK: - Vertex formats

/// One vertex of the static track diorama.
///
/// The whole parallax trick lives in how these three height fields combine in
/// `diorama_vertex`:
///
///   deck   = baseHeight + (elevation - cameraElevation) * GRADE_READ
///   height = floorPinned ? 0 : deck + heightOffset
///   screen = (position - camera) * scale + centre + height * scale * viewVector
///
/// `viewVector` comes straight from the handset's gravity vector, so tilting the
/// phone slides every raised surface across the carpet by an amount proportional
/// to how far off the floor it sits.
typedef struct CGPDioramaVertex {
    simd_float2 position;      // world XY, in track units
    float       elevation;     // physical track elevation at this sample
    float       heightOffset;  // world units above the deck (rails +, underside -)
    float       floorPinned;   // 1 = ignore deck height, lie flat on the carpet
    float       shade;         // baked edge darkening, multiplied into colour
    simd_float2 uv;
    simd_float4 colour;
} CGPDioramaVertex;

/// One instanced sprite (car, ghost, car shadow).
typedef struct CGPSpriteInstance {
    simd_float2 position;      // world XY
    float       elevation;     // track elevation used for the deck lookup
    float       heightOffset;  // above the deck: 0 = shadow on deck, >0 = airborne
    float       rotation;      // radians, 0 = pointing along +X
    float       size;          // half-extent in world units
    simd_float4 tint;
} CGPSpriteInstance;

// MARK: - Uniforms

typedef struct CGPUniforms {
    simd_float2 cameraXY;
    float       cameraElevation;
    float       scale;            // world units -> points

    simd_float2 viewportCentre;   // in points
    simd_float2 viewportSize;     // in points

    /// Parallax direction. x = roll term, y is pre-negated on the CPU so that a
    /// positive height always moves a vertex toward the top of the screen.
    simd_float2 viewVector;

    float       baseHeight;       // resting height of the deck above the carpet
    float       gradeRead;        // how strongly elevation delta maps to height
    float       time;             // seconds, for animated surfaces
    float       carpetScroll;     // carpet texture phase

    simd_float4 ambient;          // room light tint
    float       vignette;
    float       _pad0;
    float       _pad1;
    float       _pad2;
} CGPUniforms;

#endif /* ShaderTypes_h */
