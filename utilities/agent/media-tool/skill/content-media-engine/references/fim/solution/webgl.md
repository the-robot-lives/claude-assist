# WebGL / WebGL2 — raw GPU rasterization API in the browser

WebGL is the low-level, OpenGL ES-based graphics API exposed on a `<canvas>`. There is no scene graph, no camera object, no material system — you write **GLSL shaders**, upload vertex data into **buffers**, link a **program**, bind attributes/uniforms, and issue **draw calls** yourself. WebGL2 (OpenGL ES 3.0) adds VAOs, instancing, transform feedback, multiple render targets, 3D textures, and `#version 300 es` GLSL. It's what three.js/PlayCanvas/pixi are built on; you drop to raw WebGL for custom render pipelines, GPGPU, shader art, or minimal-footprint effects.

**Current Version**: WebGL 2.0 (baseline in all modern browsers; WebGL 1.0 is the fallback) **License**: Web standard (Khronos), no dependency **Bundle/Runtime**: zero — native `canvas.getContext('webgl2')`.

## Official Resources & Documentation
- **MDN WebGL**: https://developer.mozilla.org/en-US/docs/Web/API/WebGL_API
- **WebGL2 Fundamentals**: https://webgl2fundamentals.org/ (the canonical tutorial)
- **WebGL Fundamentals**: https://webglfundamentals.org/
- **Spec**: https://registry.khronos.org/webgl/specs/latest/2.0/
- **GLSL ES 3.00 spec**: https://registry.khronos.org/OpenGL/specs/es/3.0/GLSL_ES_Specification_3.00.pdf
- **The Book of Shaders** (fragment shaders): https://thebookofshaders.com/

## How WebGL differs from three.js
| Concern | three.js | raw WebGL |
|---|---|---|
| Scene graph | `Scene`/`Object3D` tree | none — you track objects yourself |
| Camera/matrices | `PerspectiveCamera` | you build model/view/projection matrices (e.g. gl-matrix) |
| Materials/lighting | prebuilt PBR + lights | you write all shading in GLSL |
| Geometry | `BoxGeometry`, loaders | you fill typed-array buffers by hand |
| Draw loop | `renderer.render()` | you bind program/VAO, set uniforms, `gl.drawArrays` |
Use raw WebGL when you need total control or minimal size; use three.js when you want productivity.

## Installation & Setup
No install. Get a context; consider `gl-matrix` for math.
```html
<canvas id="c" width="800" height="600"></canvas>
<script type="module">
  const canvas = document.getElementById('c');
  const gl = canvas.getContext('webgl2');       // or 'webgl' for v1 fallback
  if (!gl) throw new Error('WebGL2 not supported');
</script>
```
```bash
npm install gl-matrix   # optional: mat4/vec3 helpers
```

## Core Syntax / API Reference

### 1. Shaders (GLSL ES 3.00)
```javascript
const vsSource = `#version 300 es
in vec4 aPosition;
in vec3 aColor;
uniform mat4 uMVP;
out vec3 vColor;
void main() {
  vColor = aColor;
  gl_Position = uMVP * aPosition;
}`;

const fsSource = `#version 300 es
precision highp float;          // REQUIRED in fragment shaders
in vec3 vColor;
out vec4 fragColor;             // WebGL2: declare output, not gl_FragColor
uniform float uTime;
void main() {
  fragColor = vec4(vColor * (0.5 + 0.5 * sin(uTime)), 1.0);
}`;
```
WebGL1 uses `attribute`/`varying`/`gl_FragColor` and no `#version` line; WebGL2 uses `in`/`out`/named outputs with `#version 300 es`.

### 2. Compile & link a program
```javascript
function compile(gl, type, src) {
  const s = gl.createShader(type);
  gl.shaderSource(s, src);
  gl.compileShader(s);
  if (!gl.getShaderParameter(s, gl.COMPILE_STATUS))
    throw new Error(gl.getShaderInfoLog(s));   // ALWAYS check — silent failure otherwise
  return s;
}
const program = gl.createProgram();
gl.attachShader(program, compile(gl, gl.VERTEX_SHADER, vsSource));
gl.attachShader(program, compile(gl, gl.FRAGMENT_SHADER, fsSource));
gl.linkProgram(program);
if (!gl.getProgramParameter(program, gl.LINK_STATUS))
  throw new Error(gl.getProgramInfoLog(program));
```

