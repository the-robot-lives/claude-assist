# Carpet Grand Prix

> The floor is the racetrack. The phone is the floor.

---

## 1. Title & Genre

| Field | Value |
|---|---|
| **Title** | Carpet Grand Prix |
| **Genre** | Tilt-controlled arcade racer / time-attack |
| **Sub-genre** | Physical-toy simulation ("diorama racer") |
| **Engine** | Unity 6 (6000.x), URP 2D Renderer with custom parallax stack |
| **Prototype** | `prototype/index.html` — single-file HTML5 canvas build, playable now |
| **Primary platform** | iOS 16+ (iPhone 12 and newer) |
| **Secondary platform** | Android 12+ (gyro-equipped devices), 6 months post-launch |
| **Orientation** | Portrait only, one-handed |
| **Input** | Device orientation (gyroscope + accelerometer). Touch is menu-only. |
| **Monetization** | Premium — $4.99, no ads, no IAP. One paid expansion at $2.99. |
| **Rating** | ESRB E / PEGI 3 / App Store 4+ |
| **Session length** | 45–120 seconds per run; 4–7 minutes per sitting |
| **Content scope** | 38 courses across 7 rooms, 14 cars, ~3.5 hours to first credits |

---

## 2. Vision Statement

Carpet Grand Prix is what it feels like to be eight years old, lying on the living-room
floor with a plastic orange track running from the couch cushion down to the kitchen tile.
You do not drive the car — you tilt the *world*, and the car obeys gravity the way a real
die-cast car does. Because the game reads the handset's true orientation, tipping the
phone does two things at once: it feeds gravity into the physics, and it moves your
viewpoint over a floating diorama, so the track visibly slides across the carpet beneath
it and the rails lean away from you. The result is a racer where the screen stops reading
as a picture and starts reading as an object sitting on the floor in front of you. It
exists because tilt controls on mobile have been treated as a cheap accelerometer gimmick
for fifteen years, and nobody has yet made the tilt *be* the fiction.

---

## 3. Core Loop

Target session: **45–120 seconds** per run, **4–7 minutes** per sitting (3–5 runs).

```
                 ┌──────────────────────────────┐
                 │  PICK A COURSE  (5s)         │
                 │  see your ghost + medal tier │
                 └──────────────┬───────────────┘
                                ▼
                 ┌──────────────────────────────┐
                 │  CALIBRATE  (2s)             │
                 │  hold phone at rest pose,    │
                 │  3-2-1 countdown             │
                 └──────────────┬───────────────┘
                                ▼
        ┌───────────────────────────────────────────────┐
        │            THE RUN  (40–110s)                 │
        │                                               │
        │   tip away ──► gravity accelerates the car    │
        │        │                                      │
        │        ▼                                      │
        │   read the grade ahead (parallax height)      │
        │        │                                      │
        │        ▼                                      │
        │   tilt sideways ──► pick your line            │
        │        │                                      │
        │        ├──► hit boost strip     (+speed)      │
        │        ├──► clip rail           (−speed)      │
        │        ├──► miss the gap        (+2.0s)       │
        │        └──► launch off ramp     (airtime)     │
        │        │                                      │
        │        ▼                                      │
        │   ease back before the corner ──► carve it    │
        └───────────────────────┬───────────────────────┘
                                ▼
                 ┌──────────────────────────────┐
                 │  FINISH  (6s)                │
                 │  time, delta vs ghost,       │
                 │  medal, one unlock beat      │
                 └──────────────┬───────────────┘
                                │
                    ┌───────────┴───────────┐
                    ▼                       ▼
              "Run It Again"          "Next Course"
```

### Step-by-step — what the player actually does

| # | Step | Player action | Feedback |
|---|---|---|---|
| 1 | Pick | Tap a course card | Card shows best time, medal tier, ghost availability |
| 2 | Calibrate | Hold the phone however is comfortable, tap once | Bubble level centres; this pose becomes "neutral" |
| 3 | Launch | Tip the top of the phone away from the body | Car rolls; engine pitch rises with speed |
| 4 | Read | Look at how high the track floats off the carpet | Steeper grade = track sits visibly higher ahead |
| 5 | Line | Roll the handset left/right | Car slides across the lane; tyres audibly scrub |
| 6 | Commit | Hold full tilt down the straight | Speed streaks, camera pulls back, rails blur |
| 7 | Bail | Ease the phone flat before a hairpin | Car settles; grip returns |
| 8 | Recover | After a fall, re-find neutral | Respawn at last checkpoint, +2.0s, screen flash |
| 9 | Bank | Cross the finish gate | Time, delta, medal, confetti of plastic sprues |

