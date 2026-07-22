# TRD macOS/Unity — Navigation & Chrome Redesign (Clean-Room)

## Mandate
Design the menu bar, toolbars, and navigation chrome for TheRobotDrafts (Unity 6, macOS)
**from scratch**. The current in-app arrangement is deliberately not consulted — capabilities
were cataloged by scouts under a clean-room guard (what the app does, never how its UI is
currently organized).

## Process
1. Capability catalog (subagent recon, clean-room guard)
2. Information architecture: command taxonomy → menus / toolbars / contexts
3. Visual exploration: Gemini (nano-banana) image prompts for layout concepts, iterate
4. HTML/Next.js demo pages of the winning direction, iterate to satisfaction
5. Operator walkthrough → then apply to the real app together

## Design direction
- **Style**: Nocturne-dominant (dark-native professional instrument — creative tools default)
  with Minimal Tech accents (80/20). One accent hue; restraint elsewhere.
- **Platform grammar**: macOS menu-bar conventions (App / File / Edit / View / … / Window / Help)
  fused with a Unity-style editor shell (dockable panels, verb rails, contextual toolbars).
- **Principles applied**: restraint by default; 90% convention 10% novelty; keyboard-first
  parity for every menu command; progressive disclosure (novice sees little, expert unlocks);
  every mode change visibly announced.

## Constraints
- 3D-first: flat diagrams are projections/exports, never the primary surface.
- Must scale from a single class diagram to multi-model, multi-diagram enterprise workspaces.
- Mouse + keyboard primary; VR-ready verbs must not depend on hover.
- Menu text must remain meaningful when screen-reader spoken.

## Deliverables
- `CAPABILITIES.md` — scout catalog (input)
- `IA.md` — command taxonomy, menu tree, toolbar specs, shortcut map
- `prompts/*.md` + `renders/` — Gemini image prompts and generated concepts
- `demo/` — HTML demo pages of final direction
- Walkthrough artifact for operator review
