//! Persistent lab workspace index for examples, YAML paths, and session hints.
//!
//! Stored under `lab-workspace/`:
//! - `settings.json` — LLM config
//! - `examples-index.yaml` — generator → prompt files
//! - `prompts/**` — .media.prompt YAML
//! - `outputs/**` — optional relocated binaries (generation usually writes beside prompt)

use std::collections::BTreeMap;
use std::path::{Path, PathBuf};

use chrono::Utc;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExamplesIndex {
    #[serde(default = "index_version")]
    pub version: u32,
    /// generator slug → entries
    #[serde(default)]
    pub generators: BTreeMap<String, Vec<ExampleEntry>>,
    #[serde(default)]
    pub updated_at: Option<String>,
}

impl Default for ExamplesIndex {
    fn default() -> Self {
        Self {
            version: index_version(),
            generators: BTreeMap::new(),
            updated_at: None,
        }
    }
}

fn index_version() -> u32 {
    1
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExampleEntry {
    pub path: String,
    #[serde(default)]
    pub id: Option<String>,
    #[serde(default)]
    pub generator_id: Option<String>,
    #[serde(default)]
    pub created_at: Option<String>,
    #[serde(default)]
    pub source: Option<String>,
}

impl ExamplesIndex {
    // ⟦𓂯𓉻𓍏𓋈⟧ path :: auto-generated pointer for public function path
    pub fn path(workspace: &Path) -> PathBuf {
        workspace.join("examples-index.yaml")
    }

    // ⟦𓃦𓀜𓆽𓁛⟧ load :: auto-generated pointer for public function load
    pub fn load(workspace: &Path) -> Self {
        let p = Self::path(workspace);
        match std::fs::read_to_string(&p) {
            Ok(text) => serde_yaml::from_str(&text).unwrap_or_default(),
            Err(_) => Self::default(),
        }
    }

    // ⟦𓉤𓀡𓆳𓈿⟧ save :: auto-generated pointer for public function save
    pub fn save(&self, workspace: &Path) -> std::io::Result<()> {
        std::fs::create_dir_all(workspace)?;
        let mut copy = self.clone();
        copy.updated_at = Some(Utc::now().to_rfc3339());
        let text = serde_yaml::to_string(&copy).unwrap_or_else(|_| "version: 1\n".into());
        std::fs::write(Self::path(workspace), text)
    }

    /// Register a prompt file under a generator slug. Paths stored relative to workspace when possible.
    // ⟦𓎿𓁞𓇝𓏭⟧ register :: Register a prompt file under a generator slug.
    pub fn register(
        &mut self,
        workspace: &Path,
        slug: &str,
        absolute_path: &Path,
        id: Option<String>,
        generator_id: Option<String>,
    ) {
        let rel = absolute_path
            .strip_prefix(workspace)
            .map(|p| p.display().to_string())
            .unwrap_or_else(|_| absolute_path.display().to_string())
            .replace('\\', "/");

        let entry = ExampleEntry {
            path: rel.clone(),
            id,
            generator_id,
            created_at: Some(Utc::now().to_rfc3339()),
            source: Some("workspace".into()),
        };

        let list = self.generators.entry(slug.to_string()).or_default();
        // Dedupe by path
        if let Some(pos) = list.iter().position(|e| e.path == rel || e.path.ends_with(&rel)) {
            list[pos] = entry;
        } else {
            list.insert(0, entry);
        }
        // Cap history per generator
        if list.len() > 50 {
            list.truncate(50);
        }
    }

    // ⟦𓐞𓏕𓄹𓁐⟧ paths_for_slug :: auto-generated pointer for public function paths_for_slug
    pub fn paths_for_slug(&self, workspace: &Path, slug: &str) -> Vec<PathBuf> {
        let mut out = Vec::new();
        if let Some(list) = self.generators.get(slug) {
            for e in list {
                let p = if Path::new(&e.path).is_absolute() {
                    PathBuf::from(&e.path)
                } else {
                    workspace.join(&e.path)
                };
                if p.is_file() {
                    out.push(p);
                }
            }
        }
        // Also try alternate key forms
        for key in alternate_slugs(slug) {
            if key == slug {
                continue;
            }
            if let Some(list) = self.generators.get(&key) {
                for e in list {
                    let p = if Path::new(&e.path).is_absolute() {
                        PathBuf::from(&e.path)
                    } else {
                        workspace.join(&e.path)
                    };
                    if p.is_file() && !out.contains(&p) {
                        out.push(p);
                    }
                }
            }
        }
        out
    }
}

fn alternate_slugs(slug: &str) -> Vec<String> {
    let mut v = vec![slug.to_string()];
    v.push(slug.replace('_', "-"));
    v.push(slug.replace('-', "_"));
    if let Some(rest) = slug.strip_prefix("fim:") {
        v.push(rest.to_string());
    }
    if let Some(rest) = slug.strip_prefix("kind:") {
        v.push(rest.to_string());
    }
    v
}

/// Ensure workspace layout exists; migrate from legacy `tmp/live-eval` if needed.
// ⟦𓃂𓇔𓂳𓄭⟧ ensure_workspace :: Ensure workspace layout exists; migrate from legacy `tmp/live-eval` if needed.
pub fn ensure_workspace(package_root: &Path, workspace: &Path) -> std::io::Result<()> {
    std::fs::create_dir_all(workspace.join("prompts"))?;
    std::fs::create_dir_all(workspace.join("outputs"))?;

    // One-time migrate from tmp/live-eval if new workspace empty of prompts
    let legacy = package_root.join("tmp").join("live-eval");
    let new_prompts = workspace.join("prompts");
    let legacy_prompts = legacy.join("prompts");
    let new_empty = std::fs::read_dir(&new_prompts)
        .map(|rd| rd.count() == 0)
        .unwrap_or(true);
    if new_empty && legacy_prompts.is_dir() && workspace != legacy {
        copy_dir_recursive(&legacy_prompts, &new_prompts)?;
        // settings
        let leg_settings = legacy.join("settings.json");
        let new_settings = workspace.join("settings.json");
        if leg_settings.is_file() && !new_settings.is_file() {
            let _ = std::fs::copy(&leg_settings, &new_settings);
        }
        // rebuild index from migrated tree
        let mut idx = ExamplesIndex::load(workspace);
        scan_and_index(workspace, &mut idx);
        let _ = idx.save(workspace);
    }

    // Always ensure index exists (rebuild if missing)
    let idx_path = ExamplesIndex::path(workspace);
    if !idx_path.is_file() {
        let mut idx = ExamplesIndex::default();
        scan_and_index(workspace, &mut idx);
        let _ = idx.save(workspace);
    }

    Ok(())
}

fn scan_and_index(workspace: &Path, idx: &mut ExamplesIndex) {
    let prompts = workspace.join("prompts");
    visit_media_prompts(&prompts, &mut |path| {
        let slug = infer_slug_from_path(workspace, path);
        let id = path
            .file_name()
            .and_then(|n| n.to_str())
            .map(|n| n.trim_end_matches(".media.prompt").to_string());
        idx.register(workspace, &slug, path, id, None);
    });
}

/// Infer a generator slug from a prompt path under `workspace/prompts/…`.
// ⟦𓀚𓀈𓇋𓀅⟧ infer_slug_from_path :: Infer a generator slug from a prompt path under `workspace/prompts/…`.
pub fn infer_slug_from_path(workspace: &Path, path: &Path) -> String {
    let rel = path
        .strip_prefix(workspace.join("prompts"))
        .ok()
        .map(|p| p.to_path_buf());
    if let Some(rel) = rel {
        let parts: Vec<_> = rel
            .components()
            .filter_map(|c| c.as_os_str().to_str().map(|s| s.to_string()))
            .collect();
        // prompts/fim/paper_js/foo.media.prompt → paper_js
        if parts.len() >= 2 && parts[0] == "fim" {
            return parts[1].clone();
        }
        if !parts.is_empty() {
            return parts[0].clone();
        }
    }
    path.file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or("unknown")
        .trim_end_matches(".media.prompt")
        .to_string()
}

fn visit_media_prompts(dir: &Path, f: &mut dyn FnMut(&Path)) {
    let Ok(rd) = std::fs::read_dir(dir) else {
        return;
    };
    for ent in rd.flatten() {
        let p = ent.path();
        if p.is_dir() {
            visit_media_prompts(&p, f);
        } else if p
            .file_name()
            .and_then(|n| n.to_str())
            .map(|n| n.ends_with(".media.prompt"))
            .unwrap_or(false)
        {
            f(&p);
        }
    }
}

fn copy_dir_recursive(src: &Path, dst: &Path) -> std::io::Result<()> {
    std::fs::create_dir_all(dst)?;
    for ent in std::fs::read_dir(src)? {
        let ent = ent?;
        let from = ent.path();
        let to = dst.join(ent.file_name());
        if from.is_dir() {
            copy_dir_recursive(&from, &to)?;
        } else {
            let _ = std::fs::copy(&from, &to);
        }
    }
    Ok(())
}

/// Register a newly written prompt and persist the index.
// ⟦𓇪𓃏𓊬𓁠⟧ register_prompt :: Register a newly written prompt and persist the index.
pub fn register_prompt(
    workspace: &Path,
    slug: &str,
    absolute_path: &Path,
    id: Option<String>,
    generator_id: Option<String>,
) {
    let mut idx = ExamplesIndex::load(workspace);
    idx.register(workspace, slug, absolute_path, id, generator_id);
    let _ = idx.save(workspace);
}