### Failure philosophy

There is **no crash-out and no lives**. Every mistake is a *time* cost: clipping a rail
scrubs 20% of your speed, a fall costs 2.0 seconds plus the re-accelerate. The course
always finishes. Mastery layers replace punishment — bronze is reachable by anyone who
holds the phone still, gold demands line choice, and the developer ghost demands
knowing where the grade changes before you can see it.

---

## 4. Meta Loop

What carries between sessions:

| Axis | What grows | How growth feels |
|---|---|---|
| **Times** | Per-course best time + ghost replay | The ghost is *you, yesterday*. Beating it is the whole game. |
| **Medals** | Bronze / Silver / Gold / Sprue (dev time) per course | A wall of medals fills in; each room shows a fraction |
| **Rooms** | 7 rooms unlock at medal thresholds | New floor material, new hazard vocabulary, new music stem |
| **Cars** | 14 die-cast cars with real handling differences | Not upgrades — *tools*. A heavy car is better on the Basement, worse in the Attic. |
| **Track pieces** | Cosmetic track skins (orange classic, glow, wood, chrome) | Pure expression; earned, never sold |
| **The Box** | Narrative beats unlock as rooms complete | Nine wordless vignettes about a kid outgrowing the toys |

**Unlock cadence.** One meaningful unlock every 2–3 runs for the first hour, tapering to
one every 5–6 runs by hour two. Rooms cost medals, not currency — there is no currency in
this game at all.

**Ghosts.** Every course records your best line as a 40 Hz sample of position + tilt.
The ghost car is rendered as a translucent second car with its own parallax height, so
you can see it take a different line *over* or *under* your own on elevated sections.

---

## 5. Game Mechanics

### 5.1 Primary mechanic — the handset as a tilting table

The entire simulation derives from one input: the device's orientation relative to a
**rest pose** captured at the start of each run.

**Inputs**

| Signal | Source | Range used |
|---|---|---|
| `pitch` | `DeviceOrientationEvent.beta` − rest beta | ±32° = full lock |
| `roll` | `DeviceOrientationEvent.gamma` − rest gamma | ±32° = full lock |
| screen angle | `screen.orientation.angle` | remaps beta/gamma for landscape holds |

Both channels are low-passed at α = 0.16 per frame — enough to kill sensor jitter, not
enough to feel laggy (measured ~55 ms to 90% of a step input).

**Outputs — the same tilt drives three systems simultaneously**

```
                        ┌─► GRAVITY   a = TABLE_G · sin(tilt)      → physics
   tilt (pitch, roll) ──┼─► VIEWPOINT offset = height · sin(tilt)  → parallax
                        └─► CAMERA    subtle lead on the roll axis → framing
```

1. **Gravity.** The handset *is* the table the track is bolted to. Accelerations
   `ax = G·sin(roll)`, `ay = G·sin(pitch)` are applied in world space, un-rotated by the
   camera. Track grade contributes a further `a = SLOPE_G · dz/ds` along the tangent.
   At full pitch on a 20% grade the car pulls ~430 u/s², terminal ~318 u/s (≈133 mph
   at toy scale).

2. **Viewpoint.** Everything renders at a height above the carpet plane. The floor sits
   at h=0; the track deck floats at h≈74; rails extrude another 27; the car sits at
   h≈83. Screen position is `p + h · sin(viewAngle)`, where viewAngle is the tilt plus a
   0.46 baseline. Tilt the phone and the deck slides bodily across the carpet, the
   support posts splay, and the rails lean. This is the "3D" — no 3D geometry, no
   perspective matrix, just correct positional parallax on a layered diorama.

3. **Grade legibility.** Deck height is drawn *relative to the car's elevation*
   (`h = BASE + (z − z_camera) · 0.5`), so the track ahead of you literally sinks toward
   the carpet on a descent and rises on a crest. You read gradient the way you read a
   real Hot Wheels run — by looking at how far off the floor it is.

**Constraints and edge cases**

| Case | Handling |
|---|---|
| Player lies down / holds phone flat | Rest pose is relative, so any comfortable pose works |
| Player rotates mid-run (rolls over in bed) | Tap the playfield to re-centre without pausing |
| Landscape hold | beta/gamma swapped by screen orientation angle |
| Sensor unavailable / permission denied | Falls back to touch-drag and arrow keys; run still counts, flagged in the ghost data |
| Passenger in a moving car | "Vehicle Mode" removes low-frequency drift with a 4 s rolling rest-pose average |
| Sustained full lock (arm fatigue) | Tilt response is normalised at ±32°, so a lazy ±18° grip still reaches ~55% authority |

