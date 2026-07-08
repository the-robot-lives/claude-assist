# p5.js — creative coding for interactive graphics

p5.js is the modern JavaScript successor to Processing: a friendly, immediate-mode drawing library for generative art, data art, interactive installations, and teaching. You write two functions — `setup()` (runs once) and `draw()` (loops ~60fps) — and call drawing primitives (`ellipse`, `rect`, `line`, `vertex`) against a `<canvas>`. It has 2D and WEBGL (3D) modes, built-in input (`mouseX`, `keyPressed`), sound/video add-ons, and Perlin noise for organic motion.

**Current Version**: 1.9.x (stable) / 2.x (newer line); CDN `p5@1.9.0` (current major) **License**: LGPL-2.1 **Bundle/Runtime**: ~900 KB min (~250 KB gz); draws to a 2D or WebGL canvas.

## Official Resources & Documentation
- **Reference** (the map you need): https://p5js.org/reference/
- **Examples**: https://p5js.org/examples/
- **Web editor** (zero-setup): https://editor.p5js.org/
- **Learn / tutorials**: https://p5js.org/learn/
- **Repo**: https://github.com/processing/p5.js
- **Add-on libraries**: p5.sound, p5.dom (core), community: p5.play, p5.gui, ml5.js

## Installation & Setup

### CDN (most common)
```html
<script src="https://cdn.jsdelivr.net/npm/p5@1.9.0/lib/p5.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/p5@1.9.0/lib/addons/p5.sound.min.js"></script>
<script src="sketch.js"></script>
```

### Package manager
```bash
npm install p5
```

### Global vs instance mode
```javascript
// GLOBAL mode: setup/draw/ellipse are on window — simplest, one sketch per page.
function setup() { createCanvas(400, 400); }
function draw()  { background(220); ellipse(mouseX, mouseY, 50); }

// INSTANCE mode: namespaced — multiple sketches / bundler / module-safe.
const sketch = (p) => {
  p.setup = () => p.createCanvas(400, 400);
  p.draw  = () => { p.background(220); p.ellipse(p.mouseX, p.mouseY, 50); };
};
new p5(sketch, document.getElementById('holder'));
```

## Core Syntax / API Reference

### Lifecycle functions
```javascript
function preload() {}   // load assets before setup (loadImage/loadSound/loadJSON block here)
function setup()   {}   // once: createCanvas, set modes, init state
function draw()    {}   // ~60fps loop; the animation heartbeat
// Input callbacks:
function mousePressed() {} function mouseReleased() {} function mouseDragged() {}
function keyPressed() {}   function keyReleased() {}  function windowResized() {}
function doubleClicked() {} function mouseWheel(event) {}
```

### Canvas & environment
```javascript
createCanvas(w, h);                 // 2D (P2D) by default
createCanvas(w, h, WEBGL);          // 3D mode
resizeCanvas(w, h);
frameRate(30); noLoop(); loop(); redraw();
// Globals: width, height, frameCount, mouseX/mouseY, pmouseX/pmouseY, deltaTime, windowWidth
```

### 2D primitives
```javascript
point(x, y);
line(x1, y1, x2, y2);
rect(x, y, w, h, [r]);          // rounded corner radius optional
square(x, y, s);
ellipse(x, y, w, h);  circle(x, y, d);
arc(x, y, w, h, start, stop, [mode]);   // angles in radians (default)
triangle(x1,y1, x2,y2, x3,y3);
quad(x1,y1, x2,y2, x3,y3, x4,y4);
beginShape(); vertex(x, y); curveVertex(); bezierVertex(); endShape(CLOSE);
```

### Color & style
```javascript
background(220);                 // grayscale
background(255, 0, 0);           // RGB
fill(255, 128, 0);  noFill();
stroke(0, 100);  noStroke();     // 4th arg = alpha (0–255 in RGB mode)
strokeWeight(4);
colorMode(RGB, 255);             // default
colorMode(HSB, 360, 100, 100);   // hue/sat/brightness — great for generative palettes
const c = color('#4f8cff');      // also 'rgba(...)', 'tomato', color(h,s,b)
```

