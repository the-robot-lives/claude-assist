# Unity 6.x DOTS, ECS, Multithreading & Performance

*Verified June 2026 against `docs.unity3d.com`. Targets Unity 6 / 6.x LTS (`6000.x`), Burst 1.8, Mathematics 1.3, Collections/Physics/Entities/Entities-Graphics 6.5, Netcode for Entities 6.6.*

> **Versioning note.** DOTS packages moved off `1.x` numbering onto **Unity-version-aligned versioning**. `com.unity.entities@latest` now resolves to **6.5.0**, not 1.3/1.4. The **API is unchanged** — `@1.3` and `@6.5` docs describe the same feature line. The "Entities 1.0 production-ready" milestone (March 2023) carries forward.

## DOTS Stack Status

| Package | `com.unity.*` | Version | Role | Prod-ready |
|---|---|---|---|---|
| Entities (ECS) | `entities` | 6.5.0 | Archetype-based ECS runtime | Yes (since 1.0) |
| Burst | `burst` | 1.8.x | Compiles HPC# → native SIMD (LLVM) | Yes |
| C# Job System | engine core | — | Safe multithreaded scheduling | Yes |
| Mathematics | `mathematics` | 1.3.x | SIMD math (`float3`, `quaternion`) | Yes |
| Collections | `collections` | 6.5.x | Unmanaged job/Burst-safe containers | Yes |
| Unity Physics | `physics` | 6.5.x | Deterministic stateless rigid-body | Yes |
| Havok Physics | `com.havok.physics` | paired | Higher-perf solver, same data model (licensed) | Yes |
| Entities Graphics | `entities.graphics` | 6.5.0 | Renders ECS entities via SRP | Yes |
| Netcode for Entities | `netcode` | 6.6.x | Server-authoritative prediction netcode | Yes |

Unity does **not** position DOTS as a blanket GameObject replacement — use it where data-oriented scale/perf matters (large sims, thousands of entities, deterministic netcode/rollback). Hybrid GameObject↔ECS is first-class. **Entities Graphics requires an SRP: URP (Forward+ only) or HDRP; NOT Built-in.** Unity Physics is stateless/deterministic (good for rollback); Havok is a drop-in solver swap.

## ECS Fundamentals (Entities 6.5)

**Data model:** **Archetype** = unique component-type combination; entities share **chunks** (16 KiB uniform memory, one packed array per component type). Moving an entity between archetypes is a **structural change** (expensive).

| Type | Interface | Notes |
|---|---|---|
| Unmanaged component | `IComponentData` (struct) | Default; Burst/job-friendly |
| Managed component | `IComponentData` (class) | Main-thread only, no Burst, GC pressure |
| Shared component | `ISharedComponentData` | Groups chunks per value; change = structural |
| Tag | empty `IComponentData` | Drives queries by presence |
| Dynamic buffer | `IBufferElementData` | Per-entity resizable array |

**Systems — `ISystem` (preferred, struct, Burst) vs `SystemBase` (class, managed, no Burst):**
```csharp
[BurstCompile]
public partial struct MoveSystem : ISystem {
    [BurstCompile] public void OnCreate(ref SystemState state) => state.RequireForUpdate<Velocity>();
    [BurstCompile] public void OnUpdate(ref SystemState state) {
        float dt = SystemAPI.Time.DeltaTime;
        foreach (var (xform, vel) in SystemAPI.Query<RefRW<LocalTransform>, RefRO<Velocity>>())
            xform.ValueRW.Position += vel.ValueRO.Value * dt;
    }
}
```
`SystemState` exposes `EntityManager`, `Dependency`, `WorldUnmanaged`, `WorldUpdateAllocator`, `RequireForUpdate<T>()`.

**EntityQuery:** `SystemAPI.QueryBuilder()` or `new EntityQueryBuilder(Allocator.Temp)…Build()`. `WithAll/WithAny/WithNone`, enableable-aware `WithDisabled<T>/WithAbsent<T>/WithPresent<T>`. Cache manually-built queries in `OnCreate`.

