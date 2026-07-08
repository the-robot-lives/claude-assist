# ml5.js — friendly machine learning for creative coding

ml5.js wraps TensorFlow.js in an approachable, p5.js-friendly API so artists and beginners can use pre-trained models — image classification, body/hand/face tracking, sound classification, and simple custom neural networks — without ML expertise. It's designed to sit alongside p5.js (video capture, canvas drawing) and turn model output into visuals and interactions.

> **Version note.** ml5 **1.0+** reorganized the API: model names and callbacks changed. Pose tracking moved from `poseNet` to **`bodyPose`** (MoveNet/BlazePose); hand/face use **`handPose`**/**`faceMesh`** (MediaPipe); callbacks are now **`(result)`** with errors thrown/rejected, not the old **`(error, result)`** node-style. Older tutorials (poseNet, `styleTransfer`) target ml5 0.x. This doc covers 1.0 patterns and flags the legacy forms.

**Current Version**: 1.x (CDN `ml5@1`) **License**: MIT **Bundle/Runtime**: loads TF.js + model weights on demand (network-dependent); runs in-browser (WebGL/WASM backends).

## Official Resources & Documentation
- **Site**: https://ml5js.org/
- **Reference (1.0)**: https://docs.ml5js.org/
- **Repo**: https://github.com/ml5js/ml5-next-gen
- **Examples**: https://github.com/ml5js/ml5-next-gen/tree/main/examples
- **Pairs with p5.js**: https://p5js.org/

## Installation & Setup

### CDN (with p5.js)
```html
<script src="https://cdn.jsdelivr.net/npm/p5@1.9.0/lib/p5.min.js"></script>
<script src="https://unpkg.com/ml5@1/dist/ml5.min.js"></script>
```
Most ml5 models load asynchronously and often need a **local/https server** (webcam + model fetch); `file://` won't grant camera access.

## Core Syntax / API Reference

### The universal pattern
1. create a model (optionally with a ready callback), 2. run it on an image/video, 3. draw the results.
```javascript
// ml5 1.0: promise/ready callback + (result) callbacks
let classifier;
function preload() { classifier = ml5.imageClassifier('MobileNet'); }  // preload blocks until ready
function setup() {
  createCanvas(400, 400);
  classifier.classify(img, gotResult);
}
function gotResult(results) {           // 1.0: single arg; errors throw
  // results[0].label, results[0].confidence
  console.log(results[0].label, results[0].confidence);
}
```
Legacy 0.x used `gotResult(error, results)` — update to the single-arg form for 1.0.

### Image classification
```javascript
const classifier = ml5.imageClassifier('MobileNet', () => console.log('ready'));
classifier.classify(imgOrVideo, (results) => { /* [{label, confidence}, ...] */ });
```

### Body pose tracking (1.0: `bodyPose`, replaces `poseNet`)
```javascript
let bodyPose, video, poses = [];
function preload() { bodyPose = ml5.bodyPose('MoveNet'); }   // 'MoveNet' | 'BlazePose'
function setup() {
  createCanvas(640, 480);
  video = createCapture(VIDEO); video.size(640, 480); video.hide();
  bodyPose.detectStart(video, (results) => poses = results);  // continuous detection
}
function draw() {
  image(video, 0, 0);
  for (const pose of poses)
    for (const kp of pose.keypoints)
      if (kp.confidence > 0.2) { fill(255,0,0); noStroke(); circle(kp.x, kp.y, 10); }
}
```

### Hand tracking (`handPose`) & face mesh (`faceMesh`)
```javascript
let handPose, hands = [];
function preload() { handPose = ml5.handPose(); }
function setup() { /* video */ handPose.detectStart(video, (r) => hands = r); }
function draw() {
  for (const hand of hands)
    for (const kp of hand.keypoints) { fill(0,255,0); noStroke(); circle(kp.x, kp.y, 8); }
}
// faceMesh is analogous: ml5.faceMesh(), detectStart → 468 face landmarks
```

### Sound & custom models
```javascript
const sound = ml5.soundClassifier('SpeechCommands18w', () => {});
sound.classifyStart((results) => console.log(results[0].label));