**Skill ceiling.** Three layers, each ~10 hours apart:
1. *Hold it steady.* Beginners over-tilt and pinball between the rails.
2. *Ease off early.* Grip is finite; the fast line brakes with the tilt before the apex.
3. *Read the height.* Experts pre-load tilt for a grade change they can see in the
   parallax two seconds before they reach it.

### 5.2 Secondary mechanics

| Mechanic | Interaction with the primary | Detail |
|---|---|---|
| **Tyre grip** | Bleeds lateral velocity at 5.0/s, so the car carves instead of sliding | Push past ~70% lateral load and it drifts; drifting is faster through wide corners, fatal through tight ones |
| **Boost strips** | +620 u/s² along the tangent while in contact | Cyan chevrons; always placed off the natural line, so taking them costs entry speed |
| **Sticky patches** | Grip drops to 1.4/s, drag +2.6 | Spilled juice / dust bunnies. Ice-physics inversion of the core feel |
| **Ramps** | 0.72 s airborne, gravity still applies, grip does not | Lands you further down-course; a clean landing keeps all speed, a sideways one scrubs |
| **Open edges** | Rail is absent on one flagged side | The only true hazard. +2.0 s and a checkpoint respawn |
| **Rail bounce** | 34% restitution, 20% speed scrub | Cheap to touch, expensive to lean on |
| **Car mass** | Scales gravity response and grip independently | Heavy = more gravity authority, less grip. Light = twitchy, corners hard. |
| **Checkpoints** | Every ~28 samples (~900 units) | Respawn granularity; never rewinds the clock |

### 5.3 Difficulty progression

| Room | # Courses | Lane width | Avg grade | New vocabulary | Target gold time |
|---|---|---|---|---|---|
| 1. Playroom | 4 | 95 u | 12% | Rails only. Wide, forgiving, no hazards. | 38–46 s |
| 2. Kitchen | 5 | 95 u | 16% | Boost strips; first spilled-juice patches | 42–55 s |
| 3. Hallway | 5 | 88 u | 14% | Long straights, hairpin turnarounds, rug seams | 55–70 s |
| 4. Attic | 6 | 84 u | 22% | Ramps and airtime; rafter gaps | 48–62 s |
| 5. Garage | 6 | 80 u | 19% | Oil slicks (extreme sticky), tool hazards | 60–78 s |
| 6. Basement | 6 | 73 u | 27% | Open edges over a void; darkness, headlight cone | 52–68 s |
| 7. Garden | 6 | 70 u | 24% | Wind (constant lateral bias), wet grass, downhill finale | 70–95 s |

Escalation is **width down, grade up, hazard count up** — never "more enemies" or
"tighter timer." Every room adds exactly one new hazard verb and reuses everything prior.

---

## 6. World Design

### Map structure — hierarchical, one house

The world is a single suburban house seen from above. Rooms are hubs; courses are
individual track runs laid across the floor of that room. Progression is spatial —
you can see the doorway to the next room from the room you are in.

```
             [ THE BOX ]  ← narrative frame, opens after Room 7
                  │
   Playroom ──► Kitchen ──► Hallway ──► Attic
                                │
                                ├──► Garage
                                │       │
                                └──► Basement ──► Garden
```

Unlock gates: Kitchen (4 medals), Hallway (10), Attic (18), Garage (26), Basement (34),
Garden (44), The Box (all 38 golds or 60 medals total).

### Art direction pillars

1. **Die-cast, not photoreal.** Cars have visible seam lines, a base plate, and a
   chip in the paint. The track is scuffed orange plastic with stress marks at the joins.
2. **The floor is real, the track is a toy.** Carpet, tile, and floorboards are rendered
   at high fidelity with real fibre noise; the track above it is flat, saturated,
   unmistakably moulded plastic. The contrast is the whole visual joke.
3. **Light comes from the room, not the game.** Each room has one dominant practical
   light source that casts the track's shadow onto the floor in a fixed direction.
4. **Height reads as colour.** Track sections sitting higher off the floor are lit
   brighter; sections near the floor fall into the room's ambient shadow.

### Visual and audio progression

