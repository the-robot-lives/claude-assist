# Graphics & Display Stack

Status: v0.1 · 2026-07-07 · Design for the fast-os GPU kernel layer, display server, and input — plus the agent-native twist (every window is introspectable; the approval UI composites above everything). Fills the "display server + UI toolkit" deferral in [roadmap.md](roadmap.md); lands post-Phase 6.

## 1. Lessons from the field

The Linux stack settled into a proven shape: a kernel layer owning modesetting + GPU command submission (DRM/KMS), userspace drivers (Mesa) producing Vulkan, and compositors speaking a display protocol over zero-copy shared buffers (dma-buf) ([DRM overview](https://en.wikipedia.org/wiki/Direct_Rendering_Manager), [Wayland architecture](https://wayland.freedesktop.org/docs/book/Architecture.html), [high-level design](https://wayland-book.com/introduction/high-level-design.html)). Current direction is unambiguous: Vulkan-first compositors (e.g. [Nourish](https://www.phoronix.com/news/Nourish-Wayland-Compositor)), compositor-as-library (smithay under COSMIC's cosmic-comp; [graphics-stack roundup](https://news.tuxmachines.org/node/140002)), and explicit buffer import via dma-buf + format modifiers ([niri's integration notes](https://deepwiki.com/YaLTeR/niri/6.7-wayland-integration)). We adopt the shape, skip the legacy (no X11, no GL-required path, no implicit sync).

## 2. Kernel layer: `gfx` service (framekernel)

DRM/KMS-equivalent, natively ring-based:

- **Modesetting**: atomic-only (plane/CRTC/connector state committed as one transaction — the KMS lesson, minus the legacy API). Exposed on the Tool Bus like everything else: displays are typed, queryable objects.
- **Command submission**: per-context GPU queues mapped into userspace; submissions are ring entries carrying command-buffer capabilities. The kernel validates ownership/residency, not command contents (Vulkan model).
- **Memory**: GPU buffers are capability objects (`gbuf`) — export/import across processes replaces dma-buf; explicit sync only (timeline semaphores as kernel wait objects, same primitive family as NT-sync waits in [app-compatibility.md](app-compatibility.md) §3).
- **Drivers**: virtio-gpu first (dev loop + tier-3 guests), then one dGPU (likely AMD-class, best-documented) and Apple-class iGPU alongside the ARM64 flagship work. Vendor userspace compilers stay in userspace — kernel TCB never grows for shader compilation.

## 3. Userspace drivers

Vulkan is the only mandated API. Track Mesa's architecture (thin kernel interface + fat userspace) and, pragmatically, port Mesa drivers onto the personality layer early — Mesa-on-linux-personality gives working Vulkan on real GPUs before native drivers exist, the same leverage trick as Wine-on-personality. GL/GLES, if ever, is Zink-style Vulkan layering. Compute (inferd's Vulkan backend) shares the same `gbuf`/queue primitives — graphics and inference contend through one scheduler-visible interface, so token decode and frame deadlines are arbitrated, not fought over.

## 4. Display server: `viewd`

Compositor-as-a-library (smithay lesson), shipped as one default compositor:

- **Protocol**: not a Wayland clone — a Tool Bus interface family (`view.surface`, `view.input`, `view.output`). Zero-copy: clients render with Vulkan into `gbuf`s, attach via ring entry, explicit-sync semaphores gate latching. A `wayland-shim` (personality-side) maps Wayland clients onto it, which is how tier-1 Linux GUI apps and Wine's Vulkan path arrive without native ports.
- **Scheduling**: viewd runs latency-class with a frame-deadline hint per output; direct scanout is the default path for fullscreen/unoccluded surfaces (composition is the exception, not the rule).
- **Agent-native compositing**, the differentiator:
  - Every surface carries its Tool Bus identity — the scene graph is *semantically labeled*. "Click the export button in the invoice app" is a tool call, not pixel archaeology (contrast UFO²'s screenshot parsing).
  - Native-toolkit apps auto-export actions (architecture.md §6); viewd exports the *composition* — what's visible, focused, occluded — as capability-gated queryable state for agents.
  - **Trusted overlay plane**: approval prompts, staged-effect previews ([agent-integration.md](agent-integration.md) §4), and the capability-grant UI composite on a plane no client (or agent) can draw over, screenshot, or synthesize input into. Anti-spoofing is structural, not heuristic.
  - Screen capture/recording and synthetic input are capabilities per surface-set — an agent granted "see the spreadsheet" cannot see the password manager next to it.

## 5. Input & audio (the "etc.")

- **Input**: `inputd` owns HID; events are typed ring streams routed by viewd focus. Synthetic input requires a distinct capability, always visibly indicated on the trusted overlay. Input never transits the agent layer by default — keylogging isn't a grantable ambient.
- **Audio**: `audiod`, PipeWire-shaped (graph of typed nodes on the Tool Bus, latency-class scheduling for capture/playback). Same capability story: apps get endpoints, not the graph; agents see the graph read-only unless granted routing authority.

## 6. Sequencing

| Step | Depends on | Delivers |
|---|---|---|
| G1: virtio-gpu + gfx service + headless Vulkan | Phase 4 GPU backend work | inferd Vulkan backend, CI rendering tests |
| G2: viewd v0 + native toolkit seed + trusted overlay | G1, Phase 5 staged effects | graphical fsh, approval UI on hardware plane |
| G3: wayland-shim + Mesa-on-personality | G2, personality maturity | tier-1 Linux GUI apps |
| G4: dGPU/iGPU native drivers, Wine Vulkan path | G3, Phase 6 ARM64 | real hardware, Windows GUI tier |

Sources: [DRM (Wikipedia)](https://en.wikipedia.org/wiki/Direct_Rendering_Manager) · [Wayland architecture](https://wayland.freedesktop.org/docs/book/Architecture.html) · [Wayland high-level design](https://wayland-book.com/introduction/high-level-design.html) · [Nourish Vulkan compositor](https://www.phoronix.com/news/Nourish-Wayland-Compositor) · [niri Wayland integration](https://deepwiki.com/YaLTeR/niri/6.7-wayland-integration) · [smithay/COSMIC + graphics stack](https://news.tuxmachines.org/node/140002)
