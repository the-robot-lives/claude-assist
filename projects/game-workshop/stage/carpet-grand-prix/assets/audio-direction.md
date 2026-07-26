# Carpet Grand Prix — Audio Direction

Sound design bible: the 7-stem accumulating room arrangement, per-room ambient beds,
engine sound as a speed/grade readout, and the Audio Course Mode accessibility brief.

## The 7-Stem Accumulating Arrangement

The music is a single continuous seven-part composition, not seven separate tracks.
Each room unlocks one additional stem, layered permanently on top of everything
unlocked before it — nothing is ever swapped out or muted as new rooms open. The
Playroom plays only the ukulele. The Garden plays the full seven-piece band. A
player who has unlocked every room hears the entire arrangement any time they race
in the Garden, and hears progressively less of it the earlier the room.

| Room | Stem added | Instrument | Role in the arrangement |
|---|---|---|---|
| 1. Playroom | Stem 1 | Ukulele | The whole melodic idea, stated plainly, solo — everything later is a variation or harmony on this line |
| 2. Kitchen | Stem 2 | Brushed snare / hand percussion | First rhythm section element; keeps the ukulele's tempo honest without crowding it |
| 3. Hallway | Stem 3 | Upright bass, plucked | Low end enters; the arrangement stops being a solo instrument and becomes a small combo |
| 4. Attic | Stem 4 | Glockenspiel | A bright, slightly thin high voice — deliberately a little exposed and delicate, matching the Attic's dust-and-single-bulb visual mood |
| 5. Garage | Stem 5 | Electric guitar, clean/muted | The first stem with any grit to its tone, echoing the Garage's oil-and-concrete hazard set |
| 6. Basement | Stem 6 | Cello, low and sustained | The darkest-voiced stem, entering at the game's visual and narrative low point; carries weight rather than melody |
| 7. Garden | Stem 7 | Full kit drums | The arrangement's rhythmic anchor arrives last, once every other voice is already established — the full band only exists once the whole house has been heard from |

The mix is arranged so that every stem remains audible and identifiable once
layered — this is a hard requirement for the composer, not a mixing nicety, because
the accumulation *is* the meta-loop's audio expression of progress. A returning
player replaying the Playroom after unlocking the Garden should still hear only the
ukulele there; stems are locked to the room being raced, not to total unlocks, so
the accumulation is heard as you move forward through rooms in a session, not just
banked permanently across the whole game.

## Per-Room Ambient Bed

| Room | Ambient bed |
|---|---|
| Playroom | Muffled TV two rooms away, toy-box rattle |
| Kitchen | Fridge hum, dishwasher cycle |
| Hallway | Clock tick, distant footsteps |
| Attic | Rain on the roof, timber creak |
| Garage | Compressor, radio bleed |
| Basement | Boiler, drip, deep room tone |
| Garden | Crickets, wind, sprinkler |

Ambient beds are diegetic, spatialised, and always active beneath the music
arrangement, never beneath it in importance — a player should be able to identify
which room they're in with the music muted entirely, from the ambient bed alone.
Ambient beds do not accumulate the way music stems do; each room's bed is
self-contained and replaces the previous room's the instant a run begins, matching
the visual convention that each room is its own fully art-directed space rather than
a continuation of the last one.

## Engine sound as a speed/grade readout

The car's engine note is not a fixed loop with a volume knob — it is a continuous
readout of two of the physics simulation's live values, and sound design treats it
as an instrument the player is meant to learn to read without looking at a HUD:

| Physical state | Audio response |
|---|---|
| Speed increasing | Engine pitch rises continuously and smoothly with velocity — no gear-shift steps, no fixed pitch tiers, because the underlying physics model has no gears to shift |
| Current grade (uphill/downhill) | A secondary low-frequency component under the engine note thickens on downhill grade and thins on uphill grade, giving the player a felt sense of "pulling" versus "climbing" independent of the pitch-from-speed cue |
| Lateral tyre load / drift | Tyre scrub layers in as a separate, higher-frequency texture once lateral load crosses roughly 70% — the same threshold at which the physics model itself transitions from carving to drifting, so the audio cue and the handling change happen at the same instant |
| Rail contact | A short, percussive scrub/thud, scaled in volume to the 20% speed-scrub penalty rail contact costs — a heavier hit sounds and costs more, a glancing one sounds and costs less |
| Boost strip contact | A brief upward pitch flare layered over the engine note, distinct enough from a normal speed increase that a player can hear a boost happen even without seeing the cyan chevrons |

This readout exists because the primary mechanic depends on the player anticipating
grade before they can see it clearly (the flesh GDD's parallax-height legibility
system), and sound is the fastest channel for that anticipation — an experienced
player should be able to close their eyes over a section they've run before and
still feel, through engine pitch and the grade-thickening bass layer alone,
approximately where they are on the course.

## Audio Course Mode

Built for and validated against the accessibility persona P-018 (a legally blind
VoiceOver user) and specified as a hard accessibility requirement in the flesh GDD,
Audio Course Mode renders an entire run as a fully non-visual stereo field. It is
not a simplified version of the normal game's audio — it is a distinct, purpose-built
mix with its own four rules:

| Signal | Audio encoding |
|---|---|
| Lane position | Stereo pan — hard left at the left rail, centre on the racing line, hard right at the right rail; panning is continuous and immediate, matching lateral input 1:1 |
| Rail proximity | Tick rate rising in the corresponding ear as the car approaches a rail — a slow, sparse tick well clear of the rail accelerating to a fast, urgent tick right at the edge, giving the player a buffer to correct before contact rather than only a warning at the moment of contact |
| Grade | Engine pitch, using the same live speed/grade readout described above — Audio Course Mode does not use a separate grade cue, because the standard engine-pitch system was already designed to be legible without looking at the screen |
| Upcoming corners | A directional chime sounded 1.5 seconds before the corner, panned to the side the corner turns toward — giving a consistent lead time regardless of the player's current speed, so the warning arrives with the same reaction window on a slow bronze-pace run as on a fast gold-pace run |

Not every course is honestly playable this way. Per the flesh GDD, only courses
without open-edge hazards (Basement's signature hazard, which has no honest
non-visual tell) qualify, and the game states plainly, on the store page and in the
in-game course list, exactly which of the 38 courses are audio-playable — currently
14 of 38, concentrated in the Playroom and Hallway, the two rooms with the widest
lanes and no open-edge hazard. This number is disclosed rather than rounded up or
implied, because per the design intent behind P-018, a player relying on this mode
should never discover a course's limits by failing silently against a hazard the
mode was never built to convey.
