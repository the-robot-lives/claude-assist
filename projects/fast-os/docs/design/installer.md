# fast-os Installer UX

Status: v0.1 · 2026-07-07 · The install experience. Implements [roadmap-distribution.md](../roadmap-distribution.md) D1.b, where the installer is deliberately fast-os's first dogfood of the **staged-effects agent machinery** on a destructive workflow. Design system: Minimal Tech, violet accent, keyboard-complete (consistent with the [shell](shell.md)).

## 1. Principle: the installer is an agent task you can read

Most installers hide what they do behind a progress bar. fast-os's installer is built on the same plan-preview + staged-effects model as the rest of the OS ([security.md](../security.md) §4, [agent-integration.md](../agent-integration.md) §4): before anything destructive happens, it shows you **the exact operations** (partition, format, copy, bootloader) with the disks and capabilities involved, and the whole run is journaled to the flight recorder — so the install log *is* a replayable audit. Trust through transparency, and it exercises the machinery that matters most.

Runs from the live image ([roadmap-distribution.md](../roadmap-distribution.md) D1.a). Fully keyboard-navigable; pointer optional.

## 2. Flow (5 steps, one destructive gate)

```
Welcome → Target → Layout & Redundancy → Review Plan → Install → First Boot
                                          └ the one confirmation gate ┘
```

Progress is a 5-dot thread, not a wizard chrome. Back is always `Esc`; forward is `Enter` on the primary action. Nothing is written until step 4 is approved.

### Step 1 — Welcome
One screen: what fast-os is (one line), detected machine summary (arch, RAM, disks, whether running under Apple Virtualization / QEMU / bare metal), and a language/keymap control. Primary: **Begin**. A quiet secondary: **Try live first** (boot back to the live Scene without installing).

### Step 2 — Target
Lists detected disks as cards (model, size, current contents, health). Select one or several (multi-disk enables redundancy in step 3). Destructive-content disks show a subtle warning chip. If run headless/VM-seeded, this is pre-filled from the cloud-init-class seed and the UI is skippable.

### Step 3 — Layout & Redundancy
This is where fast-os's filesystem shows off ([fastfs-design.md](../fastfs-design.md)). Rather than a partition editor, offer **intent presets**:

- **Simple** — one fastfs pool, single-copy (fastest). Default for one disk.
- **Protected** — `/home` and `/var` get `mirror:2` if ≥2 disks; system stays single-copy. Default when multiple disks present.
- **Custom** — per-directory policy table (the [fastfs](../fastfs-design.md) per-directory RAID feature, surfaced: rows of path → profile → target disks).

Encryption toggle (per-policy-domain keys, Secure-Enclave/TPM-backed) defaults **on**. A live capacity/redundancy summary updates as you choose — no mental math.

### Step 4 — Review Plan (the gate)
The staged-effects preview, verbatim, the way an agent task would present it: the ordered list of operations with their target disks and the capabilities each step exercises, plus a plain-language summary ("Erase 1 disk. Create encrypted fastfs pool. Mirror /home across 2 disks. Install bootloader."). This is the *only* screen that warns, and the primary button is deliberately weighted: **Erase & Install** in accent, with the affected disk named in the button. `Esc` returns to any prior step non-destructively.

### Step 5 — Install → First Boot
Live operation log (the actual journal, streaming) with an honest progress estimate; no fake spinner. On completion: **Restart** (uses the kexec-style warm path where available, [performance-research.md](../performance-research.md) §5). First boot lands in a short **Setup Scene**: create the first principal (passkey-first, [security.md](../security.md) §1.3), pick a starter model for inferd, done — into the live shell.

## 3. Accessibility & keyboard map

WCAG 2.2 AA; keyboard is the primary path, not an accommodation.

| Key | Action |
|---|---|
| `Tab` / `Shift+Tab` | Move between controls |
| `↑ ↓` / `J K` | Move within a list (disks, policy rows) |
| `Space` | Toggle selection / checkbox |
| `Enter` | Primary action for the step |
| `Esc` | Back (never destructive) |
| `⌘/Ctrl + Enter` | Dry-run the plan (step 4) without installing |

Focus ring is the accent at 3:1 contrast; the destructive gate cannot be triggered by a stray `Enter` (requires focus explicitly on the accent button). All status changes announced for screen readers; high-contrast theme available from step 1.

## 4. Novelty budget

90% familiar: a short linear installer with a review-before-write gate is the safe, expected shape (nobody wants a "clever" disk installer). 10% novel and justified: **the review step is a real staged-effects plan preview**, not bespoke installer chrome — it reuses the OS's own approval UI, so users learn the pattern here that governs every agent action later, and the install becomes auditable/replayable for free. The per-directory redundancy presets surface a genuinely new filesystem capability without exposing a partition editor.

See [installer-mockup.svg](installer-mockup.svg) for the Review-Plan gate (the defining screen).
