# Processing.js — Processing language in the browser (legacy)

Processing.js is a JavaScript port of the Processing creative-coding language: it ran classic Processing (`.pde`) sketches — written in Processing's Java-like syntax — directly on an HTML5 `<canvas>`, and also accepted equivalent JavaScript. It brought the Processing pedagogy (`setup()`/`draw()`, immediate-mode drawing, `PVector`, `noise()`) to the web before native JS creative-coding matured.

> **Status — read first.** Processing.js is **retired / end-of-life** (development stopped ~2018). For any new work, use **p5.js** — the official, actively maintained JavaScript home for Processing-style creative coding. This file documents Processing.js for legacy/compat context and shows the p5.js equivalents you should actually write. See `p5_js.md`.

**Last Version**: 1.6.6 (unmaintained) **License**: MIT **Bundle/Runtime**: ~500 KB; parses `.pde`/Processing syntax and renders to Canvas 2D (limited 3D).

## Official Resources & Documentation
- **Processing.js (archived)**: http://processingjs.org/ (project retired)
- **Processing (desktop, Java)**: https://processing.org/
- **p5.js (the modern successor — use this)**: https://p5js.org/
- **p5.js reference**: https://p5js.org/reference/
- **Migration note**: https://github.com/processing/p5.js/wiki

## Installation & Setup

### Legacy Processing.js (compat only)
```html
<script src="https://cdnjs.cloudflare.com/ajax/libs/processing.js/1.6.6/processing.min.js"></script>
<!-- Sketch in a data-processing-sources attribute or inline: -->
<canvas data-processing-sources="sketch.pde"></canvas>
```

### Recommended: p5.js (modern replacement)
```html
<script src="https://cdn.jsdelivr.net/npm/p5@1.9.0/lib/p5.min.js"></script>
<script src="sketch.js"></script>
```
```bash
npm install p5   # for bundled/module projects
```

## Core Syntax / API Reference

### The lifecycle (identical concept in both)
```javascript
// Processing.js — Processing (Java-like) syntax in a .pde file
void setup() {
  size(640, 480);
  background(255);
  frameRate(30);
}
void draw() {
  fill(random(255), random(255), random(255), 50);
  ellipse(mouseX, mouseY, 50, 50);
}
```
```javascript
// p5.js — the same sketch, modern JS (what you should write today)
function setup() {
  createCanvas(640, 480);
  background(255);
  frameRate(30);
}
function draw() {
  fill(random(255), random(255), random(255), 50);
  ellipse(mouseX, mouseY, 50, 50);
}
```
Key mapping: `size()` → `createCanvas()`; typed `void`/`int`/`float` declarations → untyped `let`; otherwise the drawing API is nearly one-to-one.

### Drawing primitives (shared vocabulary)
```javascript
point(x, y);  line(x1, y1, x2, y2);  rect(x, y, w, h);  ellipse(x, y, w, h);
triangle(...);  quad(...);  arc(x, y, w, h, start, stop);
beginShape(); vertex(x, y); endShape(CLOSE);
fill(r, g, b, [a]);  stroke(r, g, b);  noFill();  noStroke();  strokeWeight(n);
background(v);
```

### State, transforms, math
```javascript
push(); translate(width/2, height/2); rotate(radians(45)); scale(1.5); /* ... */ pop();
random(min, max);  noise(x, y);  map(v, a, b, c, d);  constrain(v, lo, hi);  dist(x1,y1,x2,y2);
// Vectors: Processing PVector → p5.Vector (createVector)
```

### 3D
```javascript
// Processing.js had partial P3D; p5.js uses WEBGL mode:
function setup() { createCanvas(640, 480, WEBGL); }
function draw() { background(200); rotateX(frameCount*0.01); rotateY(frameCount*0.01); box(200); }
```

## Output / Supported Modes
- **2D canvas** — full immediate-mode drawing (both libraries).
- **3D** — Processing.js: limited/experimental; p5.js: `WEBGL` mode (recommended).
- **Input** — `mouseX/mouseY`, `keyPressed`, `mousePressed`.
- **Pixels/images** — `loadImage`, `get`/`set`, pixel array.

## How-To

### How to add colors & palettes (mandatory styling recipe)
Color is `fill()`/`stroke()`/`background()`; both libraries support RGB and HSB modes. In p5.js switch to HSB for smooth generative palettes.
```javascript
// p5.js (recommended)
function setup() {
  createCanvas(600, 600);
  colorMode(HSB, 360, 100, 100, 100);   // hue, sat, brightness, alpha
  noStroke();
}
function draw() {
  background(230, 20, 10, 6);            // low-alpha bg = trails
  const hue = (frameCount * 0.6) % 360;
  fill(hue, 80, 95, 90);
  circle(width/2 + cos(frameCount*0.03)*150, height/2 + sin(frameCount*0.03)*150,
         map(sin(frameCount*0.02), -1, 1, 40, 180));
}
```
Processing.js equivalent uses the same calls with `colorMode(HSB)`; the difference is the surrounding syntax (typed vars, `.pde`).

### How to make a generative flow field
```javascript
// p5.js
let scl = 0.02;
function draw() {
  background(0, 12);
  stroke(255, 60);
  for (let x = 0; x < width; x += 6) {
    const n = noise(x * scl, millis() * 0.0001);
    line(x, height/2 + n*120, x, height/2 - n*120);
  }
}
```

