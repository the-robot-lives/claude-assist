//! fastfs core: superblock, atomic commit, path operations, CoW writes,
//! snapshots, per-directory redundancy, and scrub.

use crate::codec::{fnv1a, Reader, Writer};
use crate::device::{FileDevice, BLOCK_SIZE, FIRST_ALLOC_BLOCK, SUPERBLOCK_A, SUPERBLOCK_B};
use crate::keyspace::{
    DirentRec, ExtentRec, InodeRec, Key, KeySpace, SnapRec, Value, ITYPE_DIR, ITYPE_FILE,
    KIND_DIRENT, KIND_EXTENT, KIND_INODE,
};
use crate::policy::Policy;
use crate::{FsError, Result, NONE_ID, ROOT_INODE};
use std::collections::BTreeMap;
use std::path::Path;

const SB_MAGIC: u64 = u64::from_le_bytes(*b"FASTFS01");
const SB_VERSION: u32 = 1;

#[derive(Clone)]
struct SubvolRec {
    id: u64,
    name: String,
    tip: u64,       // current writable snapshot version
    next_inode: u64,
    policy: Policy, // default policy for the subvolume root
}

struct Superblock {
    generation: u64,
    bump_next: u64,
    cp_start: u64,
    cp_len: u64,
}

pub struct StatInfo {
    pub itype: u8,
    pub size: u64,
    pub policy: Policy,
    pub replicas: usize,
}

pub struct ScrubReport {
    pub extents: u64,
    pub replicas_checked: u64,
    pub repaired: u64,
    pub unrecoverable: u64,
}

pub struct Stats {
    pub device_blocks: u64,
    pub blocks_used: u64,
    pub keys: usize,
    pub snapshots: usize,
    pub subvols: usize,
}

pub struct Fastfs {
    dev: FileDevice,
    generation: u64,
    bump_next: u64,
    next_snap_id: u64,
    next_subvol_id: u64,
    subvols: BTreeMap<u64, SubvolRec>,
    named: BTreeMap<String, u64>, // snapshot name -> frozen version id
    /// (subvol, folder path) -> list of (label, frozen version)
    history: BTreeMap<(u64, String), Vec<(String, u64)>>,
    ks: KeySpace,
}

impl Fastfs {
    // ---- lifecycle -------------------------------------------------------

    /// Create a fresh filesystem and leave it mounted.
    pub fn mkfs<P: AsRef<Path>>(path: P) -> Result<Fastfs> {
        let dev = FileDevice::create(path)?;
        let mut ks = KeySpace::new();
        // root snapshot version 0 for subvol 0
        ks.add_snap(SnapRec {
            id: 0,
            parent: NONE_ID,
            name: "@root".into(),
        });
        // root directory inode of subvol 0
        ks.put(
            Key::new(0, ROOT_INODE, KIND_INODE, 0, 0),
            Value::Inode(InodeRec::new_dir(Policy::Single)),
        );
        let mut subvols = BTreeMap::new();
        subvols.insert(
            0,
            SubvolRec {
                id: 0,
                name: "root".into(),
                tip: 0,
                next_inode: ROOT_INODE + 1,
                policy: Policy::Single,
            },
        );
        let mut fs = Fastfs {
            dev,
            generation: 0,
            bump_next: FIRST_ALLOC_BLOCK,
            next_snap_id: 1,
            next_subvol_id: 1,
            subvols,
            named: BTreeMap::new(),
            history: BTreeMap::new(),
            ks,
        };
        fs.commit()?;
        Ok(fs)
    }