| Room | Floor | Palette | Light source | Audio bed |
|---|---|---|---|---|
| Playroom | Short shag, blue-grey | Orange track, cyan rails | Afternoon window, warm | Muffled TV two rooms away, toy-box rattle |
| Kitchen | Vinyl tile, gloss | Amber track, pink rails | Overhead fluorescent, cold | Fridge hum, dishwasher cycle |
| Hallway | Runner rug + hardwood | Deep orange, white rails | Door gaps, striped | Clock tick, distant footsteps |
| Attic | Bare plywood, dust | Ochre track, red rails | Single bulb, swinging | Rain on the roof, timber creak |
| Garage | Sealed concrete, oil | Grey-blue track, yellow rails | Strip light, buzzing | Compressor, radio bleed |
| Basement | Bare slab, dark | Violet track, mint rails | Car's own headlights only | Boiler, drip, deep room tone |
| Garden | Wet grass, patio slab | Green-white track, orange rails | Dusk, long shadows | Crickets, wind, sprinkler |

The music is one 7-part arrangement. Each room unlocks a new stem layered onto the
previous ones, so the Garden plays the full band and the Playroom plays only the ukulele.

---

## 7. Narrative

Wordless. Nine vignettes, each 8–14 seconds, rendered in the same diorama style, unlocked
one per room plus two at the end. No dialogue, no text, no narrator.

### Tone — 7-axis spectrum

| Axis | Position |
|---|---|
| Serious ←→ Playful | **Playful**, 80% |
| Grounded ←→ Fantastical | **Grounded**, 70% — the toys move, nothing else breaks |
| Warm ←→ Cold | **Warm**, 85% |
| Simple ←→ Complex | **Simple**, 90% |
| Hopeful ←→ Melancholy | **Melancholy**, 60% — a gentle ache under the fun |
| Intimate ←→ Epic | **Intimate**, 95% — the whole world is one house |
| Sincere ←→ Ironic | **Sincere**, 100% |

### Eight-point story spine

| Beat | Vignette |
|---|---|
| **1. Equilibrium** | Dusk. A kid's hand pushes a red car down an orange track from the couch to the rug. Laughter offscreen. The hand withdraws. The cars stay where they landed. |
| **2. Inciting incident** | Morning. A cardboard box lands on the playroom floor. Marker on the side: **DONATE**. A parent's hands begin sweeping track pieces into it. |
| **3. First complication** | Night. The cars move on their own for the first time — badly, wobbling, relearning. Half the track is already in the box. They race on what's left. |
| **4. Rising action** | The cars start *stealing back* track pieces, one at a time, dragging them room to room. The house becomes a circuit. |
| **5. Midpoint reversal** | The kid comes downstairs at 2 a.m. for water and sees the track running through the kitchen. Long pause. They step over it and go back to bed. They never mention it. |
| **6. Crisis** | The box is taped shut and carried to the garage. The remaining cars can only reach the basement — the darkest, steepest, most dangerous run in the house. |
| **7. Climax** | The Garden run. The full team, on the last unbroken stretch of track, out the back door and down the garden path in the rain, chasing the car that got boxed. |
| **8. Resolution** | The box is open on the patio. Nothing was thrown away. The kid — older now, taller — is laying new track across the grass. Not for themselves. For someone smaller, standing behind them. |

### Cast

No lines. Characters are read entirely through handling, silhouette, and one visual tic.

| Car | Class | Theme | Handling identity | Unlock |
|---|---|---|---|---|
| **Red 7** | Muscle | Loyalty | Baseline. Balanced mass, honest grip. The starter. | Start |
| **Chrome** | Show car | Vanity | Lowest mass, sharpest grip, terrible on grade | Playroom gold ×2 |
| **The Loaf** | Van | Stubbornness | Heaviest; enormous gravity authority, no grip at all | Kitchen complete |
| **Wasp** | F1 | Ambition | Fastest terminal speed, punished hardest by rails | Hallway gold ×3 |
| **Rustbucket** | Pickup | Endurance | Immune to sticky patches, mediocre everywhere else | Attic complete |
| **Sparks** | Hot rod | Recklessness | Boost strips give it 1.4× effect; no rail restitution | Garage gold ×4 |
| **Bit** | Micro | Curiosity | Half-size hitbox; can take lines nothing else fits | Basement complete |
| **The Boxed One** | Unknown | Loss | Locked. Recovered in the Garden finale. Perfect stats. | Story complete |

Six further cars (Taxi, Tractor, Fire, Ambulance, Bus, Concept) are pure cosmetic variants
on the eight handling classes, earned through medal thresholds.

---

## 8. Player Personas

Selected from the existing library. Four primary targets.

### P-011 — Maria Rodriguez, "The Commuter Gamer" *(secondary segment, casual, offline, low-spend)*

**Why it fits.** Maria plays to reclaim dead time on a train and needs games that work
with no signal and no commitment. A 50-second run is exactly one station gap. There is
no server, no login, no session to lose.

