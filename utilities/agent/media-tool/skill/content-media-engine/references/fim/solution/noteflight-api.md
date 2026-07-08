# Noteflight API — Embeddable Notation Editor & Player

Noteflight is a commercial, cloud-hosted music-notation editor. Its JavaScript embed API
(`nfclient.js`) drops a full-featured score editor/viewer/player into a web page and exposes
a message-passing interface to load MusicXML, read/modify the score, and control playback.
Choose it when you want turnkey *interactive editing and playback* — including collaboration
and assignment/assessment features — rather than building notation UI yourself.

**Type**: Commercial SaaS (subscription/site license)  **License**: Proprietary; API key / account required
**Runtime**: Embedded `<iframe>` widget driven by `nfclient.js`  **Requires**: Internet connectivity

## Official Resources & Documentation
- Site: https://www.noteflight.com/
- API/embed docs: https://www.noteflight.com/api
- Developer info: https://www.noteflight.com/info/api
- MusicXML (interchange it consumes/produces): https://www.musicxml.com/

## Installation & Setup

### Include the client script
```html
<script src="https://www.noteflight.com/clientapi/latest/nfclient.js"></script>
<div id="notation-container" style="width:800px;height:600px;"></div>
```

### Initialize an embedded editor
The API instantiates a `ScoreView` bound to a container; `viewParams` control role and chrome.
```javascript
const view = new NFClient.ScoreView('notation-container', 'SCORE_ID', {
  width: 800,
  height: 600,
  viewParams: {
    scale: 1.0,
    role: 'template',            // 'template' | 'editor' | 'viewer'
    displayMode: 'paginated',    // 'paginated' | 'linear'
    hidePlaybackControls: false,
    hideEditControls: false,
    app: 'YOUR_APP_ID'
  }
});

view.addEventListener(NFClient.ScoreView.Events.SCORE_LOADED, () => {
  console.log('Score ready');
});
```
Note: exact constructor/init spelling varies by API generation (`NFClient.ScoreView` vs a
`NFClient.init({...})` factory). Follow the version of the docs matching the `clientapi`
path you load, and confirm your `app`/API key.

## Core API Reference

Because the editor runs in an iframe, the API is **asynchronous / promise- or event-based** —
you request data and receive it via callbacks/events, not synchronous returns.

### Loading & saving scores
```javascript
view.loadMusicXML(xmlString);        // replace content with a MusicXML document

view.getMusicXML().then(xml => {     // export current score as MusicXML
  console.log(xml.length, 'bytes');
});

view.getScore().then(score => {      // metadata/model snapshot
  console.log(score.title, score.parts);
});
```

### Playback control
```javascript
view.play();
view.pause();
view.stop();
view.setPlaybackPosition(0);         // seek to start
```

### Events
```javascript
const E = NFClient.ScoreView.Events;
view.addEventListener(E.SCORE_LOADED,  () => {/* ready */});
view.addEventListener(E.SCORE_CHANGED, (ev) => console.log('edited', ev));
view.addEventListener(E.PLAYBACK_STARTED, () => {/* ... */});
view.addEventListener(E.PLAYBACK_STOPPED, () => {/* ... */});
```

### View / role configuration
- `role: 'viewer'` — read-only display + playback.
- `role: 'editor'` — full editing UI for the signed-in user.
- `role: 'template'` — a starting score users can copy/edit into their own.
- `scale`, `displayMode`, and control-visibility flags tune the chrome.

## Capabilities Overview
- Full notation **editing** (notes, dynamics, articulations, lyrics, multi-part).
- **Playback** with instrument sounds and tempo control.
- **Cloud storage** of scores in the Noteflight account/library.
- **Real-time collaboration** (multiple editors) on higher tiers.
- **Export**: MusicXML, MIDI, PDF, audio (per plan).
- **Education**: assignments, templates, and assessment integrations (Noteflight Learn).

## How-To (worked recipes)

### How to embed a read-only score with playback
```javascript
const view = new NFClient.ScoreView('container', 'PUBLIC_SCORE_ID', {
  width: 720, height: 480,
  viewParams: { role: 'viewer', hideEditControls: true, app: 'YOUR_APP_ID' }
});
view.addEventListener(NFClient.ScoreView.Events.SCORE_LOADED, () => view.play());
```

### How to load your own MusicXML into the editor
```javascript
const view = new NFClient.ScoreView('container', null, {
  viewParams: { role: 'editor', app: 'YOUR_APP_ID' }
});
view.addEventListener(NFClient.ScoreView.Events.SCORE_LOADED, () => {
  view.loadMusicXML(myMusicXmlString);
});
```

### How to capture edits and persist them yourself
```javascript
view.addEventListener(NFClient.ScoreView.Events.SCORE_CHANGED, async () => {
  const xml = await view.getMusicXML();
  await fetch('/api/scores', { method: 'POST', body: xml,
    headers: { 'Content-Type': 'application/xml' } });
});
```