**EntityManager vs ECB:** `EntityManager` does immediate structural changes on the main thread (invalidates arrays + causes sync points). Jobs can't make structural changes — record an **EntityCommandBuffer** and play back later. Built-in playback singletons: `Begin/EndInitialization`, `Begin/EndSimulation`, `Begin/EndFixedStepSimulation`, `BeginPresentation`.
```csharp
var s = SystemAPI.GetSingleton<EndSimulationEntityCommandBufferSystem.Singleton>();
EntityCommandBuffer ecb = s.CreateCommandBuffer(state.WorldUnmanaged);
var writer = ecb.AsParallelWriter();   // safe for IJobEntity
```

**Baking / Baker / SubScenes:** authoring GameObjects → optimized entities (replaces legacy `GameObjectConversionSystem`). Put authoring objects in a **SubScene**; each authoring MonoBehaviour gets a `Baker<T>`. Bakers must be **stateless**; declare inputs via `GetComponent`/`DependsOn`.
```csharp
public class RotationSpeedBaker : Baker<RotationSpeedAuthoring> {
    public override void Bake(RotationSpeedAuthoring a) {
        var e = GetEntity(TransformUsageFlags.Dynamic);
        AddComponent(e, new RotationSpeed { RadiansPerSecond = math.radians(a.DegreesPerSecond) });
    }
}
```

**Aspects (`IAspect`) — DEPRECATED**; will be removed. Iterate components directly with `SystemAPI.Query<RefRW<T>, RefRO<U>>()`.

**Enableable components:** implement **`IEnableableComponent`**; enable/disable causes **no structural change** — ideal for frequently toggled state (replaces tag-component churn). `SetComponentEnabled<T>(entity, bool)`.

**Gotchas:** structural changes invalidate all cached arrays/`Entity` refs/pointers (re-fetch); force sync points (batch via ECB); `EntityManager` ops + managed components are main-thread only (in jobs use `ComponentLookup<T>`, `RefRW/RefRO`, ECB `ParallelWriter`); managed `IComponentData` defeats Burst + adds GC.

## Job System & Burst

| Interface | `Execute` | Parallelism | Use |
|---|---|---|---|
| `IJob` | `Execute()` | One worker | Self-contained task |
| `IJobParallelFor` | `Execute(int i)` | Auto-batched | Data-parallel over a container |
| `IJobFor` | `Execute(int i)` | Choose at schedule | Parallel-or-sequential |
| `IJobEntity` | source-gen | `Schedule`/`ScheduleParallel` | ECS query iteration (preferred) |
| `IJobChunk` | `Execute(in ArchetypeChunk,…)` | per-chunk | Chunk stats / multi-pass |

**Scheduling:** `Schedule(JobHandle dependsOn)`, `ScheduleParallel(...)`, `Run()` (immediate, debug). Chain via `JobHandle`; `JobHandle.CombineDependencies(a,b)`; `Complete()` to read results (main-thread block). In ECS systems use `state.Dependency = job.ScheduleParallel(state.Dependency);`. **Schedule early, `Complete()` late** (e.g. `LateUpdate`); never `Complete()` right after `Schedule()`.