    /// Mount an existing filesystem (reads whichever superblock has the
    /// highest generation and a valid checksum).
    pub fn mount<P: AsRef<Path>>(path: P) -> Result<Fastfs> {
        let mut dev = FileDevice::open(path)?;
        let a = decode_superblock(&dev.read_block(SUPERBLOCK_A)?);
        let b = decode_superblock(&dev.read_block(SUPERBLOCK_B)?);
        let sb = match (a, b) {
            (Some(x), Some(y)) => {
                if x.generation >= y.generation {
                    x
                } else {
                    y
                }
            }
            (Some(x), None) => x,
            (None, Some(y)) => y,
            (None, None) => return Err(FsError::Corrupt("no valid superblock".into())),
        };
        // load checkpoint blob
        let nblocks = div_ceil(sb.cp_len, BLOCK_SIZE as u64);
        let mut blob = Vec::with_capacity((nblocks * BLOCK_SIZE as u64) as usize);
        for i in 0..nblocks {
            blob.extend_from_slice(&dev.read_block(sb.cp_start + i)?);
        }
        blob.truncate(sb.cp_len as usize);

        let (next_snap_id, next_subvol_id, subvols, named, history, ks) = decode_state(&blob)?;
        Ok(Fastfs {
            dev,
            generation: sb.generation,
            bump_next: sb.bump_next,
            next_snap_id,
            next_subvol_id,
            subvols,
            named,
            history,
            ks,
        })
    }

    // ---- allocator (append-only bump) -----------------------------------

    fn alloc_block(&mut self) -> u64 {
        let b = self.bump_next;
        self.bump_next += 1;
        b
    }

    fn alloc_blocks(&mut self, n: u64) -> u64 {
        let start = self.bump_next;
        self.bump_next += n;
        start
    }

    // ---- commit ----------------------------------------------------------

    /// Serialize all state to a new checkpoint and flip the superblock. Atomic:
    /// a crash leaves the previous generation's superblock intact.
    pub fn commit(&mut self) -> Result<()> {
        let blob = self.encode_state();
        let nblocks = div_ceil(blob.len() as u64, BLOCK_SIZE as u64);
        let start = self.alloc_blocks(nblocks);
        for i in 0..nblocks {
            let off = (i * BLOCK_SIZE as u64) as usize;
            let end = (off + BLOCK_SIZE).min(blob.len());
            self.dev.write_block(start + i, &blob[off..end])?;
        }
        self.dev.flush()?;
        let gen = self.generation + 1;
        let sb = Superblock {
            generation: gen,
            bump_next: self.bump_next,
            cp_start: start,
            cp_len: blob.len() as u64,
        };
        let slot = if gen & 1 == 0 { SUPERBLOCK_A } else { SUPERBLOCK_B };
        self.dev.write_block(slot, &encode_superblock(&sb))?;
        self.dev.flush()?;
        self.generation = gen;
        Ok(())
    }

    fn encode_state(&self) -> Vec<u8> {
        let mut w = Writer::new();
        w.u64(self.next_snap_id);
        w.u64(self.next_subvol_id);
        w.u32(self.subvols.len() as u32);
        for s in self.subvols.values() {
            w.u64(s.id);
            w.string(&s.name);
            w.u64(s.tip);
            w.u64(s.next_inode);
            s.policy.encode(&mut w);
        }
        w.u32(self.named.len() as u32);
        for (name, id) in &self.named {
            w.string(name);
            w.u64(*id);
        }
        w.u32(self.history.len() as u32);
        for ((subvol, path), entries) in &self.history {
            w.u64(*subvol);
            w.string(path);
            w.u32(entries.len() as u32);
            for (label, ver) in entries {
                w.string(label);
                w.u64(*ver);
            }
        }
        w.bytes(&self.ks.encode());
        w.buf
    }

    // ---- data blocks -----------------------------------------------------

    /// Write one chunk to `policy.replicas()` physical blocks (CoW: always
    /// fresh blocks). Returns the extent record.
    fn write_chunk(&mut self, data: &[u8], policy: Policy) -> ExtentRec {
        let checksum = fnv1a(data);
        let mut replicas = Vec::new();
        for _ in 0..policy.replicas() {
            let b = self.alloc_block();
            // write_block pads to BLOCK_SIZE
            let _ = self.dev.write_block(b, data);
            replicas.push(b);
        }
        ExtentRec {
            replicas,
            len: data.len() as u32,
            checksum,
        }
    }

    /// Read a chunk, trying each replica until one verifies (self-healing read).
    fn read_chunk(&mut self, e: &ExtentRec) -> Result<Vec<u8>> {
        for &b in &e.replicas {
            let block = self.dev.read_block(b)?;
            let data = block[..e.len as usize].to_vec();
            if fnv1a(&data) == e.checksum {
                return Ok(data);
            }
        }
        Err(FsError::Corrupt(format!(
            "all {} replicas failed checksum",
            e.replicas.len()
        )))
    }

