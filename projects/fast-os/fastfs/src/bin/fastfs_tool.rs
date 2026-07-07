//! fastfs-tool — CLI for the fastfs userspace reference implementation.
//!
//! Works on any host (macOS, Linux) — it operates on a fastfs *image file*,
//! so you can create, inspect, and populate a fastfs volume without a kernel
//! driver. Import/export bridge to the host filesystem.

use fastfs::mcp;
use fastfs::{Fastfs, Policy};
use std::collections::BTreeMap;
use std::path::Path;
use std::process::exit;

const SUBVOL: u64 = 0; // CLI operates on the default subvolume

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 2 {
        usage();
        exit(2);
    }
    let cmd = args[1].as_str();
    let rest = &args[2..];
    if let Err(e) = run(cmd, rest) {
        eprintln!("fastfs: {e}");
        exit(1);
    }
}

fn run(cmd: &str, a: &[String]) -> fastfs::Result<()> {
    match cmd {
        "mkfs" => {
            let img = arg(a, 0, "image")?;
            Fastfs::mkfs(&img)?;
            println!("created fastfs image at {img}");
        }
        "ls" => {
            let img = arg(a, 0, "image")?;
            let path = a.get(1).cloned().unwrap_or_else(|| "/".into());
            let mut fs = Fastfs::mount(&img)?;
            let v = snap_flag(a, &fs);
            for (name, itype, _) in fs.readdir(SUBVOL, &path, v)? {
                let mark = if itype == 1 { "/" } else { "" };
                println!("{name}{mark}");
            }
        }
        "mkdir" => {
            let img = arg(a, 0, "image")?;
            let path = arg(a, 1, "path")?;
            Fastfs::mount(&img)?.mkdir(SUBVOL, &path)?;
        }
        "write" => {
            // write <img> <path> <localfile|-->  ; '-' reads stdin
            let img = arg(a, 0, "image")?;
            let path = arg(a, 1, "path")?;
            let src = arg(a, 2, "localfile")?;
            let data = if src == "-" {
                use std::io::Read;
                let mut b = Vec::new();
                std::io::stdin().read_to_end(&mut b).map_err(io)?;
                b
            } else {
                std::fs::read(&src).map_err(io)?
            };
            Fastfs::mount(&img)?.write_file(SUBVOL, &path, &data)?;
        }
        "read" => {
            let img = arg(a, 0, "image")?;
            let path = arg(a, 1, "path")?;
            let mut fs = Fastfs::mount(&img)?;
            let v = snap_flag(a, &fs);
            let data = fs.read_file(SUBVOL, &path, v)?;
            use std::io::Write;
            std::io::stdout().write_all(&data).map_err(io)?;
        }
        "stat" => {
            let img = arg(a, 0, "image")?;
            let path = arg(a, 1, "path")?;
            let fs = Fastfs::mount(&img)?;
            let st = fs.stat(SUBVOL, &path, None)?;
            let tags = fs.get_tags(SUBVOL, &path, None).unwrap_or_default();
            println!("type:     {}", if st.itype == 1 { "dir" } else { "file" });
            println!("size:     {} bytes", st.size);
            println!("policy:   {}", st.policy);
            println!("replicas: {}", st.replicas);
            println!("tags:     {}", tags.join(", "));
        }
        "tag" => {
            // tag <img> add|rm <path> <tag>   |   tag <img> ls <path>
            let img = arg(a, 0, "image")?;
            let sub = arg(a, 1, "add|rm|ls")?;
            let path = arg(a, 2, "path")?;
            let mut fs = Fastfs::mount(&img)?;
            match sub.as_str() {
                "add" => fs.add_tag(SUBVOL, &path, &arg(a, 3, "tag")?)?,
                "rm" => fs.remove_tag(SUBVOL, &path, &arg(a, 3, "tag")?)?,
                "ls" => println!("{}", fs.get_tags(SUBVOL, &path, None)?.join(", ")),
                _ => return Err(inv("tag subcommand must be add|rm|ls")),
            }
        }
        "find-tag" => {
            let img = arg(a, 0, "image")?;
            let tag = arg(a, 1, "tag")?;
            for p in Fastfs::mount(&img)?.find_by_tag(SUBVOL, &tag)? {
                println!("{p}");
            }
        }
        "policy" => {
            let img = arg(a, 0, "image")?;
            let path = arg(a, 1, "path")?;
            let profile = Policy::parse(&arg(a, 2, "single|mirror:N|stripe:N")?)?;
            Fastfs::mount(&img)?.set_policy(SUBVOL, &path, profile)?;
        }
        "quota" => {
            let img = arg(a, 0, "image")?;
            let path = arg(a, 1, "path")?;
            let bytes: u64 = arg(a, 2, "bytes")?
                .parse()
                .map_err(|_| inv("bytes must be a number"))?;
            Fastfs::mount(&img)?.set_quota(SUBVOL, &path, bytes)?;
        }
        "snapshot" => {
            // snapshot <img> <path> <label>
            let img = arg(a, 0, "image")?;
            let path = arg(a, 1, "path")?;
            let label = arg(a, 2, "label")?;
            let v = Fastfs::mount(&img)?.snapshot_dir(SUBVOL, &path, &label)?;
            println!("snapshot '{label}' of {path} at version {v}");
        }
        "history" => {
            let img = arg(a, 0, "image")?;
            let path = arg(a, 1, "path")?;
            for (label, v) in Fastfs::mount(&img)?.folder_history(SUBVOL, &path) {
                println!("{label}\tversion {v}");
            }
        }
        "subvol" => {
            let img = arg(a, 0, "image")?;
            let sub = arg(a, 1, "create|ls")?;
            let mut fs = Fastfs::mount(&img)?;
            match sub.as_str() {
                "create" => {
                    let id = fs.create_subvol(&arg(a, 2, "name")?)?;
                    println!("created subvolume {id}");
                }
                "ls" => {
                    for (id, name) in fs.list_subvols() {
                        println!("{id}\t{name}");
                    }
                }
                _ => return Err(inv("subvol subcommand must be create|ls")),
            }
        }
        "scrub" => {
            let img = arg(a, 0, "image")?;
            let r = Fastfs::mount(&img)?.scrub()?;
            println!(
                "scrub: {} extents, {} replicas checked, {} repaired, {} unrecoverable",
                r.extents, r.replicas_checked, r.repaired, r.unrecoverable
            );
        }
        "stats" => {
            let img = arg(a, 0, "image")?;
            let s = Fastfs::mount(&img)?.stats()?;
            println!("device blocks: {}", s.device_blocks);
            println!("blocks used:   {}", s.blocks_used);
            println!("keys:          {}", s.keys);
            println!("snapshots:     {}", s.snapshots);
            println!("subvolumes:    {}", s.subvols);
        }
        "import" => {
            // import <img> <host-dir> <fs-dest-dir>
            let img = arg(a, 0, "image")?;
            let host = arg(a, 1, "host-dir")?;
            let dest = arg(a, 2, "fs-dest")?;
            let mut fs = Fastfs::mount(&img)?;
            let _ = fs.mkdir(SUBVOL, &dest); // ok if exists
            import_dir(&mut fs, Path::new(&host), &dest)?;
            println!("imported {host} -> {dest}");
        }
        "export" => {
            // export <img> <fs-src-dir> <host-dir>
            let img = arg(a, 0, "image")?;
            let src = arg(a, 1, "fs-src")?;
            let host = arg(a, 2, "host-dir")?;
            let mut fs = Fastfs::mount(&img)?;
            std::fs::create_dir_all(&host).map_err(io)?;
            export_dir(&mut fs, &src, Path::new(&host))?;
            println!("exported {src} -> {host}");
        }
        "mcp" => {
            let sub = arg(a, 0, "list|call|schema")?;
            match sub.as_str() {
                "list" => {
                    for t in mcp::tools() {
                        let kind = if t.effectful { "effectful" } else { "read-only" };
                        println!("{:<20} [{}]  {}", t.name, kind, t.description);
                    }
                }
                "schema" => print!("{}", mcp::schema_json()),
                "call" => {
                    // mcp call <img> <tool> [k=v ...]
                    let img = arg(a, 1, "image")?;
                    let tool = arg(a, 2, "tool")?;
                    let mut kv = BTreeMap::new();
                    for pair in &a[3..] {
                        if let Some((k, v)) = pair.split_once('=') {
                            kv.insert(k.to_string(), v.to_string());
                        }
                    }
                    let mut fs = Fastfs::mount(&img)?;
                    println!("{}", mcp::call(&mut fs, SUBVOL, &tool, &kv)?);
                }
                _ => return Err(inv("mcp subcommand must be list|schema|call")),
            }
        }
        "help" | "-h" | "--help" => usage(),
        other => {
            eprintln!("unknown command '{other}'");
            usage();
            exit(2);
        }
    }
    Ok(())
}

