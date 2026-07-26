# Carpet Grand Prix — Player Persona Mapping

Four target player personas, selected from the existing persona library, with predicted
experience and feature-fit analysis. See `player-journeys/` for the step-by-step
first-session walkthrough for each.

## P-011 — Maria Rodriguez, "The Commuter Gamer" *(secondary segment, casual, offline, low-spend)*

**Why it fits.** Maria plays to reclaim dead time on a train and needs games that work
with no signal and no commitment. A 50-second run is exactly one station gap. There is no
server, no login, no session to lose.

**Predicted experience.** Three runs, phone away, same course picked up again tomorrow.
She will not chase gold medals — bronze and "a bit better than yesterday" is the whole
appeal. Her risk is physical: tilting a phone on a crowded train is conspicuous, and the
train's own motion pollutes the sensor. Vehicle Mode exists specifically for her, and the
game offers it unprompted after her second run of sustained low-frequency drift. She will
never see the story vignettes past Room 3, and that is fine — the game is complete at any
medal count.

## P-002 — Sarah Chen, "The Micro-Gamer" *(primary, casual, iOS, parent, micro-transactor)*

**Why it fits.** Sarah plays in 3–6 minute windows around her kids and treats games as a
small luxury. Carpet Grand Prix is a one-handed, portrait, pause-anywhere premium
purchase — no energy meter telling her when she is allowed to play.

**Predicted experience.** She buys it on a recommendation, plays it *with* her kids
watching, and the toys-come-alive premise does more work for her than the racing does.
She finishes the story. She skips the Basement's harder golds entirely. Her one friction
point is the $4.99 upfront ask against a library of free games — the four-course free
demo is aimed squarely at her. She is the most likely persona to buy the Garage Sale
expansion, because she wants more of the *house*, not more of the racing.

## P-008 — David Park, "The Achievement Hunter" *(primary, iOS, mid-tier spend, engineer)*

**Why it fits.** David needs a visible 100% and a skill ceiling that rewards precision
over time spent. 38 courses × 4 medal tiers is a completion grid, and Sprue (developer)
times are tuned so the last six are genuinely hard.

**Predicted experience.** Within twenty minutes he notices grade is readable from
parallax height and starts pre-loading tilt — this is the mechanic he is actually buying.
He grinds ghost deltas in 0.05s increments and files a detailed bug report about sensor
drift on his specific handset. He is the reason ghost replays store raw tilt as well as
position: he wants to *see* the input, not just the line. He 100%s the base game in ~11
hours and is the first to ask for the track editor.

## P-018 — Rachel Green, "The Accessibility User" *(edge case, legally blind, iPhone, VoiceOver advocate)*

**Why it fits — and where it does not.** This game is visually driven and Rachel cannot
play the standard mode. Including her is a design constraint, not a marketing claim: a
tilt racer is one of the few action genres that *can* be made playable non-visually,
because the entire input is proprioceptive and the entire course is a 1-D line with a
lateral offset.

**Predicted experience.** In Audio Course Mode the run is rendered as a stereo field:
lane position is panning, distance-to-rail is a rising tick rate in the corresponding
ear, grade is engine pitch, and upcoming corners are announced by a directional chime
1.5s out. She plays the Playroom and Hallway rooms — wide lanes, no open edges — and
never touches the Basement, which is not honestly playable without sight. All menus,
course cards, medal states and times are VoiceOver-labelled, and the store page states
plainly which 14 of 38 courses are audio-playable. She cares more that the game said
which ones than that the number is 14.

## Mechanics-to-persona matrix

| Mechanic / feature | P-011 Maria | P-002 Sarah | P-008 David | P-018 Rachel |
|---|---|---|---|---|
| 45–120s run length | Primary draw | Fits her 3–6 min window | Neutral — enables high run volume | Neutral |
| Free rest-pose calibration | Enables train play | Enables one-handed play with a kid in the other arm | Neutral | Neutral |
| Vehicle Mode (motion filter) | Primary beneficiary | Not used | Not used | Not used |
| Tap-to-recentre mid-run | Solves seated/crowded posture shifts | Solves interrupted play | Rarely needed | Not applicable |
| Time-cost failure (no crash-out) | Reduces stakes of a distracted glance | Kid-friendly, non-punishing | Irrelevant to his mastery goal | Reduces stakes of a missed audio cue |
| Ghost replays w/ raw tilt | Not used | Not used | Primary draw | Not used |
| Bronze/Silver/Gold/Sprue medal ladder | Bronze only, and that's fine | Silver/gold on easier rooms | Full ladder, Sprue is the goal | Bronze/Silver on audio-playable courses |
| Story vignettes (The Box) | Sees Rooms 1–3 only | Finishes the full story | Secondary to completion | Fully VoiceOver-accessible |
| Room/medal unlock gating (no currency) | Steady, no paywall friction | No IAP prompts around her kids | Transparent completion percentage | No purchase gate on accessibility features |
| Audio Course Mode | Not used | Not used | Not used | Primary draw; defines her playable content |
| Car handling variety (mass vs. grip) | Not explored deeply | Uses default/starter cars | Actively exploited per-course | Distinguishable by engine pitch alone |
| $4.99 premium, free demo | Low-stakes purchase | Demo removes purchase risk | Buys immediately, high intent | Store page's per-course accessibility list informs her purchase decision |
