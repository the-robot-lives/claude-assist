# Carpet Grand Prix — Player Journey: P-018 (Rachel Green)

**Persona:** The Accessibility User
**Focus:** Non-visual play via Audio Course Mode, honest scope communication

## First-session journey

| Step | What she does | What she feels | Design response |
|---|---|---|---|
| 1. Discovery | Reads the store page with VoiceOver before downloading, specifically looking for an accessibility statement | Cautious — most "accessible" claims on the store are overstated | The store page states plainly which 14 of 38 courses are audio-playable, not a blanket claim |
| 2. Install & first navigation | Opens the app; VoiceOver reads menu items, course cards, medal states and times aloud | Relief that basic navigation works before she even starts a run | Every menu, course card, medal state and time is VoiceOver-labelled — not an afterthought pass |
| 3. Switches to Audio Course Mode | Finds and enables the mode from a clearly labelled settings toggle | Cautious optimism | Audio Mode is a first-class mode, not a hidden accessibility flag |
| 4. First run in Audio Mode | Plays a Playroom course; lane position pans in stereo, distance-to-rail is a rising tick rate in the corresponding ear | Concentration — learning a new sensory vocabulary in real time | Three independently mixable audio channels (pan, tick rate, engine pitch) are tuned specifically not to collapse into noise |
| 5. First corner | Hears a directional chime 1.5 seconds before a turn and reacts in time | A genuine "I can actually do this" moment | The 1.5s lead time on corner chimes is set to match average reaction time for a first-time audio player, not an expert one |
| 6. Grade by ear | Notices engine pitch rising on a descent, mirroring how sighted players read parallax height | Satisfaction that grade legibility has a true non-visual equivalent, not a downgraded one | Grade-as-engine-pitch is the direct audio analogue to the parallax-height cue in the primary mechanic |
| 7. Clears Playroom and Hallway | Finishes both rooms — wide lanes, no open edges — earning bronze and silver medals | Accomplishment | These two rooms are the widest, most forgiving lane widths in the game (`../design/mechanics/difficulty-progression.md`) |
| 8. Approaches the Basement | Checks the course list and sees the Basement's courses are not marked audio-playable | Disappointment, but not betrayal | The game never oversold the Basement; the per-course list told her in advance |
| 9. Settles into her actual playable scope | Continues replaying and improving her times on the 14 audio-playable courses rather than pushing further | Contentment with an honestly scoped subset of the game | The design explicitly treats "she cares more that we said which ones than that the number is 14" as success, not a compromise to apologize for |

## What retains her

**Honesty about scope, paired with a genuinely deep non-visual version of the core loop.**
Audio Course Mode is not a stripped-down accommodation — lane position, rail proximity,
grade, and corner timing all have real, information-equivalent audio channels, so the 14
playable courses offer the same three-layer mastery ceiling (`../design/core-loop.md`)
that sighted players get on all 38. She keeps playing because the subset she has is
complete, not because she is waiting for more to become playable.

## Where she drops off

She never attempts the Basement or any other course outside the audio-playable list —
this is not a drop-off in the churn sense, it is a boundary the game drew for her
honestly at the store page, before purchase. Her actual risk of disengagement is a future
content update (a new room, a new hazard verb) shipping without an accompanying
accessibility audit; the independent accessibility audit before launch (see production
docs) and the plan to repeat that audit for future content are what keep her trust intact
past the first session.