// ---- import / export helpers --------------------------------------------

fn import_dir(fs: &mut Fastfs, host: &Path, dest: &str) -> fastfs::Result<()> {
    let mut entries: Vec<_> = std::fs::read_dir(host)
        .map_err(io)?
        .filter_map(|e| e.ok())
        .collect();
    entries.sort_by_key(|e| e.file_name());
    for e in entries {
        let name = e.file_name().to_string_lossy().to_string();
        let child_dest = format!("{}/{}", dest.trim_end_matches('/'), name);
        let ft = e.file_type().map_err(io)?;
        if ft.is_dir() {
            let _ = fs.mkdir(SUBVOL, &child_dest);
            import_dir(fs, &e.path(), &child_dest)?;
        } else if ft.is_file() {
            let data = std::fs::read(e.path()).map_err(io)?;
            fs.write_file(SUBVOL, &child_dest, &data)?;
        }
    }
    Ok(())
}

fn export_dir(fs: &mut Fastfs, src: &str, host: &Path) -> fastfs::Result<()> {
    let entries = fs.readdir(SUBVOL, src, None)?;
    for (name, itype, _) in entries {
        let child_src = format!("{}/{}", src.trim_end_matches('/'), name);
        let child_host = host.join(&name);
        if itype == 1 {
            std::fs::create_dir_all(&child_host).map_err(io)?;
            export_dir(fs, &child_src, &child_host)?;
        } else {
            let data = fs.read_file(SUBVOL, &child_src, None)?;
            std::fs::write(&child_host, data).map_err(io)?;
        }
    }
    Ok(())
}

