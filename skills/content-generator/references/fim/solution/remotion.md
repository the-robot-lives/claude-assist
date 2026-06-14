# Remotion - FIM Solution Documentation

## Description
[Remotion](https://remotion.dev) renders videos programmatically with React. Frames are React components parameterized by the current frame number, then encoded to MP4/WebM/GIF via a headless-Chromium renderer. It turns article content and data into shareable motion graphics — explainer clips, animated social promos, and data-driven videos.

## Basic Syntax
```jsx
import { useCurrentFrame, interpolate, AbsoluteFill } from 'remotion'

export const TitleCard = () => {
  const frame = useCurrentFrame()
  const opacity = interpolate(frame, [0, 30], [0, 1], { extrapolateRight: 'clamp' })
  return (
    <AbsoluteFill style={{ background: '#0b0b0b', justifyContent: 'center',
      alignItems: 'center' }}>
      <h1 style={{ color: '#fff', fontSize: 90, opacity }}>Rate Limiting 101</h1>
    </AbsoluteFill>
  )
}
// Render: npx remotion render src/index.ts TitleCard out/video.mp4
```

## Toolchain
- **@remotion/cli** - `remotion render` / `remotion studio` preview
- **Remotion Player** - Embed interactive preview in a web app
- **@remotion/lambda** - Scalable cloud rendering
- **Compositions** - Declare dimensions, fps, duration per video
- **Audio/captions** - `@remotion/captions`, audio tracks, transitions

## Strengths
- Author video with familiar React + CSS/SVG/Canvas
- Fully data-driven and parameterizable (props -> video variants)
- Deterministic, version-controlled video source
- Scales via Lambda for batch/personalized renders
- Embeddable live player for previews

## Limitations
- Node + Chromium render pipeline (heavy CI footprint)
- Rendering is CPU/GPU intensive and time-consuming
- Steeper setup than recording a screen
- Audio sync and long videos need care

## Best Use Cases
- Animated social promos for articles/launches
- Data-driven explainer videos from metrics
- Personalized/templated video at scale (Lambda)
- Reusable intro/outro and motion-graphic components

## NPL-FIM Integration
```npl
⌜remotion-video|remotion|FIM@1.0⌝
format: mp4 | webm | gif
runtime: react + chromium
render: remotion-cli | remotion-lambda
inputs: [title, data, audio]
output: motion-graphic-video
⌞remotion-video⌟
```

NPL agents use Remotion when content must become a programmatic, data-driven video — social promos or explainers rendered from React compositions.