### Transforms (2D)
```javascript
push();                          // save style + transform matrix
translate(width/2, height/2);
rotate(PI / 4);                  // radians (unless angleMode(DEGREES))
scale(1.5);
shearX(0.2);
// ...draw relative to the new origin...
pop();                           // restore
```

### WEBGL / 3D mode
```javascript
function setup() { createCanvas(600, 400, WEBGL); }
function draw() {
  background(20);
  orbitControl();                // drag to rotate the camera
  ambientLight(80);
  directionalLight(255, 255, 255, 0.5, 1, -0.5);
  pointLight(255, 200, 150, 0, -200, 200);
  rotateX(frameCount * 0.01); rotateY(frameCount * 0.01);
  normalMaterial();              // or ambientMaterial(color), specularMaterial(), texture(img)
  box(150);                      // sphere, cylinder, cone, torus, plane, ellipsoid, model()
}
```
In WEBGL the origin `(0,0)` is the **center** of the canvas (not top-left) and +y is down. Lights are required for `ambientMaterial`/`specularMaterial` to show.

### Math & motion helpers
```javascript
noise(x, [y], [z]);              // Perlin noise 0..1 — smooth organic randomness
random(min, max); randomSeed(n); noiseSeed(n);
map(v, inMin, inMax, outMin, outMax);   // remap ranges (essential for data→pixels)
constrain(v, lo, hi); lerp(a, b, t); dist(x1,y1,x2,y2);
sin(a); cos(a); radians(deg); degrees(rad); TWO_PI; PI;
createVector(x, y, [z]);         // p5.Vector: add/mult/mag/normalize/heading
```

### Media & data
```javascript
let img; function preload(){ img = loadImage('pic.jpg'); }
image(img, x, y, [w, h]);  tint(255, 128);  filter(BLUR, 3);
let data; function preload(){ data = loadJSON('data.json'); }  // also loadStrings, loadTable
saveCanvas('art', 'png');  saveGif('loop', 5);   // export
```

## Output / Supported Modes
- **P2D (2D canvas)** — default; shapes, images, text, pixels.
- **WEBGL** — 3D primitives, custom `createShader()` GLSL, camera, lights, textures, `loadModel()` (OBJ/STL).
- **Pixel manipulation** — `loadPixels()`, `pixels[]`, `updatePixels()`, `get()/set()`.
- **Off-screen buffers** — `createGraphics(w,h)` for layered/cached rendering.
- **Exports** — PNG/JPG frames, animated GIF, and (via add-ons) SVG.

## How-To

### How to add colors & palettes (mandatory styling recipe)
Color is set with `fill()`/`stroke()`/`background()`; switch to HSB mode for smooth, controllable generative palettes and use alpha for layering/trails.
```javascript
function setup() {
  createCanvas(600, 600);
  colorMode(HSB, 360, 100, 100, 100);   // H,S,B, and alpha all in friendly ranges
  noStroke();
}
function draw() {
  background(230, 20, 12, 8);            // low-alpha bg = motion trails
  const hue = (frameCount * 0.5) % 360;
  fill(hue, 80, 95, 90);                 // cycling hue
  const r = map(sin(frameCount * 0.02), -1, 1, 40, 200);
  circle(width/2 + cos(frameCount*0.03)*150, height/2 + sin(frameCount*0.03)*150, r);
}
```
Tips: build palettes as arrays of `color()` and index by data; use `lerpColor(a, b, t)` for gradients; a translucent `background()` each frame creates ghosting/trail aesthetics.

### How to animate with noise (organic motion)
```javascript
let t = 0;
function draw() {
  background(20, 30);
  stroke(255);
  for (let x = 0; x < width; x += 8) {
    const y = height/2 + (noise(x * 0.01, t) - 0.5) * 300;  // flowing line
    point(x, y);
  }
  t += 0.01;
}
```

### How to make it interactive
```javascript
function draw() {
  if (mouseIsPressed) fill(0); else fill(255);
  ellipse(mouseX, mouseY, 40);
}
function keyPressed() { if (key === 's') saveCanvas('frame', 'png'); }
```

### How to build a particle system
```javascript
let particles = [];
function setup() { createCanvas(600, 600); }
function draw() {
  background(0, 20);
  particles.push({ pos: createVector(mouseX, mouseY),
                   vel: p5.Vector.random2D().mult(random(1, 3)) });
  particles = particles.filter(p => (p.pos.add(p.vel), p.pos.x > 0 && p.pos.x < width));
  noStroke(); fill(255, 150);
  particles.forEach(p => circle(p.pos.x, p.pos.y, 4));
}
```