    // ---- path resolution -------------------------------------------------

    fn subvol(&self, subvol: u64) -> Result<&SubvolRec> {
        self.subvols
            .get(&subvol)
            .ok_or_else(|| FsError::Invalid(format!("no subvolume {subvol}")))
    }

    /// Version to read at: explicit snapshot, or the subvolume tip.
    fn read_version(&self, subvol: u64, version: Option<u64>) -> Result<u64> {
        match version {
            Some(v) => Ok(v),
            None => Ok(self.subvol(subvol)?.tip),
        }
    }

    fn inode_rec(&self, subvol: u64, inode: u64, v: u64) -> Option<InodeRec> {
        match self.ks.resolve(subvol, inode, KIND_INODE, 0, v) {
            Some(Value::Inode(i)) => Some(i),
            _ => None,
        }
    }

    fn lookup_child(&self, subvol: u64, dir: u64, name: &str, v: u64) -> Option<DirentRec> {
        let off = fnv1a(name.as_bytes());
        match self.ks.resolve(subvol, dir, KIND_DIRENT, off, v) {
            Some(Value::Dirent(d)) if d.name == name => Some(d),
            _ => None,
        }
    }

    fn resolve_path(&self, subvol: u64, path: &str, v: u64) -> Result<u64> {
        let mut cur = ROOT_INODE;
        for comp in split_components(path) {
            let d = self
                .lookup_child(subvol, cur, &comp, v)
                .ok_or(FsError::NotFound)?;
            cur = d.child;
        }
        Ok(cur)
    }

    // ---- directory ops ---------------------------------------------------

    pub fn mkdir(&mut self, subvol: u64, path: &str) -> Result<()> {
        let (parent_path, name) = split_parent(path)?;
        let tip = self.subvol(subvol)?.tip;
        let parent = self.resolve_path(subvol, &parent_path, tip)?;
        let prec = self.inode_rec(subvol, parent, tip).ok_or(FsError::NotFound)?;
        if prec.itype != ITYPE_DIR {
            return Err(FsError::NotADir);
        }
        if self.lookup_child(subvol, parent, &name, tip).is_some() {
            return Err(FsError::Exists);
        }
        let inode = {
            let s = self.subvols.get_mut(&subvol).unwrap();
            let i = s.next_inode;
            s.next_inode += 1;
            i
        };
        // new directory inherits the parent's policy
        self.ks.put(
            Key::new(subvol, inode, KIND_INODE, 0, tip),
            Value::Inode(InodeRec::new_dir(prec.policy)),
        );
        self.put_dirent(subvol, parent, &name, inode, tip);
        self.commit()
    }

    fn put_dirent(&mut self, subvol: u64, dir: u64, name: &str, child: u64, snap: u64) {
        let off = fnv1a(name.as_bytes());
        self.ks.put(
            Key::new(subvol, dir, KIND_DIRENT, off, snap),
            Value::Dirent(DirentRec {
                child,
                name: name.to_string(),
            }),
        );
    }

    pub fn readdir(
        &self,
        subvol: u64,
        path: &str,
        version: Option<u64>,
    ) -> Result<Vec<(String, u8, u64)>> {
        let v = self.read_version(subvol, version)?;
        let dir = self.resolve_path(subvol, path, v)?;
        let drec = self.inode_rec(subvol, dir, v).ok_or(FsError::NotFound)?;
        if drec.itype != ITYPE_DIR {
            return Err(FsError::NotADir);
        }
        let mut out = Vec::new();
        for off in self.ks.offsets(subvol, dir, KIND_DIRENT) {
            if let Some(Value::Dirent(d)) = self.ks.resolve(subvol, dir, KIND_DIRENT, off, v) {
                let itype = self
                    .inode_rec(subvol, d.child, v)
                    .map(|i| i.itype)
                    .unwrap_or(0);
                out.push((d.name, itype, d.child));
            }
        }
        out.sort_by(|a, b| a.0.cmp(&b.0));
        Ok(out)
    }

    // ---- file ops --------------------------------------------------------