**Safety & allocators:** `[ReadOnly]`/`[WriteOnly]`, `[NativeDisableParallelForRestriction]` (you own safety). Allocators: `Temp` (call scope, can't enter jobs), `TempJob` (≤4 frames), `Persistent` (manual `Dispose()`), `RewindableAllocator`, `state.WorldUpdateAllocator` (ECS per-frame scratch).

**Burst:** `[BurstCompile]` on the job + enclosing type. Options: `FloatMode`, `FloatPrecision`, `OptimizeFor`, `CompileSynchronously`. **Burst Inspector** (`Jobs > Burst > Open Inspector`) shows scalar vs packed (vectorization). **Pitfalls:** no managed objects/`string`/multidim arrays; `catch` unsupported (exceptions in Player builds **abort**); statics must be `readonly` (use `SharedStatic<T>` for mutable); **silent fallback** — with async compilation code runs managed until native build finishes, and a compile failure also stays managed → **always verify via Burst Inspector / warnings**.

**SIMD:** `Unity.Mathematics` (`float4`, `math.*`); `Unity.Burst.Intrinsics.X86`/`.Arm.Neon` with compile-time support checks (`if (IsAvx2Supported) {...}` becomes dead-code-eliminated branches).

## Performance Black Magic — GC, Pooling, Profiling

**GC:** Unity's GC is **non-generational, non-compacting (Boehm)** — heap only grows, frequent small temporaries are disproportionately costly. Drive per-frame allocations **toward 0 bytes**. **Incremental GC** (default in 6.5) spreads marking across frames via write barriers (not on Web/WebGL). Manual: `GarbageCollector.GCMode` to disable during a verified 0-alloc section, re-enable + `GC.Collect()` at a loading seam.

**`GC.Alloc` audit checklist:** boxing (value→`object`/interface — most common), closures/lambdas capturing vars, **LINQ**, string concat/interpolation/`ToString()`, `params` arrays, interface-typed `foreach`, `new WaitForSeconds()` per frame (cache it), `Debug.Log`, `.tag ==` (use `CompareTag`). **`Physics.RaycastNonAlloc` is deprecated → `RaycastCommand`** (Burst/Jobs batch with `NativeArray<RaycastHit>`).

**Pooling — `UnityEngine.Pool` (built-in, no package):** `ObjectPool<T>` (`Get`/`Release`, `defaultCapacity`/`maxSize`), plus `ListPool<T>`, `HashSetPool<T>`, `DictionaryPool<K,V>`. Stack-based, not thread-safe.
```csharp
using (ListPool<RaycastHit>.Get(out var hits)) { /* auto-released on scope exit */ }
```

**Profiling toolchain:**
| Tool | Path / package | Use |
|---|---|---|
| Unity Profiler | `Window > Analysis > Profiler` | CPU/GPU/Memory/Rendering; watch `GC.Alloc` |
| Deep Profiling | toggle | Finds cost/alloc source; **distorts timings** |
| Frame Debugger | `Window > Analysis > Frame Debugger` | Step draw calls; broken batching |
| Profile Analyzer | `com.unity.performance.profile-analyzer` | Aggregate/compare datasets |
| Memory Profiler | `com.unity.memoryprofiler` | Heap snapshots, leaks, diff |
| ProfilerRecorder | `Unity.Profiling.ProfilerRecorder` | Runtime metrics in builds |

Instrument with `ProfilerMarker` (`using (s_marker.Auto()) {...}`). Deep Profiling makes absolute numbers unreliable — use it to *find* the method, then measure with markers.

## Build & Runtime Perf — IL2CPP, Stripping, Asset Loading

**IL2CPP vs Mono:** IL2CPP = AOT (C#→IL→C++→native), faster runtime, required on iOS/consoles/WebGL/Android-64; no `Reflection.Emit`. **Code Generation:** Faster runtime (default) vs Faster (smaller) builds. **C++ Compiler Config:** Debug/Release/**Master** (max LTO for ship).

**Managed code stripping:** defaults IL2CPP→Minimal, Mono→Disabled. Higher levels (Medium/High) = more savings, higher break risk. **Reflection/JSON/DI break under stripping** — preserve with `[Preserve]` or `link.xml` (`preserve="all"`).

**Resources vs AssetBundles vs Addressables:** Resources **discouraged** (bloat, startup load). Addressables (`com.unity.addressables` ~3.1) recommended — `LoadAssetAsync<T>(key)` → `AsyncOperationHandle<T>`, **reference-counted `Addressables.Release(handle)`** (release in `OnDestroy`), built-in remote catalogs/CDN.

**Async:** `SceneManager.LoadSceneAsync` (gate with `allowSceneActivation=false`, poll `.progress` 0→0.9). **`Awaitable`** (Unity 6, pooled, low-GC): `NextFrameAsync`, `MainThreadAsync`/`BackgroundThreadAsync` thread hops. Caveat: not awaitable twice.

**Platform tips:** **WebGL** — IL2CPP, "Faster (smaller) builds", aggressive stripping + link.xml, no threading (avoid `BackgroundThreadAsync`), no incremental GC. **Mobile** — ASTC textures (ETC2 fallback), cut SetPass calls via SRP Batcher + atlasing, cap overdraw/shadow res. **GPU Resident Drawer** (URP/HDRP Forward+ only) — auto BatchRendererGroup + GPU instancing + occlusion culling; best when many objects share a mesh.

> Uncertainty: DOTS patch versions approximate (major.minor confirmed); IL2CPP option strings exist but verify spelling in-editor; `GarbageCollector.GCMode` enum + Memory Profiler version verify against your build.
