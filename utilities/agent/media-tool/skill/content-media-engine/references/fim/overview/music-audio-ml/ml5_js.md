# ml5.js

## What
ml5.js is a friendly machine-learning library for web-based creative coding, wrapping pre-trained models behind a simple API. It produces ML inference results (classifications, pose/hand/face landmarks, style-transferred images) that are typically drawn to a canvas. Its primary consumer is browser JavaScript, and it is designed to work alongside p5.js.

## How
- **LLM emits:** ml5.js JavaScript (usually in p5.js `preload`/`setup`/`draw` structure) — e.g. `ml5.imageClassifier('MobileNet')`, `ml5.poseNet(video, cb)`, `ml5.handpose(video, cb)`, or `ml5.styleTransfer('udnie', cb)`, with result callbacks.
- **Execute step:** load ml5 via CDN (`ml5.min.js`) together with p5.js; instantiate a model, then call its method (`classifier.classify(img, gotResult)`) or subscribe to events (`poseNet.on('pose', ...)`). Results arrive in callbacks (label/confidence, keypoints, landmarks) and are drawn with p5 primitives.
- **Final artifact:** an interactive canvas visualization driven by live model output — e.g. pose skeletons over webcam video, classification labels, hand/face landmarks, or a style-transferred image. The artifact is typically visual/interactive rather than a static file.

## Why
- **Reach for it when:** you want approachable, pre-trained ML inside creative-coding sketches without training models — image classification, pose detection (PoseNet), hand tracking (handpose), face landmarks (facemesh), style transfer, and sound classification, all wired to interactive visuals.
- **Limitations:** the source doc lists core features and available models but does not enumerate explicit limitations (see note below); in practice it depends on p5.js and pre-trained models and runs inference client-side in the browser.
- **Relative to siblings:** ml5.js is the ML/creative-coding outlier in this category — not notation or audio-synthesis, but a bridge from pre-trained models into interactive p5.js visuals. It complements rather than competes with the music/audio tools here.

## Source
- Solution reference: `fim/solution/ml5_js.md`
