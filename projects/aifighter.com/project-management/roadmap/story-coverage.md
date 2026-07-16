# Story Coverage & Traceability Matrix

Every one of AI Fighter's 100 user stories is assigned to exactly one primary milestone/lane
(see [`00-overview.md`](00-overview.md)). A story appears in **Notes** when a second lane
materially supports it — the only kind of duplication this matrix records.

**Coverage: 100/100 (100%).** All stories are roadmapped; none are deliberately excluded.

Count check: M0=15, M1=20, M2=16, M3=25, M4=24 → 100.

## M0 — Foundation: Graph Studio & Battle Engine

| US-ID | Title | Priority | Epic | Lane | Notes |
|---|---|---|---|---|---|
| US-001 | Access 20+ Node Types in the Graph Editor | Must | Graph Editor | L0.A Graph Contract | |
| US-002 | See Why Each Fighter Choice Was Made | Must | Graph Editor | L0.B Fighter Studio | L0.C engine emits the decision trace it renders |
| US-003 | Share Fighter Builds Without Revealing Core Logic | Must | Graph Editor | L0.A Graph Contract | obfuscation flag in the export format |
| US-005 | Reach Top Rank Without Spending Money | Must | Graph Editor | L0.C Battle Engine | fairness: graph-only resolution |
| US-006 | Save and Restore Previous Fighter Graph Versions | Should | Graph Editor | L0.B Fighter Studio | |
| US-015 | Search Nodes by Name or Function While Editing | Must | Graph Editor | L0.B Fighter Studio | |
| US-017 | Export My Fighter Graph as a File and Import on Any Device | Should | Graph Editor | L0.A Graph Contract | |
| US-020 | Use the App Comfortably With Color Vision Deficiency | Should | Graph Editor | L0.D Design-System | baseline color tokens |
| US-061 | Async Battle Resolution | Must | Async & Family | L0.C Battle Engine | |
| US-062 | Session-Resumable Fighter Studio | Must | Async & Family | L0.B Fighter Studio | |
| US-064 | No Energy System or Daily Streak | Must | Async & Family | L0.C Battle Engine | fairness baseline |
| US-071 | Non-Color State Indicators on Graph Nodes | Must | Accessibility | L0.D Design-System | baseline a11y contract |
| US-073 | 48px Minimum Touch Targets | Must | Accessibility | L0.D Design-System | baseline a11y contract |
| US-074 | Reduced Motion Support | Must | Accessibility | L0.D Design-System | baseline a11y contract |
| US-087 | Manual Node Positioning in the Graph Editor | Must | Graph Viz | L0.B Fighter Studio | core editor interaction |

## M1 — Core Play Loop

| US-ID | Title | Priority | Epic | Lane | Notes |
|---|---|---|---|---|---|
| US-008 | Complete a Guided Tutorial That Ends With a Working Fighter | Must | Onboarding | L1.A Onboarding | |
| US-009 | Browse and Deploy Competitive Starter Templates | Must | Onboarding | L1.A Onboarding | |
| US-012 | Receive Specific Tips After Losing a Match | Must | Onboarding | L1.A Onboarding | |
| US-014 | Submit My Fighter and Get Notified When the Battle Resolves | Must | Onboarding | L1.A Onboarding | notification via L1.C |
| US-016 | Understand Why I Was Matched Against This Opponent | Should | Graph Editor | L1.B Arena & Replay | L1.C supplies the match reason |
| US-018 | Complete a Daily Challenge to Earn Bonus Resources | Should | Onboarding | L1.A Onboarding | |
| US-021 | Replay Bookmark and Annotation | Should | Replay & Community | L1.B Arena & Replay | |
| US-022 | Decision Overlay Toggle and Filtering | Must | Replay & Community | L1.B Arena & Replay | renders the M0 decision trace |
| US-023 | Build Metadata Stats Panel | Should | Replay & Community | L1.B Arena & Replay | |
| US-034 | Replay Playback Speed and Frame Step Controls | Must | Replay & Community | L1.B Arena & Replay | |
| US-041 | Ranked Leaderboard with Percentile Breakdown | Must | Ranked Arena | L1.C Matchmaking | |
| US-042 | Multiple Fighter Slot Management | Must | Ranked Arena | L1.C Matchmaking | |
| US-043 | Fast Async Match Resolution with Notification | Must | Ranked Arena | L1.C Matchmaking | |
| US-044 | Anti-Smurf Matchmaking Detection | Should | Ranked Arena | L1.C Matchmaking | |
| US-047 | Per-Match Detailed Stat Breakdown | Should | Ranked Arena | L1.C Matchmaking | |
| US-049 | Fighter Win-Rate Breakdown by Opponent Tier | Could | Ranked Arena | L1.C Matchmaking | |
| US-050 | Ranked Queue Status and Wait Time Estimate | Must | Ranked Arena | L1.C Matchmaking | |
| US-063 | Quick-Tweak Suggestion Card | Must | Async & Family | L1.A Onboarding | closes the loop back to the editor |
| US-065 | Frequency-Aware Matchmaking | Should | Async & Family | L1.C Matchmaking | |
| US-067 | Glanceable Battle Summary | Must | Async & Family | L1.B Arena & Replay | |

