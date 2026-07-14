# Unity Performance Audit Checklist

**Measure first.** Capture a Profiler frame (CPU/GPU/Memory/Rendering), a Frame Debugger pass, and a Memory Profiler snapshot *before* changing anything. See `references/dots-ecs-performance.md` and `references/rendering-graphics.md` §6.

## 0. Baseline
- [ ] Profiler capture saved (standalone player, not just editor)
- [ ] Target frame budget known (60fps = 16.6ms; 72Hz VR = 13.9ms; 90Hz = 11.1ms)
- [ ] Bottleneck classified: CPU-main / CPU-GC / GPU / memory / build-size

## CPU — GC / allocations
- [ ] `GC.Alloc` per frame trending toward 0
- [ ] Audited: boxing, LINQ, closures/lambdas, string concat/interpolation, `params`, interface `foreach`
- [ ] `new WaitForSeconds()` cached; `Debug.Log` removed from hot paths
- [ ] `CompareTag` instead of `.tag ==`
- [ ] Pooling via `UnityEngine.Pool` (`ObjectPool<T>`, `ListPool<T>`)
- [ ] Incremental GC on (non-Web)

## CPU — main thread
- [ ] `GetComponent`/`Camera.main` cached, not per-frame
- [ ] Hot loops jobified (Burst + Job System); verified native via Burst Inspector
- [ ] Raycasts batched with `RaycastCommand` (not deprecated `RaycastNonAlloc`)
- [ ] Physics step / fixed timestep sane; interpolation set
- [ ] Update churn reduced (event-driven over polling)

## GPU / rendering
- [ ] Draw calls / SetPass counted in Frame Debugger
- [ ] SRP Batcher on; shaders SRP-Batcher-compatible (`UnityPerMaterial` CBUFFER); no batch-breaking `MaterialPropertyBlock`
- [ ] GPU Resident Drawer + Occlusion Culling (Forward+) if many shared meshes
- [ ] Static/dynamic batching + GPU instancing where applicable
- [ ] LOD Groups present and tuned; texture/mipmap streaming on
- [ ] Overdraw, shadow resolution, post stack reviewed (Rendering Debugger)
- [ ] Upscaler considered (STP / FSR / DLSS) to render below native

## Memory / build
- [ ] Memory Profiler snapshot diffed for leaks (textures, meshes, unreleased Addressables)
- [ ] Addressables handles released in `OnDestroy`
- [ ] Managed + engine code stripping set; `[Preserve]`/`link.xml` for reflection code
- [ ] Texture compression per platform (ASTC mobile / BC desktop)
- [ ] Content moved to Addressables; Resources usage minimized

## XR-specific (if applicable)
- [ ] Single-pass instanced stereo on; shaders stereo-aware
- [ ] 4x MSAA; foveated rendering enabled; Vulkan API
- [ ] No full-screen post / grab-pass on mobile VR

## Verify
- [ ] Before/after Profiler capture compared (Profile Analyzer)
- [ ] Win is real on device, not just in editor