**Predicted experience.** She will play three runs, put the phone away, and pick the same
course up tomorrow. She will *not* chase gold medals — bronze and "a bit better than
yesterday" is the whole appeal. Her risk is physical: tilting a phone on a crowded
train is conspicuous, and the train's own motion pollutes the sensor. **Vehicle Mode**
(rolling rest-pose average) exists specifically for her, and she will find it because
we detect sustained low-frequency drift and offer it unprompted after her second run.
She will never see the story vignettes past Room 3, and that is fine — the game is
complete at any medal count.

### P-002 — Sarah Chen, "The Micro-Gamer" *(primary, casual, iOS, parent, micro-transactor)*

**Why it fits.** Sarah plays in 3–6 minute windows around her kids and treats games as a
small luxury. Carpet Grand Prix is a one-handed, portrait, pause-anywhere premium
purchase — no energy meter telling her when she is allowed to play.

**Predicted experience.** She buys it on a recommendation, plays it *with* her kids
watching, and the toys-come-alive premise does more work for her than the racing does.
She will finish the story. She will skip the Basement's harder golds entirely. Her one
friction point is the $4.99 upfront ask against a library of free games — the demo
(Playroom, 4 courses, free) is aimed squarely at her. She is the most likely persona to
buy the expansion, because she will want more of the *house*, not more of the racing.

### P-008 — David Park, "The Achievement Hunter" *(primary, iOS, mid-tier spend, engineer)*

**Why it fits.** David needs a visible 100% and a skill ceiling that rewards precision
rather than time spent. 38 courses × 4 medal tiers is a completion grid, and the
developer "Sprue" times are tuned so the last six are genuinely hard.

**Predicted experience.** He will notice within twenty minutes that grade is readable
from parallax height and will start pre-loading tilt — this is the mechanic he is
actually buying. He will grind ghost deltas in 0.05 s increments and will file a
detailed bug report about sensor drift on his specific handset. He is the reason ghost
replays store raw tilt as well as position: he will want to *see* the input, not just the
line. He will 100% the base game in ~11 hours and be the first to ask for a track editor.

### P-018 — Rachel Green, "The Accessibility User" *(edge case, legally blind, iPhone, VoiceOver advocate)*

**Why it fits — and where it does not.** This game is visually driven and Rachel cannot
play the standard mode. Including her is a design constraint, not a marketing claim: a
tilt racer is one of the few action genres that *can* be made playable non-visually,
because the entire input is proprioceptive and the entire course is a 1-D line with a
lateral offset.

**Predicted experience.** In **Audio Course Mode** the run is rendered as a stereo field:
lane position is panning, distance-to-rail is a rising tick rate in the corresponding ear,
grade is engine pitch, and upcoming corners are announced by a directional chime 1.5 s
out. She will play the Playroom and Hallway rooms — wide lanes, no open edges — and will
never touch the Basement, which is not honestly playable without sight. All menus,
course cards, medal states and times are VoiceOver-labelled and the store page states
plainly which 14 of 38 courses are audio-playable. She will care more that we said which
ones than that the number is 14.

---

## 9. User Stories

### Core mechanics

1. As **P-011 (Maria)**, I want to set my neutral tilt from whatever position I am already holding the phone in, so that I can play slouched on a train without holding my arms up.
2. As **P-011 (Maria)**, I want to re-centre my rest pose with a single tap mid-run without pausing, so that shifting position does not cost me the run.
3. As **P-008 (David)**, I want tipping the phone further to produce proportionally more acceleration up to a defined limit, so that I can learn a repeatable input-to-output mapping.
4. As **P-008 (David)**, I want lateral tilt to move the car across the lane with tyre grip rather than instant translation, so that there is a fast line and a slow line through every corner.
5. As a **new player**, I want the car to keep rolling even when I hold the phone perfectly flat, so that I am never stuck and confused.
6. As **P-002 (Sarah)**, I want a mistake to cost me time rather than end my run, so that I always reach the finish line.
7. As **P-008 (David)**, I want rail contact to scrub a consistent, learnable percentage of my speed, so that I can judge whether leaning on a rail through a corner is worth it.
8. As a **player**, I want to see how steep the track ahead is before I reach it, so that I can pre-load my tilt for the grade change.
9. As **P-008 (David)**, I want boost strips placed off the natural racing line, so that taking them is a decision instead of a freebie.
10. As a **player**, I want going airborne off a ramp to preserve my speed on a clean landing and scrub it on a sideways one, so that jumps reward control.
11. As **P-011 (Maria)**, I want a Vehicle Mode that filters out the low-frequency motion of a moving train, so that the car does not drift while I am sitting still.
12. As a **player**, I want the game to remap tilt axes if I rotate the phone to landscape, so that the controls never invert unexpectedly.

