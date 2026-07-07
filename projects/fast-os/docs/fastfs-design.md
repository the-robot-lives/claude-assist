# fastfs Design — Performance-First CoW Filesystem with Policy-Scoped Redundancy

Status: v0.1 · 2026-07-07 · Research-grounded architecture for the fast-os native filesystem. Expands [architecture.md](architecture.md) §5.

## 1. Requirements

1. NVMe-native performance (queue depth, parallelism — not seek-order thinking)
2. Cheap snapshots (power the agent flight recorder and system rollback)
3. Subvolumes: many mountable roots in one pool (btrfs-style)
4. Multi-disk pools: add/remove devices live, capacity and speed scale seamlessly
5. **Redundancy as policy, not partition**: replication/RAID level set per directory subtree (or file), not per disk — constrain RAID to specific directories, everything else stays fast single-copy
6. Integrity: checksums everywhere, scrub, self-healing when replicas exist

## 2. What the research/field says

- **B-tree-of-everything beats tree-per-inode.** bcachefs's "filesystem as a database" — a few large b-trees keyed by (inode, offset, snapshot) with 256 KiB log-structured nodes — avoids btrfs's per-inode fragmentation and scales better; its on-disk format is now stable and benchmarks well ([bcachefs](https://bcachefs.org./), [architecture overview](https://www.fosslinux.com/158163/bcachefs-linux-next-gen-cow-filesystem.htm), [Wikipedia](https://en.wikipedia.org/wiki/Bcachefs), [Phoronix 6.15 comparison](https://www.phoronix.com/review/linux-615-filesystems)).
- **Version-number snapshots beat tree-cloning.** bcachefs snapshots add a version to keys instead of cloning CoW trees — O(1) creation, no rebalance storm, scales to huge snapshot counts ([bcachefs vs ZFS/btrfs discussion](https://lore.kernel.org/all/20220419014140.5jz4hahhkfksulce@moria.home.lan/T/)).
- **Allocation profiles are the redundancy mechanism.** btrfs demonstrates profiles (single/RAID0/1/10/5/6, applied separately to data vs. metadata *block groups*) and live device add/remove/balance ([btrfs profiles](https://wiki.tnonline.net/w/Btrfs/Profiles), [volume management](https://btrfs.readthedocs.io/en/latest/Volume-management.html)) — but per *filesystem*, not per directory. Its parity RAID (5/6) remains flagged unstable ([status](https://btrfs.readthedocs.io/en/latest/Status.html)).
- **Per-file/-directory policy already half-exists.** bcachefs exposes `data_replicas`, target devices, compression, etc. as inheritable per-file/per-directory options, plus per-device `data_allowed` restrictions ([ArchWiki](https://wiki.archlinux.org/title/Bcachefs), [Gentoo wiki](https://wiki.gentoo.org/wiki/Bcachefs)) — validating requirement 5's feasibility; nobody has made it the *primary* model.
- **Zoned/append-only storage is coming.** ZNS NVMe rewards log-structured, sequential-write designs ([ZNS characterization](https://arxiv.org/pdf/2310.19094)); btrfs's zoned mode uses a separate logical→physical extent tree to implement RAID profiles on zones ([volume management](https://btrfs.readthedocs.io/en/latest/Volume-management.html)).

## 3. Architecture

### 3.1 Layered model

```
┌───────────────────────────────────────────────┐
│ namespaces: subvolumes & snapshots (mounts)   │
├───────────────────────────────────────────────┤
│ keyspace: unified b-tree family               │
│   keys = (subvol, inode, offset, snap-ver)    │
│   extents · dirents · xattrs · policy records │
├───────────────────────────────────────────────┤
│ placement engine: policy → layout             │
│   single │ mirror×N │ stripe │ stripe+parity  │
├───────────────────────────────────────────────┤
│ pool: devices, allocation groups, journal     │
│   per-device roles (journal/meta/data/cache)  │
└───────────────────────────────────────────────┘
```

- **Keyspace (bcachefs-style database model):** a small family of large b-trees with log-structured 256 KiB-class nodes; all metadata is rows, enabling whole-FS integrity via one scrub walk and cheap keyed queries (the Tool Bus exposes this — agents query the FS like a table, capability-scoped).
- **Snapshots by version tagging:** creating a snapshot allocates a snapshot ID in an interval tree; no data or metadata copying. Deletion = background key-range GC. Targets: O(1) create, ≥100k live snapshots (flight recorder needs cheap, frequent, short-lived snapshots).
- **Subvolumes** are distinct key prefixes: independently mountable, snapshottable, quota-able, and each carries its own default *placement policy*. `/`, `/home`, `/var/models`, agent-task sandboxes — all subvolumes of one pool.

### 3.2 Policy-scoped redundancy (the headline feature)

Redundancy is a **placement policy record** — an inheritable attribute on any directory or file, not a property of the pool:

```
fastfs policy set /important        --profile mirror:2       # RAID1 for this subtree only
fastfs policy set /scratch          --profile stripe         # RAID0 speed, no redundancy
fastfs policy set /var/models      --profile stripe:4 --read-spread   # weights: wide reads
fastfs policy set /photos          --profile stripe+parity:1 # RAID5-like, this subtree only
```

- **Inheritance:** policy resolves at write time by nearest-ancestor lookup (cached in the inode row). New extents follow current policy; a background *conformer* migrates existing extents when policy changes — `mv` between policy domains never blocks.
- **Extent-level, not block-group-level:** each extent record carries its placement (device set, stripe geometry, parity). This is btrfs profiles pushed down from filesystem-scope to extent-scope, generalizing what bcachefs's per-file replicas hint at. The whole pool shares free space — no partitioning, no pre-committed RAID capacity.
- **Metadata rule:** b-tree nodes and journal always ≥ mirror:2 when ≥2 devices exist (metadata loss is pool loss; data loss is file loss). Data defaults to `single` for speed — the user opts *in* to redundancy where it matters.
- **Parity discipline:** parity profiles use full-stripe CoW writes only (no read-modify-write hole — the failure that keeps btrfs RAID5/6 unstable). Small writes to parity subtrees buffer in a mirrored write-intent area, then batch to full stripes.

### 3.3 Devices: add, remove, tier

- `fastfs dev add /dev/nvme2n1` — allocation groups appear, placement engine starts using them immediately; a rebalancer widens existing striped extents opportunistically (idle I/O class).
- `fastfs dev evacuate` — reverse migration off a device, live.
- **Per-device roles** (bcachefs-validated): a device can be restricted to journal/metadata/cache/data — e.g. small fast NVMe as metadata+journal device in a mixed pool.
- **Tiering hook (later):** policy may name device classes (`--target fast`), giving cache/promote semantics; ZNS devices join as append-only allocation groups — our log-structured extents map onto zones naturally ([ZNS](https://arxiv.org/pdf/2310.19094)).

### 3.4 Performance posture

Checksums (xxhash-class default, cryptographic optional per policy) on everything; compression per policy domain. Ring-native I/O path end-to-end: fastfs consumes the same SQ/CQ discipline as the rest of the kernel — no interior thread pools. Target: within 5% of ext4-class throughput for `single` policy domains, measured in CI from Phase 2 (see [performance-research.md](performance-research.md)).

## 4. Agent integration notes

Flight-recorder journals live in an auto-snapshotted subvolume (`mirror:2` forced — audit data is precious). Agent task sandboxes are throwaway subvolumes: snapshot on task start, diff on completion (the diff *is* the effect summary shown for approval), drop or merge. Policy records are Tool Bus objects — an agent can *propose* `policy set`, which is an `effectful` staged operation per [agent-integration.md](agent-integration.md) §4.

## 5. Deliberately rejected

ZFS-style RAID-Z fixed vdev geometry (violates per-directory constraint); filesystem-wide profiles only (btrfs's limitation — the thing we're fixing); in-place-update FS with separate volume manager (LVM/mdadm layering can't see files, so per-directory policy is impossible below the FS).

## 5b. Reference implementation (`fastfs/`)

A working userspace implementation lives in [`../fastfs/`](../fastfs/README.md) — zero-dependency `std` Rust, the way filesystems are normally prototyped before kernel porting. It realizes the model above and adds four capabilities beyond the original spec:

- **Tags**: arbitrary searchable labels on any file/dir (`find-tag`), stored on the inode record.
- **Per-folder quotas**: a byte budget on a directory subtree, enforced at write time by summing subtree usage against the nearest quota'd ancestor.
- **Per-folder snapshot history**: `snapshot <folder> <label>` freezes state (O(1) version tag) and records it in that folder's history; `history <folder>` lists entries and any past version is readable. (The version machinery is subvolume-wide; history is *listed* per folder — a genuine per-folder conformer/independent-version model is future work.)
- **MCP/LLM tooling**: every operation is exposed as a typed, self-describing tool (`mcp.rs`) with read-only vs `effectful` marked, realizing [agent-integration.md](agent-integration.md) §5 at the FS layer — an agent enumerates and calls filesystem tools with capability-appropriate gating.

Faithful to design: content-addressed CoW, subvolumes, version-tag snapshots, per-directory `mirror:N` with **real replicas** that `scrub` verifies and self-heals, and FNV checksums verified on every read. Simplifications (documented in the crate README): in-memory `BTreeMap` keyspace checkpointed to disk instead of an on-disk CoW B-tree (same semantics), append-only allocator (no block GC yet), no stripe parity, and host access via `import`/`export` pending a FUSE mount. Host tooling for macOS/Linux is [`../utilities/fastfs`](../utilities/README.md).

## 6. Open questions (future ADRs)

Erasure-coding geometry defaults per pool size; snapshot GC scheduling vs. latency class; whether the conformer uses idle-class rings or a dedicated device budget; dedup (probably per-policy-domain, offline, later).

Sources: [bcachefs](https://bcachefs.org./) · [bcachefs architecture](https://www.fosslinux.com/158163/bcachefs-linux-next-gen-cow-filesystem.htm) · [bcachefs on Wikipedia](https://en.wikipedia.org/wiki/Bcachefs) · [ZFS/btrfs comparison thread](https://lore.kernel.org/all/20220419014140.5jz4hahhkfksulce@moria.home.lan/T/) · [btrfs profiles](https://wiki.tnonline.net/w/Btrfs/Profiles) · [btrfs volume management](https://btrfs.readthedocs.io/en/latest/Volume-management.html) · [btrfs status](https://btrfs.readthedocs.io/en/latest/Status.html) · [bcachefs ArchWiki](https://wiki.archlinux.org/title/Bcachefs) · [bcachefs Gentoo wiki](https://wiki.gentoo.org/wiki/Bcachefs) · [ZNS performance](https://arxiv.org/pdf/2310.19094) · [Phoronix FS comparison](https://www.phoronix.com/review/linux-615-filesystems)