### How to keep the canvas full-window & responsive
```javascript
function setup() { createCanvas(windowWidth, windowHeight); }
function windowResized() { resizeCanvas(windowWidth, windowHeight); }
```

## Do's and Don'ts

### ✅ Do
- Load assets in `preload()` so they're ready before `setup()`/`draw()`.
- Use `push()`/`pop()` around transforms so state doesn't leak into later draws.
- Use `map()` to scale data/inputs into pixel/color ranges.
- Use HSB `colorMode` for generative palettes; use low-alpha `background()` for trails.
- Use instance mode when bundling or running multiple sketches on a page.

### ❌ Don't
- Don't `loadImage`/`loadJSON` in `draw()` — load once in `preload`/`setup`.
- Don't forget angles are **radians** by default (`rotate(PI/2)`), unless you call `angleMode(DEGREES)`.
- Don't assume `(0,0)` is top-left in WEBGL — it's the center.
- Don't allocate large arrays/objects every frame without pruning — memory and GC will stutter the loop.
- Don't rely on p5 for big-data charts — it's immediate-mode art, not a charting library.

## Styling, Theming & Customization
- **Color modes**: `colorMode(RGB|HSB, ...ranges)`; `lerpColor`, `hue()/saturation()/brightness()`.
- **Blend modes**: `blendMode(ADD|MULTIPLY|SCREEN|DIFFERENCE|...)` for compositing.
- **Text**: `textFont(loadFont('font.ttf'))`, `textSize`, `textAlign`, `textLeading`.
- **Filters**: `filter(BLUR|GRAY|INVERT|POSTERIZE|THRESHOLD|DILATE|ERODE)`.
- **Shaders** (WEBGL): `createShader(vert, frag)` + `shader()` for custom GLSL fragment effects.
- **Layers**: `createGraphics()` off-screen buffers for reusable/cached elements.

## Advanced Features
- **Custom GLSL shaders** in WEBGL mode (full-screen fragment art, feedback).
- **3D models**: `loadModel('mesh.obj')` + `model()`.
- **Sound** (p5.sound): oscillators, FFT/amplitude analysis for audio-reactive visuals.
- **Video / webcam**: `createCapture(VIDEO)` (pairs with ml5.js for ML).
- **GIF/animation export**: `saveGif()`.
- **DOM**: `createButton`, `createSlider`, `select()` for quick GUIs.

## Common Pitfalls & Troubleshooting
- **Blank canvas** — no `background()`, canvas not created, or an error in `draw` (check console).
- **Asset undefined** — loaded outside `preload()`; the `image()`/`sound` runs before it's ready.
- **Rotation wrong** — passing degrees where radians expected.
- **Sketch stutters over time** — unbounded arrays/particles; prune them.
- **3D object off-screen/black** — WEBGL origin is center; add lights for material shading.
- **Multiple sketches conflict** — global mode collisions; switch to instance mode.
- **Cross-origin image errors** — serve assets over http(s) with CORS.

## Integration Notes
- **ml5.js** builds on p5 for friendly ML (see `ml5_js.md`).
- **Bundlers/React**: use instance mode; mount in a `useEffect` and clean up with `p5Instance.remove()`.
- **Processing.js migration**: p5.js is the recommended modern replacement (see `processing_js.md`).

## Best For / Avoid For
`generative-art`, `creative-coding`, `data-art`, `interactive-installations`, `education`, `audio-reactive-visuals` — choose p5.js for expressive, immediate-mode graphics and teaching.
Avoid for: production dashboards/charts (use a charting lib), high-poly 3D (three.js), or large-dataset rendering (immediate mode isn't optimized for it).

## See Also
- `processing_js.md` — the predecessor p5.js modernizes
- `ml5_js.md` — machine learning that pairs with p5
- `pts_js.md`, `two_js.md` — other creative-coding/drawing libraries
- `webgl.md`, `three_js.md` — lower-level 3D when p5 WEBGL isn't enough
- `../use-case/creative-animation.md` — creative-coding solution selection