    /// Create or overwrite a file. New extents follow the parent directory's
    /// current policy (so a later `set_policy` affects subsequent writes).
    pub fn write_file(&mut self, subvol: u64, path: &str, data: &[u8]) -> Result<()> {
        let (parent_path, name) = split_parent(path)?;
        let tip = self.subvol(subvol)?.tip;
        let parent = self.resolve_path(subvol, &parent_path, tip)?;
        let prec = self.inode_rec(subvol, parent, tip).ok_or(FsError::NotFound)?;
        if prec.itype != ITYPE_DIR {
            return Err(FsError::NotADir);
        }
        let policy = prec.policy;

        // enforce the nearest ancestor directory quota (if any)
        self.enforce_quota(subvol, parent, tip, &name, data.len() as u64)?;

        let (inode, old_chunks, tags, quota) = match self.lookup_child(subvol, parent, &name, tip) {
            Some(d) => {
                let irec = self.inode_rec(subvol, d.child, tip).ok_or(FsError::NotFound)?;
                if irec.itype != ITYPE_FILE {
                    return Err(FsError::IsADir);
                }
                // preserve tags/quota across overwrite
                (
                    d.child,
                    div_ceil(irec.size, BLOCK_SIZE as u64),
                    irec.tags,
                    irec.quota,
                )
            }
            None => {
                let inode = {
                    let s = self.subvols.get_mut(&subvol).unwrap();
                    let i = s.next_inode;
                    s.next_inode += 1;
                    i
                };
                self.put_dirent(subvol, parent, &name, inode, tip);
                (inode, 0, Vec::new(), 0u64)
            }
        };

        // write new chunks (CoW — fresh blocks every time)
        let chunks: Vec<&[u8]> = if data.is_empty() {
            Vec::new()
        } else {
            data.chunks(BLOCK_SIZE).collect()
        };
        let new_chunks = chunks.len() as u64;
        for (i, chunk) in chunks.into_iter().enumerate() {
            let ext = self.write_chunk(chunk, policy);
            self.ks
                .put(Key::new(subvol, inode, KIND_EXTENT, i as u64, tip), Value::Extent(ext));
        }
        // tombstone extents beyond the new length (shrink/overwrite)
        for i in new_chunks..old_chunks {
            self.ks
                .put(Key::new(subvol, inode, KIND_EXTENT, i, tip), Value::Tombstone);
        }
        self.ks.put(
            Key::new(subvol, inode, KIND_INODE, 0, tip),
            Value::Inode(InodeRec {
                itype: ITYPE_FILE,
                size: data.len() as u64,
                policy,
                tags,
                quota,
            }),
        );
        self.commit()
    }

    pub fn read_file(&mut self, subvol: u64, path: &str, version: Option<u64>) -> Result<Vec<u8>> {
        let v = self.read_version(subvol, version)?;
        let inode = self.resolve_path(subvol, path, v)?;
        let irec = self.inode_rec(subvol, inode, v).ok_or(FsError::NotFound)?;
        if irec.itype != ITYPE_FILE {
            return Err(FsError::IsADir);
        }
        let nchunks = div_ceil(irec.size, BLOCK_SIZE as u64);
        let mut out = Vec::with_capacity(irec.size as usize);
        for i in 0..nchunks {
            match self.ks.resolve(subvol, inode, KIND_EXTENT, i, v) {
                Some(Value::Extent(e)) => {
                    let data = self.read_chunk(&e)?;
                    out.extend_from_slice(&data);
                }
                _ => return Err(FsError::Corrupt(format!("missing extent {i}"))),
            }
        }
        out.truncate(irec.size as usize);
        Ok(out)
    }

    pub fn stat(&self, subvol: u64, path: &str, version: Option<u64>) -> Result<StatInfo> {
        let v = self.read_version(subvol, version)?;
        let inode = self.resolve_path(subvol, path, v)?;
        let irec = self.inode_rec(subvol, inode, v).ok_or(FsError::NotFound)?;
        let replicas = match self.ks.resolve(subvol, inode, KIND_EXTENT, 0, v) {
            Some(Value::Extent(e)) => e.replicas.len(),
            _ => irec.policy.replicas(),
        };
        Ok(StatInfo {
            itype: irec.itype,
            size: irec.size,
            policy: irec.policy,
            replicas,
        })
    }

