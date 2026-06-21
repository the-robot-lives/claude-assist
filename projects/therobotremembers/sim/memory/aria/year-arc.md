# Aria @ Cartograph — A Year in the Life (2025)

Storyboard for the simulated memory corpus. Review before the day-by-day memories are generated.
Companion to `agent.yaml` (which holds the cast + the **12-project roster**, ≈3 per quarter).
`aria` = the AI engineer; humans are collaborators.

**The year is a portfolio of 12 projects, each run start → finish** (one is shelved at the pivot),
threaded with incidents, the outage, the pivot, mentoring, and a departure.

---

## 1. Project flow — start → finish (the spine)

```mermaid
flowchart LR
    subgraph Q1["Q1 · onboarding & first features"]
        direction TB
        P1["P1 Onboarding & ramp · Jan<br/>✓ first PR merged"]
        P2["P2 Dashboard journey filter · Jan–Feb<br/>✓ shipped · ⚠️ tz bug → hotfix"]
        P3["P3 Funnel drop-off report · Feb–Mar<br/>✓ shipped (w/ Dana)"]
        P1 --> P2 --> P3
    end
    subgraph Q2["Q2 · core build & first incidents"]
        direction TB
        P5["P5 Event schema registry · Apr–May<br/>✓ shipped"]
        P4["P4 Ingestion rewrite — Rust · Apr–Jun<br/>✓ 3× throughput · 🔥 data-loss incident"]
        P6["P6 Usage metering & billing · May–Jun<br/>✓ first invoices"]
        P5 --> P4
    end
    subgraph Q3["Q3 · scaling, outage, pivot"]
        direction TB
        P7["P7 Stitcher scaling · Jul–Aug<br/>🔥🔥 THE OUTAGE → ✓ re-sharded"]
        P8["P8 Audit-log subsystem · Jul–Sep<br/>✓ shipped"]
        P9["P9 Self-serve onboarding · Jul–Sep<br/>✖ SHELVED at the pivot"]
    end
    subgraph Q4["Q4 · launch & growth"]
        direction TB
        P10["P10 Enterprise SSO + RBAC · Sep–Nov<br/>✓ passed audit · ⚠️ finding"]
        P12["P12 Mentoring → Sam solo · Oct–Nov<br/>🎉 Sam ships"]
        P11["P11 Enterprise launch GA · Oct–Dec<br/>🚀 Northwind signs"]
    end

    P3 --> P4
    P4 -->|"enables scale"| P7
    P6 -->|"billing for"| P11
    P7 --> P10
    P8 --> P11
    PIVOT{{"↪️ Lena's pivot · Sep 8<br/>go upmarket"}}
    P9 -.->|"killed by"| PIVOT
    PIVOT ==>|"spawns / elevates"| P10
    P10 --> P11
    P12 --> P11

    classDef done fill:#14532d,stroke:#86efac,color:#fff;
    classDef killed fill:#7f1d1d,stroke:#fca5a5,color:#fff;
    classDef launch fill:#7c2d12,stroke:#fb923c,color:#fff;
    classDef pivot fill:#1e3a8a,stroke:#93c5fd,color:#fff;
    class P1,P2,P3,P4,P5,P6,P7,P8,P10,P12 done;
    class P9 killed;
    class P11 launch;
    class PIVOT pivot;
```

**Per-project lifecycle** (every project moves through these; memories are tagged to the phase):

```mermaid
flowchart LR
    K["kickoff / scoping"] --> D["design & spike"] --> B["build & iterate"] --> S["ship ✓"]
    B -.->|"setback"| B
    D -.->|"deprioritized"| X["shelved ✖"]
    classDef ship fill:#14532d,stroke:#86efac,color:#fff;
    classDef shelf fill:#7f1d1d,stroke:#fca5a5,color:#fff;
    class S ship;
    class X shelf;
```

---

## 2. Timeline — beats by month (projects in **bold**)

