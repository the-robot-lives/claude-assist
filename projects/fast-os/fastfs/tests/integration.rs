//! End-to-end tests for fastfs. Each test uses a unique temp image file.

use fastfs::device::BLOCK_SIZE;
use fastfs::{Fastfs, Policy};
use std::io::{Seek, SeekFrom, Write};
use std::path::PathBuf;
use std::sync::atomic::{AtomicU64, Ordering};

static COUNTER: AtomicU64 = AtomicU64::new(0);

/// Unique scratch image path; removed on drop.
struct Img(PathBuf);
impl Img {
    fn new(tag: &str) -> Img {
        let n = COUNTER.fetch_add(1, Ordering::SeqCst);
        let mut p = std::env::temp_dir();
        p.push(format!("fastfs-test-{tag}-{}-{n}.img", std::process::id()));
        let _ = std::fs::remove_file(&p);
        Img(p)
    }
    fn path(&self) -> &std::path::Path {
        &self.0
    }
}
impl Drop for Img {
    fn drop(&mut self) {
        let _ = std::fs::remove_file(&self.0);
    }
}

#[test]
fn mkfs_and_remount_persists() {
    let img = Img::new("persist");
    {
        let mut fs = Fastfs::mkfs(img.path()).unwrap();
        fs.mkdir(0, "/docs").unwrap();
        fs.write_file(0, "/docs/hello.txt", b"hi there").unwrap();
    }
    // fresh mount sees the committed state
    let mut fs = Fastfs::mount(img.path()).unwrap();
    let entries = fs.readdir(0, "/", None).unwrap();
    assert!(entries.iter().any(|(n, t, _)| n == "docs" && *t == 1));
    let data = fs.read_file(0, "/docs/hello.txt", None).unwrap();
    assert_eq!(data, b"hi there");
}

#[test]
fn nested_dirs_and_readdir_sorted() {
    let img = Img::new("dirs");
    let mut fs = Fastfs::mkfs(img.path()).unwrap();
    fs.mkdir(0, "/a").unwrap();
    fs.mkdir(0, "/a/b").unwrap();
    fs.write_file(0, "/a/b/z.txt", b"z").unwrap();
    fs.write_file(0, "/a/b/a.txt", b"a").unwrap();
    let names: Vec<String> = fs
        .readdir(0, "/a/b", None)
        .unwrap()
        .into_iter()
        .map(|(n, _, _)| n)
        .collect();
    assert_eq!(names, vec!["a.txt".to_string(), "z.txt".to_string()]);
}

#[test]
fn large_file_multi_chunk_roundtrip() {
    let img = Img::new("large");
    let mut fs = Fastfs::mkfs(img.path()).unwrap();
    // 3.5 blocks worth of data -> exercises chunking + tail chunk length
    let data: Vec<u8> = (0..(BLOCK_SIZE * 3 + 123)).map(|i| (i % 251) as u8).collect();
    fs.write_file(0, "/big.bin", &data).unwrap();
    let got = fs.read_file(0, "/big.bin", None).unwrap();
    assert_eq!(got, data);
    assert_eq!(fs.stat(0, "/big.bin", None).unwrap().size, data.len() as u64);
}

#[test]
fn overwrite_shrinks_and_updates() {
    let img = Img::new("overwrite");
    let mut fs = Fastfs::mkfs(img.path()).unwrap();
    fs.write_file(0, "/f", &vec![7u8; BLOCK_SIZE * 2]).unwrap();
    fs.write_file(0, "/f", b"small").unwrap();
    let got = fs.read_file(0, "/f", None).unwrap();
    assert_eq!(got, b"small");
    assert_eq!(fs.stat(0, "/f", None).unwrap().size, 5);
}

#[test]
fn snapshot_isolates_old_content() {
    let img = Img::new("snap");
    let mut fs = Fastfs::mkfs(img.path()).unwrap();
    fs.mkdir(0, "/proj").unwrap();
    fs.write_file(0, "/proj/notes.txt", b"version one").unwrap();
    fs.snapshot_dir(0, "/proj", "v1").unwrap();
    // mutate after the snapshot
    fs.write_file(0, "/proj/notes.txt", b"version two").unwrap();

    let live = fs.read_file(0, "/proj/notes.txt", None).unwrap();
    assert_eq!(live, b"version two");

    let snap_v = fs.snap_version("/proj@v1").unwrap();
    let old = fs.read_file(0, "/proj/notes.txt", Some(snap_v)).unwrap();
    assert_eq!(old, b"version one");

    // folder history lists the snapshot
    let hist = fs.folder_history(0, "/proj");
    assert_eq!(hist.len(), 1);
    assert_eq!(hist[0].0, "v1");
}

#[test]
fn mirror_policy_writes_replicas_and_scrub_heals() {
    let img = Img::new("mirror");
    {
        let mut fs = Fastfs::mkfs(img.path()).unwrap();
        fs.mkdir(0, "/important").unwrap();
        fs.set_policy(0, "/important", Policy::Mirror(2)).unwrap();
        fs.write_file(0, "/important/data", b"redundant bytes").unwrap();

        let st = fs.stat(0, "/important/data", None).unwrap();
        assert_eq!(st.policy, Policy::Mirror(2));
        assert_eq!(st.replicas, 2);

        let reps = fs.extent_replicas(0, "/important/data", 0).unwrap();
        assert_eq!(reps.len(), 2);

        // corrupt replica #2 directly on disk
        let mut f = std::fs::OpenOptions::new()
            .write(true)
            .open(img.path())
            .unwrap();
        f.seek(SeekFrom::Start(reps[1] * BLOCK_SIZE as u64)).unwrap();
        f.write_all(&vec![0xFFu8; BLOCK_SIZE]).unwrap();
        f.sync_all().unwrap();
    }
    // self-healing read still returns correct data from the good replica
    let mut fs = Fastfs::mount(img.path()).unwrap();
    assert_eq!(
        fs.read_file(0, "/important/data", None).unwrap(),
        b"redundant bytes"
    );
    // scrub repairs the bad replica
    let r = fs.scrub().unwrap();
    assert!(r.extents >= 1);
    assert_eq!(r.repaired, 1);
    assert_eq!(r.unrecoverable, 0);
}

