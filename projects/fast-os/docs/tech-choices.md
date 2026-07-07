# fast-os Technology Choice Matrix

Status: draft v0.1 · 2026-07-07. Decisions with ✅ have ADRs; others are leading candidates.

| Area | Choice | Alternatives considered | Rationale |
|---|---|---|---|
| Language | ✅ Rust (nightly, `no_std` kernel) | Zig, C, C++ | Memory safety enables framekernel; mature bare-metal ecosystem; ADR-0001 |
| Kernel architecture | ✅ Framekernel | Microkernel (seL4-style), monolithic, unikernel | Monolithic speed + language-enforced isolation; validated by Asterinas; ADR-0002 |
| Syscall interface | ✅ Async SQ/CQ rings primary | Trap-per-call, VDSO fast paths | Mode-switch cost dominates agent workloads; ADR-0003 |
| Security model | ✅ Object capabilities | POSIX DAC, SELinux-style MAC | Attenuable/revocable/auditable = safe autonomous agents; ADR-0004 |
| Inference placement | ✅ Userspace tier-0 service (inferd) | In-kernel inference, per-app libraries | Kernel stays small; shared residency; swappable backends; ADR-0005 |
| Bootloader | Limine | Custom UEFI app, GRUB | Modern protocol, both arches, minimal; revisit for ARM SoC bring-up |
| Scheduler | Thread-per-core; EEVDF-style latency class | CFS-style, pure round-robin | Shared-nothing scales; EEVDF proven (Linux, Redox adoption) |
| Native FS | Custom log-structured CoW (fastfs) | Port ext4/btrfs, littlefs | NVMe-native layout; CoW powers flight recorder; no legacy on-disk contracts |
| Net stack | smoltcp-derived, then native QUIC | Full custom, lwIP port | Proven Rust base to start; QUIC-first long-term |
| Model format | GGUF | ONNX, safetensors-only, vendor blobs | Broadest quantized ecosystem; llama.cpp NPU backends (Hexagon, OpenVINO) prove the path |
| CPU inference kernels | GGML-class quantized kernels (Rust port/binding) | Candle, burn, mistral.rs | Start by binding proven kernels; migrate to pure Rust as parity allows |
| GPU backend | Vulkan compute | CUDA, Metal, wgpu | Vendor-neutral across x86_64 dGPU + ARM iGPU |
| NPU backends | Per-SoC providers behind inferd trait | Single abstraction layer upfront | Vendor stacks too heterogeneous to abstract prematurely |
| Tool schema | MCP-compatible + capability annotations | Custom IDL only, gRPC reflection | Free interop with existing agent ecosystem; annotations add `effectful`/cap metadata |
| Config/state store | Typed watchable key-space | Text files in /etc, registry clone | Machine-and-agent queryable; schema-validated; ADR pending |
| IPC serialization | rkyv-style zero-copy | serde+bincode, protobuf, capnp | Zero-copy aligns with ring architecture |
| Build | Cargo workspace + xtask; Nix dev shells | Bazel, make | Stays in Rust ecosystem; Nix pins cross toolchains |
| Testing | QEMU snapshot tests + proptest + kani (frame) | Hardware-only, unit-only | Model-check the unsafe core; property-test the safe services |
| Dev/CI virt | QEMU/KVM, virtio-first | VMware, bare-metal CI | Fast loop; virtio drivers double as first driver set |
| POSIX story | Userspace personality shim (Phase 3+) | In-kernel compat, Linux ABI (Asterinas-style), none | Ports without contaminating native API; Linux ABI reconsidered if shim insufficient |
| UI (deferred) | Native toolkit w/ auto tool-export | Port Wayland ecosystem | Every app action becomes an agent tool by construction |
