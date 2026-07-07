//! The keyspace: the "filesystem as a database" model.
//!
//! All metadata lives in one sorted map keyed by
//! `(subvol, inode, kind, offset, snap)`. Field declaration order defines the
//! sort order (derived `Ord`), so range scans over a fixed prefix are cheap —
//! the same access pattern the eventual on-disk CoW B-tree will provide.
//!
//! Snapshots are version tags: a key written at snapshot version V is visible
//! when reading at V or any descendant of V. Resolution walks the snapshot
//! ancestry from the read version upward and returns the nearest match, so
//! creating a snapshot copies nothing.

use crate::codec::{Reader, Writer};
use crate::policy::Policy;
use crate::{FsError, Result};
use std::collections::BTreeMap;

pub const KIND_INODE: u8 = 1;
pub const KIND_DIRENT: u8 = 2;
pub const KIND_EXTENT: u8 = 3;

pub const ITYPE_DIR: u8 = 1;
pub const ITYPE_FILE: u8 = 2;

#[derive(Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Debug)]
pub struct Key {
    pub subvol: u64,
    pub inode: u64,
    pub kind: u8,
    pub offset: u64,
    pub snap: u64,
}

impl Key {
    pub fn new(subvol: u64, inode: u64, kind: u8, offset: u64, snap: u64) -> Key {
        Key {
            subvol,
            inode,
            kind,
            offset,
            snap,
        }
    }
    /// Lowest key sharing the (subvol, inode, kind) prefix.
    pub fn prefix_lo(subvol: u64, inode: u64, kind: u8) -> Key {
        Key::new(subvol, inode, kind, 0, 0)
    }
    /// Highest key sharing the (subvol, inode, kind) prefix.
    pub fn prefix_hi(subvol: u64, inode: u64, kind: u8) -> Key {
        Key::new(subvol, inode, kind, u64::MAX, u64::MAX)
    }
}

#[derive(Clone, Debug)]
pub struct InodeRec {
    pub itype: u8,
    pub size: u64,
    pub policy: Policy,
}

#[derive(Clone, Debug)]
pub struct DirentRec {
    pub child: u64,
    pub name: String,
}

/// One logical 4 KiB chunk of a file. `replicas` holds the physical block
/// address of each copy (length == policy.replicas()).
#[derive(Clone, Debug)]
pub struct ExtentRec {
    pub replicas: Vec<u64>,
    pub len: u32,
    pub checksum: u64,
}

#[derive(Clone, Debug)]
pub enum Value {
    Inode(InodeRec),
    Dirent(DirentRec),
    Extent(ExtentRec),
    /// Deletion marker — shadows inherited keys from ancestor snapshots.
    Tombstone,
}

impl Value {
    fn tag(&self) -> u8 {
        match self {
            Value::Inode(_) => 1,
            Value::Dirent(_) => 2,
            Value::Extent(_) => 3,
            Value::Tombstone => 4,
        }
    }
    fn encode(&self, w: &mut Writer) {
        w.u8(self.tag());
        match self {
            Value::Inode(i) => {
                w.u8(i.itype);
                w.u64(i.size);
                i.policy.encode(w);
            }
            Value::Dirent(d) => {
                w.u64(d.child);
                w.string(&d.name);
            }
            Value::Extent(e) => {
                w.u64_vec(&e.replicas);
                w.u32(e.len);
                w.u64(e.checksum);
            }
            Value::Tombstone => {}
        }
    }
    fn decode(r: &mut Reader) -> Result<Value> {
        let tag = r.u8()?;
        match tag {
            1 => Ok(Value::Inode(InodeRec {
                itype: r.u8()?,
                size: r.u64()?,
                policy: Policy::decode(r)?,
            })),
            2 => Ok(Value::Dirent(DirentRec {
                child: r.u64()?,
                name: r.string()?,
            })),
            3 => Ok(Value::Extent(ExtentRec {
                replicas: r.u64_vec()?,
                len: r.u32()?,
                checksum: r.u64()?,
            })),
            4 => Ok(Value::Tombstone),
            other => Err(FsError::Corrupt(format!("bad value tag {other}"))),
        }
    }
}

