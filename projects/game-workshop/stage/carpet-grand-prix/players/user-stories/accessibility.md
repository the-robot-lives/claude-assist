# Carpet Grand Prix — User Stories: Accessibility (US-026 – US-033)

### US-026: Audio Course Mode Stereo Field
- **Persona:** P-018 (Rachel Green)
- **Category:** Accessibility
- **Priority:** Must
- **Story:** As Rachel, I want an Audio Course Mode that renders lane position as stereo panning and rail proximity as a tick rate, so that I can drive without sight.
- **Acceptance Criteria:** Lane position maps continuously to stereo pan. Distance to the nearest rail maps to tick rate in the corresponding ear. Both channels are independently mixable and tested not to mask each other at typical playback volumes.

### US-027: Directional Corner Chimes
- **Persona:** P-018 (Rachel Green)
- **Category:** Accessibility
- **Priority:** Must
- **Story:** As Rachel, I want corners announced by a directional chime 1.5 seconds ahead, so that I have time to react.
- **Acceptance Criteria:** Every corner on an audio-playable course triggers a directional chime exactly 1.5 seconds (at typical course speed) before the corner's entry point. Chime direction matches the corner's turn direction.

### US-028: Honest Per-Course Audio-Playability Listing
- **Persona:** P-018 (Rachel Green)
- **Category:** Accessibility
- **Priority:** Must
- **Story:** As Rachel, I want the store page and in-game course list to state exactly which courses are audio-playable, so that I am not sold a promise the game cannot keep.
- **Acceptance Criteria:** The store page and the in-game course-select screen both display an explicit audio-playable indicator per course. The count (14 of 38 at launch) is accurate to the shipped build at all times, including after content updates.

### US-029: Full VoiceOver Labelling
- **Persona:** P-018 (Rachel Green)
- **Category:** Accessibility
- **Priority:** Must
- **Story:** As Rachel, I want every menu, course card, time and medal state labelled for VoiceOver, so that I can navigate the whole app independently.
- **Acceptance Criteria:** 100% of interactive UI elements carry accurate VoiceOver labels, verified by an independent accessibility audit before launch and re-verified after any content update.

### US-030: Adjustable Tilt Sensitivity
- **Persona:** Player with limited range of motion
- **Category:** Accessibility
- **Priority:** Should
- **Story:** As a player with limited range of motion, I want a tilt sensitivity slider from 12° to 45° full-lock, so that I can play with a small wrist movement.
- **Acceptance Criteria:** A settings slider remaps the full-lock angle anywhere in the 12°–45° range. Changing the slider does not alter medal time thresholds — sensitivity is an input-comfort setting, not a difficulty setting.

### US-031: Independent Parallax Depth Control
- **Persona:** Player prone to motion sickness
- **Category:** Accessibility
- **Priority:** Should
- **Story:** As a player prone to motion sickness, I want to reduce or disable the parallax depth effect independently of gameplay, so that I can play without the layers shifting.
- **Acceptance Criteria:** A 0–100% parallax depth slider is exposed at first launch. Reducing it to 0% never changes physics, times, or medal eligibility — all reduced settings remain leaderboard/ghost-legal.

### US-032: Colour-Blind-Safe Surface Distinction
- **Persona:** Colour-blind player
- **Category:** Accessibility
- **Priority:** Should
- **Story:** As a colour-blind player, I want boost, sticky and hazard surfaces distinguished by pattern as well as colour, so that I can read the track surface.
- **Acceptance Criteria:** Every functionally distinct track surface (boost strip, sticky patch, oil slick, open edge) carries a unique pattern or icon in addition to its colour, verified against at least the three most common colour-vision deficiency simulations.

### US-033: One-Handed Bottom-Third Reachability
- **Persona:** One-handed player
- **Category:** Accessibility
- **Priority:** Should
- **Story:** As a one-handed player, I want every menu reachable in the bottom third of a portrait screen, so that I never need a second hand.
- **Acceptance Criteria:** All primary interactive controls across every menu screen are positioned within the bottom third of the portrait viewport at default device sizes.