    /// Physical block addresses of the replicas backing `chunk` of a file
    /// (at the tip). Exposed for tooling and tests (e.g. targeted corruption).
    pub fn extent_replicas(&self, subvol: u64, path: &str, chunk: u64) -> Result<Vec<u64>> {
        let tip = self.subvol(subvol)?.tip;
        let inode = self.resolve_path(subvol, path, tip)?;
        match self.ks.resolve(subvol, inode, KIND_EXTENT, chunk, tip) {
            Some(Value::Extent(e)) => Ok(e.replicas),
            _ => Err(FsError::NotFound),
        }
    }

    // ---- policy ----------------------------------------------------------

    /// Set the redundancy policy on a directory (or file) subtree. Subsequent
    /// writes into that directory use the new policy.
    pub fn set_policy(&mut self, subvol: u64, path: &str, policy: Policy) -> Result<()> {
        let tip = self.subvol(subvol)?.tip;
        let inode = self.resolve_path(subvol, path, tip)?;
        let mut irec = self.inode_rec(subvol, inode, tip).ok_or(FsError::NotFound)?;
        irec.policy = policy;
        self.ks
            .put(Key::new(subvol, inode, KIND_INODE, 0, tip), Value::Inode(irec));
        if inode == ROOT_INODE {
            self.subvols.get_mut(&subvol).unwrap().policy = policy;
        }
        self.commit()
    }

    // ---- snapshots -------------------------------------------------------

    /// Freeze the current state under `name` (O(1)); the live subvolume
    /// continues on a fresh child version. Read the frozen state later with
    /// `snap_version(name)`.
    pub fn snapshot(&mut self, subvol: u64, name: &str) -> Result<u64> {
        let frozen = self.subvol(subvol)?.tip;
        let child = self.next_snap_id;
        self.next_snap_id += 1;
        self.ks.add_snap(SnapRec {
            id: child,
            parent: frozen,
            name: format!("@live/{name}"),
        });
        self.subvols.get_mut(&subvol).unwrap().tip = child;
        self.named.insert(name.to_string(), frozen);
        self.commit()?;
        Ok(frozen)
    }

    pub fn snap_version(&self, name: &str) -> Option<u64> {
        self.named.get(name).copied()
    }

    pub fn list_snapshots(&self) -> Vec<(String, u64)> {
        self.named.iter().map(|(k, v)| (k.clone(), *v)).collect()
    }

    // ---- subvolumes ------------------------------------------------------

    pub fn create_subvol(&mut self, name: &str) -> Result<u64> {
        let id = self.next_subvol_id;
        self.next_subvol_id += 1;
        let root_snap = self.next_snap_id;
        self.next_snap_id += 1;
        self.ks.add_snap(SnapRec {
            id: root_snap,
            parent: NONE_ID,
            name: format!("@{name}"),
        });
        self.ks.put(
            Key::new(id, ROOT_INODE, KIND_INODE, 0, root_snap),
            Value::Inode(InodeRec::new_dir(Policy::Single)),
        );
        self.subvols.insert(
            id,
            SubvolRec {
                id,
                name: name.to_string(),
                tip: root_snap,
                next_inode: ROOT_INODE + 1,
                policy: Policy::Single,
            },
        );
        self.commit()?;
        Ok(id)
    }

    pub fn list_subvols(&self) -> Vec<(u64, String)> {
        self.subvols
            .values()
            .map(|s| (s.id, s.name.clone()))
            .collect()
    }

    // ---- tags ------------------------------------------------------------

    pub fn add_tag(&mut self, subvol: u64, path: &str, tag: &str) -> Result<()> {
        let tip = self.subvol(subvol)?.tip;
        let inode = self.resolve_path(subvol, path, tip)?;
        let mut irec = self.inode_rec(subvol, inode, tip).ok_or(FsError::NotFound)?;
        let tag = tag.trim().to_string();
        if tag.is_empty() {
            return Err(FsError::Invalid("empty tag".into()));
        }
        if !irec.tags.contains(&tag) {
            irec.tags.push(tag);
            irec.tags.sort();
        }
        self.ks
            .put(Key::new(subvol, inode, KIND_INODE, 0, tip), Value::Inode(irec));
        self.commit()
    }

