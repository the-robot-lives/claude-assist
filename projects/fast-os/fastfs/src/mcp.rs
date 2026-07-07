//! MCP-shaped tool interface over fastfs.
//!
//! This realizes the fast-os "the OS is the tool server" design
//! (`docs/agent-integration.md` §5) at the filesystem layer: every fastfs
//! operation is exposed as a typed, self-describing tool an LLM/agent can
//! enumerate and call. Read-only tools are distinguished from `effectful`
//! ones so the agent surface / approval UI can gate mutations
//! (`docs/security.md` §4). No external deps — schemas and results are
//! emitted as MCP-compatible JSON by hand.

use crate::{Fastfs, FsError, Policy, Result};
use std::collections::BTreeMap;

pub struct ToolDesc {
    pub name: &'static str,
    pub description: &'static str,
    pub effectful: bool,
    /// (param, type, required, description)
    pub params: &'static [(&'static str, &'static str, bool, &'static str)],
}

pub fn tools() -> Vec<ToolDesc> {
    vec![
        ToolDesc {
            name: "fastfs.ls",
            description: "List a directory. Optionally at a snapshot version.",
            effectful: false,
            params: &[
                ("path", "string", true, "Directory path, e.g. /docs"),
                ("snap", "string", false, "Snapshot name to read at"),
            ],
        },
        ToolDesc {
            name: "fastfs.read",
            description: "Read a file's contents (UTF-8).",
            effectful: false,
            params: &[
                ("path", "string", true, "File path"),
                ("snap", "string", false, "Snapshot name to read at"),
            ],
        },
        ToolDesc {
            name: "fastfs.stat",
            description: "Metadata for a path: type, size, policy, replicas, tags.",
            effectful: false,
            params: &[("path", "string", true, "Path")],
        },
        ToolDesc {
            name: "fastfs.find_tag",
            description: "Find all paths carrying a tag.",
            effectful: false,
            params: &[("tag", "string", true, "Tag to search for")],
        },
        ToolDesc {
            name: "fastfs.history",
            description: "List snapshot history recorded for a folder.",
            effectful: false,
            params: &[("path", "string", true, "Folder path")],
        },
        ToolDesc {
            name: "fastfs.write",
            description: "Create or overwrite a file with UTF-8 content.",
            effectful: true,
            params: &[
                ("path", "string", true, "File path"),
                ("content", "string", true, "File content"),
            ],
        },
        ToolDesc {
            name: "fastfs.mkdir",
            description: "Create a directory.",
            effectful: true,
            params: &[("path", "string", true, "Directory path")],
        },
        ToolDesc {
            name: "fastfs.add_tag",
            description: "Add a tag to a path.",
            effectful: true,
            params: &[
                ("path", "string", true, "Path"),
                ("tag", "string", true, "Tag"),
            ],
        },
        ToolDesc {
            name: "fastfs.set_policy",
            description: "Set redundancy policy (single|mirror:N|stripe:N) on a directory.",
            effectful: true,
            params: &[
                ("path", "string", true, "Directory path"),
                ("profile", "string", true, "single | mirror:N | stripe:N"),
            ],
        },
        ToolDesc {
            name: "fastfs.set_quota",
            description: "Set a byte quota on a directory subtree (0 = unlimited).",
            effectful: true,
            params: &[
                ("path", "string", true, "Directory path"),
                ("bytes", "number", true, "Quota in bytes"),
            ],
        },
        ToolDesc {
            name: "fastfs.snapshot",
            description: "Snapshot a folder into its history with a label.",
            effectful: true,
            params: &[
                ("path", "string", true, "Folder path"),
                ("label", "string", true, "Snapshot label"),
            ],
        },
    ]
}

/// Emit the tool catalog as MCP-compatible JSON.
pub fn schema_json() -> String {
    let mut s = String::from("{\n  \"tools\": [\n");
    let all = tools();
    for (i, t) in all.iter().enumerate() {
        s.push_str("    {\n");
        s.push_str(&format!("      \"name\": {},\n", json_str(t.name)));
        s.push_str(&format!(
            "      \"description\": {},\n",
            json_str(t.description)
        ));
        s.push_str(&format!("      \"effectful\": {},\n", t.effectful));
        s.push_str("      \"inputSchema\": { \"type\": \"object\", \"properties\": {");
        for (j, (p, ty, _req, desc)) in t.params.iter().enumerate() {
            s.push_str(&format!(
                " {}: {{ \"type\": {}, \"description\": {} }}",
                json_str(p),
                json_str(ty),
                json_str(desc)
            ));
            if j + 1 < t.params.len() {
                s.push(',');
            }
        }
        s.push_str(" }, \"required\": [");
        let req: Vec<String> = t
            .params
            .iter()
            .filter(|(_, _, r, _)| *r)
            .map(|(p, _, _, _)| json_str(p))
            .collect();
        s.push_str(&req.join(", "));
        s.push_str("] }\n    }");
        if i + 1 < all.len() {
            s.push(',');
        }
        s.push('\n');
    }
    s.push_str("  ]\n}\n");
    s
}

