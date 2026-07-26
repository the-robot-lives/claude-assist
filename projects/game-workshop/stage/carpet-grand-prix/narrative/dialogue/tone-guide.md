# Carpet Grand Prix — Tone Guide (Wordless Narrative)

There is no dialogue system in Carpet Grand Prix. This document exists in place of one
— it is the tone and voice direction for a story told with no lines, no narrator, and
one diegetic written word in the entire nine-vignette arc. Everyone building or
reviewing a vignette should read this before touching a shot.

## What holds tone when there are no words

| Instead of | Carpet Grand Prix uses |
|---|---|
| Line reads / voice performance | Motion quality — acceleration curves, hesitation, overshoot, settle time |
| Character banter | Blocking — who enters frame first, who waits, who leads |
| Exposition | Environmental staging — what changed in the room since last time we saw it |
| Emotional beats stated aloud | Held stillness — silence and a static frame do the work a line would |
| A narrator framing the stakes | The player's own medal count — the game only shows you a vignette once you've earned the context for it |

## What the vignettes may do

- Use held, static shots well past the point of narrative "need" — stillness is a
  tool, not dead air. The Midpoint Reversal vignette's stair-pause is the longest
  static hold in the game on purpose.
- Use sound design (engine hum, tape shriek, rain, a single breath of laughter) as
  the emotional soundtrack a voice performance would normally carry.
- Use one, and only one, piece of diegetic in-fiction text: the word "DONATE" written
  in marker on a box by a character's hand, in Vignette 2. This is not narration. It
  is a prop being labelled by someone inside the story, the same as if the camera
  showed a street sign.
- Show a human figure only from the shoulders down (hands, forearms, legs, feet) at
  every point except the Midpoint Reversal, which is permitted to show slightly
  more body — while still never showing a face — because that vignette's entire
  effect depends on the audience almost, but not quite, being caught looking at
  someone.

## What the vignettes may never do

- No on-screen text of any kind beyond the single "DONATE" marker moment. No
  captions, no title cards, no "Six Months Later" — time jumps are told through
  light, weather, and the visible age of a hand or a foot, never through a caption.
- No narrator voice-over, ever, under any circumstance, including tutorialisation.
  If a mechanic needs explaining, it is explained by a course layout that teaches it
  through play (see the flesh GDD's Playroom design note: the first course teaches
  tilt-to-accelerate with zero hazards), never by a voice.
- No human face, at any point, in any vignette. This is a hard rule, not a budget
  constraint — the story is about the cars, and the moment a human face appears on
  screen the audience's attention (and empathy) reflexively moves to that face and
  off the cars. The Boxed One's silhouette in the Climax vignette is the closest the
  narrative gets to a "face," and it deliberately has none.
- No sound effect standing in for a word — no cartoon "huh?" or gasp used as a
  punctuation mark the way a line of dialogue would be. Sound in this game is
  physical (engines, tape, rain, wheels) or ambient (birdsong, a tap running), never
  a vocalised stand-in for speech.

## Reading character through motion and silhouette alone

Every car's personality is authored entirely in its handling model and its one
visual tic (see `narrative/characters/character-index.md`), and the vignette
animation is required to stay consistent with that handling identity even outside
of actual gameplay physics. In practice this means:

- **Acceleration and braking curves** are the closest thing this cast has to line
  readings. The Loaf accelerates like a decision that's already been made and
  brakes like it forgot how; Chrome corners with an exaggerated, showy arc even when
  a straight line would be faster; Wasp's whip-antenna lag is the visual equivalent
  of a beat of hesitation before it commits.
- **Silhouette read** must work with the sound off and the frame paused at any point.
  If two cars' poses are ambiguous against each other in a freeze-frame, the shot is
  staged wrong — spacing, scale, and body language are doing the job a name tag
  would do in a game with dialogue.
- **Stillness is characterisation.** A car that is first to move in a group shot
  (Red 7, consistently) reads as different from a car that waits and enters last
  (The Boxed One, always). Who moves first, and who hangs back, is directorial
  choice, not accident, in every group shot in the spine.

## What the audio carries instead of a voice track

The 7-stem room arrangement (see `assets/audio-direction.md`) and each room's
ambient bed are the emotional score that would otherwise live in a dialogue mix. In
narrative vignettes specifically:

- Engine pitch and tyre sound substitute for vocal effort — a strained, straining
  engine note reads as "trying hard," the same register a grunt or a line would
  carry in a game with voice.
- Diegetic room sound (a tap running, rain on plastic track, a door's spring)
  is mixed forward during vignettes, louder relative to music than it is during
  gameplay, because in the absence of dialogue it is doing dialogue's job of
  telling the player where they are and what just happened.
- Silence is scored deliberately and never treated as a mixing gap. The three full
  seconds of near-silence at the end of the Midpoint Reversal vignette are a
  composed choice, not empty space waiting to be filled later.

## The localisation consequence

Because there is no dialogue anywhere in the game, and the single piece of in-fiction
text ("DONATE") is deliberately handwritten and left untranslated in every build —
it is a prop, not a UI string, and translating a handwritten prop would break the
diegesis — the entire localisation surface for Carpet Grand Prix is UI only: menus,
course names, medal labels, settings, and the App Store page. Per the flesh GDD's
production budget, this keeps a 9-language localisation pass to roughly $7,500 total,
an order of magnitude below what a voiced narrative title of comparable content
volume would spend. Every vignette shipped in every territory is byte-for-byte
identical — there is no dub, no subtitle track, and no territory-specific edit,
because there is nothing language-dependent in the asset to begin with.
