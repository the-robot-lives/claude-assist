# Carpet Grand Prix — User Stories: Progression (US-013 – US-020)

### US-013: Four Medal Tiers, Top Set by Developer Time
- **Persona:** P-008 (David Park)
- **Category:** Progression
- **Priority:** Must
- **Story:** As David, I want four medal tiers per course with the top tier set by developer times, so that there is a ceiling worth chasing after gold.
- **Acceptance Criteria:** Every course exposes Bronze, Silver, Gold and Sprue thresholds per the multiplier rule in `../design/meta-loop.md`. Sprue times are set by a developer reference run, not a formula alone.

### US-014: Personal-Best Ghost
- **Persona:** P-008 (David Park)
- **Category:** Progression
- **Priority:** Must
- **Story:** As David, I want a ghost car replaying my personal best, so that I can see exactly where I am losing time.
- **Acceptance Criteria:** The ghost is overwritten immediately on any new personal-best finish. Ghost playback is available from the course-select card without starting a new run.

### US-015: Ghost Renders at Correct Diorama Height
- **Persona:** P-008 (David Park)
- **Category:** Progression
- **Priority:** Must
- **Story:** As David, I want the ghost to render at its correct height in the diorama, so that I can see it take a different line over elevated sections.
- **Acceptance Criteria:** The ghost car uses the same viewpoint-height parallax formula as the live car. On any course with a ramp or grade change, a ghost line that differs in elevation from the live car is visibly separated on screen.

### US-016: Rooms Unlock on Total Medals
- **Persona:** P-002 (Sarah Chen)
- **Category:** Progression
- **Priority:** Must
- **Story:** As Sarah, I want rooms to unlock on total medals rather than gold medals, so that steady play keeps opening new content.
- **Acceptance Criteria:** Room-gate thresholds (4/10/18/26/34/44 cumulative medals, 38 golds or 60 total for The Box) count any medal tier. A player earning only bronze medals can unlock every room.

### US-017: Genuinely Different Car Handling
- **Persona:** Player (general)
- **Category:** Progression
- **Priority:** Must
- **Story:** As a player, I want cars to have genuinely different handling rather than strictly better stats, so that choosing a car is a tactical decision per course.
- **Acceptance Criteria:** No car in the 8 handling classes dominates every course on measured gold-time comparisons. At minimum one course exists where each handling class produces a top-3 result.

### US-018: No Energy Meter, Currency, or Daily Reset
- **Persona:** P-002 (Sarah Chen)
- **Category:** Progression
- **Priority:** Must
- **Story:** As Sarah, I want no energy meter, currency, or daily reset, so that I can play for four minutes or forty without being managed.
- **Acceptance Criteria:** No system in the game gates play by elapsed real time, daily login, or a spendable resource. See `../design/economy/README.md` for the full no-economy rationale.

### US-019: Single Completion Percentage
- **Persona:** P-008 (David Park)
- **Category:** Progression
- **Priority:** Should
- **Story:** As David, I want a single completion percentage visible from the main menu, so that I know exactly what is left.
- **Acceptance Criteria:** The main menu displays one aggregate completion number derived from medals earned across all 38 courses. Tapping it breaks the number down by room.

### US-020: On-Device Progress Storage
- **Persona:** Player (general)
- **Category:** Progression
- **Priority:** Must
- **Story:** As a player, I want my times stored on-device and never lost to a server outage, so that my progress is genuinely mine.
- **Acceptance Criteria:** All times, medals, ghosts and unlocks persist entirely on-device with no server dependency for gameplay or save data. No feature in the base game requires network connectivity.