// ---- small helpers -------------------------------------------------------

fn arg(a: &[String], i: usize, what: &str) -> fastfs::Result<String> {
    a.get(i)
        .cloned()
        .ok_or_else(|| fastfs::FsError::Invalid(format!("missing argument: {what}")))
}

fn snap_flag(a: &[String], fs: &Fastfs) -> Option<u64> {
    // scan for `--snap NAME`
    let mut it = a.iter();
    while let Some(x) = it.next() {
        if x == "--snap" {
            if let Some(name) = it.next() {
                return fs.snap_version(name);
            }
        }
    }
    None
}

fn io(e: std::io::Error) -> fastfs::FsError {
    fastfs::FsError::Io(e.to_string())
}

fn inv(s: &str) -> fastfs::FsError {
    fastfs::FsError::Invalid(s.to_string())
}

fn usage() {
    eprintln!(
        r#"fastfs-tool — userspace fastfs manager (macOS/Linux)

  mkfs      <img>
  ls        <img> [path] [--snap NAME]
  mkdir     <img> <path>
  write     <img> <path> <localfile|->
  read      <img> <path> [--snap NAME]
  stat      <img> <path>
  tag       <img> add|rm|ls <path> [tag]
  find-tag  <img> <tag>
  policy    <img> <path> <single|mirror:N|stripe:N>
  quota     <img> <path> <bytes>
  snapshot  <img> <path> <label>
  history   <img> <path>
  subvol    <img> create|ls [name]
  scrub     <img>
  stats     <img>
  import    <img> <host-dir> <fs-dest>
  export    <img> <fs-src> <host-dir>
  mcp       list | schema | call <img> <tool> [k=v ...]
"#
    );
}