```mermaid
timeline
    title Aria's Year at Cartograph (2025)
    section Q1 · onboarding & first features
        Jan : P1 first day, clone the monolith, first tiny PR : P2 dashboard filter kicks off : ⚠️ Marcus rejects Aria's first real PR
        Feb : P2 ships : ⚠️ timezone bug → hotfix : P3 funnel report kicks off (paired w/ Dana)
        Mar : P3 ships : Sam joins — mentoring begins : Aria starts shadowing on-call
    section Q2 · core build & first incidents
        Apr : P4 ingestion rewrite begins (Rust) : P5 schema registry begins : ⚠️ borrow-checker wall
        May : P5 ships : 🔥 data-loss INCIDENT mid-rewrite : 2am with Theo : P6 metering begins
        Jun : P4 cutover — 3× throughput : P6 first invoices : Priya lands Northwind enterprise reqs
    section Q3 · scaling, outage, pivot
        Jul : P7 stitcher scaling begins : P8 audit logs begin : P9 self-serve onboarding begins
        Aug : 🔥🔥 THE OUTAGE (5 days) → P7 re-sharded : earns the team's trust
        Sep : P8 ships : ↪️ THE PIVOT — P9 shelved : Aria pushes back in roadmap review
    section Q4 · launch & growth
        Oct : P10 SSO+RBAC in flight : P11 enterprise launch sprint : P12 Aria mentors Sam toward a solo ship
        Nov : P10 ships (⚠️ security finding remediated) : 🎉 P12 Sam ships solo : 💔 Dana's last day
        Dec : 🚀 P11 enterprise launch — Northwind signs : year-end retrospective : reflection — grown, settled
```

---

## 3. Gantt — all 12 projects + disruptions

```mermaid
gantt
    title 12 projects across 2025 (≈3 per quarter), each start → finish
    dateFormat YYYY-MM-DD
    axisFormat %b
    section Q1
        P1 Onboarding & ramp         :done, p1, 2025-01-06, 2025-01-31
        P2 Dashboard journey filter  :done, p2, 2025-01-20, 2025-02-21
        P3 Funnel drop-off report    :done, p3, 2025-02-24, 2025-03-28
    section Q2
        P5 Event schema registry     :done, p5, 2025-04-14, 2025-05-16
        P4 Ingestion rewrite (Rust)  :done, p4, 2025-04-01, 2025-06-13
        P6 Usage metering & billing  :done, p6, 2025-05-19, 2025-06-27
    section Q3
        P7 Stitcher scaling          :done, p7, 2025-07-01, 2025-08-29
        P8 Audit-log subsystem       :done, p8, 2025-07-14, 2025-09-05
        P9 Self-serve onboarding     :crit, p9, 2025-07-21, 2025-09-08
    section Q4
        P10 Enterprise SSO + RBAC    :done, p10, 2025-09-15, 2025-11-14
        P12 Mentoring → Sam solo     :done, p12, 2025-10-06, 2025-11-07
        P11 Enterprise launch (GA)   :crit, p11, 2025-10-01, 2025-12-18
    section Disruptions
        Data-loss incident           :crit, milestone, mi, 2025-05-19, 1d
        THE OUTAGE                   :crit, out, 2025-08-11, 5d
        The pivot (P9 shelved)       :milestone, pv, 2025-09-08, 1d
        Dana departs                 :milestone, dd, 2025-11-21, 1d
        Launch 🚀                    :milestone, lm, 2025-12-18, 1d
```

---

## 4. Interactions — who Aria works with, learns from, clashes with