### How to theme the embed to fit your page
Set `scale` and hide the controls you don't want; wrap the container to control surrounding layout.
```javascript
new NFClient.ScoreView('container', 'SCORE_ID', {
  width: '100%', height: 500,
  viewParams: { scale: 1.2, displayMode: 'linear', hidePlaybackControls: false }
});
```

## Do's and Don'ts

### ✅ Do
- Wait for `SCORE_LOADED` before calling `loadMusicXML`, `play`, or reading the score.
- Treat all getters as async (promises/events) — the score lives in an iframe.
- Keep your API key / `app` id server-side where the plan requires it; follow Noteflight's key handling.
- Use `role: 'viewer'` for display-only embeds to avoid exposing editing to end users.
- Persist exported MusicXML on `SCORE_CHANGED` if you need your own copy of edits.

### ❌ Don't
- Don't expect offline operation — it is cloud-based and needs connectivity.
- Don't assume a free tier for production; Noteflight embedding is a paid/licensed feature.
- Don't call playback/score APIs synchronously — you'll get `undefined` before load completes.
- Don't deep-customize the UI beyond documented `viewParams`; the widget's chrome is largely fixed.
- Don't hard-code an `nfclient` version you haven't tested — match your code to the loaded API generation.

## Styling, Theming & Customization
- **Chrome control** via `viewParams`: `scale`, `displayMode` (`paginated`/`linear`), and
  `hidePlaybackControls`/`hideEditControls` flags.
- **Sizing**: `width`/`height` on the embed; the container's CSS governs surrounding layout.
- Deep visual theming of the notation itself is limited — the editor renders with Noteflight's own style. For full engraving control use [lilypond](lilypond.md); for custom-styled web notation use [vexflow](vexflow.md)/[osmd](osmd.md).

## Advanced Features
- **Collaboration**: multi-user real-time editing on supported plans.
- **Assessment (Noteflight Learn)**: assignment distribution, submission, and grading hooks.
- **Audio/score export**: server-side rendering to PDF/MIDI/audio via the account.
- **Score library**: cloud-hosted score IDs you can embed by reference.

## Common Pitfalls & Troubleshooting
- **Blank iframe** → invalid/absent `app`/API key, or unauthorized domain.
- **`loadMusicXML` no-op** → called before `SCORE_LOADED`.
- **No sound** → browser autoplay policy; start playback from a user gesture.
- **CORS/domain errors** → your embedding origin isn't whitelisted for the API key.
- **Version mismatch** → API method names differ across `clientapi` releases; align code to the loaded version.

## Framework Integration

### React wrapper
```jsx
import { useEffect, useRef } from 'react';

function NoteflightScore({ scoreId, role = 'viewer' }) {
  const ref = useRef(null);
  const viewRef = useRef(null);
  useEffect(() => {
    if (!window.NFClient || !ref.current) return;
    const view = new window.NFClient.ScoreView(ref.current.id, scoreId, {
      viewParams: { role, app: 'YOUR_APP_ID' },
    });
    view.addEventListener(window.NFClient.ScoreView.Events.SCORE_LOADED, () => {
      viewRef.current = view;
    });
    return () => { /* remove the iframe/container children on unmount */
      if (ref.current) ref.current.innerHTML = '';
    };
  }, [scoreId, role]);
  return <div id={`nf-${scoreId}`} ref={ref} style={{ width: '100%', height: 500 }} />;
}
```
Load `nfclient.js` once at app startup (e.g. in `index.html`) before mounting the component.

### Event catalog (common)
```javascript
const E = NFClient.ScoreView.Events;
// E.SCORE_LOADED      – ready to script
// E.SCORE_CHANGED     – user edited the score
// E.PLAYBACK_STARTED  – playback began
// E.PLAYBACK_STOPPED  – playback ended/stopped
// E.NOTE_SELECTED     – selection changed (where supported)
```

## Integration Notes
- **Input/output** is MusicXML — produce it from [music21j](music21j.md)/[lilypond](lilypond.md) and consume exports in [osmd](osmd.md) or your own tools.
- **Auth model** ties embeds to a Noteflight account/site license; plan for user accounts if you use editor roles.
- **Self-hosted alternative**: if licensing or offline use is a blocker, combine [osmd](osmd.md) (display) + a custom editor UI + [tone_js](tone_js.md) (playback).

## Best For / Avoid For
`turnkey-editor`, `education-platforms`, `collaboration`, `assignments`, `cloud-scores`,
`playback` — choose Noteflight when you want a complete hosted notation editor without building one.
Avoid for: offline apps, cost-sensitive/free projects, deep UI customization, or self-hosted
notation (use [osmd](osmd.md) + [vexflow](vexflow.md), or [alphatab](alphatab.md) for tab).

## See Also
- [musicxml](musicxml.md) — the interchange format Noteflight loads/exports
- [osmd](osmd.md) — self-hosted MusicXML display alternative
- [vexflow](vexflow.md) — build your own notation UI
- [alphatab](alphatab.md) — tab-focused viewer with playback
- Use case: [../use-case/music-notation.md](../use-case/music-notation.md)