### 3. Buffers + VAO (vertex data)
```javascript
const positions = new Float32Array([ -0.8,-0.8, 0.8,-0.8, 0.0,0.8 ]); // 3 verts, vec2
const vao = gl.createVertexArray();          // WebGL2: bundles attribute state
gl.bindVertexArray(vao);

const posBuf = gl.createBuffer();
gl.bindBuffer(gl.ARRAY_BUFFER, posBuf);
gl.bufferData(gl.ARRAY_BUFFER, positions, gl.STATIC_DRAW);

const aPos = gl.getAttribLocation(program, 'aPosition');
gl.enableVertexAttribArray(aPos);
gl.vertexAttribPointer(aPos, /*size*/2, gl.FLOAT, /*normalize*/false, /*stride*/0, /*offset*/0);
gl.bindVertexArray(null);
```
Index buffers: `gl.ELEMENT_ARRAY_BUFFER` + `gl.drawElements`.

### 4. Uniforms
```javascript
const uTime = gl.getUniformLocation(program, 'uTime');
const uMVP  = gl.getUniformLocation(program, 'uMVP');
gl.useProgram(program);
gl.uniform1f(uTime, performance.now() / 1000);
gl.uniformMatrix4fv(uMVP, false, mvpMatrix);   // Float32Array(16), column-major
// families: uniform1f/2f/3f/4f, uniform1i (samplers), uniform{2,3,4}fv, uniformMatrix{2,3,4}fv
```

### 5. Render loop
```javascript
function frame(t) {
  gl.viewport(0, 0, canvas.width, canvas.height);
  gl.clearColor(0.06, 0.06, 0.09, 1);
  gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

  gl.useProgram(program);
  gl.uniform1f(uTime, t / 1000);
  gl.bindVertexArray(vao);
  gl.drawArrays(gl.TRIANGLES, 0, 3);           // (mode, first, count)

  requestAnimationFrame(frame);
}
requestAnimationFrame(frame);
```

### 6. Textures
```javascript
const tex = gl.createTexture();
gl.bindTexture(gl.TEXTURE_2D, tex);
gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, imageElement);
gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
gl.generateMipmap(gl.TEXTURE_2D);              // needs power-of-2 in WebGL1; free in WebGL2
// bind to unit 0 → sampler uniform:
gl.activeTexture(gl.TEXTURE0);
gl.bindTexture(gl.TEXTURE_2D, tex);
gl.uniform1i(gl.getUniformLocation(program, 'uTex'), 0);
```

## Capabilities / Output Types (WebGL2)
- **Instanced rendering** — `gl.drawArraysInstanced` + `gl.vertexAttribDivisor` (particles, foliage).
- **Transform feedback** — capture vertex-shader output into buffers (GPU particle sims without fragment work).
- **Multiple render targets (MRT)** — deferred shading / G-buffers via framebuffers with several color attachments.
- **Uniform Buffer Objects (UBO)** — share uniform blocks across programs.
- **3D & 2D-array textures**, integer textures, `texelFetch`.
- **Framebuffers / render-to-texture** — post-processing, shadow maps, ping-pong sims.

## How-To

### How to add colors & control appearance (mandatory styling recipe)
There is no material system — color is whatever the **fragment shader** writes to `fragColor`. Drive it with per-vertex colors, uniforms, or computed values.
```javascript
// Fragment shader gradient tinted by a uniform color and UV
const fs = `#version 300 es
precision highp float;
in vec2 vUv;                     // 0..1 across the surface
out vec4 fragColor;
uniform vec3 uTint;
void main() {
  vec3 base = mix(vec3(0.1,0.2,0.6), vec3(1.0,0.4,0.2), vUv.x); // horizontal gradient
  fragColor = vec4(base * uTint, 1.0);
}`;
// JS: gl.uniform3f(gl.getUniformLocation(program,'uTint'), 1.0, 0.9, 0.8);
```
For "lit" color you compute lighting in-shader: `float diff = max(dot(normal, lightDir), 0.0); fragColor = vec4(albedo * diff + ambient, 1.0);`. Enable blending for transparency: `gl.enable(gl.BLEND); gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);`.

### How to enable depth testing for real 3D
```javascript
gl.enable(gl.DEPTH_TEST);
gl.enable(gl.CULL_FACE);        // skip back faces
gl.cullFace(gl.BACK);
```
Without `DEPTH_TEST`, triangles draw in submission order and near/far ordering is wrong.

### How to draw 10,000 instances (WebGL2 instancing)
```javascript
const offsets = new Float32Array(10000 * 2);   // per-instance xy
// ...fill offsets...
const offBuf = gl.createBuffer();
gl.bindBuffer(gl.ARRAY_BUFFER, offBuf);
gl.bufferData(gl.ARRAY_BUFFER, offsets, gl.STATIC_DRAW);
const aOff = gl.getAttribLocation(program, 'aOffset');
gl.enableVertexAttribArray(aOff);
gl.vertexAttribPointer(aOff, 2, gl.FLOAT, false, 0, 0);
gl.vertexAttribDivisor(aOff, 1);               // advance once per instance
gl.drawArraysInstanced(gl.TRIANGLES, 0, 3, 10000);  // ONE call
```