    pub fn remove_tag(&mut self, subvol: u64, path: &str, tag: &str) -> Result<()> {
        let tip = self.subvol(subvol)?.tip;
        let inode = self.resolve_path(subvol, path, tip)?;
        let mut irec = self.inode_rec(subvol, inode, tip).ok_or(FsError::NotFound)?;
        irec.tags.retain(|t| t != tag);
        self.ks
            .put(Key::new(subvol, inode, KIND_INODE, 0, tip), Value::Inode(irec));
        self.commit()
    }

    pub fn get_tags(&self, subvol: u64, path: &str, version: Option<u64>) -> Result<Vec<String>> {
        let v = self.read_version(subvol, version)?;
        let inode = self.resolve_path(subvol, path, v)?;
        Ok(self.inode_rec(subvol, inode, v).ok_or(FsError::NotFound)?.tags)
    }

    /// Find all paths in a subvolume whose inode carries `tag` (at the tip).
    pub fn find_by_tag(&self, subvol: u64, tag: &str) -> Result<Vec<String>> {
        let tip = self.subvol(subvol)?.tip;
        let mut out = Vec::new();
        self.walk(subvol, ROOT_INODE, "", tip, &mut |path, irec| {
            if irec.tags.iter().any(|t| t == tag) {
                out.push(path.to_string());
            }
        })?;
        out.sort();
        Ok(out)
    }

    // ---- per-folder quota ------------------------------------------------

    pub fn set_quota(&mut self, subvol: u64, path: &str, bytes: u64) -> Result<()> {
        let tip = self.subvol(subvol)?.tip;
        let inode = self.resolve_path(subvol, path, tip)?;
        let mut irec = self.inode_rec(subvol, inode, tip).ok_or(FsError::NotFound)?;
        if irec.itype != ITYPE_DIR {
            return Err(FsError::NotADir);
        }
        irec.quota = bytes;
        self.ks
            .put(Key::new(subvol, inode, KIND_INODE, 0, tip), Value::Inode(irec));
        self.commit()
    }

    /// Sum of file sizes in the subtree rooted at `inode`.
    fn subtree_usage(&self, subvol: u64, inode: u64, v: u64) -> Result<u64> {
        let mut total = 0u64;
        self.walk(subvol, inode, "", v, &mut |_p, irec| {
            if irec.itype == ITYPE_FILE {
                total += irec.size;
            }
        })?;
        Ok(total)
    }

    /// Reject a write that would push the nearest quota'd ancestor over budget.
    fn enforce_quota(
        &self,
        subvol: u64,
        parent: u64,
        v: u64,
        name: &str,
        new_size: u64,
    ) -> Result<()> {
        // find nearest ancestor (including parent) with a quota, walking up via
        // the path we resolved. We re-walk from root collecting the chain.
        let chain = self.inode_chain_to(subvol, parent, v)?;
        for &(dir_inode, _) in chain.iter().rev() {
            let irec = match self.inode_rec(subvol, dir_inode, v) {
                Some(i) => i,
                None => continue,
            };
            if irec.quota > 0 {
                let mut used = self.subtree_usage(subvol, dir_inode, v)?;
                // subtract the old size of the file being overwritten
                if let Some(d) = self.lookup_child(subvol, parent, name, v) {
                    if let Some(old) = self.inode_rec(subvol, d.child, v) {
                        used = used.saturating_sub(old.size);
                    }
                }
                if used + new_size > irec.quota {
                    return Err(FsError::Invalid(format!(
                        "quota exceeded: {} + {} > {} bytes",
                        used, new_size, irec.quota
                    )));
                }
            }
        }
        Ok(())
    }

    // ---- per-folder snapshots / history ----------------------------------

