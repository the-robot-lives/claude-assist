# Timely

**Domain:** timely.noizu.com

## Project Idea

Timely is a precision time-tracking tool for people who do complex, interrupt-driven work. It captures activity in the background, takes periodic screenshots for recall and verification, detects inactivity and resumption, and supports parallel or overlapping tasks instead of forcing real work into a single linear timer.

**Differentiator:** Timely is not just a stopwatch. It is an evidence-backed activity ledger that understands fragmented work: parallel projects, context switches, idle gaps, resumed sessions, and overlapping responsibility windows.

## Core Use Cases

- **Knowledge work tracking** — developers, designers, operators, founders, and consultants can reconstruct how time was actually spent.
- **Client billing** — screenshots, activity metadata, and task history provide audit-friendly support for invoices.
- **Self review** — users can inspect attention patterns, interruptions, and recovery time without manually narrating every switch.
- **Team visibility** — managers can understand workload and focus health without requiring constant status updates.

## Core Features

### 1. Activity Capture

- Periodic screenshots with configurable interval and privacy controls
- Active window, app, URL, and file/context metadata where available
- Keyboard/mouse activity signals without recording sensitive input content
- Local-first buffering for offline or unreliable network periods

### 2. Parallel And Overlapping Tasks

Timely models time as intervals, not a single active stopwatch. A user can:

- Track multiple tasks that overlap in the same time window
- Mark a task as primary while keeping secondary tasks active
- Split, merge, and reassign captured intervals after the fact
- Represent real workflows such as monitoring a deploy while writing code or waiting on a meeting while handling support

### 3. Inactivity Detection

- Detect idle periods from input silence, lock/sleep events, and app focus changes
- Prompt the user to discard, keep, or classify inactive time
- Apply project-specific idle thresholds
- Preserve a clear audit trail of automatic idle adjustments

### 4. Resumption Detection

- Detect when the user returns after inactivity, sleep, travel, or context loss
- Suggest resuming the last task, starting a new task, or splitting the prior interval
- Surface "where was I?" context from the last screenshots, active files, and recent notes
- Track interruption recovery time as a first-class signal

### 5. Timeline Review

- Visual day timeline with screenshots, task lanes, idle blocks, and overlaps
- Fast keyboard-driven correction flow for reclassifying time
- Screenshot gallery filtered by project, task, app, or client
- Daily and weekly summaries with confidence indicators

### 6. Reporting And Export

- Client-ready timesheets with optional screenshot evidence
- CSV, JSON, PDF, and invoice-system exports
- Billable vs non-billable breakdowns
- Project, client, task, app, and interruption analytics

## Privacy Model

Timely should be useful without becoming invasive. The product needs explicit privacy controls from the start:

- Pause tracking globally or per app/domain
- Blur or redact screenshots for sensitive apps
- Local-only screenshot storage option
- User-controlled retention policies
- Clear separation between personal analytics and team-visible reports

## Target Users

### Primary: Independent Consultants And Agencies

People billing across several clients who need defensible records without manually running timers all day.

### Secondary: Software Teams

Developers and operators working across coding, review, meetings, deploys, incidents, and support rotations.

### Tertiary: Founders And Solo Operators

People who need to understand where their day went and which activities are consuming attention.

## MVP Scope

- Desktop capture agent for macOS first
- Web dashboard for timeline review and reports
- Manual task/project/client setup
- Screenshot capture with pause/redaction controls
- Idle detection and resumption prompts
- Overlapping interval model with primary/secondary task classification
- CSV export and simple invoice summary

## Future Features

- AI-assisted task labeling from screenshots and activity context
- Calendar-aware meeting classification
- Git, issue tracker, and project-management integrations
- Team policies for screenshot retention and visibility
- Mobile companion for manual time corrections
- MCP/API interface for agents to query time history and create task annotations

## Design Direction

- **Style:** Calm operational dashboard with dense timeline review
- **Tone:** Trustworthy, private, precise
- **Primary interaction:** Keyboard-friendly timeline correction
- **Visual priority:** Time lanes, overlaps, idle blocks, and screenshot evidence

## Status

In active development, past the concept stage. Product design (personas, user stories, screens, UX brief, roadmap) is complete. A Phoenix + Hologram backend at `apps/backend` implements the domain model, authentication, and a versioned `/api/v1` JSON and offline-sync API; its schema is owned by Liquibase changelogs, not Ecto migrations. Deploy config for timely.noizu.com (build targets, Helm chart, an Infisical Terraform resource) has been written and locally verified, but **nothing has been applied yet** - no image build/push, no `terraform apply`, no `helm upgrade`, no DNS. See `tomorrow.md` for the exact state and the order of operations to bring it up.

The sync protocol - the deterministic, cross-platform name-canonicalization and conflict-resolution rules every client must implement identically - is specified in [docs/SYNC-PROTOCOL.md](docs/SYNC-PROTOCOL.md) and pinned by executable conformance fixtures in [apps/shared/contracts/](apps/shared/contracts/) (`canon-fixtures.json` for name canonicalization, `wire-fixtures.json` for wire-format request/response pairs recorded from the real server). `apps/shared/TimelyKit` (a shared Swift package used by macOS and iOS) and the Android app each implement that contract independently.

Client state varies by surface; see [apps/README.md](apps/README.md) for specifics. In short: the backend's sync API is implemented and tested; TimelyKit, Android, and iOS are all complete and passing their own test suites; the macOS app has been retrofitted onto TimelyKit for sync; the web app and web portal remain early scaffolds/prototypes.

## Key Documents

- [docs/UX-BRIEF.md](docs/UX-BRIEF.md) - Product positioning, UX principles, workflows, and IA summary
- [docs/ROADMAP.md](docs/ROADMAP.md) - Phased product and UX roadmap from design foundation through paid production
- [docs/MACOS-STYLEGUIDE.md](docs/MACOS-STYLEGUIDE.md) - macOS visual system, layout rules, components, and screen UX standards
- [docs/SYNC-PROTOCOL.md](docs/SYNC-PROTOCOL.md) - Normative cross-platform contract: identity, revisions, the push/pull loop, conflict resolution, idempotency, and offline auth
- [apps/shared/contracts/](apps/shared/contracts/) - The OpenAPI wire contract and the executable `canon()`/taxonomy-id conformance fixture every implementation must pass before it syncs
- [apps/](apps/) - macOS, iOS, Android, web app, and web portal client surfaces, the Phoenix backend, and the shared TimelyKit package - see [apps/README.md](apps/README.md) for the state of each
- [design/SITEMAP.md](design/SITEMAP.md) - Route map and overlay/navigation model
- [project-management/personas/](project-management/personas/) - 8 target personas
- [project-management/user-stories/](project-management/user-stories/) - 100 prioritized user stories
- [project-management/screens/](project-management/screens/) - 21 screen definitions
- [project-management/components/](project-management/components/) - 37 reusable component definitions

## App Commands

From this directory:

```bash
make help
make serve
make build-macos
make run-macos
make build-ios
make build-android
make build-web
make local-build
make install
```