// tiny trainable neural net:
const nn = ml5.neuralNetwork({ inputs: 2, outputs: 1, task: 'regression' });
nn.addData([x, y], [target]);
nn.normalizeData();
nn.train({ epochs: 50 }, () => nn.predict([a, b], (res) => {}));
```

## Available Models / Output Types
- **imageClassifier** (MobileNet, Darknet, custom Teachable Machine models).
- **bodyPose** (MoveNet, BlazePose) — skeleton keypoints.
- **handPose** — 21 hand landmarks (MediaPipe).
- **faceMesh** — 468 face landmarks.
- **bodySegmentation** — person/background masks.
- **soundClassifier** — audio commands.
- **neuralNetwork** — train small custom models in-browser.
- **sentiment**, **word2vec** — text models.
- (Legacy 0.x extras like `styleTransfer`, `poseNet`, `pix2pix`, `charRNN` are deprecated/removed in 1.0.)

### Model quick-reference (ml5 1.0)
| Model | Input | Output | Notes |
|---|---|---|---|
| `imageClassifier` | image/video | `[{label, confidence}]` | MobileNet, Darknet, or Teachable Machine URL |
| `bodyPose` | video | keypoints (17 MoveNet / 33 BlazePose) | replaces old `poseNet` |
| `handPose` | video | 21 landmarks/hand | MediaPipe Hands |
| `faceMesh` | video/image | 468 face landmarks | MediaPipe FaceMesh |
| `bodySegmentation` | video | mask image | person/background separation |
| `soundClassifier` | mic | `[{label, confidence}]` | SpeechCommands18w |
| `neuralNetwork` | your data | classification/regression | trainable in-browser, save/load |
| `sentiment` | text | score 0–1 | movie-review model |

## How-To

### How to turn model output into generative visuals (mandatory styling recipe)
ml5 gives you coordinates/labels; you draw them with p5.js. "Styling" = mapping confidence/position to color, size, and stroke. Use HSB color mode and map keypoint data to hue/size.
```javascript
function setup() { createCanvas(640, 480); colorMode(HSB, 360, 100, 100, 100); /* + bodyPose */ }
function draw() {
  background(230, 30, 8, 12);              // trails
  for (const pose of poses) {
    const nose = pose.keypoints.find(k => k.name === 'nose');
    const wrist = pose.keypoints.find(k => k.name === 'left_wrist');
    if (nose?.confidence > 0.3 && wrist?.confidence > 0.3) {
      const hue = map(dist(nose.x, nose.y, wrist.x, wrist.y), 0, 400, 180, 360);
      stroke(hue, 90, 95, 80); strokeWeight(map(wrist.confidence, 0, 1, 1, 8));
      line(nose.x, nose.y, wrist.x, wrist.y);   // draw between joints
    }
  }
}
```
Drive color by confidence, distance, or label; size by score. All rendering is p5.js — see `p5_js.md` for the full color/style surface.

### How to trigger effects on classification
```javascript
function classifyLoop() {
  classifier.classify(video, (results) => {
    if (results[0].confidence > 0.7) triggerEffect(results[0].label);
    classifyLoop();                 // re-run (or use detectStart for detection models)
  });
}
```

### How to run continuous detection
```javascript
handPose.detectStart(video, (results) => hands = results);  // starts a loop
// handPose.detectStop();  // stop when done
```

### How to train a tiny custom classifier in-browser
```javascript
const nn = ml5.neuralNetwork({ task: 'classification', debug: true });
// 1) collect labeled data (e.g. from mouse position → a label)
nn.addData({ x: 120, y: 80 }, { label: 'A' });
nn.addData({ x: 300, y: 220 }, { label: 'B' });
// ...more samples...
// 2) normalize + train
nn.normalizeData();
nn.train({ epochs: 32 }, () => {
  // 3) predict
  nn.classify({ x: mouseX, y: mouseY }, (results) => {
    console.log(results[0].label, results[0].confidence);
  });
});
// Save/load a trained model:
nn.save('model');            // downloads model.json + weights
// nn.load(files, () => {});  // reload later
```

### How to remove/replace the background (bodySegmentation)
```javascript
let seg, video, mask;
function preload() { seg = ml5.bodySegmentation('SelfieSegmentation'); }
function setup() { /* video */ seg.detectStart(video, (r) => mask = r.mask); }
function draw() {
  image(video, 0, 0);
  if (mask) { tint(255, 180); image(mask, 0, 0); }  // composite person over a custom bg
}
```

## Do's and Don'ts

### ✅ Do
- Load models in `preload()` (or wait for the ready callback) before running inference.
- Use `detectStart`/`classifyStart` for continuous video models (1.0) instead of manual re-call loops.
- Serve over `https`/localhost so the webcam and model fetch work.
- Check `keypoint.confidence` before drawing to avoid jitter/ghost points.
- Pair with p5.js for capture (`createCapture(VIDEO)`) and drawing.

### ❌ Don't
- Don't use the old `(error, result)` callback signature with ml5 1.0 — it's `(result)` now.
- Don't reference removed 0.x models (`poseNet`, `styleTransfer`) on 1.0 — use `bodyPose`/alternatives.
- Don't run inference before the model is ready — you'll get errors/empty results.
- Don't expect real-time speed on low-end mobile with heavy models — throttle detection or downscale video.
- Don't assume `file://` works — camera/model loading needs a server.