#[test]
fn policy_inheritance() {
    let img = Img::new("inherit");
    let mut fs = Fastfs::mkfs(img.path()).unwrap();
    fs.mkdir(0, "/m").unwrap();
    fs.set_policy(0, "/m", Policy::Mirror(3)).unwrap();
    fs.mkdir(0, "/m/sub").unwrap(); // inherits mirror:3
    fs.write_file(0, "/m/sub/f", b"x").unwrap();
    assert_eq!(fs.stat(0, "/m/sub/f", None).unwrap().replicas, 3);
    // a sibling under root keeps single
    fs.write_file(0, "/root_file", b"y").unwrap();
    assert_eq!(fs.stat(0, "/root_file", None).unwrap().replicas, 1);
}

#[test]
fn tags_add_list_find() {
    let img = Img::new("tags");
    let mut fs = Fastfs::mkfs(img.path()).unwrap();
    fs.write_file(0, "/a.txt", b"a").unwrap();
    fs.write_file(0, "/b.txt", b"b").unwrap();
    fs.add_tag(0, "/a.txt", "invoice").unwrap();
    fs.add_tag(0, "/a.txt", "2026").unwrap();
    fs.add_tag(0, "/b.txt", "invoice").unwrap();

    let mut tags = fs.get_tags(0, "/a.txt", None).unwrap();
    tags.sort();
    assert_eq!(tags, vec!["2026".to_string(), "invoice".to_string()]);

    let found = fs.find_by_tag(0, "invoice").unwrap();
    assert_eq!(found, vec!["/a.txt".to_string(), "/b.txt".to_string()]);

    fs.remove_tag(0, "/a.txt", "2026").unwrap();
    assert_eq!(fs.get_tags(0, "/a.txt", None).unwrap(), vec!["invoice"]);
}

#[test]
fn quota_enforced_on_directory() {
    let img = Img::new("quota");
    let mut fs = Fastfs::mkfs(img.path()).unwrap();
    fs.mkdir(0, "/limited").unwrap();
    fs.set_quota(0, "/limited", 10).unwrap();
    fs.write_file(0, "/limited/ok", b"12345").unwrap(); // 5 bytes, fits
    // second write exceeds the 10-byte subtree quota
    let err = fs.write_file(0, "/limited/big", b"1234567890AB");
    assert!(err.is_err(), "expected quota rejection");
    // the over-quota file must not exist
    assert!(fs.read_file(0, "/limited/big", None).is_err());
    // outside the quota'd dir, writes are unrestricted
    fs.write_file(0, "/unlimited", &vec![0u8; 1000]).unwrap();
}

#[test]
fn subvolumes_are_isolated() {
    let img = Img::new("subvol");
    let mut fs = Fastfs::mkfs(img.path()).unwrap();
    let sv = fs.create_subvol("scratch").unwrap();
    fs.write_file(0, "/only-in-root", b"r").unwrap();
    fs.write_file(sv, "/only-in-scratch", b"s").unwrap();
    // each subvolume sees only its own files
    assert!(fs.read_file(0, "/only-in-root", None).is_ok());
    assert!(fs.read_file(0, "/only-in-scratch", None).is_err());
    assert!(fs.read_file(sv, "/only-in-scratch", None).is_ok());
    assert!(fs.read_file(sv, "/only-in-root", None).is_err());
}

#[test]
fn checksum_detects_unrecoverable_corruption() {
    let img = Img::new("corrupt");
    {
        let mut fs = Fastfs::mkfs(img.path()).unwrap();
        fs.write_file(0, "/single", b"no redundancy here").unwrap();
        let reps = fs.extent_replicas(0, "/single", 0).unwrap();
        assert_eq!(reps.len(), 1); // single policy
        let mut f = std::fs::OpenOptions::new()
            .write(true)
            .open(img.path())
            .unwrap();
        f.seek(SeekFrom::Start(reps[0] * BLOCK_SIZE as u64)).unwrap();
        f.write_all(&vec![0x00u8; BLOCK_SIZE]).unwrap();
        f.sync_all().unwrap();
    }
    let mut fs = Fastfs::mount(img.path()).unwrap();
    // no good replica -> read fails loudly rather than returning bad data
    assert!(fs.read_file(0, "/single", None).is_err());
    let r = fs.scrub().unwrap();
    assert_eq!(r.unrecoverable, 1);
}

#[test]
fn mcp_tool_call_roundtrip() {
    use std::collections::BTreeMap;
    let img = Img::new("mcp");
    let mut fs = Fastfs::mkfs(img.path()).unwrap();

    let mut args = BTreeMap::new();
    args.insert("path".to_string(), "/report.md".to_string());
    args.insert("content".to_string(), "# hello".to_string());
    let res = fastfs::mcp::call(&mut fs, 0, "fastfs.write", &args).unwrap();
    assert!(res.contains("wrote"));

    let mut ls = BTreeMap::new();
    ls.insert("path".to_string(), "/".to_string());
    let listed = fastfs::mcp::call(&mut fs, 0, "fastfs.ls", &ls).unwrap();
    assert!(listed.contains("report.md"));

    // schema enumerates tools and marks effectful ones
    let schema = fastfs::mcp::schema_json();
    assert!(schema.contains("fastfs.write"));
    assert!(schema.contains("\"effectful\": true"));
}