### Progression

13. As **P-008 (David)**, I want four medal tiers per course with the top tier set by developer times, so that there is a ceiling worth chasing after gold.
14. As **P-008 (David)**, I want a ghost car replaying my personal best, so that I can see exactly where I am losing time.
15. As **P-008 (David)**, I want the ghost to render at its correct height in the diorama, so that I can see it take a different line over elevated sections.
16. As **P-002 (Sarah)**, I want rooms to unlock on total medals rather than gold medals, so that steady play keeps opening new content.
17. As a **player**, I want cars to have genuinely different handling rather than strictly better stats, so that choosing a car is a tactical decision per course.
18. As **P-002 (Sarah)**, I want no energy meter, currency, or daily reset, so that I can play for four minutes or forty without being managed.
19. As **P-008 (David)**, I want a single completion percentage visible from the main menu, so that I know exactly what is left.
20. As a **player**, I want my times stored on-device and never lost to a server outage, so that my progress is genuinely mine.

### Narrative & world

21. As **P-002 (Sarah)**, I want the story told without text, so that I can share the game with a five-year-old and a grandparent equally.
22. As **P-002 (Sarah)**, I want each new room to look and sound meaningfully different from the last, so that progressing feels like moving through a real house.
23. As a **player**, I want the music to gain a layer per room rather than switch tracks, so that later rooms feel like an accumulation of everything before.
24. As a **player**, I want the track to visibly cast a shadow onto the actual floor beneath it, so that the diorama reads as a physical object in a room.
25. As a **player**, I want a story vignette after completing each room, so that finishing a room has a payoff beyond the unlock.

### Accessibility

26. As **P-018 (Rachel)**, I want an Audio Course Mode that renders lane position as stereo panning and rail proximity as a tick rate, so that I can drive without sight.
27. As **P-018 (Rachel)**, I want corners announced by a directional chime 1.5 seconds ahead, so that I have time to react.
28. As **P-018 (Rachel)**, I want the store page and in-game course list to state exactly which courses are audio-playable, so that I am not sold a promise the game cannot keep.
29. As **P-018 (Rachel)**, I want every menu, course card, time and medal state labelled for VoiceOver, so that I can navigate the whole app independently.
30. As a **player with limited range of motion**, I want a tilt sensitivity slider from 12° to 45° full-lock, so that I can play with a small wrist movement.
31. As a **player prone to motion sickness**, I want to reduce or disable the parallax depth effect independently of gameplay, so that I can play without the layers shifting.
32. As a **colour-blind player**, I want boost, sticky and hazard surfaces distinguished by pattern as well as colour, so that I can read the track surface.
33. As a **one-handed player**, I want every menu reachable in the bottom third of a portrait screen, so that I never need a second hand.

### Onboarding & session

34. As a **new player**, I want the first course to teach tilt-to-accelerate with no hazards at all, so that I learn one thing before I learn two.
35. As **P-011 (Maria)**, I want a run to be resumable or abandonable instantly when my stop arrives, so that the game never holds me hostage.
36. As **P-002 (Sarah)**, I want a free four-course demo before the $4.99 purchase, so that I know the tilt controls work for me before I pay.

---

## 10. Monetization

### Model: Premium, $4.99. No ads. No IAP. No currency.

**Why this model fits this game.** The fiction is a boy's toy box, aimed at an audience
that includes parents buying for children (P-015 exists in this library, and P-002 plays
with her kids watching). Every F2P instrument available — energy gates, gacha cars, ad
breaks between runs — actively destroys the two things this game sells: a 50-second
session you can start any time, and toys that are *yours*. A tilt racer also has a hard
ceiling on session frequency (arm fatigue caps sessions at ~7 minutes), which caps
ad-impression and IAP-exposure volume well below what an F2P economy needs to work.
Premium at $4.99 monetises the one moment of genuine intent, and the free demo carries
the conversion load.

### Price and structure

| SKU | Price | Contents |
|---|---|---|
| Free demo | $0 | Playroom (4 courses), 2 cars, no story. Full tilt system. |
| **Carpet Grand Prix** | **$4.99** | 38 courses, 7 rooms, 14 cars, full story, ghosts, Audio Mode |
| *The Garage Sale* (expansion, month 9) | $2.99 | 12 courses, 3 rooms (Shed, Loft, Driveway), 4 cars, 3 vignettes |
| Track editor update (free, month 6) | $0 | Retention + UGC sharing via deep link |

