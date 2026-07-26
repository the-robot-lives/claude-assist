# Carpet Grand Prix — User Stories: Core Mechanics (US-001 – US-012)

### US-001: Relative Rest Pose
- **Persona:** P-011 (Maria Rodriguez)
- **Category:** Core Mechanics
- **Priority:** Must
- **Story:** As Maria, I want to set my neutral tilt from whatever position I am already holding the phone in, so that I can play slouched on a train without holding my arms up.
- **Acceptance Criteria:** Calibration captures the current device orientation as `rest pose` regardless of absolute angle. A course is fully playable from any starting hold, including flat-on-a-table and held-at-an-angle.

### US-002: Mid-Run Re-Centre
- **Persona:** P-011 (Maria Rodriguez)
- **Category:** Core Mechanics
- **Priority:** Must
- **Story:** As Maria, I want to re-centre my rest pose with a single tap mid-run without pausing, so that shifting position does not cost me the run.
- **Acceptance Criteria:** A tap anywhere on the playfield re-centres rest pose within one frame. The run clock and car state are unaffected by re-centring.

### US-003: Proportional Tilt-to-Acceleration
- **Persona:** P-008 (David Park)
- **Category:** Core Mechanics
- **Priority:** Must
- **Story:** As David, I want tipping the phone further to produce proportionally more acceleration up to a defined limit, so that I can learn a repeatable input-to-output mapping.
- **Acceptance Criteria:** Acceleration follows `a = TABLE_G · sin(tilt)` up to ±32° full lock. Response is consistent across repeated identical inputs within sensor noise tolerance.

### US-004: Grip-Mediated Lateral Movement
- **Persona:** P-008 (David Park)
- **Category:** Core Mechanics
- **Priority:** Must
- **Story:** As David, I want lateral tilt to move the car across the lane with tyre grip rather than instant translation, so that there is a fast line and a slow line through every corner.
- **Acceptance Criteria:** Lateral velocity bleeds at the tuned grip rate (5.0/s baseline). Exceeding ~70% lateral load transitions the car into a drift state per `../design/mechanics/secondary-mechanics.md`.

### US-005: Never Fully Stuck
- **Persona:** New player (general)
- **Category:** Core Mechanics
- **Priority:** Must
- **Story:** As a new player, I want the car to keep rolling even when I hold the phone perfectly flat, so that I am never stuck and confused.
- **Acceptance Criteria:** A flat-held phone still produces forward progress via track grade (`SLOPE_G · dz/ds`) on any course with a downhill segment. No input state results in a permanently stationary car on a valid course.

### US-006: Time Cost, Not Run-Ending Failure
- **Persona:** P-002 (Sarah Chen)
- **Category:** Core Mechanics
- **Priority:** Must
- **Story:** As Sarah, I want a mistake to cost me time rather than end my run, so that I always reach the finish line.
- **Acceptance Criteria:** No game state exists that ends a run before the finish gate other than the player manually quitting. All hazard contact resolves to a time penalty and/or checkpoint respawn.

### US-007: Learnable Rail Scrub
- **Persona:** P-008 (David Park)
- **Category:** Core Mechanics
- **Priority:** Must
- **Story:** As David, I want rail contact to scrub a consistent, learnable percentage of my speed, so that I can judge whether leaning on a rail through a corner is worth it.
- **Acceptance Criteria:** Rail contact always scrubs 20% of current speed with 34% restitution, regardless of contact angle or approach speed, within physics-step rounding tolerance.

### US-008: Grade Legibility Ahead of Arrival
- **Persona:** Player (general)
- **Category:** Core Mechanics
- **Priority:** Must
- **Story:** As a player, I want to see how steep the track ahead is before I reach it, so that I can pre-load my tilt for the grade change.
- **Acceptance Criteria:** Deck height renders relative to the car's current elevation (`h = BASE + (z − z_camera) · 0.5`), making a grade change visible at least 1.5–2 seconds before the car reaches it at typical course speeds.

### US-009: Boost Strips Off the Natural Line
- **Persona:** P-008 (David Park)
- **Category:** Core Mechanics
- **Priority:** Should
- **Story:** As David, I want boost strips placed off the natural racing line, so that taking them is a decision instead of a freebie.
- **Acceptance Criteria:** No boost strip in any of the 38 shipped courses sits on the geometrically shortest path between adjacent checkpoints. Taking a boost strip always requires a measurable lateral detour.

### US-010: Landing Rewards Control
- **Persona:** Player (general)
- **Category:** Core Mechanics
- **Priority:** Must
- **Story:** As a player, I want going airborne off a ramp to preserve my speed on a clean landing and scrub it on a sideways one, so that jumps reward control.
- **Acceptance Criteria:** A landing within the deck-aligned tolerance window preserves 100% of pre-jump speed. A landing outside that window applies the same speed scrub as a rail clip.

### US-011: Vehicle Mode Motion Filtering
- **Persona:** P-011 (Maria Rodriguez)
- **Category:** Core Mechanics
- **Priority:** Must
- **Story:** As Maria, I want a Vehicle Mode that filters out the low-frequency motion of a moving train, so that the car does not drift while I am sitting still.
- **Acceptance Criteria:** Vehicle Mode applies a 4-second rolling rest-pose average. The mode is offered automatically after telemetry detects sustained low-frequency drift across two consecutive runs.

### US-012: Landscape Axis Remap
- **Persona:** Player (general)
- **Category:** Core Mechanics
- **Priority:** Must
- **Story:** As a player, I want the game to remap tilt axes if I rotate the phone to landscape, so that the controls never invert unexpectedly.
- **Acceptance Criteria:** Pitch and roll are swapped according to the reported screen orientation angle before being fed to the physics layer. Control direction remains consistent (right roll always moves the car right on screen) across all four orientations.