## Styling, Theming & Customization
All visual styling is p5.js: `fill`/`stroke`/`colorMode(HSB)`, `strokeWeight`, `blendMode`, trails via low-alpha `background()`. ml5 only supplies data (labels, keypoints, masks); map that data to visual parameters. `bodySegmentation` masks can tint/replace backgrounds.

## Advanced Features
- **Custom `neuralNetwork`** — collect data, train, predict/classify in-browser; save/load models.
- **Teachable Machine** models load via `imageClassifier(modelURL)`.
- **bodySegmentation** for background removal / silhouette art.
- **Transfer learning / feature extraction** for small custom classifiers.
- **TF.js backends** (WebGL/WASM) under the hood — tune for perf.

## Common Pitfalls & Troubleshooting
- **Nothing detected / errors** — model not ready, wrong 1.0 model name, or old callback signature.
- **Webcam black / permission denied** — not on https/localhost, or `video.hide()`/size not set.
- **Laggy** — heavy model on weak hardware; downscale video, throttle, or pick a lighter model (MoveNet Lightning).
- **Jittery keypoints** — draw only above a confidence threshold; smooth with a low-pass filter.
- **Results empty** — ran inference before `preload`/ready resolved.
- **CORS on custom model** — host model files with proper headers.

## Integration Notes
- Designed around p5.js; works standalone with plain `<video>`/`<img>` too.
- In bundlers/React, load ml5 + TF.js, run in effects, and stop detection loops on unmount.
- For production-grade ML, drop to TensorFlow.js directly; ml5 optimizes for learnability, not control.

## Best For / Avoid For
`interactive-installations`, `body-tracking-art`, `gesture-interfaces`, `ml-education`, `webcam-creative-coding` — choose ml5.js to add ML to creative-coding projects with minimal setup.
Avoid for: production ML pipelines, custom architectures/large models (use TF.js/ONNX Runtime), or offline/no-network contexts (models fetch on demand).

## See Also
- `p5_js.md` — the drawing/capture layer ml5 pairs with
- `processing_js.md` — creative-coding lineage
- `pts_js.md` — geometry-driven creative coding
- `../use-case/creative-animation.md` — creative solution selection