## M2 — Training, Evolution & Research

| US-ID | Title | Priority | Epic | Lane | Notes |
|---|---|---|---|---|---|
| US-004 | Review Node Activation Heatmaps After a Match | Should | Graph Editor | L2.A Training Gym | |
| US-007 | Choose Specific Sparring Partners in the Training Gym | Should | Graph Editor | L2.A Training Gym | |
| US-019 | Read Patch Notes That Highlight Changes Affecting My Builds | Could | Graph Editor | L2.C Analytics & Balance | |
| US-045 | Balance Patch Preview and Changelogs | Should | Ranked Arena | L2.C Analytics & Balance | |
| US-046 | Replay Export for Content Creation | Should | Ranked Arena | L2.C Analytics & Balance | |
| US-048 | Season End Reward Summary and Historical Archive | Could | Ranked Arena | L2.C Analytics & Balance | |
| US-051 | Training Run Seed and Reproducibility Control | Must | Training & Research | L2.B Training Backend | |
| US-052 | Loss Curve and Weight Update Visualization | Must | Training & Research | L2.A Training Gym | |
| US-053 | JSON Graph Export with Full Training History | Must | Training & Research | L2.B Training Backend | |
| US-054 | Honest AI Model Documentation | Must | Training & Research | L2.C Analytics & Balance | |
| US-055 | Sparring Partner Configuration for Controlled Experiments | Must | Training & Research | L2.A Training Gym | |
| US-056 | Batch Training Run Scheduling | Should | Training & Research | L2.B Training Backend | |
| US-057 | Behavioral Analytics Diff Between Training Runs | Should | Training & Research | L2.B Training Backend | |
| US-058 | Graph Version Control with Rollback | Should | Training & Research | L2.B Training Backend | |
| US-059 | Training Data Export for External Analysis | Could | Training & Research | L2.B Training Backend | |
| US-060 | Public Research Profile and Lab Sharing Attribution | Could | Training & Research | L2.B Training Backend | |

## M3 — Community, Creation & Visualization

| US-ID | Title | Priority | Epic | Lane | Notes |
|---|---|---|---|---|---|
| US-010 | Share a Highlight Clip to Social Media in One Tap | Should | Onboarding | L3.A Lab & Community | |
| US-024 | Replay Theater — Curated Community Feed | Should | Replay & Community | L3.A Lab & Community | L4.B moderation supports feed review (P-011) |
| US-025 | Build Guide Authoring and Publishing | Should | Replay & Community | L3.A Lab & Community | |
| US-026 | Screenshot Export with UI Skin Options | Could | Replay & Community | L3.A Lab & Community | |
| US-027 | Tier List Builder Tool | Could | Replay & Community | L3.A Lab & Community | |
| US-037 | Archetype Comparison Side-by-Side View | Could | Replay & Community | L3.A Lab & Community | |
| US-039 | Replay Share Link with Decision Overlay Preset | Should | Replay & Community | L3.A Lab & Community | |
| US-081 | MP4 Replay Export with Decision Overlay | Must | Creator & Streaming | L3.C Creator Tools | |
| US-082 | Theater Mode for Clean On-Screen Recording | Must | Creator & Streaming | L3.C Creator Tools | |
| US-083 | Training Time-Lapse Export | Should | Creator & Streaming | L3.C Creator Tools | |
| US-084 | Creator Affiliate Program Enrollment | Should | Creator & Streaming | L3.C Creator Tools | |
| US-085 | Tournament Bracket Mode | Should | Creator & Streaming | L3.C Creator Tools | |
| US-088 | High-Resolution Graph Export (SVG and PNG) | Must | Graph Viz | L3.B Graph Visualization | |
| US-089 | Graph Color Theme Cosmetics | Must | Graph Viz | L3.B Graph Visualization | |
| US-090 | Gallery Feature for Graph Visualization Sharing | Should | Graph Viz | L3.B Graph Visualization | |
| US-091 | Training Heatmap as Downloadable Art Print | Could | Graph Viz | L3.B Graph Visualization | |
| US-092 | Replay Sharing with Embedded Decision Overlay Links | Should | Creator & Streaming | L3.C Creator Tools | |
| US-093 | Graph Alignment and Distribution Tools | Should | Graph Viz | L3.B Graph Visualization | |
| US-094 | Streamer Dashboard with Viewer-Facing Stats | Should | Creator & Streaming | L3.C Creator Tools | |
| US-095 | Performance Curve Animation Export | Could | Graph Viz | L3.B Graph Visualization | |
| US-096 | Live Decision Overlay Commentary Mode | Could | Creator & Streaming | L3.C Creator Tools | |
| US-097 | Graph Versioning and Visual Diff | Should | Graph Viz | L3.B Graph Visualization | builds on M2 graph version control |
| US-098 | Featured Graph Spotlight in Laboratory | Could | Graph Viz | L3.B Graph Visualization | |
| US-099 | Tournament Bracket Embed for External Streams | Should | Creator & Streaming | L3.C Creator Tools | |
| US-100 | Node Annotation Labels for Graph Storytelling | Should | Graph Viz | L3.B Graph Visualization | |