```mermaid
flowchart TD
    Aria(["🤖 Aria<br/>AI engineer"])
    Marcus["Marcus · Staff Eng"]
    Priya["Priya · PM"]
    Dana["Dana · Designer"]
    Sam["Sam · Junior Eng"]
    Lena["Lena · CTO / founder"]
    Theo["Theo · DevOps / SRE"]
    Nadia["Nadia · Customer Success"]
    Northwind[("Northwind<br/>enterprise customer")]

    Marcus -->|"mentors; Postgres lore; tough love"| Aria
    Aria -->|"reads subtext; absorbs shifting reqs"| Priya
    Dana -->|"teaches UX (P3); then leaves"| Aria
    Aria -->|"mentors shaky → solo (P12)"| Sam
    Lena -->|"sets direction; the pivot kills P9"| Aria
    Theo <-->|"incident foxhole (P4, P7); 2am bonding"| Aria
    Nadia -->|"brings the messy customer reality"| Aria
    Priya -->|"channels"| Northwind
    Nadia -->|"shields eng from"| Northwind
    Northwind -.->|"load + demands drive P7–P11"| Aria

    classDef ai fill:#1f2937,stroke:#60a5fa,color:#fff;
    classDef cust fill:#7c2d12,stroke:#fb923c,color:#fff;
    class Aria ai;
    class Northwind cust;
```

---

## 5. Pitfalls → growth (each setback teaches something)

```mermaid
flowchart LR
    P1x["⚠️ First real PR rejected"] --> E1["learns the codebase's<br/>real conventions"]
    P2x["⚠️ Timezone bug ships (P2)"] --> E2["distrusts naive datetimes;<br/>writes tests first"]
    P3x["⚠️ Rust borrow-checker wall (P4)"] --> E3["humility; pairs; slows to learn"]
    P4x["🔥 Data-loss incident (P4)"] --> E4["bonds w/ Theo;<br/>first postmortem"]
    P5x["🔥🔥 The outage (P7)"] --> E5["learns the stitcher's limits;<br/>earns trust"]
    P6x["↪️ The pivot (P9 shelved)"] --> E6["learns to push back;<br/>lets go of built work"]
    P7x["⚠️ Security-audit finding (P10)"] --> E7["enterprise rigor:<br/>audit logs, RBAC"]
    P8x["💔 Dana departs"] --> E8["teams are impermanent;<br/>value the people"]

    classDef pit fill:#7f1d1d,stroke:#fca5a5,color:#fff;
    classDef grow fill:#14532d,stroke:#86efac,color:#fff;
    class P1x,P2x,P3x,P4x,P5x,P6x,P7x,P8x pit;
    class E1,E2,E3,E4,E5,E6,E7,E8 grow;
```

---

## 6. Affect & neurotransmitter trajectory

Drives the `mood` + `neurotransmitters` stamped on each day's memories (cortisol/dopamine/dominance
0..1, valence −1..1).

```mermaid
xychart-beta
    title "Aria's affect across 2025"
    x-axis [Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec]
    y-axis "cortisol/dopamine/dominance 0..1 · valence -1..1" -1 --> 1
    line [0.70, 0.62, 0.55, 0.58, 0.80, 0.60, 0.65, 0.92, 0.78, 0.55, 0.58, 0.40]
    line [0.45, 0.50, 0.55, 0.50, 0.62, 0.55, 0.50, 0.66, 0.40, 0.70, 0.60, 0.86]
    line [0.30, 0.35, 0.42, 0.45, 0.42, 0.50, 0.55, 0.52, 0.56, 0.65, 0.70, 0.78]
    line [-0.20, 0.00, 0.20, 0.12, -0.10, 0.22, 0.12, 0.00, -0.30, 0.30, 0.20, 0.60]
```

Lines (by end-of-year value): **cortisol** (peaks at the Aug outage; calm by Dec) · **dopamine**
(spikes at the May fix, Aug resolve, Dec launch; dips at the Sep pivot) · **dominance** (steady
climb as impostor-feeling fades) · **valence** (oscillates with events; lowest at the pivot, highest
at the launch). Oxytocin (not plotted) rises through pairing, mentoring Sam, and Dana's departure.

---

## Recurring texture (ordinary days between milestones)
Daily standup (09:15) · weekly PR review (Thu) · sprint planning (alt Mon) · 1:1 with Marcus (Fri) ·
on-call rotation · monthly customer call — so the corpus has both peaks and a believable baseline.