/// Execute a tool call against subvolume `subvol`. Args are a simple string
/// map (the CLI accepts `k=v` pairs). Returns a JSON result object.
pub fn call(
    fs: &mut Fastfs,
    subvol: u64,
    name: &str,
    args: &BTreeMap<String, String>,
) -> Result<String> {
    let get = |k: &str| -> Result<String> {
        args.get(k)
            .cloned()
            .ok_or_else(|| FsError::Invalid(format!("missing arg '{k}'")))
    };
    let snap_ver = |fs: &Fastfs| -> Option<u64> {
        args.get("snap").and_then(|n| fs.snap_version(n))
    };

    match name {
        "fastfs.ls" => {
            let path = get("path")?;
            let v = snap_ver(fs);
            let entries = fs.readdir(subvol, &path, v)?;
            let items: Vec<String> = entries
                .iter()
                .map(|(n, t, _)| {
                    format!(
                        "{{ \"name\": {}, \"type\": {} }}",
                        json_str(n),
                        json_str(if *t == crate::keyspace::ITYPE_DIR {
                            "dir"
                        } else {
                            "file"
                        })
                    )
                })
                .collect();
            Ok(format!("{{ \"entries\": [{}] }}", items.join(", ")))
        }
        "fastfs.read" => {
            let path = get("path")?;
            let v = snap_ver(fs);
            let data = fs.read_file(subvol, &path, v)?;
            let text = String::from_utf8_lossy(&data);
            Ok(format!("{{ \"content\": {} }}", json_str(&text)))
        }
        "fastfs.stat" => {
            let path = get("path")?;
            let st = fs.stat(subvol, &path, None)?;
            let tags = fs.get_tags(subvol, &path, None).unwrap_or_default();
            let tagj: Vec<String> = tags.iter().map(|t| json_str(t)).collect();
            Ok(format!(
                "{{ \"type\": {}, \"size\": {}, \"policy\": {}, \"replicas\": {}, \"tags\": [{}] }}",
                json_str(if st.itype == crate::keyspace::ITYPE_DIR { "dir" } else { "file" }),
                st.size,
                json_str(&st.policy.to_string()),
                st.replicas,
                tagj.join(", ")
            ))
        }
        "fastfs.find_tag" => {
            let tag = get("tag")?;
            let paths = fs.find_by_tag(subvol, &tag)?;
            let pj: Vec<String> = paths.iter().map(|p| json_str(p)).collect();
            Ok(format!("{{ \"paths\": [{}] }}", pj.join(", ")))
        }
        "fastfs.history" => {
            let path = get("path")?;
            let h = fs.folder_history(subvol, &path);
            let hj: Vec<String> = h
                .iter()
                .map(|(l, v)| format!("{{ \"label\": {}, \"version\": {} }}", json_str(l), v))
                .collect();
            Ok(format!("{{ \"history\": [{}] }}", hj.join(", ")))
        }
        "fastfs.write" => {
            let path = get("path")?;
            let content = get("content")?;
            fs.write_file(subvol, &path, content.as_bytes())?;
            Ok(ok_json("wrote", &path))
        }
        "fastfs.mkdir" => {
            let path = get("path")?;
            fs.mkdir(subvol, &path)?;
            Ok(ok_json("created", &path))
        }
        "fastfs.add_tag" => {
            let path = get("path")?;
            let tag = get("tag")?;
            fs.add_tag(subvol, &path, &tag)?;
            Ok(ok_json("tagged", &path))
        }
        "fastfs.set_policy" => {
            let path = get("path")?;
            let profile = Policy::parse(&get("profile")?)?;
            fs.set_policy(subvol, &path, profile)?;
            Ok(ok_json("policy-set", &path))
        }
        "fastfs.set_quota" => {
            let path = get("path")?;
            let bytes: u64 = get("bytes")?
                .parse()
                .map_err(|_| FsError::Invalid("bytes must be a number".into()))?;
            fs.set_quota(subvol, &path, bytes)?;
            Ok(ok_json("quota-set", &path))
        }
        "fastfs.snapshot" => {
            let path = get("path")?;
            let label = get("label")?;
            let v = fs.snapshot_dir(subvol, &path, &label)?;
            Ok(format!(
                "{{ \"status\": \"snapshot\", \"path\": {}, \"version\": {} }}",
                json_str(&path),
                v
            ))
        }
        other => Err(FsError::Invalid(format!("unknown tool '{other}'"))),
    }
}

fn ok_json(status: &str, path: &str) -> String {
    format!(
        "{{ \"status\": {}, \"path\": {} }}",
        json_str(status),
        json_str(path)
    )
}

fn json_str(s: &str) -> String {
    let mut out = String::with_capacity(s.len() + 2);
    out.push('"');
    for c in s.chars() {
        match c {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\n' => out.push_str("\\n"),
            '\r' => out.push_str("\\r"),
            '\t' => out.push_str("\\t"),
            c if (c as u32) < 0x20 => out.push_str(&format!("\\u{:04x}", c as u32)),
            c => out.push(c),
        }
    }
    out.push('"');
    out
}