## M4 — Education, Family, Accessibility & Launch Readiness

| US-ID | Title | Priority | Epic | Lane | Notes |
|---|---|---|---|---|---|
| US-011 | Earn Exclusive Cosmetics by Climbing the Seasonal Ladder | Should | Onboarding | L4.D Launch Readiness | |
| US-013 | Join a Clan and Access Shared Build Resources | Could | Onboarding | L4.D Launch Readiness | |
| US-028 | Classroom Sandbox Mode | Must | Classroom | L4.A Classroom | |
| US-029 | Student Account COPPA Safeguards | Must | Classroom | L4.A Classroom | |
| US-030 | Training Data Export for Coursework | Must | Classroom | L4.A Classroom | |
| US-031 | Node Concept Glossary Integration | Should | Classroom | L4.A Classroom | |
| US-032 | Lesson Plan Template Library | Should | Classroom | L4.A Classroom | |
| US-033 | Student Tournament Bracket | Should | Classroom | L4.A Classroom | |
| US-035 | Content Moderation — Build and Guide Flagging | Must | Classroom | L4.B Safety & Moderation | moderator persona P-011 |
| US-036 | Safe Mode Content Filter for Classrooms | Must | Classroom | L4.B Safety & Moderation | |
| US-038 | Free Tier Full Feature Access for Education | Must | Classroom | L4.A Classroom | |
| US-040 | Training Analytics Heatmap Export for Assignments | Should | Classroom | L4.A Classroom | |
| US-066 | Family-Friendly Content Mode | Should | Async & Family | L4.B Safety & Moderation | moderator persona P-011 |
| US-068 | Shared Fighter Viewing for Co-Play | Could | Async & Family | L4.B Safety & Moderation | |
| US-069 | VoiceOver Live Regions for Battle State | Must | Accessibility | L4.C Accessibility | |
| US-070 | List-Based Node Connection Interface | Must | Accessibility | L4.C Accessibility | alternative editor input model |
| US-072 | Switch Control Full-App Navigation | Must | Accessibility | L4.C Accessibility | |
| US-075 | Semantic Screen Reader Labels on Graph Nodes | Must | Accessibility | L4.C Accessibility | |
| US-076 | Accessible Post-Battle Insight Report | Should | Accessibility | L4.C Accessibility | |
| US-077 | No-FOMO Tournament Structure | Should | Async & Family | L4.D Launch Readiness | |
| US-078 | VoiceOver-Navigable Fighter Template Gallery | Should | Accessibility | L4.C Accessibility | |
| US-079 | Content Moderation Queue for Community Cosmetics | Should | Async & Family | L4.B Safety & Moderation | moderator persona P-011 |
| US-080 | Haptic-Only Battle Feedback Option | Could | Accessibility | L4.C Accessibility | |
| US-086 | Early Access Preview for Creators | Could | Creator & Streaming | L4.D Launch Readiness | |

## Epic → milestone summary

| Epic | Milestone(s) |
|---|---|
| Graph Editor & Fighter Studio | M0, M1, M2 |
| Onboarding & Templates | M1, M3, M4 |
| Replay Theater & Community | M1, M3 |
| Classroom & Education Tools | M4 |
| Ranked Arena & Competition | M1, M2 |
| Training Analytics & Research | M2 |
| Async Play & Family Mode | M0, M1, M4 |
| Accessibility | M0, M4 |
| Creator & Streaming Tools | M3, M4 |
| Graph Visualization & Customization | M0, M3 |