No regional discount below $2.99. No launch discount — a launch discount on a $4.99 title
trains the audience to wait for the sale.

### Revenue scenarios (12 months from launch, net of 30% store cut)

| Scenario | Demo installs | Demo→paid | Units | Base rev | Expansion att. | Exp. rev | **Net total** |
|---|---|---|---|---|---|---|---|
| **Floor** | 60,000 | 3.5% | 2,100 | $7,350 | 12% | $756 | **$5,674** |
| **Modest** | 250,000 | 5.0% | 12,500 | $43,750 | 18% | $6,750 | **$35,350** |
| **Good** | 900,000 | 6.5% | 58,500 | $204,750 | 22% | $38,600 | **$170,345** |
| **Breakout** | 4,200,000 | 8.0% | 336,000 | $1,176,000 | 26% | $261,200 | **$1,006,040** |

The Breakout case assumes an Apple feature ("Games We Love") plus one viral video
demonstrating the parallax effect — which is the single most screen-recordable thing in
the game and the reason the tilt-diorama look is the marketing asset, not the racing.

### KPI targets

| Metric | Target | Rationale |
|---|---|---|
| Demo → paid conversion | ≥ 5.0% | Premium mobile demo benchmark is 3–7% |
| D1 retention (paid) | ≥ 55% | Short sessions, no gate |
| D7 retention (paid) | ≥ 28% | Ghost chasing is the D7 driver |
| D30 retention (paid) | ≥ 12% | Editor update targets this directly |
| Median sessions/day | 2.4 | Two commutes |
| Median session length | 5.5 min | Arm-fatigue ceiling |
| Crash-free sessions | ≥ 99.7% | |
| Refund rate | ≤ 3% | Demo should absorb "tilt isn't for me" |

---

## 11. Production Plan

### Team

| Role | Count | Phase | Monthly cost | Months | Total |
|---|---|---|---|---|---|
| Technical director / gameplay lead | 1 | M1–M11 | $11,500 | 11 | $126,500 |
| Gameplay engineer (physics, sensors) | 1 | M2–M10 | $9,500 | 9 | $85,500 |
| Engineer (UI, platform, audio integration) | 1 | M4–M11 | $9,000 | 8 | $72,000 |
| Art director | 1 | M1–M11 | $10,000 | 11 | $110,000 |
| Environment / track artist | 1 | M3–M10 | $7,500 | 8 | $60,000 |
| Animator (vignettes) | 1 | M6–M10 | $7,500 | 5 | $37,500 |
| Level designer (38 courses) | 1 | M4–M11 | $7,000 | 8 | $56,000 |
| Composer / sound design (contract) | 1 | M6–M10 | $6,000 | 5 | $30,000 |
| QA (device matrix, sensor testing) | 1 | M7–M12 | $5,000 | 6 | $30,000 |
| Producer (half-time) | 0.5 | M1–M12 | $4,500 | 12 | $54,000 |
| **Peak headcount** | **8.5** | | | | **$661,500** |

### Timeline

| Month | Milestone | Exit criteria |
|---|---|---|
| M1 | Concept lock | This document signed off; HTML prototype validated on 6 handsets |
| M2 | Vertical slice — feel | Tilt→gravity→parallax loop shippable-quality on one course |
| M3 | **Feel lock** | 20 external testers; ≥70% describe controls as "natural" unprompted |
| M4 | Content pipeline | Track authoring tool; one room art-complete |
| M5 | Rooms 1–2 playable | 9 courses, medals, ghosts working |
| M6 | Track editor architecture | Editor built as the internal authoring tool from day one |
| M7 | Rooms 3–5 playable | 26 courses; **Alpha** — feature complete |
| M8 | Rooms 6–7 + Audio Mode | 38 courses; accessibility pass 1 |
| M9 | Vignettes + full audio | All 9 vignettes; 7-stem music arrangement |
| M10 | **Beta / content lock** | Full device matrix; medal times tuned from telemetry |
| M11 | Polish + certification | Accessibility pass 2; App Store submission |
| M12 | **Launch** + live support | Demo and paid SKU live; hotfix window |
| M15 | Track editor update | Free; UGC sharing |
| M21 | The Garage Sale | Paid expansion |

### Budget

