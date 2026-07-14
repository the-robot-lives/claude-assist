use crate::config::{AppConfig, SourceRoot};
use crate::kinds::{Kind, SourceItem};
use anyhow::Result;
use std::collections::BTreeMap;
use std::fs;
use std::path::{Path, PathBuf};

const SKILL_SKIP: &[&str] = &["shared", "evals"];

/// Discover all items of a kind from configured sources.
/// On name collision, lower priority wins; losers are recorded in `collisions`.
pub fn discover(
    cfg: &AppConfig,
    kind: Kind,
) -> Result<(BTreeMap<String, SourceItem>, Vec<(String, PathBuf, PathBuf)>)> {
    let mut roots: Vec<&SourceRoot> = cfg.source_roots(kind).iter().collect();
    roots.sort_by_key(|r| r.priority);

    let mut items: BTreeMap<String, SourceItem> = BTreeMap::new();
    let mut collisions: Vec<(String, PathBuf, PathBuf)> = Vec::new();

    for root in roots {
        if !root.path.is_dir() {
            continue;
        }
        let found = match kind {
            Kind::Skills => scan_skills(&root.path, root.priority)?,
            Kind::Agents | Kind::Commands => scan_md_files(kind, &root.path, root.priority)?,
        };
        for item in found {
            if let Some(existing) = items.get(&item.name) {
                collisions.push((item.name.clone(), existing.path.clone(), item.path.clone()));
            } else {
                items.insert(item.name.clone(), item);
            }
        }
    }
    Ok((items, collisions))
}

fn scan_skills(root: &Path, priority: i32) -> Result<Vec<SourceItem>> {
    let mut out = Vec::new();
    let entries = match fs::read_dir(root) {
        Ok(e) => e,
        Err(_) => return Ok(out),
    };
    for entry in entries.flatten() {
        let path = entry.path();
        if !path.is_dir() {
            continue;
        }
        let name = match path.file_name().and_then(|n| n.to_str()) {
            Some(n) if !n.starts_with('.') && !SKILL_SKIP.contains(&n) => n.to_string(),
            _ => continue,
        };
        let skill_md = path.join("SKILL.md");
        if !skill_md.is_file() {
            continue;
        }
        let (fm_name, desc) = parse_frontmatter_meta(&skill_md);
        out.push(SourceItem {
            kind: Kind::Skills,
            name,
            path,
            priority,
            source_root: root.to_path_buf(),
            frontmatter_name: fm_name,
            description: desc,
        });
    }
    Ok(out)
}

fn scan_md_files(kind: Kind, root: &Path, priority: i32) -> Result<Vec<SourceItem>> {
    let mut out = Vec::new();
    let entries = match fs::read_dir(root) {
        Ok(e) => e,
        Err(_) => return Ok(out),
    };
    for entry in entries.flatten() {
        let path = entry.path();
        if !path.is_file() {
            continue;
        }
        let fname = match path.file_name().and_then(|n| n.to_str()) {
            Some(n) if n.ends_with(".md") && !n.starts_with('.') => n,
            _ => continue,
        };
        let name = fname.trim_end_matches(".md").to_string();
        let (fm_name, desc) = parse_frontmatter_meta(&path);
        out.push(SourceItem {
            kind,
            name,
            path,
            priority,
            source_root: root.to_path_buf(),
            frontmatter_name: fm_name,
            description: desc,
        });
    }
    Ok(out)
}

/// Parse simple YAML frontmatter for `name` and `description`.
pub fn parse_frontmatter_meta(path: &Path) -> (Option<String>, Option<String>) {
    let Ok(text) = fs::read_to_string(path) else {
        return (None, None);
    };
    let Some(rest) = text.strip_prefix("---") else {
        return (None, None);
    };
    let Some(end) = rest.find("\n---") else {
        return (None, None);
    };
    let yaml = &rest[..end];
    let mut name = None;
    let mut desc = None;
    for line in yaml.lines() {
        let line = line.trim();
        if let Some(v) = line.strip_prefix("name:") {
            let v = v.trim().trim_matches('"').trim_matches('\'').to_string();
            if !v.is_empty() {
                name = Some(v);
            }
        } else if let Some(v) = line.strip_prefix("description:") {
            let v = v.trim().trim_matches('"').trim_matches('\'').to_string();
            if !v.is_empty() {
                // may be multi-line quoted; take first line only for list display
                desc = Some(v);
            }
        }
    }
    (name, desc)
}

/// Check skill structure: SKILL.md exists with name + description in frontmatter.
pub fn skill_structure_ok(path: &Path) -> (bool, Vec<String>) {
    let mut issues = Vec::new();
    let skill_md = if path.is_dir() {
        path.join("SKILL.md")
    } else {
        path.to_path_buf()
    };
    if !skill_md.is_file() {
        issues.push("missing SKILL.md".into());
        return (false, issues);
    }
    let (name, desc) = parse_frontmatter_meta(&skill_md);
    if name.is_none() {
        issues.push("SKILL.md frontmatter missing name".into());
    }
    if desc.is_none() {
        issues.push("SKILL.md frontmatter missing description".into());
    }
    (issues.is_empty(), issues)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Write;
    use tempfile::tempdir;

    #[test]
    fn discover_skills() {
        let dir = tempdir().unwrap();
        let skill = dir.path().join("demo");
        fs::create_dir(&skill).unwrap();
        let mut f = fs::File::create(skill.join("SKILL.md")).unwrap();
        writeln!(f, "---\nname: demo\ndescription: hi\n---\n").unwrap();
        fs::create_dir(dir.path().join("shared")).unwrap();

        let mut cfg = AppConfig::builtin_defaults();
        cfg.sources.skills = vec![crate::config::SourceRoot {
            path: dir.path().to_path_buf(),
            priority: 10,
        }];
        let (items, _) = discover(&cfg, Kind::Skills).unwrap();
        assert!(items.contains_key("demo"));
        assert!(!items.contains_key("shared"));
    }

    #[test]
    fn discover_agents() {
        let dir = tempdir().unwrap();
        let mut f = fs::File::create(dir.path().join("npl-tasker.md")).unwrap();
        writeln!(f, "---\nname: npl-tasker\ndescription: t\n---\n").unwrap();

        let mut cfg = AppConfig::builtin_defaults();
        cfg.sources.agents = vec![crate::config::SourceRoot {
            path: dir.path().to_path_buf(),
            priority: 10,
        }];
        let (items, _) = discover(&cfg, Kind::Agents).unwrap();
        assert!(items.contains_key("npl-tasker"));
    }
}
