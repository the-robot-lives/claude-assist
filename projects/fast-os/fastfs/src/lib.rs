//! fastfs — userspace reference implementation of the fast-os native filesystem.
//!
//! This crate implements the design in `docs/fastfs-design.md` in ordinary
//! `std` Rust so the on-disk format and algorithms can be tested end-to-end
//! before being ported to the in-kernel `no_std` version. It demonstrates the
//! design's distinguishing features:
//!
//! - **Content-addressed CoW**: overwrites allocate fresh blocks; old blocks
//!   remain reachable by snapshots (log-structured, bump-allocated store).
//! - **Subvolumes**: many independently-mountable roots in one pool.
//! - **O(1) version-tagged snapshots**: creating a snapshot allocates a
//!   version id, never copies data (bcachefs-style).
//! - **Per-directory redundancy policy**: `mirror:N` / `stripe` / `single`
//!   set on any directory subtree; `mirror:N` writes N real replicas that
//!   `scrub` verifies and self-heals.
//! - **Integrity everywhere**: every data block carries an FNV checksum,
//!   verified on read; superblocks and checkpoints are checksummed too.
//!
//! Not yet modeled here (tracked in the design doc): on-disk CoW B-tree
//! (this prototype keeps the keyspace as an in-memory `BTreeMap` checkpointed
//! to disk — identical semantics, simpler substrate), block GC/free (the
//! prototype's allocator is append-only), and stripe parity.

pub mod codec;
pub mod device;
pub mod fs;
pub mod keyspace;
pub mod mcp;
pub mod policy;

pub use fs::Fastfs;
pub use policy::Policy;

use std::fmt;

/// Sentinel for "no parent" in the snapshot tree and "no subvolume".
pub const NONE_ID: u64 = u64::MAX;

/// The root directory inode number within every subvolume.
pub const ROOT_INODE: u64 = 1;

#[derive(Debug)]
pub enum FsError {
    Io(String),
    NotFound,
    NotADir,
    IsADir,
    Exists,
    Corrupt(String),
    Invalid(String),
}

impl fmt::Display for FsError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            FsError::Io(s) => write!(f, "io error: {s}"),
            FsError::NotFound => write!(f, "no such file or directory"),
            FsError::NotADir => write!(f, "not a directory"),
            FsError::IsADir => write!(f, "is a directory"),
            FsError::Exists => write!(f, "already exists"),
            FsError::Corrupt(s) => write!(f, "corrupt: {s}"),
            FsError::Invalid(s) => write!(f, "invalid: {s}"),
        }
    }
}

impl std::error::Error for FsError {}

impl From<std::io::Error> for FsError {
    fn from(e: std::io::Error) -> Self {
        FsError::Io(e.to_string())
    }
}

pub type Result<T> = std::result::Result<T, FsError>;