### How to draw a radial mandala
```javascript
// p5.js
function mandala(segments) {
  push(); translate(width/2, height/2);
  for (let i = 0; i < segments; i++) { rotate(TWO_PI/segments); line(0,0,100,0); ellipse(100,0,20,20); }
  pop();
}
```

### How to migrate a `.pde` sketch to p5.js
1. `size(w,h)` → `createCanvas(w,h)`; add `WEBGL` for 3D.
2. Remove Java types: `int i` → `let i`, `float x` → `let x`, `void setup()` → `function setup()`.
3. `PVector` → `createVector` / `p5.Vector`.
4. Class syntax: Java classes → ES6 `class`.
5. Load assets in `preload()`.

### Processing.js → p5.js API mapping (quick reference)
| Processing.js (`.pde`) | p5.js (JS) |
|---|---|
| `void setup() {}` | `function setup() {}` |
| `void draw() {}` | `function draw() {}` |
| `size(w, h)` / `size(w,h,P3D)` | `createCanvas(w, h)` / `createCanvas(w,h,WEBGL)` |
| `int`/`float`/`boolean x` | `let x` |
| `PVector v = new PVector(x,y)` | `let v = createVector(x, y)` |
| `PImage img` + `loadImage()` | `let img` + `loadImage()` in `preload()` |
| `color(r,g,b)` | `color(r, g, b)` (same) |
| `class Ball {}` (Java) | `class Ball {}` (ES6) |
| `mousePressed()` (var) | `mouseIsPressed` (bool) / `mousePressed()` (event) |
| `println()` | `console.log()` / `print()` |

### How to draw a bouncing-particle network (p5.js)
```javascript
let particles = [];
function setup() {
  createCanvas(windowWidth, windowHeight);
  for (let i = 0; i < 100; i++)
    particles.push({ x: random(width), y: random(height), vx: random(-1,1), vy: random(-1,1) });
}
function draw() {
  background(0, 12);
  stroke(255, 50);
  for (const p of particles) {
    p.x += p.vx; p.y += p.vy;
    if (p.x < 0 || p.x > width) p.vx *= -1;
    if (p.y < 0 || p.y > height) p.vy *= -1;
    for (const o of particles) if (dist(p.x,p.y,o.x,o.y) < 100) line(p.x,p.y,o.x,o.y);
  }
}
```

## Do's and Don'ts

### ✅ Do
- **Prefer p5.js for anything new** — Processing.js is unmaintained.
- Keep the `setup()`/`draw()` mental model; it transfers directly.
- Use HSB `colorMode` + low-alpha backgrounds for generative palettes/trails.
- Load images/fonts in `preload()` (p5.js).
- Use `map()` to scale data/inputs into pixel/color ranges.

### ❌ Don't
- Don't start new projects on Processing.js — no updates, no security fixes, worse browser compat.
- Don't mix Java typing into p5.js JavaScript.
- Don't expect Processing.js 3D (P3D) to match modern WEBGL; migrate to p5.js WEBGL.
- Don't load assets in `draw()`.
- Don't assume `.pde` parsing performance matches native JS — Processing.js transpiles at runtime.

## Styling, Theming & Customization
- **Color modes**: `colorMode(RGB|HSB, ranges)`.
- **Blend modes** (p5.js): `blendMode(ADD|MULTIPLY|SCREEN|...)`.
- **Typography**: `textFont`, `textSize`, `textAlign`.
- **Filters** (p5.js): `filter(BLUR|GRAY|INVERT|POSTERIZE|THRESHOLD)`.
- **Shaders** (p5.js WEBGL): `createShader` for custom GLSL — not available in Processing.js.

## Advanced Features
- p5.js supersets Processing.js: WEBGL shaders, `p5.sound` (audio-reactive), webcam (`createCapture`), DOM helpers, `saveGif`, instance mode, and the ml5.js ML add-on.
- Processing.js advanced features (P3D, some Java interop) are legacy and not recommended.

## Common Pitfalls & Troubleshooting
- **Sketch won't run (Processing.js)** — retired library/browser incompat; port to p5.js.
- **Rotation wrong** — degrees vs radians; use `radians()` or `angleMode(DEGREES)` (p5.js).
- **Blank canvas** — no `background()`, or an error in `draw` (check console).
- **Assets undefined** — loaded outside `preload()`.
- **3D looks off** — Processing.js P3D limitations; migrate to p5.js WEBGL (origin is center).
- **Slow parsing** — Processing.js runtime transpilation of `.pde`; native p5.js JS avoids it.

## Integration Notes
- New integrations should target p5.js (instance mode for bundlers/React; mount in `useEffect`, `remove()` on cleanup).
- Existing `.pde` archives can be preserved via the desktop Processing app or migrated to p5.js.

## Best For / Avoid For
`legacy-processing-sketches`, `education-archives` — only choose Processing.js to keep old `.pde` content running.
For everything else — `generative-art`, `creative-coding`, `data-art`, `interactive-installations` — use **p5.js**.

## See Also
- `p5_js.md` — the modern, maintained successor (use this)
- `pts_js.md`, `two_js.md` — other creative-coding/drawing libraries
- `ml5_js.md` — ML that pairs with p5.js
- `../use-case/creative-animation.md` — creative solution selection