| Category | Cost | Notes |
|---|---|---|
| Salaries (12 months) | $661,500 | Table above |
| Contract audio (music mastering, SFX library) | $18,000 | Beyond composer retainer |
| Device matrix (14 handsets, iOS + Android) | $9,500 | Sensor behaviour varies enormously by OEM |
| Tools & licences (Unity Pro ×8, analytics, CI) | $16,000 | |
| External QA / accessibility audit | $22,000 | Independent audit is non-negotiable given the Audio Mode claim |
| Localisation (9 languages, UI only — no dialogue) | $7,500 | Wordless narrative keeps this cheap |
| Marketing (capture, trailer, festival submissions) | $85,000 | Weighted to the parallax demo video |
| Contingency (12%) | $99,500 | |
| **Total** | **$919,000** | |

**Scope honesty.** At 8.5 heads and 12 months this budget only closes in the *Good*
revenue scenario or better. If the M3 feel-lock gate fails — if testers do not describe
the tilt as natural — the correct decision is to cut to 24 courses, 4 rooms and 8 cars,
drop the animated vignettes to stills, and rebuild the plan at ~$480,000. That decision
belongs at M3, not M9.

---

## 12. Technical Requirements

### Platform targets

| Platform | Minimum | Recommended | Target frame rate |
|---|---|---|---|
| iOS | iPhone 11, iOS 16 | iPhone 13+, iOS 17 | 60 fps locked; 120 fps on ProMotion |
| iPadOS | iPad 9th gen | iPad Air M1 | 60 fps (letterboxed portrait) |
| Android | Snapdragon 730G / Exynos 9611, Android 12, gyroscope required | Snapdragon 8 Gen 1+ | 60 fps |

Install size ≤ 220 MB. Memory ceiling 380 MB. No network required for any gameplay.
Devices without a gyroscope are blocked from purchase via manifest feature flags rather
than shipped a degraded experience.

### Key technical challenges

| # | Challenge | Risk | Mitigation |
|---|---|---|---|
| 1 | **Sensor variance across OEMs.** Android gyro fusion quality, sample rate and axis conventions differ wildly by vendor; some report at 20 Hz. | High | Abstract all sensor reads behind one calibration layer. Resample to a fixed 60 Hz internal rate with interpolation. Per-device profile table shipped as data, updatable without a client release. Android launches 6 months after iOS specifically to build this table. |
| 2 | **Drift and rest-pose loss.** Long runs and body movement shift the neutral pose; the player feels the car "pulling." | High | Rest pose is relative and re-centrable with a tap. Vehicle Mode applies a 4 s rolling average. Telemetry flags runs where the player re-centred more than twice — those courses get retuned. |
| 3 | **Parallax vs. motion sickness.** A view that shifts with head/hand motion is exactly the stimulus that provokes discomfort in a minority of players. | Medium | Parallax depth exposed as a 0–100% slider decoupled from physics, so reducing it never changes handling or times. Default 100%, prompted at first launch. Leaderboard-legal at any setting. |
| 4 | **Fill-rate on the layered diorama.** Carpet + shadow + posts + slab + deck + features + two rails + car + ghost = 9 overdrawn layers at 120 fps on a small GPU. | Medium | Cull to the visible arc only (~60 samples). Bake carpet to a scrolling tiled texture. Batch each layer into one mesh per frame. The HTML prototype already holds 60 fps on an iPhone 12 with this structure. |
| 5 | **Deterministic ghosts.** Replays must match across devices and app versions or every stored best time is a lie. | Medium | Fixed 60 Hz physics tick decoupled from render. Ghosts store sampled *position*, not input, so a physics change never invalidates history — and store the raw tilt alongside it for display only. |
| 6 | **Audio Course Mode fidelity.** A stereo field must convey lane position, rail proximity and grade simultaneously without becoming noise. | Medium | Three separate, independently mixable channels with a dedicated audio designer pass at M8. Independent accessibility audit at M11. Ship an honest per-course playability list rather than a blanket claim. |
| 7 | **Web permission model (prototype only).** `DeviceOrientationEvent.requestPermission()` requires a user gesture and a secure context. | Low | Prototype gates behind an explicit button and degrades to keyboard/drag on `file://`. Not a concern for the native build. |

---

## Prototype

`prototype/index.html` — no build step, no dependencies. Serve it over **https or
localhost** (iOS will not release the gyroscope on `file://`), open on an iPhone, and tap
**Grant Motion & Race**.

- **Tip the phone away from you** — gravity accelerates the car down the run.
- **Roll it left and right** — pick your line across the lane.
- **Tap the playfield** — re-centre your rest pose mid-run.
- On a desktop it falls back to **arrow keys** or **click-and-drag**.

Three courses of increasing difficulty, per-course best times in `localStorage`, boost
strips, sticky patches, ramps, and open edges. All tuning constants sit in the `TUNE`
object at the top of the script.
