# fastfs

Userspace reference implementation of the fast-os native filesystem
(design: [`../docs/fastfs-design.md`](../docs/fastfs-design.md)). Written in
ordinary `std` Rust with **zero dependencies** so the on-disk format and
algorithms can be tested end-to-end before being ported to the in-kernel
`no_std` version.

## Build & test

```bash
cd fastfs
cargo test              # runs the integration suite
cargo build --release   # builds the fastfs-tool CLI
```

(Host utility wrapper for macOS/Linux: [`../utilities/fastfs`](../utilities/README.md).)

## What it implements

| Feature | Notes |
|---|---|
| Content-addressed CoW | Overwrites allocate fresh blocks; old blocks stay reachable by snapshots (log-structured, bump-allocated). |
| Subvolumes | Many independently-mountable roots in one pool, isolated inode/version spaces. |
| O(1) version-tagged snapshots | Snapshot allocates a version id; copies nothing (bcachefs-style). |
| Per-directory redundancy | `single` / `mirror:N` / `stripe:N` on any subtree; `mirror:N` writes N real replicas. |
| Scrub + self-heal | Verifies every replica's checksum; repairs a bad copy from a good one. |
| Integrity everywhere | FNV checksum per data block (verified on read); checksummed superblocks/checkpoints. |
| Atomic commit | Double-buffered superblock; a crash leaves the previous generation intact. |
| **Tags** | Arbitrary searchable tags per file/dir (`find-tag`). |
| **Per-folder quotas** | Byte budget on a directory subtree, enforced on write. |
| **Per-folder history** | Named folder snapshots with a listable history; read any past version. |
| **MCP/LLM tooling** | Every operation exposed as a typed, self-describing tool; read-only vs `effectful` marked. |

## Architecture

```
device.rs    file-backed 4 KiB block device (auto-extending)
codec.rs     little-endian serialization + FNV checksum
keyspace.rs  the "filesystem as a database": one sorted map keyed by
             (subvol, inode, kind, offset, snap); snapshot ancestry resolution
policy.rs    redundancy placement policy (single/mirror/stripe)
fs.rs        superblock, atomic commit, path ops, CoW writes, snapshots,
             tags, quotas, folder history, mirrored replicas, scrub
mcp.rs       MCP-shaped tool catalog + dispatcher (the agent surface)
bin/fastfs_tool.rs   CLI incl. host import/export
```

## Test coverage

`tests/integration.rs` exercises: mkfs+remount persistence, nested dirs +
sorted readdir, multi-chunk file roundtrip, overwrite/shrink, snapshot content
isolation + folder history, `mirror:2` replica writes + scrub repair, policy
inheritance, unrecoverable-corruption detection, tags add/list/find, quota
enforcement, subvolume isolation, and an MCP tool-call roundtrip.

## Relationship to the kernel

This prototype keeps the keyspace as an in-memory `BTreeMap` checkpointed to
disk — identical *semantics* to the design's on-disk CoW B-tree, simpler
substrate. Block GC/free (the allocator is append-only), stripe parity, and a
FUSE host mount are deliberately left for later and tracked in the design doc.
The module boundaries mirror the eventual kernel layout so porting is
mechanical.