    /// Snapshot the current state and record it in `dir`'s history. The
    /// version machinery is subvolume-wide, but history is listed per folder,
    /// so you get "show me this folder last Tuesday" semantics.
    pub fn snapshot_dir(&mut self, subvol: u64, path: &str, label: &str) -> Result<u64> {
        // resolve the folder (must exist and be a dir) before freezing
        let tip = self.subvol(subvol)?.tip;
        let inode = self.resolve_path(subvol, path, tip)?;
        let irec = self.inode_rec(subvol, inode, tip).ok_or(FsError::NotFound)?;
        if irec.itype != ITYPE_DIR {
            return Err(FsError::NotADir);
        }
        let frozen = self.snapshot(subvol, &format!("{path}@{label}"))?;
        self.history
            .entry((subvol, path.to_string()))
            .or_default()
            .push((label.to_string(), frozen));
        self.commit()?;
        Ok(frozen)
    }

    pub fn folder_history(&self, subvol: u64, path: &str) -> Vec<(String, u64)> {
        self.history
            .get(&(subvol, path.to_string()))
            .cloned()
            .unwrap_or_default()
    }

    // ---- traversal helpers ----------------------------------------------

    /// Depth-first walk of a subtree, invoking `f(path, inode_rec)` per entry
    /// (including the starting directory itself as "").
    fn walk(
        &self,
        subvol: u64,
        inode: u64,
        prefix: &str,
        v: u64,
        f: &mut dyn FnMut(&str, &InodeRec),
    ) -> Result<()> {
        if let Some(irec) = self.inode_rec(subvol, inode, v) {
            f(if prefix.is_empty() { "/" } else { prefix }, &irec);
            if irec.itype == ITYPE_DIR {
                for off in self.ks.offsets(subvol, inode, KIND_DIRENT) {
                    if let Some(Value::Dirent(d)) =
                        self.ks.resolve(subvol, inode, KIND_DIRENT, off, v)
                    {
                        let child_path = format!("{prefix}/{}", d.name);
                        self.walk(subvol, d.child, &child_path, v, &mut *f)?;
                    }
                }
            }
        }
        Ok(())
    }

    /// The inode chain (inode, name) from root down to `target`, at version v.
    fn inode_chain_to(&self, subvol: u64, target: u64, v: u64) -> Result<Vec<(u64, String)>> {
        let mut chain = vec![(ROOT_INODE, String::new())];
        if target == ROOT_INODE {
            return Ok(chain);
        }
        // BFS/DFS from root to find target, recording the path of inodes.
        fn dfs(
            fs: &Fastfs,
            subvol: u64,
            cur: u64,
            target: u64,
            v: u64,
            acc: &mut Vec<(u64, String)>,
        ) -> bool {
            if cur == target {
                return true;
            }
            for off in fs.ks.offsets(subvol, cur, KIND_DIRENT) {
                if let Some(Value::Dirent(d)) = fs.ks.resolve(subvol, cur, KIND_DIRENT, off, v) {
                    acc.push((d.child, d.name.clone()));
                    if dfs(fs, subvol, d.child, target, v, acc) {
                        return true;
                    }
                    acc.pop();
                }
            }
            false
        }
        if dfs(self, subvol, ROOT_INODE, target, v, &mut chain) {
            Ok(chain)
        } else {
            Err(FsError::NotFound)
        }
    }

    // ---- scrub / stats ---------------------------------------------------

    /// Verify every replica of every extent; repair a bad replica from a good
    /// one where possible.
    pub fn scrub(&mut self) -> Result<ScrubReport> {
        let mut rep = ScrubReport {
            extents: 0,
            replicas_checked: 0,
            repaired: 0,
            unrecoverable: 0,
        };
        for (_key, e) in self.ks.extents() {
            rep.extents += 1;
            // find a known-good copy
            let mut good: Option<Vec<u8>> = None;
            let mut bad: Vec<u64> = Vec::new();
            for &b in &e.replicas {
                rep.replicas_checked += 1;
                let block = self.dev.read_block(b)?;
                let data = block[..e.len as usize].to_vec();
                if fnv1a(&data) == e.checksum {
                    if good.is_none() {
                        good = Some(data);
                    }
                } else {
                    bad.push(b);
                }
            }
            match good {
                Some(data) => {
                    for b in bad {
                        self.dev.write_block(b, &data)?;
                        rep.repaired += 1;
                    }
                }
                None => {
                    if !bad.is_empty() {
                        rep.unrecoverable += 1;
                    }
                }
            }
        }
        if rep.repaired > 0 {
            self.dev.flush()?;
        }
        Ok(rep)
    }