/// A snapshot version: an id plus its parent (NONE_ID for a subvolume root).
#[derive(Clone, Debug)]
pub struct SnapRec {
    pub id: u64,
    pub parent: u64,
    pub name: String,
}

#[derive(Default)]
pub struct KeySpace {
    map: BTreeMap<Key, Value>,
    /// snapshot id -> record
    snaps: BTreeMap<u64, SnapRec>,
}

impl KeySpace {
    pub fn new() -> Self {
        KeySpace {
            map: BTreeMap::new(),
            snaps: BTreeMap::new(),
        }
    }

    pub fn add_snap(&mut self, rec: SnapRec) {
        self.snaps.insert(rec.id, rec);
    }

    pub fn snap(&self, id: u64) -> Option<&SnapRec> {
        self.snaps.get(&id)
    }

    /// Ancestry chain from `v` up to the subvolume root, nearest first.
    fn ancestors(&self, v: u64) -> Vec<u64> {
        let mut out = Vec::new();
        let mut cur = v;
        let mut guard = 0;
        while cur != crate::NONE_ID {
            out.push(cur);
            match self.snaps.get(&cur) {
                Some(s) => cur = s.parent,
                None => break,
            }
            guard += 1;
            if guard > 1_000_000 {
                break; // defensive against a corrupt cycle
            }
        }
        out
    }

    pub fn put(&mut self, key: Key, val: Value) {
        self.map.insert(key, val);
    }

    /// Resolve (subvol, inode, kind, offset) as seen at snapshot version `v`.
    /// Returns None if absent or tombstoned.
    pub fn resolve(&self, subvol: u64, inode: u64, kind: u8, offset: u64, v: u64) -> Option<Value> {
        for anc in self.ancestors(v) {
            if let Some(val) = self.map.get(&Key::new(subvol, inode, kind, offset, anc)) {
                return match val {
                    Value::Tombstone => None,
                    other => Some(other.clone()),
                };
            }
        }
        None
    }

    /// Distinct offsets present for (subvol, inode, kind) across all snaps.
    pub fn offsets(&self, subvol: u64, inode: u64, kind: u8) -> Vec<u64> {
        let lo = Key::prefix_lo(subvol, inode, kind);
        let hi = Key::prefix_hi(subvol, inode, kind);
        let mut out: Vec<u64> = Vec::new();
        for (k, _) in self.map.range(lo..=hi) {
            if out.last() != Some(&k.offset) {
                out.push(k.offset);
            }
        }
        out.dedup();
        out
    }

    // --- serialization of the whole keyspace + snap table ---

    pub fn encode(&self) -> Vec<u8> {
        let mut w = Writer::new();
        w.u64(self.snaps.len() as u64);
        for s in self.snaps.values() {
            w.u64(s.id);
            w.u64(s.parent);
            w.string(&s.name);
        }
        w.u64(self.map.len() as u64);
        for (k, v) in &self.map {
            w.u64(k.subvol);
            w.u64(k.inode);
            w.u8(k.kind);
            w.u64(k.offset);
            w.u64(k.snap);
            v.encode(&mut w);
        }
        w.buf
    }

    pub fn decode(bytes: &[u8]) -> Result<KeySpace> {
        let mut r = Reader::new(bytes);
        let mut ks = KeySpace::new();
        let nsnaps = r.u64()?;
        for _ in 0..nsnaps {
            let id = r.u64()?;
            let parent = r.u64()?;
            let name = r.string()?;
            ks.snaps.insert(id, SnapRec { id, parent, name });
        }
        let nkeys = r.u64()?;
        for _ in 0..nkeys {
            let key = Key::new(r.u64()?, r.u64()?, r.u8()?, r.u64()?, r.u64()?);
            let val = Value::decode(&mut r)?;
            ks.map.insert(key, val);
        }
        Ok(ks)
    }
}