### How to render to a texture (post-processing base)
```javascript
const fbo = gl.createFramebuffer();
gl.bindFramebuffer(gl.FRAMEBUFFER, fbo);
gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, colorTex, 0);
// draw scene here → colorTex; then bind default framebuffer (null) and draw a fullscreen
// quad sampling colorTex through a post-process shader.
```

## Do's and Don'ts

### ✅ Do
- Always check `COMPILE_STATUS`/`LINK_STATUS` and log `getShaderInfoLog` — WebGL fails silently otherwise.
- Declare `precision highp float;` (or mediump) at the top of every fragment shader.
- Use VAOs (WebGL2) to bundle attribute state — bind one VAO per object.
- Cache attribute/uniform locations once, not per frame.
- Minimize state changes and draw calls; batch and instance.
- Call `gl.viewport()` on resize and set canvas `width/height` (backing store), not just CSS size.

### ❌ Don't
- Don't create buffers/programs/textures inside the render loop — they leak GPU memory.
- Don't forget `gl.enable(gl.DEPTH_TEST)` for 3D — you'll get z-ordering artifacts.
- Don't assume WebGL1 GLSL works in WebGL2 — `#version 300 es` changes `attribute`→`in`, `varying`→`in/out`, `gl_FragColor`→named output.
- Don't ignore context loss — GPUs can drop the context; handle `webglcontextlost`/`restored`.
- Don't upload non-power-of-2 textures with mipmaps/repeat in WebGL1 (fine in WebGL2).

## Styling, Theming & Customization
All appearance is shader-authored:
- **Vertex colors**: interpolated `in`/`out` varyings.
- **Uniform-driven palettes**: pass colors/time/resolution as uniforms.
- **Textures**: sample albedo/normal/data maps.
- **Blending & alpha**: `gl.blendFunc` modes for additive/premultiplied compositing.
- **Tone mapping / gamma**: apply in the fragment shader (`pow(color, vec3(1.0/2.2))`) since there's no built-in color management.

## Advanced Features
- **Transform feedback** GPU particle systems (no CPU readback).
- **Compute-like GPGPU** via ping-pong framebuffers and data textures (WebGL2 has no true compute; WebGPU does).
- **Deferred rendering** with MRT G-buffers.
- **Extensions**: `EXT_color_buffer_float`, `OES_texture_float_linear`, `WEBGL_debug_shaders` — query with `gl.getExtension`.
- **WebGL2 → WebGPU** migration path when you need real compute shaders.

## Common Pitfalls & Troubleshooting
- **Blank canvas** — shader compile/link error swallowed (check logs), wrong `precision`, or nothing drawn (no `drawArrays`/wrong count).
- **Everything black** — attribute location `-1` (name mismatch/optimized out), or uniform not set.
- **Z-fighting / wrong overlap** — depth test disabled or bad near/far in projection matrix.
- **Distorted image** — canvas backing store size (`canvas.width`) ≠ CSS size, or missing `gl.viewport()` after resize.
- **Texture is black** — not bound to the active unit, sampler uniform not set to the unit index, or non-power-of-2 in WebGL1.
- **Context lost** — GPU reset/tab backgrounded; must recreate all GL resources on restore.

## Integration Notes
- Pair with `gl-matrix` (or `wgpu-matrix`) for matrix math; there's no built-in linear algebra.
- Frameworks (three.js, PlayCanvas, PixiJS, regl, twgl.js) wrap this API — `twgl.js`/`regl` are thin helpers if raw WebGL is too verbose.
- For heavy compute or modern pipelines, consider WebGPU (`navigator.gpu`).

## Best For / Avoid For
`custom-shaders`, `shader-art`, `gpgpu`, `minimal-footprint-effects`, `learning-graphics` — choose raw WebGL when you need a bespoke pipeline, smallest possible payload, or full shader control.
Avoid for: ordinary 3D apps (three.js/R3F/PlayCanvas do the boilerplate), 2D UI, or teams without GLSL/graphics experience.

## See Also
- `three_js.md` — the scene-graph library built on this API
- `react-three-fiber.md`, `playcanvas.md` — higher-level engines over WebGL
- `p5_js.md` — creative-coding WEBGL mode with a gentle API
- `../use-case/3d-graphics.md` — 3D solution selection