    pub fn stats(&mut self) -> Result<Stats> {
        Ok(Stats {
            device_blocks: self.dev.block_count()?,
            blocks_used: self.bump_next,
            keys: self.ks.len(),
            snapshots: self.named.len(),
            subvols: self.subvols.len(),
        })
    }
}

// ---- free helpers --------------------------------------------------------

fn div_ceil(a: u64, b: u64) -> u64 {
    if b == 0 {
        0
    } else {
        (a + b - 1) / b
    }
}

fn split_components(path: &str) -> Vec<String> {
    path.split('/')
        .filter(|c| !c.is_empty())
        .map(|c| c.to_string())
        .collect()
}

/// Split into (parent path, final name). Errors on the root path.
fn split_parent(path: &str) -> Result<(String, String)> {
    let comps = split_components(path);
    if comps.is_empty() {
        return Err(FsError::Invalid("cannot operate on root path".into()));
    }
    let name = comps.last().unwrap().clone();
    let parent = comps[..comps.len() - 1].join("/");
    Ok((parent, name))
}

fn encode_superblock(sb: &Superblock) -> Vec<u8> {
    let mut w = Writer::new();
    w.u64(SB_MAGIC);
    w.u32(SB_VERSION);
    w.u64(sb.generation);
    w.u64(sb.bump_next);
    w.u64(sb.cp_start);
    w.u64(sb.cp_len);
    let checksum = fnv1a(&w.buf);
    w.u64(checksum);
    w.buf
}

fn decode_superblock(block: &[u8]) -> Option<Superblock> {
    let mut r = Reader::new(block);
    let magic = r.u64().ok()?;
    if magic != SB_MAGIC {
        return None;
    }
    let _version = r.u32().ok()?;
    let generation = r.u64().ok()?;
    let bump_next = r.u64().ok()?;
    let cp_start = r.u64().ok()?;
    let cp_len = r.u64().ok()?;
    let stored = r.u64().ok()?;
    // checksum covers everything before the checksum field (8+4+8*4 = 44 bytes)
    let computed = fnv1a(&block[..44]);
    if stored != computed {
        return None;
    }
    Some(Superblock {
        generation,
        bump_next,
        cp_start,
        cp_len,
    })
}

type StateTuple = (
    u64,
    u64,
    BTreeMap<u64, SubvolRec>,
    BTreeMap<String, u64>,
    BTreeMap<(u64, String), Vec<(String, u64)>>,
    KeySpace,
);

fn decode_state(bytes: &[u8]) -> Result<StateTuple> {
    let mut r = Reader::new(bytes);
    let next_snap_id = r.u64()?;
    let next_subvol_id = r.u64()?;
    let nsub = r.u32()?;
    let mut subvols = BTreeMap::new();
    for _ in 0..nsub {
        let id = r.u64()?;
        let name = r.string()?;
        let tip = r.u64()?;
        let next_inode = r.u64()?;
        let policy = Policy::decode(&mut r)?;
        subvols.insert(
            id,
            SubvolRec {
                id,
                name,
                tip,
                next_inode,
                policy,
            },
        );
    }
    let nnamed = r.u32()?;
    let mut named = BTreeMap::new();
    for _ in 0..nnamed {
        let name = r.string()?;
        let id = r.u64()?;
        named.insert(name, id);
    }
    let nhist = r.u32()?;
    let mut history: BTreeMap<(u64, String), Vec<(String, u64)>> = BTreeMap::new();
    for _ in 0..nhist {
        let subvol = r.u64()?;
        let path = r.string()?;
        let n = r.u32()?;
        let mut entries = Vec::with_capacity(n as usize);
        for _ in 0..n {
            let label = r.string()?;
            let ver = r.u64()?;
            entries.push((label, ver));
        }
        history.insert((subvol, path), entries);
    }
    let ks_bytes = r.bytes()?;
    let ks = KeySpace::decode(&ks_bytes)?;
    Ok((next_snap_id, next_subvol_id, subvols, named, history, ks))
}
